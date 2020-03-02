#!/usr/bin/env python3
import argparse
import pickle

import lxml.etree as ET

from lib.rr_graph import tracks
import lib.rr_graph.graph2 as rr
import lib.rr_graph_xml.graph2 as rr_xml
from lib import progressbar_utils

from data_structs import *
from minigraph import MiniGraph

# =============================================================================

# Set to True to dump minigraph for each switchbox
DUMP_MINIGRAPHS = False

# =============================================================================


class SwitchboxModel(object):

    def __init__(self, graph, loc, phy_loc, switchbox):
        self.graph = graph
        self.loc = loc
        self.phy_loc = phy_loc
        self.switchbox = switchbox

        # A map of top-level switchbox pins to minigraph node ids. Indexed by
        # (pin.name, pin.direction)
        self.switchbox_pin_to_mininode = {}

        # A map of minigraph node ids to channel directions.
        self.mininode_to_direction = {}

        # Initialize the minigraph
        self.minigraph = MiniGraph()
        self._build_minigraph()


    def _yield_muxes(self):
        """
        Yields all muxes of the switchbox as tuples (stage, switch, mux)
        """
        for stage in self.switchbox.stages.values():
            for switch in stage.switches.values():
                for mux in switch.muxes.values():
                    yield stage, switch, mux


    def _build_minigraph(self):
        """
        Builds a minigraph for the switchbox model. The minigraph will contain
        additional nodes and edges that would simplify connecting to/from the
        switchbox.
        """

        # Add nodes for top-level pins
        for pin in self.switchbox.pins:

            # Add the node
            mininode_id = self.minigraph.add_node(is_locked = False)

            # Add to the top-level map
            key = (pin.name, pin.direction,)
            self.switchbox_pin_to_mininode[key] = mininode_id

        # Add nodes for switch pins
        pin_to_mininode = {}
        for stage, switch, mux in self._yield_muxes():
            for pin in mux.pins:

                # Lock minigraph nodes that are inter-stage. Those will
                # become VPR rr nodes.
                is_locked = pin.direction == PinDirection.OUTPUT and pin.name is None

                # Add the node
                mininode_id = self.minigraph.add_node(is_locked = is_locked)

                # For locked nodes assign VPR channel direction
                if is_locked:
                    chan_type = "X" if stage.id % 2 else "Y"
                    self.mininode_to_direction[mininode_id] = chan_type

                # Add the pin location to the map
                loc = SwitchboxPinLoc(
                    stage_id  = stage.id,
                    switch_id = switch.id,
                    mux_id    = mux.id,
                    pin_id    = pin.id,
                    pin_direction = pin.direction
                )

                pin_to_mininode[loc] = mininode_id

        # Add connections between top-level switchbox pins and switches
        for pin in self.switchbox.inputs.values():
            key = (pin.name, pin.direction)
            src_mininode = self.switchbox_pin_to_mininode[key]

            for loc in pin.locs:
                dst_mininode = pin_to_mininode[loc]
                self.minigraph.add_edge(src_mininode, dst_mininode)

        for pin in self.switchbox.outputs.values():
            key = (pin.name, pin.direction)
            dst_mininode = self.switchbox_pin_to_mininode[key]

            assert len(pin.locs) == 1, pin

            src_mininode = pin_to_mininode[pin.locs[0]]
            self.minigraph.add_edge(src_mininode, dst_mininode)

        # Add connections between switches
        for connection in self.switchbox.connections:
            src_mininode_id = pin_to_mininode[connection.src]
            dst_mininode_id = pin_to_mininode[connection.dst]

            self.minigraph.add_edge(src_mininode_id, dst_mininode_id)

        # Add muxes inside switches
        for stage, switch, mux in self._yield_muxes():
            dst_pin = mux.output
            dst_loc = SwitchboxPinLoc(
                stage_id  = stage.id,
                switch_id = switch.id,
                mux_id    = mux.id,
                pin_id    = dst_pin.id,
                pin_direction = dst_pin.direction
            )

            for src_pin in mux.inputs.values():
                src_loc = SwitchboxPinLoc(
                    stage_id  = stage.id,
                    switch_id = switch.id,
                    mux_id    = mux.id,
                    pin_id    = src_pin.id,
                    pin_direction = src_pin.direction
                )

                src_mininode_id = pin_to_mininode[src_loc]
                dst_mininode_id = pin_to_mininode[dst_loc]

                metadata = self._get_metadata_for_mux(
                    stage,
                    switch,
                    mux,
                    src_pin.id
                )

                self.minigraph.add_edge(
                    src_mininode_id,
                    dst_mininode_id,
                    metadata = metadata
                )


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


    def populate_minigraph_nodes(self):
        """
        Optimize the minigraph (remove dummy nodes), add its nodes to the VPR
        rr graph.
        """

        # Dump
        if DUMP_MINIGRAPHS:
            fname = "minigraph_{}_X{}Y{}_pre_opt.dot".format(
                self.switchbox.type,
                self.loc.x,
                self.loc.y,
            )
            with open(fname, "w") as fp:
                fp.write(self.minigraph.dump_dot())

        # Optimize the minigraph. This removes dummy nodes and merges edges
        # coming to and from them.
        self.minigraph.optimize()
        self.minigraph.prune_leafs()

        # Dump
        if DUMP_MINIGRAPHS:
            fname = "minigraph_{}_X{}Y{}_post_opt.dot".format(
                self.switchbox.type,
                self.loc.x,
                self.loc.y,
            )
            with open(fname, "w") as fp:
                fp.write(self.minigraph.dump_dot())

        # Add nodes
        for mininode in self.minigraph.nodes.values():
         
            # This node correspond to an existing VPR rr graph node. Skip
            # adding it
            metadata = mininode.metadata
            if metadata is not None:
                continue

            if mininode.id in self.mininode_to_direction:
                direction  = self.mininode_to_direction[mininode.id]
                segment_id = self.graph.get_segment_id_from_name("sb_node")
            else:
                direction  = "X"
                segment_id = self.graph.get_segment_id_from_name("generic")

            # Add the track to the graph
            track = tracks.Track(
                direction = direction,
                x_low  = self.loc.x,
                x_high = self.loc.x,
                y_low  = self.loc.y,
                y_high = self.loc.y,
            )

            node_id = self.graph.add_track(track, segment_id)
            node = self.graph.nodes[-1]
            assert node.id == node_id

            # Set the VPR node id as the metadata of the minigraph node
            self.minigraph.update_node(mininode.id, metadata=node_id)


    def populate_minigraph_edges(self):
        """
        Add the minigraph edges to the VPR rr graph.
        """

        for miniedge in self.minigraph.edges.values():

            # Get source and destination minigraph nodes
            src_minigraph_node = self.minigraph.nodes[miniedge.src_node]
            dst_minigraph_node = self.minigraph.nodes[miniedge.dst_node]

            # Both must have VPR nodes associated.
            if src_minigraph_node.metadata is None or \
               dst_minigraph_node.metadata is None:
                continue

            # Get metadata
            metadata = miniedge.metadata
            if len(metadata):
                meta_name  = "fasm_features"
                meta_value = "\n".join(metadata)
            else:
                meta_name  = None
                meta_value = ""

            # Add the edge
            src_node_id = src_minigraph_node.metadata
            dst_node_id = dst_minigraph_node.metadata

            # Add the edge to the graph
            self.graph.add_edge(
                src_node_id,
                dst_node_id,
                0, # TODO: switch id
                name=meta_name,
                value=meta_value                
                )

