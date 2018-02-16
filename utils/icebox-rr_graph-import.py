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
"""

from os.path import commonprefix

import icebox
import getopt, sys, re

import operator
from collections import namedtuple, OrderedDict
from functools import reduce
import lxml.etree as ET

mode_384 = False
mode_5k = False
mode_8k = False

def usage():
    print("""
Usage: icebox_chipdb [options] [bitmap.asc]

    -3
        create chipdb for 384 device

    -5
        create chipdb for 5k device

    -8
        create chipdb for 8k device
""")
    sys.exit(0)

VERBOSE=True

try:
    opts, args = getopt.getopt(sys.argv[1:], "358")
except:
    usage()

device_name = '1k'
for o, a in opts:
    if o == "-8":
        mode_8k = True
        device_name = '8k'
    elif o == "-5":
        mode_5k = True
        device_name = '5k'
    elif o == "-3":
        mode_384 = True
        device_name = '384'
    else:
        usage()

ic = icebox.iceconfig()
if mode_8k:
    ic.setup_empty_8k()
elif mode_5k:
    ic.setup_empty_5k()
elif mode_384:
    ic.setup_empty_384()
else:
    ic.setup_empty_1k()

# -----------------------------------------------------------------------
# -----------------------------------------------------------------------
# -----------------------------------------------------------------------

_TilePos = namedtuple('T', ['x', 'y'])
class TilePos(_TilePos):
    _sentinal = []
    def __new__(cls, x, y=_sentinal, *args):
        if y is cls._sentinal:
            if len(x) == 2:
                x, y = x
            else:
                raise TypeError("TilePos takes 2 positional arguments not {}".format(x))

        assert isinstance(x, int), "x must be an int not {!r}".format(x)
        assert isinstance(y, int), "y must be an int not {!r}".format(y)
        return _TilePos.__new__(cls, x=x, y=y)


class GlobalName(tuple):
    def __new__(cls, *args, **kw):
        return super(GlobalName, cls).__new__(cls, args, **kw)

    def __init__(self, *args, **kw):
        pass


# -----------------------------------------------------------------------
# -----------------------------------------------------------------------
# -----------------------------------------------------------------------

# Root of XML
# ------------------------------
"""
<rr_graph tool_name="" tool_version="" tool_comment="">
"""
rr_graph = ET.Element(
    'rr_graph',
    dict(tool_name="icebox", tool_version="???", tool_comment="Generated for iCE40 {} device".format(device_name)),
)

# -----------------------------------------------------------------------
# -----------------------------------------------------------------------
# -----------------------------------------------------------------------

# Create the switch types
# ------------------------------
"""
    <switches>
            <switch id="0" name="my_switch" buffered="1"/>
                <timing R="100" Cin="1233-12" Cout="123e-12" Tdel="1e-9"/>
                <sizing mux_trans_size="2.32" buf_size="23.54"/>
            </switch>
    </switches>
"""
switches = ET.SubElement(rr_graph, 'switches')

# Buffer switch drives an output net from a possible list of input nets.
buffer_id = 0
switch_buffer = ET.SubElement(
    switches, 'switch',
    {'id': str(buffer_id), 'name': 'buffer', 'buffered': "1", 'type': "mux"},
)

switch_buffer_sizing = ET.SubElement(
    switch_buffer, 'sizing',
    {'mux_trans_size': "2.32", 'buf_size': "23.54"},
)

# Routing switch connects two nets together to form a span12er wire.
routing_id = 1
switch_routing = ET.SubElement(
    switches, 'switch',
    {'id': str(routing_id), 'name': 'routing', 'buffered': "0", 'type': "mux"},
)

switch_routing_sizing = ET.SubElement(
    switch_routing, 'sizing',
    {'mux_trans_size': "2.32", 'buf_size': "23.54"},
)

# -----------------------------------------------------------------------
# -----------------------------------------------------------------------
# -----------------------------------------------------------------------

# Build the segment list
# ------------------------------
"""fpga_arch
<segment name="unique_name" length="int" type="{bidir|unidir}" freq="float" Rmetal="float" Cmetal="float">
    content
</segment>

<!-- The sb/cb pattern does not actually match the iCE40 you need to manually generate rr_graph -->

<!-- Span 4 wires which go A -> A+5 (IE Span 4 tiles) -->
<segment name="span4" length="5" type="bidir" freq="float" Rmetal="float" Cmetal="float">
    <sb type="pattern">1 1 1 1 1</sb>
    <cb type="pattern">1 1 1 1</cb>
</segment>

<segment name="span12" length="13" type="bidir" freq="float" Rmetal="float" Cmetal="float">
    <sb type="pattern">1 1 1 1 1 1 1 1 1 1 1 1 1</sb>
    <cb type="pattern">1 1 1 1 1 1 1 1 1 1 1 1</cb>
