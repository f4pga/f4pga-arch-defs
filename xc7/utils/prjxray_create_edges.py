#!/usr/bin/env python3
""" Creates graph nodes and edges in connection database.

For ROI configurations, pips that would intefer with the ROI are not emitted,
and connections that lies outside the ROI are ignored.

"""

import argparse
import prjxray.db
from prjxray.roi import Roi
import simplejson as json
import progressbar
import datetime
import sqlite3
import functools
from collections import namedtuple
from lib.rr_graph import tracks
from lib.rr_graph import graph2
from prjxray.site_type import SitePinDirection
from lib.connection_database import get_track_model
from lib.rr_graph.graph2 import NodeType
import multiprocessing

now = datetime.datetime.now


def add_graph_nodes_for_pins(conn, tile_type, wire, pin_directions):
    """ Adds graph_node rows for each pin on a wire in a tile. """

    # Find the generic wire_in_tile_pkey for the specified tile_type name and
    # wire name.
    c = conn.cursor()
    c.execute("""
SELECT
  pkey,
  site_pin_pkey
FROM
  wire_in_tile
WHERE
  name = ?
  and tile_type_pkey = (
    SELECT
      pkey
    FROM
      tile_type
    WHERE
      name = ?
  );
""", (wire, tile_type))

    (wire_in_tile_pkey, site_pin_pkey) = c.fetchone()

    # Determine if this should be an IPIN or OPIN based on the site_pin
    # direction.
    c.execute("""
        SELECT direction FROM site_pin WHERE pkey = ?;""", (site_pin_pkey,))
    (pin_direction,) = c.fetchone()

    pin_direction = SitePinDirection(pin_direction)
    if pin_direction == SitePinDirection.IN:
        node_type = NodeType.IPIN
    elif pin_direction == SitePinDirection.OUT:
        node_type = NodeType.OPIN
    else:
        assert False, pin_direction

    # Find all instances of this specific wire.
    c.execute("""
        SELECT pkey, node_pkey, tile_pkey
            FROM wire WHERE wire_in_tile_pkey = ?;""",
            (wire_in_tile_pkey,))

    c2 = conn.cursor()
    c3 = conn.cursor()
    c2.execute("""BEGIN EXCLUSIVE TRANSACTION;""")

    for wire_pkey, node_pkey, tile_pkey in c:
        c3.execute("""
            SELECT grid_x, grid_y FROM tile WHERE pkey = ?;""",
            (tile_pkey,))

        grid_x, grid_y = c3.fetchone()

        updates = []
        values = []

        # Insert a graph_node per pin_direction.
        for pin_direction in pin_directions:
            c2.execute("""
            INSERT INTO graph_node(
                graph_node_type, node_pkey, x_low, x_high, y_low, y_high)
                VALUES (?, ?, ?, ?, ?, ?)""", (
                node_type.value, node_pkey, grid_x, grid_x, grid_y, grid_y,
                ))

            updates.append('{}_graph_node_pkey = ?'.format(pin_direction.name.lower()))
            values.append(c2.lastrowid)

        # Update the wire with the graph_nodes in each direction, if
        # applicable.
        c2.execute("""
            UPDATE wire SET {updates} WHERE pkey = ?;""".format(
                updates=','.join(updates)), values + [wire_pkey])

    c2.execute("""COMMIT TRANSACTION;""")
    c2.connection.commit()

def create_find_pip(conn):
    """ Returns a function that takes (tile_type, pip) and returns pip_in_tile_pkey. """
    c = conn.cursor()

    @functools.lru_cache(maxsize=None)
    def find_pip(tile_type, pip):
        c.execute("""
SELECT
  pkey
FROM
  pip_in_tile
WHERE
  name = ?
  AND tile_type_pkey = (
    SELECT
      pkey
    FROM
      tile_type
    WHERE
      name = ?
  );""", (pip, tile_type))

        result = c.fetchone()
        assert result is not None, (tile_type, pip)
        return result[0]

    return find_pip

