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

import sys
import os.path
MYDIR = os.path.dirname(__file__)
sys.path.insert(0, os.path.join(MYDIR, "..", "..", "utils"))
sys.path.insert(0, os.path.join(MYDIR, "..", "..", "third_party", "icestorm", "icebox"))

from os.path import commonprefix

import icebox
import icebox_asc2hlc
import lib.rr_graph.graph as graph
import lib.rr_graph.channel as channel
import re

import operator
from collections import namedtuple, OrderedDict
from functools import reduce
import lxml.etree as ET

VERBOSE = True
device_name = None

LOCAL_TRACKS_PER_GROUP = 8
LOCAL_TRACKS_MAX_GROUPS = 4

GBL2LOCAL_MAX_TRACKS = 4

SPAN4_MAX_TRACKS = 48
SPAN12_MAX_TRACKS = 24

GLOBAL_MAX_TRACKS = 8

# TODO check this
chan_width_max = LOCAL_TRACKS_MAX_GROUPS * (
    LOCAL_TRACKS_PER_GROUP + 1
) + GBL2LOCAL_MAX_TRACKS + SPAN4_MAX_TRACKS + SPAN12_MAX_TRACKS + GLOBAL_MAX_TRACKS


def P1(pos):
    '''Convert icebox to VTR coordinate system by adding 1 for dummy blocks'''
    assert type(pos) is graph.Position
    # evidently doens't have operator defined...
    # return pos + graph.Position(1, 1)
    return graph.Position(pos.x + 1, pos.y + 1)


def PN1(pos):
    '''Convert VTR to icebox coordinate system by subtracting 1 for dummy blocks'''
    assert type(pos) is graph.Position
    return graph.Position(pos.x - 1, pos.y - 1)


TilePos = graph.Position


class Posinfo(tuple):
    def __new__(cls, *args, **kw):
        return super(Posinfo, cls).__new__(cls, args, **kw)

    def __init__(self, start, idx, end, delta):
        pass


'''
Name of a segment group type
Basically represents a wire running along one or more tiles

GlobalName(type, position, attributes)
type=local
    attributes: (g, i)
type=glb2local
    attributes: i

'''


# FIXME: bind channel type to Channel object
class GlobalName(tuple):
    def __new__(cls, *args, **kw):
        return super(GlobalName, cls).__new__(cls, args, **kw)

    def __init__(self, *args, **kw):
        pass

    def __str__(self):
        # FIXME: don't worry about specifics for now
        return str(tuple(self))
        t = self[0]

        # TODO: confirm these are good names
        if t == 'global':
            which = self[2]
            return '%s_%s' % (t, which)
        elif t == 'glb2local':
            i = self[2]
            pos = self[1]
            return '%s%s/%s_%s' % (t, pos.x, pos.y,
                                   NetNames.localname_track_glb2local(pos, i))
        elif t == 'channel':
            # ('channel', 'span12', 'horizontal', (P(x=0, y=1), 0, P(x=7, y=1), 7))
            t, subtype, direction, posstuff = self
            start, dy, end, dx = posstuff
            return '%s_%s_%s_(%s_%s_%s_%s)' % (t, subtype, direction, start,
                                               dy, end, dx)
        elif t == 'local':
            pos = self[1]
            g, i = self[2]
            return '%s%s/%s_%s' % (t, pos.x, pos.y,
                                   NetNames.localname_track_local(pos, g, i))
        # GlobalName("pin", TilePos(x, y), pin)
        else:
            return '%s_fixme_%s' % (t, self[1:])

    def type(self):
        return self[0]

    def pin(self):
        t, pos, localname = self
        assert t == 'pin'
        assert type(pos) is TilePos
        assert type(localname) is str
        return pos, localname

    @staticmethod
    def make_pin(pos, localname):
        assert type(pos) is TilePos
        assert type(localname) is str
        return GlobalName('pin', pos, localname)

    @staticmethod
    def make_local(pos, g, i):
        assert type(pos) is TilePos
        assert type(g) is int, (g, type(g))
        assert type(i) is int, (i, type(i))
        return GlobalName('local', pos, (g, i))

    @staticmethod
    def make_glb2local(pos, i):
        assert type(pos) is TilePos
        assert type(i) is int, (i, type(i))
        return GlobalName('glb2local', pos, i)

    @staticmethod
    def check_posinfo(posinfo):
        assert type(posinfo) is Posinfo
        (pos1, field2, pos2, field4) = posinfo
        assert type(pos1) is TilePos
        assert type(pos2) is TilePos
        assert type(field2) is int
        assert type(field4) is int

    @staticmethod
    def make_channel_stub(localname, chanspan, posinfo):
        # ('channel', 'stub', 'neigh_op_bnl_0', 'span4', (P(x=1, y=1), 0, P(x=1, y=1), 1))
        assert chanspan in ("span4", )
        GlobalName.check_posinfo(posinfo)
        return GlobalName('channel', 'stub', localname, chanspan, posinfo)

    @staticmethod
    def make_span(chanspan, chandir, posinfo):
        # ('channel', 'span12', 'horizontal', (P(x=0, y=1), 0, P(x=7, y=1), 7))
        assert chanspan in ('span4', 'span12')
        GlobalName.check_posinfo(posinfo)
        assert chandir in ('vertical', 'horizontal', 'corner'), chandir
        return GlobalName('channel', chanspan, chandir, posinfo)

    @staticmethod
    def make_global(ntiles_str, globalname):
        assert type(ntiles_str) is str
        assert type(globalname) is str
        return GlobalName('global', ntiles_str, globalname)

    # FIXME: this looks wrong
    # there should be some position info here
    # but these are low priority right now
    @staticmethod
    def make_direct(flavor):
        assert flavor in ('neighbour', 'carrychain')
        return GlobalName('direct', flavor)