# =============================================================================


def tile_pin_to_rr_pin(tile_type, pin_name):
    """
    Converts the tile pin name as in the database to its counterpart in the
    rr graph.
    """

    # FIXME: I guess the last '[0]' will differ for tiles with capacity > 1
    return "TL-{}.{}[0]".format(tile_type, pin_name)


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
                print("ERROR: No node for pin '{}' at ({},{})".format(rr_pin_name, loc.x, loc.y))
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
        rr_pin_name = tile_pin_to_rr_pin(tile.type, conn_loc.pin)

        # Get the VPR rr node for the pin
        try:
            nodes = graph.get_nodes_for_pin((conn_loc.loc.x, conn_loc.loc.y,), rr_pin_name)
            assert len(nodes) == 1, (rr_pin_name, conn_loc.loc.x, conn_loc.loc.y)
        except KeyError as ex:
            print("ERROR: No node for pin '{}' at ({},{})".format(rr_pin_name, conn_loc.loc.x, conn_loc.loc.y))
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

        node_id = graph.add_track(track, segment_id)
        curr_node = graph.nodes[-1]
        assert curr_node.id == node_id

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

    # For each column add one that spand over the entire grid height
    const_node_map = {}
    for x in range(xmin + 1, xmax):

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


# =============================================================================

