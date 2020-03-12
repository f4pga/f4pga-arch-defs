#!/usr/bin/env python3
import argparse
import pickle
from collections import defaultdict

import lxml.etree as ET

from lib.rr_graph import tracks
import lib.rr_graph.graph2 as rr
import lib.rr_graph_xml.graph2 as rr_xml
from lib import progressbar_utils

from data_structs import *
from utils import yield_muxes, fixup_pin_name

# =============================================================================


def is_hop(connection):
    """
    Returns True if a connection represents a HOP wire.
    """

    if connection.src.type == ConnectionType.SWITCHBOX and \
       connection.dst.type == ConnectionType.SWITCHBOX:
        return True

    return False


def is_tile(connection):
    """
    Rtturns True for connections going to/from tile.
    """

    if connection.src.type == ConnectionType.SWITCHBOX and \
       connection.dst.type == ConnectionType.TILE:
        return True

    if connection.src.type == ConnectionType.TILE and \
       connection.dst.type == ConnectionType.SWITCHBOX:
        return True

    return False


def is_local(connection):
    """
    Returns true if a connection is local.
    """
    return connection.src.loc == connection.dst.loc


# =============================================================================


def add_track(graph, track, segment_id):
    """
    Adds a track to the graph. Returns the node object representing the track
    node.
    """

    node_id = graph.add_track(track, segment_id)
    node = graph.nodes[-1]
    assert node.id == node_id

    return node


def add_node(graph, loc, direction, segment_id):
    """
    Adds a track of length 1 to the graph. Returns the node object
    """

    return add_track(
        graph, 
        tracks.Track(
            direction = direction,
            x_low  = loc.x,
            x_high = loc.x,
            y_low  = loc.y,
            y_high = loc.y,
            ),
        segment_id
        )

# =============================================================================


def node_joint_location(node_a, node_b):
    """
    Given two VPR nodes returns a location of the point where they touch each
    other.
    """

    loc_a1 = Loc(node_a.loc.x_low , node_a.loc.y_low )
    loc_a2 = Loc(node_a.loc.x_high, node_a.loc.y_high)

    loc_b1 = Loc(node_b.loc.x_low , node_b.loc.y_low )
    loc_b2 = Loc(node_b.loc.x_high, node_b.loc.y_high)

    if loc_a1 == loc_b1:
        return loc_a1
    if loc_a1 == loc_b2:
        return loc_a1
    if loc_a2 == loc_b1:
        return loc_a2
    if loc_a2 == loc_b2:
        return loc_a2

    assert False, (node_a, node_b)


def add_edge(graph, src_node_id, dst_node_id, switch_id, meta_name=None, meta_value=""):
    """
    Adds an edge to the routing graph. If the given switch corresponds to a
    "pass" type switch then adds two edges going both ways.
    """

    # Connect src to dst
    graph.add_edge(
        src_node_id,
        dst_node_id,
        switch_id,
        meta_name,
        meta_value
    )

    # Check if the switch is of the "pass" type. If so then add an edge going
    # in the opposite way.
    switch = graph.switch_map[switch_id]
    if switch.type in [rr.SwitchType.SHORT, rr.SwitchType.PASS_GATE]:

        graph.add_edge(
            dst_node_id,
            src_node_id,
            switch_id,
            meta_name,
            meta_value
        )


