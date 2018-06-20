#!/usr/bin/env python3
#
#  Copyright (C) 2015  Clifford Wolf <clifford@clifford.at>
#
#  Permission to use, copy, modify, and/or distribute this software for any
#  purpose with or without fee is hereby granted, provided that the above
#  copyright notice and this permission notice appear in all copies.
#
#  THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
#  WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
#  MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
#  ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
#  WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
#  ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
#  OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
#
"""
The way this works is as follows;

Loop over all possible "wires" and work out;

 * If the wire is an actual wire or a pin
 * A unique, descriptive name

For each wire, we then work out which channel the wire should be assigned too.
    We build up the channels as follows;

     X Channel
        Span 4 Tracks
        Empty
        Span 12 Tracks
        Empty
        Global Tracks

     Y Channel
        Empty
        Local Tracks
        Empty
        Neighbour Tracks
        Empty
        Span 4 Tracks
        Empty
        Span 12 Tracks
        Empty
        Global Tracks

We use the Y channels for the Local + Neighbour track because we have cells
which are multiple tiles wide in the Y direction.

For each wire, we work out the "edges" (IE connection to other wires / pins).

Naming (ie track names)
http://www.clifford.at/icestorm/logic_tile.html
"Note: the Lattice tools use a different normalization scheme for this wire names."
This doc: https://docs.google.com/document/d/1kTehDgse8GA2af5HoQ9Ntr41uNL_NJ43CjA32DofK8E/edit#
I think is based on CW's naming but has some divergences

Some terminology clarification:
-A VPR "track" is a specific net that can be connected to in the global fabric
-Icestorm docs primarily talk about "wires" which generally refer to a concept how how these nets are used per tile
That is, we take the Icestorm tile wire pattern and convert it to VPR tracks

Other resources:
http://hedmen.org/icestorm-doc/icestorm.html


mithro MVP proposal: spans and locals only
Then add globals, then neighbourhood
"""

# Python libs
import operator
import os.path
import re
import sys
from collections import namedtuple, OrderedDict
from functools import reduce
from os.path import commonprefix

MYDIR = os.path.dirname(__file__)

# Third party libs
import lxml.etree as ET

sys.path.insert(0, os.path.join(MYDIR, "..", "..", "third_party", "icestorm", "icebox"))
import icebox
import icebox_asc2hlc

# Local libs
sys.path.insert(0, os.path.join(MYDIR, "..", "..", "utils"))
import lib.rr_graph.graph as graph
import lib.rr_graph.channel as channel
from lib.rr_graph import Offset
from lib.asserts import assert_type

ic = None
VERBOSE = True
device_name = None


class PositionIcebox(graph.Position):
    def __str__(self):
        return graph.Position.__str__(self).replace("PositionIcebox", "PI")
    def __repr__(self):
        return graph.Position.__repr__(self).replace("PositionIcebox", "PI")


class PositionVPR(graph.Position):
    def __str__(self):
        return graph.Position.__str__(self).replace("PositionVPR", "PV")
    def __repr__(self):
        return graph.Position.__repr__(self).replace("PositionVPR", "PV")


def pos_icebox2vpr(pos):
    '''Convert icebox to VTR coordinate system by adding 1 for dummy blocks'''
    assert_type(pos, PositionIcebox)
    return PositionVPR(pos.x + 2, pos.y + 2)


def pos_vpr2icebox(pos):
    '''Convert VTR to icebox coordinate system by subtracting 1 for dummy blocks'''
    assert_type(pos, PositionVPR)
    return PositionIcebox(pos.x - 2, pos.y - 2)


def pos_icebox2vprpin(pos):
    if pos.x == 0:
        return PositionVPR(1, pos.y+2)
    elif pos.y == 0:
        return PositionVPR(pos.x+2, 1)
    elif pos.x == ic.max_x:
        return PositionVPR(pos.x+2+1, pos.y+2)
    elif pos.y == ic.max_y:
        return PositionVPR(pos.x+2, pos.y+2+1)
    assert False, (pos, (ic.max_x, ic.max_y))


