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
from collections import namedtuple, OrderedDict, defaultdict
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
import lib.rr_graph.channel as channel
import lib.rr_graph.graph as graph
import lib.rr_graph.points as points
from lib.rr_graph import Offset
from lib.asserts import assert_eq
from lib.asserts import assert_not_in
from lib.asserts import assert_type

NP = points.NamedPosition

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
    """Convert icebox to VTR coordinates."""
    assert_type(pos, PositionIcebox)
    return PositionVPR(pos.x + 2, pos.y + 2)


def pos_vpr2icebox(pos):
    """Convert VTR to icebox coordinates."""
    assert_type(pos, PositionVPR)
    return PositionIcebox(pos.x - 2, pos.y - 2)


def pos_icebox2vprpin(pos):
    """Convert icebox IO position into VTR 'pin' position."""
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
    """A pretty string from an RoutingGraph node."""
    if node is None:
        return "None"
    assert isinstance(node, ET._Element), node
    if node.tag == "node":
        return RunOnStr(graph.RoutingGraphPrinter.node, node, g.block_grid)
    elif node.tag == "edge":
        return RunOnStr(graph.RoutingGraphPrinter.edge, g.routing, node, g.block_grid)


def format_entry(e):
    """A pretty string from an icebox entry."""
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
    """Return if a position is the corner of an chip."""
    return pos in (
        (0, 0), (0, ic.max_y), (ic.max_x, 0), (ic.max_x, ic.max_y))


def tiles(ic):
    """Return all tiles on the chip (except the corners)."""
    for x in range(ic.max_x + 1):
        for y in range(ic.max_y + 1):
            p = PositionIcebox(x, y)
            if is_corner(ic, p):
                continue
            yield p


def filter_track_names(group):
    """Filter out unusable icebox track names."""
    assert_type(group, list)
    for p in group:
        assert_type(p.pos, PositionIcebox)
        names = list(p.names)
        p.names.clear()

        for n in names:
            # FIXME: Get the sp4_r_v_ wires working
            if "sp4_r_v_" in n:
                continue
            # FIXME: Fix the carry logic.
            if "cout" in n or "carry_in" in n:
                continue
            if "lout" in n:
                continue
            p.names.append(n)

    rgroup = []
    for p in group:
        if not p.names:
            continue
        rgroup.append(p)
    return rgroup


def group_hlc_name(group):
    """Get the HLC "global name" from a group local names."""
    assert_type(group, list)
    global ic
    hlcnames = defaultdict(int)
    hlcnames_details = []
    for ipos, localnames in group:
        for name in localnames:
            assert_type(ipos, PositionIcebox)
            hlcname = icebox_asc2hlc.translate_netname(*ipos, ic.max_x-1, ic.max_y-1, name)

            if hlcname != name:
                hlcnames_details.append((ipos, name, hlcname))

            hlcnames[hlcname] += 1

    if not hlcnames:
        return None

    if len(hlcnames) > 1:
        logging.warn("Multiple HLC names (%s) found group %s", hlcnames, group)
        filtered_hlcnames = {k: v for k,v in hlcnames.items() if v > 1}
        if not filtered_hlcnames:
            return None
        if len(filtered_hlcnames) != 1:
            logging.warn("Skipping as conflicting names for %s (%s)", hlcnames, hlcnames_details)
            return None
        hlcnames = filtered_hlcnames
    assert len(hlcnames) == 1, (hlcnames, hlcnames_details)
    return list(hlcnames.keys())[0]


