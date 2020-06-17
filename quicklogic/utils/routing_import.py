#!/usr/bin/env python3
import argparse
import pickle
import itertools
import re
from collections import defaultdict

import lxml.etree as ET

from lib.rr_graph import tracks
import lib.rr_graph.graph2 as rr
import lib.rr_graph_xml.graph2 as rr_xml
from lib import progressbar_utils

from data_structs import *
from utils import yield_muxes, fixup_pin_name

# =============================================================================

CLOCK_CELLS = [
    "CLOCK",
    "GMUX",
    "QMUX",
    "CAND"
]

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


def is_direct(connection):
    """
    Returns True if the connections spans two tiles directly. Not necessarly
    at the same location
    """

    if connection.src.type == ConnectionType.TILE and \
       connection.dst.type == ConnectionType.TILE:
        return True

    return False

def is_clock(connection):
    """
    Returns True if the connection spans two clock cells
    """

    if connection.src.type == ConnectionType.CLOCK or \
       connection.dst.type == ConnectionType.CLOCK:
        return True

    return False

def is_local(connection):
    """
    Returns true if a connection is local.
    """
    return connection.src.loc == connection.dst.loc


# =============================================================================


def add_track(graph, track, segment_id, node_timing=None):
    """
    Adds a track to the graph. Returns the node object representing the track
    node.
    """

    if node_timing is None:
        node_timing = rr.NodeTiming(r=0.0, c=0.0)

    node_id = graph.add_track(track, segment_id, timing=node_timing)
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
            direction=direction,
            x_low=loc.x,
            x_high=loc.x,
            y_low=loc.y,
            y_high=loc.y,
        ), segment_id
    )


# =============================================================================


def node_joint_location(node_a, node_b):
    """
    Given two VPR nodes returns a location of the point where they touch each
    other.
    """

    loc_a1 = Loc(node_a.loc.x_low, node_a.loc.y_low)
    loc_a2 = Loc(node_a.loc.x_high, node_a.loc.y_high)

    loc_b1 = Loc(node_b.loc.x_low, node_b.loc.y_low)
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


def add_edge(
        graph, src_node_id, dst_node_id, switch_id, meta_name=None,
        meta_value=""
):
    """
    Adds an edge to the routing graph. If the given switch corresponds to a
    "pass" type switch then adds two edges going both ways.
    """

    # Sanity check
    assert src_node_id != dst_node_id, \
        (src_node_id, dst_node_id, switch_id, meta_name, meta_value)

    # Connect src to dst
    graph.add_edge(src_node_id, dst_node_id, switch_id, meta_name, meta_value)

    # Check if the switch is of the "pass" type. If so then add an edge going
    # in the opposite way.
    switch = graph.switch_map[switch_id]
    if switch.type in [rr.SwitchType.SHORT, rr.SwitchType.PASS_GATE]:

        graph.add_edge(
            dst_node_id, src_node_id, switch_id, meta_name, meta_value
        )