def create_find_wire(conn):
    """ Returns a function finds a wire based on tile name and wire name.

    Args:
        conn: Database connection

    Returns:
        Function.  See find_wire below for signature.
    """
    c = conn.cursor()


    @functools.lru_cache(maxsize=None)
    def find_wire_in_tile(tile_type, wire):
        c.execute("""
SELECT
  pkey
FROM
  wire_in_tile
WHERE
  name = ?
  AND tile_type_pkey = (
    SELECT
      pkey
    FROM
      tile_type
    WHERE
      name = ?
  );""", (wire, tile_type))

        return c.fetchone()[0]


    @functools.lru_cache(maxsize=None)
    def find_wire(tile, tile_type, wire):
        """ Finds a wire in the database.

        Args:
            tile (str): Tile name
            tile_type (str): Type of tile name
            wire (str): Wire name

        Returns:
            Tuple (wire_pkey, tile_pkey, node_pkey), where:
                wire_pkey (int): Primary key of wire table
                tile_pkey (int): Primary key of tile table that contains this
                    wire.
                node_pkey (int): Primary key of node table that is the node
                    this wire belongs too.
        """

        wire_in_tile_pkey = find_wire_in_tile(tile_type, wire)
        c.execute("""
SELECT
  pkey,
  tile_pkey,
  node_pkey
FROM
  wire
WHERE
  wire_in_tile_pkey = ?
  AND tile_pkey = (
    SELECT
      pkey
    FROM
      tile
    WHERE
      name = ?
  );""", (wire_in_tile_pkey, tile))

        return c.fetchone()

    return find_wire

Pins = namedtuple('Pins', 'x y edge_map site_pin_direction')

OPPOSITE_DIRECTIONS = {
        tracks.Direction.TOP: tracks.Direction.BOTTOM,
        tracks.Direction.BOTTOM: tracks.Direction.TOP,
        tracks.Direction.LEFT: tracks.Direction.RIGHT,
        tracks.Direction.RIGHT: tracks.Direction.LEFT,
    }

class Connector(object):
    """ Connector is an object for joining two nodes.

    Connector represents either a site pin within a specific tile or routing
    channel made of one or more channel nodes.


    """
    def __init__(self, pins=None, tracks=None):
        """ Create a Connector object.

        Provide either pins or tracks, not both or neither.

        Args:
            pins (Pins namedtuple): If this Connector object represents a
                site pin, provide the pins named arguments.
            tracks (tuple of (tracks.Tracks, list of graph nodes)): If this
                Connector object represents a routing channel, provide the
                tracks named argument.

                The tuple can most easily be constructed via
                connection_database.get_track_model, which builds the Tracks
                models and the graph node list.
        """
        self.pins = pins
        self.tracks = tracks
        assert (self.pins is not None) ^ (self.tracks is not None)

    def connect_at(self, loc, other_connector):
        """ Connect two Connector objects at a location within the grid.

        Args:
            loc (prjxray.grid_types.GridLoc): Location within grid to make
                connection.
            other_connector (Connector): Destination connection.

        Returns:
            Tuple of (src_graph_node_pkey, dest_graph_node_pkey)

        """
        if self.tracks and other_connector.tracks:
            tracks_model, graph_nodes = self.tracks
            idx1 = None
            for idx1, _ in tracks_model.get_tracks_for_wire_at_coord(loc):
                break

            assert idx1 is not None

            other_tracks_model, other_graph_nodes = other_connector.tracks
            idx2 = None
            for idx2, _ in other_tracks_model.get_tracks_for_wire_at_coord(loc):
                break

            assert idx2 is not None

            return graph_nodes[idx1], other_graph_nodes[idx2]
        elif self.pins and other_connector.tracks:
            assert self.pins.site_pin_direction == SitePinDirection.OUT
            assert self.pins.x == loc.grid_x
            assert self.pins.y == loc.grid_y

            tracks_model, graph_nodes = other_connector.tracks
            for idx, pin_dir in tracks_model.get_tracks_for_wire_at_coord(loc):
                if pin_dir in self.pins.edge_map:
                    return self.pins.edge_map[pin_dir], graph_nodes[idx]
        elif self.tracks and other_connector.pins:
            assert other_connector.pins.site_pin_direction == SitePinDirection.IN
            assert other_connector.pins.x == loc.grid_x
            assert other_connector.pins.y == loc.grid_y

            tracks_model, graph_nodes = self.tracks
            for idx, pin_dir in tracks_model.get_tracks_for_wire_at_coord(loc):
                if pin_dir in other_connector.pins.edge_map:
                    return graph_nodes[idx], other_connector.pins.edge_map[pin_dir]
        elif self.pins and other_connector.pins:
            assert self.pins.site_pin_direction == SitePinDirection.OUT
            assert other_connector.pins.site_pin_direction == SitePinDirection.IN

            if len(self.pins.edge_map) == 1 and len(other_connector.pins.edge_map) == 1:
                # If there is only one choice, make it.
                return list(self.pins.edge_map.values())[0], list(other_connector.pins.edge_map.values())[0]

            for pin_dir in self.pins.edge_map:
                if OPPOSITE_DIRECTIONS[pin_dir] in other_connector.pins.edge_map:
                    return (
                        self.pins.edge_map[pin_dir],
                        other_connector.pins.edge_map[OPPOSITE_DIRECTIONS[pin_dir]],
                        )

        assert False, (self.tracks, self.pins, other_connector.tracks, other_connector.pins)


