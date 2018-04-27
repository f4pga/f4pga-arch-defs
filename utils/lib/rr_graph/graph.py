#!/usr/bin/env python3
'''
rr_graph docs: http://docs.verilogtorouting.org/en/latest/vpr/file_formats/
etree docs: http://lxml.de/api/lxml.etree-module.html

general philosiphy
Data structures should generally be conceptual objects rather than direct XML manipulation
Generally one class per XML node type
However, GraphIdsMap is special cased, operating on XML directly and holding

Class list
class Pin(MostlyReadOnly):
    xml: can import but doesn't keep track of a node
class PinClass(MostlyReadOnly):
    xml: can import but doesn't keep track of a node
class BlockType(MostlyReadOnly):
    xml: can import but doesn't keep track of a node
class Block(MostlyReadOnly):
    for <grid_loc>
class BlockGrid:
    Was: BlockGraph
    xml: nothing, handled by intneral Block objects though
class GraphIdsMap:
    holds pins + edges
    xml: updated as pins are added
        inconsistent with the rest of the project
    However, outside generally only add pins through objects
    so they don't see the XML directly
    except print does iterate directly over the XML
class Graph:
    Top level class holding everything together
    has

enums
class BlockTypeEdge(enum.Enum):
    lightweight enum type
class PinClassDirection(enum.Enum):
    lightweight enum type

TODO: parse comments
'''

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
from .channel import Channels, Track, single_element, node_loc, node_pos

from ..asserts import assert_eq
from ..asserts import assert_is
from ..asserts import assert_type
from ..asserts import assert_type_or_none


def frozendict(*args, **kwargs):
    return MappingProxyType(dict(*args, **kwargs))


class MostlyReadOnly:
    """Object which is **mostly** read only. Can set if not already set

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
    >>> a.missing
    Traceback (most recent call last):
        ...
    AttributeError: missing not found
    >>> a.missing = 1
    Traceback (most recent call last):
        ...
    AttributeError: missing not found
    >>> a.missing
    Traceback (most recent call last):
        ...
    AttributeError: missing not found
    """

    def __setattr__(self, key, new_value=None):
        if key.startswith("_"):
            current_value = getattr(self, key[1:])
            if new_value == current_value:
                return
            elif current_value != None:
                raise AttributeError("{} is already set to {}, can't be changed".format(key, current_value))
            return super().__setattr__(key, new_value)

        if "_"+key not in self.__class__.__slots__:
            raise AttributeError("{} not found".format(key))

        self.__setattr__("_"+key, new_value)

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
        elif isinstance(value, enum.Enum):
            return value
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



