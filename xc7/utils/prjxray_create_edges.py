#!/usr/bin/env python3
""" Creates graph nodes and edges in connection database.

For ROI configurations, pips that would intefer with the ROI are not emitted,
and connections that lies outside the ROI are ignored.

Rough structure:

Add graph_nodes for all IPIN's and OPIN's in the grid based on pin assignments.

Collect tracks used by the ROI (if in used) to prevent tracks from being used
twice.

Make graph edges based on pips in every tile.

Compute which routing tracks are alive based on whether they have at least one
edge that sinks and one edge that sources the routing node.

Build final channels based on alive tracks and insert dummy CHANX or CHANY to
fill empty spaces.  This is required by VPR to allocate the right data.

"""

import argparse
import prjxray.db
from prjxray.roi import Roi
from prjxray import grid_types
import simplejson as json
from lib import progressbar_utils
import datetime
import functools
from collections import namedtuple
from lib.rr_graph import tracks
from lib.rr_graph import graph2
from prjxray.site_type import SitePinDirection
from prjxray_constant_site_pins import yield_ties_to_wire
from lib.connection_database import get_track_model, get_wire_in_tile_from_pin_name
from lib.rr_graph.graph2 import NodeType
import multiprocessing

from prjxray_db_cache import DatabaseCache

now = datetime.datetime.now


def add_graph_nodes_for_pins(conn, tile_type, wire, pin_directions):
    """ Adds graph_node rows for each pin on a wire in a tile. """

    (wire_in_tile_pkeys, site_pin_pkey) = get_wire_in_tile_from_pin_name(
        conn=conn, tile_type_str=tile_type, wire_str=wire
    )

    # Determine if this should be an IPIN or OPIN based on the site_pin
    # direction.
    c = conn.cursor()
    c.execute(
        """
        SELECT direction FROM site_pin WHERE pkey = ?;""", (site_pin_pkey, )
    )
    (pin_direction, ) = c.fetchone()

    pin_direction = SitePinDirection(pin_direction)
    if pin_direction == SitePinDirection.IN:
        node_type = NodeType.IPIN
    elif pin_direction == SitePinDirection.OUT:
        node_type = NodeType.OPIN
    # FIXME: Support INOUT pins
    elif pin_direction == SitePinDirection.INOUT:
        node_type = NodeType.OPIN
    else:
        assert False, pin_direction

    write_cur = conn.cursor()
    write_cur.execute("""BEGIN EXCLUSIVE TRANSACTION;""")

    for wire_in_tile_pkey in wire_in_tile_pkeys.values():
        # Find all instances of this specific wire.
        c.execute(
            """
            SELECT pkey, node_pkey, tile_pkey
                FROM wire WHERE wire_in_tile_pkey = ?;""",
            (wire_in_tile_pkey, )
        )

        c3 = conn.cursor()

        for wire_pkey, node_pkey, tile_pkey in c:
            c3.execute(
                """
                SELECT grid_x, grid_y FROM tile WHERE pkey = ?;""",
                (tile_pkey, )
            )

            grid_x, grid_y = c3.fetchone()

            updates = []
            values = []

            # Insert a graph_node per pin_direction.
            for pin_direction in pin_directions:
                write_cur.execute(
                    """
                INSERT INTO graph_node(
                    graph_node_type, node_pkey, x_low, x_high, y_low, y_high)
                    VALUES (?, ?, ?, ?, ?, ?)""", (
                        node_type.value,
                        node_pkey,
                        grid_x,
                        grid_x,
                        grid_y,
                        grid_y,
                    )
                )

                updates.append(
                    '{}_graph_node_pkey = ?'.format(
                        pin_direction.name.lower()
                    )
                )
                values.append(write_cur.lastrowid)

            # Update the wire with the graph_nodes in each direction, if
            # applicable.
            write_cur.execute(
                """
                UPDATE wire SET {updates} WHERE pkey = ?;""".format(
                    updates=','.join(updates)
                ), values + [wire_pkey]
            )

    write_cur.execute("""COMMIT TRANSACTION;""")
    write_cur.connection.commit()


