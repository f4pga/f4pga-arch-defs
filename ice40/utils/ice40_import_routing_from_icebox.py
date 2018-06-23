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
import logging
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


class PositionIcebox(graph.Position):
    def __str__(self):
        return "PI(%2s,%2s)" % self
    def __repr__(self):
        return str(self)


class PositionVPR(graph.Position):
    def __str__(self):
        return "PV(%2s,%2s)" % self
    def __repr__(self):
        return str(self)


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


class RunOnStr:
    """Don't run function until a str() is called."""
    def __init__(self, f, *args, **kw):
        self.f = f
        self.args = args
        self.kw = kw
        self.s = None

    def __str__(self):
        if not self.s:
            self.s = self.f(*self.args, **self.kw)
        return self.s


def format_node(g, node):
    if node is None:
        return "None"
    assert isinstance(node, ET._Element), node
    if node.tag == "node":
        return RunOnStr(graph.RoutingGraphPrinter.node, node, g.block_grid)
    elif node.tag == "edge":
        return RunOnStr(graph.RoutingGraphPrinter.edge, g.routing, node, g.block_grid)


def format_entry(e):
    try:
        bits, sw, src, dst, *args = e
    except ValueError:
        return str(e)
    if args:
        args = " " + str(args)
    else:
        args = ""
    return RunOnStr(operator.mod, "[%s %s %s %s%s]", (",".join(bits), sw, src, dst, args))


def is_corner(ic, pos):
    return pos in (
        (0, 0), (0, ic.max_y), (ic.max_x, 0), (ic.max_x, ic.max_y))


def tiles(ic):
    for x in range(ic.max_x + 1):
        for y in range(ic.max_y + 1):
            p = PositionIcebox(x, y)
            if is_corner(ic, p):
                continue
            yield p


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
        # FIXME: Get the neighbourhood wires working.
        if "neigh_op" in netname:
            continue
        # FIXME: Get the logic_op wires working.
        if "logic_op" in netname:
            continue
        # FIXME: Get the sp4_r_v_ wires working
        if "sp4_r_v_" in netname:
            continue
        # FIXME: Fix the carry logic.
        if "cout" in netname or "carry_in" in netname:
            continue
        if "lout" in netname:
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

    good = []
    skipped = []
    if x_val[-1][0] > y_val[-1][0]:
        x_ipos = x_val[-1][1]
        for ipos, netname in group:
            if ipos.x != x_ipos:
                skipped.append((ipos, netname))
                continue
            good.append((ipos, netname))
    else:
        y_ipos = y_val[-1][1]
        for ipos, netname in group:
            if ipos.y != y_ipos:
                skipped.append((ipos, netname))
                continue
            good.append((ipos, netname))
    return good, skipped


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

    print('Loading rr_graph')
    g = graph.Graph(read_rr_graph, clear_fabric=True)
    g.set_tooling(
        name="icebox",
        version="dev",
        comment="Generated for iCE40 {} device".format(device_name))

    return ic, g


