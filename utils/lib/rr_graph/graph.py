#!/usr/bin/env python3

import re
import enum

from collections import namedtuple

import lxml.etree as ET

from . import Position
from . import Size
from . import Offset
from .channel import Channels

from ..asserts import assert_eq


def parse_net(s, _r=re.compile("^(.*\\.)?([^.\\[]+)(\\[([0-9]+|[0-9]+:[0-9]+)]|)$")):
    """

    >>> parse_net('BLK_BB-VPR_PAD.outpad[0]')
    ('BLK_BB-VPR_PAD', 'outpad', [0])
    >>> parse_net('BLK_BB-VPR_PAD.outpad')
    ('BLK_BB-VPR_PAD', 'outpad', None)
    >>> parse_net('outpad[10]')
    (None, 'outpad', [10])
    >>> parse_net('outpad')
    (None, 'outpad', None)
    >>> parse_net('outpad[10:12]')
    (None, 'outpad', [10, 11, 12])
    >>> parse_net('outpad')
    (None, 'outpad', None)
    >>> parse_net('wire[2:0]')
    (None, 'wire', [0, 1, 2])
    >>> parse_net('a.b.c[11:8]')
    ('a.b', 'c', [8, 9, 10, 11])

    """

    g = _r.match(s)
    if not g:
        raise TypeError("Pin {!r} not parsed.".format(s))
    block_name, port_name, pin_full, pin_idx = g.groups()

    if not block_name:
        block_name = None
    else:
        assert block_name[-1] == ".", block_name
        block_name = block_name[:-1]

    assert "." not in port_name

    if not pin_idx:
        pins = None
    else:
        assert_eq(pin_full[0], '[')
        assert_eq(pin_full[-1], ']')
        assert_eq(len(pin_full), len(pin_idx)+2)

        if ":" in pin_idx:
            assert_eq(pin_idx.count(':'), 1)
            start, end = (int(b) for b in pin_idx.split(":", 1))
        else:
            start = int(pin_idx)
            end = start

        if start > end:
            end, start = start, end

        end += 1

        pins = list(range(start, end))

    return block_name, port_name, pins


_Pin = namedtuple("Pin", ("port", "num"))
class Pin(_Pin):
    __cache = {}

    def __new__(cls, port, pin_num):
        assert_type(port, Port)
        assert_type(pin_num, int)
        if port.width is not None:
            assert pin_num < port.width, "{} < {}".format(pin_num, port.width)

        cache_key = (port, pin_num)
        if cache_key in cls.__cache:
            obj = cls.__cache[cache_key]
        else:
            obj = _Pin.__new__(cls, port, pin_num)

        cls.__cache[cache_key] = obj
        return obj

    def __str__(self):
        return "{}[{!d}]".format(self.port.name, self.pin_num)

    @property
    def type(self):
        return self.port.type


_Port = namedtuple("Port", ("block", "name"))
class Port(_Port):
    __cache = {}

    class Direction:
        INPUT = "input"
        OUTPUT = "output"
        CLOCK = "clock"
        UNKNOWN = "unknown"

    def __new__(cls, block, port_name, port_dir=None, port_width=None):
        assert "[" not in port_name, port_name
        assert "]" not in port_name, port_name
        assert "." not in port_name, port_name
        assert_type(port_dir, Port.Direction)
        if port_width is not None:
            assert_type(port_width, int)

        cache_key = (block, port_name)
        if cache_key in cls.__cache:
            obj = cls.__cache[cache_key]
        else:
            obj = _Pin.__new__(cls, block, pin_name)
            obj.width = None
            obj.dir = None

        if obj.width is None:
            obj.width = port_width
        else:
            assert_eq(obj.width, port_width)

        if obj.dir is None:
            obj.dir = port_dir
        else:
            assert_eq(obj.dir, port_dir)

        cls.__cache[cache_key] = obj
        return obj

    @classmethod
    def parse(cls, s, block, port_dir=None, port_width=None):
        r = parse_net(s)
        assert_eq(len(r), 3)
        block_name, port_name, pins = r
        if block_name is not None:
            raise TypeError("Name contains block! {!r} ({})".format(s, r))

        if port_name is None:
            raise TypeError("Did not get a port name! {!r} ({})".format(s, r))

        port = cls(block, port_name, port_dir, port_width)

        if pins is None:
            return port

        return (Pin(port, p) in pins)