def create_find_pip(conn):
    """Returns a function that takes (tile_type, pip) and returns a tuple
     containing: pip_in_tile_pkey, is_directional, is_pseudo, can_invert"""
    c = conn.cursor()

    @functools.lru_cache(maxsize=None)
    def find_pip(tile_type, pip):
        c.execute(
            """
SELECT
  pkey, is_directional, is_pseudo, can_invert
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
  );""", (pip, tile_type)
        )

        result = c.fetchone()
        assert result is not None, (tile_type, pip)
        return result

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
        c.execute(
            """
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
  );""", (wire, tile_type)
        )

        result = c.fetchone()
        assert result is not None, (tile_type, wire)
        return result[0]

    @functools.lru_cache(maxsize=None)
    def find_wire(phy_tile, tile_type, wire):
        """ Finds a wire in the database.

        Args:
            phy_tile (str): Physical tile name
            tile_type (str): Type of tile name
            wire (str): Wire name

        Returns:
            Tuple (wire_pkey, phy_tile_pkey, node_pkey), where:
                wire_pkey (int): Primary key of wire table
                tile_pkey (int): Primary key of VPR tile row that contains
                    this wire.
                phy_tile_pkey (int): Primary key of physical tile row that
                    contains this wire.
                node_pkey (int): Primary key of node table that is the node
                    this wire belongs too.
        """

        wire_in_tile_pkey = find_wire_in_tile(tile_type, wire)
        c.execute(
            """
SELECT
  pkey,
  tile_pkey,
  phy_tile_pkey,
  node_pkey
FROM
  wire
WHERE
  wire_in_tile_pkey = ?
  AND phy_tile_pkey = (
    SELECT
      pkey
    FROM
      phy_tile
    WHERE
      name = ?
  );""", (wire_in_tile_pkey, phy_tile)
        )

        result = c.fetchone()
        assert result is not None, (
            phy_tile, tile_type, wire, wire_in_tile_pkey
        )
        return result

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

    def __init__(self, conn, pins=None, tracks=None):
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
        self.conn = conn
        self.pins = pins
        self.tracks = tracks
        assert (self.pins is not None) ^ (self.tracks is not None)

    def get_pip_switch(
            self, src_wire_pkey, pip_pkey, dest_wire_pkey, switch_pkey
    ):
        """ Return the switch_pkey for the given connection.

        Selects either normal or backward switch from pip, or if switch is
        already known, returns known switch.

        It is not valid to provide a switch and provide src/dest/pip arguments.

        Arguments
        ---------
        src_wire_pkey : int
            Source wire row primary key.  May be None if switch_pkey is not
            None.
        pip_pkey : int
            Pip connecting source to destination wire.  May be None if
            switch_pkey is not None.
        dest_wire_pkey : int
            Destination wire row primary key.  May be None if switch_pkey
            is not None.
        switch_pkey : int
            Switch row primary key, can be used if switch_pkey is already
            known (e.g. synthetic edge).  If switch_pkey is not None, other
            arguments should be None to avoid ambiguity.

        Returns
        -------
        Switch row primary key to connect through specified pip.

        """
        if switch_pkey is not None:
            # Handle cases where the switch is supplied, rather than looked up.
            assert src_wire_pkey is None
            assert dest_wire_pkey is None
            assert pip_pkey is None
            return switch_pkey
        else:
            assert switch_pkey is None

        cur = self.conn.cursor()

        cur.execute(
            """
SELECT
  src_wire_in_tile_pkey,
  dest_wire_in_tile_pkey,
  switch_pkey,
  backward_switch_pkey
FROM
  pip_in_tile
WHERE
  pkey = ?""", (pip_pkey, )
        )
        pip_src_wire_in_tile_pkey, pip_dest_wire_in_tile_pkey, switch_pkey, backward_switch_pkey = cur.fetchone(
        )

        cur.execute(
            "SELECT wire_in_tile_pkey FROM wire WHERE pkey = ?",
            (src_wire_pkey, )
        )
        src_wire_in_tile_pkey = cur.fetchone()[0]

        cur.execute(
            "SELECT wire_in_tile_pkey FROM wire WHERE pkey = ?",
            (dest_wire_pkey, )
        )
        dest_wire_in_tile_pkey = cur.fetchone()[0]

        if src_wire_in_tile_pkey == pip_src_wire_in_tile_pkey:
            assert dest_wire_in_tile_pkey == pip_dest_wire_in_tile_pkey
            return switch_pkey
        else:
            assert src_wire_in_tile_pkey == pip_dest_wire_in_tile_pkey
            assert dest_wire_in_tile_pkey == pip_src_wire_in_tile_pkey
            return backward_switch_pkey

    def find_wire_node(
            self, wire_pkey, graph_node_pkey, track_graph_node_pkey
    ):
        """ Find/create graph node for site pin.

        In order to support site pin timing modelling, an additional node
        is required to support the timing model.  This function returns that
        node, along with the switch that should be used to connect the
        IPIN/OPIN to that node. See diagram for details.

        Arguments
        ---------
        wire_pkey : int
            Wire primary key to a wire attached to a site pin.
        graph_node_pkey : int
            Graph node primary key that represents which IPIN/OPIN node is
            being used to connect the site pin to the routing graph.
        track_graph_node_pkey : int
            Graph node primary key that represents the first routing node this
            site pin connects too.  See diagram for details.

        Returns
        -------
        site_pin_switch_pkey : int
            Switch primary key to the switch to connect IPIN/OPIN node to
            new site pin wire node.  See diagram for details.
        site_pin_graph_node_pkey : int
            Graph node primary key that represents site pin wire node.
            See diagram for details.

        Diagram:

           --+
             |    tile wire #1  +-----+ tile wire #2
             +==>-------------->+ pip +--------------->
             | ^-Site pin       +-----+
           --+

            +----+           +-----+            +-----+
            |OPIN+--edge #1->+CHAN1+--edge #2-->+CHAN2|->
            +----+           +-----+            +-----+

        The timing information from the site pin is encoded in edge #1.
        The timing information from tile wire #1 is encoded in CHAN1.
        The timing information from pip is encoded in edge #2.
        The remaining timing information is encoded in edges and channels
        as expected.

        This function returns edge #1 as the site_pin_switch_pkey.
        This function returns CHAN1 as site_pin_graph_node_pkey.

        The diagram for an IPIN is the same, except reverse all the arrows.

        """
        cur = self.conn.cursor()

        cur.execute(
            """
SELECT
    node_pkey,
    top_graph_node_pkey,
    bottom_graph_node_pkey,
    right_graph_node_pkey,
    left_graph_node_pkey,
    site_pin_graph_node_pkey
FROM wire WHERE pkey = ?""", (wire_pkey, )
        )
        values = cur.fetchone()
        node_pkey = values[0]
        edge_nodes = values[1:5]
        site_pin_graph_node_pkey = values[5]

        cur.execute(
            """
SELECT
  site_pin_switch_pkey
FROM
  wire_in_tile
WHERE
  pkey = (
    SELECT
      wire_in_tile_pkey
    FROM
      wire
    WHERE
      pkey = ?
  )""", (wire_pkey, )
        )
        site_pin_switch_pkey = cur.fetchone()[0]

        assert graph_node_pkey in edge_nodes

        if site_pin_graph_node_pkey is None:
            capacitance = 0
            resistance = 0
            for wire_cap, wire_res in cur.execute("""
SELECT wire_in_tile.capacitance, wire_in_tile.resistance
FROM wire_in_tile
WHERE pkey IN (
    SELECT wire_in_tile_pkey FROM wire WHERE node_pkey = ?
)""", (node_pkey, )):
                capacitance += wire_cap
                resistance + wire_res

            # This node does not exist, create it now
            write_cur = self.conn.cursor()

            write_cur.execute("INSERT INTO track DEFAULT VALUES")
            new_track_pkey = write_cur.lastrowid

            write_cur.execute(
                """
INSERT INTO
    graph_node(
        graph_node_type,
        node_pkey,
        x_low,
        x_high,
        y_low,
        y_high,
        capacity,
        capacitance,
        resistance,
        track_pkey)
SELECT
    graph_node_type,
    ?,
    x_low,
    x_high,
    y_low,
    y_high,
    capacity,
    ?,
    ?,
    ?
FROM graph_node WHERE pkey = ?""", (
                    node_pkey,
                    capacitance,
                    resistance,
                    new_track_pkey,
                    track_graph_node_pkey,
                )
            )
            site_pin_graph_node_pkey = write_cur.lastrowid

            write_cur.execute(
                """
UPDATE wire SET site_pin_graph_node_pkey = ?
WHERE pkey = ?""", (
                    site_pin_graph_node_pkey,
                    wire_pkey,
                )
            )

            write_cur.connection.commit()

        return site_pin_switch_pkey, site_pin_graph_node_pkey

    def get_edge_with_mux_switch(
            self, src_wire_pkey, pip_pkey, dest_wire_pkey
    ):
        """ Return switch_pkey for EDGE_WITH_MUX instance. """
        cur = self.conn.cursor()

        cur.execute(
            """
SELECT site_wire_pkey FROM node WHERE pkey = (
    SELECT node_pkey FROM wire WHERE pkey = ?
    );""", (src_wire_pkey, )
        )
        src_site_wire_pkey = cur.fetchone()[0]

        cur.execute(
            """
SELECT site_wire_pkey FROM node WHERE pkey = (
    SELECT node_pkey FROM wire WHERE pkey = ?
    );""", (dest_wire_pkey, )
        )
        dest_site_wire_pkey = cur.fetchone()[0]

        cur.execute(
            """
SELECT switch_pkey FROM edge_with_mux WHERE
    src_wire_pkey = ?
AND
    dest_wire_pkey = ?
AND
    pip_in_tile_pkey = ?""", (
                src_site_wire_pkey,
                dest_site_wire_pkey,
                pip_pkey,
            )
        )
        result = cur.fetchone()
        assert result is not None, (
            src_site_wire_pkey,
            dest_site_wire_pkey,
            pip_pkey,
        )
        return result[0]

    def connect_at(
            self,
            loc,
            other_connector,
            src_wire_pkey=None,
            dest_wire_pkey=None,
            pip_pkey=None,
            switch_pkey=None
    ):
        """ Connect two Connector objects at a location within the grid.

        Arguments
        ---------
        loc : prjxray.grid_types.GridLoc
            Location within grid to make connection.
        other_connector : Connector
            Destination connection.
        src_wire_pkey : int
            Source wire pkey of pip being connected.  Must be None if
            switch_pkey is not None. Used for switch_pkey lookup if needed.
        dest_wire_pkey : int
            Destination wire pkey of pip being connected.  Must be None if
            switch_pkey is not None. Used for switch_pkey lookup if needed.
        pip_pkey : int
            Pip pkey of pip being connected.  Must be None if switch_pkey is
            not None. Used for switch_pkey lookup if needed.
        switch_pkey : int
            Switch pkey for edge being added.  If None, src_wire_pkey,
            dest_wire_pkey, pip_pkey are used to lookup switch_pkey. If not
            None, switch_pkey is used as the switch along the edge.
            Must be None if src_wire_pkey/dest_wire_pkey/pip_pkey is not None.

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
            for idx2, _ in other_tracks_model.get_tracks_for_wire_at_coord(loc
                                                                           ):
                break

            assert idx2 is not None

            switch_pkey = self.get_pip_switch(
                src_wire_pkey, pip_pkey, dest_wire_pkey, switch_pkey
            )

            yield graph_nodes[idx1], switch_pkey, other_graph_nodes[idx2]
            return
        elif self.pins and other_connector.tracks:
            assert self.pins.site_pin_direction == SitePinDirection.OUT
            assert self.pins.x == loc.grid_x
            assert self.pins.y == loc.grid_y

            tracks_model, graph_nodes = other_connector.tracks
            for idx, pin_dir in tracks_model.get_tracks_for_wire_at_coord(loc):
                if pin_dir in self.pins.edge_map:
                    # Site pin -> Interconnect is modelled as:
                    #
                    # OPIN -> edge (Site pin) -> Wire CHAN -> edge (PIP) -> Interconnect CHAN node
                    #
                    src_node = self.pins.edge_map[pin_dir]
                    dest_track_node = graph_nodes[idx]
                    site_pin_switch_pkey, src_wire_node = self.find_wire_node(
                        src_wire_pkey, src_node, dest_track_node
                    )

                    switch_pkey = self.get_pip_switch(
                        src_wire_pkey, pip_pkey, dest_wire_pkey, switch_pkey
                    )
                    yield (src_node, site_pin_switch_pkey, src_wire_node)
                    yield (src_wire_node, switch_pkey, dest_track_node)
                    return
        elif self.tracks and other_connector.pins:
            assert other_connector.pins.site_pin_direction == SitePinDirection.IN
            assert other_connector.pins.x == loc.grid_x
            assert other_connector.pins.y == loc.grid_y

            tracks_model, graph_nodes = self.tracks
            for idx, pin_dir in tracks_model.get_tracks_for_wire_at_coord(loc):
                if pin_dir in other_connector.pins.edge_map:
                    # Interconnect -> Site pin is modelled as:
                    #
                    # Interconnect CHAN node -> edge (PIP) -> Wire CHAN -> edge (Site pin) -> IPIN
                    #
                    src_track_node = graph_nodes[idx]
                    dest_node = other_connector.pins.edge_map[pin_dir]
                    site_pin_switch_pkey, dest_wire_node = self.find_wire_node(
                        dest_wire_pkey, dest_node, src_track_node
                    )

                    switch_pkey = self.get_pip_switch(
                        src_wire_pkey, pip_pkey, dest_wire_pkey, switch_pkey
                    )
                    yield (src_track_node, switch_pkey, dest_wire_node)
                    yield (dest_wire_node, site_pin_switch_pkey, dest_node)
                    return

        elif self.pins and other_connector.pins:
            assert self.pins.site_pin_direction == SitePinDirection.OUT
            assert other_connector.pins.site_pin_direction == SitePinDirection.IN

            switch_pkey = self.get_edge_with_mux_switch(
                src_wire_pkey, pip_pkey, dest_wire_pkey
            )

            if len(self.pins.edge_map) == 1 and len(
                    other_connector.pins.edge_map) == 1:
                # If there is only one choice, make it.
                src_node = list(self.pins.edge_map.values())[0]
                dest_node = list(other_connector.pins.edge_map.values())[0]

                yield (src_node, switch_pkey, dest_node)
                return

            for pin_dir in self.pins.edge_map:
                if OPPOSITE_DIRECTIONS[pin_dir
                                       ] in other_connector.pins.edge_map:
                    src_node = self.pins.edge_map[pin_dir]
                    dest_node = other_connector.pins.edge_map[
                        OPPOSITE_DIRECTIONS[pin_dir]]
                    yield (src_node, switch_pkey, dest_node)
                    return

        assert False, (
            self.tracks, self.pins, other_connector.tracks,
            other_connector.pins
        )


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
        c.execute(
            """
        SELECT pkey, track_pkey, graph_node_type, x_low, x_high, y_low, y_high FROM graph_node
        WHERE node_pkey = ?;""", (node_pkey, )
        )

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

            return Connector(
                conn=conn, tracks=get_track_model(conn, track_pkey)
            )

        # Check if this node has a special track.  This is being used to
        # denote the GND and VCC track connections on TIEOFF HARD0 and HARD1.
        c.execute(
            """