def create_find_connector(conn):
    """ Returns a function returns a Connector object for a given wire and node.

    Args:
        conn: Database connection

    Returns:
        Function.  See find_connector below for signature.
    """
    c = conn.cursor()

    @functools.lru_cache(maxsize=None)
    def find_connector(wire_pkey, node_pkey):
        """ Finds Connector for a wire and node in the database.

        Args:
            wire_pkey (int): Primary key into wire table of target wire
            node_pkey (int): Primary key into node table of parent node of
                specified wire.

        Returns:
            None if wire is disconnected, otherwise returns Connector objet.
        """

        # Find all graph_nodes for this node.
        c.execute("""
        SELECT pkey, track_pkey, graph_node_type, x_low, x_high, y_low, y_high FROM graph_node
        WHERE node_pkey = ?;""", (node_pkey,))

        graph_nodes = c.fetchall()

        # If there are no graph nodes, this wire is likely disconnected.
        if len(graph_nodes) == 0:
            return

        # If this is a track (e.g. track_pkey is not NULL), then verify
        # all graph_nodes for the specified node belong to the same track,
        # and then retrieved and return the connector for the track.
        track_pkey = graph_nodes[0][1]
        if track_pkey is not None:
            for node in graph_nodes:
                assert node[1] == track_pkey

            return Connector(tracks=get_track_model(conn, track_pkey))

        # This is not a track, so it must be a site pin.  Make sure the
        # graph_nodes share a type and verify that it is in fact a site pin.
        node_type = graph2.NodeType(graph_nodes[0][2])
        for node in graph_nodes:
            assert node_type == graph2.NodeType(node[2])

        assert node_type in [graph2.NodeType.IPIN, graph2.NodeType.OPIN]
        if node_type == graph2.NodeType.IPIN:
            site_pin_direction = SitePinDirection.IN
        elif node_type == graph2.NodeType.OPIN:
            site_pin_direction = SitePinDirection.OUT
        else:
            assert False, node_type

        # Build the edge_map (map of edge direction to graph node).
        c.execute("""
SELECT
  top_graph_node_pkey,
  bottom_graph_node_pkey,
  left_graph_node_pkey,
  right_graph_node_pkey
FROM
  wire
WHERE
  node_pkey = ?;""", (node_pkey,))

        all_graph_node_pkeys = c.fetchall()

        graph_node_pkeys = None
        for keys in all_graph_node_pkeys:
            if any(keys):
                assert graph_node_pkeys is None
                graph_node_pkeys = keys

        # This wire may not have an connections, if so return now.
        if graph_node_pkeys is None:
            return

        edge_map = {}

        for edge, graph_node in zip(
                (
                    tracks.Direction.TOP,
                    tracks.Direction.BOTTOM,
                    tracks.Direction.LEFT,
                    tracks.Direction.RIGHT,
                    ), graph_node_pkeys,

                ):
            if graph_node is not None:
                edge_map[edge] = graph_node

        assert len(edge_map) == len(graph_nodes), (edge_map, graph_node_pkeys, graph_nodes)

        # Make sure that all graph nodes for this wire are in the edge_map
        # and at the same grid coordinate.
        x = graph_nodes[0][3]
        y = graph_nodes[0][5]
        for pkey, _, _, x_low, x_high, y_low, y_high in graph_nodes:
            assert x == x_low, (wire_pkey, node_pkey, x, x_low, x_high)
            assert x == x_high, (wire_pkey, node_pkey, x, x_low, x_high)

            assert y == y_low, (wire_pkey, node_pkey, y, y_low, y_high)
            assert y == y_high, (wire_pkey, node_pkey, y, y_low, y_high)

            assert pkey in edge_map.values(), (pkey, edge_map)

        return Connector(pins=Pins(
            edge_map=edge_map,
            x=x,
            y=y,
            site_pin_direction=site_pin_direction,
            ))

    return find_connector

