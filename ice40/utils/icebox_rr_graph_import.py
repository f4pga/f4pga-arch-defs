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

from os.path import commonprefix

import icebox
import lib.rr_graph.graph as graph
import lib.rr_graph.channel as channel
import os.path, re, sys

import operator
from collections import namedtuple, OrderedDict
from functools import reduce
import lxml.etree as ET


VERBOSE=True
device_name = None

LOCAL_TRACKS_PER_GROUP  = 8
LOCAL_TRACKS_MAX_GROUPS = 4

GBL2LOCAL_MAX_TRACKS    = 4

SPAN4_MAX_TRACKS  = 48
SPAN12_MAX_TRACKS = 24

GLOBAL_MAX_TRACKS = 8





def P1(pos):
    '''Convert icebox to VTR coordinate system by adding 1 for dummy blocks'''
    assert type(pos) is graph.Position
    # evidently doens't have operator defined...
    # return pos + graph.Position(1, 1)
    return graph.Position(pos.x + 1, pos.y + 1)

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
            return '%s%s/%s_%s' % (t, pos.x, pos.y, NetNames.localname_track_glb2local(pos, i))
        elif t == 'channel':
            # ('channel', 'span12', 'horizontal', (P(x=0, y=1), 0, P(x=7, y=1), 7))
            t, subtype, direction, posstuff = self
            start, dy, end, dx = posstuff
            return '%s_%s_%s_(%s_%s_%s_%s)' % (t, subtype, direction, start, dy, end, dx)
        elif t == 'local':
            pos = self[1]
            g, i = self[2]
            return '%s%s/%s_%s' % (t, pos.x, pos.y, NetNames.localname_track_local(pos, g, i))
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
        return GlobalName("local", pos, (g, i))

    @staticmethod
    def make_glb2local(pos, i):
        assert type(pos) is TilePos
        assert type(i) is int, (i, type(i))
        return GlobalName("glb2local", pos, i)

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
        assert chanspan in ("span4",)
        GlobalName.check_posinfo(posinfo)
        return GlobalName("channel", "stub", localname, chanspan, posinfo)

    @staticmethod
    def make_span(chanspan, chandir, posinfo):
        # ('channel', 'span12', 'horizontal', (P(x=0, y=1), 0, P(x=7, y=1), 7))
        assert chanspan in ("span4", "span12")
        GlobalName.check_posinfo(posinfo)
        assert chandir in ('vertical', 'horizontal', 'corner'), chandir
        return GlobalName("channel", chanspan, chandir, posinfo)

    @staticmethod
    def make_global(ntiles_str, globalname):
        assert type(ntiles_str) is str
        assert type(globalname) is str
        return GlobalName("global", ntiles_str, globalname)

    # FIXME: this looks wrong
    # there should be some position info here
    # but these are low priority right now
    @staticmethod
    def make_direct(flavor):
        assert flavor in ('neighbour', 'carrychain')
        return GlobalName('direct', flavor)

# Tracks -----------------------------------------------------------------



def tiles(ic):
    for x in range(ic.max_x+1):
        for y in range(ic.max_y+1):
            yield TilePos(x, y)

def get_corner_tiles(ic):
    corner_tiles = set()
    for x in (0, ic.max_x):
        for y in (0, ic.max_y):
            corner_tiles.add((x, y))
    return corner_tiles