SELECT
  track_pkey,
  site_wire_pkey
FROM
  node
WHERE
  pkey = ?;""", (node_pkey, )
        )
        for track_pkey, site_wire_pkey in c:
            if track_pkey is not None and site_wire_pkey is not None:
                return Connector(
                    conn=conn, tracks=get_track_model(conn, track_pkey)
                )

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
        c.execute(
            """
SELECT
  top_graph_node_pkey,
  bottom_graph_node_pkey,
  left_graph_node_pkey,
  right_graph_node_pkey
FROM
  wire
WHERE
  node_pkey = ?;""", (node_pkey, )
        )

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
            ),
                graph_node_pkeys,
        ):
            if graph_node is not None:
                edge_map[edge] = graph_node

        assert len(edge_map) == len(graph_nodes), (
            edge_map, graph_node_pkeys, graph_nodes
        )

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

        return Connector(
            conn=conn,
            pins=Pins(
                edge_map=edge_map,
                x=x,
                y=y,
                site_pin_direction=site_pin_direction,
            )
        )

    return find_connector


def create_const_connectors(conn):
    c = conn.cursor()
    c.execute(
        """
SELECT vcc_track_pkey, gnd_track_pkey FROM constant_sources;
    """
    )
    vcc_track_pkey, gnd_track_pkey = c.fetchone()

    const_connectors = {}
    const_connectors[0] = Connector(
        conn=conn, tracks=get_track_model(conn, gnd_track_pkey)
    )
    const_connectors[1] = Connector(
        conn=conn, tracks=get_track_model(conn, vcc_track_pkey)
    )

    return const_connectors


def make_connection(
        conn, input_only_nodes, output_only_nodes, find_wire, find_pip,
        find_connector, tile_name, tile_type, pip, delayless_switch_pkey,
        const_connectors
):
    """ Attempt to connect graph nodes on either side of a pip.

    Args:
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
            phy_tile_pkey (int) - Primary key into table of parent physical
                tile of the pip.
            pip_pkey (int) - Primary key into pip_in_tile table for this pip.

    """

    src_wire_pkey, tile_pkey, phy_tile_pkey, src_node_pkey = find_wire(
        tile_name, tile_type, pip.net_from
    )
    sink_wire_pkey, tile_pkey2, phy_tile_pkey2, sink_node_pkey = find_wire(
        tile_name, tile_type, pip.net_to
    )

    assert phy_tile_pkey == phy_tile_pkey2
    assert tile_pkey == tile_pkey2

    c = conn.cursor()
    c.execute("SELECT grid_x, grid_y FROM tile WHERE pkey = ?", (tile_pkey, ))
    loc = grid_types.GridLoc(*c.fetchone())

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

    pip_pkey, pip_is_directional, pip_is_pseudo, pip_can_invert = \
        find_pip(tile_type, pip.name)

    assert not pip_is_pseudo

    for src_graph_node_pkey, switch_pkey, dest_graph_node_pkey in src_connector.connect_at(
            pip_pkey=pip_pkey, src_wire_pkey=src_wire_pkey,
            dest_wire_pkey=sink_wire_pkey, loc=loc,
            other_connector=sink_connector):
        yield (
            src_graph_node_pkey, dest_graph_node_pkey, switch_pkey,
            phy_tile_pkey, pip_pkey, False
        )

    if not pip_is_directional:
        for src_graph_node_pkey, switch_pkey, dest_graph_node_pkey in sink_connector.connect_at(
                pip_pkey=pip_pkey, src_wire_pkey=sink_wire_pkey,
                dest_wire_pkey=src_wire_pkey, loc=loc,
                other_connector=src_connector):
            yield (
                src_graph_node_pkey, dest_graph_node_pkey, switch_pkey,
                phy_tile_pkey, pip_pkey, True
            )

    # Make additional connections to constant network if the sink needs it.
    for constant_src in yield_ties_to_wire(pip.net_to):
        for src_graph_node_pkey, switch_pkey, dest_graph_node_pkey in const_connectors[
                constant_src].connect_at(switch_pkey=delayless_switch_pkey,
                                         loc=loc,
                                         other_connector=sink_connector):
            yield (
                src_graph_node_pkey, dest_graph_node_pkey, switch_pkey,
                phy_tile_pkey, None, False
            )


def mark_track_liveness(
        conn, pool, input_only_nodes, output_only_nodes, alive_tracks
):
    """ Checks tracks for liveness.

    Iterates over all graph nodes that are routing tracks and determines if
    at least one graph edge originates from or two the track.

    Args:
        conn (sqlite3.Connection): Connection database

    """

    c = conn.cursor()
    write_cur = conn.cursor()
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

        write_cur.execute(
            """SELECT count(switch_pkey) FROM graph_edge WHERE
            src_graph_node_pkey = ?;""", (graph_node_pkey, )
        )
        src_count = write_cur.fetchone()[0]

        write_cur.execute(
            """SELECT count(switch_pkey) FROM graph_edge WHERE
            dest_graph_node_pkey = ?;""", (graph_node_pkey, )
        )
        sink_count = write_cur.fetchone()[0]

        if src_count > 0 and sink_count > 0:
            alive_tracks.add(track_pkey)

    c.execute("SELECT count(pkey) FROM track;")
    track_count = c.fetchone()[0]
    print(
        "{} Alive tracks {} / {}".format(
            now(), len(alive_tracks), track_count
        )
    )

    write_cur.execute("""BEGIN EXCLUSIVE TRANSACTION;""")
    for (track_pkey, ) in c.execute("""SELECT pkey FROM track;"""):
        write_cur.execute(
            "UPDATE track SET alive = ? WHERE pkey = ?;",
            (track_pkey in alive_tracks, track_pkey)
        )
    write_cur.execute("""COMMIT TRANSACTION;""")

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
    write_cur = conn.cursor()

    xs = []
    ys = []

    x_tracks = {}
    y_tracks = {}
    for pkey, track_pkey, graph_node_type, x_low, x_high, y_low, y_high in write_cur.execute(
            """
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

        xs.append(x_low)
        xs.append(x_high)
        ys.append(y_low)
        ys.append(y_high)

        node_type = graph2.NodeType(graph_node_type)
        if node_type == graph2.NodeType.CHANX:
            assert y_low == y_high, (pkey, track_pkey)

            if y_low not in x_tracks:
                x_tracks[y_low] = []

            x_tracks[y_low].append((x_low, x_high, pkey))
        elif node_type == graph2.NodeType.CHANY:
            assert x_low == x_high, (pkey, track_pkey)

            if x_low not in y_tracks:
                y_tracks[x_low] = []

            y_tracks[x_low].append((y_low, y_high, pkey))
        else:
            assert False, node_type

    x_list = []
    y_list = []

    x_channel_models = {}
    y_channel_models = {}

    for y in x_tracks:
        x_channel_models[y] = pool.apply_async(
            graph2.process_track, (x_tracks[y], )
        )

    for x in y_tracks:
        y_channel_models[x] = pool.apply_async(
            graph2.process_track, (y_tracks[x], )
        )

    write_cur.execute("""BEGIN EXCLUSIVE TRANSACTION;""")

    for y in progressbar_utils.progressbar(range(max(x_tracks) + 1)):
        if y in x_tracks:
            x_channel_models[y] = x_channel_models[y].get()

            x_list.append(len(x_channel_models[y].trees))

            for idx, tree in enumerate(x_channel_models[y].trees):
                for i in tree:
                    write_cur.execute(
                        'UPDATE graph_node SET ptc = ? WHERE pkey = ?;',
                        (idx, i[2])
                    )
        else:
            x_list.append(0)

    for x in progressbar_utils.progressbar(range(max(y_tracks) + 1)):
        if x in y_tracks:
            y_channel_models[x] = y_channel_models[x].get()

            y_list.append(len(y_channel_models[x].trees))

            for idx, tree in enumerate(y_channel_models[x].trees):
                for i in tree:
                    write_cur.execute(
                        'UPDATE graph_node SET ptc = ? WHERE pkey = ?;',
                        (idx, i[2])
                    )
        else:
            y_list.append(0)

    x_min = min(xs)
    y_min = min(ys)
    x_max = max(xs)
    y_max = max(ys)

    write_cur.execute(
        """
    INSERT INTO channel(chan_width_max, x_min, x_max, y_min, y_max) VALUES
        (?, ?, ?, ?, ?);""",
        (max(max(x_list), max(y_list)), x_min, x_max, y_min, y_max)
    )

    for idx, info in enumerate(x_list):
        write_cur.execute(
            """
        INSERT INTO x_list(idx, info) VALUES (?, ?);""", (idx, info)
        )

    for idx, info in enumerate(y_list):
        write_cur.execute(
            """
        INSERT INTO y_list(idx, info) VALUES (?, ?);""", (idx, info)
        )

    write_cur.execute("""COMMIT TRANSACTION;""")