# Tracks -----------------------------------------------------------------


def tiles(ic):
    for x in range(ic.max_x + 1):
        for y in range(ic.max_y + 1):
            yield TilePos(x, y)


def get_corner_tiles(ic):
    corner_tiles = set()
    for x in (0, ic.max_x):
        for y in (0, ic.max_y):
            corner_tiles.add((x, y))
    return corner_tiles


# Everything in this class is in IC coordinates
class NetNames:
    def __init__(self, ic):
        self.ic = ic
        self.verbose = False
        # IC coordinate space
        self.all_tiles = list(tiles(self.ic))
        # IC coordinate space
        self.corner_tiles = get_corner_tiles(self.ic)
        self.index_names()
        # (Position, local name) to node ID
        # For channels multiple keys may map to one node ID
        # NOTE: these are in IC coordinate space
        self.poslname2nodeid = {}

    def index_names(self):
        # in IC coordinates
        self.globalname2netnames = {}
        self.netname2globalname = {}

        all_group_segments = self.ic.group_segments(
            self.all_tiles, connect_gb=False)
        for group in sorted(all_group_segments):
            fgroup = NetNames.filter_localnames(self.ic, group)
            if not fgroup:
                continue

            if self.verbose:
                print()
            gname = NetNames._calculate_globalname_net(self.ic, tuple(fgroup))
            if not gname:
                if self.verbose:
                    print('Could not calculate global name for', group)
                continue

            if gname[0] == "pin":
                #alias_type = "pin"
                # FIXME: revisit later
                continue
                assert gname in self.globalname2netnames, gname
            else:
                #alias_type = "net"
                if gname not in self.globalname2netnames and self.verbose:
                    print("Adding net {}".format(gname))

            #print(x, y, gname, group)
            for x, y, netname in fgroup:
                self.add_globalname2localname(gname, TilePos(x, y), netname)

    def index_pin_node_ids(self, g, ice_node_id_file=None):
        '''Build a list of icebox global pin names to Graph node IDs'''
        name_rr2local = {}

        # FIXME: quick attempt, not thoroughly checked
        # BLK_TL-PLB
        # http://www.clifford.at/icestorm/logic_tile.html
        # http://www.clifford.at/icestorm/bitdocs-1k/tile_1_1.html
        name_rr2local['BLK_TL-PLB.lutff_global_s_r[0]'] = 'lutff_global/s_r'
        name_rr2local['BLK_TL-PLB.lutff_global_clk[0]'] = 'lutff_global/clk'
        name_rr2local['BLK_TL-PLB.lutff_global_cen[0]'] = 'lutff_global/cen'
        # FIXME: these two are wrong I think, but don't worry about carry for now
        name_rr2local['BLK_TL-PLB.FCIN[0]'] = 'lutff_0/cin'
        name_rr2local['BLK_TL-PLB.FCOUT[0]'] = 'lutff_7/cout'
        #name_rr2local['BLK_TL-PLB.lutff_0_cin[0]'] = 'lutff_0/cin'
        #name_rr2local['BLK_TL-PLB.lutff_7_cout[0]'] = 'lutff_7/cout'
        for luti in range(8):
            name_rr2local['BLK_TL-PLB.lutff_{}_out[0]'.format(
                luti)] = 'lutff_{}/out'.format(luti)
            name_rr2local['BLK_TL-PLB.lutff_{}_cout[0]'.format(
                luti)] = 'lutff_{}/cout'.format(luti)
            name_rr2local['BLK_TL-PLB.lutff_{}_fcout[0]'.format(
                luti)] = 'lutff_{}/fcout'.format(luti)
            for lut_input in range(4):
                name_rr2local['BLK_TL-PLB.lutff_{}_in[{}]'.format(
                    luti, lut_input)] = 'lutff_{}/in_{}'.format(
                        luti, lut_input)

        # BLK_TL-PIO
        # http://www.clifford.at/icestorm/io_tile.html
        for orientation in 'LRBTA':
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
                name_rr2local['BLK_TL-PIO_{}.[{}]io_D_IN[0]'.format(
                    orientation, blocki)] = 'io_{}/D_IN_0'.format(blocki)
                name_rr2local['BLK_TL-PIO_{}.[{}]io_D_IN[1]'.format(
                    orientation, blocki)] = 'io_{}/D_IN_1'.format(blocki)
                name_rr2local['BLK_TL-PIO_{}.[{}]io_D_OUT[0]'.format(
                    orientation, blocki)] = 'io_{}/D_OUT_0'.format(blocki)
                name_rr2local['BLK_TL-PIO_{}.[{}]io_D_OUT[1]'.format(
                    orientation, blocki)] = 'io_{}/D_OUT_1'.format(blocki)
                name_rr2local['BLK_TL-PIO_{}.[{}]io_OUT_ENB[0]'.format(
                    orientation, blocki)] = 'io_{}/OUT_ENB'.format(blocki)

        for block in g.block_grid:
            for pin in block.pins:
                node = g.routing.localnames[(block.position, pin.name)]

                rr_name = pin.xmlname
                try:
                    localname = name_rr2local[rr_name]
                except KeyError:
                    print("WARNING: rr_name {} doesn't have a translation".format(
                            rr_name))
                    continue
                node_id = int(node.get('id'))
                self.poslname2nodeid[(PN1(block.position),
                                      localname)] = node_id
                if ice_node_id_file:
                    ice_node_id_file.annotate_node(node, [(block.position, localname)])

    def index_track(self, trackid, nids):
        for pos, localname in nids:
            self.poslname2nodeid[pos, localname] = trackid

    def add_globalname2localname(self, globalname, pos, localname):
        assert isinstance(
            globalname,
            GlobalName), "{!r} must be a GlobalName".format(globalname)
        assert isinstance(pos, TilePos), "{!r} must be a TilePos".format(pos)

        nid = (pos, localname)

        if nid in self.netname2globalname:
            assert globalname == self.netname2globalname[nid], (
                "While adding global name {} found existing global name {} for {}".
                format(globalname, self.netname2globalname[nid], nid))
            return

        self.netname2globalname[nid] = globalname
        if globalname not in self.globalname2netnames:
            self.globalname2netnames[globalname] = set()

        if nid not in self.globalname2netnames[globalname]:
            self.globalname2netnames[globalname].add(nid)
            if self.verbose:
                print("Adding alias for {} is tile {}, {}".format(
                    globalname, pos, localname))
        else:
            if self.verbose:
                print("Existing alias for {} is tile {}, {}".format(
                    globalname, pos, localname))

    def localname2globalname(self, pos, localname, default=None):
        """Convert from a local name to a globally unique name."""
        assert isinstance(pos, TilePos), "{!r} must be a TilePos".format(pos)
        nid = (pos, localname)
        return self.netname2globalname.get(nid, default)

    @staticmethod
    def filter_name(localname):
        if localname.endswith('cout') or localname.endswith('lout'):
            return True

        if localname.startswith('padout_') or localname.startswith('padin_'):
            return True

        if localname in ("fabout", "carry_in", "carry_in_mux"):
            return True
        return False

    @staticmethod
    def filter_localnames(ic, group):
        fgroup = []
        for x, y, name in group:
            if not ic.tile_has_entry(x, y, name):
                # print("Skipping {} on {},{}".format(name, x,y))
                continue

            if NetNames.filter_name(name):
                continue

            fgroup.append((x, y, name))
        return fgroup

    @staticmethod
    def localname_track_local(pos, g, i):
        return 'local_g{}_{}'.format(g, i)

    #def iceboxname_track_local(pos, g, i):
    #    return 'local_g{}_{}'.format(g, i)

    @staticmethod
    def localname_track_glb2local(pos, i):
        return 'glb2local_{}'.format(i)

    #def iceboxname_track_glb2local(pos, i):
    #    return 'gbl2local_{}'.format(i)

    @staticmethod
    def _calculate_globalname_net(ic, segments):
        '''
        Take a net segments list from ic.group_segments() and decode what it is
        icebox segment: a bit of a net on a specific tile
        Each icebox segment is a (tile x, tile y, local net name) tuple
        icebox groups are segments aggregated into larger nets
        It may be either a VPR pin or a VPR track

        This function does not have any side effects
        and neither ic nor segments is modified

        Return value:
        None if its something we don't care about
        Otherwise a tuple with the first element as the type
        Possible values:
        ('pin', Position, localname)
        channel:
            prefix: guess_wire_type()
            suffix:
        '''

        def get_tiles(segments):
            '''Index tiles and return a pin GlobalName if this is a pin'''

            # These lists are not necessarily equal if its a neighborhood connection
            # List of positions
            tiles = set()
            # List of localnames
            # when len(names) != len(tiles) the last position is garaunteed to be for the last name
            names = set()

            assert segments

            def check_pin(x, y, name):
                if name.startswith('lutff_'):  # Actually a pin
                    lut_idx, pin = name.split('/')

                    if lut_idx == "lutff_global":
                        return GlobalName.make_pin(TilePos(x, y), pin)
                    else:
                        if '_' in pin:
                            pin, pin_idx = pin.split('_')
                            return GlobalName.make_pin(
                                TilePos(x, y), "lut[{}].{}[{}]".format(
                                    lut_idx[len("lutff_"):], pin,
                                    pin_idx).lower())
                        else:
                            return GlobalName.make_pin(
                                TilePos(x, y), "lut[{}].{}".format(
                                    lut_idx[len("lutff_"):], pin).lower())

                elif name.startswith('io_'):  # Actually a pin
                    io_idx, pin = name.split('/')

                    if io_idx == "io_global":
                        return GlobalName.make_pin(TilePos(x, y), pin)
                    else:
                        return GlobalName.make_pin(
                            TilePos(x, y), "io[{}].{}".format(
                                io_idx[len("io_"):], pin).lower())

                elif name.startswith('ram/'):  # Actually a pin
                    name = name[len('ram/'):]
                    if '_' in name:
                        pin, pin_idx = name.split('_')
                        return GlobalName.make_pin(
                            TilePos(x, y), "{}[{}]".format(pin,
                                                           pin_idx).lower())
                    else:
                        return GlobalName.make_pin(TilePos(x, y), name.lower())
                return None

            for x, y, name in segments:
                pin_gn = check_pin(x, y, name)
                if pin_gn:
                    return pin_gn, None
                '''
                ???
                "Local name in logic tile (A,B) for Logic Span 4 wires from tile to the right - (A+1,B)."
                LA/B_sp4_r_v_bB2
                LA/B_sp4_r_v_tT1_tB1
                A neighbour connection

                I think what this is doing is if its a neighborhood wire, add the last location only
                ie create a 0 length channel to the common tile rather than spreading out over (up to) 9 tiles
                This I'm guessing will generate 9 names and 1 tile
                '''
                if not name.startswith('sp4_r_v_'):
                    tiles.add(TilePos(x, y))
                names.add(name)

            # see note above
            if not tiles:
                tiles.add(TilePos(x, y))

            assert names, "No names for {}".format(names)
            # Usually these are equal but not always (neighbours in particular)
            # If they aren't equal, how can you use these to form globalnames?
            return None, (tiles, names)

        def guess_wire_type(names):
            wire_type = []
            for n in names:
                if n.startswith('span4_horz_'):
                    if wire_type and 'horizontal' not in wire_type:
                        wire_type = ['channel', 'span4', 'corner']
                        break
                    else:
                        wire_type = ['channel', 'span4', 'horizontal']
                if n.startswith('span4_vert_'):
                    if wire_type and 'vertical' not in wire_type:
                        wire_type = ['channel', 'span4', 'corner']
                        break
                    else:
                        wire_type = ['channel', 'span4', 'vertical']
                if n.startswith('sp12_h_'):
                    wire_type = ['channel', 'span12', 'horizontal']
                    break
                if n.startswith('sp12_v_'):
                    wire_type = ['channel', 'span12', 'vertical']
                    break
                if n.startswith('sp4_h_'):
                    wire_type = ['channel', 'span4', 'horizontal']
                    break
                if n.startswith('sp4_v_'):
                    wire_type = ['channel', 'span4', 'vertical']
                    break
                if n.startswith('neigh_op'):
                    #wire_type = ['direct', 'neighbour']
                    break
                if n == 'carry_in':
                    wire_type = [
                        'direct',
                        'carrychain',
                    ]
                    break
            return wire_type

        def make_local(name, pos):
            m = re.match("local_g([0-3])_([0-7])", name)
            assert m, "{!r} didn't match local regex".format(name)
            g = int(m.group(1))
            i = int(m.group(2))

            assert name == NetNames.localname_track_local(pos, g, i)
            # return NetNames.globalname_track_local(pos, g, i)
            return GlobalName.make_local(pos, g, i)

        def make_glb2local(name, pos):
            m = re.match("glb2local_([0-3])", name)
            assert m, "{!r} didn't match glb2local regex".format(name)
            i = int(m.group(1))

            assert name == NetNames.localname_track_glb2local(
                pos, i), "{!r} != {!r}".format(
                    name, NetNames.localname_track_glb2local(pos, i))
            # return NetNames.globalname_track_glb2local(pos, i)
            return GlobalName.make_glb2local(pos, i)

        def make_channel_stub(name, pos):
            '''sp4_r_v_ + neigh_op_'''
            # TODO: put some examples of what we are trying to parse
            m = re.search("_([0-9]+)$", name)
            # TODO: what are the numbers here?
            return GlobalName.make_channel_stub(name, "span4",
                                                Posinfo(
                                                    pos, int(m.group(1)), pos,
                                                    1))

        def make_1_tile_channel(name, pos):
            '''Routing that we want to fit into a 0 length channel / occupies one tile'''
            if name.startswith('local_'):
                return make_local(name, pos)
            elif name.startswith('glb2local_'):
                return make_glb2local(name, pos)
            # Special case when no logic to the right....
            elif name.startswith('sp4_r_v_') or name.startswith('neigh_op_'):
                return make_channel_stub(name, pos)

            print("Unknown only local net {}".format(name))
            return None

        def get_sedo(wire_type):
            '''return start, end, delta, offset'''
            xs = set()
            ys = set()
            '''
            Corner type
            ex: tl => top left
            '''
            es = set()
            for x, y in tiles:
                xs.add(x)
                ys.add(y)
                es.add(ic.tile_pos(x, y))

            if 'horizontal' in wire_type:
                # Check for constant y value
                assert len(ys) == 1, repr((ys, names))
                y = ys.pop()

                start = TilePos(min(xs), y)
                end = TilePos(max(xs), y)

                offset = min(xs)
                delta = end[0] - start[0]

            elif 'vertical' in wire_type:
                # Check for constant x value
                assert len(xs) in (1, 2), repr((xs, names))
                x = xs.pop()

                start = TilePos(x, min(ys))
                end = TilePos(x, max(ys))

                offset = min(ys)
                delta = end[1] - start[1]

            elif 'corner' in wire_type:
                assert len(es) == 2, (es, segments)

                if 't' in es:
                    if 'l' in es:
                        # +--
                        # |
                        assert min(xs) == 0
                        #assert (0,max(ys)) in tiles, tiles
                        start = TilePos(0, min(ys))
                        end = TilePos(max(xs), max(ys))
                        delta = max(ys) - min(ys) + min(xs)
                    elif 'r' in es:
                        # --+
                        #   |
                        #assert (max(xs), max(ys)) in tiles, tiles
                        start = TilePos(min(xs), max(ys))
                        end = TilePos(max(xs), min(ys))
                        delta = max(xs) - min(xs) + max(ys) - min(ys)
                    else:
                        assert False
                elif 'b' in es:
                    if 'l' in es:
                        # |
                        # +--
                        assert min(xs) == 0
                        assert min(ys) == 0
                        #assert (0,0) in tiles, tiles
                        start = TilePos(0, max(ys))
                        end = TilePos(max(xs), 0)
                        delta = max(xs) + max(ys) - min(ys)
                    elif 'r' in es:
                        #   |
                        # --+
                        assert min(ys) == 0
                        #assert (max(xs), 0) in tiles, tiles
                        start = TilePos(min(xs), 0)
                        end = TilePos(max(xs), max(ys))
                        delta = max(xs) - min(xs) + max(ys)
                    else:
                        assert False
                else:
                    assert False, 'Unknown span corner wire {}'.format(
                        (es, segments))

                offset = 0  # FIXME: ????

            elif 'neighbour' in wire_type:
                x = list(sorted(xs))[int(len(xs) / 2) + 1]
                y = list(sorted(ys))[int(len(ys) / 2) + 1]
                return None

            elif 'carrychain' in wire_type:
                assert len(xs) == 1
                assert len(ys) == 2
                start = TilePos(min(xs), min(ys))
                end = TilePos(min(xs), max(ys))
                delta = 1

                return None
            else:
                assert False, 'Unknown span wire {}'.format((wire_type,
                                                             segments))
            return start, end, delta, offset

        def make_span(wire_type, tiles):
            chanstr, chantype, chandir = wire_type
            assert chanstr == 'channel'
            assert chantype in ('span4', 'span12'), chantype
            assert chandir in ('vertical', 'horizontal', 'corner'), chandir

            res = get_sedo(wire_type)
            if res is None:
                return None
            start, end, delta, offset = res
            assert start in tiles
            assert end in tiles

            n = None
            for x, y, name in segments:
                if x == start[0] and y == start[1]:
                    n = int(name.split("_")[-1])
                    break
            assert n is not None

            if "span4" in wire_type:
                max_channels = SPAN4_MAX_TRACKS
                max_span = 4
            elif "span12" in wire_type:
                max_channels = SPAN12_MAX_TRACKS
                max_span = 12

            finish_per_offset = int(max_channels / max_span)
            filled = (max_channels -
                      ((offset * finish_per_offset) % max_channels))
            idx = (filled + n) % max_channels

            #wire_type.append('{:02}-{:02}x{:02}-{:02}x{:02}'.format(delta, start[0], start[1], end[0], end[1]))
            # wire_type.append((start, idx, end, delta))
            # return GlobalName(*wire_type)
            return GlobalName.make_span(chantype, chandir,
                                        Posinfo(start, idx, end, delta))

        pin_gn, tilesnames = get_tiles(segments)
        if pin_gn:
            return pin_gn
        tiles, names = tilesnames

        # glb2local, neighborhood, and local
        if len(tiles) == 1:
            # See guarantee in get_tiles() for these always matching
            pos = tiles.pop()
            name = names.pop().lower()
            return make_1_tile_channel(name, pos)
        # Global wire, as only has one name?
        elif len(names) == 1:
            return GlobalName.make_global('{}_tiles'.format(len(tiles)),
                                          names.pop().lower())

        # Work out the type of wire
        wire_type = guess_wire_type(names)
        if not wire_type:
            return None

        if wire_type[0] == 'channel':
            return make_span(wire_type, tiles)
        elif wire_type[0] == 'direct':
            assert len(wire_type) == 2
            return GlobalName.make_direct(wire_type[1])
        else:
            assert 0, 'Unhandled wire type {}'.format(str(wire_type))