class NetNames:
    def __init__(self, ic):
        self.ic = ic
        self.index_names()

    def index_names(self):
        self.globalname2netnames = {}
        self.globalname2node = {}
        self.globalname2nodeid = {}

        self.netname2globalname = {}

        self.all_tiles = list(tiles(self.ic))
        self.corner_tiles = get_corner_tiles(self.ic)

        all_group_segments = self.ic.group_segments(self.all_tiles, connect_gb=False)
        for group in sorted(all_group_segments):
            fgroup = NetNames.filter_localnames(self.ic, group)
            if not fgroup:
                continue

            print()
            gname = NetNames._calculate_globalname_net(self.ic, tuple(fgroup))
            if not gname:
                print('Could not calculate global name for', group)
                continue

            if gname[0] == "pin":
                #alias_type = "pin"
                # FIXME: revisit later
                continue
                assert gname in self.globalname2netnames, gname
            else:
                #alias_type = "net"
                if gname not in self.globalname2netnames:
                    print("Adding net {}".format(gname))

            #print(x, y, gname, group)
            for x, y, netname in fgroup:
                self.add_globalname2localname(gname, TilePos(x, y), netname)

    def add_globalname2localname(self, globalname, pos, localname):
        assert isinstance(globalname, GlobalName), "{!r} must be a GlobalName".format(globalname)
        assert isinstance(pos, TilePos), "{!r} must be a TilePos".format(pos)

        nid = (pos, localname)

        if nid in self.netname2globalname:
            assert globalname == self.netname2globalname[nid], (
                "While adding global name {} found existing global name {} for {}".format(
                    globalname, self.netname2globalname[nid], nid))
            return

        self.netname2globalname[nid] = globalname
        if globalname not in self.globalname2netnames:
            self.globalname2netnames[globalname] = set()

        if nid not in self.globalname2netnames[globalname]:
            self.globalname2netnames[globalname].add(nid)
            print("Adding alias for {} is tile {}, {}".format(globalname, pos, localname))
        else:
            print("Existing alias for {} is tile {}, {}".format(globalname, pos, localname))

    @staticmethod
    def filter_name(localname):
        if localname.endswith('cout') or localname.endswith('lout'):
            return True

        if localname.startswith('padout_') or localname.startswith('padin_'):
            return True

        if localname in ("fabout","carry_in","carry_in_mux"):
            return True
        return False

    @staticmethod
    def filter_localnames(ic, group):
        fgroup = []
        for x,y,name in group:
            if not ic.tile_has_entry(x, y, name):
                print("Skipping {} on {},{}".format(name, x,y))
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
                if name.startswith('lutff_'): # Actually a pin
                    lut_idx, pin = name.split('/')

                    if lut_idx == "lutff_global":
                        return GlobalName.make_pin(TilePos(x, y), pin)
                    else:
                        if '_' in pin:
                            pin, pin_idx = pin.split('_')
                            return GlobalName.make_pin(TilePos(x, y), "lut[{}].{}[{}]".format(lut_idx[len("lutff_"):], pin, pin_idx).lower())
                        else:
                            return GlobalName.make_pin(TilePos(x, y), "lut[{}].{}".format(lut_idx[len("lutff_"):], pin).lower())

                elif name.startswith('io_'): # Actually a pin
                    io_idx, pin = name.split('/')

                    if io_idx == "io_global":
                        return GlobalName.make_pin(TilePos(x, y), pin)
                    else:
                        return GlobalName.make_pin(TilePos(x, y), "io[{}].{}".format(io_idx[len("io_"):], pin).lower())

                elif name.startswith('ram/'): # Actually a pin
                    name = name[len('ram/'):]
                    if '_' in name:
                        pin, pin_idx = name.split('_')
                        return GlobalName.make_pin(TilePos(x, y), "{}[{}]".format(pin, pin_idx).lower())
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
                    wire_type = ['channel', 'span4','horizontal']
                    break
                if n.startswith('sp4_v_'):
                    wire_type = ['channel', 'span4', 'vertical']
                    break
                if n.startswith('neigh_op'):
                    #wire_type = ['direct', 'neighbour']
                    break
                if n == 'carry_in':
                    wire_type = ['direct', 'carrychain',]
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

            assert name == NetNames.localname_track_glb2local(pos, i), "{!r} != {!r}".format(
                name, NetNames.localname_track_glb2local(pos, i))
            # return NetNames.globalname_track_glb2local(pos, i)
            return GlobalName.make_glb2local(pos, i)

        def make_channel_stub(name, pos):
            '''sp4_r_v_ + neigh_op_'''
            # TODO: put some examples of what we are trying to parse
            m = re.search("_([0-9]+)$", name)
            # TODO: what are the numbers here?
            return GlobalName.make_channel_stub(name, "span4", Posinfo(pos, int(m.group(1)), pos, 1))

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
                end   = TilePos(max(xs), y)

                offset = min(xs)
                delta = end[0] - start[0]

            elif 'vertical' in wire_type:
                # Check for constant x value
                assert len(xs) in (1, 2), repr((xs, names))
                x = xs.pop()

                start = TilePos(x, min(ys))
                end   = TilePos(x, max(ys))

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
                        start = TilePos(0,min(ys))
                        end   = TilePos(max(xs), max(ys))
                        delta = max(ys)-min(ys)+min(xs)
                    elif 'r' in es:
                        # --+
                        #   |
                        #assert (max(xs), max(ys)) in tiles, tiles
                        start = TilePos(min(xs), max(ys))
                        end   = TilePos(max(xs), min(ys))
                        delta = max(xs)-min(xs) + max(ys)-min(ys)
                    else:
                        assert False
                elif 'b' in es:
                    if 'l' in es:
                        # |
                        # +--
                        assert min(xs) == 0
                        assert min(ys) == 0
                        #assert (0,0) in tiles, tiles
                        start = TilePos(0,max(ys))
                        end   = TilePos(max(xs), 0)
                        delta = max(xs) + max(ys)-min(ys)
                    elif 'r' in es:
                        #   |
                        # --+
                        assert min(ys) == 0
                        #assert (max(xs), 0) in tiles, tiles
                        start = TilePos(min(xs), 0)
                        end   = TilePos(max(xs), max(ys))
                        delta = max(xs)-min(xs) + max(ys)
                    else:
                        assert False
                else:
                    assert False, 'Unknown span corner wire {}'.format((es, segments))

                offset = 0 # FIXME: ????

            elif 'neighbour' in wire_type:
                x = list(sorted(xs))[int(len(xs)/2)+1]
                y = list(sorted(ys))[int(len(ys)/2)+1]
                return None

            elif 'carrychain' in wire_type:
                assert len(xs) == 1
                assert len(ys) == 2
                start = TilePos(min(xs), min(ys))
                end   = TilePos(min(xs), max(ys))
                delta = 1

                return None
            else:
                assert False, 'Unknown span wire {}'.format((wire_type, segments))
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
            filled = (max_channels - ((offset * finish_per_offset) % max_channels))
            idx = (filled + n) % max_channels

            #wire_type.append('{:02}-{:02}x{:02}-{:02}x{:02}'.format(delta, start[0], start[1], end[0], end[1]))
            # wire_type.append((start, idx, end, delta))
            # return GlobalName(*wire_type)
            return GlobalName.make_span(chantype, chandir, Posinfo(start, idx, end, delta))

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
            return GlobalName.make_global('{}_tiles'.format(len(tiles)), names.pop().lower())

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