</segment>

	<segments>
		<segment id="0" name="global">
			<timing R_per_meter="101" C_per_meter="2.25000004521955232483776399022e-14"/>
		</segment>
		<segment id="1" name="span12"> <!-- span12 ->
			<timing R_per_meter="101" C_per_meter="2.25000004521955232483776399022e-14"/>
		</segment>
		<segment id="2" name="span4"> <!-- span4 -->
			<timing R_per_meter="101" C_per_meter="2.25000004521955232483776399022e-14"/>
		</segment>
		<segment id="3" name="local">
			<timing R_per_meter="101" C_per_meter="2.25000004521955232483776399022e-14"/>
		</segment>
		<segment id="4" name="neighbour">
			<timing R_per_meter="101" C_per_meter="2.25000004521955232483776399022e-14"/>
		</segment>
	</segments>
"""


segment_types = OrderedDict([
    ('global',  {}),
    ('span12',    {}),
    ('span4',   {}),
    ('local',   {}),
    ('direct',  {}),
])

segments = ET.SubElement(rr_graph, 'segments')
for sid, (name, attrib) in enumerate(segment_types.items()):
    seg = ET.SubElement(segments, 'segment', {'id':str(sid), 'name':name})
    segment_types[name] = sid
    ET.SubElement(seg, 'timing', {'R_per_meter': "101", 'C_per_meter':"1.10e-14"})

# -----------------------------------------------------------------------
# -----------------------------------------------------------------------
# -----------------------------------------------------------------------

# Mapping dictionaries
globalname2netnames = {}
globalname2node = {}
globalname2nodeid = {}

netname2globalname = {}

def add_globalname2localname(globalname, pos, localname):
    global globalname2netnames

    assert isinstance(globalname, GlobalName), "{!r} must be a GlobalName".format(globalname)
    assert isinstance(pos, TilePos), "{!r} must be a TilePos".format(tilepos)

    nid = (pos, localname)

    if nid in netname2globalname:
        assert globalname == netname2globalname[nid], (
            "While adding global name {} found existing global name {} for {}".format(
                globalname, netname2globalname[nid], nid))
        return

    netname2globalname[nid] = globalname
    if globalname not in globalname2netnames:
        globalname2netnames[globalname] = set()

    if nid not in globalname2netnames[globalname]:
        globalname2netnames[globalname].add(nid)
        print("Adding alias for {} is tile {} - {}".format(globalname, pos, localname))
    else:
        print("Existing alias for {} is tile {} - {}".format(globalname, pos, localname))


def localname2globalname(pos, localname, default=None):
    """Convert from a local name to a globally unique name."""
    assert isinstance(pos, TilePos), "{!r} must be a TilePos".format(tilepos)
    nid = (pos, localname)
    return netname2globalname.get(nid, default)


# -----------------------------------------------------------------------
# -----------------------------------------------------------------------
# -----------------------------------------------------------------------

# Nodes
# --------------------------------
# The rr_nodes tag stores information about each node for the routing resource
# graph. These nodes describe each wire and each logic block pin as represented
# by nodes.

# type - Indicates whether the node is a wire or a logic block.
#  * CHANX and CHANY describe a horizontal and vertical channel.
#  * SOURCE and SINK describes where nets begin and end.
#  * OPIN represents an output pin.
#  * IPIN represents an input pin.

# direction
#  If the node represents a track (CHANX or CHANY), this field represents its
#  direction as {INC_DIR | DEC_DIR | BI_DIR}.
#  In other cases this attribute should not be specified.
# -- All channels are BI_DIR in the iCE40

"""
        <node id="1536" type="CHANX" direction="BI_DIR" capacity="1">
                <loc xlow="1" ylow="0" xhigh="4" yhigh="0" ptc="0"/>
                <timing R="404" C="1.25850014003753285507514192432e-13"/>
                <segment segment_id="0"/>
        </node>
        <node id="1658" type="CHANY" direction="BI_DIR" capacity="1">
                <loc xlow="4" ylow="1" xhigh="4" yhigh="4" ptc="0"/>
                <timing R="404" C="1.01850006293396910805881816486e-13"/>
                <segment segment_id="0"/>
        </node>

        <edge src_node="1536" sink_node="1609" switch_id="1"/>
        <edge src_node="1536" sink_node="1618" switch_id="0"/>
        <edge src_node="1536" sink_node="1623" switch_id="1"/>
        <edge src_node="1536" sink_node="1632" switch_id="0"/>
        <edge src_node="1536" sink_node="1637" switch_id="1"/>
        <edge src_node="1536" sink_node="1645" switch_id="0"/>
        <edge src_node="1536" sink_node="1650" switch_id="1"/>
        <edge src_node="1536" sink_node="1658" switch_id="0"/>

		<node id="1658" type="CHANY" direction="BI_DIR" capacity="1">
			<loc xlow="4" ylow="1" xhigh="4" yhigh="4" ptc="0"/>
			<timing R="404" C="1.01850006293396910805881816486e-13"/>
			<segment segment_id="0"/>
		</node>
		<node id="1659" type="CHANY" direction="BI_DIR" capacity="1">
			<loc xlow="4" ylow="1" xhigh="4" yhigh="1" ptc="1"/>
			<timing R="101" C="6.0040006007264917764487677232e-14"/>
			<segment segment_id="0"/>
		</node>