def connect(graph, src_node, dst_node, switch_id=None, segment_id=None, meta_name=None, meta_value=""):
    """
    Connect two VPR nodes in a way that certain rules are obeyed.

    The rules are:
    - a CHANX cannot connect directly to a CHANY and vice versa,
    - a CHANX cannot connect to an IPIN facing left or right,
    - a CHANY cannot connect to an IPIN facting top or bottom,
    - an OPIN facing left or right cannot connect to a CHANX,
    - an OPIN facing top or bottom cannot connect to a CHANY

    Whenever a rule is not met then the connection is made through a padding
    node:

    src -> ["short" swtich] -> pad -> [desired switch] -> dst

    Otherwise the connection is made directly

    src -> [desired switch] -> dst

    The influence of whether the rules are obeyed or not on the actual VPR
    behavior is unclear.
    """

    # Use the default delayless switch if none is given
    if switch_id is None:
        switch_id = graph.get_delayless_switch_id()

    # Get the "short" switch id
    short_id = graph.get_switch_id("short")

    # Use the "pad" segment if none given
    if segment_id is None:
        segment_id = graph.get_segment_id_from_name("pad")

    # CHANX to CHANY or vice-versa
    if src_node.type == rr.NodeType.CHANX and dst_node.type == rr.NodeType.CHANY or \
       src_node.type == rr.NodeType.CHANY and dst_node.type == rr.NodeType.CHANX:

        # Check loc
        node_joint_location(src_node, dst_node)

        # Connect directly
        add_edge(
            graph,
            src_node.id,
            dst_node.id,
            switch_id,
            meta_name,
            meta_value
        )

    # CHANX to CHANX or CHANY to CHANY
    elif src_node.type == rr.NodeType.CHANX and dst_node.type == rr.NodeType.CHANX or \
         src_node.type == rr.NodeType.CHANY and dst_node.type == rr.NodeType.CHANY:

        loc = node_joint_location(src_node, dst_node)
        direction = "X" if src_node.type == rr.NodeType.CHANY else "Y"

        # Padding node
        pad_node = add_node(
            graph,
            loc,
            direction,
            segment_id
        )

        # Connect through the padding node
        graph.add_edge(src_node.id, pad_node.id, short_id)
        graph.add_edge(pad_node.id, src_node.id, short_id)

        add_edge(
            graph,
            pad_node.id,
            dst_node.id,
            switch_id,
            meta_name,
            meta_value
        )

    # OPIN to CHANX/CHANY
    elif src_node.type == rr.NodeType.OPIN and dst_node.type in \
        [rr.NodeType.CHANX, rr.NodeType.CHANY]:

        # All OPINs go right (towards +X)
        assert src_node.loc.side == tracks.Direction.RIGHT, src_node

        # Connected to CHANX
        if dst_node.type == rr.NodeType.CHANX:

            loc = node_joint_location(src_node, dst_node)

            # Padding node
            pad_node = add_node(
                graph,
                loc,
                "Y",
                segment_id
            )

            # Connect through the padding node
            graph.add_edge(src_node.id, pad_node.id, short_id)
            graph.add_edge(pad_node.id, src_node.id, short_id)

            add_edge(
                graph,
                pad_node.id,
                dst_node.id,
                switch_id,
                meta_name,
                meta_value
            )

        # Connected to CHANY
        elif dst_node.type == rr.NodeType.CHANY:

            # Directly
            add_edge(
                graph,
                src_node.id,
                dst_node.id,
                switch_id,
                meta_name,
                meta_value
            )

        # Should not happen
        else:
            assert False, dst_node

    # CHANX/CHANY to IPIN
    elif dst_node.type == rr.NodeType.IPIN and src_node.type in \
        [rr.NodeType.CHANX, rr.NodeType.CHANY]:

        # All IPINs go top (toward +Y)
        assert dst_node.loc.side == tracks.Direction.TOP, dst_node

        # Connected to CHANY
        if src_node.type == rr.NodeType.CHANY:

            loc = node_joint_location(src_node, dst_node)

            # Padding node
            pad_node = add_node(
                graph,
                loc,
                "X",
                segment_id
            )

            # Connect through the padding node
            graph.add_edge(src_node.id, pad_node.id, short_id)
            graph.add_edge(pad_node.id, src_node.id, short_id)

            add_edge(
                graph,
                pad_node.id,
                dst_node.id,
                switch_id,
                meta_name,
                meta_value
            )

        # Connected to CHANX
        elif src_node.type == rr.NodeType.CHANX:

            # Directly
            add_edge(
                graph,
                src_node.id,
                dst_node.id,
                switch_id,
                meta_name,
                meta_value
            )

        # Should not happen
        else:
            assert False, dst_node

    # An unhandled case
    else:
        assert False, (src_node, dst_node)


# =============================================================================