def add_pin_aliases(g, ic):
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

    name_rr2local['BLK_TL-PLB.FCOUT[0]'] = 'lutff_0/cout'

    # BLK_TL-PIO
    # http://www.clifford.at/icestorm/io_tile.html
    # FIXME: filter out orientations that don't exist?
    for blocki in range(2):
        name_rr2local['BLK_TL-PIO.[{}]LATCH[0]'.format(
            blocki)] = 'io_{}/latch'.format(blocki)
        name_rr2local['BLK_TL-PIO.[{}]OUTCLK[0]'.format(
            blocki)] = 'io_{}/outclk'.format(blocki)
        name_rr2local['BLK_TL-PIO.[{}]CEN[0]'.format(
            blocki)] = 'io_{}/cen'.format(blocki)
        name_rr2local['BLK_TL-PIO.[{}]INCLK[0]'.format(
            blocki)] = 'io_{}/inclk'.format(blocki)
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
        name_rr2local['BLK_TL-PIO.[{}]PACKAGE_PIN[0]'.format(
            blocki)] = 'io_{}/pin'.format(blocki)

    # BLK_TL-RAM
    for top_bottom in 'BT':
        # rdata, wdata, and mask ranges are the same based on Top/Bottom
        if top_bottom == 'T':
            data_range = range(8,16)
            # top has Read clock and enbable and address
            rw = 'R'
        else:
            data_range = range(0,8)
            # top has Read clock and enbable and address
            rw = 'W'

        def add_ram_pin(rw, sig, ind=None):
            if ind is None:
                name_rr2local['BLK_TL-RAM.{}{}[{}]'.format(rw, sig, 0)] = 'ram/{}{}'.format(rw, sig)
            else:
                name_rr2local['BLK_TL-RAM.{}{}[{}]'.format(rw, sig, ind)] = 'ram/{}{}_{}'.format(rw, sig, ind)

        add_ram_pin(rw, 'CLK')
        add_ram_pin(rw, 'CLKE')
        add_ram_pin(rw, 'E')

        for ind in range(11):
            add_ram_pin(rw, 'ADDR', ind)

        for ind in data_range:
            add_ram_pin('R', 'DATA', ind)
            add_ram_pin('W', 'DATA', ind)
            add_ram_pin('', 'MASK', ind)

    for block in g.block_grid:
        for pin in block.pins:
            if "RAM" in block.block_type.name:
                pin_pos = block.position + ram_pin_offset(pin)
            else:
                pin_pos = block.position
            ipos = pos_vpr2icebox(PositionVPR(*pin_pos))

            hlc_name = name_rr2local.get(pin.xmlname, group_hlc_name([(ipos, pin.name)]))

            node = g.routing.localnames[(pin_pos, pin.name)]
            node.set_metadata("hlc_coord", "{},{}".format(*ipos))
            node.set_metadata("hlc_name", hlc_name)

            rr_name = pin.xmlname
            try:
                localname = name_rr2local[rr_name]
            except KeyError:
                logging.warn("rr_name %s doesn't have a translation", rr_name)
                continue

            # FIXME: only add for actual position instead for all
            logging.debug(
                "Adding alias %s:%s for %s",
                PositionVPR(*block.position), localname, format_node(g, node))
            g.routing.localnames.add(pin_pos, localname, node)
            g.routing.localnames.add(pin_pos, hlc_name, node)


def add_dummy_tracks(g, ic):
    """Add a single dummy track to every channel."""
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