"""

nodes = ET.SubElement(rr_graph, 'rr_nodes')
def add_node(globalname, attribs):
    """Add node with globalname and attributes."""
    assert isinstance(globalname, GlobalName), "{!r} should be a GlobalName".format(globalname)

    # Add common attributes
    attribs['capacity'] =  str(1)

    # Work out the ID for this node and add to the mapping
    attribs['id'] = str(len(globalname2node))

    node = ET.SubElement(nodes, 'node', attribs)

    # Stash in the mappings
    assert globalname not in globalname2node
    assert globalname not in globalname2nodeid
    globalname2node[globalname] = node
    globalname2nodeid[globalname] = attribs['id']

    # Add some helpful comments
    if VERBOSE:
        node.append(ET.Comment(" {} ".format(globalname)))

    return node


# Edges -----------------------------------------------------------------

edges = ET.SubElement(rr_graph, 'rr_edges')
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

# -----------------------------------------------------------------------
# -----------------------------------------------------------------------
# -----------------------------------------------------------------------

# Channels (node) ----------------------------------------------------

channels = {}
for y in range(ic.max_y+1):
    channels[(-1,y)] = {}

for x in range(ic.max_x+1):
    channels[(x,-1)] = {}


def add_channel(globalname, nodetype, start, end, idx, segtype):
    assert isinstance(globalname, GlobalName), "{!r} should be a GlobalName".format(globalname)
    assert isinstance(start, TilePos), "{!r} must be a TilePos".format(start)
    assert isinstance(end, TilePos), "{!r} must be a TilePos".format(end)

    x_start = start[0]
    y_start = start[1]

    x_end = end[0]
    y_end = end[1]

    if nodetype == 'CHANY':
        assert x_start == x_end
        channel = (x_start, -1)
        w_start, w_end = y_start, y_end
    elif nodetype == 'CHANX':
        assert y_start == y_end
        channel = (-1, y_start)
        w_start, w_end = x_start, x_end
    else:
        assert False

    assert channel in channels, "{} not in {}".format(channel, channels)

    if w_start < w_end:
        chandir = "INC_DIR"
    elif w_start > w_end:
        chandir = "DEC_DIR"

    if idx not in channels[channel]:
        channels[channel][idx] = []
    channels[channel][idx].append(globalname)

    attribs = {
        'direction': 'BI_DIR',
        'type': nodetype,
    }
    node = add_node(globalname, attribs)

    # <loc xlow="int" ylow="int" xhigh="int" yhigh="int" side="{LEFT|RIGHT|TOP|BOTTOM}" ptc="int">

    # xlow, xhigh, ylow, yhigh - Integer coordinates of the ends of this routing source.
    # ptc - This is the pin, track, or class number that depends on the rr_node type.

    # side - { LEFT | RIGHT | TOP | BOTTOM }
    # For IPIN and OPIN nodes specifies the side of the grid tile on which the node
    # is located. Purely cosmetic?
    ET.SubElement(node, 'loc', {
        'xlow': str(x_start), 'ylow': str(y_start),
        'xhigh': str(x_end), 'yhigh': str(y_end),
        'ptc': str(idx),
    })
    ET.SubElement(node, 'segment', {'segment_id': str(segtype)})

    print("Adding channel {} from {} -> {} pos {}".format(globalname, start, end, idx))

# -----------------------------------------------------------------------
# -----------------------------------------------------------------------
# -----------------------------------------------------------------------

# Pins
# ------------------------------
def globalname_pin(pos, localname):
    return GlobalName("pin", TilePos(*pos), localname)


"""
def iceboxname_pin(tiletype, localname):
    if tiletype == 'IO':
        prefix = 'io['
        if localname.startswith(prefix):
            return 'io_{}/{}'.format(
                localname[len(prefix):len(prefix)+1],
                localname[localname.split('.')[-1]],
            )
        else:
            return 'io_global/{}'.format(localname)
    elif tiletype == "LOGIC":
        prefix = 'lut['
        if localname.startswith(prefix):

            a, b = localname.split('.')

            prefix2 = 'in['
            if b.startswith(prefix2):
                return 'lutff_{}/{}'.format(
                    localname[len(prefix):len(prefix)+1],
                    b
                )

            else:
                return 'lutff_{}/{}'.format(
                    localname[len(prefix):len(prefix)+1],
                    b
                )
        else:
            return 'lutff_global/{}'.format(localname)