class Block:
    class Edges(Enum):
        TOP = "TOP"
        LEFT = "LEFT"
        RIGHT = "RIGHT"
        BOTTOM = "BOTTOM"
        BOT = BOTTOM



class GlobalNameMap:
    class Name(str):
        def __new__(cls, pos, block_typename, name):
            str.__new__(cls, "GRID_X{}Y{}/{}.{}".format(
                pos.x, pos.y, block_typename, name))

    def __init__(self, rr_graph):
        # Mapping dictionaries
        self.globalnames2id  = {}
        self.id2obj = {'node': {}, 'edge': {}}
        self._xml_graph = rr_graph

    def _next_id(self, objtype):
        return len(self.id2obj[objtype])

    @property
    def _xml_nodes(self):
        nodes = list(self._xml_graph.iterfind("rr_nodes"))
        assert len(nodes) == 1
        return nodes[0]

    @property
    def _xml_edges(self):
        edges = list(self._xml_graph.iterfind("rr_edges"))
        assert len(edges) == 1
        return edges[0]

    @staticmethod
    def _objtype(obj):
        assert isinstance(obj, ET.SubElement), (
            "{!r} is not an ET.SubElement".format(obj))
        assert "_" in obj.tag, (
            "Tag {!r} doesn't contain '_'.".format(obj.tag))
        objtype = obj.tagname.split("_", 1)[-1]
        assert objtype in self.id2obj, (
            "Object type of {!r} is not valid ({}).".format(
                objtype, ", ".join(self.id2obj.keys())))

    def __getitem__(self, globalname):
        objtype, objid = self.globalnames2id[globalname]
        return self.id2obj[objtype][objid]

    def __setitem__(self, globalname, obj):
        objtype = self._objtype(obj)

        objid = obj.get('id', None)
        if objid is None:
            objid = len(self.id2obj[objtype])

        parent = getattr(self, "_xml_{}".format(objtype))
        if globalname in self.globalname2id:
            assert_eq(self.globalname2id[globalname], objid)
            assert obj is self.id2obj[objid]
            assert obj in list(parent)

        self.id2obj[objtype][objid] = obj
        self.globalname2id[globalname] = objid
        parent.append(obj)


class BlockType:
    def __init__(self):
        self.id = None
        self.pins = []

    #def


_Block = namedtuple("Block", ("pos", "offset", "typeid"))
class Block(_Block):
    pass