class SwitchboxModel(object):

    def __init__(self, graph, loc, phy_loc, switchbox):
        self.graph      = graph
        self.loc        = loc
        self.phy_loc    = phy_loc
        self.switchbox  = switchbox

        self.mux_input_to_node  = {}
        self.mux_output_to_node = {}

        self.input_to_node = {}

        self._build()


    def _build(self):
        """
        Build the switchbox model
        """

        # Add nodes and edge for all inputs and outputs of all muxes.
        # Add mux edges.
        for stage, switch, mux in yield_muxes(self.switchbox):

            dir_inp = "X" if (stage.id % 2) else "Y"
            dir_out = "Y" if (stage.id % 2) else "X"

            segment_id = self.graph.get_segment_id_from_name("generic")

            # Output node
            key = (stage.id, switch.id, mux.id)
            assert key not in self.mux_output_to_node
            
            out_node = add_node(
                self.graph,
                self.loc,
                dir_out,
                segment_id
            )
            self.mux_output_to_node[key] = out_node

            # Input nodes + mux edges
            for pin in mux.inputs.values():

                key = (stage.id, switch.id, mux.id, pin.id)
                assert key not in self.mux_input_to_node

                # Input node
                inp_node = add_node(
                    self.graph,
                    self.loc,
                    dir_inp,
                    segment_id
                )

                self.mux_input_to_node[key] = inp_node

                # Get mux metadata
                metadata = self._get_metadata_for_mux(
                    stage,
                    switch,
                    mux,
                    pin.id
                )

                if len(metadata):
                    meta_name  = "fasm_features"
                    meta_value = "\n".join(metadata)
                else:
                    meta_name  = None
                    meta_value = ""

                # Get switch id
                try:
                    switch_id = self.graph.get_switch_id(
                        mux.timing["switches"][pin.id]
                    )
                except KeyError:
                    print(mux.timing["switches"], list(mux.inputs.keys()))
                    switch_id = self.graph.get_delayless_switch_id()

                # Mux switch with appropriate timing and fasm metadata
                self.graph.add_edge(
                    inp_node.id,
                    out_node.id,
                    switch_id,
                    name  = meta_name,
                    value = meta_value,
                )

        # Add internal connections between muxes.
        for connection in self.switchbox.connections:
            src = connection.src
            dst = connection.dst

            # Check
            assert src.pin_id == 0, src
            assert src.pin_direction == PinDirection.OUTPUT, src

            # Get an input node
            key = (dst.stage_id, dst.switch_id, dst.mux_id, dst.pin_id)
            dst_node = self.mux_input_to_node[key]

            # Create a mux output
            self._create_mux_output(
                src.stage_id,
                src.switch_id,
                src.mux_id,
                dst_node
            )

        # Build a map of switchbox input pin names to VPR nodes corresponding
        # to connected mux inputs.
        for pin in self.switchbox.inputs.values():

            # Get the nodes
            nodes = []
            for loc in pin.locs:
                key = (loc.stage_id, loc.switch_id, loc.mux_id, loc.pin_id)
                node = self.mux_input_to_node[key]
                nodes.append(node)

            assert pin.name not in self.input_to_node
            self.input_to_node[pin.name] = nodes


    def _get_metadata_for_mux(self, stage, switch, mux, src_pin_id):
        """
        Formats fasm features for the given edge representin a switchbox mux.
        Returns a list of fasm features.
        """
        metadata = []

        # Format prefix
        prefix = "X{}Y{}.ROUTING".format(self.phy_loc.x, self.phy_loc.y)

        # A mux in the HIGHWAY stage
        if stage.type == "HIGHWAY":
            feature = "I_highway.IM{}.I_pg{}".format(
                switch.id,
                src_pin_id
            )

        # A mux in the STREET stage
        elif stage.type == "STREET":
            feature = "I_street.Isb{}{}.I_M{}.I_pg{}".format(
                stage.id + 1,
                switch.id + 1,
                mux.id,
                src_pin_id
            )

        else:
            assert False, stage

        metadata.append(".".join([prefix, feature]))
        return metadata


    def _create_mux_output(self, stage_id, switch_id, mux_id, dst_node=None):
        """
        Creates a new output for the given mux with appropriate timing mode.
        Returns the output node object
        """

        dir_inp = "Y" if (stage_id % 2) else "X"
        dir_out = "X" if (stage_id % 2) else "Y"

        # Add the new output node if not given
        if dst_node is None:
            dst_node = add_node(
                self.graph,
                self.loc,
                dir_out,
                self.graph.get_segment_id_from_name("sb_node")
            )

        # Add the output load model to the mux
        mux = self.switchbox.stages[stage_id].switches[switch_id].muxes[mux_id]
        key = (stage_id, switch_id, mux_id)
        out_node = self.mux_output_to_node[key]

        # Intermediate node with capacitance        
        segment_id = self.graph.get_segment_id_from_name(
            mux.timing["segment"]
        )

        load_node = add_node(
            self.graph,
            self.loc,
            dir_inp,
            segment_id
        )

        # Pass gate edge to switch the capacitance on/off (delayless)
        connect(
            self.graph,
            out_node,
            load_node,
            switch_id = self.graph.get_switch_id("delayless_pass_gate")
        )

        # Isolating buffer (delayless)
        connect(
            self.graph,
            load_node,
            dst_node,
        )

        return dst_node


    def get_input_nodes(self, pin_name):
        """
        Return a list of VPR node objects that correspond to a particular
        switchbox input.
        """
        return self.input_to_node[pin_name]


    def create_output(self, pin_name, dst_node=None):
        """
        Creates a new output for the given switchbox output. Returns the
        output node object.
        """

        # Get the output pin
        pin = self.switchbox.outputs[pin_name]

        assert len(pin.locs) == 1
        loc = pin.locs[0]

        # Create a mux output for its mux
        return self._create_mux_output(
            loc.stage_id,
            loc.switch_id,
            loc.mux_id,
            dst_node
        )