"""

def pos_to_vpr(pos):
    return [pos[0] + 1, pos[1] + 1]

def add_pin(pos, localname, dir, idx):
    """Add an pin at index i to tile at pos."""

    """
        <node id="0" type="SINK" capacity="1">
                <loc xlow="0" ylow="1" xhigh="0" yhigh="1" ptc="0"/>
                <timing R="0" C="0"/>
        </node>
        <node id="2" type="IPIN" capacity="1">
                <loc xlow="0" ylow="1" xhigh="0" yhigh="1" side="TOP" ptc="0"/>
                <timing R="0" C="0"/>
        </node>
    """
    gname = globalname_pin(pos, localname)
    gname_pin = GlobalName(*gname, 'pin')

    add_globalname2localname(gname, pos, localname)
    vpos = pos_to_vpr(pos)

    if dir == "out":
        # Sink node
        attribs = {
            'type': 'SINK',
        }
        node = add_node(gname, attribs)
        ET.SubElement(node, 'loc', {
            'xlow': str(vpos[0]), 'ylow': str(vpos[1]),
            'xhigh': str(vpos[0]), 'yhigh': str(vpos[1]),
            'ptc': str(idx),
        })
        ET.SubElement(node, 'timing', {'R': str(0), 'C': str(0)})

        # Pin node
        attribs = {
            'type': 'IPIN',
        }
        node = add_node(gname_pin, attribs)
        ET.SubElement(node, 'loc', {
            'xlow': str(vpos[0]), 'ylow': str(vpos[1]),
            'xhigh': str(vpos[0]), 'yhigh': str(vpos[1]),
            'ptc': str(idx),
            'side': 'TOP',
        })
        ET.SubElement(node, 'timing', {'R': str(0), 'C': str(0)})

        # Edge between pin node
        add_edge(gname, gname_pin)

    elif dir == "in":
        # Source node
        attribs = {
            'type': 'SOURCE',
        }
        node = add_node(gname, attribs)
        ET.SubElement(node, 'loc', {
            'xlow': str(vpos[0]), 'ylow': str(vpos[1]),
            'xhigh': str(vpos[0]), 'yhigh': str(vpos[1]),
            'ptc': str(idx),
        })
        ET.SubElement(node, 'timing', {'R': str(0), 'C': str(0)})

        # Pin node
        attribs = {
            'type': 'OPIN',
        }
        node = add_node(gname_pin, attribs)
        ET.SubElement(node, 'loc', {
            'xlow': str(vpos[0]), 'ylow': str(vpos[1]),
            'xhigh': str(vpos[0]), 'yhigh': str(vpos[1]),
            'ptc': str(idx),
            'side': 'TOP',
        })
        ET.SubElement(node, 'timing', {'R': str(0), 'C': str(0)})

        # Edge between pin node
        add_edge(gname_pin, gname)

    else:
        assert False, "Unknown dir of {} for {}".format(dir, gname)

    print("Adding pin {} on tile {}@{}".format(gname, pos, idx))


# -----------------------------------------------------------------------
# -----------------------------------------------------------------------
# -----------------------------------------------------------------------

# Local Tracks
# ------------------------------

def globalname_track_local(pos, g, i):
    return GlobalName("local", TilePos(*pos), (g, i))

def localname_track_local(pos, g, i):
    return 'local_g{}_{}'.format(g, i)

#def iceboxname_track_local(pos, g, i):
#    return 'local_g{}_{}'.format(g, i)

def globalname_track_glb2local(pos, i):
    return GlobalName("glb2local", TilePos(*pos), i)

def localname_track_glb2local(pos, i):
    return 'glb2local_{}'.format(i)

#def iceboxname_track_glb2local(pos, i):
#    return 'gbl2local_{}'.format(i)

"""
def _add_local(globalname, pos, ptc):
    attribs = {
        'direction': 'BI_DIR',
        'type': 'CHANX',
    }
    node = add_node(globalname, attribs)

    ET.SubElement(node, 'loc', {
        'xlow':  str(pos.x), 'ylow':  str(pos.y),
        'xhigh': str(pos.x), 'yhigh': str(pos.y),
        'ptc': str(ptc),
    })

    ET.SubElement(node, 'segment', {'segment_id': str('local')})
