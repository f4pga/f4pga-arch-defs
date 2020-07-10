import prjxray.db
from prjxray.roi import Roi
from prjxray.overlay import Overlay
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
import re
import math
import numpy

from prjxray_db_cache import DatabaseCache

now = datetime.datetime.now


def get_node_type(conn, graph_node_pkey):
    """ Returns the node type of a given graph node"""

    c = conn.cursor()
    c.execute(
        """
        SELECT graph_node_type FROM graph_node WHERE pkey = ?""",
        (graph_node_pkey, )
    )

    return c.fetchone()[0]


def get_pins(conn, site_type, site_pin):
    """ Returns a set of the pin graph_nodes related to the input site type and pin names."""

    c = conn.cursor()
    c.execute(
        """
WITH pins(wire_in_tile_pkey) AS (
  SELECT wire_in_tile.pkey FROM wire_in_tile
  INNER JOIN site_pin ON site_pin.pkey = wire_in_tile.site_pin_pkey
  INNER JOIN site_type ON site_pin.site_type_pkey = site_type.pkey
  WHERE
    site_type.name == ?
  AND
    site_pin.name == ?
)
SELECT graph_node.pkey FROM graph_node
INNER JOIN wire ON graph_node.node_pkey = wire.node_pkey
WHERE
  wire.wire_in_tile_pkey IN (SELECT wire_in_tile_pkey FROM pins);
    """, (
            site_type,
            site_pin,
        )
    )

    return set(graph_node_pkey for (graph_node_pkey, ) in c.fetchall())


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

            assert len(updates) > 0, (updates, wire_in_tile_pkey, wire_pkey)

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


class KnownSwitch(object):
    def __init__(self, switch_pkey):
        self.switch_pkey = switch_pkey

    def get_pip_switch(self, src_wire_pkey, dest_wire_pkey):
        assert src_wire_pkey is None
        assert dest_wire_pkey is None
        return self.switch_pkey