def group_seg_type(group):
    """Get the segment type from a group of local names."""
    assert_type(group, list)

    types = defaultdict(int)
    for ipos, localnames in group:
        assert_type(ipos, PositionIcebox)
        for name in localnames:
            # ???
            if "/" in name:
                types["pin"] += 1
                continue
            if "carry" in name:
                types["pin"] += 1
                continue
            # DSP Pins
            # FIXME: Must be a better way to do this.
            if name in ("clk", "ce", "c", "a", "b", "c", "ci", "o", "co"):
                types["pin"] += 1
                continue
            if "hold" in name:
                types["pin"] += 1
                continue
            if "rst" in name:  # irsttop, irstbot, orsttop, orstbot
                types["pin"] += 1
                continue
            if "load" in name:  # oloadtop, oloadbot
                types["pin"] += 1
                continue
            if "addsub" in name:  # oloadtop, oloadbot
                types["pin"] += 1
                continue
            # Normal tracks...
            if "local" in name:
                types["local"] += 1
            if "op" in name:
                types["neigh"] += 1
            if "global" in name:
                types["global"] += 1
            if "sp4" in name or "span4" in name:
                types["span4"] += 1
            if "sp12" in name or "span12" in name:
                types["span12"] += 1
            # The global drivers
            if "fabout" in name:
                types["local"] += 1
            if "pin" in name:
                types["local"] += 1

    assert types, "No group types for {}".format(group)

    if len(types) > 1:
        logging.warn("Multiple types (%s) found for group %s", types, group)
        filtered_types = {k: v for k,v in types.items() if v > 1}
        assert len(filtered_types) == 1, (filtered_types, types, group)
        types = filtered_types

    assert len(types) == 1, "Multiple group types {} for {}".format(types, group)
    for k in types:
        return k
    assert False, types


def group_chan_type(group):
    """Get the channel track type from a group of local names."""
    assert_type(group, list)
    for ipos, netname in group:
        assert_type(ipos, PositionIcebox)
        if "local" in netname:
            return channel.Track.Type.Y
        if "_h" in netname:
            return channel.Track.Type.X
        if "_v" in netname:
            return channel.Track.Type.Y
        # The drivers
        if "fabout" in netname:
            return channel.Track.Type.X
        if "pin" in netname:
            return channel.Track.Type.X
        if "/" in netname:
            return channel.Track.Type.Y
    assert False, group
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
    """Create icebox local names from the architecture pin names."""
    name_rr2local = {}

    # BLK_TL-PLB - http://www.clifford.at/icestorm/logic_tile.html
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

    # BLK_TL-PIO - http://www.clifford.at/icestorm/io_tile.html
    for blocki in range(2):
        name_rr2local['BLK_TL-PIO.[{}]LATCH[0]'.format(
            blocki)] = 'io_{}/latch'.format(blocki)
        name_rr2local['BLK_TL-PIO.[{}]OUTCLK[0]'.format(
            blocki)] = 'io_{}/outclk'.format(blocki)
        name_rr2local['BLK_TL-PIO.[{}]CEN[0]'.format(
            blocki)] = 'io_{}/cen'.format(blocki)
        name_rr2local['BLK_TL-PIO.[{}]INCLK[0]'.format(
            blocki)] = 'io_{}/inclk'.format(blocki)
        name_rr2local['BLK_TL-PIO.[{}]D_IN[0]'.format(
            blocki)] = 'io_{}/D_IN_0'.format(blocki)
        name_rr2local['BLK_TL-PIO.[{}]D_IN[1]'.format(
            blocki)] = 'io_{}/D_IN_1'.format(blocki)
        name_rr2local['BLK_TL-PIO.[{}]D_OUT[0]'.format(
            blocki)] = 'io_{}/D_OUT_0'.format(blocki)
        name_rr2local['BLK_TL-PIO.[{}]D_OUT[1]'.format(
            blocki)] = 'io_{}/D_OUT_1'.format(blocki)
        name_rr2local['BLK_TL-PIO.[{}]OUT_ENB[0]'.format(
            blocki)] = 'io_{}/OUT_ENB'.format(blocki)
        name_rr2local['BLK_TL-PIO.[{}]PACKAGE_PIN[0]'.format(
            blocki)] = 'io_{}/pin'.format(blocki)

    # BLK_TL-RAM - http://www.clifford.at/icestorm/ram_tile.html
    for top_bottom in 'BT':
        # rdata, wdata, and mask ranges are the same based on Top/Bottom
        if top_bottom == 'T':
            data_range = range(8,16)
            # top has Read clock and enable and address
            rw = 'R'
        else:
            data_range = range(0,8)
            # top has Read clock and enable and address
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
                pin_offset = ram_pin_offset(pin)
            elif "DSP" in block.block_type.name:
                pin_offset = dsp_pin_offset(pin)
            else:
                pin_offset = Offset(0, 0)
            pin_pos = block.position + pin_offset

            vpos = PositionVPR(*pin_pos)
            ipos = pos_vpr2icebox(vpos)

            node = g.routing.localnames[(pin_pos, pin.name)]
            node.set_metadata("hlc_coord", "{},{}".format(*ipos))

            logging.debug("On %s for %s", vpos, format_node(g, node))

            hlc_name = name_rr2local.get(
                pin.xmlname, group_hlc_name([NP(ipos, [pin.name])]))
            logging.debug(
                " Setting local name %s on %s for %s",
                hlc_name, vpos, format_node(g, node))
            g.routing.localnames.add(vpos, hlc_name, node)
            node.set_metadata("hlc_name", hlc_name)

            rr_name = pin.xmlname
            try:
                localname = name_rr2local[rr_name]
            except KeyError:
                logging.warn(
                    "On %s - %s doesn't have a translation",
                    ipos, rr_name)
                continue

            # FIXME: only add for actual position instead for all
            if localname == hlc_name:
                logging.debug(
                    " Local name %s same as hlc_name on %s for %s",
                    localname, vpos, format_node(g, node))
            else:
                assert False, "{} != {}".format(localname, hlc_name)
                logging.debug(
                    " Setting local name %s on %s for %s",
                    localname, vpos, format_node(g, node))
                g.routing.localnames.add(vpos, localname, node)