"""

LOCAL_TRACKS_PER_GROUP  = 8
LOCAL_TRACKS_MAX_GROUPS = 4

GBL2LOCAL_MAX_TRACKS    = 4

SPAN4_MAX_TRACKS  = 48
SPAN12_MAX_TRACKS = 24

GLOBAL_MAX_TRACKS = 8


def add_track_local(pos, g, i):
    lname = localname_track_local(pos, g, i)
    gname = globalname_track_local(pos, g, i)

    idx = g * (LOCAL_TRACKS_PER_GROUP) + i

    #print("Adding local track {} on tile {}@{}".format(gname, pos, idx))
    add_channel(gname, 'CHANY', pos, pos, idx, 'local')
    add_globalname2localname(gname, pos, lname)


def add_track_gbl2local(pos, i):
    lname = localname_track_glb2local(pos, i)
    gname = globalname_track_glb2local(pos, i)

    idx = LOCAL_TRACKS_MAX_GROUPS * (LOCAL_TRACKS_PER_GROUP) + i

    #print("Adding glb2local {} track {} on tile {}@{}".format(i, gname, pos, idx))
    add_channel(gname, 'CHANY', pos, pos, idx, 'gbl2local')
    add_globalname2localname(gname, pos, lname)


# -----------------------------------------------------------------------
# -----------------------------------------------------------------------
# -----------------------------------------------------------------------

def tiles(ic):
    for x in range(ic.max_x+1):
        for y in range(ic.max_y+1):
            yield TilePos(x, y)

all_tiles = list(tiles(ic))

corner_tiles = set()
for x in (0, ic.max_x):
    for y in (0, ic.max_y):
        corner_tiles.add((x, y))

# Should we just use consistent names instead?
tile_name_map = {"IO" : "PIO", "LOGIC" : "PLB", "RAMB" : "RAMB", "RAMT" : "RAMT"}

# Add the tiles
# ------------------------------
tile_types = {
    "PIO": {
        "id": 1,
        "pin_map": OrderedDict([
            ('outclk', ('in', 0)),
            ('inclk',  ('in', 1)),
            ('cen',    ('in', 2)),
            ('latch',  ('in', 3)),

            ('io[0].d_in_0',  ('out', 4)),
            ('io[0].d_in_1',  ('out', 5)),
            ('io[0].d_out_0', ('in',  6)),
            ('io[0].d_out_1', ('in',  7)),
            ('io[0].out_enb', ('in',  8)),

            ('io[1].d_in_0',  ('out', 10)),
            ('io[1].d_in_1',  ('out', 11)),
            ('io[1].d_out_0', ('in',  12)),
            ('io[1].d_out_1', ('in',  13)),
            ('io[1].out_enb', ('in',  14)),
        ]),
        'size': (1, 1),
    },

    "PLB": {
        "id": 2,
        "pin_map": OrderedDict([
            ('lut[0].in[0]', ('in', 0)),
            ('lut[0].in[1]', ('in', 1)),
            ('lut[0].in[2]', ('in', 2)),
            ('lut[0].in[3]', ('in', 3)),

            ('lut[1].in[0]', ('in', 4)),
            ('lut[1].in[1]', ('in', 5)),
            ('lut[1].in[2]', ('in', 6)),
            ('lut[1].in[3]', ('in', 7)),

            ('lut[2].in[0]', ('in', 8)),
            ('lut[2].in[1]', ('in', 9)),
            ('lut[2].in[2]', ('in', 10)),
            ('lut[2].in[3]', ('in', 11)),

            ('lut[3].in[0]', ('in', 12)),
            ('lut[3].in[1]', ('in', 13)),
            ('lut[3].in[2]', ('in', 14)),
            ('lut[3].in[3]', ('in', 15)),

            ('lut[4].in[0]', ('in', 16)),
            ('lut[4].in[1]', ('in', 17)),
            ('lut[4].in[2]', ('in', 18)),
            ('lut[4].in[3]', ('in', 19)),

            ('lut[5].in[0]', ('in', 20)),
            ('lut[5].in[1]', ('in', 21)),
            ('lut[5].in[2]', ('in', 22)),
            ('lut[5].in[3]', ('in', 23)),

            ('lut[6].in[0]', ('in', 24)),
            ('lut[6].in[1]', ('in', 25)),
            ('lut[6].in[2]', ('in', 26)),
            ('lut[6].in[3]', ('in', 27)),

            ('lut[7].in[0]', ('in', 28)),
            ('lut[7].in[1]', ('in', 29)),
            ('lut[7].in[2]', ('in', 30)),
            ('lut[7].in[3]', ('in', 31)),

            ('cen', ('in', 32)),
            ('s_r', ('in', 33)),

            ('lut[0].out', ('out', 34)),
            ('lut[1].out', ('out', 35)),
            ('lut[2].out', ('out', 36)),
            ('lut[3].out', ('out', 37)),
            ('lut[4].out', ('out', 38)),
            ('lut[5].out', ('out', 39)),
            ('lut[6].out', ('out', 40)),
            ('lut[7].out', ('out', 41)),

            ('clk', ('in', 32)),
        ]),
        'size': (1, 1),
    },

    "RAMB": {
        "id": 3,
        "pin_map": OrderedDict([
            ('rdata[0]', ('out', 0)),
            ('rdata[1]', ('out', 0)),
            ('rdata[2]', ('out', 0)),
            ('rdata[3]', ('out', 0)),
            ('rdata[4]', ('out', 0)),
            ('rdata[5]', ('out', 0)),
            ('rdata[6]', ('out', 0)),
            ('rdata[7]', ('out', 0)),

            ('waddr[0]',  ('in', 0)),
            ('waddr[1]',  ('in', 0)),
            ('waddr[2]',  ('in', 0)),
            ('waddr[3]',  ('in', 0)),
            ('waddr[4]',  ('in', 0)),
            ('waddr[5]',  ('in', 0)),
            ('waddr[6]',  ('in', 0)),
            ('waddr[7]',  ('in', 0)),
            ('waddr[8]',  ('in', 0)),
            ('waddr[9]',  ('in', 0)),
            ('waddr[10]', ('in', 0)),

            ('mask[0]', ('in', 0)),
            ('mask[1]', ('in', 0)),
            ('mask[2]', ('in', 0)),
            ('mask[3]', ('in', 0)),
            ('mask[4]', ('in', 0)),
            ('mask[5]', ('in', 0)),
            ('mask[6]', ('in', 0)),
            ('mask[7]', ('in', 0)),

            ('wdata[0]', ('in', 0)),
            ('wdata[1]', ('in', 0)),
            ('wdata[2]', ('in', 0)),
            ('wdata[3]', ('in', 0)),
            ('wdata[4]', ('in', 0)),
            ('wdata[5]', ('in', 0)),
            ('wdata[6]', ('in', 0)),
            ('wdata[7]', ('in', 0)),

            ('we',    ('in', 0)),
            ('wclk',  ('in', 0)),
            ('wclke', ('in', 0)),
        ]),
        'size': (1, 1),
    },

    "RAMT": {
        "id": 4,
        "pin_map": OrderedDict([
            ('rdata[8]',  ('out', 0)),
            ('rdata[9]',  ('out', 0)),
            ('rdata[10]', ('out', 0)),
            ('rdata[11]', ('out', 0)),
            ('rdata[12]', ('out', 0)),
            ('rdata[13]', ('out', 0)),
            ('rdata[14]', ('out', 0)),
            ('rdata[15]', ('out', 0)),

            ('raddr[0]',  ('in', 0)),
            ('raddr[1]',  ('in', 0)),
            ('raddr[2]',  ('in', 0)),
            ('raddr[3]',  ('in', 0)),
            ('raddr[4]',  ('in', 0)),
            ('raddr[5]',  ('in', 0)),
            ('raddr[6]',  ('in', 0)),
            ('raddr[7]',  ('in', 0)),
            ('raddr[8]',  ('in', 0)),
            ('raddr[9]',  ('in', 0)),
            ('raddr[10]', ('in', 0)),

            ('mask[8]',  ('in', 0)),
            ('mask[9]',  ('in', 0)),
            ('mask[10]', ('in', 0)),
            ('mask[11]', ('in', 0)),
            ('mask[12]', ('in', 0)),
            ('mask[13]', ('in', 0)),
            ('mask[14]', ('in', 0)),
            ('mask[15]', ('in', 0)),

            ('wdata[8]',  ('in', 0)),
            ('wdata[9]',  ('in', 0)),
            ('wdata[10]', ('in', 0)),
            ('wdata[11]', ('in', 0)),
            ('wdata[12]', ('in', 0)),
            ('wdata[13]', ('in', 0)),
            ('wdata[14]', ('in', 0)),
            ('wdata[15]', ('in', 0)),

            ('re',    ('in', 0)),
            ('rclk',  ('in', 0)),
            ('rclke', ('in', 0)),
        ]),
        'size': (1, 1),
    },
}

print()
print("Generate tiles types")
print("="*75)

"""
    <block_types>
            <block_type id="0" name="io" width="1" height="1">
                <pin_class type="input">
                    0 1 2 3
                </pin_class>
                <pin_class type="output">
                    4 5 6 7
                </pin_class>
            </block_type>
    </block_types>