def add_global_tracks(g, ic):
    """Add the global tracks to every channel."""
    def skip(fmt, *args, **kw):
        raise AssertionError(fmt % args)

    GLOBAL_SPINE_ROW = ic.max_x // 2
    GLOBAL_BUF = "GLOBAL_BUFFER_OUTPUT"
    padin_db = ic.padin_pio_db()
    iolatch_db = ic.iolatch_db()

    # Create the 8 global networks
    glb = g.segments["global"]
    short = g.switches["__vpr_delayless_switch__"]
    for i in range(0, 8):
        glb_name = "glb_netwk_{}".format(i)

        # Vertical global wires
        for x in range(0, ic.max_x+1):
            istart = PositionIcebox(x, 0)
            iend = PositionIcebox(x, ic.max_y)
            track, track_node = g.create_xy_track(
                pos_icebox2vpr(istart), pos_icebox2vpr(iend),
                segment=glb,
                typeh=channel.Track.Type.Y,
                direction=channel.Track.Direction.BI)
            track_node.set_metadata("hlc_name", glb_name)
            for y in range(0, ic.max_y+1):
                ipos = PositionIcebox(x, y)
                vpos = pos_icebox2vpr(ipos)
                g.routing.localnames.add(vpos, glb_name, track_node)

        # One horizontal wire
        istart = PositionIcebox(0, GLOBAL_SPINE_ROW)
        iend = PositionIcebox(ic.max_x+1, GLOBAL_SPINE_ROW)
        track, track_node = g.create_xy_track(
            pos_icebox2vpr(istart), pos_icebox2vpr(iend),
            segment=glb,
            typeh=channel.Track.Type.X,
            direction=channel.Track.Direction.BI)
        track_node.set_metadata("hlc_name", glb_name)

        for x in range(0, ic.max_x+1):
            ipos = PositionIcebox(x, GLOBAL_SPINE_ROW)
            vpos = pos_icebox2vpr(ipos)
            g.routing.localnames.add(vpos, glb_name+"_h", track_node)

        # Connect the vertical wires to the horizontal one to make a single
        # global network
        for x in range(0, ic.max_x+1):
            ipos = PositionIcebox(x, GLOBAL_SPINE_ROW)
            create_edge_with_names(
                g,
                glb_name, glb_name+"_h",
                ipos, short,
                skip,
                bidir=True,
            )

    # Create the padin_X localname aliases for the glb_network_Y
    # FIXME: Why do these exist!?
    for n, (gx, gy, gz) in enumerate(padin_db):
        vpos = pos_icebox2vpr(PositionIcebox(gx, gy))

        glb_name = "glb_netwk_{}".format(n)
        glb_node = g.routing.get_by_name(glb_name, vpos)
        g.routing.localnames.add(vpos, "padin_{}".format(gz), glb_node)

    # Create the IO->global drivers which exist in some IO tiles.
    for n, (gx, gy, gz) in enumerate(padin_db):
        ipos = PositionIcebox(gx, gy)
        vpos = pos_icebox2vpr(ipos)

        # Create the GLOBAL_BUFFER_OUTPUT track and short it to the
        # PACKAGE_PIN output of the correct IO subtile.
        track, track_node = g.create_xy_track(
            vpos, vpos,
            segment=glb,
            typeh=channel.Track.Type.Y,
            direction=channel.Track.Direction.BI)
        track_node.set_metadata(
            "hlc_name", "io_{}/{}".format(gz, GLOBAL_BUF))
        g.routing.localnames.add(vpos, GLOBAL_BUF, track_node)

        create_edge_with_names(
            g,
            "io_{}/pin".format(gz), GLOBAL_BUF,
            ipos, short,
            skip,
        )

        # Create the switch to enable the GLOBAL_BUFFER_OUTPUT track to
        # drive the global network.
        create_edge_with_names(
            g,
            GLOBAL_BUF, "glb_netwk_{}".format(n),
            ipos, g.switches["buffer"],
            skip,
        )

    # Work out for which tiles the fabout is directly shorted to a global
    # network.
    fabout_to_glb = {}
    for gn, (gx, gy, gz) in enumerate(padin_db):
        ipos = PositionIcebox(gx, gy)
        assert ipos not in fabout_to_glb, (ipos, fabout_to_glb)
        gn = None
        for igx, igy, ign in ic.gbufin_db():
            if ipos == (igx, igy):
                gn = ign
        assert gn is not None, (ipos, gz, gn)

        fabout_to_glb[ipos] = (gz, gn)

    # Create the nets which are "global" to an IO tile pair.
    for ipos in list(tiles(ic)):
        tile_type = ic.tile_type(*ipos)
        if tile_type != "IO":
            continue

        vpos = pos_icebox2vpr(ipos)

        # Create the "io_global" signals inside a tile
        io_names = [
            "inclk",
            "outclk",
            "cen",
            "latch",
        ]
        for name in io_names:
            glb_name = "io_global/{}".format(name)

            hlc_name = group_hlc_name([(ipos, glb_name)])
            track, track_node = g.create_xy_track(
                vpos, vpos,
                segment=glb,
                typeh=channel.Track.Type.Y,
                direction=channel.Track.Direction.BI)
            track_node.set_metadata("hlc_name", hlc_name)
            g.routing.localnames.add(vpos, glb_name, track_node)

            # Connect together the io_global signals inside a tile
            for i in range(2):
                local_name = "io_{}/{}".format(i, name)
                create_edge_with_names(
                    g,
                    glb_name,
                    local_name,
                    ipos, short,
                    skip,
                )

        # Create the fabout track. Every IO tile has a fabout track, but
        # sometimes the track is special;
        # - drives a glb_netwk_X,
        # - drives the io_global/latch for the bank
        hlc_name = group_hlc_name([(ipos, "fabout")])
        track, track_node = g.create_xy_track(
            vpos, vpos,
            segment=glb,
            typeh=channel.Track.Type.Y,
            direction=channel.Track.Direction.BI)
        track_node.set_metadata("hlc_name", hlc_name)
        g.routing.localnames.add(vpos, "fabout", track_node)

        # Fabout drives a global network?
        if ipos in fabout_to_glb:
            gz, gn = fabout_to_glb[ipos]
            create_edge_with_names(
                g,
                "fabout", "glb_netwk_{}".format(gn),
                ipos, short,
                skip,
            )

        # Fabout drives the io_global/latch?
        if ipos in iolatch_db:
            create_edge_with_names(
                g,
                "fabout", "io_global/latch",
                ipos, short,
                skip,
            )