def format_node(g, node):
    if node is None:
        return "None"
    assert isinstance(node, ET._Element), node
    if node.tag == "node":
        return graph.RoutingGraphPrinter.node(node, g.block_grid)
    elif node.tag == "edge":
        return str(node)
        #return graph.RoutingGraphPrinter.edge(g.routing, node, g.block_grid)


def tiles(ic):
    for x in range(ic.max_x + 1):
        for y in range(ic.max_y + 1):
            yield PositionIcebox(x, y)


def find_path(group):
    assert_type(group, list)
    start = group[0][0]
    end = group[0][0]
    for ipos, netname in group:
        assert_type(ipos, PositionIcebox)
        if ipos < start:
            start = ipos
        if ipos > end:
            end = ipos
    return start, end


def filter_track_names(group):
    assert_type(group, list)
    names = []
    for ipos, netname in group:
        assert_type(ipos, PositionIcebox)
        if "neigh_op" in netname:
            continue
        if "logic_op" in netname:
            continue
        if "glb_netwk" in netname:
            continue
        names.append((ipos, netname))
    return names


def filter_non_straight(group):
    assert_type(group, list)
    x_count = {}
    y_count = {}
    for ipos, netname in group:
        assert_type(ipos, PositionIcebox)
        if ipos.x not in x_count:
            x_count[ipos.x] = 0
        x_count[ipos.x] += 1
        if ipos.y not in y_count:
            y_count[ipos.y] = 0
        y_count[ipos.y] += 1
    x_val = list(sorted((c, x) for x, c in x_count.items()))
    y_val = list(sorted((c, y) for y, c in y_count.items()))

    r = []
    if x_val[-1][0] > y_val[-1][0]:
        x_ipos = x_val[-1][1]
        for ipos, netname in group:
            if ipos.x != x_ipos:
                print("Skipping non-straight", "x", x_ipos, ipos, netname)
                continue
            r.append((ipos, netname))
    else:
        y_ipos = y_val[-1][1]
        for ipos, netname in group:
            if ipos.y != y_ipos:
                print("Skipping non-straight", "y", y_ipos, ipos, netname)
                continue
            r.append((ipos, netname))
    return r


def group_hlc_name(group):
    assert_type(group, list)
    global ic
    hlcnames = set()
    for ipos, localname in group:
        assert_type(ipos, PositionIcebox)
        hlcname = icebox_asc2hlc.translate_netname(*ipos, ic.max_x-1, ic.max_y-1, localname)
        hlcnames.add(hlcname)
    assert len(hlcnames) == 1, hlcnames
    return hlcnames.pop()


def group_seg_type(group):
    assert_type(group, list)
    for ipos, netname in group:
        assert_type(ipos, PositionIcebox)
        if "local" in netname:
            return "local"
        if "global" in netname:
            return "global"
        if "sp4" in netname or "span4" in netname:
            return "span4"
        if "sp12" in netname or "span12" in netname:
            return "span12"
    return "unknown"


def group_chan_type(group):
    assert_type(group, list)
    for ipos, netname in group:
        assert_type(ipos, PositionIcebox)
        if "local" in netname:
            return channel.Track.Type.Y
        if "_h" in netname:
            return channel.Track.Type.X
        if "_v" in netname:
            return channel.Track.Type.Y
    return None


def init(device_name, read_rr_graph):
    global ic
    ic = icebox.iceconfig()
    {
        #'t4':  ic.setup_empty_t4,
        '8k': ic.setup_empty_8k,
        '5k': ic.setup_empty_5k,
        '1k': ic.setup_empty_1k,
        '384': ic.setup_empty_384,
    }[device_name]()
    fn_dir = {
        't4': 'test4',
        '8k': 'HX8K',
        '5k': 'HX5K',
        '1k': 'HX1K',
        '384': 'LP384',
    }[device_name]

    print('Loading rr_graph')
    g = graph.Graph(read_rr_graph, clear_fabric=True)
    g.set_tooling(
        name="icebox",
        version="dev",
        comment="Generated for iCE40 {} device".format(device_name))

    return ic, g