# =============================================================================


def tile_pin_to_rr_pin(tile_type, pin_name):
    """
    Converts the tile pin name as in the database to its counterpart in the
    rr graph.
    """

    # FIXME: I guess the last '[0]' will differ for tiles with capacity > 1
    return "TL-{}.{}[0]".format(tile_type, fixup_pin_name(pin_name))


def build_tile_pin_to_node_map(graph, tile_types, tile_grid):
    """
    Builds a map of tile pins (at given location!) to rr nodes.
    """

    node_map = {}

    # Build the map for each tile instance in the grid.
    for loc, tile in tile_grid.items():
        node_map[loc] = {}

        # Empty tiles do not have pins
        if tile is None:
            continue

        # For each pin of the tile
        for pin in tile_types[tile.type].pins:

            # Get the VPR pin name and its node
            rr_pin_name = tile_pin_to_rr_pin(tile.type, pin.name)

            try:
                nodes = graph.get_nodes_for_pin((loc.x, loc.y,), rr_pin_name)
                assert len(nodes) == 1, (rr_pin_name, loc.x, loc.y)
            except KeyError as ex:
                print("WARNING: No node for pin '{}' at ({},{})".format(rr_pin_name, loc.x, loc.y))
                continue 

            # Add to the map
            node_map[loc][pin.name] = nodes[0][0]

    return node_map


def build_tile_connection_map(graph, nodes_by_id, tile_grid, connections):
    """
    Builds a map of connections to/from tiles and rr nodes.
    """
    node_map = {}

    # Adds entry to the map
    def add_to_map(connection, conn_loc):
        tile = tile_grid[conn_loc.loc]

        if tile is None:
            print("WARNING: No tile for pin '{} at '{}'".format(conn_loc.pin, conn_loc.loc))
            return

        rr_pin_name = tile_pin_to_rr_pin(tile.type, conn_loc.pin)

        # Get the VPR rr node for the pin
        try:
            nodes = graph.get_nodes_for_pin((conn_loc.loc.x, conn_loc.loc.y,), rr_pin_name)
            assert len(nodes) == 1, (rr_pin_name, conn_loc.loc.x, conn_loc.loc.y)
        except KeyError as ex:
            print("WARNING: No node for pin '{}' at ({},{})".format(rr_pin_name, conn_loc.loc.x, conn_loc.loc.y))
            return

        # Convert to Node objects
        node = nodes_by_id[nodes[0][0]]

        # Add to the map
        node_map[connection] = node

    # Look for connections to/from tiles.
    for connection in connections:

        # FIXME: This is not correct if there are direct connections between
        # two different tiles!
        assert not (connection.src.type == ConnectionType.TILE and \
                    connection.dst.type == ConnectionType.TILE), connection

        # Connection to a tile
        if connection.dst.type == ConnectionType.TILE:
            add_to_map(connection, connection.dst)
            continue

        # Connection from a tile
        if connection.src.type == ConnectionType.TILE:
            add_to_map(connection, connection.src)
            continue

    return node_map

# =============================================================================