'''
https://docs.google.com/document/d/1kTehDgse8GA2af5HoQ9Ntr41uNL_NJ43CjA32DofK8E/edit#heading=h.b5gijh3mhpx9
Local wires are given global names by giving a prefix of WA/B_ where;
    W == Letter code for tile type
        I == IO tile
        L == Logic Tile
        R == Block RAM Tile
    A == X tile coordinate
    B == Y tile coordinate
'''
'''
def local_track_gname(block, g, i):
    assert type(block) is graph.Block
    pos = block.position
    assert type(g) is int
    assert type(i) is int

    tile_type_short = {
        'BLK_BB-VPR_PAD':   'I',
        'BLK_TL-PLB':       'L',
        'FIXME_BRAM':       'R',
        }[block.block_type.name]
    return '{}{}/{}_local_g{}_{}'.format(tile_type_short, pos.x, pos.y, g, i)

def glb2local_track_gname(block, i):
    assert type(block) is graph.Block
    pos = block.position

    tile_type_short = {
        'BLK_BB-VPR_PAD':   'I',
        'BLK_TL-PLB':       'L',
        'FIXME_BRAM':       'R',
        }[block.block_type.name]
    return '{}{}/{}_glb2local_{}'.format(tile_type_short, pos.x, pos.y, i)
'''

'''
def setup_empty_t4(self):
    self.clear()
    self.device = "T4"
    self.max_x = 3
    self.max_y = 3

    for x in range(1, self.max_x):
        for y in range(1, self.max_y):
            self.logic_tiles[(x, y)] = ["0" * 54 for i in range(16)]

    for x in range(1, self.max_x):
        self.io_tiles[(x, 0)] = ["0" * 18 for i in range(16)]
        self.io_tiles[(x, self.max_y)] = ["0" * 18 for i in range(16)]

    for y in range(1, self.max_y):
        self.io_tiles[(0, y)] = ["0" * 18 for i in range(16)]
        self.io_tiles[(self.max_x, y)] = ["0" * 18 for i in range(16)]
'''