def init(device_name, read_rr_graph):
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
    if read_rr_graph:
        ref_rr_fn = read_rr_graph
    else:
        ref_rr_fn = '../../tests/build/ice40/{}/wire.rr_graph.xml'.format(
            fn_dir)

    # Load g stuff we care about
    # (basically omit rr_nodes)
    # clear_fabric reduces load time from about 11.1 => 2.8 sec on my machine
    # seems to be mostly from the edges?
    print('Loading rr_graph')
    g = graph.Graph(ref_rr_fn, clear_fabric=True)
    g.set_tooling(
        name="icebox",
        version="dev",
        comment="Generated for iCE40 {} device".format(device_name))

    print('Indexing icebox net names')
    nn = NetNames(ic)

    return ic, g, nn


def create_switches(g):
    # Create the switch types
    # ------------------------------
    print('Creating switches')
    # Buffer switch drives an output net from a possible list of input nets.
    _switch_buffer = g.routing.add_switch('buffer', buffered=1, stype='mux')
    # Routing switch connects two nets together to form a span12er wire.
    _switch_routing = g.routing.add_switch('routing', buffered=0, stype='mux')

    #_switch_delayless = g.routing.add_delayless_switch()
    _switch_delayless = g.routing.add_switch(
        '__vpr_delayless_switch__', buffered=1, configurable=0, stype='mux')