def verify_channels(conn, alive_tracks):
    """ Verify PTC numbers in channels.
    No duplicate PTC's.

    Violation of this requirement results in a check failure during rr graph
    loading.

    """

    c = conn.cursor()

    chan_ptcs = {}

    for (graph_node_pkey, track_pkey, graph_node_type, x_low, x_high, y_low,
         y_high, ptc, capacity) in c.execute(
             """
    SELECT pkey, track_pkey, graph_node_type, x_low, x_high, y_low, y_high, ptc, capacity FROM
        graph_node WHERE (graph_node_type = ? or graph_node_type = ?);""",
             (graph2.NodeType.CHANX.value, graph2.NodeType.CHANY.value)):

        if track_pkey not in alive_tracks and capacity != 0:
            assert ptc is None, graph_node_pkey
            continue

        assert ptc is not None, graph_node_pkey

        for x in range(x_low, x_high + 1):
            for y in range(y_low, y_high + 1):
                key = (graph_node_type, x, y)
                if key not in chan_ptcs:
                    chan_ptcs[key] = []

                chan_ptcs[key].append((graph_node_pkey, ptc))

    for key in chan_ptcs:
        ptcs = {}
        for graph_node_pkey, ptc in chan_ptcs[key]:
            assert ptc not in ptcs, (ptcs[ptc], graph_node_pkey)
            ptcs[ptc] = graph_node_pkey