def connect(
        graph,
        src_node,
        dst_node,
        switch_id=None,
        segment_id=None,
        meta_name=None,
        meta_value=""
):
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

    src -> [delayless] -> pad -> [desired switch] -> dst

    Otherwise the connection is made directly

    src -> [desired switch] -> dst

    The influence of whether the rules are obeyed or not on the actual VPR
    behavior is unclear.
    """

    # Use the default delayless switch if none is given
    if switch_id is None:
        switch_id = graph.get_delayless_switch_id()

    # Determine which segment to use if none given
    if segment_id is None:
        # If the source is IPIN/OPIN then use the same segment as used by
        # the destination.
        # If the destination is IPIN/OPIN then do the opposite.
        # Finally if both are CHANX/CHANY then use the source's segment.

        if src_node.type in [rr.NodeType.IPIN, rr.NodeType.OPIN]:
            segment_id = dst_node.segment.segment_id
        elif dst_node.type in [rr.NodeType.IPIN, rr.NodeType.OPIN]:
            segment_id = src_node.segment.segment_id
        else:
            segment_id = src_node.segment.segment_id

    # CHANX to CHANY or vice-versa
    if src_node.type == rr.NodeType.CHANX and dst_node.type == rr.NodeType.CHANY or \
       src_node.type == rr.NodeType.CHANY and dst_node.type == rr.NodeType.CHANX:

        # Check loc
        node_joint_location(src_node, dst_node)

        # Connect directly
        add_edge(
            graph, src_node.id, dst_node.id, switch_id, meta_name, meta_value
        )

    # CHANX to CHANX or CHANY to CHANY
    elif src_node.type == rr.NodeType.CHANX and dst_node.type == rr.NodeType.CHANX or \
         src_node.type == rr.NodeType.CHANY and dst_node.type == rr.NodeType.CHANY:

        loc = node_joint_location(src_node, dst_node)
        direction = "X" if src_node.type == rr.NodeType.CHANY else "Y"

        # Padding node
        pad_node = add_node(graph, loc, direction, segment_id)

        # Connect through the padding node
        add_edge(
            graph, src_node.id, pad_node.id, graph.get_delayless_switch_id()
        )

        add_edge(
            graph, pad_node.id, dst_node.id, switch_id, meta_name, meta_value
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
            pad_node = add_node(graph, loc, "Y", segment_id)

            # Connect through the padding node
            add_edge(
                graph, src_node.id, pad_node.id,
                graph.get_delayless_switch_id()
            )

            add_edge(
                graph, pad_node.id, dst_node.id, switch_id, meta_name,
                meta_value
            )

        # Connected to CHANY
        elif dst_node.type == rr.NodeType.CHANY:

            # Directly
            add_edge(
                graph, src_node.id, dst_node.id, switch_id, meta_name,
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
            pad_node = add_node(graph, loc, "X", segment_id)

            # Connect through the padding node
            add_edge(
                graph, src_node.id, pad_node.id,
                graph.get_delayless_switch_id()
            )

            add_edge(
                graph, pad_node.id, dst_node.id, switch_id, meta_name,
                meta_value
            )

        # Connected to CHANX
        elif src_node.type == rr.NodeType.CHANX:

            # Directly
            add_edge(
                graph, src_node.id, dst_node.id, switch_id, meta_name,
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
    """
    Represents a model of connectivity of a concrete instance of a switchbox.
    """

    def __init__(self, graph, loc, phy_loc, switchbox):
        self.graph = graph
        self.loc = loc
        self.phy_loc = phy_loc
        self.switchbox = switchbox

        self.mux_input_to_node = {}
        self.mux_output_to_node = {}

        self.input_to_node = {}

        self._build()

    @staticmethod
    def get_chan_dirs_for_stage(stage):
        """
        Returns channel directions for inputs and outputs of a stage.
        """

        if stage.type == "HIGHWAY":
            return "Y", "X"

        elif stage.type == "STREET":
            dir_inp = "Y" if (stage.id % 2) else "X"
            dir_out = "X" if (stage.id % 2) else "Y"
            return dir_inp, dir_out

        else:
            assert False, stage.type

    def _create_muxes(self):
        """
        Creates nodes for muxes and internal edges within them. Annotates the
        internal edges with fasm data.

        Builds maps of muxs' inputs and outpus to VPR nodes.
        """

        # Build mux driver timing map. Assign each mux output its timing data
        driver_timing = {}
        for connection in self.switchbox.connections:
            src = connection.src
            dst = connection.dst

            stage = self.switchbox.stages[src.stage_id]
            switch = stage.switches[src.switch_id]
            mux = switch.muxes[src.mux_id]
            pin = mux.inputs[src.pin_id]

            if pin.id not in mux.timing:
                continue

            timing = mux.timing[pin.id].driver

            key = (src.stage_id, src.switch_id, src.mux_id)
            if key in driver_timing:
                assert driver_timing[key] == timing, \
                    (self.loc, key, driver_timing[key], timing)
            else:
                driver_timing[key] = timing

        # Create muxes
        segment_id = self.graph.get_segment_id_from_name("sbox")

        for stage, switch, mux in yield_muxes(self.switchbox):
            dir_inp, dir_out = self.get_chan_dirs_for_stage(stage)

            # Output node
            key = (stage.id, switch.id, mux.id)
            assert key not in self.mux_output_to_node

            out_node = add_node(self.graph, self.loc, dir_out, segment_id)
            self.mux_output_to_node[key] = out_node

            # Intermediate output node
            int_node = add_node(self.graph, self.loc, dir_out, segment_id)

            # Get switch id for the switch assigned to the driver. If
            # there is none then use the delayless switch. Probably the
            # driver is connected to a const.
            if key in driver_timing:
                switch_id = self.graph.get_switch_id(
                    driver_timing[key].vpr_switch
                )
            else:
                switch_id = self.graph.get_delayless_switch_id()

            # Output driver edge
            connect(
                self.graph,
                int_node,
                out_node,
                switch_id=switch_id,
                segment_id=segment_id,
            )

            # Input nodes + mux edges
            for pin in mux.inputs.values():

                key = (stage.id, switch.id, mux.id, pin.id)
                assert key not in self.mux_input_to_node

                # Input node
                inp_node = add_node(self.graph, self.loc, dir_inp, segment_id)
                self.mux_input_to_node[key] = inp_node

                # Get mux metadata
                metadata = self._get_metadata_for_mux(
                    stage, switch, mux, pin.id
                )

                if len(metadata):
                    meta_name = "fasm_features"
                    meta_value = "\n".join(metadata)
                else:
                    meta_name = None
                    meta_value = ""

                # Get switch id for the switch assigned to the mux edge. If
                # there is none then use the delayless switch. Probably the
                # edge is connected to a const.
                if pin.id in mux.timing:
                    switch_id = self.graph.get_switch_id(
                        mux.timing[pin.id].sink.vpr_switch
                    )
                else:
                    switch_id = self.graph.get_delayless_switch_id()

                # Mux switch with appropriate timing and fasm metadata
                connect(
                    self.graph,
                    inp_node,
                    int_node,
                    switch_id=switch_id,
                    segment_id=segment_id,
                    meta_name=meta_name,
                    meta_value=meta_value,
                )

    def _connect_muxes(self):
        """
        Creates VPR edges that connects muxes within the switchbox.
        """

        segment_id = self.graph.get_segment_id_from_name("sbox")
        switch_id = self.graph.get_switch_id("short")

        # Add internal connections between muxes.
        for connection in self.switchbox.connections:
            src = connection.src
            dst = connection.dst

            # Check
            assert src.pin_id == 0, src
            assert src.pin_direction == PinDirection.OUTPUT, src

            # Get the input node
            key = (dst.stage_id, dst.switch_id, dst.mux_id, dst.pin_id)
            dst_node = self.mux_input_to_node[key]

            # Get the output node
            key = (src.stage_id, src.switch_id, src.mux_id)
            src_node = self.mux_output_to_node[key]

            # Connect
            connect(
                self.graph,
                src_node,
                dst_node,
                switch_id=switch_id,
                segment_id=segment_id
            )

    def _create_input_drivers(self):
        """
        Creates VPR nodes and edges that model input connectivity of the
        switchbox.
        """

        # Create a driver map containing all mux pin locations that are
        # connected to a driver. The map is indexed by (pin_name, vpr_switch)
        # and groups togeather inputs that should be driver by a specific
        # switch due to the timing model.
        driver_map = defaultdict(lambda: [])

        for pin in self.switchbox.inputs.values():
            for loc in pin.locs:

                stage = self.switchbox.stages[loc.stage_id]
                switch = stage.switches[loc.switch_id]
                mux = switch.muxes[loc.mux_id]
                pin = mux.inputs[loc.pin_id]

                if pin.id not in mux.timing:
                    vpr_switch = None
                else:
                    vpr_switch = mux.timing[pin.id].driver.vpr_switch

                key = (pin.name, vpr_switch)
                driver_map[key].append(loc)

        # Create input nodes for each input pin
        segment_id = self.graph.get_segment_id_from_name("sbox")

        for pin in self.switchbox.inputs.values():

            node = add_node(self.graph, self.loc, "Y", segment_id)

            assert pin.name not in self.input_to_node, pin.name
            self.input_to_node[pin.name] = node

        # Create driver nodes, connect everything
        for (pin_name, vpr_switch), locs in driver_map.items():

            # Create the driver node
            drv_node = add_node(self.graph, self.loc, "X", segment_id)

            # Connect input node to the driver node. Use the switch with timing.
            inp_node = self.input_to_node[pin_name]

            # Get switch id for the switch assigned to the driver. If
            # there is none then use the delayless switch. Probably the
            # driver is connected to a const.
            if vpr_switch is not None:
                switch_id = self.graph.get_switch_id(vpr_switch)
            else:
                switch_id = self.graph.get_delayless_switch_id()

            # Connect
            connect(
                self.graph,
                inp_node,
                drv_node,
                switch_id=switch_id,
                segment_id=segment_id
            )

            # Now connect the driver node with its loads
            switch_id = self.graph.get_switch_id("short")
            for loc in locs:

                key = (loc.stage_id, loc.switch_id, loc.mux_id, loc.pin_id)
                dst_node = self.mux_input_to_node[key]

                connect(
                    self.graph,
                    drv_node,
                    dst_node,
                    switch_id=switch_id,
                    segment_id=segment_id
                )

    def _build(self):
        """
        Build the switchbox model
        """

        # Create and connect muxes
        self._create_muxes()
        self._connect_muxes()

        # Create and connect input drivers models
        self._create_input_drivers()

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
            feature = "I_highway.IM{}.I_pg{}".format(switch.id, src_pin_id)

        # A mux in the STREET stage
        elif stage.type == "STREET":
            feature = "I_street.Isb{}{}.I_M{}.I_pg{}".format(
                stage.id + 1, switch.id + 1, mux.id, src_pin_id
            )

        else:
            assert False, stage

        metadata.append(".".join([prefix, feature]))
        return metadata

    def get_input_node(self, pin_name):
        """
        Returns a VPR node associated with the given input of the switchbox
        """
        return self.input_to_node[pin_name]

    def get_output_node(self, pin_name):
        """
        Returns a VPR node associated with the given output of the switchbox
        """

        # Get the output pin
        pin = self.switchbox.outputs[pin_name]

        assert len(pin.locs) == 1
        loc = pin.locs[0]

        # Return its node
        key = (loc.stage_id, loc.switch_id, loc.mux_id)
        return self.mux_output_to_node[key]


# =============================================================================


class QmuxModel(object):
    """
    A model of a QMUX cell implemented in the "route through" manner using
    RR nodes and edges.

    A QMUX has the following clock inputs
     - 0: QCLKIN0
     - 1: QCLKIN1
     - 2: QCLKIN2
     - 3: HSCKIN (from routing)

    The selection is controlled by a binary value of {IS1, IS0}. Both of the
    pins are connected to the switchbox.

    Since the QMUX is to be modelled using routing resources only, the part
    of the switchbox (of the whole switchbox) controlling the IS0 and IS1 pins
    will be removed. Appropriate fasm features will be attached to the edges
    that will model the QMUX. This will mimic the switchbox operation.

    The HSCKIN input is not modelled so the global clock network cannot be
    entered at a QMUX.
    """

    def __init__(self, graph, cell, phy_loc, connections, node_map):
        self.graph = graph
        self.cell = cell
        self.phy_loc = phy_loc

        self.connections = [c for c in connections if is_clock(c)]
        self.connection_loc_to_node = node_map

        self._build()

    def _build(self):

        # Get segment and switch id
        segment_id = self.graph.get_segment_id_from_name("clock")
        switch_id = self.graph.get_delayless_switch_id()

        # Get the GMUX to QMUX connections
        eps = {}
        for connection in self.connections:
            if connection.dst.type == ConnectionType.CLOCK:
                dst_cell, dst_pin = connection.dst.pin.split(".")

                if dst_cell == self.cell.name and dst_pin.startswith("QCLKIN"):
                    eps[dst_pin] = connection.dst

        # Get the QMUX to CAND connection
        for connection in self.connections:
            if connection.src.type == ConnectionType.CLOCK:
                src_cell, src_pin = connection.src.pin.split(".")

                if src_cell == self.cell.name and src_pin == "IZ":
                    eps["IZ"] = connection.src

        # Validate
        for pin in ["IZ", "QCLKIN0", "QCLKIN1", "QCLKIN2"]:
            if pin not in eps:
                print("ERROR: Coulnd't find rr node for {}.{}".format(self.cell.name, pin))
                return

        # Add edges modelling the QMUX
        for i in [0, 1, 2]:
            pin = "QCLKIN{}".format(i)

            src_node = self.connection_loc_to_node[eps[pin]]
            dst_node = self.connection_loc_to_node[eps["IZ"]]

            # Make edge metadata
            metadata = self._get_metadata(i)

            if len(metadata):
                meta_name = "fasm_features"
                meta_value = "\n".join(metadata)
            else:
                meta_name = None
                meta_value = ""

            # Mux switch with appropriate timing and fasm metadata
            connect(
                self.graph,
                src_node,
                dst_node,
                switch_id=switch_id,
                segment_id=segment_id,
                meta_name=meta_name,
                meta_value=meta_value,
            )

    def _get_metadata(self, selection):
        """
        """
        metadata = []

        # Format prefix
        prefix = "X{}Y{}".format(self.phy_loc.x, self.phy_loc.y)

        # TODO

        return metadata


class CandModel(object):
    """
    A model of a CAND cell implemented in the "route through" manner using
    RR nodes and edges.

    A CAND cell has aninput IC connected to QMUX via a dedicated route, an
    output connected to its clock column and a dynamic enable input EN
    connected to the routing network.

    We won't use the enable input EN so its not modelled in any way. The
    CAND cell is statically enabled or disabled via the bitstream. There is
    a single edge that models the cell with appropriate fasm features attached.
    """

    def __init__(self, graph, cell, phy_loc, connections, node_map, cand_node_map):
        self.graph = graph
        self.cell = cell
        self.phy_loc = phy_loc

        self.connections = [c for c in connections if is_clock(c)]
        self.connection_loc_to_node = node_map

        self.cand_node_map = cand_node_map

        self._build()

    def _build(self):

        # Get segment and switch id
        segment_id = self.graph.get_segment_id_from_name("clock")
        switch_id = self.graph.get_delayless_switch_id()

        # Get the CAND name
        cand_name = self.cell.name.split("_", maxsplit=1)[0]
        # Get the column clock entry node
        col_node = self.cand_node_map[cand_name][self.cell.loc]

        # Get the QMUX to CAND connection
        for connection in self.connections:
            if connection.dst.type == ConnectionType.CLOCK:
                dst_cell, dst_pin = connection.dst.pin.split(".")

                if dst_cell == self.cell.name and dst_pin == "IC":
                    ep = connection.dst
                    break
        else:
            print("ERROR: Coulnd't find rr node for {}.{}".format(self.cell.name, "IC"))
            return

        # Get the node for the connection destination
        row_node = self.connection_loc_to_node[ep]

        # Edge metadata that when used switches the CAND cell from the
        # "Static Disable" to "Static Enable" mode.
        metadata = self._get_metadata()

        if len(metadata):
            meta_name = "fasm_features"
            meta_value = "\n".join(metadata)
        else:
            meta_name = None
            meta_value = ""

        # Mux switch with appropriate timing and fasm metadata
        connect(
            self.graph,
            row_node,
            col_node,
            switch_id=switch_id,
            segment_id=segment_id,
            meta_name=meta_name,
            meta_value=meta_value,
        )

    def _get_metadata(self):
        """
        Formats a list of fasm features to be appended to the CAND modelling
        edge.
        """
        metadata = []

        # Format prefix
        prefix = "X{}Y{}".format(self.phy_loc.x, self.phy_loc.y)

        # TODO

        return metadata

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
                nodes = graph.get_nodes_for_pin((
                    loc.x,
                    loc.y,
                ), rr_pin_name)
                assert len(nodes) == 1, (rr_pin_name, loc.x, loc.y)
            except KeyError as ex:
                print(
                    "WARNING: No node for pin '{}' at ({},{})".format(
                        rr_pin_name, loc.x, loc.y
                    )
                )
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
    def add_to_map(conn_loc):

        tile = tile_grid.get(conn_loc.loc, None)
        if tile is None:
            print(
                "WARNING: No tile for pin '{} at '{}'".format(
                    conn_loc.pin, conn_loc.loc
                )
            )
            return

        rr_pin_name = tile_pin_to_rr_pin(tile.type, conn_loc.pin)

        # Get the VPR rr node for the pin
        try:
            nodes = graph.get_nodes_for_pin(
                (
                    conn_loc.loc.x,
                    conn_loc.loc.y,
                ), rr_pin_name
            )
            assert len(nodes
                       ) == 1, (rr_pin_name, conn_loc.loc.x, conn_loc.loc.y)
        except KeyError as ex:
            print(
                "WARNING: No node for pin '{}' at ({},{})".format(
                    rr_pin_name, conn_loc.loc.x, conn_loc.loc.y
                )
            )
            return

        # Convert to Node objects
        node = nodes_by_id[nodes[0][0]]

        # Add to the map
        node_map[conn_loc] = node

    # Look for connection endpoints that mention tiles
    endpoints = set(
        [c.src for c in connections if c.src.type == ConnectionType.TILE]
    )
    endpoints |= set(
        [c.dst for c in connections if c.dst.type == ConnectionType.TILE]
    )

    # Build the map
    for ep in endpoints:
        add_to_map(ep)

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
                direction="Y",
                x_low=min(x0, xc),
                x_high=max(x0, xc),
                y_low=min(y0, yc),
                y_high=max(y0, yc),
            )
            nodes[0] = add_track(graph, track, segment_id)

        if abs(dx):
            track = tracks.Track(
                direction="X",
                x_low=min(xc, x1),
                x_high=max(xc, x1),
                y_low=min(yc, y1),
                y_high=max(yc, y1),
            )
            nodes[1] = add_track(graph, track, segment_id)

    # Go horizontally first
    else:
        xc, yc = x1, y0

        if abs(dx):
            track = tracks.Track(
                direction="X",
                x_low=min(x0, xc),
                x_high=max(x0, xc),
                y_low=min(y0, yc),
                y_high=max(y0, yc),
            )
            nodes[0] = add_track(graph, track, segment_id)

        if abs(dy):
            track = tracks.Track(
                direction="Y",
                x_low=min(xc, x1),
                x_high=max(xc, x1),
                y_low=min(yc, y1),
                y_high=max(yc, y1),
            )
            nodes[1] = add_track(graph, track, segment_id)

    # In case of a horizontal or vertical only track make both nodes the same
    assert nodes[0] is not None or nodes[1] is not None

    if nodes[0] is None:
        nodes[0] = nodes[1]
    if nodes[1] is None:
        nodes[1] = nodes[0]

    # Add edge connecting the two nodes if needed
    if nodes[0].id != nodes[1].id:
        add_edge(graph, nodes[0].id, nodes[1].id, switch_id)

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
        coords = range(v0, v1 - 1, -1)
    else:
        coords = range(v0, v1 + 1)

    # Add track chain
    for v in coords:

        # Add track (node)
        if direction == "X":
            track = tracks.Track(
                direction=direction,
                x_low=v,
                x_high=v,
                y_low=u,
                y_high=u,
            )
        elif direction == "Y":
            track = tracks.Track(
                direction=direction,
                x_low=u,
                x_high=u,
                y_low=v,
                y_high=v,
            )
        else:
            assert False, direction

        curr_node = add_track(graph, track, segment_id)

        # Add edge from the previous one
        if prev_node is not None:
            add_edge(graph, prev_node.id, curr_node.id, switch_id)

        # No previous one, this is the first one
        else:
            start_node = curr_node

        node_by_v[v] = curr_node
        prev_node = curr_node

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
    segment_id = graph.get_segment_id_from_name(const.lower())
    switch_id = graph.get_delayless_switch_id()

    # Find the source tile
    src_loc = [
        loc for loc, t in tile_grid.items()
        if t is not None and t.type == "SYN_{}".format(const)
    ]
    assert len(src_loc) == 1, const
    src_loc = src_loc[0]

    print(const, src_loc)

    # Go down from the source to the edge of the tilegrid
    entry_node, col_node, _ = add_track_chain(
        graph, "Y", src_loc.x, src_loc.y, 1, segment_id, switch_id
    )

    # Connect the tile OPIN to the column
    pin_name = "TL-SYN_{const}.{const}0_{const}[0]".format(const=const)
    opin_node = graph.get_nodes_for_pin((src_loc[0], src_loc[1]), pin_name)
    assert len(opin_node) == 1, pin_name

    add_edge(graph, opin_node[0][0], entry_node.id, switch_id)

    # Got left and right from the source column over the bottommost row
    row_entry_node1, _, row_node_map1 = add_track_chain(
        graph, "X", 0, src_loc.x, 1, segment_id, switch_id
    )
    row_entry_node2, _, row_node_map2 = add_track_chain(
        graph, "X", 0, src_loc.x + 1, xmax - 1, segment_id, switch_id
    )

    # Connect rows to the column
    add_edge(graph, col_node.id, row_entry_node1.id, switch_id)
    add_edge(graph, col_node.id, row_entry_node2.id, switch_id)
    row_node_map = {**row_node_map1, **row_node_map2}

    row_node_map[0] = row_node_map[1]

    # For each column add one that spand over the entire grid height
    const_node_map = {}
    for x in range(xmin, xmax):

        # Add the column
        col_entry_node, _, col_node_map = add_track_chain(
            graph, "Y", x, ymin + 1, ymax - 1, segment_id, switch_id
        )

        # Add edge fom the horizontal row
        add_edge(graph, row_node_map[x].id, col_entry_node.id, switch_id)

        # Populate the const node map
        for y, node in col_node_map.items():
            const_node_map[Loc(x=x, y=y)] = node

    return const_node_map


def create_track_for_hop_connection(graph, connection):
    """
    Creates a HOP wire track for the given connection
    """

    # Determine whether the wire goes horizontally or vertically.
    if connection.src.loc.y == connection.dst.loc.y:
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
        direction=direction,
        x_low=min(connection.src.loc.x, connection.dst.loc.x),
        x_high=max(connection.src.loc.x, connection.dst.loc.x),
        y_low=min(connection.src.loc.y, connection.dst.loc.y),
        y_high=max(connection.src.loc.y, connection.dst.loc.y),
    )

    node = add_track(
        graph, track, graph.get_segment_id_from_name(segment_name)
    )

    return node



# =============================================================================


def populate_hop_connections(graph, switchbox_models, connections):
    """
    Populates HOP connections
    """

    # Process connections
    bar = progressbar_utils.progressbar
    conns = [c for c in connections if is_hop(c)]
    for connection in bar(conns):

        # Get switchbox models
        src_switchbox_model = switchbox_models[connection.src.loc]
        dst_switchbox_model = switchbox_models[connection.dst.loc]

        # Get nodes
        src_node = src_switchbox_model.get_output_node(connection.src.pin)
        dst_node = dst_switchbox_model.get_input_node(connection.dst.pin)

        # Create the hop wire, use it as output node of the switchbox
        hop_node = create_track_for_hop_connection(graph, connection)

        # Connect
        connect(graph, src_node, hop_node)

        connect(graph, hop_node, dst_node)


def populate_tile_connections(
        graph, switchbox_models, connections, connection_loc_to_node
):
    """
    Populates switchbox to tile and tile to switchbox connections
    """

    # Process connections
    bar = progressbar_utils.progressbar
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

            # To tile
            if connection.dst.type == ConnectionType.TILE:
                if connection.dst not in connection_loc_to_node:
                    print(
                        "WARNING: No IPIN node for connection {}".
                        format(connection)
                    )
                    continue

                tile_node = connection_loc_to_node[connection.dst]
                sbox_node = switchbox_model.get_output_node(connection.src.pin)

                connect(graph, sbox_node, tile_node)

            # From tile
            if connection.src.type == ConnectionType.TILE:
                if connection.src not in connection_loc_to_node:
                    print(
                        "WARNING: No OPIN node for connection {}".
                        format(connection)
                    )
                    continue

                tile_node = connection_loc_to_node[connection.src]
                sbox_node = switchbox_model.get_input_node(connection.dst.pin)

                connect(graph, tile_node, sbox_node)

        # Connection to/from a foreign tile
        else:

            # Get segment id and switch id
            segment_id = graph.get_segment_id_from_name("special")
            switch_id = graph.get_delayless_switch_id()

            # Add a track connecting the two locations
            src_node, dst_node = add_l_track(
                graph, connection.src.loc.x, connection.src.loc.y,
                connection.dst.loc.x, connection.dst.loc.y, segment_id,
                switch_id
            )

            # Connect the track
            eps = [connection.src, connection.dst]
            for i, ep in enumerate(eps):

                # Endpoint at tile
                if ep.type == ConnectionType.TILE:

                    # To tile
                    if ep == connection.dst:
                        if ep not in connection_loc_to_node:
                            print(
                                "WARNING: No IPIN node for connection {}".
                                format(connection)
                            )
                            continue

                        node = connection_loc_to_node[ep]
                        connect(graph, dst_node, node, switch_id)

                    # From tile
                    elif ep == connection.src:
                        if ep not in connection_loc_to_node:
                            print(
                                "WARNING: No OPIN node for connection {}".
                                format(connection)
                            )
                            continue

                        node = connection_loc_to_node[ep]
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
                        sbox_node = switchbox_model.get_input_node(ep.pin)

                        connect(graph, dst_node, sbox_node)

                    # From switchbox
                    elif ep == connection.src:
                        sbox_node = switchbox_model.get_output_node(ep.pin)

                        connect(graph, sbox_node, src_node)

def populate_direct_connections(
        graph, connections, connection_loc_to_node
):
    """
    Populates all direct tile-to-tile connections.
    """

    # Process connections
    bar = progressbar_utils.progressbar
    conns = [c for c in connections if is_direct(c)]
    for connection in bar(conns):
        print("Direct:", connection)

        # Get segment id and switch id
        if connection.src.pin.startswith("CLOCK"):
            segment_id = graph.get_segment_id_from_name("clock")
            switch_id = graph.get_delayless_switch_id()

        else:
            segment_id = graph.get_segment_id_from_name("special")
            switch_id = graph.get_delayless_switch_id()

        # Get tile nodes
        src_tile_node = connection_loc_to_node.get(connection.src, None)
        dst_tile_node = connection_loc_to_node.get(connection.dst, None)

        # Couldn't find at least one endpoint node
        if src_tile_node is None or dst_tile_node is None:
            if src_tile_node is None:
                print(
                    "WARNING: No OPIN node for direct connection {}".
                    format(connection)
                )

            if dst_tile_node is None:
                print(
                    "WARNING: No IPIN node for direct connection {}".
                    format(connection)
                )

            continue

        # Add a track connecting the two locations
        src_track_node, dst_track_node = add_l_track(
            graph, 
            src_tile_node.loc.x_low, src_tile_node.loc.y_low,
            dst_tile_node.loc.x_low, dst_tile_node.loc.y_low,
            segment_id,
            switch_id
        )

        # Connect the track endpoints to the IPIN and OPIN
        connect(graph, src_tile_node, src_track_node)
        connect(graph, dst_track_node, dst_tile_node)


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
                sbox_node = switchbox_model.get_input_node(pin.name)

                connect(
                    graph,
                    const_node,
                    sbox_node,
                )

def populate_cand_connections(graph, switchbox_models, cand_node_map):
    """
    Populates global clock network to switchbox connections. These all the
    CANDn inputs of a switchbox.
    """

    bar = progressbar_utils.progressbar
    for loc, switchbox_model in bar(switchbox_models.items()):

        # Look for input connected to a CAND
        for pin in switchbox_model.switchbox.inputs.values():

            # Got a CAND input
            if pin.name in cand_node_map:
                cand_node = cand_node_map[pin.name][loc]
                sbox_node = switchbox_model.get_input_node(pin.name)

                connect(
                    graph,
                    cand_node,
                    sbox_node,
                )

# =============================================================================


def create_quadrant_clock_tracks(graph, connections, connection_loc_to_node):
    """
    Creates tracks representing global clock network routes namely all
    connections between GMUXes and QMUXes as well as QMUXes to CANDs.
    """

    node_map = {}

    # Get segment id and switch id
    segment_id = graph.get_segment_id_from_name("clock")
    switch_id = graph.get_delayless_switch_id()

    # Process connections
    bar = progressbar_utils.progressbar
    conns = [c for c in connections if is_clock(c)]
    for connection in bar(conns):

        # Source
        if connection.src.type == ConnectionType.TILE:
            src_node = connection_loc_to_node.get(connection.src, None)
            if src_node is None:
                print(
                    "WARNING: No OPIN node for clock connection {}".
                    format(connection)
                )
                continue

        elif connection.src.type == ConnectionType.CLOCK:
            src_node = None

        else:
            assert False, connection

        # Destination
        if connection.dst.type == ConnectionType.TILE:
            dst_node = connection_loc_to_node.get(connection.dst, None)
            if dst_node is None:
                print(
                    "WARNING: No IPIN node for clock connection {}".
                    format(connection)
                )
                continue

        elif connection.dst.type == ConnectionType.CLOCK:
            dst_node = None

        else:
            assert False, connection

        # Add a track connecting the two locations
        # Some CAND cells share the same physical location as QMUX cells.
        # In that case add a single "jump" node
        if connection.src.loc == connection.dst.loc:
            src_track_node = add_node(
                graph,
                connection.src.loc,
                "X",
                segment_id
            )
            dst_track_node = src_track_node

        else:
            src_track_node, dst_track_node = add_l_track(
                graph, 
                connection.src.loc.x, connection.src.loc.y,
                connection.dst.loc.x, connection.dst.loc.y,
                segment_id,
                switch_id
            )

        # Connect the OPIN
        if src_node is not None:
            connect(graph, src_node, src_track_node)

        # Add to the node map.
        else:
            ep = connection.src

            # If not already there, add it
            if ep not in node_map:
                node_map[ep] = src_track_node

            # Add a connection to model the fan-out
            else:
                connect(graph, node_map[ep], src_track_node)

        # Connect the IPIN
        if dst_node is not None:
            connect(graph, dst_track_node, dst_node)

        # Add to the node map. Since this is a destination there cannot be any
        # fan-in.
        else:
            ep = connection.dst
            assert ep not in node_map, ep
            node_map[ep] = dst_track_node

    return node_map


def create_column_clock_tracks(graph, clock_cells, quadrants):
    """
    This function adds tracks for clock column routes. It returns a map of
    "assess points" to that tracks to be used by switchbox connections.
    """

    CAND_RE = re.compile(r"^(?P<name>CAND[0-4])_(?P<quad>[A-Z]+)_(?P<col>[0-9]+)$")

    # Get segment id and switch id
    segment_id = graph.get_segment_id_from_name("clock")
    switch_id = graph.get_delayless_switch_id()

    # Process CAND cells
    cand_node_map = {}

    for cell in clock_cells.values():

        # A clock column is defined by a CAND cell
        if cell.type != "CAND":
            continue

        # Get index and quadrant
        match = CAND_RE.match(cell.name)
        if not match:
            continue

        cand_name = match.group("name")
        cand_quad = match.group("quad")

        quadrant = quadrants[cand_quad]

        # Add track chains going upwards and downwards from the CAND cell
        up_entry_node, _, up_node_map = add_track_chain(
            graph, "Y", cell.loc.x, cell.loc.y,     quadrant.y0, segment_id, switch_id
        )
        dn_entry_node, _, dn_node_map = add_track_chain(
            graph, "Y", cell.loc.x, cell.loc.y + 1, quadrant.y1, segment_id, switch_id
        )

        # Connect entry nodes
        cand_entry_node = up_entry_node
        add_edge(graph, cand_entry_node.id, dn_entry_node.id, switch_id)

        # Join node maps
        node_map = {**up_node_map, **dn_node_map}

        # Populate the global clock network to switchbox access map
        for y, node in node_map.items():
            loc = Loc(x=cell.loc.x, y=y)

            if cand_name not in cand_node_map:
                cand_node_map[cand_name] = {}

            cand_node_map[cand_name][loc] = node

    return cand_node_map

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
            print(
                "WARNING: Removing duplicated edge from {} to {}, metadata='{}'"
                .format(edge.src_node, edge.sink_node, metadata)
            )
            continue

        conns.add((edge.src_node, edge.sink_node))

        # Yield the edge
        yield (edge.src_node, edge.sink_node, edge.switch_id, metadata)


# =============================================================================


def main():

    # Parse arguments
    parser = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter
    )

    parser.add_argument(
        "--vpr-db", type=str, required=True, help="VPR database file"
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

        vpr_quadrants = db["vpr_quadrants"]
        vpr_clock_cells = db["vpr_clock_cells"]
        cells_library = db["cells_library"]
        loc_map = db["loc_map"]
        vpr_tile_types = db["vpr_tile_types"]
        vpr_tile_grid = db["vpr_tile_grid"]
        vpr_switchbox_types = db["vpr_switchbox_types"]
        vpr_switchbox_grid = db["vpr_switchbox_grid"]
        connections = db["connections"]
        segments = db["segments"]
        switches = db["switches"]

    # Load the routing graph, build SOURCE -> OPIN and IPIN -> SINK edges.
    print("Loading rr graph...")
    xml_graph = rr_xml.Graph(
        input_file_name=args.rr_graph_in,
        output_file_name=args.rr_graph_out,
        progressbar=progressbar_utils.progressbar
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
                        p_cost=0.0
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
    tile_pin_to_node = build_tile_pin_to_node_map(
        xml_graph.graph, vpr_tile_types, vpr_tile_grid
    )

    # Add const network
    const_node_map = {}
    for const in ["VCC", "GND"]:
        m = add_tracks_for_const_network(xml_graph.graph, const, vpr_tile_grid)
        const_node_map[const] = m

    # Connection loc (endpoint) to node map. Map ConnectionLoc objects to VPR
    # rr graph node ids.
    connection_loc_to_node = {}

    # Build a map of connections to/from tiles and rr nodes. The map points
    # to an IPIN/OPIN node for a connection loc that mentions it.
    node_map = build_tile_connection_map(
        xml_graph.graph, nodes_by_id, vpr_tile_grid, connections
    )
    connection_loc_to_node.update(node_map)

    # Build the global clock network
    print("Building the global clock network...")

    # GMUX to QMUX and QMUX to CAND tracks
    node_map = create_quadrant_clock_tracks(
        xml_graph.graph, connections, connection_loc_to_node
    )
    connection_loc_to_node.update(node_map)

    # Clock column tracks
    cand_node_map = create_column_clock_tracks(
        xml_graph.graph, vpr_clock_cells, vpr_quadrants
    )

    # Add QMUX and CAND models
    for cell in progressbar_utils.progressbar(vpr_clock_cells.values()):
        phy_loc = loc_map.bwd[cell.loc]

        if cell.type == "QMUX":
            model = QmuxModel(
                graph=xml_graph.graph,
                cell=cell,
                phy_loc=phy_loc,
                connections=connections,
                node_map=connection_loc_to_node
            )

        if cell.type == "CAND":
            model = CandModel(
                graph=xml_graph.graph,
                cell=cell,
                phy_loc=phy_loc,
                connections=connections,
                node_map=connection_loc_to_node,
                cand_node_map=cand_node_map
            )

    # Add switchbox models.
    print("Building switchbox models...")
    switchbox_models = {}
    for loc, type in progressbar_utils.progressbar(vpr_switchbox_grid.items()):
        phy_loc = loc_map.bwd[loc]

        switchbox_models[loc] = SwitchboxModel(
            graph=xml_graph.graph,
            loc=loc,
            phy_loc=phy_loc,
            switchbox=vpr_switchbox_types[type],
        )

    # Populate connections to the switchbox models
    print("Populating connections...")
    populate_hop_connections(xml_graph.graph, switchbox_models, connections)
    populate_tile_connections(
        xml_graph.graph, switchbox_models, connections, connection_loc_to_node
    )
    populate_direct_connections(
        xml_graph.graph, connections, connection_loc_to_node
    )
    populate_cand_connections(
        xml_graph.graph, switchbox_models, cand_node_map
    )
    populate_const_connections(
        xml_graph.graph, switchbox_models, const_node_map
    )

    # Create channels from tracks
    pad_segment_id = xml_graph.graph.get_segment_id_from_name("pad")
    channels_obj = xml_graph.graph.create_channels(pad_segment=pad_segment_id)

    # Remove padding channels
    print("Removing padding nodes...")
    xml_graph.graph.nodes = [
        n for n in xml_graph.graph.nodes if n.capacity > 0
    ]

    # Build node id to node map again since there have been new nodes added.
    nodes_by_id = {node.id: node for node in xml_graph.graph.nodes}

    # Sanity check edges
    print("Sanity checking edges...")
    node_ids = set([n.id for n in xml_graph.graph.nodes])
    for edge in xml_graph.graph.edges:
        assert edge.src_node in node_ids, edge
        assert edge.sink_node in node_ids, edge
        assert edge.src_node != edge.sink_node, edge

    # Sanity check IPIN/OPIN connections. There must be no tile completely
    # disconnected from the routing network
    print("Sanity checking tile connections...")

    connected_locs = set()
    for edge in xml_graph.graph.edges:
        src = nodes_by_id[edge.src_node]
        dst = nodes_by_id[edge.sink_node]

        if src.type == rr.NodeType.OPIN:
            loc = (src.loc.x_low, src.loc.y_low)
            connected_locs.add(loc)

        if dst.type == rr.NodeType.IPIN:
            loc = (src.loc.x_low, src.loc.y_low)
            connected_locs.add(loc)

    non_empty_locs = set((loc.x, loc.y) for loc in xml_graph.graph.grid \
                         if loc.block_type_id > 0)

    unconnected_locs = non_empty_locs - connected_locs
    for loc in unconnected_locs:
        block_type = xml_graph.graph.block_type_at_loc(loc)
        print(
            " ERROR: Tile '{}' at ({}, {}) is not connected!".format(
                block_type, loc[0], loc[1]
            )
        )

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