def add_tracks_for_hop_wires(graph, connections):
    """
    Adds a track for each HOP connection wire. Returns a map of connections to
    graph nodes.
    """

    node_map = {}
        
    # Add tracks for HOP wires between switchboxes
    hops = [c for c in connections if c.src.type == ConnectionType.SWITCHBOX \
                                  and c.dst.type == ConnectionType.SWITCHBOX]

    bar = progressbar_utils.progressbar
    for connection in bar(hops):

        # Determine whether the wire goes horizontally or vertically.
        if connection.src.loc.y == connection.dst.loc.y:
            direction = "X"
        elif connection.src.loc.x == connection.dst.loc.x:
            direction = "Y"
        else:
            assert False, connection

        # Determine the connection length
        length = max(
            abs(connection.src.loc.x - connection.dst.loc.x),
            abs(connection.src.loc.y - connection.dst.loc.y)
        )

        segment_name = "hop{}".format(length)

        # Add the track to the graph
        track = tracks.Track(
            direction = direction,
            x_low  = connection.src.loc.x,
            x_high = connection.dst.loc.x,
            y_low  = connection.src.loc.y,
            y_high = connection.dst.loc.y,
        )

        node_id = graph.add_track(track, graph.get_segment_id_from_name(segment_name))
        node = graph.nodes[-1]
        assert node.id == node_id

        # Add to the node map
        node_map[connection] = node

    return node_map

# =============================================================================

def assign_vpr_node(minigraph, mininode, vpr_node_id):
    """
    Assigns a minigraph node with a VPR node id. Checks whether the node
    wa not previously assigned.
    """
    assert minigraph.nodes[mininode].metadata is None
    minigraph.update_node(mininode, is_locked=True, metadata=vpr_node_id)


def populate_connections(connections, tile_grid, switchbox_models, connection_to_node):
    """
    Populates connections to minigraphs of switchbox models.
    """

    # Process connections
    bar = progressbar_utils.progressbar
    for connection in bar(connections):
    
        # Connection between switchboxes through HOP wires. A connection
        # represents the HOP wire node.
        if connection.src.type == ConnectionType.SWITCHBOX and \
           connection.dst.type == ConnectionType.SWITCHBOX:

            # Get the HOP wire node
            node = connection_to_node[connection]

            # Get the output switchbox and its minigraph
            if connection.src.loc in switchbox_models:
                switchbox_model = switchbox_models[connection.src.loc]
                minigraph = switchbox_model.minigraph

                # Get the output node of the minigraph
                key = (connection.src.pin, PinDirection.OUTPUT)
                mininode = switchbox_model.switchbox_pin_to_mininode[key]

                # Assign it the VPR node id
                assign_vpr_node(minigraph, mininode, node.id)
                    
            # Get the input switchbox and its minigraph
            if connection.dst.loc in switchbox_models:
                switchbox_model = switchbox_models[connection.dst.loc]
                minigraph = switchbox_model.minigraph

                # Get the input node of the minigraph
                key = (connection.dst.pin, PinDirection.INPUT)
                mininode = switchbox_model.switchbox_pin_to_mininode[key]

                # Assign it the VPR node id
                assign_vpr_node(minigraph, mininode, node.id)
        
        # Connection between switchbox and its tile. The connection represents
        # edge between IPIN/OPIN and CHANX/CHANY.
        else:

            # Must be the same switchbox and tile
            assert connection.src.loc == connection.dst.loc, connection            
            loc = connection.src.loc

            # No switchbox model at the loc, skip.
            if loc not in switchbox_models:
                continue

            # Get the switchbox model (both locs are the same)
            switchbox_model = switchbox_models[loc]
            minigraph = switchbox_model.minigraph

            # Get the tile IPIN/OPIN node
            if connection not in connection_to_node:
                print("ERROR: No IPIN/OPIN node for connection {}".format(connection))
                continue

            node = connection_to_node[connection]

            # To tile
            if connection.dst.type == ConnectionType.TILE:

                # Get the output node of the minigraph
                key = (connection.src.pin, PinDirection.OUTPUT)
                mininode = switchbox_model.switchbox_pin_to_mininode[key]

                # Assign it the VPR node id
                assign_vpr_node(minigraph, mininode, node.id)
        
            # From tile
            if connection.src.type == ConnectionType.TILE:

                # Get the input node of the minigraph
                key = (connection.dst.pin, PinDirection.INPUT)
                mininode = switchbox_model.switchbox_pin_to_mininode[key]

                # Assign it the VPR node id
                assign_vpr_node(minigraph, mininode, node.id)