def print_node(conn, node_pkey):
    cur = conn.cursor()
    cur2 = conn.cursor()
    cur.execute(
        """SELECT pkey FROM wire WHERE node_pkey = ?
        """, (node_pkey, )
    )
    for (wire_pkey, ) in cur:
        cur2.execute(
            """SELECT name FROM wire_in_tile WHERE pkey = (
            SELECT wire_in_tile_pkey FROM wire WHERE pkey = ?
            )""", (wire_pkey, )
        )
        wire_name = cur2.fetchone()[0]

        cur2.execute(
            """SELECT name FROM phy_tile WHERE pkey = (
            SELECT phy_tile_pkey FROM wire WHERE pkey = ?
            )""", (wire_pkey, )
        )
        tile_name = cur2.fetchone()[0]
        print(' {}/{}'.format(tile_name, wire_name))


def print_graph_node(conn, graph_node_pkey):
    cur = conn.cursor()
    cur2 = conn.cursor()
    cur.execute(
        """SELECT pkey FROM wire WHERE node_pkey = (
        SELECT node_pkey FROM graph_node WHERE pkey = ?
        )""", (graph_node_pkey, )
    )
    for (wire_pkey, ) in cur:
        cur2.execute(
            """SELECT name FROM wire_in_tile WHERE pkey = (
            SELECT wire_in_tile_pkey FROM wire WHERE pkey = ?
            )""", (wire_pkey, )
        )
        wire_name = cur2.fetchone()[0]

        cur2.execute(
            """SELECT name FROM phy_tile WHERE pkey = (
            SELECT phy_tile_pkey FROM wire WHERE pkey = ?
            )""", (wire_pkey, )
        )
        tile_name = cur2.fetchone()[0]
        print(' {}/{}'.format(tile_name, wire_name))