# TODO: look into adding these
def add_global_nets(g, nn):
    assert 0, 'FIXME: old code'
    '''
    def add_net_global(i):
        lname = 'glb_netwk_{}'.format(i)
        gname = GlobalName('global', '248_tiles', lname)
        add_channel(gname, 'CHANY', TilePos(0, 0), TilePos(0, 0), i, 'global')

    for i in range(0, 8):
        add_net_global(i)

    add_channel(GlobalName('global', 'fabout'), 'CHANY', TilePos(0, 0), TilePos(0, 0), 0, 'global')
    '''


def create_xy_track(g,
                    nn,
                    nids,
                    start_ic,
                    end_ic,
                    segment,
                    idx=None,
                    name=None,
                    typeh=None,
                    direction=None):
    # VPR tiles have padding vs icebox coordinate system
    track, track_node = g.create_xy_track(
        P1(start_ic),
        P1(end_ic),
        segment,
        idx=idx,
        name=name,
        typeh=typeh,
        direction=direction)
    nn.index_track(int(track_node.get('id')), nids)
    return track, track_node


class IceboxNodeIDFile:
    '''Translate between icebox names and generate node IDs'''
    def __init__(self, fn, size):
        self.f = open(fn, 'w')
        self.size = (size[0]-1, size[1]-1)

    def annotate_node(self, node, nids):
        """a.annotate_node(ET._Element, [(pos, name)])"""
        nodeid = '{}'.format(node.get('id'))
        hlcnames = set()
        for pos, localname in nids:
            print("{} ({} {})".format(nodeid, pos, localname))
            hlcname = icebox_asc2hlc.translate_netname(*pos, *self.size, localname)
            hlcnames.add(hlcname)
        assert len(hlcnames) == 1
        print(hlcnames)
        print("-"*10)
        self.f.write("{} {}\n".format(nodeid, hlcnames.pop()))


