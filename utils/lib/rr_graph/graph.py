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
from ..asserts import assert_type_or_none


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
        assert pins is not None, pins

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
            for p in pins:
                self._add_pin(p)

    @classmethod
    def from_xml(cls, block_type, pin_class_node):
        """

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
        assert_eq(pin.block_type_name, self.name)

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

    @property
    def x(self):
        return self.position.x

    @property
    def y(self):
        return self.position.y

    @classmethod
    def from_xml(cls, graph, grid_loc_node):
        """
        >>> g = BlockGraph()
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


class BlockGraph:

    def __init__(self):
        self.block_grid = {}
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

    def block_grid_size(self):
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

    def __getitem__(self, pos):
        return self.block_grid[pos]


def simple_test_graph():
    bg = BlockGraph()

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
    def __init__(self, block_graph, xml_graph=None):
        assert_type(block_graph, BlockGraph)

        # Mapping dictionaries
        self.globalname2id  = {}
        self.id2node = {'node': {}, 'edge': {}}

        self._block_graph = block_graph

        if xml_graph is None:
            xml_graph = ET.Element("rr_graph")
            ET.SubElement(xml_graph, "rr_nodes")
            ET.SubElement(xml_graph, "rr_edges")
        self._xml_graph = xml_graph

        for node in self._xml_nodes:
            self.add_node(node)

    def _next_id(self, xml_group):
        return len(self.id2node[xml_group])

    def check(self):
        # Make sure all the global names mappings are same size.
        assert len(self.globalname2ids) == sum(len(v) for v in self.id2node.values())

    @property
    def _xml_nodes(self):
        nodes = list(self._xml_graph.iterfind("rr_nodes"))
        assert len(nodes) == 1, nodes
        return nodes[0]

    @property
    def _xml_edges(self):
        edges = list(self._xml_graph.iterfind("rr_edges"))
        assert len(edges) == 1, edges
        return edges[0]

    def _xml_group(self, xml_node):
        assert xml_node.tag in self.id2node, (
            "Object type of {!r} is not valid ({}).".format(
                xml_node.tag, ", ".join(self.id2node.keys())))
        return xml_node.tag

    def add_node(self, xml_node):
        name = self.node_name(xml_node)
        self[name] = xml_node

    def __getitem__(self, globalname):
        xml_group, node_id = self.globalnames2id[globalname]
        return self.id2node[xml_group][node_id]

    def __setitem__(self, globalname, xml_node):
        xml_group = self._xml_group(xml_node)

        node_id = xml_node.get('id', None)
        if node_id is None:
            node_id = len(self.id2node[xml_group])

        parent_xml = getattr(self, "_xml_{}s".format(xml_group))
        #assert obj in list(parent_xml)
        #parent_xml.append(obj)

        if globalname in self.globalname2id:
            assert_eq(self.globalname2id[globalname], node_id)
            assert obj is self.id2node[node_id]

        self.id2node[xml_group][node_id] = xml_node
        self.globalname2id[globalname] = node_id

    def node_name(self, xml_node):
        """Get a globally unique name for an `node` in the rr_nodes.

        >>> 
        >>> bg = simple_test_graph()
        >>> m = GraphIdsMap(block_graph=bg)
        >>> 
        >>> m.node_name(ET.fromstring('''
        ... <node id="0" type="SINK" capacity="1">
        ...   <loc xlow="0" ylow="3" xhigh="0" yhigh="3" ptc="0"/>
        ...   <timing R="0" C="0"/>
        ... </node>
        ... '''))
        'INBLOCK_X000Y003/IDX[00]/NODE/<-'
        >>> m.node_name(ET.fromstring('''
        ... <node id="1" type="SOURCE" capacity="1">
        ...   <loc xlow="1" ylow="2" xhigh="1" yhigh="2" ptc="1"/>
        ...   <timing R="0" C="0"/>
        ... </node>
        ... '''))
        'DUALBLK_X001Y002/IDX[01]/NODE/->'
        >>> m.node_name(ET.fromstring('''
        ... <node id="2" type="IPIN" capacity="1">
        ...   <loc xlow="2" ylow="1" xhigh="2" yhigh="1" side="TOP" ptc="0"/>
        ...   <timing R="0" C="0"/>
        ... </node>
        ... '''))
        'DUALBLK_X002Y001/IDX[00]/IPIN/T<'
        >>> m.node_name(ET.fromstring('''
        ... <node id="6" type="OPIN" capacity="1">
        ...   <loc xlow="3" ylow="0" xhigh="3" yhigh="0" side="RIGHT" ptc="1"/>
        ...   <timing R="0" C="0"/>
        ... </node>
        ... '''))
        'OUTBLOK_X003Y000/IDX[01]/OPIN/R>'
        >>> m.node_name(ET.fromstring('''
        ... <node capacity="1" direction="INC_DIR" id="372" type="CHANX">
        ...   <loc ptc="4" xhigh="3" xlow="3" yhigh="0" ylow="0"/>
        ...   <timing C="2.72700004e-14" R="101"/>
        ...   <segment segment_id="1"/>
        ... </node>
        ... '''))
        'OUTBLOK_X003Y000--[04]->X003Y000_OUTBLOK'
        >>> m.node_name(ET.fromstring('''
        ... <node capacity="1" direction="DEC_DIR" id="373" type="CHANY">
        ...   <loc ptc="5" xhigh="3" xlow="3" yhigh="0" ylow="0"/>
        ...   <timing C="2.72700004e-14" R="101"/>
        ...   <segment segment_id="1"/>
        ... </node>
        ... '''))
        'OUTBLOK_X003Y000<|[05]||X003Y000_OUTBLOK'

        'BT_X002Y003[000]-T-PIN<'
        'BT_X002Y003[000]-L-PIN<'
        'BT_X002Y003[000]-R-PIN<'
        'BT_X002Y003[000]-B-PIN<'
        'BT_X002Y003[000]-SINK-<'
        'BT_X002Y003[000]-SRC-->'
        'BT_X002Y003[000]-T-PIN>'
        'BT_X002Y003[000]-L-PIN>'
        'BT_X002Y003[000]-R-PIN>'
        'BT_X002Y003[000]-B-PIN>'

        'BT_X003Y000--[05]->X003Y000_BT'
        'BT_X003Y000<-[05]--X003Y000_BT'

        'BT_X003Y000||[05]|>X003Y000_BT'
        'BT_X003Y000<|[05]||X003Y000_BT'
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
            direction = {
                'INC_DIR': '{f}{f}[{ptc:02d}]{f}>',
                'DEC_DIR': '<{f}[{ptc:02d}]{f}{f}',
            }[xml_node.attrib.get("direction")]

            block_from = self._block_graph[low]
            block_to   = self._block_graph[high]
            return "{}_X{:03d}Y{:03d}{}X{:03d}Y{:03d}_{}".format(
                block_from.block_type.name, block_from.x, block_from.y,
                direction.format(f={RRNodeType.channel_x: '-', RRNodeType.channel_y: '|'}[node_type], ptc=ptc),
                block_to.x, block_to.y, block_to.block_type.name)
        elif node_type is RRNodeType.input_class:
            type_str = "NODE/<-"
            # FIXME: Check high == block.position + block.block_type.size
        elif node_type is RRNodeType.output_class:
            type_str = "NODE/->"
            # FIXME: Check high == block.position + block.block_type.size
        elif node_type is RRNodeType.input_pin:
            assert edge in "TLRB", edge
            type_str = "IPIN/{}<".format(edge)
        elif node_type is RRNodeType.output_pin:
            assert edge in "TLRB", edge
            type_str = "OPIN/{}>".format(edge)
        else:
            assert False, "Unknown node_type {}".format(node_type)
        assert type_str

        block = self._block_graph[low]

        return "{}_X{:03d}Y{:03d}/IDX[{:02d}]/{}".format(
            block.block_type.name, block.position.x, block.position.y, ptc, type_str)

    def edge_name(self, xml_node):
        """Get a globally unique name for an `edge` in the rr_edges.

        An edge goes between two `node` objects.

        >>> bg = simple_test_graph()
        >>> xml_string1 = '''
        ... <rr_graph>
        ...  <rr_nodes>
        ...   <node id="0" type="SINK" capacity="1">
        ...     <loc xlow="0" ylow="3" xhigh="0" yhigh="3" ptc="0"/>
        ...     <timing R="0" C="0"/>
        ...   </node>
        ...   <node capacity="1" direction="DEC_DIR" id="1" type="CHANY">
        ...     <loc ptc="5" xhigh="3" xlow="3" yhigh="0" ylow="0"/>
        ...     <timing C="2.72700004e-14" R="101"/>
        ...     <segment segment_id="1"/>
        ...   </node>
        ...  </rr_nodes>
        ... </rr_graph>
        ... '''
        >>> m = GraphIdsMap(block_graph=bg, xml_graph=ET.fromstring(xml_string1))
        >>> m.edge_name(ET.fromstring('''
        ... <edge sink_node="0" src_node="1" switch_id="1"/>
        ... '''))
        'OUTBLOK_X003Y000<|[05]||X003Y000_OUTBLOK->>-INBLOCK_X000Y003/IDX[00]/NODE/<-'
        """
        assert xml_node.tag == 'edge'

        id2node = self.id2node['node']

        snk_node_id = xml_node.attrib.get("sink_node")
        src_node_id = xml_node.attrib.get("src_node")

        assert snk_node_id in id2node, snk_node_id
        assert src_node_id in id2node, src_node_id

        return "{}->>-{}".format(self.node_name(id2node[src_node_id]), self.node_name(id2node[snk_node_id]))


## class RRNode:
##     @classmethod
##     def from_pin(cls, block, pin):
##         """ Creates an IPIN/OPIN from `class Pin` object. """
## 
##         assert_type(block, Block)
##         assert_type(pin, Pin)
##         assert_type(pin.pin_class, PinClass)
##         assert_type(pin.pin_class.block_type, BlockType)
## 
##         low = pin_class.block_type.position
##         return RRNode(id, low, low, pin)
## 
##     @classmethod
##     def from_pin_class(cls, block, pin_class):
##         """ Creates a SOURCE or SINK node from a `class PinClass` object. """
##         assert_type(block, Block)
##         assert_type(pin_class, PinClass)
##         assert_type(pin_class.block_type, BlockType)
## 
##         low = block.position
##         high = block.position + pin_class.block_type.size
## 
##         obj = RRNode(self, low, high, 0, timing=timing)
##         return obj
## 
##     @classmethod
##     def from_block(cls, block):
##         """
##         Creates the SOURCE/SINK nodes for each pin class
##         Creates the IPIN/OPIN nodes for each pin inside a pin class.
##         """
##         nodes = []
##         for pc in block.block_type.pin_classes:
##             nodes.append(cls.from_pin_class(block, pc))
##             for p in pc.pins:
##                nodes.append(cls.from_pin(block, p))
##         return nodes


