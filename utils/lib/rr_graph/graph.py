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
from ..asserts import assert_type


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



class IdMapMixIn:
    _id_map = {}

    @classmethod
    def get_id_map(cls):
        return cls._id_map.setdefault(cls, {})

    def _set_id(self, value):
        if value is None:
            return
        assert self._id is None
        id_map = self.get_id_map()
        assert value not in id_map
        self._id = value
        id_map[value] = self


class UniqueFactoryMixIn:

    """
    Use the UniqueFactoryMixIn as follows.

    >>> _MySingleton = namedtuple("MySingleton", ("arg1", "arg2"))
    >>> class MySingleton(_MySingleton, UniqueFactoryMixIn):
    ...     _mutable = (
    ...         ("change_me", str),
    ...     )
    ...     def __new__(cls, arg1, arg2):
    ...         return cls._singleton__new__(_MySingleton.__new__, (arg1, arg2))
    >>> a = MySingleton("a", 2)
    >>> a
    MySingleton(arg1='a', arg2=2)
    >>> b = MySingleton("a", 2)
    >>> b
    MySingleton(arg1='a', arg2=2)
    >>> a is b
    True
    >>> c = MySingleton("b", 2)
    >>> c
    MySingleton(arg1='b', arg2=2)
    >>> a is c
    False
    >>> d = MySingleton(arg1='a', arg2=2)
    >>> d.change_me
    Traceback (most recent call last):
        ...
    NotImplementedError: Value 'change_me' not available yet!
    >>> d.change_me = "hello"
    >>> d.change_me
    'hello'
    >>> a.change_me
    'hello'

    """

    _singleton_cache = {}
    _mutable = None
    @classmethod
    def _singleton__new__(cls, new, args, mutable=None, create=True):
        assert cls != UniqueFactoryMixIn, cls
        if mutable is None:
            mutable = {}

        assert hasattr(cls, "_singleton_cache")
        assert hasattr(cls, "_mutable")
        if cls._mutable is None:
            raise NotImplementedError(
                "Subclass {} needs to set cls._mutable value.".format(cls))
        if not isinstance(cls._mutable, tuple):
            raise NotImplementedError(
                "Subclass {} needs cls._mutable value to be a tuple. Currently: {}".format(
                    cls, cls._mutable))

        cache_key = args
        lcache = cls._singleton_cache.setdefault(cls, {})
        if cache_key in lcache:
            obj = lcache[cache_key]
        elif create:
            obj = new(cls, *args)
            for attrib_name, attrib_type in cls._mutable:
                setattr(obj, "_"+attrib_name, None)
            lcache[cache_key] = obj
        else:
            raise KeyError("{} with key {} not found.".format(cls, cache_key))

        # Check mutable attributes first
        found = {}
        for name, value in mutable.items():
            assert_type(value, cls._type_mutable(name))
            found[name] = value

        # Check they didn't provide extra mutable attributes
        remaining = set(mutable.keys()) - set(found.keys())
        if remaining:
            raise TypeError("Provided unsupported mutable items {}".format(remaining))

        # Set mutable attributes
        for name, value in found.items():
            obj._set_mutable(name, value)

        return obj

    @classmethod
    def _type_mutable(cls, name):
        for mutable_name, mutable_type in cls._mutable:
            if name != mutable_name:
                continue
            return mutable_type
        raise NotImplementedError("{} is not a mutable value.".format(name))

    def _has_mutable(self, name):
        for mutable_name, mutable_type in self._mutable:
            if name == mutable_name:
                return True
        return False

    def _get_mutable(self, name):
        return getattr(self, "_"+name, None)

    def _set_mutable(self, name, value=None):
        if value is not None:
            assert_type(value, self._type_mutable(name))
        current_value = self._get_mutable(name)
        if current_value is None:
            if hasattr(self, "_set_"+name):
                getattr(self, "_set_"+name)(value)
            else:
                setattr(self, "_"+name, value)
        else:
            assert_eq(curret_value, value)

    def __getattr__(self, name):
        if self._has_mutable(name):
            value = self._get_mutable(name)
            if value is None:
                raise NotImplementedError("Value {!r} not available yet!".format(name))
            return value
        raise AttributeError("{} not found on {}.".format(name, self))