def add_span_tracks(g, nn, verbose=True, ice_node_id_file=None):
    print('Adding span tracks')

    #x_channel_offset = LOCAL_TRACKS_MAX_GROUPS * (LOCAL_TRACKS_PER_GROUP) + GBL2LOCAL_MAX_TRACKS
    #y_channel_offset = 0

    def add_track_channel(globalname, nids):
        #start, idx, end, delta = globalname[-1]
        posinfo = globalname[-1]
        assert type(posinfo) is Posinfo
        start, idx, end, delta = posinfo

        x_start = start[0]
        y_start = start[1]

        x_end = end[0]
        y_end = end[1]

        if x_start == x_end:
            chantype = channel.Track.Type.Y
            assert "vertical" in globalname or "stub" in globalname
            #idx += x_channel_offset
        elif y_start == y_end:
            chantype = channel.Track.Type.X
            assert "horizontal" in globalname or "stub" in globalname
            #idx += y_channel_offset
        else:
            # XXX: diagonol? removing non-span I guess?
            # XXX: stubs omitted here?
            return

        # should be globalname[0]?
        if 'span4' in globalname:
            segtype = 'span4'
            #return
        elif 'span12' in globalname:
            segtype = 'span12'
            #idx += SPAN4_MAX_TRACKS #+ 1
            #return
        else:
            assert False, globalname

        # add_channel(globalname, nodetype, start, end, idx, segtype)
        segment = g.segments[segtype]
        # add_channel()
        if verbose:
            print("Adding {} track {} on tile {}".format(
                segtype, globalname, start))
        return create_xy_track(
            g,
            nn,
            nids,
            start,
            end,
            segment,
            typeh=chantype,
            direction=channel.Track.Direction.BI,
            name=str(globalname))

    def add_track_local(globalname, nids):
        _gtype, pos, (_g, _i) = globalname
        segment = g.segments['local']
        return create_xy_track(
            g,
            nn,
            nids,
            pos,
            pos,
            segment,
            typeh=channel.Track.Type.Y,
            direction=channel.Track.Direction.BI,
            name=str(globalname))

    def add_track_glb2local(globalname, nids):
        _gtype, pos, _i = globalname
        segment = g.segments['glb2local']
        return create_xy_track(
            g,
            nn,
            nids,
            pos,
            pos,
            segment,
            typeh=channel.Track.Type.Y,
            direction=channel.Track.Direction.BI,
            name=str(globalname))

    def add_track_default(globalname, nids):
        gtype = globalname.type()
        print("WARNING: skipping track %s" % gtype)

    for globalname, nids in sorted(nn.globalname2netnames.items()):
        result = {
            "channel": add_track_channel,
            # NOTE: review creation before adding
            # "direct": add_track_direct,
            "glb2local": add_track_glb2local,
            "local": add_track_local,
        }.get(globalname[0], add_track_default)(globalname, nids)

        if result is not None and ice_node_id_file:
            _track, track_node = result
            ice_node_id_file.annotate_node(track_node, nids)

    print('Ran')