def parse_net(s, _r=re.compile("^(.*\\.)?([^.\\[]*[^0-9\\[.]+[^.\\[]*)?(\\[([0-9]+|[0-9]+:[0-9]+)]|[0-9]+|)$")):
    """
    Returns:
        - tuple (block_name, port_name, list of pin numbers)


    Fully specified
    >>> parse_net('a.b[0]')
    ('a', 'b', [0])
    >>> parse_net('c.d[1]')
    ('c', 'd', [1])
    >>> parse_net('c.d[40]')
    ('c', 'd', [40])
    >>> parse_net('BLK_BB-VPR_PAD.outpad[0]')
    ('BLK_BB-VPR_PAD', 'outpad', [0])

    Fully specified with more complex block names
    >>> parse_net('a.b.c[0]')
    ('a.b', 'c', [0])
    >>> parse_net('c-d.e[11]')
    ('c-d', 'e', [11])

    Fully specified with block names that include square brackets
    >>> parse_net('a.b[2].c[0]')
    ('a.b[2]', 'c', [0])
    >>> parse_net('c-d[3].e[11]')
    ('c-d[3]', 'e', [11])

    Fully specified range of pins
    >>> parse_net('a.b[11:8]')
    ('a', 'b', [8, 9, 10, 11])
    >>> parse_net('c.d[8:11]')
    ('c', 'd', [8, 9, 10, 11])

    Net with no pin index.
    >>> parse_net('BLK_BB-VPR_PAD.outpad')
    ('BLK_BB-VPR_PAD', 'outpad', None)

    Net with no block
    >>> parse_net('outpad[10]')
    (None, 'outpad', [10])
    >>> parse_net('outpad[10:12]')
    (None, 'outpad', [10, 11, 12])
    >>> parse_net('outpad[12:10]')
    (None, 'outpad', [10, 11, 12])

    No block or pin index
    >>> parse_net('outpad')
    (None, 'outpad', None)
    >>> parse_net('outpad0')
    (None, 'outpad0', None)
    >>> parse_net('0outpad')
    (None, '0outpad', None)

    >>> parse_net('0')
    (None, None, [0])

    # FIXME: ???
    #>>> parse_net('0 1 2')
    #(None, None, [0, 1, 2])

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

    if not port_name:
        port_name = None
    else:
        assert "." not in port_name, port_name

    if not pin_full:
        start, end = None, None
        pins = None
    elif pin_idx:
        assert_eq(pin_full[0], '[')
        assert_eq(pin_full[-1], ']')
        assert_eq(len(pin_full), len(pin_idx)+2)

        if ":" in pin_idx:
            assert_eq(pin_idx.count(':'), 1)
            start, end = (int(b) for b in pin_idx.split(":", 1))
        else:
            start = int(pin_idx)
            end = start
    else:
        start, end = int(pin_full), int(pin_full)

    if start is not None and end is not None:
        if start > end:
            end, start = start, end
        end += 1

        pins = list(range(start, end))

    return block_name, port_name, pins


class Pin(MostlyReadOnly):
    """
    A Pin turns into on IPIN/OPIN node for each block.
    For <pin> nodes

    pin_class_index: = XML index
        starts at 0 within a pin_class and increments for each pin
    block_type_index: = XML ptc
        starts at 0 within a block and increments for each pin
    """

    __slots__ = [
        "_pin_class", "_pin_class_index",
        "_port_name", "_port_index",
        "_block_type_name", "_block_type_index",
    ]

    # Index within a specific BlockType
    # BlockType has multiple pin classes
    # PinClass has multiple pins, usually 1
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
        return "{}({})->{}[{}]".format(self.block_type_name, self.block_type_index, self.port_name, self.port_index)

    @classmethod
    def from_text(cls, pin_class, text, pin_class_index=None, block_type_index=None):
        """
        >>> pin = Pin.from_text(None, '0')
        >>> pin
        Pin(pin_class=None, pin_class_index=None, port_name=None, port_index=None, block_type_name=None, block_type_index=0)
        >>> str(pin)
        'None(0)->None[None]'

        >>> pin = Pin.from_text(None, '10')
        >>> pin
        Pin(pin_class=None, pin_class_index=None, port_name=None, port_index=None, block_type_name=None, block_type_index=10)
        >>> str(pin)
        'None(10)->None[None]'

        >>> pin = Pin.from_text(None, 'bt.outpad[2]')
        >>> pin
        Pin(pin_class=None, pin_class_index=None, port_name='outpad', port_index=2, block_type_name='bt', block_type_index=None)
        >>> str(pin)
        'bt(None)->outpad[2]'

        """
        assert_type(text, str)
        block_type_name, port_name, pins = parse_net(text.strip())
        assert pins is not None, text.strip()

        assert_eq(len(pins), 1)
        if block_type_index is None and port_name is None:
            block_type_index = pins[0]
            port_index = None
        else:
            port_index = pins[0]

        return cls(
            pin_class, pin_class_index,
            port_name, port_index,
            block_type_name, block_type_index,
        )

    @classmethod
    def from_xml(cls, pin_class, pin_node):
        """

        >>> pc = PinClass(BlockType(name="bt"), direction=PinClassDirection.INPUT)
        >>> xml_string = '<pin index="0" ptc="1">bt.outpad[2]</pin>'
        >>> pin = Pin.from_xml(pc, ET.fromstring(xml_string))
        >>> pin
        Pin(pin_class=PinClass(), pin_class_index=0, port_name='outpad', port_index=2, block_type_name='bt', block_type_index=1)
        >>> str(pin)
        'bt(1)->outpad[2]'
        >>> pin.ptc
        1
        """
        assert pin_node.tag == "pin"
        pin_class_index = int(pin_node.attrib["index"])
        block_type_index = int(pin_node.attrib["ptc"])

        return cls.from_text(pin_class, pin_node.text.strip(), pin_class_index=pin_class_index, block_type_index=block_type_index)

    #def pos(self):
    #    return self.pin_class.

class PinClassDirection(enum.Enum):
    INPUT = "input"
    OUTPUT = "output"
    CLOCK = "clock"
    UNKNOWN = "unknown"

    def __repr__(self):
        return repr(self.value)


class PinClass(MostlyReadOnly):
    """All pins inside a pin class are equivalent.
    ie same net. Would a LUT with swappable inputs count?
    For <pin_class> nodes

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
        # pin index to Pin object
        self._pins = {}

        if block_type is not None:
            block_type._add_pin_class(self)

        if pins is not None:
            for p in pins:
                self._add_pin(p)

    @classmethod
    def from_xml(cls, block_type, pin_class_node):
        """
        block_type: block this belongs to
        pin_class_node: XML object to parse

        >>> bt = BlockType(name="bt")
        >>> xml_string1 = '''
        ... <pin_class type="INPUT">
        ...   <pin index="1" ptc="2">bt.outpad[3]</pin>
        ... </pin_class>
        ... '''
        >>> pc = PinClass.from_xml(bt, ET.fromstring(xml_string1))
        >>> pc # doctest: +ELLIPSIS
        PinClass(block_type=BlockType(), direction='input', pins={1: ...})
        >>> len(pc.pins)
        1
        >>> pc.pins[1]
        Pin(pin_class=PinClass(), pin_class_index=1, port_name='outpad', port_index=3, block_type_name='bt', block_type_index=2)


        >>> xml_string2 = '''
        ... <pin_class type="INPUT">0</pin_class>
        ... '''
        >>> pc = PinClass.from_xml(None, ET.fromstring(xml_string2))
        >>> pc # doctest: +ELLIPSIS
        PinClass(block_type=None, direction='input', pins={0: ...})
        >>> len(pc.pins)
        1
        >>> pc.pins[0]
        Pin(pin_class=PinClass(), pin_class_index=0, port_name=None, port_index=None, block_type_name=None, block_type_index=0)


        >>> xml_string3 = '''
        ... <pin_class type="OUTPUT">2 3 4</pin_class>
        ... '''
        >>> pc = PinClass.from_xml(None, ET.fromstring(xml_string3))
        >>> pc # doctest: +ELLIPSIS
        PinClass(block_type=None, direction='output', pins={0: ...})
        >>> len(pc.pins)
        3
        >>> pc.pins[0]
        Pin(pin_class=PinClass(), pin_class_index=0, port_name=None, port_index=None, block_type_name=None, block_type_index=2)
        >>> pc.pins[1]
        Pin(pin_class=PinClass(), pin_class_index=1, port_name=None, port_index=None, block_type_name=None, block_type_index=3)
        >>> pc.pins[2]
        Pin(pin_class=PinClass(), pin_class_index=2, port_name=None, port_index=None, block_type_name=None, block_type_index=4)

        """
        assert_eq(pin_class_node.tag, "pin_class")
        assert "type" in pin_class_node.attrib
        class_direction = getattr(PinClassDirection, pin_class_node.attrib["type"])
        assert_type(class_direction, PinClassDirection)

        pc_obj = cls(block_type, class_direction)

        pin_nodes = list(pin_class_node.iterfind("./pin"))
        if len(pin_nodes) == 0:
            for n in pin_class_node.text.split():
                pc_obj._add_pin(Pin.from_text(pc_obj, n))
        else:
            for pin_node in pin_nodes:
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
        # FIXME: need to investigate pins, pin classes, how indexes related
        # http://docs.verilogtorouting.org/en/latest/vpr/file_formats/#tag-nodes-loc
        # See ptc attribute
        #assert len(self._pins) == 0, (self._pins, pin)

        # If the pin doesn't have a hard coded class index, set it to the next
        # index available.
        if pin.pin_class_index is None:
            pin.pin_class_index = max([-1]+list(self._pins.keys()))+1

        assert pin.pin_class_index is not None, pin.pin_class_index

        if pin.pin_class_index not in self._pins:
            self._pins[pin.pin_class_index] = pin
        assert self._pins[pin.pin_class_index] is pin, "When adding {}, found {} already at index {}".format(pin, self._pins[pin.pin_class_index], pin.pin_class_index)

        pin._pin_class = self

        if self.block_type is not None:
            self.block_type._add_pin(pin)