def set_pin_connection(
        conn, write_cur, pin_graph_node_pkey, forward, graph_node_pkey, tracks
):
    """ Sets pin connection box location canonical location.

    Tracks that are a part of the pinfeed also get this location.

    """
    cur = conn.cursor()
    cur2 = conn.cursor()
    cur.execute(
        """SELECT node_pkey, graph_node_type FROM graph_node WHERE pkey = ?""",
        (pin_graph_node_pkey, )
    )
    pin_node_pkey, graph_node_type = cur.fetchone()

    source_wires = []
    cur.execute(
        """SELECT pkey FROM wire WHERE node_pkey = (
        SELECT node_pkey FROM graph_node WHERE pkey = ?
        )""", (graph_node_pkey, )
    )
    for (wire_pkey, ) in cur:
        if forward:
            cur2.execute(
                """SELECT count() FROM pip_in_tile WHERE src_wire_in_tile_pkey = (
                SELECT wire_in_tile_pkey FROM wire WHERE pkey = ?
                )""", (wire_pkey, )
            )
        else:
            cur2.execute(
                """SELECT count() FROM pip_in_tile WHERE dest_wire_in_tile_pkey = (
                SELECT wire_in_tile_pkey FROM wire WHERE pkey = ?
                )""", (wire_pkey, )
            )

        has_pip = cur2.fetchone()[0]
        if has_pip:
            source_wires.append(wire_pkey)

    if pin_graph_node_pkey == 2003295:
        print(graph_node_pkey, source_wires)

    assert len(source_wires) <= 1

    if len(source_wires) == 1:
        cur.execute(
            "SELECT phy_tile_pkey FROM wire WHERE pkey = ?",
            (source_wires[0], )
        )
        phy_tile_pkey = cur.fetchone()[0]
        for track_pkey in tracks:
            write_cur.execute(
                "UPDATE track SET canon_phy_tile_pkey = ? WHERE pkey = ?", (
                    phy_tile_pkey,
                    track_pkey,
                )
            )

        if not forward:
            assert NodeType(graph_node_type) == NodeType.IPIN
            source_wire_pkey = source_wires[0]
            write_cur.execute(
                """
UPDATE graph_node SET connection_box_wire_pkey = ? WHERE pkey = ?
            """, (
                    source_wire_pkey,
                    pin_graph_node_pkey,
                )
            )


def walk_and_mark_segment(
        conn, write_cur, graph_node_pkey, forward, segment_pkey, unknown_pkey,
        pin_graph_node_pkey, tracks
):
    cur = conn.cursor()

    cur.execute(
        """SELECT graph_node_type FROM graph_node WHERE pkey = ?""",
        (graph_node_pkey, )
    )
    graph_node_type = NodeType(cur.fetchone()[0])
    if graph_node_type in [NodeType.CHANX, NodeType.CHANY]:
        cur.execute(
            "SELECT track_pkey FROM graph_node WHERE pkey = ?",
            (graph_node_pkey, )
        )
        track_pkey = cur.fetchone()[0]
        assert track_pkey is not None

        cur.execute(
            "SELECT segment_pkey FROM track WHERE pkey = ?", (track_pkey, )
        )
        old_segment_pkey = cur.fetchone()[0]
        if old_segment_pkey == unknown_pkey or old_segment_pkey is None:
            tracks.append(track_pkey)
            write_cur.execute(
                "UPDATE track SET segment_pkey = ? WHERE pkey = ?", (
                    segment_pkey,
                    track_pkey,
                )
            )

    if forward:
        cur.execute(
            """
SELECT dest_graph_node_pkey FROM graph_edge WHERE src_graph_node_pkey = ?
""", (graph_node_pkey, )
        )
        next_nodes = cur.fetchall()
    else:
        cur.execute(
            """
SELECT src_graph_node_pkey FROM graph_edge WHERE dest_graph_node_pkey = ?
""", (graph_node_pkey, )
        )
        next_nodes = cur.fetchall()

    next_node = None
    if len(next_nodes) == 1:
        next_node = next_nodes[0][0]
    elif not forward:
        if pin_graph_node_pkey == 2763252:
            print('graph_node:', graph_node_pkey)
            print('Next_nodes:', next_nodes)

        # Some nodes simply lead to GND/VCC tieoff pins, these should not
        # stop the walk, as they are not relevant to connection box.
        next_non_tieoff_nodes = []
        for (next_graph_node_pkey, ) in next_nodes:
            cur.execute(
                """
SELECT count() FROM constant_sources WHERE
    vcc_track_pkey = (SELECT track_pkey FROM graph_node WHERE pkey = ?)
OR
    gnd_track_pkey = (SELECT track_pkey FROM graph_node WHERE pkey = ?)
    """, (
                    next_graph_node_pkey,
                    next_graph_node_pkey,
                )
            )
            if cur.fetchone()[0] == 0:
                next_non_tieoff_nodes.append(next_graph_node_pkey)

        if pin_graph_node_pkey == 2763252:
            print('Next non TIEOFF nodes:', next_non_tieoff_nodes)

        if len(next_non_tieoff_nodes) == 1:
            next_node = next_non_tieoff_nodes[0]

    if next_node is not None:
        walk_and_mark_segment(
            conn, write_cur, next_node, forward, segment_pkey, unknown_pkey,
            pin_graph_node_pkey, tracks
        )
    else:
        set_pin_connection(
            conn=conn,
            write_cur=write_cur,
            pin_graph_node_pkey=pin_graph_node_pkey,
            forward=forward,
            graph_node_pkey=graph_node_pkey,
            tracks=tracks
        )