def add_edges(g, nn, verbose=True):
    for xic, yic in nn.all_tiles:
        pos_ic = TilePos(xic, yic)
        if pos_ic in nn.corner_tiles:
            continue
        #if pos_ic != (1, 1):
        #    continue

        if verbose:
            print()
            print(xic, yic)
            print("-" * 75)
        edgei = 0
        adds = set()
        for entry in ic.tile_db(xic, yic):
            if not ic.tile_has_entry(xic, yic, entry):
                continue
            # TODO: review
            #if entry[1] != 'buffer':
            #    continue

            verbose and print('')
            #verbose and print('ic_raw', entry)
            # [['B2[3]', 'B3[3]'], 'routing', 'sp12_h_r_0', 'sp12_h_l_23']
            switch_type = entry[1]
            if switch_type not in ("routing", "buffer"):
                verbose and print('WARNING: skip switch type %s' % switch_type)
                continue

            src_localname = entry[2]
            dst_localname = entry[3]
            verbose and print('Got name %s => %s' %
                              (src_localname, dst_localname))
            if nn.filter_name(src_localname) or nn.filter_name(dst_localname):
                verbose and print('Filter name %s => %s' %
                                  (src_localname, dst_localname))
                continue

            src_node_id = nn.poslname2nodeid.get((pos_ic, src_localname), None)
            '''
            if src_node_id != 323:
                continue
            else:
                print('Got name %s => %s' % (src_localname, dst_localname))
                verbose = 1
            '''
            dst_node_id = nn.poslname2nodeid.get((pos_ic, dst_localname), None)
            # May have duplicate entries
            if (src_node_id, dst_node_id) in adds:
                verbose and print(
                    "duplicate edge {}:{} node {} => {}:{} node {}".
                    format(
                        pos_ic,
                        src_localname,
                        src_node_id,
                        pos_ic,
                        dst_localname,
                        dst_node_id,
                    ))
                continue
            if src_node_id is None:
                verbose and print(
                    "WARNING: skipping edge as src missing *{}:{}* node {} => {}:{} node {}".
                    format(
                        pos_ic,
                        src_localname,
                        src_node_id,
                        pos_ic,
                        dst_localname,
                        dst_node_id,
                    ))
                continue
            if dst_node_id is None:
                verbose and print(
                    "WARNING: skipping edge as dst missing {}:{} node {} => *{}:{}* node {}".
                    format(
                        pos_ic,
                        src_localname,
                        src_node_id,
                        pos_ic,
                        dst_localname,
                        dst_node_id,
                    ))
                continue
            bidir = switch_type == "routing"
            verbose and print(
                "Adding {} {} edge {}  {}:{} ({}) => {}:{} ({})".format(
                    switch_type,
                    'bidir' if bidir else 'unidir',
                    len(g.routing.id2element[graph.RoutingEdge]),
                    pos_ic,
                    src_localname,
                    src_node_id,
                    pos_ic,
                    dst_localname,
                    dst_node_id,
                ))
            verbose and print('  ', entry)
            # FIXME: proper switch ID
            edgea = g.routing.create_edge_with_ids(
                src_node_id, dst_node_id, switch=g.switches[switch_type])
            edgeb = None
            if bidir:
                edgeb = g.routing.create_edge_with_ids(
                    dst_node_id, src_node_id, switch=g.switches[switch_type])

            def edgestr(edge):
                return '%s => %s' % (edge.get('src_node'),
                                     edge.get('sink_node'))

            assert edgea is not None
            verbose and print('  Add edge A %s' % edgestr(edgea))
            adds.add((src_node_id, dst_node_id))
            if bidir:
                assert edgeb is not None
                verbose and print('  Add edge B %s' % edgestr(edgeb))
                adds.add((dst_node_id, src_node_id))
            edgei += 1
            if 0 and edgei > 380:
                break