def init(device_name):
    ic = icebox.iceconfig()
    {
        't4':  ic.setup_empty_t4,
        '8k':  ic.setup_empty_8k,
        '5k':  ic.setup_empty_5k,
        '1k':  ic.setup_empty_1k,
        '384': ic.setup_empty_384,
    }[device_name]()
    fn_dir =     {
        't4':  'test4',
        '8k':  'HX8K',
        '5k':  'HX5K',
        '1k':  'HX1K',
        '384': 'LP384',
    }[device_name]
    ref_rr_fn = '../../tests/build/ice40/{}/wire.rr_graph.xml'.format(fn_dir)

    # Load g stuff we care about
    # (basically omit rr_nodes)
    # clear_fabric reduces load time from about 11.1 => 2.8 sec on my machine
    # seems to be mostly from the edges?
    print('Loading rr_graph')
    g = graph.Graph(ref_rr_fn, clear_fabric=True)
    g.set_tooling(name="icebox", version="dev", comment="Generated for iCE40 {} device".format(device_name))

    print('Indexing icebox net names')
    nn = NetNames(ic)

    return ic, g, nn

def create_switches(g):
    # Create the switch types
    # ------------------------------
    print('Creating switches')
    #_switch_delayless = g.ids.add_delayless_switch()
    _switch_delayless = g.ids.add_switch('__vpr_delayless_switch__', buffered=1, configurable=0, stype='mux')

    # Buffer switch drives an output net from a possible list of input nets.
    _switch_buffer = g.ids.add_switch('buffer', buffered=1, stype='mux')
    # Routing switch connects two nets together to form a span12er wire.
    _switch_routing = g.ids.add_switch('routing', buffered=0, stype='mux')

def create_segments(g):
    print('Creating segments')
    segment_names = (
            'global',
            'span12',
            'span4',
            'gbl2local',
            'local',
            'direct',
            )
    for segment_name in segment_names:
        _segment = g.channels.create_segment(segment_name)

def add_local_tracks(g, nn):
    print('Adding local tracks')

    def add_track_local(graph, nn, block, group, i, segment):
        pos = block.position
        lname = NetNames.localname_track_local(pos, group, i)
        # gname = NetNames.globalname_track_local(pos, group, i)
        gname = GlobalName.make_local(pos, group, i)

        print("Adding local track {} on tile {}".format(gname, pos))
        graph.create_xy_track(block.position, block.position, segment,
               typeh=channel.Track.Type.Y, direction=channel.Track.Direction.BI,
               id_override=gname)
        nn.add_globalname2localname(gname, pos, lname)


    def add_track_gbl2local(graph, nn, block, i, segment):
        pos = block.position
        lname = NetNames.localname_track_glb2local(pos, i)
        # gname = NetNames.globalname_track_glb2local(pos, i)
        gname = GlobalName.make_glb2local(pos, i)

        print("Adding glb2local {} track {} on tile {}".format(i, gname, pos))
        graph.create_xy_track(block.position, block.position, segment,
               typeh=channel.Track.Type.Y, direction=channel.Track.Direction.BI,
               id_override=gname)
        nn.add_globalname2localname(gname, pos, lname)

    # TODO: review segments based on timing requirements
    local_segment = g.channels.segment_s2seg['local']
    gbl2local_segment = g.channels.segment_s2seg['gbl2local']

    for block in g.block_grid.blocks_for():
        if block.block_type.name == 'EMPTY':
            continue
        print('Block %s, %s' % (block, block.block_type.name))

        if block.block_type.name == 'BLK_BB-VPR_PAD':
            groups_local = (2, LOCAL_TRACKS_PER_GROUP)
            groups_glb2local = 0
        elif block.block_type.name == 'BLK_TL-PLB':
            groups_local = (LOCAL_TRACKS_MAX_GROUPS, LOCAL_TRACKS_PER_GROUP)
            groups_glb2local = GBL2LOCAL_MAX_TRACKS
        else:
            assert 0, block.block_type.name

        # Local tracks
        for groupi in range(0, groups_local[0]):
            for i in range(0, groups_local[1]):
                add_track_local(g, nn, block, groupi, i, local_segment)

        # Global to local
        if groups_glb2local:
            for _i in range(0, groups_glb2local):
                add_track_gbl2local(g, nn, block, i, gbl2local_segment)