def add_l_track(graph, x0, y0, x1, y1, segment_id, switch_id):
    """
    Add a "L"-shaped track consisting of two channel nodes and a switch
    between the given two grid coordinates. The (x0, y0) determines source
    location and (x1, y1) destination (sink) location.

    Returns a tuple with indices of the first and last node.
    """
    dx = x1 - x0
    dy = y1 - y0

    assert dx != 0 or dy != 0, (x0, y0)

    nodes = [None, None]

    # Go vertically first
    if abs(dy) >= abs(dx):
        xc, yc = x0, y1

        if abs(dy):
            track = tracks.Track(
                direction = "Y",
                x_low  = min(x0, xc),
                x_high = max(x0, xc),
                y_low  = min(y0, yc),
                y_high = max(y0, yc),
            )
            nodes[0] = add_track(graph, track, segment_id)

        if abs(dx):
            track = tracks.Track(
                direction = "X",
                x_low  = min(xc, x1),
                x_high = max(xc, x1),
                y_low  = min(yc, y1),
                y_high = max(yc, y1),
            )
            nodes[1] = add_track(graph, track, segment_id)

    # Go horizontally first
    else:
        xc, yc = x1, y0

        if abs(dx):
            track = tracks.Track(
                direction = "X",
                x_low  = min(x0, xc),
                x_high = max(x0, xc),
                y_low  = min(y0, yc),
                y_high = max(y0, yc),
            )
            nodes[0] = add_track(graph, track, segment_id)

        if abs(dy):
            track = tracks.Track(
                direction = "Y",
                x_low  = min(xc, x1),
                x_high = max(xc, x1),
                y_low  = min(yc, y1),
                y_high = max(yc, y1),
            )
            nodes[1] = add_track(graph, track, segment_id)

    # In case of a horizontal or vertical only track make both nodes the same
    assert nodes[0] is not None or nodes[1] is not None

    if nodes[0] is None:
        nodes[0] = nodes[1]
    if nodes[1] is None:
        nodes[1] = nodes[0]

    # Add edge
    graph.add_edge(nodes[0].id, nodes[1].id, switch_id)
    return nodes


def add_track_chain(graph, direction, u, v0, v1, segment_id, switch_id):
    """
    Adds a chain of tracks that span the grid in the given direction.
    Returns the first and last node of the chain along with a map of
    coordinates to nodes.
    """
    node_by_v = {}
    prev_node = None

    # Make range generator
    if v0 > v1:
        coords = range(v0, v1-1, -1)
    else:
        coords = range(v0, v1+1)

    # Add track chain
    for v in coords:

        # Add track (node)
        if direction == "X":
            track = tracks.Track(
                direction = direction,
                x_low  = v,
                x_high = v,
                y_low  = u,
                y_high = u,
            )
        elif direction == "Y":
            track = tracks.Track(
                direction = direction,
                x_low  = u,
                x_high = u,
                y_low  = v,
                y_high = v,
            )
        else:
            assert False, direction

        curr_node = add_track(graph, track, segment_id)

        # Add edge from the previous one
        if prev_node is not None:
            graph.add_edge(
                prev_node.id,
                curr_node.id,
                switch_id
                )

        # No previous one, this is the first one
        else:
            start_node = curr_node

        node_by_v[v] = curr_node
        prev_node    = curr_node

    return start_node, curr_node, node_by_v


def add_tracks_for_const_network(graph, const, tile_grid):
    """
    Builds a network of CHANX/CHANY and edges to propagate signal from a 
    const source.
    
    The const network is purely artificial and does not correspond to any
    physical routing resources.

    Returns a map of const network nodes for each location.
    """

    # Get the tilegrid span
    xs = set([loc.x for loc in tile_grid])
    ys = set([loc.y for loc in tile_grid])
    xmin, ymin = min(xs), min(ys)
    xmax, ymax = max(xs), max(ys)

    # Get segment id and switch id
    segment_id = graph.get_segment_id_from_name("generic") 
    switch_id  = 0

    # Find the source tile
    src_loc = [loc for loc, t in tile_grid.items() if t is not None and t.type == "SYN_{}".format(const)]
    assert len(src_loc) == 1, const
    src_loc = src_loc[0]

    print(const, src_loc)

    # Go down from the source to the edge of the tilegrid
    entry_node, col_node, _ = add_track_chain(graph, "Y", src_loc.x, src_loc.y, 1, segment_id, switch_id)

    # Connect the tile OPIN to the column
    pin_name  = "TL-SYN_{const}.{const}0_{const}[0]".format(const=const)
    opin_node = graph.get_nodes_for_pin((src_loc[0], src_loc[1]), pin_name)
    assert len(opin_node) == 1, pin_name
    
    graph.add_edge(opin_node[0][0], entry_node.id, switch_id)

    # Got left and right from the source column over the bottommost row
    row_entry_node1, _, row_node_map1 = add_track_chain(graph, "X", 0, src_loc.x,   1,        segment_id, switch_id)
    row_entry_node2, _, row_node_map2 = add_track_chain(graph, "X", 0, src_loc.x+1, xmax - 1, segment_id, switch_id)

    # Connect rows to the column
    graph.add_edge(col_node.id, row_entry_node1.id, switch_id)
    graph.add_edge(col_node.id, row_entry_node2.id, switch_id)
    row_node_map = {**row_node_map1, **row_node_map2}

    row_node_map[0] = row_node_map[1]

    # For each column add one that spand over the entire grid height
    const_node_map = {}
    for x in range(xmin, xmax):

        # Add the column
        col_entry_node, _, col_node_map = add_track_chain(graph, "Y", x, ymin + 1, ymax - 1, segment_id, switch_id)

        # Add edge fom the horizontal row
        graph.add_edge(
            row_node_map[x].id,
            col_entry_node.id,
            switch_id
            )

        # Populate the const node map
        for y, node in col_node_map.items():
            const_node_map[Loc(x=x, y=y)] = node

    return const_node_map