def create_edge_with_names(g, src_name, dst_name, ipos, switch, skip, bidir=False):
    src_hlc_name = group_hlc_name([(ipos, src_name)])
    dst_hlc_name = group_hlc_name([(ipos, dst_name)])

    vpos = pos_icebox2vpr(ipos)
    src_node = g.routing.get_by_name(src_name, vpos, None)
    dst_node = g.routing.get_by_name(dst_name, vpos, None)

    if src_node is None:
        skip(
            "src missing *%s:%s* (%s) node %s => %s:%s (%s) node %s",
            vpos,
            src_name,
            src_hlc_name,
            format_node(g, src_node),
            vpos,
            dst_name,
            dst_hlc_name,
            format_node(g, dst_node),
            level=logging.WARNING,
        )
        return
    if dst_node is None:
        skip(
            "dst missing %s:%s (%s) node %s => *%s:%s* (%s) node %s",
            vpos,
            src_name,
            src_hlc_name,
            format_node(g, src_node),
            vpos,
            dst_name,
            dst_hlc_name,
            format_node(g, dst_node),
        )
        return

    logging.debug(
        "On %s add %-8s edge %s - %s:%s (%s) node %s => %s:%s (%s) node %s",
        ipos,
        switch.name,
        len(g.routing.id2element[graph.RoutingEdge]),
        vpos,
        src_name,
        src_hlc_name,
        format_node(g, src_node),
        vpos,
        dst_name,
        dst_hlc_name,
        format_node(g, dst_node),
    )

    edge = g.routing.create_edge_with_nodes(src_node, dst_node, switch=switch)
    edge.set_metadata("hlc_coord", "{},{}".format(*ipos))
    if bidir:
        edge = g.routing.create_edge_with_nodes(dst_node, src_node, switch=switch)
        edge.set_metadata("hlc_coord", "{},{}".format(*ipos))


def add_tracks(g, ic, all_group_segments, segtype_filter=None):
    add_dummy_tracks(g, ic)

    for group in sorted(all_group_segments):
        group = [(PositionIcebox(x, y), netname) for x, y, netname in group]

        segtype = group_seg_type(group)
        if segtype_filter is not None and segtype != segtype_filter:
            continue
        if segtype == "unknown":
            logging.debug("Skipping unknown track group: %s", group)
            continue
        if segtype == "global":
            logging.debug("Skipping global track group: %s", group)
            continue
        segment = g.segments[segtype]

        fgroup = filter_track_names(group)
        if not fgroup:
            logging.debug("Filtered out track group: %s", group)
            continue

        fgroup, skipped = filter_non_straight(fgroup)
        assert len(fgroup) > 0, (fgroup, fgroup)
        if len(skipped) > 0:
            logging.debug("""Filtered non-straight segments;
 Skipping: %s
Remaining: %s""", skipped, fgroup)

        hlc_name = group_hlc_name(group)

        istart, iend = find_path(fgroup)
        if istart.x == iend.x and istart.y != iend.y:
            typeh = channel.Track.Type.Y
        elif istart.x != iend.x and istart.y == iend.y:
            typeh = channel.Track.Type.X
        elif istart.x != iend.x and istart.y != iend.y:
            logging.warn("Skipping non-straight track group: %s (%s)", fgroup, group)
            continue
        else:
            typeh = group_chan_type(fgroup)
        vstart, vend = pos_icebox2vpr(istart), pos_icebox2vpr(iend)

        track, track_node = g.create_xy_track(
            vstart, vend,
            segment=segment,
            typeh=typeh,
            direction=channel.Track.Direction.BI)

        track_fmt = format_node(g, track_node)
        logging.debug(
            "Created track %s %s %s from %s %s",
            hlc_name, track_fmt, segment.name, typeh, group)

        track_node.set_metadata("hlc_name", hlc_name)
        if segtype != "local":
            g.routing.globalnames.add(hlc_name, track_node)
            logging.debug(
                " Setting global name %s for %s",
                hlc_name, track_fmt)

        for pos, netname in fgroup:
            vpos = pos_icebox2vpr(pos)
            g.routing.localnames.add(vpos, netname, track_node)
            logging.debug(
                " Setting local  name %s on %s for %s",
                netname, vpos, track_fmt)