_Pin = namedtuple("Pin", ("port", "num"))
class Pin(_Pin, UniqueFactoryMixIn):
    _mutable = (
        ("ptc", int),
    )

    def __new__(cls, port, num, ptc=None):
        assert_type(port, Port)
        assert_type(num, int)

        # Check the num is inside the port_width
        if port.width is not None:
            assert num < port.width, "{} < {}".format(num, port.width)

        return UniqueFactoryMixIn._singleton__new__(
            cls,
            _Pin.__new__,
            args=(port, num),
            mutable={"ptc": ptc},
        )

    def __str__(self):
        return "{!s}[{!d}]".format(self.port, self.num)

    @property
    def direction(self):
        return self.port.direction


class PortDirection:
    INPUT = "input"
    OUTPUT = "output"
    CLOCK = "clock"
    UNKNOWN = "unknown"


class BlockTypeEdge(enum.Enum):
    TOP = "TOP"
    LEFT = "LEFT"
    RIGHT = "RIGHT"
    BOTTOM = "BOTTOM"
    BOT = BOTTOM

    NORTH = TOP
    EAST = RIGHT
    SOUTH = BOTTOM
    WEST = LEFT


_Port = namedtuple("Port", ("block_type", "name"))
class Port(_Port, UniqueFactoryMixIn):
    _mutable = (
        ("direction", PortDirection),
        ("width", int),
        ("edge", BlockTypeEdge),
    )

    def __new__(cls, block_type, port_name, port_dir=None, port_width=None, port_edge=None):
        assert "[" not in port_name, port_name
        assert "]" not in port_name, port_name
        assert "." not in port_name, port_name

        assert_type(block_type, BlockType)

        obj = cls._singleton__new__(
            cls,
            args=(block_type, port_name),
            mutable={
                "direction": port_dir,
                "width": port_width,
                "edge": port_edge,
            },
        )
        obj.create_pins()
        return obj

    def _create_pin(self, num):
        pin = Pin(self, num)
        self.pins.add(pin)
        return pin

    def create_pins(self, port_width=None):
        if obj.width is not None:
            assert_eq(obj.width, port_width)

        if self.width is None:
            self.width = port_width

        assert self.width is not None

        for num in range(0, port_width):
            self._create_pin(num)
        assert_eq(len(self.pins), self.width)

        return pin

    @classmethod
    def parse(cls, s, block_type=None):
        r = parse_net(s)
        assert_eq(len(r), 3)
        block_type_name, port_name, pins = r

        if block_type_name is not None:
            block_type_from_name = BlockType(block_type_name)
            if block_type is not None:
                assert_eq(block_type, block_type_from_name)

        if port_name is None:
            raise TypeError("Did not get a port name! {!r} ({})".format(s, r))

        port = cls(block_type, port_name)

        if pins is None:
            return port

        pin_objs = []
        for num in pins:
            pin_objs.append(port._create_pin(num))

        return pin_objs

    def __str__(self):
        return "{!s}.{!s}[{!d}:0]".format(self.block, self.name, self.width)


_BlockEdges = namedtuple("BlockEdges", ("block", "top", "right", "bottom", "left"))
class BlockEdges:
    def __new__(cls, block):
        if block.edges is not None:
            return block.edges

        edges = _BlockEdges.__new__(cls, block, {}, {}, {}, {})
        block.edges = edges
        return edges

    def __getitem__(self, key):
        if isinstance(key, BlockTypeEdge):
            return self.__getitem__[key.value()]


_BlockType = namedtuple("BlockType", ("name"))
class BlockType(_BlockType, UniqueFactoryMixIn, IdMapMixIn):

    _mutable = (
        ("id", int),
        ("ports", set),
    )

    def __new__(cls, block_name, block_id=None):
        assert_type(block_name, str)
        if block_id is not None:
            assert_type(block_id, int)

        # Singleton cache
        obj = cls._singleton__new__(
            _BlockType.__new__,
            args=(block_name,),
            mutable={
                "id": block_id,
            },
        )

        if obj._ports is None:
            obj._ports = set()

        return obj

    def create_port(self, *args, **kw):
        port = Port(self, *args, **kw)
        self.ports.add(port)
        return port

    def get_pin(self, pin_ptc):
        for port in self.ports:
            for pin in port.pins:
                if pin.ptc == pin_ptc:
                    return pin
        return None

    @classmethod
    def by_id(cls, block_id):
        return cls.get_id_map()[block_id]