def create_track_for_hop_connection(graph, connection):
    """
    Creates a HOP wire track for the given connection
    """

    # Determine whether the wire goes horizontally or vertically.
    if   connection.src.loc.y == connection.dst.loc.y:
        direction = "X"
    elif connection.src.loc.x == connection.dst.loc.x:
        direction = "Y"
    else:
        assert False, connection

    assert connection.src.loc != connection.dst.loc, connection

    # Determine the connection length
    length = max(
        abs(connection.src.loc.x - connection.dst.loc.x),
        abs(connection.src.loc.y - connection.dst.loc.y)
    )

    segment_name = "hop{}".format(length)

    # Add the track to the graph
    track = tracks.Track(
        direction = direction,
        x_low  = min(connection.src.loc.x, connection.dst.loc.x),
        x_high = max(connection.src.loc.x, connection.dst.loc.x),
        y_low  = min(connection.src.loc.y, connection.dst.loc.y),
        y_high = max(connection.src.loc.y, connection.dst.loc.y),
    )

    node = add_track(graph, track, graph.get_segment_id_from_name(segment_name))

    return node

# =============================================================================


def populate_hop_connections(graph, switchbox_models, connections):
    """
    Populates HOP connections
    """

    # Process connections
    bar   = progressbar_utils.progressbar
    conns = [c for c in connections if is_hop(c)]
    for connection in bar(conns):

        # Get switchbox models
        src_switchbox_model = switchbox_models[connection.src.loc]
        dst_switchbox_model = switchbox_models[connection.dst.loc]

        # For each mux input of the desitnation switchbox create an output
        # in the source switchbox
        inp_nodes = dst_switchbox_model.get_input_nodes(connection.dst.pin)
        for inp_node in inp_nodes:

            # Create the hop wire, use it as output node of the switchbox
            hop_node = create_track_for_hop_connection(graph, connection)

            # Create output in the source switchbox
            src_switchbox_model.create_output(connection.src.pin, hop_node)

            # Add a delayless edge
            connect(
                graph,
                hop_node,
                inp_node,
            )

            # FIXME: inp_node and hop_node could be the same.