def add_edges(g, ic):
    for ipos in list(tiles(ic)):
        tile_type = ic.tile_type(*ipos)
        vpos = pos_icebox2vpr(ipos)

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
            def skip(m, *args, level=logging.DEBUG, **kw):
                p = {
                    logging.DEBUG: logging.debug,
                    logging.WARNING: logging.warn,
                    logging.INFO: logging.info,
                }[level]
                p("On %s skipping entry %s: "+m, ipos, format_entry(entry), *args, **kw)

            if not ic.tile_has_entry(*ipos, entry):
                #skip('Non-existent edge!')
                continue

            switch_type = entry[1]
            if switch_type not in ("routing", "buffer"):
                skip('Unknown switch type %s', switch_type)
                continue

            src_localname = entry[2]
            dst_localname = entry[3]

            remaining = filter_track_names([(ipos, src_localname), (ipos, dst_localname)])
            if len(remaining) != 2:
                skip("Remaining %s", remaining)
                continue

            create_edge_with_names(
                g,
                src_localname, dst_localname,
                ipos, g.switches[switch_type],
                skip,
            )


def print_nodes_edges(g):
    print("Edges: %d (index: %d)" %
          (len(g.routing._xml_parent(graph.RoutingEdge)),
           len(g.routing.id2element[graph.RoutingEdge])))
    print("Nodes: %d (index: %d)" %
          (len(g.routing._xml_parent(graph.RoutingNode)),
           len(g.routing.id2element[graph.RoutingNode])))


def ram_pin_offset(pin):
    top_pins = ["RADDR", "RCLKE", "RCLK", "RE"]
    bot_pins = ["WADDR", "WCLKE", "WCLK", "WE"]
    if pin.port_name in top_pins or (
            pin.port_name in ["RDATA", "MASK", "WDATA"] and
            pin.port_index in range(8,16)):
        return Offset(0, 1)
    elif pin.port_name in bot_pins or (
            pin.port_name in ["RDATA", "MASK", "WDATA"] and
            pin.port_index in range(8)):
        return Offset(0, 0)
    else:
        assert False, "RAM pin doesn't match name expected for metadata"


def get_pin_meta(block, pin):
    grid_sz = PositionVPR(ic.max_x+1+4, ic.max_y+1+4)
    if "PIN" in block.block_type.name:
        if block.position.x == 1:
            return (graph.RoutingNodeSide.RIGHT, Offset(0, 0))
        elif block.position.y == 1:
            return (graph.RoutingNodeSide.TOP, Offset(0, 0))
        elif block.position.y == grid_sz.y-2:
            return (graph.RoutingNodeSide.BOTTOM, Offset(0, 0))
        elif block.position.x == grid_sz.x-2:
            return (graph.RoutingNodeSide.LEFT, Offset(0, 0))

    if "RAM" in block.block_type.name:
        return (graph.RoutingNodeSide.RIGHT, ram_pin_offset(pin))

    if "PIO" in block.block_type.name:
        if pin.name.startswith("O[") or pin.name.startswith("I["):
            if block.position.x == 2:
                return (graph.RoutingNodeSide.LEFT, Offset(0, 0))
            elif block.position.y == 2:
                return (graph.RoutingNodeSide.BOTTOM, Offset(0, 0))
            elif block.position.y == grid_sz.y-3:
                return (graph.RoutingNodeSide.TOP, Offset(0, 0))
            elif block.position.x == grid_sz.x-3:
                return (graph.RoutingNodeSide.RIGHT, Offset(0, 0))
        return (graph.RoutingNodeSide.RIGHT, Offset(0, 0))

    if "PLB" in block.block_type.name:
        if "FCIN" in pin.port_name:
            return (graph.RoutingNodeSide.BOTTOM, Offset(0, 0))
        elif "FCOUT" in pin.port_name:
            return (graph.RoutingNodeSide.TOP, Offset(0, 0))

        return (graph.RoutingNodeSide.RIGHT, Offset(0, 0))

    assert False, (block, pin)


def main(part, read_rr_graph, write_rr_graph):
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
    add_pin_aliases(g, ic)

    segments = ic.group_segments(list(tiles(ic)))
    add_tracks(g, ic, segments, segtype_filter="local")
    add_tracks(g, ic, segments, segtype_filter="span4")
    add_tracks(g, ic, segments, segtype_filter="span12")
    add_global_tracks(g, ic)

    print()
    print('Adding edges')
    print('='*80)
    add_edges(g, ic)
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

    if args.verbose:
        loglevel=logging.DEBUG
    else:
        loglevel=logging.INFO
    logging.basicConfig(level=loglevel)

    mode = args.device.lower()[2:]
    main(mode, args.read_rr_graph, args.write_rr_graph)
