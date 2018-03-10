#!/usr/bin/env python3

import enum
import io
import pprint
import re
import sys

from collections import namedtuple
from collections import OrderedDict
from types import MappingProxyType

import lxml.etree as ET

from . import Position
from . import Size
from . import Offset
from .channel import Channels

from ..asserts import assert_eq
from ..asserts import assert_is
from ..asserts import assert_type

def assert_type_or_none(obj, classes):
    if obj is not None:
        assert_type(obj, classes)


def frozendict(*args, **kwargs):
  return MappingProxyType(dict(*args, **kwargs))


class MostlyReadOnly:
    """Object which is **mostly** read only.

    >>> class MyRO(MostlyReadOnly):
    ...     __slots__ = ["_str", "_list", "_set", "_dict"]
    >>> a = MyRO()
    >>> a
    MyRO(str=None, list=None, set=None, dict=None)
    >>> a._str = 't'
    >>> a.str
    't'
    >>> a._list = [1,2,3]
    >>> a.list
    (1, 2, 3)
    >>> a._set = {1, 2, 3}
    >>> a.set
    frozenset({1, 2, 3})
    >>> a._dict = {'a': 1, 'b': 2, 'c': 3}
    >>> b = a.dict
    >>> b['d'] = 4
    Traceback (most recent call last):
        ...
        b['d'] = 4
    TypeError: 'mappingproxy' object does not support item assignment
    >>> sorted(b.items())
    [('a', 1), ('b', 2), ('c', 3)]
    >>> a._dict['d'] = 4
    >>> sorted(a._dict.items())
    [('a', 1), ('b', 2), ('c', 3), ('d', 4)]
    >>> sorted(b.items())
    [('a', 1), ('b', 2), ('c', 3)]
    >>> a
    MyRO(str='t', list=[1, 2, 3], set={1, 2, 3}, dict={'a': 1, 'b': 2, 'c': 3, 'd': 4})
    >>> a.random
    Traceback (most recent call last):
        ...
    AttributeError: random not found
    >>> a.random = 1
    Traceback (most recent call last):
        ...
    AttributeError: random not found
    >>> a.random
    Traceback (most recent call last):
        ...
    AttributeError: random not found
    >>> 
    """

    def __setattr__(self, key, value=None):
        if key.startswith("_"):
            return super().__setattr__(key, value)
        if "_"+key not in self.__class__.__slots__:
            raise AttributeError("{} not found".format(key))

    def __getattr__(self, key):
        if "_"+key not in self.__class__.__slots__:
            raise AttributeError("{} not found".format(key))

        value = getattr(self, "_"+key, None)
        if isinstance(value, (tuple, int, bytes, str, type(None), MostlyReadOnly)):
            return value
        elif isinstance(value, list):
            return tuple(value)
        elif isinstance(value, set):
            return frozenset(value)
        elif isinstance(value, dict):
            return frozendict(value)
        else:
            raise AttributeError(
                "Unable to return {}, don't now how to make type {} (from {!r}) read only.".format(
                    key, type(value), value))

    def __repr__(self):
        attribs = []
        for attr in self.__slots__:
            value = getattr(self, attr, None)
            if isinstance(value, MostlyReadOnly):
                rvalue = "{}()".format(value.__class__.__name__)
            elif isinstance(value, (dict, set)):
                s = io.StringIO()
                pprint.pprint(value, stream=s, width=sys.maxsize)
                rvalue = s.getvalue().strip()
            else:
                rvalue = repr(value)
            if attr.startswith("_"):
                attr = attr[1:]
            attribs.append("{}={!s}".format(attr, rvalue))
        return "{}({})".format(self.__class__.__name__, ", ".join(attribs))



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


