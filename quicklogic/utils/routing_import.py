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

    def __init__(self, graph, loc, switchbox):
        self.graph = graph
        self.loc = loc
        self.switchbox = switchbox

        # A map of top-level switchbox pins to minigraph node ids. Indexed by
        # (pin.name, pin.direction)
        self.switchbox_pin_to_mininode = {}

        # A map of minigraph node ids to channel directions.
        self.mininode_to_direction = {}

        # Initialize the minigraph
        self.minigraph = MiniGraph()
        self._build_minigraph()

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
        for stage in self.switchbox.stages.values():
            for switch in stage.switches.values():
                for pin in switch.pins:

                    # Lock minigraph nodes that are inter-stage. Those will
                    # become VPR rr nodes.
                    is_locked = pin.direction == PinDirection.OUTPUT and pin.name is None

                    # Add the node
                    mininode_id = self.minigraph.add_node(is_locked = is_locked)

                    # Add the pinspec to the map
                    pinspec = (stage.id, switch.id, pin.id, pin.direction) 
                    pin_to_mininode[pinspec] = mininode_id

                    # Add to mininode direction map
                    direction = "X" if stage.id % 2 else "Y"
                    self.mininode_to_direction[mininode_id] = direction

        # Add connections between top-level switchbox pins and switches
        for stage in self.switchbox.stages.values():
            for switch in stage.switches.values():
                for pin in switch.pins:

                    # Only top-level
                    if pin.name is None:
                        continue
                    # Skip unconnected pins
                    if pin.name == "-1":
                        continue

                    # Input to switch
                    if pin.direction == PinDirection.INPUT:
                        key = (pin.name, pin.direction)
                        src_mininode = self.switchbox_pin_to_mininode[key]

                        pinspec = (stage.id, switch.id, pin.id, pin.direction) 
                        dst_mininode = pin_to_mininode[pinspec]

                        self.minigraph.add_edge(src_mininode, dst_mininode)

                    # Switch to output
                    elif pin.direction == PinDirection.OUTPUT:
                        key = (pin.name, pin.direction)
                        dst_mininode = self.switchbox_pin_to_mininode[key]

                        pinspec = (stage.id, switch.id, pin.id, pin.direction) 
                        src_mininode = pin_to_mininode[pinspec]

                        self.minigraph.add_edge(src_mininode, dst_mininode)

                    else:
                        assert False, pin

        # Add connections between switches
        for connection in self.switchbox.connections:
            src_pinspec = (connection.src_stage, connection.src_switch, connection.src_pin, PinDirection.OUTPUT)
            dst_pinspec = (connection.dst_stage, connection.dst_switch, connection.dst_pin, PinDirection.INPUT)

            src_mininode_id = pin_to_mininode[src_pinspec]
            dst_mininode_id = pin_to_mininode[dst_pinspec]

            self.minigraph.add_edge(src_mininode_id, dst_mininode_id)

        # Add muxes inside switches
        for stage in self.switchbox.stages.values():
            for switch in stage.switches.values():
                for dst_pin_id, src_pin_ids in switch.mux.items():
                    dst_pinspec = (stage.id, switch.id, dst_pin_id, PinDirection.OUTPUT)
                    for src_pin_id in src_pin_ids:
                        src_pinspec = (stage.id, switch.id, src_pin_id, PinDirection.INPUT)

                        src_mininode_id = pin_to_mininode[src_pinspec]
                        dst_mininode_id = pin_to_mininode[dst_pinspec]

                        self.minigraph.add_edge(src_mininode_id, dst_mininode_id)

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

            # Add the edge
            src_node_id = src_minigraph_node.metadata
            dst_node_id = dst_minigraph_node.metadata

            # Add the edge to the graph
            # TODO: VPR switch id, FASM metadata
            self.graph.add_edge(
                src_node_id,
                dst_node_id,
                0
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
        assert not (connection.src.is_direct and connection.dst.is_direct), connection

        # Connection to a tile
        if connection.dst.is_direct:
            add_to_map(connection, connection.dst)
            continue

        # Connection from a tile
        if connection.src.is_direct:
            add_to_map(connection, connection.src)
            continue

    return node_map

# =============================================================================


def add_tracks_for_hop_wires(graph, connections):
    """
    Adds a track for each HOP connection wire. Returns a map of connections to
    graph nodes.
    """

    node_map = {}
        
    # Add tracks for HOP wires between switchboxes
    hops = [c for c in connections if not c.src.is_direct and not c.dst.is_direct]
    bar = progressbar_utils.progressbar
    for connection in bar(hops):

        # Determine whether the wire goes horizontally or vertically. Make the
        # track shorter by 1 to avoid connections between neighboring channels.
        if connection.src.loc.y == connection.dst.loc.y:
            direction = "X"
            if connection.dst.loc.x > connection.src.loc.x:
                dst = Loc(x=connection.dst.loc.x - 1, y=connection.dst.loc.y)
            else:
                dst = Loc(x=connection.dst.loc.x + 1, y=connection.dst.loc.y)

        elif connection.src.loc.x == connection.dst.loc.x:
            direction = "Y"
            if connection.dst.loc.y > connection.src.loc.y:
                dst = Loc(x=connection.dst.loc.x, y=connection.dst.loc.y - 1)
            else:
                dst = Loc(x=connection.dst.loc.x, y=connection.dst.loc.y + 1)

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
            x_high = dst.x,
            y_low  = connection.src.loc.y,
            y_high = dst.y,
        )

        node_id = graph.add_track(track, graph.get_segment_id_from_name(segment_name))
        node = graph.nodes[-1]
        assert node.id == node_id

        # Add to the node map
        node_map[connection] = node

    return node_map


def populate_connections(graph, connections, tile_grid, switchbox_models, connection_to_node):
    """
    Populates connections to minigraphs of switchbox models.
    """

    def assign_vpr_node(minigraph, mininode, vpr_node_id):
        """
        Assigns a minigraph node with a VPR node id. Checks whether the node
        wa not previously assigned.
        """
        assert minigraph.nodes[mininode].metadata is None
        minigraph.update_node(mininode, is_locked=True, metadata=vpr_node_id)

    # Process connections
    bar = progressbar_utils.progressbar
    for connection in bar(connections):
    
        # Connection between switchboxes through HOP wires. A connection
        # represents the HOP wire node.
        if not connection.src.is_direct and not connection.dst.is_direct:

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
            if connection.dst.is_direct:

                # Get the output node of the minigraph
                key = (connection.src.pin, PinDirection.OUTPUT)
                mininode = switchbox_model.switchbox_pin_to_mininode[key]

                # Assign it the VPR node id
                assign_vpr_node(minigraph, mininode, node.id)
        
            # From tile
            if connection.src.is_direct:

                # Get the input node of the minigraph
                key = (connection.dst.pin, PinDirection.INPUT)
                mininode = switchbox_model.switchbox_pin_to_mininode[key]

                # Assign it the VPR node id
                assign_vpr_node(minigraph, mininode, node.id)

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

        switchbox_models[loc] = SwitchboxModel(
            graph = xml_graph.graph,
            loc = loc,
            switchbox = vpr_switchbox_types[type],
        )    

    # Populate connections to the switchbox models
    print("Populating connections...")
    populate_connections(xml_graph.graph, connections, vpr_tile_grid, switchbox_models, connection_to_node)

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
        edges_obj=edges_obj,
        node_remap=node_remap,
    )

# =============================================================================

if __name__ == "__main__":
    main()