def populate_tile_connections(graph, switchbox_models, connections, connection_to_node):
    """
    Populates switchbox to tile and tile to switchbox connections
    """

    # Process connections
    bar   = progressbar_utils.progressbar
    conns = [c for c in connections if is_tile(c)]
    for connection in bar(conns):

        # Connection to/from the local tile
        if is_local(connection):

            # Must be the same switchbox and tile
            assert connection.src.loc == connection.dst.loc, connection            
            loc = connection.src.loc

            # No switchbox model at the loc, skip.
            if loc not in switchbox_models:
                continue

            # Get the switchbox model (both locs are the same)
            switchbox_model = switchbox_models[loc]

            # Get the tile IPIN/OPIN node
            if connection not in connection_to_node:
                print("WARNING: No IPIN/OPIN node for connection {}".format(connection))
                continue

            tile_node = connection_to_node[connection]

            # To tile
            if connection.dst.type == ConnectionType.TILE:

                # Create an output in the switchbox model. Don't create a new
                # node. Use the existing IPIN one.
                sbox_node = switchbox_model.create_output(connection.src.pin, tile_node)

            # From tile
            if connection.src.type == ConnectionType.TILE:

                # Add edges between the tile node and switchbox mux inputs
                for sbox_node in switchbox_model.get_input_nodes(connection.dst.pin):

                    # Add a delayless edge
                    connect(
                        graph,
                        tile_node,
                        sbox_node,
                    )

        # Connection to/from a foreign tile
        else:

            # Get segment id and switch id
            segment_id = graph.get_segment_id_from_name("special")
            switch_id  = graph.get_delayless_switch_id()

            # Add a track connecting the two locations
            src_node, dst_node = add_l_track(
                graph,
                connection.src.loc.x, connection.src.loc.y,
                connection.dst.loc.x, connection.dst.loc.y,
                segment_id,
                switch_id
            )

            # Connect the track
            eps = [connection.src, connection.dst]
            for i, ep in enumerate(eps):

                # Endpoint at tile
                if ep.type == ConnectionType.TILE:

                    # Get the tile IPIN/OPIN node
                    if connection not in connection_to_node:
                        print("WARNING: No IPIN/OPIN node for connection {}".format(connection))
                        continue

                    node = connection_to_node[connection]

                    # To tile
                    if ep == connection.dst:
                        connect(graph, dst_node, node, switch_id)

                    # From tile
                    elif ep == connection.src:
                        connect(graph, node, src_node, switch_id)

                # Endpoint at switchbox
                elif ep.type == ConnectionType.SWITCHBOX:

                    # No switchbox model at the loc, skip.
                    if ep.loc not in switchbox_models:
                        continue

                    # Get the switchbox model (both locs are the same)
                    switchbox_model = switchbox_models[ep.loc]

                    # To switchbox
                    if ep == connection.dst:

                        # Add edges between the track node and switchbox mux inputs
                        for sbox_node in switchbox_model.get_input_nodes(ep.pin):

                            # Add a delayless edge
                            connect(
                                graph,
                                dst_node,
                                sbox_node,
                            )

                    # From switchbox
                    elif ep == connection.src:

                        # Create an output in the switchbox model. Don't create a new
                        # node. Use the existing track node.
                        sbox_node = switchbox_model.create_output(ep.pin, src_node)


def populate_const_connections(graph, switchbox_models, const_node_map):
    """
    Connects switchbox inputs that represent VCC and GND constants to
    nodes of the global const network.
    """

    bar = progressbar_utils.progressbar
    for loc, switchbox_model in bar(switchbox_models.items()):

        # Look for input connected to a const
        for pin in switchbox_model.switchbox.inputs.values():

            # Got a const input
            if pin.name in const_node_map:
                const_node = const_node_map[pin.name][loc]

                # Connect it to the switchbox input
                for inp_node in switchbox_model.get_input_nodes(pin.name):
                    connect(
                        graph,
                        const_node,
                        inp_node,
                    )

# =============================================================================


def yield_edges(edges):
    """
    Yields edges in a format acceptable by the graph serializer.
    """
    conns = set()

    # Process edges
    for edge in edges:

        # Reformat metadata
        if edge.metadata:
            metadata = [(meta.name, meta.value) for meta in edge.metadata]
        else:
            metadata = None

        # Check for repetition
        if (edge.src_node, edge.sink_node) in conns:
            print("WARNING: Removing duplicated edge from {} to {}, metadata='{}'".format(
                edge.src_node, edge.sink_node, metadata
            ))
            continue

        conns.add((edge.src_node, edge.sink_node))

        # Yield the edge
        yield (edge.src_node, edge.sink_node, edge.switch_id, metadata)

# =============================================================================