class BlockType(MostlyReadOnly):
    '''For <block_type> nodes'''

    __slots__ = ["_graph", "_id", "_name", "_size", "_pin_classes", "_pin_index"]

    def __init__(self, graph=None, id=-1, name="", size=Size(1,1), pin_classes=None):
        assert_type_or_none(graph, BlockGrid)
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

        if graph is not None:
            graph.add_block_type(self)

    def to_string(self, extra=False):
        if not extra:
            return "BlockType({name})".format(name=self.name)
        else:
            return "in 0x{graph_id:x} (pin_classes=[{pin_class_num} classes] pin_index=[{pin_index_num} pins])".format(
                graph_id=id(self._graph), pin_class_num=len(self.pin_classes), pin_index_num=len(self.pin_index))

    @classmethod
    def from_xml(cls, graph, block_type_node):
        """

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
        >>> bt = BlockType.from_xml(None, ET.fromstring(xml_string))
        >>> bt # doctest: +ELLIPSIS
        BlockType(graph=None, id=1, name='BLK_BB-VPR_PAD', size=Size(w=2, h=3), pin_classes=[...], pin_index={...})
        >>> len(bt.pin_classes)
        3
        >>> bt.pin_classes[0].direction
        'output'
        >>> bt.pin_classes[0] # doctest: +ELLIPSIS
        PinClass(block_type=BlockType(), direction='output', pins={...})
        >>> bt.pin_classes[0].pins[0]
        Pin(pin_class=PinClass(), pin_class_index=0, port_name='outpad', port_index=0, block_type_name='BLK_BB-VPR_PAD', block_type_index=0)
        >>> bt.pin_classes[1].direction
        'output'
        >>> bt.pin_classes[1].pins[0]
        Pin(pin_class=PinClass(), pin_class_index=0, port_name='outpad', port_index=1, block_type_name='BLK_BB-VPR_PAD', block_type_index=1)
        >>> bt.pin_classes[2].direction
        'input'
        >>> bt.pin_classes[2].pins[0]
        Pin(pin_class=PinClass(), pin_class_index=0, port_name='inpad', port_index=0, block_type_name='BLK_BB-VPR_PAD', block_type_index=2)

        >>> xml_string = '''
        ... <block_type id="1" name="BLK_BB-VPR_PAD" width="2" height="3">
        ...   <pin_class type="OUTPUT">
        ...     <pin index="0" ptc="0">BLK_BB-VPR_PAD.outpad[0]</pin>
        ...     <pin index="1" ptc="1">BLK_BB-VPR_PAD.outpad[1]</pin>
        ...   </pin_class>
        ...   <pin_class type="INPUT">
        ...     <pin index="0" ptc="2">BLK_BB-VPR_PAD.inpad[0]</pin>
        ...   </pin_class>
        ... </block_type>
        ... '''
        >>> bt = BlockType.from_xml(None, ET.fromstring(xml_string))
        >>> bt # doctest: +ELLIPSIS
        BlockType(graph=None, id=1, name='BLK_BB-VPR_PAD', size=Size(w=2, h=3), pin_classes=[...], pin_index={...})
        >>> bt.pin_classes[0] # doctest: +ELLIPSIS
        PinClass(block_type=BlockType(), direction='output', pins={...})
        >>> len(bt.pin_index)
        3
        >>> len(bt.pin_classes)
        2
        >>> len(bt.pin_classes[0].pins)
        2
        >>> len(bt.pin_classes[1].pins)
        1
        >>> bt.pin_classes[0].pins[0]
        Pin(pin_class=PinClass(), pin_class_index=0, port_name='outpad', port_index=0, block_type_name='BLK_BB-VPR_PAD', block_type_index=0)
        >>> bt.pin_classes[0].pins[1]
        Pin(pin_class=PinClass(), pin_class_index=1, port_name='outpad', port_index=1, block_type_name='BLK_BB-VPR_PAD', block_type_index=1)
        >>> bt.pin_classes[1].pins[0]
        Pin(pin_class=PinClass(), pin_class_index=0, port_name='inpad', port_index=0, block_type_name='BLK_BB-VPR_PAD', block_type_index=2)
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
        if pin.block_type_index != None:
            if pin.block_type_index in self._pin_index:
                assert_is(pin, self._pin_index[pin.block_type_index])

    def _add_pin(self, pin):
        """

        >>> pc = PinClass(direction=PinClassDirection.INPUT)
        >>> len(pc.pins)
        0
        >>> pc._add_pin(Pin())
        >>> len(pc.pins)
        1
        >>> bt = BlockType()
        >>> len(bt.pin_index)
        0
        >>> bt._add_pin_class(pc)
        >>> len(bt.pin_index)
        1

        """
        assert_type(pin, Pin)
        self._could_add_pin(pin)

        if pin.block_type_name is None:
            pin.block_type_name = self.name
        assert_eq(self.name, pin.block_type_name, "Expect block type name '%s' match pin prefix '%s'" % (self.name, pin.block_type_name))

        if pin.block_type_index is None:
            pin.block_type_index = max([-1]+list(self._pin_index.keys()))+1

        if pin.block_type_index not in self._pin_index:
            self._pin_index[pin.block_type_index] = pin

        assert_eq(self._pin_index[pin.block_type_index], pin)

    def _add_pin_class(self, pin_class):
        assert_type(pin_class, PinClass)
        for p in pin_class.pins.values():
            self._could_add_pin(p)

        if pin_class.block_type is None:
            pin_class.block_type = self
        assert self is pin_class.block_type

        for p in pin_class.pins.values():
            self._add_pin(p)

        if pin_class not in self._pin_classes:
            self._pin_classes.append(pin_class)

class Block(MostlyReadOnly):
    '''For <grid_loc> nodes'''

    __slots__ = ["_graph", "_block_type", "_position", "_offset"]

    def __init__(self, graph=None, block_type_id=None, block_type=None, position=None, offset=Offset(0,0)):
        assert_type_or_none(graph, BlockGrid)
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

    @property
    def x(self):
        return self.position.x

    @property
    def y(self):
        return self.position.y

    @classmethod
    def from_xml(cls, graph, grid_loc_node):
        """
        >>> g = BlockGrid()
        >>> g.add_block_type(BlockType(id=0, name="bt"))
        >>> xml_string = '''
        ... <grid_loc x="0" y="0" block_type_id="0" width_offset="0" height_offset="0"/>
        ... '''
        >>> bl1 = Block.from_xml(g, ET.fromstring(xml_string))
        >>> bl1 # doctest: +ELLIPSIS
        Block(graph=BG(0x...), block_type=BlockType(), position=P(x=0, y=0), offset=Offset(w=0, h=0))
        >>>
        >>> xml_string = '''
        ... <grid_loc x="2" y="5" block_type_id="0" width_offset="1" height_offset="2"/>
        ... '''
        >>> bl2 = Block.from_xml(g, ET.fromstring(xml_string))
        >>> bl2 # doctest: +ELLIPSIS
        Block(graph=BG(0x...), block_type=BlockType(), position=P(x=2, y=5), offset=Offset(w=1, h=2))
        """
        assert grid_loc_node.tag == "grid_loc"

        block_type_id = int(grid_loc_node.attrib["block_type_id"])
        pos = Position(int(grid_loc_node.attrib["x"]), int(grid_loc_node.attrib["y"]))
        offset = Offset(
            int(grid_loc_node.attrib["width_offset"]),
            int(grid_loc_node.attrib["height_offset"]))
        return Block(graph=graph, block_type_id=block_type_id, position=pos, offset=offset)

    def pins(self):
        '''Convenience function to get all pins'''
        for pin_class in self.block_type.pin_classes:
            for pin in pin_class.pins.values():
                yield pin

    def ptc2pin(self, ptc):
        '''Return Pin for the given ptc (Pin.block_type_index)'''
        # TODO: consider indexing
        for pin_class in self.block_type.pin_classes:
            for pin in pin_class.pins.values():
                if pin.block_type_index == ptc:
                    return pin
        else:
            raise KeyError("ptc %d not found" % ptc)

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

class BlockGrid:
    '''
    For <grid>
    Stores blocks (tiles)
    Stores grid + type
    Does not have routing
    '''

    def __init__(self):
        # block Pos to BlockType
        self.block_grid = {}
        # block id to BlockType
        self.block_types = {}

    def __repr__(self):
        return "BG(0x{:x})".format(id(self))

    def _next_block_type_id(self):
        return len(self.block_types)

    def add_block_type(self, block_type):
        assert_type_or_none(block_type, BlockType)

        if block_type.id is None:
            block_type.id = self._next_block_type_id()

        bid = block_type.id
        assert (
            bid not in self.block_types or
            self.block_types[bid] is None or
            self.block_types[bid] is block_type)
        self.block_types[bid] = block_type

    def add_block(self, block):
        assert_type_or_none(block, Block)
        pos = block.position
        assert (
            pos not in self.block_grid or
            self.block_grid[pos] is None or
            self.block_grid[pos] is block)
        self.block_grid[pos] = block

    def size(self):
        x_max = max(p.x for p in self.block_grid)
        y_max = max(p.y for p in self.block_grid)
        return Size(x_max+1, y_max+1)

    def blocks(self, positions):
        return [self.block_grid[pos] for pos in positions]

    def block_types_for(self, col=None, row=None):
        ss = []
        for pos in sorted(self.block_grid):
            if col is not None:
                if pos.x != col:
                    continue
            if row is not None:
                if pos.y != row:
                    continue

            ss.append(self.block_grid[pos].block_type)
        return ss

    def blocks_for(self, col=None, row=None):
        ss = []
        for pos in sorted(self.block_grid):
            if col is not None:
                if pos.x != col:
                    continue
            if row is not None:
                if pos.y != row:
                    continue

            ss.append(self.block_grid[pos])
        return ss

    def __getitem__(self, pos):
        return self.block_grid[pos]

    def __iter__(self):
        for pos in sorted(self.block_grid):
            yield self.block_grid[pos]

class RRNodeType(enum.Enum):
    input_class     = "SINK"
    output_class    = "SOURCE"
    input_pin       = "IPIN"
    output_pin      = "OPIN"
    channel_x       = "CHANX"
    channel_y       = "CHANY"

    @classmethod
    def from_xml(cls, xml_node):
        assert xml_node.tag == "node", xml_node
        return RRNodeType(xml_node.attrib["type"])

class GraphIdsMap:
    '''
    in rr_graph each node has ID
    maps between the human and those incrementing numbers
    for <node>, <edge> objects
    <switch> is also currently in here, but maybe shouldn't be
    '''

    def __init__(self, block_graph, xml_graph=None, verbose=True):
        '''
        >>> g = simple_test_graph()
        '''
        self.verbose = verbose
        assert_type(block_graph, BlockGrid)

        # Mapping dictionaries
        self.name2id  = {}
        # lookup XML node for given object ID
        self.id2node = {'node': {}, 'edge': {}, 'switch': {}}
        # nodes associated with pins
        # these are slow to find manually as it involves going through entire graph
        # FIXME: index these for quicker lookup
        #self.pinclass2nodes = {}
        #self.pin2nodes = {}

        self._block_graph = block_graph

        if xml_graph is None:
            xml_graph = ET.Element("rr_graph")
            ET.SubElement(xml_graph, "rr_nodes")
            ET.SubElement(xml_graph, "rr_edges")
            ET.SubElement(xml_graph, "switches")
        self._xml_graph = xml_graph

        # Index existing XML entries
        for node in self._xml_nodes:
            self.add_node_xml(node)
        for edge in self._xml_edges:
            self.add_edge_xml(edge)
        for switch in self._xml_switches:
            self.add_switch_xml(switch)

    def clear_graph(self):
        """Delete the existing nodes and edges."""
        self._xml_nodes.clear()
        self._xml_edges.clear()
        self._xml_switches.clear()

        self.name2id  = {}
        self.id2node = {'node': {}, 'edge': {}, 'switch': {}}

    def _next_id(self, xml_group):
        return len(self.id2node[xml_group])

    def check(self):
        # Make sure all the global names mappings are same size.
        assert len(self.name2ids) == sum(len(v) for v in self.id2node.values())

    @property
    def _xml_nodes(self):
        return single_element(self._xml_graph, 'rr_nodes')

    @property
    def _xml_edges(self):
        return single_element(self._xml_graph, 'rr_edges')

    @property
    def _xml_switches(self):
        return single_element(self._xml_graph, 'switches')

    def _xml_group(self, xml_node):
        assert xml_node.tag in self.id2node, (
            "Object type of {!r} is not valid ({}).".format(
                xml_node.tag, ", ".join(self.id2node.keys())))
        return xml_node.tag

    def add_node_xml(self, xml_node, verbose=False):
        if 'capacity' not in xml_node.attrib:
            xml_node.attrib['capacity'] =  str(1)

        name = self.node_name(xml_node)
        self[name] = xml_node

        if verbose:
            xml_node.append(ET.Comment(" {} ".format(name)))

    def add_edge_xml(self, xml_edge, verbose=False):
        # what is this? needed?
        #if 'capacity' not in xml_node.attrib:
        #    xml_node.attrib['capacity'] =  str(1)

        name = self.edge_name(xml_edge)
        self[name] = xml_edge

        # invalid chars in comment
        #if verbose:
        #    xml_edge.append(ET.Comment(" {} ".format(name)))

    def add_switch_xml(self, xml_switch, verbose=False):
        name = self.switch_name(xml_switch)
        self[name] = xml_switch

    def __getitem__(self, name):
        xml_group, node_id = self.names2id[name]
        return self.id2node[xml_group][node_id]

    def __setitem__(self, name, xml_node):
        xml_group = self._xml_group(xml_node)

        node_id = xml_node.get('id', None)
        if node_id is None:
            node_id = len(self.id2node[xml_group])

        '''
        parent_xml = {
            'node': self._xml_nodes,
            'edge': self._xml_edges,
            'switch': self._xml_switches,
            }[xml_group]
        #assert obj in list(parent_xml)
        #parent_xml.append(obj)
        '''

        if name in self.name2id:
            assert_eq(self.name2id[name], node_id, "%s inconsistent node ID with old %s, new %s" % (name, self.name2id[name], node_id))
            #assert obj is self.id2node[node_id]

        self.id2node[xml_group][node_id] = xml_node
        self.name2id[name] = node_id

    def node_name(self, xml_node):
        """Get a globally unique name for an `node` in the rr_nodes.

        >>>
        >>> bg = simple_test_block_grid()
        >>> m = GraphIdsMap(block_grid=bg)
        >>>
        >>> m.node_name(ET.fromstring('''
        ... <node id="0" type="SINK" capacity="1">
        ...   <loc xlow="0" ylow="3" xhigh="0" yhigh="3" ptc="0"/>
        ...   <timing R="0" C="0"/>
        ... </node>
        ... '''))
        'X000Y003_INBLOCK[00].SINK-<'
        >>> m.node_name(ET.fromstring('''
        ... <node id="1" type="SOURCE" capacity="1">
        ...   <loc xlow="1" ylow="2" xhigh="1" yhigh="2" ptc="1"/>
        ...   <timing R="0" C="0"/>
        ... </node>
        ... '''))
        'X001Y002_DUALBLK[01].SRC-->'
        >>> m.node_name(ET.fromstring('''
        ... <node id="2" type="IPIN" capacity="1">
        ...   <loc xlow="2" ylow="1" xhigh="2" yhigh="1" side="TOP" ptc="0"/>
        ...   <timing R="0" C="0"/>
        ... </node>
        ... '''))
        'X002Y001_DUALBLK[00].T-PIN<'
        >>> m.node_name(ET.fromstring('''
        ... <node id="6" type="OPIN" capacity="1">
        ...   <loc xlow="3" ylow="0" xhigh="3" yhigh="0" side="RIGHT" ptc="1"/>
        ...   <timing R="0" C="0"/>
        ... </node>
        ... '''))
        'X003Y000_OUTBLOK[01].R-PIN>'
        >>> m.node_name(ET.fromstring('''
        ... <node capacity="1" direction="INC_DIR" id="372" type="CHANX">
        ...   <loc ptc="4" xhigh="3" xlow="3" yhigh="0" ylow="0"/>
        ...   <timing C="2.72700004e-14" R="101"/>
        ...   <segment segment_id="1"/>
        ... </node>
        ... '''))
        'X003Y000--04->X003Y000'
        >>> m.node_name(ET.fromstring('''
        ... <node capacity="1" direction="DEC_DIR" id="373" type="CHANY">
        ...   <loc ptc="5" xhigh="3" xlow="3" yhigh="0" ylow="0"/>
        ...   <timing C="2.72700004e-14" R="101"/>
        ...   <segment segment_id="1"/>
        ... </node>
        ... '''))
        'X003Y000<|05||X003Y000'
        >>> m.node_name(ET.fromstring('''
        ... <node capacity="1" direction="BI_DIR" id="374" type="CHANX">
        ...   <loc ptc="5" xhigh="3" xlow="3" yhigh="0" ylow="0"/>
        ...   <timing C="2.72700004e-14" R="101"/>
        ...   <segment segment_id="1"/>
        ... </node>
        ... '''))
        'X003Y000<-05->X003Y000'

        'X002Y003_BT[00].T-PIN<'
        'X002Y003_BT[00].L-PIN<'
        'X002Y003_BT[00].R-PIN<'
        'X002Y003_BT[00].B-PIN<'
        'X002Y003_BT[00].SINK<'
        'X002Y003_BT[00].SRC>'
        'X002Y003_BT[00].T-PIN>'
        'X002Y003_BT[00].L-PIN>'
        'X002Y003_BT[00].R-PIN>'
        'X002Y003_BT[00].B-PIN>'

        'X003Y000--05->X003Y000'
        'X003Y000<-05--X003Y000'

        'X003Y000||05|>X003Y000'
        'X003Y000<|05||X003Y000'
        """

        loc_node = list(xml_node.iterfind("./loc"))[0]
        low = Position(int(loc_node.attrib["xlow"]), int(loc_node.attrib["ylow"]))
        high = Position(int(loc_node.attrib["xhigh"]), int(loc_node.attrib["yhigh"]))
        ptc = int(loc_node.attrib["ptc"])
        edge = loc_node.attrib.get("side", " ")[0]

        type_str = None
        node_type = RRNodeType.from_xml(xml_node)
        if False:
            pass
        elif node_type in (RRNodeType.channel_x, RRNodeType.channel_y):
            direction = xml_node.attrib.get("direction")
            direction_fmt = {
                'INC_DIR': '{f}{f}{ptc:02d}{f}>',
                'DEC_DIR': '<{f}{ptc:02d}{f}{f}',
                'BI_DIR': '<{f}{ptc:02d}{f}>',
            }.get(direction, None)
            assert direction_fmt, "Bad direction %s" % direction

            block_from = self._block_graph[low]
            block_to   = self._block_graph[high]
            return "X{:03d}Y{:03d}{}X{:03d}Y{:03d}".format(
                block_from.x, block_from.y,
                direction_fmt.format(f={RRNodeType.channel_x: '-', RRNodeType.channel_y: '|'}[node_type], ptc=ptc),
                block_to.x, block_to.y)
        elif node_type is RRNodeType.input_class:
            type_str = "SINK-<"
            # FIXME: Check high == block.position + block.block_type.size
        elif node_type is RRNodeType.output_class:
            type_str = "SRC-->"
            # FIXME: Check high == block.position + block.block_type.size
        elif node_type is RRNodeType.input_pin:
            assert edge in "TLRB", edge
            type_str = "{}-PIN<".format(edge)
        elif node_type is RRNodeType.output_pin:
            assert edge in "TLRB", edge
            type_str = "{}-PIN>".format(edge)
        else:
            assert False, "Unknown node_type {}".format(node_type)
        assert type_str

        block = self._block_graph[low]

        return "X{x:03d}Y{y:03d}_{t}[{i:02d}].{s}".format(
            t=block.block_type.name, x=block.position.x, y=block.position.y,
            i=ptc, s=type_str)

    def nodes_for_edge(self, xml_node):
        '''Return all node XML objects associated with given edge XML object

        >>> test_nodes_for_edges()
        '''
        assert xml_node.tag == 'edge'
        snk_node_id = xml_node.attrib.get("sink_node")
        src_node_id = xml_node.attrib.get("src_node")

        # XXX: check that the two nodes are in similar grid positions?

        id2node = self.id2node['node']
        assert snk_node_id in id2node, snk_node_id
        assert src_node_id in id2node, src_node_id
        return id2node[src_node_id], id2node[snk_node_id]

    def edge_name(self, xml_node, flip=False):
        """Get a globally unique name for an `edge` in the rr_edges.

        An edge goes between two `node` objects.

        >>> bg = simple_test_block_grid()
        >>> xml_string1 = '''
        ... <rr_graph>
        ...  <rr_nodes>
        ...   <node id="0" type="SOURCE" capacity="1">
        ...     <loc xlow="0" ylow="3" xhigh="0" yhigh="3" ptc="0"/>
        ...     <timing R="0" C="0"/>
        ...   </node>
        ...   <node capacity="1" direction="INC_DIR" id="1" type="CHANY">
        ...     <loc ptc="5" xhigh="3" xlow="0" yhigh="0" ylow="3"/>
        ...     <timing C="2.72700004e-14" R="101"/>
        ...     <segment segment_id="1"/>
        ...   </node>
        ...  </rr_nodes>
        ... <rr_edges />
        ... <switches />
        ... </rr_graph>
        ... '''
        >>> m = GraphIdsMap(block_grid=bg, xml_graph=ET.fromstring(xml_string1))
        >>> m.edge_name(ET.fromstring('''
        ... <edge sink_node="1" src_node="0" switch_id="1"/>
        ... '''))
        'X000Y003_INBLOCK[00].SRC--> ->>- X000Y003||05|>X003Y000'
        """
        src_node, snk_node = self.nodes_for_edge(xml_node)

        if flip:
            return "{} -<<- {}".format(self.node_name(snk_node), self.node_name(src_node))
        else:
            return "{} ->>- {}".format(self.node_name(src_node), self.node_name(snk_node))

    def switch_name(self, xml_switch):
        # FIXME: better name
        return "SW%s" % xml_switch.attrib["id"]

    def edges_for_node(self, xml_node):
        node_id = xml_node.attrib.get('id', None)
        assert node_id is not None, ET.tostring(xml_node)

        edges = []
        for edge_node in self._xml_edges:
            src_node, snk_node = self.nodes_for_edge(edge_node)

            src_id = src_node.get('id', None)
            assert src_id is not None, ET.tostring(src_node)
            snk_id = snk_node.get('id', None)
            assert snk_id is not None, ET.tostring(snk_node)

            if src_id == node_id or snk_id == node_id:
                edges.append(edge_node)

        return edges

    def add_node(self, low, high, ptc, ntype, direction=None, segment_id=None):
        assert ntype in ('IPIN', 'OPIN', 'SINK', 'SOURCE', 'CHANX', 'CHANY')
        attrs = {'id': str(self._next_id('node')), 'type': ntype}
        if ntype in ('CHANX', 'CHANY'):
            assert direction != None
            attrs['direction'] = direction.value
        if ntype in ('SOURCE'):
            assert low == high, (low, high)
        node = ET.SubElement(self._xml_nodes, 'node', attrs)
        ET.SubElement(node, 'loc', {
            'xlow': str(low.x), 'ylow': str(low.y),
            'xhigh': str(high.x), 'yhigh': str(high.y),
            'ptc': str(ptc),
            # FIXME: This should probably be settable..
            'side': 'RIGHT',
        })
        ET.SubElement(node, 'timing', {'R': str(0), 'C': str(0)})
        if ntype in ('CHANX', 'CHANY'):
            assert segment_id != None
            assert type(segment_id) is int
            ET.SubElement(node, 'segment', {'segment_id': str(segment_id)})

        self.add_node_xml(node)
        return node

    def add_edge(self, src_node, sink_node, switch_id):
        # <edge src_node="34" sink_node="44" switch_id="1"/>
        assert type(src_node) is int, type(src_node)
        assert type(sink_node) is int, type(sink_node)
        assert type(switch_id) is int, type(switch_id)

        assert str(src_node) in self.id2node['node'], src_node
        assert str(sink_node) in self.id2node['node'], sink_node
        assert str(switch_id) in self.id2node['switch'], switch_id
        edge = ET.SubElement(self._xml_edges, 'edge', {
                'src_node': str(src_node), 'sink_node': str(sink_node), 'switch_id': str(switch_id)})
        self.add_edge_xml(edge)
        return edge

    def add_switch(self, name, stype='mux', buffered=1, configurable=None, timing=None, sizing=None):
        '''
        timing: dict of attributes
        sizing: dict of attributes
        '''
        # <switch id="0" name="my_switch" buffered="1" configurable="1"/>
        '''
        name='my_switch'
        configurable=1
        buffered="1"
        return ET.SubElement(self._xml_switches, 'switch', {
                'id': str(self._next_id('switch')), 'name': name, 'buffered': str(buffered), 'configurable': str(configurable)})
        '''
        # just one dummy switch for now
        # assert len(self._xml_switches) == 0
        assert stype in 'mux|tristate|pass_gate|short|buffer'.split('|'), stype
        attrs = {'id': str(self._next_id('switch')), 'name': name, 'type': stype, 'buffered': str(buffered)}
        if configurable is not None:
            attrs['confiturable'] = str(int(bool(configurable)))
        switch_node = ET.SubElement(self._xml_switches, 'switch', attrs)
        if timing:
            assert False, 'fixme: float conversion'
            ET.SubElement(switch_node, 'timing', timing)

        # FIXME: this attribute is required
        # https://github.com/verilog-to-routing/vtr-verilog-to-routing/issues/333
        if sizing:
            assert False, 'fixme: float conversion'
            ET.SubElement(switch_node, 'sizing', sizing)
        else:
            ET.SubElement(switch_node, 'sizing', {'mux_trans_size':"0", "buf_size":"0"})

        self.add_switch_xml(switch_node)
        return switch_node

    def add_node_for_pin(self, block, pin):
        """ Creates an IPIN/OPIN node from `class Pin` object. """
        assert_type(block, Block)
        assert_type(pin, Pin)
        assert_type(pin.pin_class, PinClass)
        assert_type(pin.pin_class.block_type, BlockType)

        pc = pin.pin_class
        # Connection within the same tile
        low = block.position
        # FIXME: look into multiple tile blocks
        assert block.offset == (0, 0), block.offset
        high = block.position

        pin_node = None
        if pc.direction in (PinClassDirection.INPUT, PinClassDirection.CLOCK):
            pin_node = self.add_node(low, high, pin.ptc, 'IPIN')
        elif pin.pin_class.direction in (PinClassDirection.OUTPUT,):
            pin_node = self.add_node(low, high, pin.ptc, 'OPIN')
        else:
            assert False, "Unknown dir of {}.{}".format(pin, pin.pin_class)

        assert pin_node != None, pin_node

        if self.verbose:
            print("Adding pin {:55s} on tile ({:12s}, {:12s})@{:4d}".format(str(pin), str(low), str(high), pin.ptc))
        return pin_node

    def add_nodes_for_pin_class(self, block, pin_class, switch):
        """ Creates a SOURCE or SINK node from a `class PinClass` object. """
        assert_type(block, Block)
        assert_type(block.block_type, BlockType)
        assert_type(pin_class, PinClass)
        assert_type(pin_class.block_type, BlockType)
        assert_eq(block.block_type, pin_class.block_type)

        pos_low = block.position
        pos_high = block.position + pin_class.block_type.size - Size(1, 1)

        # Assuming only one pin per class for now
        # see [0] references
        assert len(pin_class.pins) == 1, 'Expect one pin per pin class, got %s' % (pin_class.pins,)
        pin = pin_class.pins[0]
        if pin_class.direction in (PinClassDirection.INPUT, PinClassDirection.CLOCK):
            # Sink node
            sink_node = self.add_node(pos_low, pos_high, pin.ptc, 'SINK')

            for p in pin_class.pins.values():
                pin_node = self.add_node_for_pin(block, p)

                # Edge PIN->SINK
                self.add_edge(int(pin_node.get("id")), int(sink_node.get("id")), int(switch.get("id")))

        elif pin_class.direction in (PinClassDirection.OUTPUT,):
            # Source node
            src_node = self.add_node(pos_low, pos_high, pin.ptc, 'SOURCE')

            for p in pin_class.pins.values():
                pin_node = self.add_node_for_pin(block, p)

                # Edge SOURCE->PIN
                self.add_edge(int(src_node.get("id")), int(pin_node.get("id")), int(switch.get("id")))

        else:
            assert False, "Unknown dir of {} for {}".format(pin_class.direction, str(pin_class))

        #return pin_node

    def add_nodes_for_block(self, block, switch):
        """
        Creates the SOURCE/SINK nodes for each pin class
        Creates the IPIN/OPIN nodes for each pin inside a pin class.

        >>> test_add_nodes_for_block()
        """
        for pc in block.block_type.pin_classes:
            self.add_nodes_for_pin_class(block, pc, switch)

    def add_node_for_track(self, track):
        assert_type(track, Track)
        assert track.idx != None

        return self.add_node(track.start, track.end, track.idx, track.type.value,
                             direction=track.direction, segment_id=track.segment.id)

class Graph:
    '''
    Top level representation, holds the XML root
    For <rr_graph> node
    '''

    def __init__(self, rr_graph_file=None, verbose=True):
        self.verbose = verbose

        # Read in existing file
        if rr_graph_file:
            self.block_grid = BlockGrid()
            self._xml_graph = ET.parse(rr_graph_file, ET.XMLParser(remove_blank_text=True))
            self.import_block_types()
            self.import_grid()
        else:
            self._xml_graph = ET.Element("rr_graph")
            ET.SubElement(self._xml_graph, "rr_nodes")
            ET.SubElement(self._xml_graph, "rr_edges")

        self.ids = GraphIdsMap(self.block_grid, self._xml_graph, verbose=verbose)

        # Channels import requires rr_nodes
        if rr_graph_file:
            self.import_xml_channels()
        else:
            # First and last row/col cannot be occupied, see channel.py
            self.channels = Channels(self.block_grid.size() - Position(1, 1))

    # Following takes info from existing rr_graph file

    def import_block_types(self):
        # Create in the block_types information
        for block_type in self._xml_graph.iterfind("./block_types/block_type"):
            BlockType.from_xml(self.block_grid, block_type)

    def import_grid(self):
        for block_xml in self._xml_graph.iterfind("./grid/grid_loc"):
            Block.from_xml(self.block_grid, block_xml)
        size = self.block_grid.size()
        assert size.x > 0
        assert size.y > 0

    def import_xml_channels(self):
        bgs = self.block_grid.size()
        print(bgs)
        cs = bgs - Size(1, 1)
        print(cs)
        self.channels = Channels(cs)
        # Add segments
        self.channels.from_xml_segments(single_element(self._xml_graph, 'segments'))
        # Add channels
        self.channels.from_xml_nodes(self.ids._xml_nodes)

    def set_tooling(self, name, version, comment):
        root = self._xml_graph.getroot()
        root.set("tool_name", name)
        root.set("tool_version", version)
        root.set("tool_comment", comment)

    def add_nodes_for_blocks(self, switch):
        for block in self.block_grid:
            self.ids.add_nodes_for_block(block, switch)

    def connect_pin_to_track(self, block, pin, track, switch, node_index=None):
        '''
        Create an edge from given pin in block to given track with switching properties of switch
        '''
        assert_type(block, Block)
        assert_type(pin, Pin)
        assert_type(track, Track)
        assert_type(switch, ET._Element)

        # Create a node for the track connection as given position
        bpin2node, track2node = node_index if node_index else self.index_node_objects()
        pin_node = bpin2node[(block, pin)]
        pos = block.position

        # See if there is a node at the track at the given position
        # if not, add one
        track_node = track2node[track]
        if track_node is None:
            track_node = self.add_node(pos, pos, track.idx, track.type)

        # It wants directionality...although bidir can exist too?
        src_node, sink_node = {
            'input':  (track_node, pin_node),
            'output':  (pin_node, track_node),
            }[pin.pin_class.direction.value]

        self.ids.add_edge(int(src_node.get("id")), int(sink_node.get("id")), int(switch.get("id")))

    def connect_track_to_track(self, xtrack, ytrack, switch, node_index=None):
        _bpin2node, track2node = node_index if node_index else self.index_node_objects()
        #pos = Position(ytrack.common, xtrack.common)

        # FIXME: assume for now there are already nodes there from previous step
        xtrack_node = track2node[xtrack]
        ytrack_node = track2node[ytrack]

        # Make bi directional
        self.ids.add_edge(int(xtrack_node.get("id")), int(ytrack_node.get("id")), int(switch.get("id")))
        self.ids.add_edge(int(ytrack_node.get("id")), int(xtrack_node.get("id")), int(switch.get("id")))

    def create_xy_track(self, start, end, segment, idx=None, type=None, direction=None):
        '''Create track object and corresponding nodes'''
        track = self.channels.create_xy_track(start, end, segment, idx=idx, type=type, direction=direction)
        track_node = self.ids.add_node_for_track(track)
        return track, track_node

    def index_node_objects(self):
        '''
        TODO: mithro suggests using node names instead of this. Look into making this happen
        That is, make it so that something like node_xml_str(pin_node) == node_obj_str(block, pin)
        Then lookup nodes using self.ids[node_obj_str(block, pin)]

        return pin2node, track2node
        pin2node: bpin2node[(Block instance, Pin instance)] => node ET
        track2node: Channel.Track to node

        >>> test_index_node_objects()
        '''
        # index pin and pin class associates
        # 'IPIN', 'OPIN', 'SINK', 'SOURCE', 'CHANX', 'CHANY'
        #pinclass2nodes = {}
        bpin2node = {}
        track2node = {}

        for node in self.ids._xml_nodes:
            if node.tag == ET.Comment:
                continue

            type = node.get('type')
            loc = node_loc(node)
            pos_low, pos_high = node_pos(node)
            ptc = int(loc.get('ptc'))

            if type in ('IPIN', 'OPIN'):
                assert pos_low == pos_high, (pos_low, pos_high)
                pos = pos_low

                # Lookup Block/<grid_loc>
                # ptc is the associated pin ptc value of the block_type
                block = self.block_grid[pos]
                pin = block.ptc2pin(ptc)
                kbp = (block, pin)
                assert kbp not in bpin2node
                bpin2node[kbp] = node
            elif type in ('SINK', 'SOURCE'):
                #pinclass2nodes
                pass
            elif type in ('CHANX', 'CHANY'):
                # ptc is the index of the track in the channels at that location
                # why is INC_DIR and segment needed?
                # can't those be looked up?
                grid = {'CHANX': self.channels.x, 'CHANY': self.channels.y}[type]
                #segment_id = list(node.iterfind("segment"))[0].get('segment_id')
                try:
                    track = grid[pos_low][ptc]
                except IndexError:
                    raise IndexError("%s node pos %s ptc %d not found" % (type, pos, ptc))
                assert track not in track2node
                track2node[track] = node
            else:
                assert False, type

        return bpin2node, track2node

    def to_xml(self):
        '''Return an ET object representing this rr_graph'''
        #et = ET.fromstring('<rr_graph tool_name="graph.py" tool_version="dev" tool_comment="Generated from black magic" />')
        #return et
        self.set_tooling("graph.py", "dev", "Generated from black magic")

        # <rr_nodes>, <rr_edges>, and <switches> should be good as is
        # note <rr_nodes> includes channel tracks, but not width definitions

        # FIXME: regenerate <block_types>
        # FIXME: regenerate <grid>

        self.channels.to_xml(self._xml_graph)

        return self._xml_graph

'''
Debug / test
'''

def simple_test_block_grid():
    bg = BlockGrid()

    # Create a block type with one input and one output pin
    bt = BlockType(graph=bg, id=0, name="DUALBLK")
    pci = PinClass(block_type=bt, direction=PinClassDirection.INPUT)
    pi = Pin(pin_class=pci, pin_class_index=0)
    pco = PinClass(block_type=bt, direction=PinClassDirection.OUTPUT)
    po = Pin(pin_class=pco, pin_class_index=0)

    # Create a block type with one input class with 4 pins
    bt = BlockType(graph=bg, id=1, name="INBLOCK")
    pci = PinClass(block_type=bt, direction=PinClassDirection.INPUT)
    Pin(pin_class=pci, pin_class_index=0)
    Pin(pin_class=pci, pin_class_index=1)
    Pin(pin_class=pci, pin_class_index=2)
    Pin(pin_class=pci, pin_class_index=3)

    # Create a block type with out input class with 2 pins
    bt = BlockType(graph=bg, id=2, name="OUTBLOK")
    pci = PinClass(block_type=bt, direction=PinClassDirection.OUTPUT)
    Pin(pin_class=pci, pin_class_index=0)
    Pin(pin_class=pci, pin_class_index=1)
    Pin(pin_class=pci, pin_class_index=2)
    Pin(pin_class=pci, pin_class_index=3)

    # Add some blocks
    bg.add_block(Block(graph=bg, block_type_id=1, position=Position(0,0)))
    bg.add_block(Block(graph=bg, block_type_id=1, position=Position(0,1)))
    bg.add_block(Block(graph=bg, block_type_id=1, position=Position(0,2)))
    bg.add_block(Block(graph=bg, block_type_id=1, position=Position(0,3)))

    bg.add_block(Block(graph=bg, block_type_id=0, position=Position(1,0)))
    bg.add_block(Block(graph=bg, block_type_id=0, position=Position(1,1)))
    bg.add_block(Block(graph=bg, block_type_id=0, position=Position(1,2)))
    bg.add_block(Block(graph=bg, block_type_id=0, position=Position(1,3)))

    bg.add_block(Block(graph=bg, block_type_id=0, position=Position(2,0)))
    bg.add_block(Block(graph=bg, block_type_id=0, position=Position(2,1)))
    bg.add_block(Block(graph=bg, block_type_id=0, position=Position(2,2)))
    bg.add_block(Block(graph=bg, block_type_id=0, position=Position(2,3)))

    bg.add_block(Block(graph=bg, block_type_id=2, position=Position(3,0)))
    bg.add_block(Block(graph=bg, block_type_id=2, position=Position(3,1)))
    bg.add_block(Block(graph=bg, block_type_id=2, position=Position(3,2)))
    bg.add_block(Block(graph=bg, block_type_id=2, position=Position(3,3)))

    return bg

def simple_test_graph(**kwargs):
    '''
    Simple block containing one input block, one output block, with some routing between them
    Can be used to implmenet a 2:1 mux
    '''
    xml_str = '''
            <rr_graph tool_name="vpr" tool_version="82a3c72" tool_comment="Based on my_arch.xml">
                <channels>
                    <channel chan_width_max="2" x_min="0" y_min="0" x_max="1" y_max="0"/>
                    <x_list index="0" info="1"/>
                    <y_list index="0" info="2"/>
                    <y_list index="1" info="2"/>
                </channels>
                <switches>
                    <switch id="0" name="my_switch" buffered="1">
                        <timing R="100" Cin="1233-12" Cout="123e-12" Tdel="1e-9"/>
                        <sizing mux_trans_size="2.32" buf_size="23.54"/>
                    </switch>
                </switches>
                <segments>
                    <segment id="0" name="L4">
                        <timing R_per_meter="201.7" C_per_meter="18.110e-15"/>
                    </segment>
                </segments>
                <block_types>
                    <block_type id="0" name="MYIN" width="1" height="1">
                        <pin_class type="INPUT">
                            <pin index="0" ptc="0">DATIN[0]</pin>
                        </pin_class>
                        <pin_class type="INPUT">
                            <pin index="0" ptc="1">DATIN[1]</pin>
                        </pin_class>
                    </block_type>
                    <block_type id="1" name="MYOUT" width="1" height="1">
                        <pin_class type="OUTPUT">
                            <pin index="0" ptc="0">IN[0]</pin>
                        </pin_class>
                    </block_type>
                </block_types>
                <grid>
                    <grid_loc x="0" y="0" block_type_id="0" width_offset="0" height_offset="0"/>
                    <grid_loc x="1" y="0" block_type_id="1" width_offset="0" height_offset="0"/>
                </grid>
                <rr_nodes>
                    <node id="0" type="SOURCE" capacity="1">
                        <loc xlow="0" ylow="0" xhigh="0" yhigh="0" ptc="0"/>
                        <timing R="0" C="0"/>
                    </node>
                    <node id="1" type="OPIN" capacity="1">
                        <loc xlow="0" ylow="0" xhigh="0" yhigh="0" ptc="0" side="RIGHT"/>
                    </node>
                    <node id="2" type="SOURCE" capacity="1">
                        <loc xlow="0" ylow="0" xhigh="0" yhigh="0" ptc="1"/>
                    </node>
                    <node id="3" type="OPIN" capacity="1">
                        <loc xlow="0" ylow="0" xhigh="0" yhigh="0" ptc="1" side="RIGHT"/>
                    </node>
                    <node id="4" type="SINK" capacity="1">
                        <loc xlow="1" ylow="0" xhigh="1" yhigh="0" ptc="0"/>
                    </node>
                    <node id="5" type="IPIN" capacity="1">
                        <loc xlow="1" ylow="0" xhigh="1" yhigh="0" ptc="0" side="LEFT"/>
                    </node>
                    <node id="6" type="CHANY" direction="INC_DIR" capacity="1">
                        <loc xlow="0" ylow="0" xhigh="0" yhigh="0" ptc="0"/>
                        <timing R="100" C="12e-12"/>
                        <segment segment_id="0"/>
                    </node>
                    <node id="7" type="CHANY" direction="DEC_DIR" capacity="1">
                        <loc xlow="0" ylow="0" xhigh="0" yhigh="0" ptc="1"/>
                        <segment segment_id="0"/>
                    </node>
                </rr_nodes>
                <rr_edges>
                    <edge src_node="0" sink_node="1" switch_id="0"/>
                    <edge src_node="2" sink_node="3" switch_id="0"/>
                    <edge src_node="4" sink_node="5" switch_id="0"/>
                    <edge src_node="1" sink_node="6" switch_id="0"/>
                    <edge src_node="3" sink_node="7" switch_id="0"/>
                    <edge src_node="0" sink_node="6" switch_id="0"/>
                    <edge src_node="6" sink_node="5" switch_id="0"/>
                    <edge src_node="7" sink_node="5" switch_id="0"/>
                </rr_edges>
            </rr_graph>
            '''
    return Graph(io.StringIO(xml_str), **kwargs)

def test_add_nodes_for_block(ret=False):
    g = simple_test_graph(verbose=False)
    g.ids.clear_graph()
    switch = g.ids.add_switch('SPST', buffered=1)
    for block in g.block_grid:
        g.ids.add_nodes_for_block(block, switch)
    '''
    2 input pins, 1 output pin
    Should have added 3 edges to connect edge to pin
    Ande one PIN node + one NET node
    '''
    assert len(g.ids._xml_edges) == 3
    assert len(g.ids._xml_nodes) == 6
    if ret:
        return g

'''
mcmaster: strongly dislike doctest
Preparing this for a port to unittest
'''

def test_nodes_for_edges():
    g = test_add_nodes_for_block(True)
    # Each edge should connect a net to a pin
    for edge in g.ids._xml_edges:
        assert len(g.ids.nodes_for_edge(edge)) == 2

def node_ptc(node):
    locs = list(node.iterfind("loc"))
    assert len(locs) == 1, locs
    loc = locs[0]
    return int(loc.get('ptc'))

def test_index_node_objects():
    g = simple_test_graph(verbose=False)

    bpin2node, track2node= g.index_node_objects()

    # 3 pins in this design
    assert len(bpin2node) == 3
    for (block, pin), node in bpin2node.items():
        assert pin.ptc == node_ptc(node)

        bpos_lo, bpos_hi = node_pos(node)
        assert bpos_lo == bpos_hi
        assert bpos_lo == block.position, (bpos_lo, block.position)

    # 2 y tracks, no x tracks
    assert len(track2node) == 2, len(track2node)
    for track, node in track2node.items():
        assert track.idx == node_ptc(node)

def print_block_types(rr_graph):
    '''Sequentially list block types'''
    bg = rr_graph.block_grid

    for type_id, bt in bg.block_types.items():
        print("{:4}  ".format(type_id), "{:40s}".format(bt.to_string()), bt.to_string(extra=True))

def print_grid(rr_graph):
    '''ASCII diagram displaying XY layout'''
    bg = rr_graph.block_grid
    grid = bg.size()

    #print('Grid %dw x %dh' % (grid.width, grid.height))
    col_widths = []
    for x in range(0, grid.width):
        col_widths.append(max(len(bt.name) for bt in bg.block_types_for(col=x)))

    print("    ", end=" ")
    for x in range(0, grid.width):
        print("{: ^{width}d}".format(x, width=col_widths[x]), end="   ")
    print()

    print("   /", end="-")
    for x in range(0, grid.width):
        print("-"*col_widths[x], end="-+-")
    print()

    for y in reversed(range(0, grid.height)):
        print("{: 3d} |".format(y, width=col_widths[0]), end=" ")
        for x, bt in enumerate(bg.block_types_for(row=y)):
            assert x < len(col_widths), (x, bt)
            print("{: ^{width}}".format(bt.name, width=col_widths[x]), end=" | ")
        print()

def print_nodes(rr_graph, lim=None):
    '''Display source/sink edges on all XML nodes'''
    ids = rr_graph.ids
    print('Nodes: {}, edges {}'.format(len(ids._xml_nodes), len(ids._xml_edges)))
    for nodei, node in enumerate(ids._xml_nodes):
        print()
        if lim and nodei >= lim:
            print('...')
            break
        #print(nodei)
        #ET.dump(node)
        print('{} ({})'.format(ids.node_name(node), node.get("id")))
        srcs = []
        snks = []
        for e in ids.edges_for_node(node):
            src, snk = ids.nodes_for_edge(e)
            if src == node:
                srcs.append(e)
            elif snk == node:
                snks.append(e)
            else:
                print("!?@", ids.edge_name(e))

        print("  Sources:")
        for e in srcs:
            print("   ", ids.edge_name(e))
        if not srcs:
            print("   ", None)

        print("  Sink:")
        for e in snks:
            print("   ", ids.edge_name(e, flip=True))
        if not snks:
            print("   ", None)

def print_graph(rr_graph, verbose=False, lim=10):
    if verbose:
        lim=0

    print()
    print_block_types(rr_graph)
    print()
    print_grid(rr_graph)
    print()
    print_nodes(rr_graph, lim=lim)
    print()

def main():
    import os
    if len(sys.argv) == 1 or not os.path.exists(sys.argv[-1]):
        import doctest
        print('Doctest begin')
        doctest.testmod()
        print('Doctest end')
    else:
        g = Graph(rr_graph_file=sys.argv[-1])
        print_graph(g, verbose=True)

if __name__ == "__main__":
    main()