def populate_const_connections(switchbox_models, const_node_map):
    """
    Connects switchbox inputs that represent VCC and GND constants to
    nodes of the global const network.
    """

    for loc, switchbox_model in switchbox_models.items():

        # Look for input connected to a const
        for pin in switchbox_model.switchbox.pins:

            if pin.direction is not PinDirection.INPUT:
                continue

            # Got a const input
            if pin.name in const_node_map:

                # Get the node
                node = const_node_map[pin.name][loc]

                # Get the input node of the minigraph
                key = (pin.name, PinDirection.INPUT)
                mininode = switchbox_model.switchbox_pin_to_mininode[key]
                minigraph = switchbox_model.minigraph

                # Assign it the VPR node id
                assign_vpr_node(minigraph, mininode, node.id)

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

    # Load the routing graph, build SOURCE -> OPIN and IPIN -> SINK edges.
    print("Loading rr graph...")
    xml_graph = rr_xml.Graph(
        input_file_name  = args.rr_graph_in,
        output_file_name = args.rr_graph_out,
        progressbar      = None
    )

    print("Building maps...")

    # Build node id to node map
    nodes_by_id = {node.id: node for node in xml_graph.graph.nodes}

    # Build tile pin names to rr node ids map
    tile_pin_to_node = build_tile_pin_to_node_map(xml_graph.graph, vpr_tile_types, vpr_tile_grid)

    # Connection to node map. Map Connection objects to rr graph node ids
    connection_to_node = {}

    # Add const network
    const_node_map = {}
    for const in ["VCC", "GND"]:
        m = add_tracks_for_const_network(xml_graph.graph, const, vpr_tile_grid)
        const_node_map[const] = m

    # Add tracks for HOP wires. Build map of these to rr nodes.
    node_map = add_tracks_for_hop_wires(xml_graph.graph, connections)
    connection_to_node.update(node_map)

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

        if loc.x <= 4 and loc.y <= 4:
            print(type, loc, phy_loc)

        switchbox_models[loc] = SwitchboxModel(
            graph = xml_graph.graph,
            loc = loc,
            phy_loc = phy_loc,
            switchbox = vpr_switchbox_types[type],
        )    

    # Populate connections to the switchbox models
    print("Populating connections...")
    populate_connections(connections, vpr_tile_grid, switchbox_models, connection_to_node)
    populate_const_connections(switchbox_models, const_node_map)

    # Implement switchboxes in the VPR graph
    print("Building final rr graph...")
    bar = progressbar_utils.progressbar

    for loc, switchbox_model in bar(switchbox_models.items()):
        switchbox_model.populate_minigraph_nodes()

    for loc, switchbox_model in bar(switchbox_models.items()):
        switchbox_model.populate_minigraph_edges()

    # Create channels from tracks
    pad_segment_id = xml_graph.graph.get_segment_id_from_name("generic")
    channels_obj = xml_graph.graph.create_channels(pad_segment=pad_segment_id)

    # Remove padding channels
    print("Removing padding nodes...")
    padding_nodes = []
    for node in xml_graph.graph.nodes:
        if node.capacity == 0:
            padding_nodes.append(node)

    for node in padding_nodes:
        xml_graph.graph.nodes.remove(node)

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