def active_graph_node(conn, graph_node_pkey, forward):
    """ Returns true if an edge in the specified direction exists. """
    cur = conn.cursor()

    if forward:
        cur.execute(
            """
SELECT count(*) FROM graph_edge WHERE src_graph_node_pkey = ? LIMIT 1
            """, (graph_node_pkey, )
        )
    else:
        cur.execute(
            """
SELECT count(*) FROM graph_edge WHERE dest_graph_node_pkey = ? LIMIT 1
            """, (graph_node_pkey, )
        )

    return cur.fetchone()[0] > 0


def annotate_pin_feeds(conn):
    """ Identifies and annotates pin feed channels.

    Some channels are simply paths from IPIN's or OPIN's.  Set
    pin_classification to either IPIN_FEED or OPIN_FEED.  During track creation
    if these nodes are not given a specific segment, they will be assigned as
    INPINFEED or OUTPINFEED.
    """
    write_cur = conn.cursor()
    cur = conn.cursor()

    cur.execute("SELECT pkey FROM segment WHERE name = ?", ("unknown", ))
    unknown_pkey = cur.fetchone()[0]

    cur.execute("SELECT pkey FROM segment WHERE name = ?", ("INPINFEED", ))
    inpinfeed_pkey = cur.fetchone()[0]

    cur.execute("SELECT pkey FROM segment WHERE name = ?", ("OUTPINFEED", ))
    outpinfeed_pkey = cur.fetchone()[0]

    write_cur.execute("""BEGIN EXCLUSIVE TRANSACTION;""")

    # Walk from OPIN's first.
    for (graph_node_pkey, node_pkey) in cur.execute("""
SELECT graph_node.pkey, graph_node.node_pkey
FROM graph_node
WHERE graph_node.graph_node_type = ?
        """, (NodeType.OPIN.value, )):
        if not active_graph_node(conn, graph_node_pkey, forward=True):
            continue

        walk_and_mark_segment(
            conn,
            write_cur,
            graph_node_pkey,
            forward=True,
            segment_pkey=outpinfeed_pkey,
            unknown_pkey=unknown_pkey,
            pin_graph_node_pkey=graph_node_pkey,
            tracks=list(),
        )

    # Walk from IPIN's next.
    for (graph_node_pkey, ) in cur.execute("""
SELECT graph_node.pkey
FROM graph_node
WHERE graph_node.graph_node_type = ?
        """, (NodeType.IPIN.value, )):

        if not active_graph_node(conn, graph_node_pkey, forward=False):
            continue

        walk_and_mark_segment(
            conn,
            write_cur,
            graph_node_pkey,
            forward=False,
            segment_pkey=inpinfeed_pkey,
            unknown_pkey=unknown_pkey,
            pin_graph_node_pkey=graph_node_pkey,
            tracks=list(),
        )

    write_cur.execute("""COMMIT TRANSACTION;""")


def set_track_canonical_loc(conn):
    """ For each track, compute a canonical location.

    This canonical location should be consisent across instances of the track
    type.  For example, a 6 length NW should always have a canonical location
    at the SE corner of the the track.

    For bidirection wires (generally long segments), use a consisent 
    canonilization.
    """

    write_cur = conn.cursor()
    cur = conn.cursor()
    cur2 = conn.cursor()
    cur3 = conn.cursor()

    write_cur.execute("""BEGIN EXCLUSIVE TRANSACTION;""")

    cur.execute("SELECT pkey FROM track WHERE alive")
    tracks = cur.fetchall()
    for (track_pkey, ) in progressbar_utils.progressbar(tracks):
        source_wires = []
        for (wire_pkey, ) in cur2.execute("""
SELECT pkey FROM wire WHERE node_pkey IN (
    SELECT pkey FROM node WHERE track_pkey = ?
    )""", (track_pkey, )):
            cur3.execute(
                """
SELECT count(*)
FROM pip_in_tile
WHERE
    dest_wire_in_tile_pkey = (SELECT wire_in_tile_pkey FROM wire WHERE pkey = ?)
LIMIT 1
    """, (wire_pkey, )
            )
            pips_to_wire = cur3.fetchone()[0]
            if pips_to_wire > 0:
                cur3.execute(
                    """
SELECT grid_x, grid_y FROM phy_tile WHERE pkey = (
    SELECT phy_tile_pkey FROM wire WHERE pkey = ?
                    )""", (wire_pkey, )
                )
                grid_x, grid_y = cur3.fetchone()
                source_wires.append(((grid_x, grid_y), wire_pkey))

        if len(source_wires) > 0:
            source_wire_pkey = min(source_wires, key=lambda x: x[0])[1]
            write_cur.execute(
                """
UPDATE track
SET canon_phy_tile_pkey = (SELECT phy_tile_pkey FROM wire WHERE pkey = ?)
WHERE pkey = ?
            """, (source_wire_pkey, track_pkey)
            )

    write_cur.execute("""COMMIT TRANSACTION;""")