def make_connection(conn, input_only_nodes, output_only_nodes,
        find_wire, find_pip, find_connector,
        tile_name, loc, tile_type, pip, switch_pkey):
    """ Attempt to connect graph nodes on either side of a pip.

    Args:
        conn (sqlite3.Connection): Routing database
        input_only_nodes (set of node_pkey): Nodes that can only be used as
            sinks. This is because a synthetic tile will use this node as a
            source.
        output_only_nodes (set of node_pkey): Nodes that can only be used as
            sources. This is because a synthetic tile will use this node as a
            sink.
        find_wire (function): Return value from create_find_wire.
        find_pip (function): Return value from create_find_pip.
        find_connector (function): Return value from create_find_connector.
        tile_name (str): Name of tile pip belongs too.
        loc (prjxray.grid_types.GridLoc): Location of tile.
        pip (prjxray.tile.Pip): Pip being connected.
        switch_pkey (int): Primary key to switch table of switch to be used
            in this connection.

    Returns:
        None if connection cannot be made, otherwise returns tuple of:
            src_graph_node_pkey (int) - Primary key into graph_node table of
                source.
            dest_graph_node_pkey (int) - Primary key into graph_node table of
                destination.
            switch_pkey (int) - Primary key into switch table of switch used
                in connection.
            tile_pkey (int) - Primary key into table of parent tile of pip.
            pip_pkey (int) - Primary key into pip_in_tile table for this pip.

    """

    src_wire_pkey, tile_pkey, src_node_pkey = find_wire(tile_name, tile_type, pip.net_from)
    sink_wire_pkey, tile_pkey2, sink_node_pkey = find_wire(tile_name, tile_type, pip.net_to)

    assert tile_pkey == tile_pkey2

    # Skip nodes that are reserved because of ROI
    if src_node_pkey in input_only_nodes:
        return

    if sink_node_pkey in output_only_nodes:
        return


    src_connector = find_connector(src_wire_pkey, src_node_pkey)
    if src_connector is None:
        return

    sink_connector = find_connector(sink_wire_pkey, sink_node_pkey)
    if sink_connector is None:
        return


    pip_pkey = find_pip(tile_type, pip.name)

    src_graph_node_pkey, dest_graph_node_pkey = src_connector.connect_at(loc, sink_connector)

    return [(
            src_graph_node_pkey,
            dest_graph_node_pkey,
            switch_pkey,
            tile_pkey,
            pip_pkey,
            )]