class Pip(object):
    def __init__(self, c, tile_type, pip):
        self.c = c
        c.execute(
            """
SELECT
  pkey,
  src_wire_in_tile_pkey,
  dest_wire_in_tile_pkey,
  switch_pkey,
  backward_switch_pkey,
  is_directional,
  is_pseudo,
  can_invert
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
        (
            self.pip_pkey, self.src_wire_in_tile_pkey,
            self.dest_wire_in_tile_pkey, self.switch_pkey,
            self.backward_switch_pkey, self.is_directional, self.is_pseudo,
            self.can_invert
        ) = result
        assert self.switch_pkey is not None, (pip, tile_type)

        if self.is_directional:
            assert self.switch_pkey == self.backward_switch_pkey

    def __iter__(self):
        yield "pip_pkey", self.pip_pkey
        yield "src_wire_in_tile_pkey", self.src_wire_in_tile_pkey
        yield "dest_wire_in_tile_pkey", self.dest_wire_in_tile_pkey
        yield "switch_pkey", self.switch_pkey
        yield "backward_switch_pkey", self.backward_switch_pkey
        yield "is_directional", self.is_directional
        yield "is_pseudo", self.is_pseudo
        yield "can_invert", self.can_invert

    def get_pip_switch(self, src_wire_pkey, dest_wire_pkey):
        """ Return the switch_pkey for the given connection.

        Selects either normal or backward switch from pip, or if switch is
        already known, returns known switch.

        It is not valid to provide a switch and provide src/dest/pip arguments.

        Arguments
        ---------
        src_wire_pkey : int
            Source wire row primary key.
        dest_wire_pkey : int
            Destination wire row primary key.
        Returns
        -------
        Switch row primary key to connect through specified pip.

        """

        assert src_wire_pkey is not None
        assert dest_wire_pkey is not None

        if self.switch_pkey == self.backward_switch_pkey:
            return self.switch_pkey

        self.c.execute(
            "SELECT wire_in_tile_pkey FROM wire WHERE pkey = ?",
            (src_wire_pkey, )
        )
        src_wire_in_tile_pkey = self.c.fetchone()[0]

        self.c.execute(
            "SELECT wire_in_tile_pkey FROM wire WHERE pkey = ?",
            (dest_wire_pkey, )
        )
        dest_wire_in_tile_pkey = self.c.fetchone()[0]

        if src_wire_in_tile_pkey == self.src_wire_in_tile_pkey:
            assert dest_wire_in_tile_pkey == self.dest_wire_in_tile_pkey
            return self.switch_pkey
        else:
            assert src_wire_in_tile_pkey == self.dest_wire_in_tile_pkey
            assert dest_wire_in_tile_pkey == self.src_wire_in_tile_pkey
            return self.backward_switch_pkey


def create_find_pip(conn):
    """Returns a function that takes (tile_type, pip) and returns a tuple
     containing: pip_in_tile_pkey, is_directional, is_pseudo, can_invert"""
    c = conn.cursor()

    @functools.lru_cache(maxsize=None)
    def find_pip(tile_type, pip):
        return Pip(c, tile_type, pip)

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
  AND phy_tile_type_pkey = (
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

    @functools.lru_cache(maxsize=100000)
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
        self.track_connections = {}
        assert (self.pins is not None) ^ (self.tracks is not None)

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
    SELECT site_wire_pkey FROM node WHERE pkey = (
        SELECT node_pkey FROM wire WHERE pkey = ?
        )
        """, (wire_pkey, )
        )
        site_wire_pkey = cur.fetchone()[0]

        cur.execute(
            """
SELECT
    node_pkey,
    top_graph_node_pkey,
    bottom_graph_node_pkey,
    right_graph_node_pkey,
    left_graph_node_pkey,
    site_pin_graph_node_pkey
FROM wire WHERE pkey = ?""", (site_wire_pkey, )
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
  site_pin_switch_pkey IS NOT NULL
AND
  pkey IN (
    SELECT
      wire_in_tile_pkey
    FROM
      wire
    WHERE
      node_pkey IN (
        SELECT
          node_pkey
        FROM
          wire
        WHERE
          pkey = ?
    )
  )""", (wire_pkey, )
        )
        results = cur.fetchall()
        assert len(results) == 1, (wire_pkey, results)
        site_pin_switch_pkey = results[0][0]
        assert site_pin_switch_pkey is not None, wire_pkey

        assert graph_node_pkey in edge_nodes, (
            wire_pkey, graph_node_pkey, track_graph_node_pkey, edge_nodes
        )

        if site_pin_graph_node_pkey is None:
            assert track_graph_node_pkey is not None, (
                wire_pkey, graph_node_pkey, track_graph_node_pkey, edge_nodes
            )

            is_lv_node = False
            for (name, ) in cur.execute("""
SELECT wire_in_tile.name
FROM wire_in_tile
WHERE pkey IN (
    SELECT wire_in_tile_pkey FROM wire WHERE node_pkey = ?
)""", (node_pkey, )):
                if name.startswith('LV'):
                    is_lv_node = True
                    break

            capacitance = 0
            resistance = 0
            for idx, (wire_cap, wire_res) in enumerate(cur.execute("""
SELECT wire_in_tile.capacitance, wire_in_tile.resistance
FROM wire_in_tile
WHERE pkey IN (
    SELECT wire_in_tile_pkey FROM wire WHERE node_pkey = ?
)""", (node_pkey, ))):
                capacitance += wire_cap
                resistance + wire_res

                if is_lv_node and idx == 1:
                    # Only use first 2 wire RC's, ignore the rest.  It appears
                    # that some of the RC constant was lumped into the switch
                    # timing, so don't double count.
                    #
                    # FIXME: Note that this is a hack, and should be fixed if
                    # possible.
                    break

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

    def find_connection_at_loc(self, loc):
        assert self.tracks is not None
        tracks_model, graph_nodes = self.tracks
        if loc not in self.track_connections:
            for idx in tracks_model.get_tracks_for_wire_at_coord(loc).values():
                break

            self.track_connections[loc] = idx
        else:
            idx = self.track_connections[loc]

        assert idx is not None

        return idx

    def connect_at(
            self,
            loc,
            other_connector,
            pip,
            src_wire_pkey=None,
            dest_wire_pkey=None,
    ):
        """ Connect two Connector objects at a location within the grid.

        Arguments
        ---------
        loc : prjxray.grid_types.GridLoc
            Location within grid to make connection.
        other_connector : Connector
            Destination connection.
        src_wire_pkey : int
            Source wire pkey of pip being connected.
        dest_wire_pkey : int
            Destination wire pkey of pip being connected.
        pip : Pip
            Pip object of pip being connected.

        Returns:
            Tuple of (src_graph_node_pkey, dest_graph_node_pkey)

        """

        if self.tracks and other_connector.tracks:
            tracks_model, graph_nodes = self.tracks
            idx1 = self.find_connection_at_loc(loc)

            other_tracks_model, other_graph_nodes = other_connector.tracks
            idx2 = other_connector.find_connection_at_loc(loc)

            switch_pkey = pip.get_pip_switch(src_wire_pkey, dest_wire_pkey)

            yield graph_nodes[idx1], switch_pkey, other_graph_nodes[
                idx2], pip.pip_pkey
            return
        elif self.pins and other_connector.tracks:
            assert self.pins.site_pin_direction == SitePinDirection.OUT

            tracks_model, graph_nodes = other_connector.tracks
            for pin_dir, idx in tracks_model.get_tracks_for_wire_at_coord(
                    grid_types.GridLoc(self.pins.x, self.pins.y)).items():
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

                    switch_pkey = pip.get_pip_switch(
                        src_wire_pkey, dest_wire_pkey
                    )
                    yield (src_node, site_pin_switch_pkey, src_wire_node, None)
                    yield (
                        src_wire_node, switch_pkey, dest_track_node,
                        pip.pip_pkey
                    )
                    return
        elif self.tracks and other_connector.pins:
            assert other_connector.pins.site_pin_direction == SitePinDirection.IN

            tracks_model, graph_nodes = self.tracks
            for pin_dir, idx in tracks_model.get_tracks_for_wire_at_coord(
                    grid_types.GridLoc(other_connector.pins.x,
                                       other_connector.pins.y)).items():
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

                    switch_pkey = pip.get_pip_switch(
                        src_wire_pkey, dest_wire_pkey
                    )
                    yield (
                        src_track_node, switch_pkey, dest_wire_node,
                        pip.pip_pkey
                    )
                    yield (
                        dest_wire_node, site_pin_switch_pkey, dest_node, None
                    )
                    return

        elif self.pins and other_connector.pins and not pip.is_pseudo:
            assert self.pins.site_pin_direction == SitePinDirection.OUT, dict(
                pip
            )
            assert other_connector.pins.site_pin_direction == SitePinDirection.IN, dict(
                pip
            )

            switch_pkey = self.get_edge_with_mux_switch(
                src_wire_pkey, pip.pip_pkey, dest_wire_pkey
            )

            if len(self.pins.edge_map) == 1 and len(
                    other_connector.pins.edge_map) == 1:
                # If there is only one choice, make it.
                src_node = list(self.pins.edge_map.values())[0]
                dest_node = list(other_connector.pins.edge_map.values())[0]

                yield (src_node, switch_pkey, dest_node, pip.pip_pkey)
                return

            for pin_dir in self.pins.edge_map:
                if OPPOSITE_DIRECTIONS[pin_dir
                                       ] in other_connector.pins.edge_map:
                    src_node = self.pins.edge_map[pin_dir]
                    dest_node = other_connector.pins.edge_map[
                        OPPOSITE_DIRECTIONS[pin_dir]]
                    yield (src_node, switch_pkey, dest_node, pip.pip_pkey)
                    return

        # If there is a pseudo pip that needs to be explicitly routed through,
        # two CHAN nodes are first created before and after IPIN and OPIN and
        # connected with an edge accordingly
        elif self.pins and other_connector.pins and pip.is_pseudo:
            switch_pkey = pip.get_pip_switch(src_wire_pkey, dest_wire_pkey)

            for pin_dir in self.pins.edge_map:
                if pin_dir in other_connector.pins.edge_map:
                    src_node = self.pins.edge_map[pin_dir]
                    src_node_type = get_node_type(self.conn, src_node)
                    assert NodeType(
                        src_node_type
                    ) == NodeType.IPIN, "src node for ppip is not an IPIN ({}, {})".format(
                        src_node, src_node_type
                    )

                    dest_node = other_connector.pins.edge_map[pin_dir]
                    dest_node_type = get_node_type(self.conn, dest_node)
                    assert NodeType(
                        dest_node_type
                    ) == NodeType.OPIN, "dest node for ppip is not an OPIN ({}, {})".format(
                        src_node, dest_node_type
                    )

                    src_wire_switch_pkey, src_wire_node = self.find_wire_node(
                        src_wire_pkey, src_node, None
                    )

                    dest_wire_switch_pkey, dest_wire_node = self.find_wire_node(
                        dest_wire_pkey, dest_node, None
                    )

                    yield (
                        src_wire_node, switch_pkey, dest_wire_node,
                        pip.pip_pkey
                    )
                    return

        assert False, (
            self.tracks, self.pins, other_connector.tracks,
            other_connector.pins, loc
        )


def create_find_connector(conn):
    """ Returns a function returns a Connector object for a given wire and node.

    Args:
        conn: Database connection

    Returns:
        Function.  See find_connector below for signature.
    """
    c = conn.cursor()

    @functools.lru_cache(maxsize=100000)
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
            assert node_type == graph2.NodeType(
                node[2]
            ), (node_pkey, node_type, graph2.NodeType(node[2]))

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


def create_get_tile_loc(conn):
    c = conn.cursor()

    @functools.lru_cache(maxsize=None)
    def get_tile_loc(tile_pkey):
        c.execute(
            "SELECT grid_x, grid_y FROM tile WHERE pkey = ?", (tile_pkey, )
        )
        return grid_types.GridLoc(*c.fetchone())

    return get_tile_loc


def yield_edges(
        const_connectors, delayless_switch, phy_tile_pkey, src_connector,
        sink_connector, pip, pip_obj, src_wire_pkey, sink_wire_pkey, loc,
        forward
):
    if forward:
        for (src_graph_node_pkey, switch_pkey, dest_graph_node_pkey,
             pip_pkey) in src_connector.connect_at(
                 pip=pip_obj, src_wire_pkey=src_wire_pkey,
                 dest_wire_pkey=sink_wire_pkey, loc=loc,
                 other_connector=sink_connector):
            assert switch_pkey is not None, (
                pip, src_graph_node_pkey, dest_graph_node_pkey, phy_tile_pkey,
                pip_pkey
            )
            yield (
                src_graph_node_pkey, dest_graph_node_pkey, switch_pkey,
                phy_tile_pkey, pip_pkey, False
            )

    if not forward and not pip.is_directional:
        for (src_graph_node_pkey, switch_pkey, dest_graph_node_pkey,
             pip_pkey) in sink_connector.connect_at(
                 pip=pip_obj, src_wire_pkey=sink_wire_pkey,
                 dest_wire_pkey=src_wire_pkey, loc=loc,
                 other_connector=src_connector):
            assert switch_pkey is not None, (
                pip, src_graph_node_pkey, dest_graph_node_pkey, phy_tile_pkey,
                pip_pkey
            )
            yield (
                src_graph_node_pkey, dest_graph_node_pkey, switch_pkey,
                phy_tile_pkey, pip_pkey, True
            )

    if forward:
        # Make additional connections to constant network if the sink needs it.
        for constant_src in yield_ties_to_wire(pip.net_to):
            for (src_graph_node_pkey, switch_pkey, dest_graph_node_pkey
                 ) in const_connectors[constant_src].connect_at(
                     pip=delayless_switch, loc=loc,
                     other_connector=sink_connector):
                assert switch_pkey is not None, (
                    pip, src_graph_node_pkey, dest_graph_node_pkey,
                    phy_tile_pkey, pip_pkey
                )
                yield (
                    src_graph_node_pkey, dest_graph_node_pkey, switch_pkey,
                    phy_tile_pkey, None, False
                )


def make_connection(
        conn, input_only_nodes, output_only_nodes, find_wire, find_pip,
        find_connector, get_tile_loc, tile_name, tile_type, pip,
        delayless_switch, const_connectors, forward
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

    pip_obj = find_pip(tile_type, pip.name)

    # Generally pseudo-pips are skipped, with the exception for BUFHCE related pips,
    # for which we want to create a routing path to have VPR route thorugh these pips.
    assert not pip_obj.is_pseudo or "CLK_HROW_CK" in pip.name

    loc = get_tile_loc(tile_pkey)

    for edge in yield_edges(
            const_connectors=const_connectors,
            delayless_switch=delayless_switch, phy_tile_pkey=phy_tile_pkey,
            src_connector=src_connector, sink_connector=sink_connector,
            pip=pip, pip_obj=pip_obj, src_wire_pkey=src_wire_pkey,
            sink_wire_pkey=sink_wire_pkey, loc=loc, forward=forward):
        yield edge


def mark_track_liveness(conn, input_only_nodes, output_only_nodes):
    """ Checks tracks for liveness.

    Iterates over all graph nodes that are routing tracks and determines if
    at least one graph edge originates from or two the track.

    Args:
        conn (sqlite3.Connection): Connection database

    """

    alive_tracks = set()
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

        write_cur.execute(
            """
SELECT count() FROM (
  SELECT dest_graph_node_pkey FROM graph_edge WHERE src_graph_node_pkey = ?
  UNION
  SELECT src_graph_node_pkey FROM graph_edge WHERE dest_graph_node_pkey = ?
  );""", (graph_node_pkey, graph_node_pkey)
        )
        active_other_nodes = write_cur.fetchone()[0]

        if src_count > 0 and sink_count > 0 and active_other_nodes > 1:
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

    write_cur.execute("""BEGIN EXCLUSIVE TRANSACTION;""")
    write_cur.execute("""CREATE INDEX alive_tracks ON track(alive);""")
    write_cur.execute(
        """CREATE INDEX graph_node_x_index ON graph_node(x_low);"""
    )
    write_cur.execute(
        """CREATE INDEX graph_node_y_index ON graph_node(y_low);"""
    )
    write_cur.execute("""COMMIT TRANSACTION;""")


def direction_to_enum(pin):
    """ Converts string to tracks.Direction. """
    for direction in tracks.Direction:
        if direction._name_ == pin:
            return direction

    assert False


def build_channels(conn):
    x_channel_models = {}
    y_channel_models = {}

    cur = conn.cursor()

    cur.execute(
        """
SELECT MIN(x_low), MAX(x_high), MIN(y_low), MAX(y_high) FROM graph_node
INNER JOIN track
ON track.pkey = graph_node.track_pkey
WHERE track.alive;"""
    )
    x_min, x_max, y_min, y_max = cur.fetchone()

    for x in progressbar_utils.progressbar(range(x_min, x_max + 1)):
        cur.execute(
            """
SELECT
    graph_node.y_low,
    graph_node.y_high,
    graph_node.pkey
FROM graph_node
INNER JOIN track
ON track.pkey = graph_node.track_pkey
WHERE
    track_pkey IS NOT NULL
AND
    track.alive
AND
    graph_node_type = ?
AND
    x_low = ?;""", (graph2.NodeType.CHANY.value, x)
        )

        data = list(cur)
        y_channel_models[x] = graph2.process_track(data)

    for y in progressbar_utils.progressbar(range(y_min, y_max + 1)):
        cur.execute(
            """
SELECT
    graph_node.x_low,
    graph_node.x_high,
    graph_node.pkey
FROM graph_node
INNER JOIN track
ON track.pkey = graph_node.track_pkey
WHERE
    track_pkey IS NOT NULL
AND
    track.alive
AND
    graph_node_type = ?
AND
    y_low = ?;""", (graph2.NodeType.CHANX.value, y)
        )

        data = list(cur)
        x_channel_models[y] = graph2.process_track(data)

    x_list = []
    y_list = []

    write_cur = conn.cursor()
    write_cur.execute("""BEGIN EXCLUSIVE TRANSACTION;""")

    for y in progressbar_utils.progressbar(range(y_max + 1)):
        if y in x_channel_models:
            x_list.append(len(x_channel_models[y].trees))

            for idx, tree in enumerate(x_channel_models[y].trees):
                for i in tree:
                    write_cur.execute(
                        'UPDATE graph_node SET ptc = ? WHERE pkey = ?;',
                        (idx, i[2])
                    )
        else:
            x_list.append(0)

    for x in progressbar_utils.progressbar(range(x_max + 1)):
        if x in y_channel_models:
            y_list.append(len(y_channel_models[x].trees))

            for idx, tree in enumerate(y_channel_models[x].trees):
                for i in tree:
                    write_cur.execute(
                        'UPDATE graph_node SET ptc = ? WHERE pkey = ?;',
                        (idx, i[2])
                    )
        else:
            y_list.append(0)

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


def verify_channels(conn):
    """ Verify PTC numbers in channels.
    No duplicate PTC's.

    Violation of this requirement results in a check failure during rr graph
    loading.

    """

    c = conn.cursor()

    chan_ptcs = {}

    for (graph_node_pkey, alive, graph_node_type, x_low, x_high, y_low, y_high,
         ptc, capacity) in c.execute(
             """
SELECT
    graph_node.pkey,
    track.alive,
    graph_node.graph_node_type,
    graph_node.x_low,
    graph_node.x_high,
    graph_node.y_low,
    graph_node.y_high,
    graph_node.ptc,
    graph_node.capacity
FROM graph_node
INNER JOIN track
ON graph_node.track_pkey = track.pkey
WHERE (graph_node_type = ? or graph_node_type = ?);""",
             (graph2.NodeType.CHANX.value, graph2.NodeType.CHANY.value)):

        if not alive and capacity != 0:
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
    sink_wires = []
    cur.execute(
        """SELECT pkey FROM wire WHERE node_pkey = (
        SELECT node_pkey FROM graph_node WHERE pkey = ?
        )""", (graph_node_pkey, )
    )
    for (wire_pkey, ) in cur:
        cur2.execute(
            """SELECT count() FROM pip_in_tile WHERE src_wire_in_tile_pkey = (
            SELECT wire_in_tile_pkey FROM wire WHERE pkey = ?
            ) AND pip_in_tile.is_pseudo = 0""", (wire_pkey, )
        )
        has_forward_pip = cur2.fetchone()[0]

        cur2.execute(
            """SELECT count() FROM pip_in_tile WHERE dest_wire_in_tile_pkey = (
            SELECT wire_in_tile_pkey FROM wire WHERE pkey = ?
            ) AND pip_in_tile.is_pseudo = 0""", (wire_pkey, )
        )
        has_backward_pip = cur2.fetchone()[0]

        if forward:
            if has_forward_pip:
                source_wires.append(wire_pkey)
            if has_backward_pip:
                sink_wires.append(wire_pkey)
        else:
            if has_forward_pip:
                sink_wires.append(wire_pkey)
            if has_backward_pip:
                source_wires.append(wire_pkey)

    if len(source_wires) > 1:
        if forward:
            # Ambiguous output location, just use input pips, which should
            # have only 1 phy_tile location.
            cur2.execute(
                """
WITH wires_in_graph_node(phy_tile_pkey, phy_tile_type_pkey, wire_in_tile_pkey) AS (
    SELECT wire.phy_tile_pkey, phy_tile.tile_type_pkey, wire.wire_in_tile_pkey
    FROM graph_node
    INNER JOIN wire ON wire.node_pkey = graph_node.node_pkey
    INNER JOIN phy_tile ON wire.phy_tile_pkey = phy_tile.pkey
    WHERE graph_node.pkey = ?
)
SELECT DISTINCT wire.phy_tile_pkey, pip_in_tile.is_directional
FROM wires_in_graph_node
INNER JOIN pip_in_tile
ON
    pip_in_tile.dest_wire_in_tile_pkey = wires_in_graph_node.wire_in_tile_pkey
AND
    pip_in_tile.tile_type_pkey = wires_in_graph_node.phy_tile_type_pkey
INNER JOIN wire
ON
    wire.wire_in_tile_pkey = pip_in_tile.src_wire_in_tile_pkey
AND
    wire.phy_tile_pkey = wires_in_graph_node.phy_tile_pkey;
                """, (graph_node_pkey, )
            )
            src_phy_tiles = cur2.fetchall()

            if len(src_phy_tiles) > 1:
                # Try pruning bi-directional pips
                src_phy_tiles = [
                    (phy_tile_pkey, is_directional)
                    for (phy_tile_pkey, is_directional) in src_phy_tiles
                    if is_directional
                ]

            assert len(src_phy_tiles) == 1, (
                pin_graph_node_pkey, graph_node_pkey, source_wires, tracks,
                src_phy_tiles
            )
            phy_tile_pkey = src_phy_tiles[0][0]
        else:
            # Have an ambiguous source, see if there is an unambigous sink.
            #
            # Remove sinks that are also sources (e.g. bidirectional wires)
            sink_wires = list(set(sink_wires) - set(source_wires))

            if len(sink_wires) == 1:
                cur.execute(
                    "SELECT phy_tile_pkey FROM wire WHERE pkey = ?",
                    (sink_wires[0], )
                )
                source_wires = sink_wires
                phy_tile_pkey = cur.fetchone()[0]
            else:
                assert False, (
                    pin_graph_node_pkey, graph_node_pkey, source_wires,
                    sink_wires, tracks
                )
                return
    elif len(source_wires) == 1:
        cur.execute(
            "SELECT phy_tile_pkey FROM wire WHERE pkey = ?",
            (source_wires[0], )
        )
        phy_tile_pkey = cur.fetchone()[0]
    elif len(sink_wires) == 1:
        cur.execute(
            "SELECT phy_tile_pkey FROM wire WHERE pkey = ?", (sink_wires[0], )
        )
        source_wires = sink_wires
        phy_tile_pkey = cur.fetchone()[0]
    else:
        return

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
        pin_graph_node_pkey, tracks, visited_nodes
):
    """ Recursive function to walk along a node and mark segments.

    This algorithm is used for marking INPINFEED and OUTPINFEED on nodes
    starting from an IPIN or OPIN edge.

    In addition, the canonical location of the connection box IPIN/OPIN nodes
    is the canonical location of the routing interface.  For example, the
    CLBLL_R tile is located to the right of the INT_R tile.  The routing
    lookahead routes to the INT_R (e.g. a x-1 of the CLBLL_R).  So the
    canonical location of the CLBLL_R IPIN is the INT_R tile, not the CLBLL_R
    tile.

    """
    cur = conn.cursor()

    # Update track segment's to segment_pkey (e.g. INPINFEED or OUTPINFEED).
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
    else:
        track_pkey = None

    # Traverse to the next graph node.
    if forward:
        cur.execute(
            """
SELECT
    graph_edge.dest_graph_node_pkey,
    graph_node.track_pkey
FROM
    graph_edge
INNER JOIN graph_node ON graph_node.pkey = graph_edge.dest_graph_node_pkey
WHERE
    src_graph_node_pkey = ?
""", (graph_node_pkey, )
        )
        next_nodes = cur.fetchall()
    else:
        cur.execute(
            """
SELECT
    graph_edge.src_graph_node_pkey,
    graph_node.track_pkey
FROM
    graph_edge
INNER JOIN graph_node ON graph_node.pkey = graph_edge.src_graph_node_pkey
WHERE
    dest_graph_node_pkey = ?
""", (graph_node_pkey, )
        )
        next_nodes = cur.fetchall()

    if not forward:
        # Some nodes simply lead to GND/VCC tieoff pins, these should not
        # stop the walk, as they are not relevant to connection box.
        next_non_tieoff_nodes = []
        for (next_graph_node_pkey, next_track) in next_nodes:
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
                next_non_tieoff_nodes.append(
                    (next_graph_node_pkey, next_track)
                )

        if len(next_non_tieoff_nodes) == 1:
            (next_node, next_track) = next_non_tieoff_nodes[0]

        next_nodes = next_non_tieoff_nodes

    if len(next_nodes) == 1:
        # This is a simple edge, keep walking.
        (next_node, next_track) = next_nodes[0]
    else:
        next_other_nodes = []
        for next_node, next_track in next_nodes:
            # Shorted groups will have edges back to previous nodes, but they
            # will be in the same track, so ignore these.
            if next_node in visited_nodes and track_pkey == next_track:
                continue
            else:
                next_other_nodes.append((next_node, next_track))

        if len(next_other_nodes) == 1:
            # This is a simple edge, keep walking.
            (next_node, next_track) = next_other_nodes[0]
        else:
            next_node = None

    if next_node is not None and next_node not in visited_nodes:
        # If there is a next node, keep walking
        visited_nodes.add(next_node)
        walk_and_mark_segment(
            conn=conn,
            write_cur=write_cur,
            graph_node_pkey=next_node,
            forward=forward,
            segment_pkey=segment_pkey,
            unknown_pkey=unknown_pkey,
            pin_graph_node_pkey=pin_graph_node_pkey,
            tracks=tracks,
            visited_nodes=visited_nodes
        )
    else:
        # There is not a next node, update the connection box of the IPIN/OPIN
        # the walk was started from.
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


def annotate_pin_feeds(conn, ccio_sites):
    """ Identifies and annotates pin feed channels.

    Some channels are simply paths from IPIN's or OPIN's.  Set
    pin_classification to either IPIN_FEED or OPIN_FEED.  During track creation
    if these nodes are not given a specific segment, they will be assigned as
    INPINFEED or OUTPINFEED.
    """
    write_cur = conn.cursor()
    cur = conn.cursor()

    segments = {}
    for segment_pkey, segment_name in cur.execute(
            "SELECT pkey, name FROM segment"):
        segments[segment_name] = segment_pkey

    # Find BUFHCE OPIN's, so that walk_and_mark_segment uses correct segment
    # type.
    bufhce_opins = get_pins(conn, "BUFHCE", "O")

    # Find BUFGCTRL OPIN's, so that walk_and_mark_segment uses correct segment
    # type.
    bufg_opins = get_pins(conn, "BUFGCTRL", "O")

    # Find BUFGCTRL IPIN's, so that walk_and_mark_segment uses correct segment
    # type.
    bufg_ipins = set()
    for nipins in range(2):
        bufg_ipins |= get_pins(conn, "BUFGCTRL", "I{}".format(nipins))

    # Find PLL OPIN's, so that walk_and_mark_segment uses correct segment
    # type.
    pll_opins = set()
    for nclk in range(6):
        pll_opins |= get_pins(conn, "PLLE2_ADV", "CLKOUT{}".format(nclk))

    # Find PLL IPIN's, so that walk_and_mark_segment uses correct segment
    # type.
    pll_ipins = set()
    for nclk in range(2):
        pll_ipins |= get_pins(conn, "PLLE2_ADV", "CLKIN{}".format(nclk + 1))

    ccio_opins = set()

    # Find graph nodes for IOI_ILOGIC0_O for IOPAD_M's that are CCIO tiles (
    # e.g. have dedicate clock paths).
    for ccio_site in ccio_sites:
        ccio_ilogic = ccio_site.replace('IOB', 'ILOGIC')
        cur.execute(
            """
WITH ilogic_o_wires(wire_in_tile_pkey) AS (
  SELECT wire_in_tile.pkey FROM wire_in_tile
  INNER JOIN site_pin ON site_pin.pkey = wire_in_tile.site_pin_pkey
  INNER JOIN site_type ON site_pin.site_type_pkey = site_type.pkey
  WHERE
    site_type.name == "ILOGICE3"
  AND
    site_pin.name == "O"
  AND
    wire_in_tile.site_pkey IN (
        SELECT site_pkey FROM site_instance WHERE name = ?
    )
)
SELECT graph_node.pkey FROM graph_node
INNER JOIN wire ON graph_node.node_pkey = wire.node_pkey
WHERE
  wire.wire_in_tile_pkey IN (SELECT wire_in_tile_pkey FROM ilogic_o_wires)
AND
  wire.phy_tile_pkey = (SELECT phy_tile_pkey FROM site_instance WHERE name = ?);
        """, (ccio_ilogic, ccio_ilogic)
        )
        for (graph_node_pkey, ) in cur:
            ccio_opins.add(graph_node_pkey)

    write_cur.execute("""BEGIN EXCLUSIVE TRANSACTION;""")

    # Walk from OPIN's first.
    for (graph_node_pkey, node_pkey) in cur.execute("""
SELECT graph_node.pkey, graph_node.node_pkey
FROM graph_node
WHERE graph_node.graph_node_type = ?
        """, (NodeType.OPIN.value, )):
        if not active_graph_node(conn, graph_node_pkey, forward=True):
            continue

        if graph_node_pkey in bufhce_opins:
            segment_pkey = segments["HCLK_ROWS"]
        elif graph_node_pkey in bufg_opins:
            segment_pkey = segments["GCLK_OUTPINFEED"]
        elif graph_node_pkey in pll_opins:
            segment_pkey = segments["PLL_OUTPINFEED"]
        elif graph_node_pkey in ccio_opins:
            segment_pkey = segments["CCIO_OUTPINFEED"]
        else:
            segment_pkey = segments["OUTPINFEED"]

        walk_and_mark_segment(
            conn,
            write_cur,
            graph_node_pkey,
            forward=True,
            segment_pkey=segment_pkey,
            unknown_pkey=segments["unknown"],
            pin_graph_node_pkey=graph_node_pkey,
            tracks=list(),
            visited_nodes=set()
        )

    # Walk from IPIN's next.
    for (graph_node_pkey, ) in cur.execute("""
SELECT graph_node.pkey
FROM graph_node
WHERE graph_node.graph_node_type = ?
        """, (NodeType.IPIN.value, )):

        if not active_graph_node(conn, graph_node_pkey, forward=False):
            continue

        if graph_node_pkey in bufg_ipins:
            segment_pkey = segments["GCLK_INPINFEED"]
        elif graph_node_pkey in pll_ipins:
            segment_pkey = segments["PLL_INPINFEED"]
        else:
            segment_pkey = segments["INPINFEED"]

        walk_and_mark_segment(
            conn,
            write_cur,
            graph_node_pkey,
            forward=False,
            segment_pkey=segment_pkey,
            unknown_pkey=segments["unknown"],
            pin_graph_node_pkey=graph_node_pkey,
            tracks=list(),
            visited_nodes=set()
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


def get_segment_length(segment_lengths):
    if len(segment_lengths) == 0:
        return 1

    median_length = int(math.ceil(numpy.median(segment_lengths)))

    return max(1, median_length)


def compute_segment_lengths(conn):
    """ Determine segment lengths used for cost normalization. """
    cur = conn.cursor()
    cur2 = conn.cursor()
    cur3 = conn.cursor()
    cur4 = conn.cursor()

    write_cur = conn.cursor()

    write_cur.execute("""BEGIN EXCLUSIVE TRANSACTION;""")

    for (segment_pkey, ) in cur.execute("SELECT pkey FROM segment"):

        segment_lengths = []

        # Get all tracks with this segment
        for (track_pkey, src_phy_tile_pkey) in cur2.execute("""
SELECT pkey, canon_phy_tile_pkey FROM track
WHERE
    canon_phy_tile_pkey IS NOT NULL
AND
    segment_pkey = ?
        """, (segment_pkey, )):
            segment_length = 1
            cur4.execute(
                "SELECT grid_x, grid_y FROM phy_tile WHERE pkey = ?",
                (src_phy_tile_pkey, )
            )
            src_x, src_y = cur4.fetchone()

            # Get tiles downstream of this track.
            for (dest_phy_tile_pkey, ) in cur3.execute("""
SELECT DISTINCT canon_phy_tile_pkey FROM track WHERE pkey IN (
    SELECT track_pkey FROM graph_node WHERE pkey IN (
        SELECT dest_graph_node_pkey FROM graph_edge WHERE src_graph_node_pkey IN (
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

            segment_lengths.append(segment_length)

        write_cur.execute(
            "UPDATE segment SET length = ? WHERE pkey = ?", (
                get_segment_length(segment_lengths),
                segment_pkey,
            )
        )

    write_cur.execute("""COMMIT TRANSACTION;""")


def commit_edges(write_cur, edges):
    write_cur.execute("""BEGIN EXCLUSIVE TRANSACTION;""")
    write_cur.executemany(
        """
        INSERT INTO graph_edge(
            src_graph_node_pkey, dest_graph_node_pkey, switch_pkey,
            phy_tile_pkey, pip_in_tile_pkey, backward) VALUES (?, ?, ?, ?, ?, ?)""",
        edges
    )
    write_cur.execute("""COMMIT TRANSACTION;""")


REMOVE_TRAILING_NUM = re.compile(r'[0-9]+$')


def pip_sort_key(forward_pip):
    """ Sort pips to match canonical order. """
    forward, pip = forward_pip

    count = (
        len(REMOVE_TRAILING_NUM.sub('', pip.net_to)) +
        len(REMOVE_TRAILING_NUM.sub('', pip.net_from))
    )

    if forward:
        return (pip.is_pseudo, count, pip.net_to, pip.net_from)
    else:
        return (pip.is_pseudo, count, pip.net_from, pip.net_to)


def make_sorted_pips(pips):
    out_pips = []

    for pip in pips:
        # Add forward copy of pip
        out_pips.append((True, pip))

        # Add backward copy of pip if not directional.
        if not pip.is_directional:
            out_pips.append((False, pip))

    out_pips.sort(key=pip_sort_key)
    return out_pips


def create_edge_indices(conn):
    write_cur = conn.cursor()

    write_cur.execute("""BEGIN EXCLUSIVE TRANSACTION;""")
    write_cur.execute(
        """CREATE INDEX src_node_index ON graph_edge(src_graph_node_pkey);"""
    )
    write_cur.execute(
        """CREATE INDEX dest_node_index ON graph_edge(dest_graph_node_pkey);"""
    )
    write_cur.execute("""CREATE INDEX node_track_index ON node(track_pkey);""")
    write_cur.execute("""COMMIT TRANSACTION;""")
    write_cur.connection.commit()

    print('{} Indices created, marking track liveness'.format(now()))


def create_and_insert_edges(
        db, grid, conn, use_roi, roi, input_only_nodes, output_only_nodes
):
    write_cur = conn.cursor()

    write_cur.execute(
        'SELECT pkey FROM switch WHERE name = ?;',
        ('__vpr_delayless_switch__', )
    )
    delayless_switch_pkey = write_cur.fetchone()[0]
    delayless_switch = KnownSwitch(delayless_switch_pkey)

    find_pip = create_find_pip(conn)
    find_wire = create_find_wire(conn)
    find_connector = create_find_connector(conn)
    get_tile_loc = create_get_tile_loc(conn)

    const_connectors = create_const_connectors(conn)

    sorted_pips = {}

    num_edges = 0
    edges = []
    for loc in progressbar_utils.progressbar(grid.tile_locations()):
        edge_set = set()

        gridinfo = grid.gridinfo_at_loc(loc)
        tile_name = grid.tilename_at_loc(loc)

        # Not a synth node, check if in ROI.
        if use_roi and not roi.tile_in_roi(loc):
            continue

        tile_type = db.get_tile_type(gridinfo.tile_type)

        if tile_type not in sorted_pips:
            sorted_pips[tile_type] = make_sorted_pips(tile_type.get_pips())

        for forward, pip in sorted_pips[tile_type]:
            # FIXME: The PADOUT0/1 connections do not work.
            #
            # These connections are used for:
            #  - XADC
            #  - Differential signal signal connection between pads.
            #
            # Issue tracking fix:
            # https://github.com/SymbiFlow/symbiflow-arch-defs/issues/1033
            if 'PADOUT0' in pip.name and 'DIFFI_IN1' not in pip.name:
                continue
            if 'PADOUT1' in pip.name and 'DIFFI_IN0' not in pip.name:
                continue

            # These edges are used for bringing general interconnect to the
            # horizontal clock buffers.  This should only be used when routing
            # clocks.
            if 'CLK_HROW_CK_INT_' in pip.name:
                continue

            # Generally pseudo-pips are skipped, with the exception for BUFHCE related pips,
            # for which we want to create a routing path to have VPR route thorugh these pips.
            if pip.is_pseudo and "CLK_HROW_CK" not in pip.name:
                continue

            # Filter out PIPs related to MIO and DDR pins of the Zynq7 PS.
            # These PIPs are actually not there, they are just informative.
            if "PS72_" in pip.net_to or "PS72_" in pip.net_from:
                continue

            connections = make_connection(
                conn=conn,
                input_only_nodes=input_only_nodes,
                output_only_nodes=output_only_nodes,
                find_pip=find_pip,
                find_wire=find_wire,
                find_connector=find_connector,
                get_tile_loc=get_tile_loc,
                tile_name=tile_name,
                tile_type=gridinfo.tile_type,
                pip=pip,
                delayless_switch=delayless_switch,
                const_connectors=const_connectors,
                forward=forward,
            )

            if connections:
                for connection in connections:
                    key = tuple(connection[0:3])
                    if key in edge_set:
                        continue

                    edge_set.add(key)
                    edges.append(connection)

        if len(edges) > 1000:
            commit_edges(write_cur, edges)

            num_edges += len(edges)
            edges = []

    print('{} Created {} edges, inserted'.format(now(), num_edges))


def get_ccio_sites(grid):
    ccio_sites = set()

    for tile in grid.tiles():
        gridinfo = grid.gridinfo_at_tilename(tile)

        for site, pin_function in gridinfo.pin_functions.items():
            if 'SRCC' in pin_function or 'MRCC' in pin_function:
                if gridinfo.sites[site][-1] == 'M':
                    ccio_sites.add(site)

    return ccio_sites


def create_edges(args):
    db = prjxray.db.Database(args.db_root, args.part)
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

        if args.synth_tiles and args.overlay:
            use_roi = True
            with open(args.synth_tiles) as f:
                synth_tiles = json.load(f)

            region_dict = dict()
            for r in synth_tiles['info']:
                bounds = (r['GRID_X_MIN'], r['GRID_X_MAX'], \
                        r['GRID_Y_MIN'], r['GRID_Y_MAX'])
                region_dict[r['name']] = bounds

            roi = Overlay(
                db=db,
                region_dict=region_dict
            )

            print('{} generating routing graph for Overlay.'.format(now()))
        elif args.synth_tiles:
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
        elif args.graph_limit:
            use_roi = True
            x_min, y_min, x_max, y_max = map(int, args.graph_limit.split(','))
            roi = Roi(
                db=db,
                x1=x_min,
                y1=y_min,
                x2=x_max,
                y2=y_max,
            )
            synth_tiles = {'tiles': {}}
        else:
            use_roi = False

        output_only_nodes = set()
        input_only_nodes = set()

        print('{} Finding nodes belonging to ROI'.format(now()))
        if use_roi:
            find_wire = create_find_wire(conn)
            for loc in progressbar_utils.progressbar(grid.tile_locations()):
                gridinfo = grid.gridinfo_at_loc(loc)
                tile_name = grid.tilename_at_loc(loc)

                if tile_name in synth_tiles['tiles']:
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

        create_and_insert_edges(
            db=db,
            grid=grid,
            conn=conn,
            use_roi=use_roi,
            roi=roi if use_roi else None,
            input_only_nodes=input_only_nodes,
            output_only_nodes=output_only_nodes
        )

        create_edge_indices(conn)

        mark_track_liveness(conn, input_only_nodes, output_only_nodes)

    return get_ccio_sites(grid)