def compute_segment_lengths(conn):
    """ Determine segment lengths used for cost normalization. """
    cur = conn.cursor()
    cur2 = conn.cursor()
    cur3 = conn.cursor()
    cur4 = conn.cursor()

    write_cur = conn.cursor()

    write_cur.execute("""BEGIN EXCLUSIVE TRANSACTION;""")

    for (segment_pkey, ) in cur.execute("SELECT pkey FROM segment"):
        segment_length = 1

        # Get all tracks with this segment
        for (track_pkey, src_phy_tile_pkey) in cur2.execute("""
SELECT pkey, canon_phy_tile_pkey FROM track
WHERE
    canon_phy_tile_pkey IS NOT NULL
AND
    segment_pkey = ?
        """, (segment_pkey, )):
            cur4.execute(
                "SELECT grid_x, grid_y FROM phy_tile WHERE pkey = ?",
                (src_phy_tile_pkey, )
            )
            src_x, src_y = cur4.fetchone()

            # Get tiles downstream of this track.
            for (dest_phy_tile_pkey, ) in cur3.execute("""
SELECT DISTINCT canon_phy_tile_pkey FROM track WHERE pkey IN (
    SELECT track_pkey FROM graph_node WHERE pkey IN (
        SELECT dest_graph_node_pkey FROM graph_edge WHERE src_graph_node_pkey = (
            SELECT pkey FROM graph_node WHERE track_pkey = ?
        )
    )
) AND canon_phy_tile_pkey IS NOT NULL
            """, (track_pkey, )):
                if src_phy_tile_pkey == dest_phy_tile_pkey:
                    continue

                cur4.execute(
                    "SELECT grid_x, grid_y FROM phy_tile WHERE pkey = ?",
                    (dest_phy_tile_pkey, )
                )
                dest_x, dest_y = cur4.fetchone()

                segment_length = max(
                    segment_length,
                    abs(dest_x - src_x) + abs(dest_y - src_y)
                )

        write_cur.execute(
            "UPDATE segment SET length = ? WHERE pkey = ?", (
                segment_length,
                segment_pkey,
            )
        )

    write_cur.execute("""COMMIT TRANSACTION;""")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        '--db_root', required=True, help='Project X-Ray Database'
    )
    parser.add_argument(
        '--connection_database',
        help='Database of fabric connectivity',
        required=True
    )
    parser.add_argument(
        '--pin_assignments', help='Pin assignments JSON', required=True
    )
    parser.add_argument(
        '--synth_tiles',
        help='If using an ROI, synthetic tile defintion from prjxray-arch-import'
    )

    args = parser.parse_args()

    pool = multiprocessing.Pool(20)

    db = prjxray.db.Database(args.db_root)
    grid = db.grid()

    with DatabaseCache(args.connection_database) as conn:

        with open(args.pin_assignments) as f:
            pin_assignments = json.load(f)

        tile_wires = []
        for tile_type, wire_map in pin_assignments['pin_directions'].items():
            for wire in wire_map.keys():
                tile_wires.append((tile_type, wire))

        for tile_type, wire in progressbar_utils.progressbar(tile_wires):
            pins = [
                direction_to_enum(pin)
                for pin in pin_assignments['pin_directions'][tile_type][wire]
            ]
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

        const_connectors = create_const_connectors(conn)

        print('{} Finding nodes belonging to ROI'.format(now()))
        if use_roi:
            for loc in progressbar_utils.progressbar(grid.tile_locations()):
                gridinfo = grid.gridinfo_at_loc(loc)
                tile_name = grid.tilename_at_loc(loc)

                if tile_name in synth_tiles['tiles']:
                    assert len(synth_tiles['tiles'][tile_name]['pins']) == 1
                    for pin in synth_tiles['tiles'][tile_name]['pins']:
                        if pin['port_type'] not in ['input', 'output']:
                            continue

                        _, _, _, node_pkey = find_wire(
                            tile_name, gridinfo.tile_type, pin['wire']
                        )

                        if pin['port_type'] == 'input':
                            # This track can output be used as a sink.
                            input_only_nodes |= set((node_pkey, ))
                        elif pin['port_type'] == 'output':
                            # This track can output be used as a src.
                            output_only_nodes |= set((node_pkey, ))
                        else:
                            assert False, pin

        write_cur = conn.cursor()
        write_cur.execute(
            'SELECT pkey FROM switch WHERE name = ?;',
            ('__vpr_delayless_switch__', )
        )
        delayless_switch_pkey = write_cur.fetchone()[0]

        edges = []

        edge_set = set()

        for loc in progressbar_utils.progressbar(grid.tile_locations()):
            gridinfo = grid.gridinfo_at_loc(loc)
            tile_name = grid.tilename_at_loc(loc)

            # Not a synth node, check if in ROI.
            if use_roi and not roi.tile_in_roi(loc):
                continue

            tile_type = db.get_tile_type(gridinfo.tile_type)

            for pip in tile_type.get_pips():
                if pip.is_pseudo:
                    continue

                connections = make_connection(
                    conn=conn,
                    input_only_nodes=input_only_nodes,
                    output_only_nodes=output_only_nodes,
                    find_pip=find_pip,
                    find_wire=find_wire,
                    find_connector=find_connector,
                    tile_name=tile_name,
                    tile_type=gridinfo.tile_type,
                    pip=pip,
                    delayless_switch_pkey=delayless_switch_pkey,
                    const_connectors=const_connectors
                )

                if connections:
                    for connection in connections:
                        key = tuple(connection[0:3])
                        if key in edge_set:
                            continue

                        edge_set.add(key)

                        edges.append(connection)

        print('{} Created {} edges, inserting'.format(now(), len(edges)))

        write_cur.execute("""BEGIN EXCLUSIVE TRANSACTION;""")
        for edge in progressbar_utils.progressbar(edges):
            write_cur.execute(
                """
                INSERT INTO graph_edge(
                    src_graph_node_pkey, dest_graph_node_pkey, switch_pkey,
                    phy_tile_pkey, pip_in_tile_pkey, backward) VALUES (?, ?, ?, ?, ?, ?)""",
                edge
            )

        write_cur.execute("""COMMIT TRANSACTION;""")

        print('{} Inserted edges'.format(now()))

        write_cur.execute(
            """CREATE INDEX src_node_index ON graph_edge(src_graph_node_pkey);"""
        )
        write_cur.execute(
            """CREATE INDEX dest_node_index ON graph_edge(dest_graph_node_pkey);"""
        )
        write_cur.execute(
            """CREATE INDEX node_track_index ON node(track_pkey);"""
        )
        write_cur.connection.commit()

        print('{} Indices created, marking track liveness'.format(now()))

        alive_tracks = set()
        mark_track_liveness(
            conn, pool, input_only_nodes, output_only_nodes, alive_tracks
        )

        print('{} Set track canonical loc'.format(now()))
        set_track_canonical_loc(conn)

        print('{} Annotate pin feeds'.format(now()))
        annotate_pin_feeds(conn)

        print('{} Compute segment lengths'.format(now()))
        compute_segment_lengths(conn)

        print(
            '{} Flushing database back to file "{}"'.format(
                now(), args.connection_database
            )
        )

    with DatabaseCache(args.connection_database, read_only=True) as conn:
        verify_channels(conn, alive_tracks)
        print("{}: Channels verified".format(datetime.datetime.now()))


if __name__ == '__main__':
    main()