def add_pin_aliases(g, ic, verbose=True):
    '''Build a list of icebox global pin names to Graph node IDs'''
    name_rr2local = {}

    # FIXME: quick attempt, not thoroughly checked
    # BLK_TL-PLB
    # http://www.clifford.at/icestorm/logic_tile.html
    # http://www.clifford.at/icestorm/bitdocs-1k/tile_1_1.html
    name_rr2local['BLK_TL-PLB.lutff_global/s_r[0]'] = 'lutff_global/s_r'
    name_rr2local['BLK_TL-PLB.lutff_global/clk[0]'] = 'lutff_global/clk'
    name_rr2local['BLK_TL-PLB.lutff_global/cen[0]'] = 'lutff_global/cen'
    # FIXME: these two are wrong I think, but don't worry about carry for now
    #name_rr2local['BLK_TL-PLB.FCIN[0]'] = 'lutff_0/cin'
    #name_rr2local['BLK_TL-PLB.FCOUT[0]'] = 'lutff_7/cout'
    #name_rr2local['BLK_TL-PLB.lutff_0_cin[0]'] = 'lutff_0/cin'
    #name_rr2local['BLK_TL-PLB.lutff_7_cout[0]'] = 'lutff_7/cout'
    for luti in range(8):
        name_rr2local['BLK_TL-PLB.lutff_{}/out[0]'.format(
            luti)] = 'lutff_{}/out'.format(luti)
        for lut_input in range(4):
            name_rr2local['BLK_TL-PLB.lutff_{}/in[{}]'.format(
                luti, lut_input)] = 'lutff_{}/in_{}'.format(
                    luti, lut_input)

    # BLK_TL-PIO
    # http://www.clifford.at/icestorm/io_tile.html
    # FIXME: filter out orientations that don't exist?
    #name_rr2local['BLK_TL-PIO_{}.io_global_latch[0]'.format(
    #    orientation)] = 'io_global/latch'
    #name_rr2local['BLK_TL-PIO_{}.io_global_outclk[0]'.format(
    #    orientation)] = 'io_global/outclk'
    #name_rr2local['BLK_TL-PIO_{}.io_global_cen[0]'.format(
    #    orientation)] = 'io_global/cen'
    #name_rr2local['BLK_TL-PIO_{}.io_global_inclk[0]'.format(
    #    orientation)] = 'io_global/inclk'
    for blocki in range(2):
        name_rr2local['BLK_TL-PIO.[{}]D_IN_0[0]'.format(
            blocki)] = 'io_{}/D_IN_0'.format(blocki)
        name_rr2local['BLK_TL-PIO.[{}]D_IN_1[0]'.format(
            blocki)] = 'io_{}/D_IN_1'.format(blocki)
        name_rr2local['BLK_TL-PIO.[{}]D_OUT_0[0]'.format(
            blocki)] = 'io_{}/D_OUT_0'.format(blocki)
        name_rr2local['BLK_TL-PIO.[{}]D_OUT_1[0]'.format(
            blocki)] = 'io_{}/D_OUT_1'.format(blocki)
        name_rr2local['BLK_TL-PIO.[{}]OUT_ENB[0]'.format(
            blocki)] = 'io_{}/OUT_ENB'.format(blocki)

    for block in g.block_grid:
        ipos = pos_vpr2icebox(PositionVPR(*block.position))
        for pin in block.pins:
            hlc_name = group_hlc_name([(ipos, pin.name)])

            node = g.routing.localnames[(block.position, pin.name)]
            node.set_metadata("hlc_pos", "{} {}".format(*ipos))
            node.set_metadata("hlc_name", hlc_name)

            rr_name = pin.xmlname
            try:
                localname = name_rr2local[rr_name]
            except KeyError:
                print("WARNING: rr_name {} doesn't have a translation".format(rr_name))
                continue

            print("Adding alias {}:{} for {}".format(
                block.position, localname, format_node(g, node)))
            g.routing.localnames.add(block.position, localname, node)
            g.routing.localnames.add(block.position, hlc_name, node)