class Pin(MostlyReadOnly):
    """

    A Pin turns into on IPIN/OPIN node for each block.
    """

    __slots__ = [
        "_pin_class", "_pin_class_index",
        "_port_name", "_port_index",
        "_block_type_name", "_block_type_index",
    ]

    @property
    def ptc(self):
        return self.block_type_index

    @property
    def direction(self):
        return self.pin_class.direction

    @property
    def block_type_name(self):
        if self._block_type_name is None:
            if self.pin_class is None:
                return "??"
            return self.pin_class.block_type_name
        return self._block_type_name

    def __init__(
            self,
            pin_class=None, pin_class_index=None,
            port_name=None, port_index=None,
            block_type_name=None, block_type_index=None):

        assert_type_or_none(pin_class, PinClass)
        assert_type_or_none(pin_class_index, int)

        assert_type_or_none(port_name, str)
        assert_type_or_none(port_index, int)

        assert_type_or_none(block_type_name, str)
        assert_type_or_none(block_type_index, int)

        self._pin_class = pin_class
        self._pin_class_index = pin_class_index
        self._port_name = port_name
        self._port_index = port_index
        self._block_type_name = block_type_name
        self._block_type_index = block_type_index

        if pin_class is not None:
            pin_class._add_pin(self)

    def __str__(self):
        return "{}.{}[{}]".format(self.block_type_name, self.port_name, self.port_index)

    @classmethod
    def from_xml(cls, pin_class, pin_node):
        """

        >>> pc = PinClass(BlockType(name="bt"), direction=PinClassDirection.INPUT)
        >>> xml_string = '<pin index="0" ptc="1">bt.outpad[2]</pin>'
        >>> pin = Pin.from_xml(pc, ET.fromstring(xml_string))
        >>> pin
        Pin(pin_class=PinClass(), pin_class_index=0, port_name='outpad', port_index=2, block_type_name='bt', block_type_index=1)
        >>> str(pin)
        'bt.outpad[2]'
        """

        assert pin_node.tag == "pin"
        pin_class_index = int(pin_node.attrib["index"])
        block_type_index = int(pin_node.attrib["ptc"])

        block_type_name, port_name, pins = parse_net(pin_node.text.strip())

        assert block_type_name is not None
        assert port_name is not None

        assert_eq(len(pins), 1)
        port_index = pins[0]

        #assert_eq(pin_block_name, pin_class.block_type.name)

        return cls(
            pin_class, pin_class_index,
            port_name, port_index,
            block_type_name, block_type_index,
        )


class PinClassDirection(enum.Enum):
    INPUT = "input"
    OUTPUT = "output"
    CLOCK = "clock"
    UNKNOWN = "unknown"

    def __repr__(self):
        return repr(self.value)


class PinClass(MostlyReadOnly):
    """All pins inside a pin class are equivalent.

    A PinClass turns into one SOURCE (when direction==OUTPUT) or SINK (when
    direction in (INPUT, CLOCK)) per each block.

    """

    __slots__ = ["_block_type", "_direction", "_pins"]

    @property
    def port_name(self):
        port_name = self._pins[0].port_name
        for pin in self._pins[1:]:
            assert_eq(port_name, pin.port_name)
        return port_name

    @property
    def block_type_name(self):
        if self.block_type is None:
            return "??"
        return self.block_type.name

    def __init__(self, block_type=None, direction=None, pins=None):
        assert_type_or_none(block_type, BlockType)
        assert_type_or_none(direction, PinClassDirection)

        self._block_type = block_type
        self._direction = direction
        self._pins = {}

        if block_type is not None:
            block_type._add_pin_class(self)

        if pins is not None:
            for i, p in sorted(enumerate(pins)):
                assert i == p.pin_class_index
                self._add_pin(p)

    @classmethod
    def from_xml(cls, block_type, pin_class_node):
        """

        >>> bt = BlockType(name="bt")
        >>> xml_string = '''
        ... <pin_class type="INPUT">
        ...   <pin index="0" ptc="0">bt.outpad[0]</pin>
        ... </pin_class>
        ... '''
        >>> pc = PinClass.from_xml(bt, ET.fromstring(xml_string))
        >>> pc # doctest: +ELLIPSIS
        PinClass(block_type=BlockType(), direction='input', pins={0: ...})
        >>> 
        """
        assert_eq(pin_class_node.tag, "pin_class")
        assert "type" in pin_class_node.attrib
        class_direction = getattr(PinClassDirection, pin_class_node.attrib["type"])
        assert_type(class_direction, PinClassDirection)

        pc_obj = cls(block_type, class_direction)
        for pin_node in pin_class_node.iterfind("./pin"):
            pc_obj._add_pin(Pin.from_xml(pc_obj, pin_node))
        return pc_obj

    def __str__(self):
        return "{}.PinClass({}, [{}])".format(
            self.block_type_name,
            self.direction,
            ", ".join(str(i) for i in sorted(self.pins.items())),
        )

    def _add_pin(self, pin):
        assert_type(pin, Pin)
        if self.block_type is not None and pin.block_type_name is not None:
            assert_eq(pin.block_type_name, self.block_type.name)
            self.block_type._add_pin(pin)
        self._pins[pin.pin_class_index] = pin