def print_nodes_edges(g):
    print("Edges: %d (index: %d)" %
          (len(g.routing._xml_parent(graph.RoutingEdge)),
           len(g.routing.id2element[graph.RoutingEdge])))
    print("Nodes: %d (index: %d)" %
          (len(g.routing._xml_parent(graph.RoutingNode)),
           len(g.routing.id2element[graph.RoutingNode])))


def my_test(ic, g):
    print('my_test()')

    def tiles(ic):
        for x in range(ic.max_x + 1):
            for y in range(ic.max_y + 1):
                yield TilePos(x, y)

    all_tiles = list(tiles(ic))
    # gives tile + local wire names at that tile
    all_group_segments = ic.group_segments(all_tiles, connect_gb=False)

    # loop over all segments and print some basic info
    if 0:
        for segment in all_group_segments:
            print('Segment')
            for (tilex, tiley, name) in segment:
                print('  %sX%sY has %s' % (tilex, tiley, name))

    if 1:
        for segments in all_group_segments:
            print('Group')
            gn = NetNames._calculate_globalname_net(ic, segments)
            print('  Segments: ', segments)
            if gn is None:
                continue
            print('  GlobalName: ', gn)

            gntype = gn[0]
            if gntype == 'local':
                print('  Routing, local')
            elif gntype == 'channel':
                print('  Routing, span')
            elif gntype == 'glb2local':
                print('  Routing, glb2local')
            elif gntype == 'pin':
                pass
            else:
                assert 0, gntype

    print('exiting')
    sys.exit(1)