def add_span_tracks(g, nn):
    print('Adding span tracks')

    x_channel_offset = LOCAL_TRACKS_MAX_GROUPS * (LOCAL_TRACKS_PER_GROUP) + GBL2LOCAL_MAX_TRACKS
    y_channel_offset = 0

    def add_track_span(globalname):
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
            idx += x_channel_offset
        elif y_start == y_end:
            chantype = channel.Track.Type.X
            assert "horizontal" in globalname or "stub" in globalname
            idx += y_channel_offset
        else:
            # XXX: diagonol? removing non-span I guess?
            return

        # should be globalname[0]?
        if 'span4' in globalname:
            segtype = 'span4'
        elif 'span12' in globalname:
            segtype = 'span12'
            idx += SPAN4_MAX_TRACKS #+ 1
        elif 'local' in globalname:
            segtype = 'local'
            # FIXME: weren't these already added?
            return
        else:
            assert False, globalname

        # add_channel(globalname, nodetype, start, end, idx, segtype)
        segment = g.channels.segment_s2seg[segtype]
        # add_channel()
        print("Adding {} track {} on tile {}".format(segtype, globalname, start))
        g.create_xy_track(P1(start), P1(end), segment,
               typeh=chantype, direction=channel.Track.Direction.BI,
               id_override=str(globalname))

    for globalname in sorted(nn.globalname2netnames.keys()):
        if globalname[0] != "channel":
            continue
        add_track_span(globalname)


    print('Ran')


# TODO check this
chan_width_max = LOCAL_TRACKS_MAX_GROUPS * (LOCAL_TRACKS_PER_GROUP+1) + GBL2LOCAL_MAX_TRACKS + SPAN4_MAX_TRACKS + SPAN12_MAX_TRACKS + GLOBAL_MAX_TRACKS


def print_nodes_edges(g):
    print("Edges: %d (index: %d)" % (len(g.ids._xml_edges),
                                     len(g.ids.id2node['edge'])))
    print("Nodes: %d (index: %d)" % (len(g.ids._xml_nodes),
                                     len(g.ids.id2node['node'])))

def my_test(ic, g):
    print('my_test()')

    def tiles(ic):
        for x in range(ic.max_x+1):
            for y in range(ic.max_y+1):
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

def run(part):
    global ic

    print('Importing input g')
    ic, g, nn = init(part)
    # my_test(ic, g)
    print('Source g loaded')
    print_nodes_edges(g)
    grid_sz = g.block_grid.size()
    print("Grid size: %s" % (grid_sz, ))
    print('Exporting pin placement')
    sides = g.pin_sidesf()

    print()

    print('Clearing nodes and edges')
    g.ids.clear_graph()
    print('Clearing channels')
    g.channels.clear()
    print('Cleared original g')
    print_nodes_edges(g)
    print()
    create_switches(g)
    create_segments(g)
    print()
    print('Rebuilding block I/O nodes')
    delayless_switch = g.ids.switch('__vpr_delayless_switch__')
    g.add_nodes_for_blocks(delayless_switch, sides)
    print_nodes_edges(g)
    # think these will get added as part of below
    if 0:
        print()
        add_local_tracks(g, nn)
        print_nodes_edges(g)
    print()
    add_span_tracks(g, nn)
    print_nodes_edges(g)
    print()
    print('Saving')
    open('rr_out.xml', 'w').write(
        ET.tostring(g.to_xml(), pretty_print=True).decode('ascii'))
    print()
    print('Exiting')
    sys.exit(0)