class BlockType(MostlyReadOnly):

    __slots__ = ["_graph", "_id", "_name", "_size", "_pin_classes", "_pin_index"]

    def __init__(self, graph=None, id=-1, name="", size=Size(1,1), pin_classes=None):
        assert_type_or_none(graph, BlockGraph)
        assert_type_or_none(id, int)
        assert_type_or_none(name, str)
        assert_type_or_none(size, Size)

        self._graph = graph
        self._id = id
        self._name = name
        self._size = size

        self._pin_classes = []
        self._pin_index = {}
        if pin_classes is not None:
            for pc in pin_classes:
                self._add_pin_class(pc)

    @classmethod
    def from_xml(cls, graph, block_type_node):
        """

        >>> g = None
        >>> xml_string = '''
        ... <block_type id="1" name="BLK_BB-VPR_PAD" width="2" height="3">
        ...   <pin_class type="OUTPUT">
	...     <pin index="0" ptc="0">BLK_BB-VPR_PAD.outpad[0]</pin>
	...   </pin_class>
        ...   <pin_class type="OUTPUT">
	...     <pin index="0" ptc="1">BLK_BB-VPR_PAD.outpad[1]</pin>
	...   </pin_class>
        ...   <pin_class type="INPUT">
	...     <pin index="0" ptc="2">BLK_BB-VPR_PAD.inpad[0]</pin>
	...   </pin_class>
        ... </block_type>
        ... '''
        >>> bt = BlockType.from_xml(g, ET.fromstring(xml_string))
        >>> bt # doctest: +ELLIPSIS
        BlockType(graph=None, id=1, name='BLK_BB-VPR_PAD', size=Size(w=2, h=3), pin_classes=[...], pin_index={...})
        >>> 

        """
        assert block_type_node.tag == "block_type", block_type_node
        block_type_id = int(block_type_node.attrib['id'])
        block_type_name = block_type_node.attrib['name'].strip()
        block_type_width = int(block_type_node.attrib['width'])
        block_type_height = int(block_type_node.attrib['height'])

        bt = cls(graph, block_type_id, block_type_name, Size(block_type_width, block_type_height))
        for pin_class_node in block_type_node.iterfind("./pin_class"):
            bt._add_pin_class(PinClass.from_xml(bt, pin_class_node))
        return bt

    def _could_add_pin(self, pin):
        if pin.block_type_index in self._pin_index:
            assert_is(pin, self._pin_index[pin.block_type_index])

    def _add_pin(self, pin):
        assert_type(pin, Pin)
        self._could_add_pin(pin)
        if pin.block_type_name is None:
            pin.block_type_name = self.name
        else:
            assert_eq(pin.block_type_name, self.name)
        self._pin_index[pin.block_type_index] = pin

    def _add_pin_class(self, pin_class):
        assert_type(pin_class, PinClass)
        assert self is pin_class.block_type

        for p in pin_class.pins.values():
            self._could_add_pin(p)

        for p in pin_class.pins.values():
            self._add_pin(p)

        self._pin_classes.append(pin_class)