class Graph:
    def __init__(self, rr_graph_file=None):
        # Read in existing file
        if rr_graph_file:
            self._xml_graph = ET.parse(read_rr_file)
        else:
            self._xml_graph = ET.Element("rr_graph")
            ET.SubElement(self._xml_graph, "rr_nodes")
            ET.SubElement(self._xml_graph, "rr_edges")

        self.names = GlobalNameMap(self._xml_graph)

        self.grid = {}
        self.channels = Channels()

    def clear_graph(self):
        """Delete the existing nodes and edges."""
        self._xml_nodes.clear()
        self._xml_edges.clear()

    def import_grid(self):
        self.grid = {}
        for loc in self._xml_graph.iterfind("./grid/grid_loc"):
            assert "x" in loc.attrib
            assert "y" in loc.attrib
            assert "block_type_id" in loc.attrib
            assert "width_offset" in loc.attrib
            assert "height_offset" in loc.attrib

            pos = Position(int(loc.attrib['x']), int(loc.attrib['y']))
            offset = Offset(int(loc.attrib["width_offset"]), int(loc.attrib["height_offset"]))


    def import_blocks(self):
        # Create in the block_types information
        blocktype_pins = {}
        for block_type in self._xml_graph.iterfind("./block_types/block_type"):
            block_id = int(block_type.attrib['id'])
            block_name = block_type.attrib['name'].strip()

            assert block_name not in blocktype_pins
            blocktype_pins[block_name] = {}
            for pin in block_type.iterfind("./pin_class/pin"):
                pin_index = int(pin.attrib["index"])
                pin_ptc = int(pin.attrib["ptc"])
                pin_block_name, pin_port_name, pins = parse_net(pin.text.strip())
                assert_eq(pin_block_name, block_name)
                assert_eq(len(pins), 1)
                assert Pin.Types(pin.getparent().attrib["type"])
                blocktype_pins[block_name][pin_name] = (pin_ptc, pin_type)


    def add_pin(self, pos, pin_name, ptc=None, edge=Block.Edge.TOP):
        """Add an pin at index i to tile at pos."""

        pin_globalname_a = pin_globalname+"-"+pin_dir

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

        low = list(pos)
        high = list(pos)

        if pin_dir in ("INPUT", "CLOCK"):
            # Pin node
            attribs = {
                'type': 'IPIN',
            }
            node = self._add_node(pin_globalname, attribs)
            ET.SubElement(node, 'loc', {
                'xlow': str(low[0]), 'ylow': str(low[1]),
                'xhigh': str(high[0]), 'yhigh': str(high[1]),
                'ptc': str(pin_idx),
                'side': 'TOP',
            })
            ET.SubElement(node, 'timing', {'R': str(0), 'C': str(0)})

            # Sink node
            if "INT_R" in pin_globalname:
                low[0]-=1
            elif "INT_L" in pin_globalname:
                high[0]+=1

            attribs = {
                'type': 'SINK',
            }
            node = self._add_node(pin_globalname_a, attribs)
            ET.SubElement(node, 'loc', {
                'xlow': str(low[0]), 'ylow': str(low[1]),
                'xhigh': str(high[0]), 'yhigh': str(high[1]),
                'ptc': str(pin_idx),
            })
            ET.SubElement(node, 'timing', {'R': str(0), 'C': str(0)})

            # Edge PIN->SINK
            add_edge(pin_globalname, pin_globalname_a)

        elif pin_dir in ("OUTPUT",):
            # Pin node
            attribs = {
                'type': 'OPIN',
            }
            node = self._add_node(pin_globalname, attribs)
            ET.SubElement(node, 'loc', {
                'xlow': str(low[0]), 'ylow': str(low[1]),
                'xhigh': str(high[0]), 'yhigh': str(high[1]),
                'ptc': str(pin_idx),
                'side': 'TOP',
            })
            ET.SubElement(node, 'timing', {'R': str(0), 'C': str(0)})

            # Source node
            if "INT_R" in pin_globalname:
                low[0]-=1
            elif "INT_L" in pin_globalname:
                high[0]+=1

            attribs = {
                'type': 'SOURCE',
            }
            node = self._add_node(pin_globalname_a, attribs)
            ET.SubElement(node, 'loc', {
                'xlow': str(low[0]), 'ylow': str(low[1]),
                'xhigh': str(high[0]), 'yhigh': str(high[1]),
                'ptc': str(pin_idx),
            })
            ET.SubElement(node, 'timing', {'R': str(0), 'C': str(0)})

            # Edge SOURCE->PIN
            add_edge(pin_globalname_a, pin_globalname)

        else:
            assert False, "Unknown dir of {} for {}".format(pin_dir, pin_globalname)

        print("Adding pin {:55s} on tile ({:3d}, {:3d})@{:4d}".format(pin_globalname, pos[0], pos[1], pin_idx))



    def check(self):
        # Make sure all the global names mappings are same size.
        assert len(self.globalname2ids) == sum(len(v) for v in self.id2obj.values())

    def _add_node(self, globalname, attribs):
        """Add node with globalname and attributes."""
        # Add common attributes
        attribs['capacity'] =  str(1)


        attribs['id'] = str(len(globalname2node))

        node = ET.SubElement(nodes, 'node', attribs)

        # Stash in the mappings
        assert globalname not in globalname2node, globalname
        assert globalname not in globalname2nodeid, globalname

        globalname2node[globalname] = node
        globalname2nodeid[globalname] = attribs['id']

        # Add some helpful comments
        if args.verbose:
            node.append(ET.Comment(" {} ".format(globalname)))

        return node


    def add_edge(src_globalname, dst_globalname):
        """Add an edge between two nodes."""
        src_node_id = self.globalname2nodeid[src_globalname]
        dst_node_id = self.globalname2nodeid[dst_globalname]

        attribs = {
            'src_node': str(src_node_id),
            'sink_node': str(dst_node_id),
            'switch_id': str(0),
        }
        e = ET.SubElement(edges, 'edge', attribs)

        # Add some helpful comments
        if args.verbose:
            e.append(ET.Comment(" {} -> {} ".format(src_globalname, dst_globalname)))
            self.globalname2node[src_globalname].append(ET.Comment(" this -> {} ".format(dst_globalname)))
            self.globalname2node[dst_globalname].append(ET.Comment(" {} -> this ".format(src_globalname)))


    def add_channel_filler(self, pos, chantype):
        x,y = pos
        current_len = len(channels[chantype][(x,y)])
        fillername = "{}-{},{}+{}-filler".format(chantype,x,y,current_len)
        add_channel(fillername, pos, pos, '0', _chantype=chantype)
        new_len = len(channels[chantype][(x,y)])
        assert current_len + 1 == new_len, new_len


    def add_channel(self, globalname, start, end, segtype, _chantype=None):
        x_start, y_start = start
        x_end, y_end = end

        # Y channel as X is constant
        if x_start == x_end and (_chantype is None or _chantype == "CHANY"):
            assert x_start == x_end
            assert _chantype is None or _chantype == "CHANY"
            chantype = 'CHANY'
            w_start, w_end = y_start, y_end

        # X channel as Y is constant
        elif y_start == y_end and (_chantype is None or _chantype == "CHANX"):
            assert y_start == y_end
            assert _chantype is None or _chantype == "CHANX"
            chantype = 'CHANX'
            w_start, w_end = x_start, x_end

        # Going to need two channels to make this work..
        else:
            assert _chantype is None
            start_channelname = add_channel(
                globalname+"_Y", (x_start, y_start), (x_start, y_end), segtype)[0]
            end_channelname = add_channel(
                globalname+"_X", (x_start, y_end), (x_end, y_end), segtype)[-1]
            add_edge(globalname+"_Y", globalname+"_X")
            return start_channelname, end_channelname

        assert _chantype is None or chantype == _chantype, (chantype, _chantype)

        if w_start > w_end:
            chandir = "DEC_DIR"
        elif w_start < w_end:
            chandir = "INC_DIR"
        elif w_start == w_end and _chantype != None:
            chandir = "INC_DIR"
        else:
            assert False, (globalname, start, end, segtype, _chantype)

        attribs = {
            'direction': chandir,
            'type': chantype,
        }
        node = _add_node(globalname, attribs)

        # <loc xlow="int" ylow="int" xhigh="int" yhigh="int" side="{LEFT|RIGHT|TOP|BOTTOM}" ptc="int">
        channels_for_type = channels[chantype]

        idx = 0
        for x in range(x_start, x_end+1):
            for y in range(y_start, y_end+1):
                idx = max(idx, len(channels_for_type[(x,y)]))

        for x in range(x_start, x_end+1):
            for y in range(y_start, y_end+1):
                while len(channels_for_type[(x,y)]) < idx and _chantype == None:
                    add_channel_filler((x,y), chantype)
                channels_for_type[(x,y)].append(globalname)

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
        return globalname, globalname

if __name__ == "__main__":
    import doctest
    doctest.testmod()