"""
tt = ET.SubElement(rr_graph, 'block_types')

for tile_name, tile_desc in tile_types.items():
    print("{}".format(tile_name))
    tile = ET.SubElement(
        tt, 'block_type',
        {'id': str(tile_desc['id']), 
         'name':   tile_name, 
         'width':  str(tile_desc["size"][0]),
         'height': str(tile_desc["size"][1]),
        })

    #pins_in  = ET.SubElement(tile, 'pin_class', {'type': 'input'})
    #pins_out = ET.SubElement(tile, 'pin_class', {'type': 'output'})

# ------------------------------

grid = ET.SubElement(rr_graph, 'grid')

print()
print("Generate grid")
print("="*75)

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

print()
print("Generate tiles (with pins and local tracks)")
print("="*75)

for x, y in all_tiles:

    # Corner tile == Empty
    if (x,y) in corner_tiles:
        continue

    pos = TilePos(x, y)

    tile_type = tile_types[tile_name_map[ic.tile_type(pos.x, pos.y)]]

    tid = (pos, tile_type)

    attribs = {
        'x': str(pos.x), 'y': str(pos.y),
        'block_type_id': tile_type["id"],
        'width_offset': str(tile_type["size"][0]-1), 'height_offset': str(tile_type["size"][1]-1),
    }

    # Add pins for the tile
    print()
    print("{}: Adding pins".format(tid))
    print("-"*75)
    for idx, (name, (dir, _)) in enumerate(tile_type["pin_map"].items()):
        add_pin(pos, name, dir, idx)

    # Add the local tracks
    if tile_type == "IO":
        groups_local = (2, LOCAL_TRACKS_PER_GROUP)
        groups_glb2local = 0
    else:
        groups_local = (LOCAL_TRACKS_MAX_GROUPS, LOCAL_TRACKS_PER_GROUP)
        groups_glb2local = GBL2LOCAL_MAX_TRACKS

    print()
    print("{}: Adding local tracks".format(tid))
    print("-"*75)
    for g in range(0, groups_local[0]):
        for i in range(0, groups_local[1]):
            add_track_local(pos, g, i)

    if groups_glb2local:
        print()
        print("{}: Adding glb2local tracks".format(tid))
        print("-"*75)
        for i in range(0, groups_glb2local):
            add_track_gbl2local(pos, i)


# Nets
# ------------------------------

def globalname_net(pos, name):
    return netname2globalname[(pos, name)]


def _calculate_globalname_net(group):
    tiles = set()
    names = set()

    assert group

    for x, y, name in group:
        if name.startswith('lutff_'): # Actually a pin
            lut_idx, pin = name.split('/')

            if lut_idx == "lutff_global":
                return GlobalName("pin", TilePos(x, y), pin)
            else:
                if '_' in pin:
                    pin, pin_idx = pin.split('_')
                    return GlobalName("pin", TilePos(x, y), "lut[{}].{}[{}]".format(lut_idx[len("lutff_"):], pin, pin_idx).lower())
                else:
                    return GlobalName("pin", TilePos(x, y), "lut[{}].{}".format(lut_idx[len("lutff_"):], pin).lower())

        elif name.startswith('io_'): # Actually a pin
            io_idx, pin = name.split('/')

            if io_idx == "io_global":
                return GlobalName("pin", TilePos(x, y), pin)
            else:
                return GlobalName("pin", TilePos(x, y), "io[{}].{}".format(io_idx[len("io_"):], pin).lower())

        elif name.startswith('ram/'): # Actually a pin
            name = name[len('ram/'):]
            if '_' in name:
                pin, pin_idx = name.split('_')
                return GlobalName("pin", TilePos(x, y), "{}[{}]".format(pin, pin_idx).lower())
            else:
                return GlobalName("pin", TilePos(x, y), name.lower())

        if not name.startswith('sp4_r_v_'):
            tiles.add(TilePos(x, y))
        names.add(name)

    if not tiles:
        tiles.add(TilePos(x, y))
    assert names, "No names for {}".format(names)

    wire_type = []
    if len(tiles) == 1:
        pos = tiles.pop()

        name = names.pop().lower()
        if name.startswith('local_'):
            m = re.match("local_g([0-3])_([0-7])", name)
            assert m, "{!r} didn't match local regex".format(name)
            g = int(m.group(1))
            i = int(m.group(2))

            assert name == localname_track_local(pos, g, i)
            return globalname_track_local(pos, g, i)
        elif name.startswith('glb2local_'):
            m = re.match("glb2local_([0-3])", name)
            assert m, "{!r} didn't match glb2local regex".format(name)
            i = int(m.group(1))

            assert name == localname_track_glb2local(pos, i), "{!r} != {!r}".format(
                name, localname_track_glb2local(pos, i))
            return globalname_track_glb2local(pos, i)

        # Special case when no logic to the right....
        elif name.startswith('sp4_r_v_') or name.startswith('neigh_op_'):
            m = re.search("_([0-9]+)$", name)

            wire_type += ["channel", "stub", name]
            wire_type += ["span4"]
            wire_type += [(pos, int(m.group(1)), pos, 1)]
            return GlobalName(*wire_type)

        print("Unknown only local net {}".format(name))
        return None

    # Global wire, as only has one name?
    elif len(names) == 1:
        wire_type = ['global', '{}_tiles'.format(len(tiles)), names.pop().lower()]

    # Work out the type of wire
    if not wire_type:
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

    if not wire_type:
        return None

    if 'channel' in wire_type:
        xs = set()
        ys = set()
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
            assert len(es) == 2, (es, group)

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
                assert False, 'Unknown span corner wire {}'.format((es, group))

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
            assert False, 'Unknown span wire {}'.format((wire_type, group))

        assert start in tiles
        assert end in tiles

        n = None
        for x, y, name in group:
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
        wire_type.append((start, idx, end, delta))

    return GlobalName(*wire_type)

# ------------------------------

print()
print("Calculating nets")
print("="*75)

def filter_name(localname):
    if localname.endswith('cout') or localname.endswith('lout'):
        return True

    if localname.startswith('padout_') or localname.startswith('padin_'):
        return True

    if localname in ("fabout","carry_in","carry_in_mux"):
        return True
    return False


def filter_localnames(group):
    fgroup = []
    for x,y,name in group:
        if not ic.tile_has_entry(x, y, name):
            print("Skipping {} on {},{}".format(name, x,y))
            continue

        if filter_name(name):
            continue

        fgroup.append((x, y, name))
    return fgroup


def add_net_global(i):
    lname = 'glb_netwk_{}'.format(i)
    gname = GlobalName('global', '248_tiles', lname)
    add_channel(gname, 'CHANY', TilePos(0, 0), TilePos(0, 0), i, 'global')

for i in range(0, 8):
    add_net_global(i)

add_channel(GlobalName('global', 'fabout'), 'CHANY', TilePos(0, 0), TilePos(0, 0), 0, 'global')

# ------------------------------

all_group_segments = ic.group_segments(all_tiles, connect_gb=False)
for group in sorted(all_group_segments):
    fgroup = filter_localnames(group)
    if not fgroup:
        continue

    print()
    gname = _calculate_globalname_net(tuple(fgroup))
    if not gname:
        print('Could not calculate global name for', group)
        continue

    if gname[0] == "pin":
        alias_type = "pin"
        assert gname in globalname2netnames, gname
    else:
        alias_type = "net"
        if gname not in globalname2netnames:
            print("Adding net {}".format(gname))

    print(x, y, gname, group)
    for x, y, netname in fgroup:
        add_globalname2localname(gname, TilePos(x, y), netname)


# Create the channels
# -------------------
print()
print("Adding span channels")
print("-"*75)

x_channel_offset = LOCAL_TRACKS_MAX_GROUPS * (LOCAL_TRACKS_PER_GROUP) + GBL2LOCAL_MAX_TRACKS
y_channel_offset = 0

def add_track_span(globalname):
    start, idx, end, delta = globalname[-1]

    x_start = start[0]
    y_start = start[1]

    x_end = end[0]
    y_end = end[1]

    if x_start == x_end:
        nodetype = 'CHANY'
        assert "vertical" in globalname or "stub" in globalname
        idx += x_channel_offset
    elif y_start == y_end:
        nodetype = 'CHANX'
        assert "horizontal" in globalname or "stub" in globalname
        idx += y_channel_offset
    else:
        return

    if 'span4' in globalname:
        segtype = 'span4'
    elif 'span12' in globalname:
        segtype = 'span12'
        idx += SPAN4_MAX_TRACKS #+ 1
    elif 'local' in globalname:
        segtype = 'local'
    else:
        assert False, globalname

    add_channel(globalname, nodetype, start, end, idx, segtype)


for globalname in sorted(globalname2netnames.keys()):
    if globalname[0] != "channel":
        continue
    add_track_span(globalname)


print()
print()
print()
print("Channel summary")
print("="*75)
for channel in sorted(channels):
    print()
    print(channel)
    print("-"*75)

    m = max(channels[channel])

    for idx in range(0, m+1):
        print()
        print(idx)
        if idx not in channels[channel]:
            print("-"*5)
            continue
        for track in channels[channel][idx]:
            if track in globalname2netnames:
                print(track, globalname2netnames[track])
            else:
                print(track, None)
print()
print("Generate channels")
print("="*75)
# TODO check this
chwm = LOCAL_TRACKS_MAX_GROUPS * (LOCAL_TRACKS_PER_GROUP+1) + GBL2LOCAL_MAX_TRACKS + SPAN4_MAX_TRACKS + SPAN12_MAX_TRACKS + GLOBAL_MAX_TRACKS

chans = ET.SubElement(rr_graph, 'channels')
chan = ET.SubElement(
    chans, 'channel',
    {'chan_width_max': str(chwm),
    'x_min': str(0),
    'x_max': str(chwm),
    'y_min': str(0),
    'y_max': str(chwm),
    })

for i in range(4):
    x_list = ET.SubElement(
        chans, 'x_list',
        {'index': str(i),
         'info': str(chwm)
        })
    y_list = ET.SubElement(
       chans, 'y_list',
       {'index': str(i),
        'info': str(chwm)
       })

# Generating edges
# ------------------------------
# These need to match the architecture definition given to vpr.

# rr_edges
# rr_edges tag that encloses information about all the edges between nodes.
# Each rr_edges tag contains multiple subtags:
#   <edge src_node="int" sink_node="int" switch_id="int"/>
# This subtag repeats every edge that connects nodes together in the graph.
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


f = open('rr_graph.xml', 'w')
f.write(ET.tostring(rr_graph, pretty_print=True).decode('utf-8'))
f.close()

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