def add_tracks(g, ic, verbose=True):
    dummy = g.segments["dummy"]
    for x in range(-2, ic.max_x+2):
        istart = PositionIcebox(x, 0)
        iend = PositionIcebox(x, ic.max_y)
        track, track_node = g.create_xy_track(
            pos_icebox2vpr(istart), pos_icebox2vpr(iend),
            segment=dummy,
            direction=channel.Track.Direction.BI)
    for y in range(-2, ic.max_y+2):
        istart = PositionIcebox(0, y)
        iend = PositionIcebox(ic.max_x, y)
        track, track_node = g.create_xy_track(
            pos_icebox2vpr(istart), pos_icebox2vpr(iend),
            segment=dummy,
            direction=channel.Track.Direction.BI)

    all_group_segments = ic.group_segments(
        list(tiles(ic)), connect_gb=False)
    for group in sorted(all_group_segments):
        if verbose:
            print()
        group = [(PositionIcebox(x, y), netname) for x, y, netname in group]

        fgroup = filter_track_names(group)
        if not fgroup:
            print("Filtered out track group", group)
            continue

        fgroup = filter_non_straight(fgroup)
        assert fgroup, (fgroup, fgroup)

        segtype = group_seg_type(group)
        if segtype == "unknown":
            print("Skipping unknown track group", group)
            continue
        if segtype == "global":
            print("Skipping global track group", group)
            continue
        segment = g.segments[segtype]

        hlc_name = group_hlc_name(group)

        istart, iend = find_path(fgroup)
        if istart.x == iend.x and istart.y != iend.y:
            typeh = channel.Track.Type.Y
        elif istart.x != iend.x and istart.y == iend.y:
            typeh = channel.Track.Type.X
        elif istart.x != iend.x and istart.y != iend.y:
            print("Skipping non-straight track", group)
            continue
        else:
            typeh = group_chan_type(fgroup)
        vstart, vend = pos_icebox2vpr(istart), pos_icebox2vpr(iend)

        print()
        print("Creating track", hlc_name, vstart, vend, segment, typeh, group)
        track, track_node = g.create_xy_track(
            vstart, vend,
            segment=segment,
            typeh=typeh,
            direction=channel.Track.Direction.BI)

        track_node.set_metadata("hlc_name", hlc_name)

        for pos, netname in fgroup:
            vpos = pos_icebox2vpr(pos)
            g.routing.localnames.add(vpos, hlc_name, track_node)
            g.routing.localnames.add(vpos, netname, track_node)
            print(pos, "->", vpos, format_node(g, track_node), "==", netname)
        print()
        print()


def add_edges(g, ic, verbose=True):
    verbose = True
    all_tiles = list(tiles(ic))
    for ipos in all_tiles:
        tile_type = ic.tile_type(*ipos)
        vpos = pos_icebox2vpr(ipos)

        if verbose:
            print()
            print(ipos)
            print("-" * 75)

        # FIXME: If IO type, connect PACKAGE_PIN_I and PACKAGE_PIN_O manually...