def main():
    
    # Parse arguments
    parser = argparse.ArgumentParser(description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter)

    parser.add_argument(
        "--vpr-db",
        type=str,
        required=True,
        help="VPR database file"
    )
    parser.add_argument(
        "--rr-graph-in",
        type=str,
        required=True,
        help="Input RR graph XML file"
    )
    parser.add_argument(
        "--rr-graph-out",
        type=str,
        default="rr_graph.xml",
        help="Output RR graph XML file (def. rr_graph.xml)"
    )

    args = parser.parse_args()

    # Load data from the database
    print("Loading database...")
    with open(args.vpr_db, "rb") as fp:
        db = pickle.load(fp)

        cells_library  = db["cells_library"]
        loc_map        = db["loc_map"]
        vpr_tile_types = db["vpr_tile_types"]
        vpr_tile_grid  = db["vpr_tile_grid"]
        vpr_switchbox_types = db["vpr_switchbox_types"]
        vpr_switchbox_grid  = db["vpr_switchbox_grid"]
        connections    = db["connections"]
        segments       = db["segments"]
        switches       = db["switches"]

    # Load the routing graph, build SOURCE -> OPIN and IPIN -> SINK edges.
    print("Loading rr graph...")
    xml_graph = rr_xml.Graph(
        input_file_name  = args.rr_graph_in,
        output_file_name = args.rr_graph_out,
        progressbar      = progressbar_utils.progressbar
    )

    # Add back the switches that were unused in the arch.xml and got pruned
    # byt VPR.
    for switch in switches:
        try:
            xml_graph.graph.get_switch_id(switch.name)            
            continue
        except KeyError:
            xml_graph.add_switch(
                rr.Switch(
                    id=None,
                    name=switch.name,
                    type=rr.SwitchType[switch.type.upper()],
                    timing=rr.SwitchTiming(
                        r=switch.r,
                        c_in=switch.c_in,
                        c_out=switch.c_out,
                        c_internal=switch.c_int,
                        t_del=switch.t_del,
                    ),
                    sizing=rr.SwitchSizing(
                        mux_trans_size=0,
                        buf_size=0,
                    ),
                )
            )

    print("Building maps...")

    # Add a switch map to the graph
    switch_map = {}
    for switch in xml_graph.graph.switches:
        assert switch.id not in switch_map, switch
        switch_map[switch.id] = switch

    xml_graph.graph.switch_map = switch_map

    # Build node id to node map
    nodes_by_id = {node.id: node for node in xml_graph.graph.nodes}

    # Build tile pin names to rr node ids map
    tile_pin_to_node = build_tile_pin_to_node_map(xml_graph.graph, vpr_tile_types, vpr_tile_grid)

    # Add const network
    const_node_map = {}
    for const in ["VCC", "GND"]:
        m = add_tracks_for_const_network(xml_graph.graph, const, vpr_tile_grid)
        const_node_map[const] = m

    # Connection to node map. Map Connection objects to rr graph node ids
    connection_to_node = {}

    # Build a map of connections to/from tiles and rr nodes. The map points 
    # to an IPIN/OPIN node for a connection that mentions it.
    #
    # FIXME: This won't work for direct tile-tile connections! But there are
    # none.
    node_map = build_tile_connection_map(xml_graph.graph, nodes_by_id, vpr_tile_grid, connections)
    connection_to_node.update(node_map)

    # Add switchbox models.
    print("Building switchbox models...")
    switchbox_models = {}
    for loc, type in progressbar_utils.progressbar(vpr_switchbox_grid.items()):

        phy_loc = loc_map.bwd[loc]

        switchbox_models[loc] = SwitchboxModel(
            graph = xml_graph.graph,
            loc = loc,
            phy_loc = phy_loc,
            switchbox = vpr_switchbox_types[type],
        )    

    # Populate connections to the switchbox models
    print("Populating connections...")
    populate_hop_connections(xml_graph.graph, switchbox_models, connections)
    populate_tile_connections(xml_graph.graph, switchbox_models, connections, connection_to_node)
    populate_const_connections(xml_graph.graph, switchbox_models, const_node_map)

    # Create channels from tracks
    pad_segment_id = xml_graph.graph.get_segment_id_from_name("pad")
    channels_obj = xml_graph.graph.create_channels(pad_segment=pad_segment_id)

    # Remove padding channels
    print("Removing padding nodes...")
    xml_graph.graph.nodes = [n for n in xml_graph.graph.nodes if n.capacity > 0]

    # Write the routing graph
    nodes_obj = xml_graph.graph.nodes
    edges_obj = xml_graph.graph.edges
    node_remap = lambda x: x

    print("Serializing the rr graph...")
    xml_graph.serialize_to_xml(
        channels_obj=channels_obj,
        connection_box_obj=None,
        nodes_obj=nodes_obj,
        edges_obj=yield_edges(edges_obj),
        node_remap=node_remap,
    )

# =============================================================================

if __name__ == "__main__":
    main()