class Graph:
    def __init__(self, rr_graph_file=None):
        # Read in existing file
        if rr_graph_file:
            self.block_graph = BlockGraph()
            self._xml_graph = ET.parse(rr_graph_file)
            self.import_block_types()
            self.import_grid()
        else:
            self._xml_graph = ET.Element("rr_graph")
            ET.SubElement(self._xml_graph, "rr_nodes")
            ET.SubElement(self._xml_graph, "rr_edges")

        self.ids = GraphIdsMap(self)

        #self.grid = {}
        #self.channels = Channels()

    def clear_graph(self):
        """Delete the existing nodes and edges."""
        self._xml_nodes.clear()
        self._xml_edges.clear()

    def import_block_types(self):
        # Create in the block_types information
        for block_type in self._xml_graph.iterfind("./block_types/block_type"):
            BlockType.from_xml(self.block_graph, block_type)

    def import_grid(self):
        self.grid = {}
        for block_xml in self._xml_graph.iterfind("./grid/grid_loc"):
            Block.from_xml(self.block_graph, block_xml)

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
    import os
    if len(sys.argv) == 1 or not os.path.exists(sys.argv[-1]):
        import doctest
        doctest.testmod()
    else:
        rr_graph = Graph(rr_graph_file=sys.argv[-1])
        import pprint


        bg = rr_graph.block_graph

        print()
        for type_id, bt in bg.block_types.items():
            print("{:4}  ".format(type_id), "{:40s}".format(bt.to_string()), bt.to_string(extra=True))
        print()

        grid = bg.block_grid_size()

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
            print("{: 2d} |".format(y, width=col_widths[0]), end=" ")
            for x, bt in enumerate(bg.block_types_for(row=y)):
                assert x < len(col_widths), (x, bt)
                print("{: ^{width}}".format(bt.name, width=col_widths[x]), end=" | ")
            print()
        print()