def add_dummy_tracks(g, ic):
    """Add a single dummy track to every channel."""
    dummy = g.segments["dummy"]
    for x in range(-2, ic.max_x+2):
        istart = PositionIcebox(x, 0)
        iend = PositionIcebox(x, ic.max_y)
        track, track_node = g.create_xy_track(
            pos_icebox2vpr(istart), pos_icebox2vpr(iend),
            segment=dummy,
            direction=channel.Track.Direction.BI,
            capacity=0)
    for y in range(-2, ic.max_y+2):
        istart = PositionIcebox(0, y)
        iend = PositionIcebox(ic.max_x, y)
        track, track_node = g.create_xy_track(
            pos_icebox2vpr(istart), pos_icebox2vpr(iend),
            segment=dummy,
            direction=channel.Track.Direction.BI,
            capacity=0)


# FIXME: Currently unused.
def add_global_tracks(g, ic):
    """Add the global tracks to every channel."""
    add_dummy_tracks(g, ic)

    GLOBAL_SPINE_ROW = ic.max_x // 2
    GLOBAL_BUF = "GLOBAL_BUFFER_OUTPUT"
    padin_db = ic.padin_pio_db()
    iolatch_db = ic.iolatch_db()

    # Create the 8 global networks
    for i in range(0, 8):
        glb_name = "glb_netwk_{}".format(i)
        seg = g.segments[glb_name]

        # Vertical global wires
        for x in range(0, ic.max_x+1):
            istart = PositionIcebox(x, 0)
            iend = PositionIcebox(x, ic.max_y)
            track, track_node = g.create_xy_track(
                pos_icebox2vpr(istart), pos_icebox2vpr(iend),
                segment=seg,
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
            segment=seg,
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
                ipos, g.switches['short'],
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
        glb_name = "glb_netwk_{}".format(n)
        ipos = PositionIcebox(gx, gy)
        vpos = pos_icebox2vpr(ipos)

        # Create the GLOBAL_BUFFER_OUTPUT track and short it to the
        # PACKAGE_PIN output of the correct IO subtile.
        track, track_node = g.create_xy_track(
            vpos, vpos,
            segment=g.segments[glb_name],
            typeh=channel.Track.Type.Y,
            direction=channel.Track.Direction.BI)
        track_node.set_metadata(
            "hlc_name", "io_{}/{}".format(gz, GLOBAL_BUF))
        g.routing.localnames.add(vpos, GLOBAL_BUF, track_node)

        create_edge_with_names(
            g,
            "io_{}/pin".format(gz), GLOBAL_BUF,
            ipos, g.switches["driver"],
        )

        # Create the switch to enable the GLOBAL_BUFFER_OUTPUT track to
        # drive the global network.
        create_edge_with_names(
            g,
            GLOBAL_BUF, glb_name,
            ipos, g.switches["buffer"],
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
            tile_glb_name = "io_global/{}".format(name)

            hlc_name = group_hlc_name([NP(ipos, [tile_glb_name])])
            track, track_node = g.create_xy_track(
                vpos, vpos,
                segment=g.segments['tile_global'],
                typeh=channel.Track.Type.Y,
                direction=channel.Track.Direction.BI)
            track_node.set_metadata("hlc_name", hlc_name)
            g.routing.localnames.add(vpos, tile_glb_name, track_node)

            # Connect together the io_global signals inside a tile
            for i in range(2):
                local_name = "io_{}/{}".format(i, name)
                create_edge_with_names(
                    g,
                    tile_glb_name, local_name,
                    ipos, g.switches['driver'],
                )

        # Create the fabout track. Every IO tile has a fabout track, but
        # sometimes the track is special;
        # - drives a glb_netwk_X,
        # - drives the io_global/latch for the bank
        hlc_name = group_hlc_name([NP(ipos, ["fabout"])])
        track, track_node = g.create_xy_track(
            vpos, vpos,
            segment=g.segments['fabout'],
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
                ipos, g.switches['short'],
            )

        # Fabout drives the io_global/latch?
        if ipos in iolatch_db:
            create_edge_with_names(
                g,
                "fabout", "io_global/latch",
                ipos, g.switches['short'],
            )


def create_edge_with_names(g, src_name, dst_name, ipos, switch, skip=None, bidir=None):
    """Create an edge at a given icebox position from two local names."""
    assert_type(src_name, str)
    assert_type(dst_name, str)
    assert_type(ipos, PositionIcebox)
    assert_type(switch, graph.Switch)

    if skip is None:
        def skip(fmt, *a, **k):
            raise AssertionError(fmt % a)

    if switch.type in (graph.SwitchType.SHORT, graph.SwitchType.PASS_GATE):
        if bidir is None:
            bidir = True
        else:
            assert bidir is True, "Switch {} must be bidir ({})".format(
                switch, (ipos, src_name, dst_name, bidir))
    elif bidir is None:
        bidir = False

    src_hlc_name = group_hlc_name([NP(ipos, [src_name])])
    dst_hlc_name = group_hlc_name([NP(ipos, [dst_name])])

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

    g.routing.create_edge_with_nodes(
        src_node, dst_node,
        switch=switch,
        bidir=bidir,
        metadata={Offset(0,0):{"hlc_coord": "{},{}".format(*ipos)}},
    )


def add_track_with_lines(g, ic, segment, lines, connections, hlc_name_f):
    """Add tracks to the rr_graph from straight lines and connections."""
    logging.debug(
        "Created track %s from sections: %s", segment.name, len(lines))
    logging.debug(
        "Created track %s from sections: %s", segment.name, lines)
    for line in lines:
        istart, iend = points.straight_ends([p.pos for p in line])
        logging.debug(
            "  %s>%s (%s)", istart, iend, line) #{n for p, n in named_positions})
    for ipos, joins in sorted(connections.items()):
        for name_a, name_b in joins:
            logging.debug(
                "  %s %s<->%s", ipos, name_a, name_b)

    for line in lines:
        istart, iend = points.straight_ends([p.pos for p in line])
        vstart, vend = pos_icebox2vpr(istart), pos_icebox2vpr(iend)

        if line.direction.value == '-':
            typeh = channel.Track.Type.X
        elif line.direction.value == '|':
            typeh = channel.Track.Type.Y
        else:
            typeh = channel.Track.Type.Y

        track, track_node = g.create_xy_track(
            vstart, vend,
            segment=segment,
            typeh=typeh,
            direction=channel.Track.Direction.BI,
        )
        track_node.set_metadata("hlc_coord", "{},{}".format(*istart), offset=Offset(0, 0))
        # FIXME: Add offset for iend

        # <metadata>
        #   <meta name="hlc_name">{PI( 0, 1): 'io_1/D_IN_0', PI( 1, 1): 'neigh_op_lft_2,neigh_op_lft_6'}</meta>
        # </metadata>
        #
        # <metadata>
        #   <meta name="hlc_name" x_offset="0" y_offset="1">io_1/D_IN_0</meta>
        #   <meta name="hlc_name" x_offset="1" y_offset="1">neigh_op_lft_2</meta>
        #   <meta name="hlc_name" x_offset="1" y_offset="1">neigh_op_lft_6</meta>
        # </metadata>

        track_fmt = format_node(g, track_node)
        logging.debug(
            " Created track %s %s from %s", track_fmt, segment.name, typeh)

        for npos in line:
            ipos = npos.pos
            vpos = pos_icebox2vpr(ipos)

            offset = Offset(npos.pos.x-line[0].pos.x, npos.pos.y-line[0].pos.y)
            hlc_name = hlc_name_f(line, ipos)
            if hlc_name is not None:
                track_node.set_metadata("hlc_name", hlc_name, offset=offset)

            for n in npos.names:
                try:
                    g.routing.localnames[(vpos, n)]

                    drv_node = g.routing.localnames[(vpos, n)]
                    drv_fmt = str(format_node(g, drv_node))
                    logging.debug(
                        "  Existing node %s with local name %s on %s",
                        drv_fmt, n, vpos)

                    g.routing.localnames.add(vpos, n+"_?", track_node)
                    if ipos in connections:
                        continue
                    connections[ipos].append((n, n+"_?"))
                except KeyError:
                    g.routing.localnames.add(vpos, n, track_node)
                    logging.debug(
                        "  Setting local name %s on %s for %s",
                        n, vpos, track_fmt)

    for ipos, joins in sorted(connections.items()):
        logging.info("pos:%s joins:%s", ipos, joins)
        for name_a, name_b in joins:
            vpos = pos_icebox2vpr(ipos)

            node_a = g.routing.localnames[(vpos, name_a)]
            node_b = g.routing.localnames[(vpos, name_b)]

            logging.debug(" Shorting at coords %s - %s -> %s\n\t%s\n ->\n\t%s",
                ipos, name_a, name_b,
                format_node(g, node_a),
                format_node(g, node_b),
            )
            create_edge_with_names(
                g,
                name_a, name_b,
                ipos, g.switches["short"],
            )


def add_track_with_globalname(g, ic, segment, connections, lines, globalname):
    """Add tracks to the rr_graph from lines, connections, using a HLC global name."""
    def hlc_name_f(line, offset):
        return globalname
    add_track_with_lines(g, ic, segment, lines, connections, hlc_name_f)


def add_track_with_localnames(g, ic, segment, connections, lines):
    """Add tracks to the rr_graph from lines, connections, using local names (from the positions)."""
    def hlc_name_f(line, pos):
        for npos in line:
            if pos.x == npos.x and pos.y == npos.y:
                names = set(n for n in npos.names if not n.endswith("_x"))
                assert len(names) <= 1, (line, npos)
                if not names:
                    return None
                return names.pop()
        assert False, (line, npos, pos)

    new_lines = []
    for line in lines:
        names = [n for n in line.names if not n.endswith('_x')]
        if len(names) <= 1:
            continue

        for npos in line:
            if len(npos.names) <= 1:
                continue
            fnames = [i for i in npos.names if not i.endswith("_x")]
            if len(fnames) <= 1:
                continue
            logging.debug("temp - %s %s %s", npos, fnames[0], fnames[1:])
            for name in fnames[1:]:
                npos.names.remove(name)
                new_pos = points.NamedPosition(npos.pos, [name])
                new_line = points.StraightSegment(
                    direction=line.direction, positions=[new_pos])
                logging.debug(
                    "npos:%s name:%s new_pos:%s new_line:%s",
                    npos, name, new_pos, new_line)
                new_lines.append(new_line)
                connections[npos.pos].append((fnames[0], name))
                assert new_lines[-1], (npos, new_lines)
            assert npos.names, npos
    logging.debug("new_lines: %s", new_lines)
    lines.extend(new_lines)
    add_track_with_lines(g, ic, segment, lines, connections, hlc_name_f)



def add_tracks(g, ic, all_group_segments, segtype_filter=None):
    """Adding tracks from icebox segment groups."""
    add_dummy_tracks(g, ic)

    for group in sorted(all_group_segments):
        positions = {}
        for x, y, netname in group:
            p = PositionIcebox(x, y)
            if p in positions:
                positions[p].names.append(netname)
            else:
                positions[(x, y)] = points.NamedPosition(p, [netname])
        positions = list(positions.values())

        segtype = group_seg_type(positions)
        if segtype_filter is not None and segtype != segtype_filter:
            continue
        if segtype == "unknown":
            logging.debug("Skipping unknown track group: %s", group)
            continue
        if segtype == "global":
            logging.debug("Skipping global track group: %s", group)
            continue
        segment = g.segments[segtype]

        fpositions = filter_track_names(positions)
        if not fpositions:
            logging.debug("Filtered out track group: %s", positions)
            continue

        connections, lines = points.decompose_into_straight_lines(fpositions)
        logging.info("connections:%s lines:%s", connections, lines)
        hlc_name = group_hlc_name(fpositions)
        if hlc_name:
            add_track_with_globalname(g, ic, segment, connections, lines, hlc_name)
        else:
            add_track_with_localnames(g, ic, segment, connections, lines)


def add_edges(g, ic):
    """Adding edges to the rr_graph from icebox edges."""
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

            remaining = filter_track_names([NP(ipos, [src_localname]), NP(ipos, [dst_localname])])
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
    """Get the offset for a given RAM pin."""
    # The pin split between top/bottom tiles is different on the 1k to all the
    # other parts.
    ram_pins_0to8 = ["WADDR[0]", "WCLKE[0]", "WCLK[0]", "WE[0]"]
    for i in range(8):
        ram_pins_0to8.extend([
            "RDATA[{}]".format(i),
            "MASK[{}]".format(i),
            "WDATA[{}]".format(i),
        ])
    ram_pins_0to8.extend(['WADDR[{}]'.format(i) for i in range(0, 11)])

    ram_pins_8to16 = ["RCLKE[0]", "RCLK[0]", "RE[0]"]
    for i in range(8,16):
        ram_pins_8to16.extend([
            "RDATA[{}]".format(i),
            "MASK[{}]".format(i),
            "WDATA[{}]".format(i),
        ])
    ram_pins_8to16.extend(['RADDR[{}]'.format(i) for i in range(0, 11)])

    if ic.device == '384':
        assert False, "384 device doesn't have RAM!"
    elif ic.device == '1k':
        top_pins = ram_pins_8to16
        bot_pins = ram_pins_0to8
    else:
        assert ic.device in ('5k', '8k'), "{} is unknown device".format(ic.device)
        top_pins = ram_pins_0to8
        bot_pins = ram_pins_8to16

    if pin.name in top_pins:
        return Offset(0, 1)
    elif pin.name in bot_pins:
        return Offset(0, 0)
    else:
        assert False, "RAM pin {} doesn't match name expected for metadata".format(pin.name)


def dsp_pin_offset(pin):
    return Offset(0, pin.port_index)


def get_pin_meta(block, pin):
    """Get the offset and edge for a given pin."""
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

    if "DSP" in block.block_type.name:
        return (graph.RoutingNodeSide.RIGHT, dsp_pin_offset(pin))

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

    short = graph.Switch(
        id=g.switches.next_id(), type=graph.SwitchType.SHORT, name="short",
        timing=graph.SwitchTiming(R=0, Cin=0, Cout=0, Tdel=0),
        sizing=graph.SwitchSizing(mux_trans_size=0, buf_size=0),
    )
    g.add_switch(short)
    driver = graph.Switch(
        id=g.switches.next_id(), type=graph.SwitchType.BUFFER, name="driver",
        timing=graph.SwitchTiming(R=0, Cin=0, Cout=0, Tdel=0),
        sizing=graph.SwitchSizing(mux_trans_size=0, buf_size=0),
    )
    g.add_switch(driver)

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
    add_tracks(g, ic, segments, segtype_filter="neigh")
    add_tracks(g, ic, segments, segtype_filter="span4")
    add_tracks(g, ic, segments, segtype_filter="span12")
    #add_global_tracks(g, ic)

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