def mark_track_liveness(conn, pool, input_only_nodes, output_only_nodes):
    """ Checks tracks for liveness.

    Iterates over all graph nodes that are routing tracks and determines if
    at least one graph edge originates from or two the track.

    Args:
        conn (sqlite3.Connection): Connection database

    """
    alive_tracks = set()

    c = conn.cursor()
    c2 = conn.cursor()
    for graph_node_pkey, node_pkey, track_pkey in c.execute("""
SELECT
  pkey,
  node_pkey,
  track_pkey
FROM
  graph_node
WHERE
  track_pkey IS NOT NULL;"""):
        if track_pkey in alive_tracks:
            continue

        if node_pkey in input_only_nodes or node_pkey in output_only_nodes:
            alive_tracks.add(track_pkey)
            continue

        c2.execute("""SELECT count(switch_pkey) FROM graph_edge WHERE
            src_graph_node_pkey = ?;""", (graph_node_pkey,))
        src_count = c2.fetchone()[0]

        c2.execute("""SELECT count(switch_pkey) FROM graph_edge WHERE
            dest_graph_node_pkey = ?;""", (graph_node_pkey,))
        sink_count = c2.fetchone()[0]

        if src_count > 0 and sink_count > 0:
            alive_tracks.add(track_pkey)


    c.execute("SELECT count(pkey) FROM track;")
    track_count = c.fetchone()[0]
    print("{} Alive tracks {} / {}".format(now(), len(alive_tracks), track_count))

    c2.execute("""BEGIN EXCLUSIVE TRANSACTION;""")
    for (track_pkey,) in c.execute("""SELECT pkey FROM track;"""):
        c2.execute("UPDATE track SET alive = ? WHERE pkey = ?;", (
            track_pkey in alive_tracks, track_pkey))
    c2.execute("""COMMIT TRANSACTION;""")

    print('{} Track aliveness committed'.format(now()))

    print("{}: Build channels".format(datetime.datetime.now()))
    build_channels(conn, pool, alive_tracks)
    print("{}: Channels built".format(datetime.datetime.now()))

def direction_to_enum(pin):
    """ Converts string to tracks.Direction. """
    for direction in tracks.Direction:
        if direction._name_ == pin:
            return direction

    assert False