##        if tile_type == "IO":
##            vpr_pio_pos = vpos
##            vpr_pin_pos = pos_icebox2vprpin(ipos)
##            print(tile_type, "pio:", ipos, vpos, "pin:", vpr_pin_pos)
##            if "EMPTY" in g.block_grid[vpr_pin_pos].block_type.name:
##                continue
##
##            print("PIO localnames:", g.routing.localnames[vpr_pio_pos])
##            print("PIN localnames:", g.routing.localnames[vpr_pin_pos])
##            for i in [0, 1]:
##                # pio -> pin
##                pio_iname = "O[{}]".format(i)
##                src_inode = g.routing.localnames[(vpr_pio_pos, pio_iname)]
##                pin_iname = "[{}]O[0]".format(i)
##                dst_inode = g.routing.localnames[(vpr_pin_pos, pin_iname)]
##                edgei = g.routing.create_edge_with_nodes(
##                    src_inode, dst_inode, switch=g.switches["short"])
##                print(vpr_pio_pos, pio_iname, format_node(g, src_inode),
##                      vpr_pin_pos, pin_iname, format_node(g, dst_inode),
##                      edgei)
##
##                # pin -> pio
##                pin_oname = "[{}]I[0]".format(i)
##                src_onode = g.routing.localnames[(vpr_pin_pos, pin_oname)]
##                pio_oname = "I[{}]".format(i)
##                dst_onode = g.routing.localnames[(vpr_pio_pos, pio_oname)]
##                edgeo = g.routing.create_edge_with_nodes(
##                    src_onode, dst_onode, switch=g.switches["short"])
##                print(vpr_pin_pos, pin_oname, format_node(g, src_onode),
##                      vpr_pio_pos, pio_oname, format_node(g, dst_onode),
##                      edgeo)

        for entry in ic.tile_db(*ipos):
            if not ic.tile_has_entry(*ipos, entry):
                verbose and print(
                    '  WARNING: skip %s %s' % (ipos, entry))
                continue

            verbose and print('')
            verbose and print("icebox edge entry", ipos, entry)
            switch_type = entry[1]
            if switch_type not in ("routing", "buffer"):
                verbose and print(
                    '  WARNING: skip switch type %s' % switch_type)
                continue

            src_localname = entry[2]
            dst_localname = entry[3]
            verbose and print(
                '  Got name %s => %s' % (src_localname, dst_localname))

            src_node = g.routing.localnames.get((vpos, src_localname), None)
            dst_node = g.routing.localnames.get((vpos, dst_localname), None)

            dst_hlc_name = group_hlc_name([(ipos, dst_localname)])
            src_hlc_name = group_hlc_name([(ipos, src_localname)])

            # May have duplicate entries
            if src_node is None:
                verbose and print(
                    "  WARNING: skipping edge as src missing *{}:{}* ({}) node {} => {}:{} ({}) node {}".format(
                        vpos,
                        src_localname,
                        src_hlc_name,
                        format_node(g, src_node),
                        vpos,
                        dst_localname,
                        dst_hlc_name,
                        format_node(g, dst_node),
                    ))
                continue
            if dst_node is None:
                verbose and print(
                    "  WARNING: skipping edge as dst missing {}:{} ({}) node {} => *{}:{}* ({}) node {}".format(
                        vpos,
                        src_localname,
                        src_hlc_name,
                        format_node(g, src_node),
                        vpos,
                        dst_localname,
                        dst_hlc_name,
                        format_node(g, dst_node),
                    ))
                continue

            verbose and print(
                "  ADDING: {} edge {} - {}:{} ({}) node {} => {}:{} ({}) node {}".format(
                    switch_type,
                    len(g.routing.id2element[graph.RoutingEdge]),
                    vpos,
                    src_localname,
                    src_hlc_name,
                    format_node(g, src_node),
                    vpos,
                    dst_localname,
                    dst_hlc_name,
                    format_node(g, dst_node),
                ))

            edge = g.routing.create_edge_with_nodes(
                src_node, dst_node, switch=g.switches[switch_type])

            edge.set_metadata("hlc_pos", "{} {}".format(*ipos))


def print_nodes_edges(g):
    print("Edges: %d (index: %d)" %
          (len(g.routing._xml_parent(graph.RoutingEdge)),
           len(g.routing.id2element[graph.RoutingEdge])))
    print("Nodes: %d (index: %d)" %
          (len(g.routing._xml_parent(graph.RoutingNode)),
           len(g.routing.id2element[graph.RoutingNode])))