def run(part, read_rr_graph, write_rr_graph, write_ice_node_id):
    global ic

    print('Importing input g', part)
    ic, g, nn = init(part, read_rr_graph)
    print("ic", ic)
    ice_node_id_file = IceboxNodeIDFile(write_ice_node_id, (ic.max_x, ic.max_y))

    # my_test(ic, g)
    print('Source g loaded')
    print_nodes_edges(g)
    grid_sz = g.block_grid.size
    print("Grid size: %s" % (grid_sz, ))
    print('Exporting pin placement')
    pin_sides = g.extract_pin_sides()

    def get_pin_sides(block, pin):
        return pin_sides[(block.position, pin.name)]

    print()

    print('Clearing nodes and edges')
    g.routing.clear()
    print('Clearing channels')
    g.channels.clear()
    print('Cleared original g')
    print_nodes_edges(g)
    print()
    #create_switches(g)
    #create_segments(g)
    print()
    print('Rebuilding block I/O nodes')
    g.create_block_pins_fabric(g.switches['__vpr_delayless_switch__'],
                               get_pin_sides)
    print_nodes_edges(g)

    print('Indexing pin node names w/ %d index entries' % len(
        nn.poslname2nodeid))
    nn.index_pin_node_ids(g, ice_node_id_file=ice_node_id_file)
    # 'lutff_4/out'
    # self.poslname2nodeid[(PN1(block.position), localname)]
    print(
        'Indexed pin node names w/ %d index entries' % len(nn.poslname2nodeid))

    #add_global_nets(g, nn)
    print()
    add_span_tracks(g, nn, ice_node_id_file=ice_node_id_file)
    print_nodes_edges(g)
    print()
    add_edges(g, nn)
    print()
    print('Padding channels')
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
    parser.add_argument('--write_ice_node_id', default=None, help='')

    args = parser.parse_args()

    if not args.write_ice_node_id:
        args.write_ice_node_id = os.path.join(
                os.path.dirname(args.write_rr_graph),
                'ice_node_id.csv')

    VERBOSE = args.verbose

    mode = args.device.lower()[2:]
    run(mode, args.read_rr_graph, args.write_rr_graph, args.write_ice_node_id)