if __name__ == '__main__':
    import argparse

    parser = argparse.ArgumentParser()
    parser.add_argument('--dev-t4', '-4', action='store_true', help='create chipdb for test4 device')
    parser.add_argument('--dev-384', '-3', action='store_true', help='create chipdb for 384 device')
    parser.add_argument('--dev-1k', '-1', action='store_true', help='create chipdb for 1k device')
    parser.add_argument('--dev-5k', '-5', action='store_true', help='create chipdb for 5k device')
    parser.add_argument('--dev-8k', '-8', action='store_true', help='create chipdb for 8k device')
    parser.add_argument('--verbose', '-v', action='store_true', help='verbose output')
    args = parser.parse_args()

    VERBOSE = args.verbose

    if args.dev_t4:
        mode = 't4'
    elif args.dev_8k:
        mode = '8k'
    elif args.dev_5k:
        mode = '5k'
    elif args.dev_1k:
        mode = '1k'
    elif args.dev_384:
        mode = '384'
    else:
        assert 0, "Must specifiy device"
    run(mode)



# ************************************************************************************
# FUTURE USE / UNUSED CODE
# ************************************************************************************




# Edges -----------------------------------------------------------------

'''
edges = g.create_edges()
def add_edge(src_globalname, dst_globalname, bidir=False):
    if bidir:
        add_edge(src_globalname, dst_globalname)
        add_edge(dst_globalname, src_globalname)
        return

    assert isinstance(src_globalname, GlobalName), "src {!r} should be a GlobalName".format(src_globalname)
    assert isinstance(dst_globalname, GlobalName), "dst {!r} should be a GlobalName".format(dst_globalname)

    src_node_id = globalname2nodeid[src_globalname]
    dst_node_id = globalname2nodeid[dst_globalname]

    attribs = {
        'src_node': str(src_node_id),
        'sink_node': str(dst_node_id),
        'switch_id': str(0),
    }
    e = ET.SubElement(edges, 'edge', attribs)

    # Add some helpful comments
    if VERBOSE:
        e.append(ET.Comment(" {} -> {} ".format(src_globalname, dst_globalname)))
        globalname2node[src_globalname].append(ET.Comment(" this -> {} ".format(dst_globalname)))
        globalname2node[dst_globalname].append(ET.Comment(" {} -> this ".format(src_globalname)))
'''



# tim: building a mapping between icebox IDs and VPR IDs
# maybe overriding IDs in output
'''
for x in range(ic.max_x+3):
    for y in range(ic.max_y+3):
        tx = x - 1
        ty = y - 1
        block_type_id = 0

        if tx >= 0 and tx <= ic.max_x and ty >= 0 and ty <= ic.max_y and (tx,ty) not in corner_tiles:
            block_type_id = tile_types[tile_name_map[ic.tile_type(tx, ty)]]["id"]

        grid_loc = ET.SubElement(
            grid, 'grid_loc',
            {'x': str(x),
             'y': str(y),
             'block_type_id': str(block_type_id),
             'width_offset':  "0",
             'height_offset': "0",
            })
'''




# Nets
# ------------------------------

'''
def globalname_net(pos, name):
    return netname2globalname[(pos, name)]
'''



# ------------------------------

def nets():
    print()
    print("Calculating nets")
    print("="*75)



    def add_net_global(i):
        lname = 'glb_netwk_{}'.format(i)
        gname = GlobalName('global', '248_tiles', lname)
        add_channel(gname, 'CHANY', TilePos(0, 0), TilePos(0, 0), i, 'global')

    for i in range(0, 8):
        add_net_global(i)

    add_channel(GlobalName('global', 'fabout'), 'CHANY', TilePos(0, 0), TilePos(0, 0), 0, 'global')






# Generating edges
# ------------------------------
# These need to match the architecture definition given to vpr.

# rr_edges
# rr_edges tag that encloses information about all the edges between nodes.
# Each rr_edges tag contains multiple subtags:
#   <edge src_node="int" sink_node="int" switch_id="int"/>
# This subtag repeats every edge that connects nodes together in the g.
# Required Attributes:
#  * src_node, sink_node
#    The index for the source and sink node that this edge connects to.
#  * switch_id
#    The type of switch that connects the two nodes.

"""
    <rr_edges>
            <edge src_node="0" sink_node="1" switch_id="0"/>
            <edge src_node="1" sink_node="2" switch_id="0"/>
    </rr_edges>
"""