class Block(MostlyReadOnly):

    __slots__ = ["_graph", "_block_type", "_position", "_offset"]

    def __init__(self, graph=None, block_type_id=None, block_type=None, position=None, offset=Offset(0,0)):
        assert_type_or_none(graph, BlockGraph)
        assert_type_or_none(block_type_id, int)
        assert_type_or_none(block_type, BlockType)
        assert_type_or_none(position, Position)
        assert_type_or_none(offset, Offset)

        if block_type_id is not None:
            if graph is not None:
                assert block_type is None
                assert graph.block_types is not None
                block_type = graph.block_types[block_type_id]
            else:
                raise TypeError("Must provide graph with numeric block_type")

        self._graph = graph
        self._block_type = block_type
        self._position = position
        self._offset = offset

        if graph is not None:
            graph.add_block(self)

    @classmethod
    def from_xml(cls, graph, grid_loc_node):
        """
        >>> g = BlockGraph()
        >>> g.add_block_type(BlockType(id=0, name="bt"))
        >>> xml_string = '''
	... <grid_loc x="0" y="0" block_type_id="0" width_offset="0" height_offset="0"/>
        ... '''
        >>> bl = Block.from_xml(g, ET.fromstring(xml_string))
        """
        assert grid_loc_node.tag == "grid_loc"

        block_type_id = int(grid_loc_node.attrib["block_type_id"])
        pos = Position(int(grid_loc_node.attrib["x"]), int(grid_loc_node.attrib["y"]))
        offset = Offset(
            int(grid_loc_node.attrib["width_offset"]),
            int(grid_loc_node.attrib["height_offset"]))
        return Block(graph=graph, block_type_id=block_type_id, position=pos, offset=offset)


class BlockGraph:

    def __init__(self):
        self.block_grid = {}
        self.block_types = {}

    def add_block_type(self, block_type):
        assert_type_or_none(block_type, BlockType)
        bid = block_type.id
        assert (
            bid not in self.block_types or
            self.block_types[bid] is None or
            self.block_types[bid] is block_type)
        self.block_types[bid] = block_type

    def block_type_num(self):
        return len(self.block_types)

    def add_block(self, block):
        assert_type_or_none(block, Block)
        pos = block.position
        assert (
            pos not in self.block_grid or
            self.block_grid[pos] is None or
            self.block_grid[pos] is block)
        self.block_grid[pos] = block

    def block_grid_size(cls):
        x_max = max(p.x for p in cls.block_grid)
        y_max = max(p.y for p in cls.block_grid)
        return Size(x_max+1, y_max+1)