def get_pin_meta(block, pin):
    grid_sz = PositionVPR(ic.max_x+1+4, ic.max_y+1+4)
    print("get_pin_meta", block, pin, pin.name, end=" ")
    if "PIN" in block.block_type.name:
        print("pin", end=" ")
        if block.position.x == 1:
            print("right")
            return (graph.RoutingNodeSide.RIGHT, Offset(0, 0))
        elif block.position.y == 1:
            print("top")
            return (graph.RoutingNodeSide.TOP, Offset(0, 0))
        elif block.position.y == grid_sz.y-2:
            print("bottom")
            return (graph.RoutingNodeSide.BOTTOM, Offset(0, 0))
        elif block.position.x == grid_sz.x-2:
            print("left")
            return (graph.RoutingNodeSide.LEFT, Offset(0, 0))

    if "RAM" in block.block_type.name:
        print("ram", end=" ")
        top_pins = ["RDATAB", "WADDR", "MASKB", "WDATAB", "WCLKE", "WCLK", "WE"]
        bot_pins = ["RDATAT", "RADDR", "MASKT", "WDATAT", "RCLKE", "RCLK", "RE"]
        if pin.port_name in top_pins:
            print("top")
            return (graph.RoutingNodeSide.RIGHT, Offset(0, 1))
        elif pin.port_name in bot_pins:
            print("bot")
            return (graph.RoutingNodeSide.RIGHT, Offset(0, 0))
        assert False

    if "PIO" in block.block_type.name:
        print("pio", end=" ")
        if pin.name.startswith("O[") or pin.name.startswith("I["):
            if block.position.x == 2:
                print("right")
                return (graph.RoutingNodeSide.LEFT, Offset(0, 0))
            elif block.position.y == 2:
                print("top")
                return (graph.RoutingNodeSide.BOTTOM, Offset(0, 0))
            elif block.position.y == grid_sz.y-3:
                print("bottom")
                return (graph.RoutingNodeSide.TOP, Offset(0, 0))
            elif block.position.x == grid_sz.x-3:
                print("left")
                return (graph.RoutingNodeSide.RIGHT, Offset(0, 0))
        print("other")
        return (graph.RoutingNodeSide.RIGHT, Offset(0, 0))

    if "PLB" in block.block_type.name:
        print("plb", end=" ")
        if "FCIN" in pin.port_name:
            print("bottom")
            return (graph.RoutingNodeSide.BOTTOM, Offset(0, 0))
        elif "FCOUT" in pin.port_name:
            print("top")
            return (graph.RoutingNodeSide.TOP, Offset(0, 0))

        print("other")
        return (graph.RoutingNodeSide.RIGHT, Offset(0, 0))

    assert False, (block, pin)


def run(part, read_rr_graph, write_rr_graph):
    global ic

    print('Importing input g', part)
    ic, g = init(part, read_rr_graph)

    # my_test(ic, g)
    print('Source g loaded')
    print_nodes_edges(g)
    grid_sz = g.block_grid.size
    print("Grid size: %s" % (grid_sz, ))
    print()

    print('Clearing')
    print('='*80)
    print('Clearing nodes and edges')
    g.routing.clear()
    print('Clearing channels')
    g.channels.clear()
    print('Cleared original g')
    print_nodes_edges(g)
    print()
    print()
    print('Rebuilding block I/O nodes')
    print('='*80)

    g.create_block_pins_fabric(
        g.switches['__vpr_delayless_switch__'], get_pin_meta)
    print_nodes_edges(g)

    print()
    print('Adding pin aliases')
    print('='*80)
    add_pin_aliases(g, ic, VERBOSE)
    add_tracks(g, ic, VERBOSE)
    print()
    print('Adding edges')
    print('='*80)
    add_edges(g, ic, VERBOSE)
    print()
    print_nodes_edges(g)
    print()
    print('Padding channels')
    print('='*80)
    dummy_segment = g.segments['dummy']
    g.pad_channels(dummy_segment.id)
    print()
    print('Saving')
    open(write_rr_graph, 'w').write(
        ET.tostring(g.to_xml(), pretty_print=True).decode('ascii'))
    print()
    print('Exiting')
    sys.exit(0)


if __name__ == '__main__':
    import argparse

    parser = argparse.ArgumentParser()
    parser.add_argument(
        '--verbose', '-v', action='store_true', help='verbose output')
    parser.add_argument('--device', help='')
    parser.add_argument('--read_rr_graph', help='')
    parser.add_argument('--write_rr_graph', default='out.xml', help='')

    args = parser.parse_args()

    VERBOSE = args.verbose

    mode = args.device.lower()[2:]
    run(mode, args.read_rr_graph, args.write_rr_graph)