def edges():
    print()
    print("Generating edges")
    print("="*75)

    for x, y in all_tiles:
        pos = TilePos(x, y)
        if pos in corner_tiles:
            continue

        print()
        print(x, y)
        print("-"*75)
        for entry in ic.tile_db(x, y):
            if not ic.tile_has_entry(x, y, entry):
                continue

            switch_type = entry[1]
            if switch_type not in ("routing", "buffer"):
                continue

            rtype = entry[1]
            src_localname = entry[2]
            dst_localname = entry[3]

            if filter_name(src_localname) or filter_name(dst_localname):
                continue

            src_globalname = localname2globalname(pos, src_localname, default='???')
            dst_globalname = localname2globalname(pos, dst_localname, default='???')

            src_nodeid = globalname2nodeid.get(src_globalname, None)
            dst_nodeid = globalname2nodeid.get(dst_globalname, None)

            if src_nodeid is None or dst_nodeid is None:
                print("Skipping {} ({}, {}) -> {} ({}, {})".format(
                    (pos, src_localname), src_globalname, src_nodeid,
                    (pos, dst_localname), dst_globalname, dst_nodeid,
                    ))
            else:
                add_edge(src_globalname, dst_globalname, switch_type == "routing")



# -----------------------------------------------------------------------
# -----------------------------------------------------------------------
# -----------------------------------------------------------------------

# 'local_'

# 'neigh_'
# ((11, 10, 'neigh_op_tnr_0'),
#  (11, 11, 'neigh_op_rgt_0'),
#  (11, 12, 'neigh_op_bnr_0'),
#
#  (12, 10, 'neigh_op_top_0'),
#  (12, 11, 'lutff_0/out'),
#  (12, 12, 'neigh_op_bot_0'),
#
#  (13, 10, 'logic_op_tnl_0'),
#  (13, 11, 'logic_op_lft_0'),
#  (13, 12, 'logic_op_bnl_0'))

# (11,12) | (12,12) | (13,12)
# --------+---------+--------
# (11,11) | (12,11) | (13,11)
# --------+---------+--------
# (11,10) | (12,10) | (13,10)

#     bnr |   bot   | l bnl
# --------+---------+--------
#     rgt |lutff/out| l lft
# --------+---------+--------
#     tnr |   top   | l tnl


# channel, multiple tiles
# 'sp12_'
# 'sp4_'

# pin, one tile
# 'lutff_'


# sp4_v
# (11, 12, 'sp4_r_v_b_10'), (12, 12, 'sp4_v_b_10'),
# (11, 11, 'sp4_r_v_b_23'), (12, 11, 'sp4_v_b_23'),
# (11, 10, 'sp4_r_v_b_34'), (12, 10, 'sp4_v_b_34'),
# (11,  9, 'sp4_r_v_b_47'), (12,  9, 'sp4_v_b_47'),
#                           (12,  8, 'sp4_v_t_47'),


# sp4_h
# ((5, 9, 'sp4_h_r_9'),
#  (6, 9, 'sp4_h_r_20'),
#  (7, 9, 'sp4_h_r_33'),
#  (8, 9, 'sp4_h_r_44'),
#  (9, 9, 'sp4_h_l_44'))


# ((0,  1, 'glb_netwk_2'),
#  (0,  2, 'glb_netwk_2'),
#  (0,  3, 'glb_netwk_2'),
#  ...

# ((0,  1, 'io_global/latch'),
#  (0,  2, 'io_global/latch'),
#  (0,  3, 'io_global/latch'),
#  (0,  4, 'io_global/latch'),
#  (0,  5, 'io_global/latch'),
#  (0,  6, 'io_global/latch'),
#  (0,  7, 'fabout'),
#  (0,  7, 'io_global/latch'),
#  (0,  8, 'io_global/latch'),
#  (0,  9, 'io_global/latch'),
#  (0, 10, 'io_global/latch'),
#  (0, 11, 'io_global/latch'),
#  (0, 12, 'io_global/latch'),
#  (0, 13, 'io_global/latch'),
#  (0, 14, 'io_global/latch'),
#  (0, 15, 'io_global/latch'),
#  (0, 16, 'io_global/latch'))

# .buffer X Y DST_NET_INDEX CONFIG_BITS_NAMES
# CONFIG_BITS_VALUES_1 SRC_NET_INDEX_1

# .routing X Y DST_NET_INDEX CONFIG_BITS_NAMES
# CONFIG_BITS_VALUES_1 SRC_NET_INDEX_1