class RRNode:
    class Type(enum.Enum):
        input_class     = "SINK"
        output_class    = "SOURCE"
        input_pin       = "IPIN"
        output_pin      = "OPIN"
        channel_x       = "CHANX"
        channel_y       = "CHANY"

    def __init__(self, id, low, high, ptc, capacity=1, timing=None, graph=None):
        if high is None:
            high = low

        assert_type_or_node(id, int)
        assert_type(low, Position)
        assert_type(high, Position)
        assert_type(ptc, int)
        assert_type(capacity, int)

        self.id = id
        self.low = low
        self.high = high
        self.ptc = ptc
        self.capacity = capacity
        self.timing = timing

    @classmethod
    def from_pin(cls, block, pin):
        """ Creates an IPIN/OPIN from `class Pin` object. """

        assert_type(block, Block)
        assert_type(pin, Pin)
        assert_type(pin.pin_class, PinClass)
        assert_type(pin.pin_class.block_type, BlockType)

        low = pin_class.block_type.position
        RRNode.__init__(self, id, low, low, pin)

    @classmethod
    def from_pin_class(cls, block, pin_class):
        """ Creates a SOURCE or SINK node from a `class PinClass` object. """
        assert_type(block, Block)
        assert_type(pin_class, PinClass)
        assert_type(pin_class.block_type, BlockType)

        low = block.position
        high = block.position + pin_class.block_type.size

        RRNode.__init__(self, low, high, 0, timing=timing)
        self.pin_class = pin_class

    @classmethod
    def from_block(cls, block):
        """
        Creates the SOURCE/SINK nodes for each pin class
        Creates the IPIN/OPIN nodes for each pin inside a pin class.
        """
        for pc in block.block_type.pin_classes:
            cls.from_pin_class(block, pc)
            for p in pc.pins:
               cls.from_pin(block, p)
        # FIXME

    @classmethod
    def from_xml(cls, block_graph, node_node):
        """

        >>> g = None
        >>> xml_string1 = '''
        ... <node id="0" type="SINK" capacity="1">
        ...   <loc xlow="1" ylow="1" xhigh="1" yhigh="1" ptc="0"/>
        ...   <timing R="0" C="0"/>
        ... </node>
        ... '''
        >>> n1 = RRNode.from_xml(g, ET.fromstring(xml_string1))
        >>> xml_string2 = '''
        ... <node id="1" type="SOURCE" capacity="1">
        ...   <loc xlow="1" ylow="1" xhigh="1" yhigh="1" ptc="1"/>
        ...   <timing R="0" C="0"/>
        ... </node>
        ... '''
        >>> n2 = RRNode.from_xml(g, ET.fromstring(xml_string2))
        >>> xml_string3 = '''
        ... <node id="2" type="IPIN" capacity="1">
        ...   <loc xlow="1" ylow="1" xhigh="1" yhigh="1" side="TOP" ptc="0"/>
        ...   <timing R="0" C="0"/>
        ... </node>
        ... '''
        >>> n3 = RRNode.from_xml(g, ET.fromstring(xml_string3))
        >>> xml_string4 = '''
        ... <node id="6" type="OPIN" capacity="1">
        ...   <loc xlow="1" ylow="1" xhigh="1" yhigh="1" side="TOP" ptc="1"/>
        ...   <timing R="0" C="0"/>
        ... </node>
        ... '''
        >>> n4 = RRNode.from_xml(g, ET.fromstring(xml_string4))
        """
        assert node_node.tag == "node", node_node

        kw = {}

        kw['id'] = int(node_node.attrib["id"])
        kw['capacity'] = int(node_node.attrib["capacity"])

        low = None
        high = None
        for loc_node in node_node.iterfind("./loc"):
            low = Position(int(loc_node.attrib["xlow"]), int(loc_node.attrib["ylow"]))
            high = Position(int(loc_node.attrib["xhigh"]), int(loc_node.attrib["yhigh"]))
        assert_type(low, Position)
        assert_type(high, Position)

        if block_graph is not None:
            start_block = block_graph.block_grid[low]
            end_block = block_graph.block_grid[high]

        node_type = RRNode.Type(node_node.attrib["type"])

    @staticmethod
    def get_name(block, element):
        """

        >>> bt = BlockType(name="bt")
        >>> pc = PinClass(block_type=bt, direction=PinClassDirection.INPUT)
        >>> p = Pin(pin_class=pc, pin_class_index=0, port_name="port", port_index=2)
        >>> pc._add_pin(p); bt._add_pin_class(pc)
        >>> b = Block(position=Position(2,3), block_type=bt)
        >>> RRNode.get_name(b, p)
        'GRID_X002Y003/bt.port[2]'
        """
        return "GRID_X{:03d}Y{:03d}/{}".format(
            block.position.x, block.position.y, element)



class RRNodeSS(RRNode):
    """Created from `class PinClass` and `class Block`"""
    def __init__(self, block, pin_class, timing=None):
        pass

class RRNodePin(RRNode):
    """Created from `class Pin` and `class Block`"""

    def __init__(self, id, block, pin, timing=None):
        assert_type(block, Block)
        assert_type(pin, Pin)
        assert_type(pin.pin_class, PinClass)
        assert_type(pin.pin_class.block_type, BlockType)

        low = pin_class.block_type.position
        RRNode.__init__(self, id, low, low, pin)


class RROutputClass(RRNodeSS):
    """Created from `class Pin(direction=OUTPUT)` and `class Block`"""
    TYPE=RRNode.Type.output_class


class RRInputClass(RRNodeSS):
    """Created from `class Pin(direction=INPUT|CLOCK)` and `class Block`"""
    TYPE=RRNode.Type.input_class


class RROutputPin(RRNodeSS):
    """Created from `class PinClass(direction=OUTPUT)` and `class Block`"""
    TYPE=RRNode.Type.output_pin


class RRInputClass(RRNodeSS):
    """Created from `class PinClass(direction=INPUT|CLOCK)` and `class Block`"""
    TYPE=RRNode.Type.input_pin


class NodesIdsMap:
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
        self.globalname3id[globalname] = node_id
        parent_xml.append(obj)


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

            bt = BlockType(name=block_name, id=block_id)
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


_Port = namedtuple("Port", ("block_type", "name"))
class Port(_Port):
    _mutable = (
        ("direction", PinClassDirection),
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
            block_type_from_name = BlockType(name=block_type_name)
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