def build_channels(conn, pool, active_tracks):
    c = conn.cursor()

    xs = []
    ys = []

    x_tracks = {}
    y_tracks = {}
    for pkey, track_pkey, graph_node_type, x_low, x_high, y_low, y_high in c.execute("""
SELECT
  pkey,
  track_pkey,
  graph_node_type,
  x_low,
  x_high,
  y_low,
  y_high
FROM
  graph_node
WHERE
  track_pkey IS NOT NULL;"""):
        if track_pkey not in active_tracks:
            continue

        x_low = max(x_low, 1)
        y_low = max(y_low, 1)

        xs.append(x_low)
        xs.append(x_high)
        ys.append(y_low)
        ys.append(y_high)

        node_type = graph2.NodeType(graph_node_type)
        if node_type == graph2.NodeType.CHANX:
            assert y_low == y_high

            if y_low not in x_tracks:
                x_tracks[y_low] = []

            x_tracks[y_low].append((
                    x_low,
                    x_high,
                    pkey))
        elif node_type == graph2.NodeType.CHANY:
            assert x_low == x_high

            if x_low not in y_tracks:
                y_tracks[x_low] = []

            y_tracks[x_low].append((
                    y_low,
                    y_high,
                    pkey))
        else:
            assert False, node_type

    x_list = []
    y_list = []

    x_channel_models = {}
    y_channel_models = {}

    for y in x_tracks:
        x_channel_models[y] = pool.apply_async(graph2.process_track, (x_tracks[y],))

    for x in y_tracks:
        y_channel_models[x] = pool.apply_async(graph2.process_track, (y_tracks[x],))

    c.execute("""BEGIN EXCLUSIVE TRANSACTION;""")

    for y in progressbar.progressbar(range(max(x_tracks)+1)):
        if y in x_tracks:
            x_channel_models[y] = x_channel_models[y].get()

            x_list.append(len(x_channel_models[y].trees))

            for idx, tree in enumerate(x_channel_models[y].trees):
                for i in tree:
                    c.execute('UPDATE graph_node SET ptc = ? WHERE pkey = ?;',
                            (idx, i[2]))
        else:
            x_list.append(0)

    for x in progressbar.progressbar(range(max(y_tracks)+1)):
        if x in y_tracks:
            y_channel_models[x] = y_channel_models[x].get()

            y_list.append(len(y_channel_models[x].trees))

            for idx, tree in enumerate(y_channel_models[x].trees):
                for i in tree:
                    c.execute('UPDATE graph_node SET ptc = ? WHERE pkey = ?;',
                            (idx, i[2]))
        else:
            y_list.append(0)

    x_min=min(xs)
    y_min=min(ys)
    x_max=max(xs)
    y_max=max(ys)

    num_padding = 0
    capacity = 0
    for chan, channel_model in x_channel_models.items():
        for ptc, start, end in channel_model.fill_empty(x_min, x_max):
            assert ptc < x_list[chan]

            num_padding += 1
            c.execute("""
INSERT INTO graph_node(
  graph_node_type, x_low, x_high, y_low,
  y_high, capacity, ptc
)
VALUES
  (?, ?, ?, ?, ?, ?, ?);
                """, (graph2.NodeType.CHANX.value, start, end, chan, chan, capacity, ptc))

    for chan, channel_model in y_channel_models.items():
        for ptc, start, end in channel_model.fill_empty(y_min, y_max):
            assert ptc < y_list[chan]

            num_padding += 1
            c.execute("""
INSERT INTO graph_node(
  graph_node_type, x_low, x_high, y_low,
  y_high, capacity, ptc
)
VALUES
  (?, ?, ?, ?, ?, ?, ?);
                """, (graph2.NodeType.CHANY.value, chan, chan, start, end, capacity, ptc))

    print('Number padding nodes {}'.format(num_padding))

    c.execute("""
    INSERT INTO channel(chan_width_max, x_min, x_max, y_min, y_max) VALUES
        (?, ?, ?, ?, ?);""", (
            max(max(x_list), max(y_list)),
            x_min, x_max, y_min, y_max))

    for idx, info in enumerate(x_list):
        c.execute("""
        INSERT INTO x_list(idx, info) VALUES (?, ?);""", (idx, info))

    for idx, info in enumerate(y_list):
        c.execute("""
        INSERT INTO y_list(idx, info) VALUES (?, ?);""", (idx, info))

    c.execute("""COMMIT TRANSACTION;""")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument(
            '--db_root', required=True, help='Project X-Ray Database')
    parser.add_argument(
            '--connection_database', help='Database of fabric connectivity', required=True)
    parser.add_argument(
            '--pin_assignments', help='Pin assignments JSON', required=True)
    parser.add_argument(
            '--synth_tiles', help='If using an ROI, synthetic tile defintion from prjxray-arch-import')

    args = parser.parse_args()

    pool = multiprocessing.Pool(20)

    db = prjxray.db.Database(args.db_root)
    grid = db.grid()
    conn = sqlite3.connect(args.connection_database)

    with open(args.pin_assignments) as f:
        pin_assignments = json.load(f)

    tile_wires = []
    for tile_type, wire_map in pin_assignments['pin_directions'].items():
        for wire in wire_map.keys():
            tile_wires.append((tile_type, wire))

    for tile_type, wire in progressbar.progressbar(tile_wires):
        pins = [direction_to_enum(pin)
                for pin in pin_assignments['pin_directions'][tile_type][wire]]
        add_graph_nodes_for_pins(conn, tile_type, wire, pins)

    if args.synth_tiles:
        use_roi = True
        with open(args.synth_tiles) as f:
            synth_tiles = json.load(f)

        roi = Roi(
                db=db,
                x1=synth_tiles['info']['GRID_X_MIN'],
                y1=synth_tiles['info']['GRID_Y_MIN'],
                x2=synth_tiles['info']['GRID_X_MAX'],
                y2=synth_tiles['info']['GRID_Y_MAX'],
                )

        print('{} generating routing graph for ROI.'.format(now()))
    else:
        use_roi = False

    output_only_nodes = set()
    input_only_nodes = set()

    find_pip = create_find_pip(conn)
    find_wire = create_find_wire(conn)
    find_connector = create_find_connector(conn)

    print('{} Finding nodes belonging to ROI'.format(now()))
    if use_roi:
        for loc in progressbar.progressbar(grid.tile_locations()):
            gridinfo = grid.gridinfo_at_loc(loc)
            tile_name = grid.tilename_at_loc(loc)

            if tile_name in synth_tiles['tiles']:
                assert len(synth_tiles['tiles'][tile_name]['pins']) == 1
                for pin in synth_tiles['tiles'][tile_name]['pins']:
                    _, _, node_pkey = find_wire(tile_name, gridinfo.tile_type,
                            pin['wire'])

                    if pin['port_type'] == 'input':
                        # This track can output be used as a sink.
                        input_only_nodes |= set((node_pkey,))
                    elif pin['port_type'] == 'output':
                        # This track can output be used as a src.
                        output_only_nodes |= set((node_pkey,))
                    else:
                        assert False, pin

    c = conn.cursor()
    c.execute('SELECT pkey FROM switch WHERE name = ?;', ('routing',))
    switch_pkey = c.fetchone()[0]

    edges = []

    edge_set = set()

    for loc in progressbar.progressbar(grid.tile_locations()):
        gridinfo = grid.gridinfo_at_loc(loc)
        tile_name = grid.tilename_at_loc(loc)

        # Not a synth node, check if in ROI.
        if use_roi and not roi.tile_in_roi(loc):
            continue


        tile_type = db.get_tile_type(gridinfo.tile_type)

        for pip in tile_type.get_pips():
            if pip.is_pseudo:
                continue

            if not pip.is_directional:
                # TODO: Handle bidirectional pips?
                continue

            connections = make_connection(
                    conn=conn,
                    input_only_nodes=input_only_nodes,
                    output_only_nodes=output_only_nodes,
                    find_pip=find_pip,
                    find_wire=find_wire,
                    find_connector=find_connector,
                    tile_name=tile_name,
                    loc=loc,
                    tile_type=gridinfo.tile_type,
                    pip=pip,
                    switch_pkey=switch_pkey)
            if connections:
                # TODO: Skip duplicate connections, until they have unique
                # switches
                for connection in connections:
                    key = tuple(connection[0:3])
                    if key in edge_set:
                        continue

                    edge_set.add(key)

                    edges.append(connection)

    print('{} Created {} edges, inserting'.format(now(), len(edges)))

    c.execute("""BEGIN EXCLUSIVE TRANSACTION;""")
    for edge in progressbar.progressbar(edges):
        c.execute("""
                INSERT INTO graph_edge(
                    src_graph_node_pkey, dest_graph_node_pkey, switch_pkey,
                    tile_pkey, pip_in_tile_pkey)  VALUES (?, ?, ?, ?, ?)""",
                    edge)

    c.execute("""COMMIT TRANSACTION;""")

    print('{} Inserted edges'.format(now()))

    c.execute("""CREATE INDEX src_node_index ON graph_edge(src_graph_node_pkey);""")
    c.execute("""CREATE INDEX dest_node_index ON graph_edge(dest_graph_node_pkey);""")
    c.connection.commit()

    print('{} Indices created, marking track liveness'.format(now()))
    mark_track_liveness(conn, pool, input_only_nodes, output_only_nodes)

if __name__ == '__main__':
    main()