_Block = namedtuple("Block", ("id", "offset"))
class Block(_Block, UniqueFactoryMixIn, IdMapMixIn):
    _mutable = (
        ("block_type", BlockType),
    )

    @classmethod
    def get_pos_map(cls):
        return cls.get_id_map()

    @property
    def pos(self):
        return self.id

    @classmethod
    def grid_size(cls):
        x_max = max(p.x for p in cls.get_pos_map())
        y_max = max(p.y for p in cls.get_pos_map())
        return Size(x_max+1, y_max+1)

    def __new__(cls, block_pos, block_offset, block_type=None):
        assert_type(block_pos, Position)
        assert_type(block_offset, Offset)

        # Singleton cache
        obj = cls._singleton__new__(
            _Block.__new__,
            args=(block_pos, block_offset),
            mutable={
                "block_type": block_type,
            },
        )
        obj._id = None
        obj._set_id(block_pos)
        return obj


class NodesIdsMap:
    class Name(str):
        def __new__(cls, pos, block_typename, name):
            str.__new__(cls, "GRID_X{}Y{}/{}.{}".format(
                pos.x, pos.y, block_typename, name))

    def __init__(self, rr_graph):
        # Mapping dictionaries
        self.globalnames2id  = {}
        self.id2node = {'node': {}, 'edge': {}}
        self._xml_graph = rr_graph

    def _next_id(self, node_type):
        return len(self.id2node[node_type])

    def check(self):
        # Make sure all the global names mappings are same size.
        assert len(self.globalname2ids) == sum(len(v) for v in self.id2node.values())

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
    def _node_type(obj):
        assert isinstance(obj, ET.SubElement), (
            "{!r} is not an ET.SubElement".format(obj))
        assert "_" in obj.tag, (
            "Tag {!r} doesn't contain '_'.".format(obj.tag))
        node_type = obj.tagname.split("_", 1)[-1]
        assert node_type in self.id2node, (
            "Object type of {!r} is not valid ({}).".format(
                node_type, ", ".join(self.id2node.keys())))

    def __getitem__(self, globalname):
        node_type, node_id = self.globalnames2id[globalname]
        return self.id2node[node_type][node_id]

    def __setitem__(self, globalname, node_xml):
        node_type = self._node_type(node_xml)

        node_id = node_xml.get('id', None)
        if node_id is None:
            node_id = len(self.id2node[node_type])

        parent_xml = getattr(self, "_xml_{}".format(node_type))
        if globalname in self.globalname2id:
            assert_eq(self.globalname2id[globalname], node_id)
            assert obj is self.id2node[node_id]
            assert obj in list(parent_xml)

        self.id2node[node_type][node_id] = obj
        self.globalname2id[globalname] = node_id
        parent_xml.append(obj)


class Graph:
    def __init__(self, rr_graph_file=None):
        # Read in existing file
        if rr_graph_file:
            self._xml_graph = ET.parse(rr_graph_file)
            self.import_block_types()
            self.import_grid()
        else:
            self._xml_graph = ET.Element("rr_graph")
            ET.SubElement(self._xml_graph, "rr_nodes")
            ET.SubElement(self._xml_graph, "rr_edges")

        self.ids = NodesIdsMap(self._xml_graph)

        #self.grid = {}
        #self.channels = Channels()

    def clear_graph(self):
        """Delete the existing nodes and edges."""
        self._xml_nodes.clear()
        self._xml_edges.clear()


    def import_block_types(self):
        # Create in the block_types information
        for block_type in self._xml_graph.iterfind("./block_types/block_type"):
            block_id = int(block_type.attrib['id'])
            block_name = block_type.attrib['name'].strip()

            bt = BlockType(block_name, block_id)
            continue
            for pin in block_type.iterfind("./pin_class/pin"):
                pin_index = int(pin.attrib["index"])
                pin_ptc = int(pin.attrib["ptc"])
                pin_block_name, pin_port_name, pins = parse_net(pin.text.strip())
                assert_eq(pin_block_name, block_name)
                assert_eq(len(pins), 1)
                assert Pin.Types(pin.getparent().attrib["type"])
                blocktype_pins[block_name][pin_name] = (pin_ptc, pin_type)

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

            assert offset == (0,0), "Non-zero offsets ({!r}) not supported yet.".format(offset)

            block_type = BlockType.by_id(int(loc.attrib["block_type_id"]))
            assert block_type is not None

            Block(pos, offset, block_type)


    def add_pin(self, pos, pin_name, ptc=None, edge=BlockTypeEdge.TOP):
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
    import sys
    if len(sys.argv) == 1:
        import doctest
        doctest.testmod()
    else:
        Graph(rr_graph_file=sys.argv[-1])
        import pprint
        pprint.pprint(BlockType.get_id_map())
        pprint.pprint(Block.get_id_map())
        print(Block.grid_size())
