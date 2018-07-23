#!/usr/bin/env python3
"""
rr_graph docs: http://docs.verilogtorouting.org/en/latest/vpr/file_formats/
etree docs: http://lxml.de/api/lxml.etree-module.html

general philosophy
Data structures should generally be conceptual objects rather than direct XML manipulation
Generally one class per XML node type
However, RRGraph is special cased, operating on XML directly and holding

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
class RoutingGraph:
    holds pins + edges
    xml: updated as pins are added
        inconsistent with the rest of the project
    However, outside generally only add pins through objects
    so they don't see the XML directly
    except print does iterate directly over the XML
class Graph:
    Top level class holding everything together has

enums
class BlockTypeEdge(enum.Enum):
    lightweight enum type
class PinClassDirection(enum.Enum):
    lightweight enum type

XXX: parse comments? Maybe can do a pass removing them
"""

import enum
import io
import re

from collections import namedtuple
from types import MappingProxyType

import lxml.etree as ET

from . import Position
from . import P
from . import Size
from . import Offset
from . import node_pos, single_element
from .channel import Channels, Track

from ..asserts import assert_eq
from ..asserts import assert_is
from ..asserts import assert_type
from ..asserts import assert_type_or_none

from ..collections_extra import MostlyReadOnly


_DEFAULT_MARKER = []


def dict_next_id(d):
    current_ids = [-1] + list(d.keys())
    return max(current_ids) + 1


def parse_net(
        s,
        _r=re.compile(
            "^(.*\\.)?([^.\\[]*[^0-9\\[.]+[^.\\[]*)?(\\[([0-9]+|[0-9]+:[0-9]+)]|[0-9]+|)$"
        )):
    """
    Parses a Verilog/Verilog-To-Routing net/port definition.

    The general form of this net/port definition is;

       block_name.portname[startpin:endpin]

    Almost all parts of the definition are optional. See the examples below.

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
        assert_eq(len(pin_full), len(pin_idx) + 2)

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

    Attributes
    ----------

    port_name : string

    port_index : int

    block_type_name : string
    block_type_subblk : int
        When a block has `capacity > 1` there are multiple "subblocks"
        contained.

    block_type_index : int
        Starts at 0 within a block and increments for each pin.
        Equal to the ptc property in the rr_graph XML.

    ptc : int
        Alias for block_type_index

    direction : PinClassDirection
        If the pin is an clock, input or output.

    side : RoutingNodeSide
        Side of the block the pin is found on.
    """

    __slots__ = [
        "_pin_class",
        "_port_name",
        "_port_index",
        "_block_type_name",
        "_block_type_subblk",
        "_block_type_index",
        "_side",
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
    def block_type_fullname(self):
        bt_name = None
        if self.block_type_name is not None:
            bt_name = self.block_type_name
        elif self.pin_class is not None:
            bt_name = self.pin_class.block_type_name
        if bt_name and self.block_type_subblk is not None:
            return "{}[{}]".format(bt_name, self.block_type_subblk)
        return bt_name

    @property
    def name(self):
        """<portname>[<port_index>]"""
        assert_type(self._port_name, str,
                "Pin doesn't have port_name {}".format(repr(self)))
        assert_type(self._port_index, int,
                "Pin doesn't have port_index {}".format(repr(self)))
        return "{}[{}]".format(self.port_key, self._port_index)

    @property
    def port_key(self):
        if self.block_type_subblk is not None:
            return "[{}]{}".format(self.block_type_subblk, self.port_name)
        else:
            return self.port_name

    @property
    def xmlname(self):
        """Give name as originally in the XML. <block_type_name>.<name>"""
        return "{}.{}".format(self.block_type_name, self.name)

    def __init__(self,
                 pin_class=None,
                 port_name=None,
                 port_index=None,
                 block_type_name=None,
                 block_type_subblk=None,
                 block_type_index=None,
                 side=None):

        assert_type_or_none(pin_class, PinClass)

        assert_type_or_none(port_name, str)
        assert_type_or_none(port_index, int)

        assert_type_or_none(block_type_name, str)
        assert_type_or_none(block_type_subblk, int)
        assert_type_or_none(block_type_index, int)

        assert_type_or_none(side, RoutingNodeSide)

        self._pin_class = pin_class
        self._port_name = port_name
        self._port_index = port_index
        self._block_type_name = block_type_name
        self._block_type_subblk = block_type_subblk
        self._block_type_index = block_type_index
        self._side = side

        if pin_class is not None:
            pin_class._add_pin(self)

    def __str__(self):
        return "{}({})->{}[{}]".format(self.block_type_fullname,
                                       self.block_type_index, self.port_name,
                                       self.port_index)

    @classmethod
    def from_text(cls,
                  pin_class,
                  text,
                  block_type_index=None):
        """Create a Pin object from a textual pin string.

        Parameters
        ----------
        pin_class : PinClass

        text : str
            Textual pin definition

        block_type_index : int or None, optional

        Examples
        ----------

        >>> pin = Pin.from_text(None, '0')
        >>> pin
        Pin(pin_class=None, port_name=None, port_index=None, block_type_name=None, block_type_subblk=None, block_type_index=0, side=None)
        >>> str(pin)
        'None(0)->None[None]'

        >>> pin = Pin.from_text(None, '10')
        >>> pin
        Pin(pin_class=None, port_name=None, port_index=None, block_type_name=None, block_type_subblk=None, block_type_index=10, side=None)
        >>> str(pin)
        'None(10)->None[None]'

        >>> pin = Pin.from_text(None, 'bt.outpad[2]')
        >>> pin
        Pin(pin_class=None, port_name='outpad', port_index=2, block_type_name='bt', block_type_subblk=None, block_type_index=None, side=None)
        >>> str(pin)
        'bt(None)->outpad[2]'

        >>> pin = Pin.from_text(None, 'bt[3].outpad[2]')
        >>> pin
        Pin(pin_class=None, port_name='outpad', port_index=2, block_type_name='bt', block_type_subblk=3, block_type_index=None, side=None)
        >>> str(pin)
        'bt[3](None)->outpad[2]'

        """
        assert_type(text, str)
        block_type_name, port_name, pins = parse_net(text.strip())
        assert pins is not None, text.strip()

        if block_type_name and '[' in block_type_name:
            _, block_type_name, (block_type_subblk,) = parse_net(block_type_name.strip())
        else:
            block_type_subblk = None

        assert_eq(len(pins), 1)
        if block_type_index is None and port_name is None:
            block_type_index = pins[0]
            port_index = None
        else:
            port_index = pins[0]

        return cls(
            pin_class=pin_class,
            port_name=port_name,
            port_index=port_index,
            block_type_name=block_type_name,
            block_type_subblk=block_type_subblk,
            block_type_index=block_type_index,
        )

    @classmethod
    def from_xml(cls, pin_class, pin_node):
        """Create a Pin object from an XML rr_graph node.

        Parameters
        ----------
        pin_class : PinClass

        pin_node : ET._Element
            An `<pin>` XML node from an rr_graph.

        Examples
        ----------
        >>> pc = PinClass(BlockType(name="bt"), direction=PinClassDirection.INPUT)
        >>> xml_string = '<pin ptc="1">bt.outpad[2]</pin>'
        >>> pin = Pin.from_xml(pc, ET.fromstring(xml_string))
        >>> pin
        Pin(pin_class=PinClass(), port_name='outpad', port_index=2, block_type_name='bt', block_type_subblk=None, block_type_index=1, side=None)
        >>> str(pin)
        'bt(1)->outpad[2]'
        >>> pin.ptc
        1
        """
        assert pin_node.tag == "pin"
        block_type_index = int(pin_node.attrib["ptc"])

        return cls.from_text(
            pin_class,
            pin_node.text.strip(),
            block_type_index=block_type_index)


class PinClassDirection(enum.Enum):
    INPUT = "input"
    OUTPUT = "output"
    CLOCK = "clock"
    UNKNOWN = "unknown"

    def __repr__(self):
        return repr(self.value)

    def __str__(self):
        return str(enum.Enum.__str__(self)).replace("PinClassDirection", "PCD")


class PinClass(MostlyReadOnly):
    """

    All pins inside a pin class are equivalent.

    ie same net. Would a LUT with swappable inputs count?
    For <pin_class> nodes

    A PinClass turns into one SOURCE (when direction==OUTPUT) or SINK (when
    direction in (INPUT, CLOCK)) per each block.

    Attributes
    ----------
    block_type : BlockType

    direction : PinClassDirection

    pins : tuple of Pin
        Pin inside this PinClass object. Useful for doing `for p in pc.pins`.

    port_name : str
        Name of the port this PinClass represents. In the form of;
            port_name[pin_idx]
            port_name[pin_idx:pin_idx]

    block_type_name : str
    """

    __slots__ = ["_block_type", "_direction", "_pins"]

    @property
    def port_name(self):
        """
        >>> bg = BlockGrid()
        >>> bt = BlockType(g=bg, id=0, name="B")
        >>> c1 = PinClass(block_type=bt, direction=PinClassDirection.OUTPUT)
        >>> c2 = PinClass(block_type=bt, direction=PinClassDirection.OUTPUT)
        >>> c3 = PinClass(block_type=bt, direction=PinClassDirection.OUTPUT)
        >>> p0 = Pin(pin_class=c1, port_name="P1", port_index=0)
        >>> p1 = Pin(pin_class=c2, port_name="P1", port_index=1)
        >>> p2 = Pin(pin_class=c2, port_name="P1", port_index=2)
        >>> p3 = Pin(pin_class=c2, port_name="P1", port_index=3)
        >>> p4 = Pin(pin_class=c3, port_name="P2", port_index=0)
        >>> c1.port_name
        'P1[0]'
        >>> c2.port_name
        'P1[3:1]'
        >>> c3.port_name
        'P2[0]'
        """
        port_indexes = [p.port_index for p in self.pins]
        pin_start = min(port_indexes)
        pin_end = max(port_indexes)
        assert_eq(port_indexes, list(range(pin_start, pin_end+1)))
        if pin_start == pin_end:
            return "{}[{}]".format(self.pins[0].port_name, pin_end)
        return "{}[{}:{}]".format(self.pins[0].port_name, pin_end, pin_start)

    @property
    def block_type_name(self):
        if self.block_type is None:
            return None
        return self.block_type.name

    def __init__(self, block_type=None, direction=None, pins=None):
        assert_type_or_none(block_type, BlockType)
        assert_type_or_none(direction, PinClassDirection)

        self._block_type = block_type
        self._direction = direction
        # Although pins within a pin class have no defined order,
        # preserve input XML ordering for consistency
        self._pins = []

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
        ...   <pin ptc="2">bt.outpad[3]</pin>
        ...   <pin ptc="3">bt.outpad[4]</pin>
        ... </pin_class>
        ... '''
        >>> pc = PinClass.from_xml(bt, ET.fromstring(xml_string1))
        >>> pc # doctest: +ELLIPSIS
        PinClass(block_type=BlockType(), direction='input', pins=[...])
        >>> len(pc.pins)
        2
        >>> pc.pins[0]
        Pin(pin_class=PinClass(), port_name='outpad', port_index=3, block_type_name='bt', block_type_subblk=None, block_type_index=2, side=None)
        >>> pc.pins[1]
        Pin(pin_class=PinClass(), port_name='outpad', port_index=4, block_type_name='bt', block_type_subblk=None, block_type_index=3, side=None)
        >>> for p in pc.pins:
        ...   print("{}[{}]".format(p.port_name, p.port_index))
        outpad[3]
        outpad[4]
        >>> pc.port_name
        'outpad[4:3]'

        >>> bt = BlockType(name="a")
        >>> xml_string2 = '''
        ... <pin_class type="INPUT">
        ...   <pin ptc="0">a.b[1]</pin>
        ... </pin_class>
        ... '''
        >>> pc = PinClass.from_xml(bt, ET.fromstring(xml_string2))
        >>> pc # doctest: +ELLIPSIS
        PinClass(block_type=BlockType(), direction='input', pins=[...])
        >>> len(pc.pins)
        1
        >>> pc.pins[0]
        Pin(pin_class=PinClass(), port_name='b', port_index=1, block_type_name='a', block_type_subblk=None, block_type_index=0, side=None)

        >>> bt = BlockType(name="a")
        >>> xml_string3 = '''
        ... <pin_class type="OUTPUT">
        ...   <pin ptc="2">a.b[5]</pin>
        ...   <pin ptc="3">a.b[6]</pin>
        ...   <pin ptc="4">a.b[7]</pin>
        ... </pin_class>
        ... '''
        >>> pc = PinClass.from_xml(bt, ET.fromstring(xml_string3))
        >>> pc # doctest: +ELLIPSIS
        PinClass(block_type=BlockType(), direction='output', pins=[...])
        >>> len(pc.pins)
        3
        >>> pc.pins[0]
        Pin(pin_class=PinClass(), port_name='b', port_index=5, block_type_name='a', block_type_subblk=None, block_type_index=2, side=None)
        >>> pc.pins[1]
        Pin(pin_class=PinClass(), port_name='b', port_index=6, block_type_name='a', block_type_subblk=None, block_type_index=3, side=None)
        >>> pc.pins[2]
        Pin(pin_class=PinClass(), port_name='b', port_index=7, block_type_name='a', block_type_subblk=None, block_type_index=4, side=None)
        """
        assert_eq(pin_class_node.tag, "pin_class")
        assert "type" in pin_class_node.attrib
        class_direction = getattr(PinClassDirection,
                                  pin_class_node.attrib["type"])
        assert_type(class_direction, PinClassDirection)

        pc_obj = cls(block_type, class_direction)

        pin_nodes = list(pin_class_node.iterfind("./pin"))
        # Old format with pins described in text field
        if len(pin_nodes) == 0:
            for n in pin_class_node.text.split():
                pc_obj._add_pin(Pin.from_text(pc_obj, n))
        # New format using XML nodes
        else:
            for pin_node in pin_nodes:
                pc_obj._add_pin(Pin.from_xml(pc_obj, pin_node))

        return pc_obj

    def __str__(self):
        return "{}.PinClass({}, [{}])".format(
            self.block_type_name,
            self.direction,
            ", ".join(str(i) for i in sorted(self.pins)),
        )

    def _add_pin(self, pin):
        assert_type(pin, Pin)

        # PinClass.from_xml() and Pin.from_xml() both call add_pin
        if pin in self._pins:
            return

        # Verify the pin has matching properties.
        # --------------------------------------------
        if pin.pin_class is not None:
            assert_eq(pin.pin_class, self)

        #if pin.port_name is not None:
        #    assert_eq(pin.port_name, self.port_name)

        #if pin.port_index is not None:
        #    assert_not_in(pin.port_index, self.ports_index)

        if pin.block_type_name is not None:
            assert_eq(pin._block_type_name, self.block_type_name)

        # Fill out any unset properties
        # --------------------------------------------
        if pin.pin_class is None:
            pin._pin_class = self

        self._pins.append(pin)

        #if pin.port_name is None:
        #    pin._port_name = self.port_name

        #if pin.port_index is None:
        #    pin._port_index = dict_next_id(self.block_type._ports[self.port_name])

        if pin.block_type_name is None:
            pin._block_type_name = self.block_type_name

        if self.block_type is not None:
            self.block_type._add_pin(pin)


class BlockType(MostlyReadOnly):
    """
    For <block_type> nodes

    Attributes
    ----------
    graph : Graph

    id : int

    name : str
        Name of the block type.

    size : Size
        Size of the block type, default is `Size(1, 1)`.

    pin_classes : tuple of PinClass
        Pin classes that this block contains.

    pins_index : mapping[int] -> Pin
        ptc value to pin mapping.

    ports_index : mapping[str] -> mapping[int] -> Pin

    pins : tuple of Pin
        List of pins on this BlockType.

    ports : tuple of str
        List of ports on this BlockType.
    """

    @property
    def pins(self):
        return tuple(self._pins_index.values())

    @property
    def ports(self):
        return tuple(self._ports_index.keys())

    @property
    def positions(self):
        for x in range(0, self.size.width):
            for y in range(0, self.size.height):
                yield Offset(x, y)


    __slots__ = [
        "_graph", "_id", "_name", "_size",
        "_pin_classes", "_pins_index",
        "_ports_index",
    ]

    def __init__(self,
                 g=None,
                 id=-1,
                 name="",
                 size=Size(1, 1),
                 pin_classes=None):
        assert_type_or_none(g, BlockGrid)
        assert_type_or_none(id, int)
        assert_type_or_none(name, str)
        assert_type_or_none(size, Size)

        self._graph = g
        self._id = id
        self._name = name
        self._size = size

        self._pin_classes = []
        self._pins_index = {}
        self._ports_index = {}
        if pin_classes is not None:
            for pc in pin_classes:
                self._add_pin_class(pc)

        if g is not None:
            g.add_block_type(self)

    def to_string(self, extra=False):
        if not extra:
            return "BlockType({name})".format(name=self.name)
        else:
            return "in 0x{graph_id:x} (pin_classes=[{pin_class_num} classes] pins_index=[{pins_index_num} pins])".format(
                graph_id=id(self._graph),
                pin_class_num=len(self.pin_classes),
                pins_index_num=len(self.pins_index))

    @classmethod
    def from_xml(cls, g, block_type_node):
        """

        >>> xml_string = '''
        ... <block_type id="1" name="BLK_BB-VPR_PAD" width="2" height="3">
        ...   <pin_class type="OUTPUT">
        ...     <pin ptc="0">BLK_BB-VPR_PAD.outpad[0]</pin>
        ...   </pin_class>
        ...   <pin_class type="OUTPUT">
        ...     <pin ptc="1">BLK_BB-VPR_PAD.outpad[1]</pin>
        ...   </pin_class>
        ...   <pin_class type="INPUT">
        ...     <pin ptc="2">BLK_BB-VPR_PAD.inpad[0]</pin>
        ...   </pin_class>
        ... </block_type>
        ... '''
        >>> bt = BlockType.from_xml(None, ET.fromstring(xml_string))
        >>> bt # doctest: +ELLIPSIS
        BlockType(graph=None, id=1, name='BLK_BB-VPR_PAD', size=Size(w=2, h=3), pin_classes=[...], pins_index={...})
        >>> len(bt.pin_classes)
        3
        >>> bt.pin_classes[0].direction
        'output'
        >>> bt.pin_classes[0] # doctest: +ELLIPSIS
        PinClass(block_type=BlockType(), direction='output', pins=[...])
        >>> bt.pin_classes[0].pins[0]
        Pin(pin_class=PinClass(), port_name='outpad', port_index=0, block_type_name='BLK_BB-VPR_PAD', block_type_subblk=None, block_type_index=0, side=None)
        >>> bt.pin_classes[1].direction
        'output'
        >>> bt.pin_classes[1].pins[0]
        Pin(pin_class=PinClass(), port_name='outpad', port_index=1, block_type_name='BLK_BB-VPR_PAD', block_type_subblk=None, block_type_index=1, side=None)
        >>> bt.pin_classes[2].direction
        'input'
        >>> bt.pin_classes[2].pins[0]
        Pin(pin_class=PinClass(), port_name='inpad', port_index=0, block_type_name='BLK_BB-VPR_PAD', block_type_subblk=None, block_type_index=2, side=None)

        Multiple pins in a single pinclass.
        >>> xml_string = '''
        ... <block_type id="1" name="BLK_BB-VPR_PAD" width="2" height="3">
        ...   <pin_class type="OUTPUT">
        ...     <pin ptc="0">BLK_BB-VPR_PAD.outpad[0]</pin>
        ...     <pin ptc="1">BLK_BB-VPR_PAD.outpad[1]</pin>
        ...   </pin_class>
        ...   <pin_class type="INPUT">
        ...     <pin ptc="2">BLK_BB-VPR_PAD.inpad[0]</pin>
        ...   </pin_class>
        ... </block_type>
        ... '''
        >>> bt = BlockType.from_xml(None, ET.fromstring(xml_string))
        >>> bt # doctest: +ELLIPSIS
        BlockType(graph=None, id=1, name='BLK_BB-VPR_PAD', size=Size(w=2, h=3), pin_classes=[...], pins_index={...}, ports_index={...})
        >>> bt.pin_classes[0] # doctest: +ELLIPSIS
        PinClass(block_type=BlockType(), direction='output', pins=[...])
        >>> len(bt.pins_index)
        3
        >>> len(bt.pin_classes)
        2
        >>> len(bt.pin_classes[0].pins)
        2
        >>> len(bt.pin_classes[1].pins)
        1
        >>> bt.pin_classes[0].pins[0]
        Pin(pin_class=PinClass(), port_name='outpad', port_index=0, block_type_name='BLK_BB-VPR_PAD', block_type_subblk=None, block_type_index=0, side=None)
        >>> bt.pin_classes[0].pins[1]
        Pin(pin_class=PinClass(), port_name='outpad', port_index=1, block_type_name='BLK_BB-VPR_PAD', block_type_subblk=None, block_type_index=1, side=None)
        >>> bt.pin_classes[1].pins[0]
        Pin(pin_class=PinClass(), port_name='inpad', port_index=0, block_type_name='BLK_BB-VPR_PAD', block_type_subblk=None, block_type_index=2, side=None)
        >>>

        Multiple subblocks within a block_type
        >>> xml_string = '''
        ... <block_type id="1" name="BLK_BB-VPR_PAD" width="2" height="3">
        ...   <pin_class type="OUTPUT">
        ...     <pin ptc="0">BLK_BB-VPR_PAD[0].outpad[0]</pin>
        ...   </pin_class>
        ...   <pin_class type="INPUT">
        ...     <pin ptc="1">BLK_BB-VPR_PAD[0].inpad[0]</pin>
        ...   </pin_class>
        ...   <pin_class type="OUTPUT">
        ...     <pin ptc="2">BLK_BB-VPR_PAD[1].outpad[0]</pin>
        ...   </pin_class>
        ...   <pin_class type="INPUT">
        ...     <pin ptc="3">BLK_BB-VPR_PAD[1].inpad[0]</pin>
        ...   </pin_class>
        ... </block_type>
        ... '''
        >>> bt = BlockType.from_xml(None, ET.fromstring(xml_string))
        >>> bt # doctest: +ELLIPSIS
        BlockType(graph=None, id=1, name='BLK_BB-VPR_PAD', size=Size(w=2, h=3), pin_classes=[...], pins_index={...}, ports_index={...})
        >>> bt.pin_classes[0] # doctest: +ELLIPSIS
        PinClass(block_type=BlockType(), direction='output', pins=[...])
        >>> len(bt.pins_index)
        4
        >>> len(bt.pin_classes)
        4
        >>> # All the pin classes should only have one pin
        >>> bt.pin_classes[0].pins
        (Pin(pin_class=PinClass(), port_name='outpad', port_index=0, block_type_name='BLK_BB-VPR_PAD', block_type_subblk=0, block_type_index=0, side=None),)
        >>> bt.pin_classes[1].pins
        (Pin(pin_class=PinClass(), port_name='inpad', port_index=0, block_type_name='BLK_BB-VPR_PAD', block_type_subblk=0, block_type_index=1, side=None),)
        >>> bt.pin_classes[2].pins
        (Pin(pin_class=PinClass(), port_name='outpad', port_index=0, block_type_name='BLK_BB-VPR_PAD', block_type_subblk=1, block_type_index=2, side=None),)
        >>> bt.pin_classes[3].pins
        (Pin(pin_class=PinClass(), port_name='inpad', port_index=0, block_type_name='BLK_BB-VPR_PAD', block_type_subblk=1, block_type_index=3, side=None),)
        """
        assert block_type_node.tag == "block_type", block_type_node
        block_type_id = int(block_type_node.attrib['id'])
        block_type_name = block_type_node.attrib['name'].strip()
        block_type_width = int(block_type_node.attrib['width'])
        block_type_height = int(block_type_node.attrib['height'])

        bt = cls(g, block_type_id, block_type_name,
                 Size(block_type_width, block_type_height))
        for pin_class_node in block_type_node.iterfind("./pin_class"):
            bt._add_pin_class(PinClass.from_xml(bt, pin_class_node))
        return bt

    def _could_add_pin(self, pin):
        if pin.block_type_index != None:
            if pin.block_type_index in self._pins_index:
                assert_is(pin, self._pins_index[pin.block_type_index])

    def _add_pin(self, pin):
        """

        >>> pc = PinClass(direction=PinClassDirection.INPUT)
        >>> len(pc.pins)
        0
        >>> pc._add_pin(Pin())
        >>> len(pc.pins)
        1
        >>> bt = BlockType()
        >>> len(bt.pins_index)
        0
        >>> bt._add_pin_class(pc)
        >>> len(bt.pins_index)
        1

        """
        assert_type(pin, Pin)
        self._could_add_pin(pin)

        # Verify the pin has matching properties.
        # --------------------------------------------
        assert pin.pin_class is not None

        if pin.port_key is not None and pin.port_index is not None:
            if pin.port_key in self._ports_index:
                if pin.port_index in self._ports_index[pin.port_key]:
                    assert_eq(pin, self._ports_index[pin.port_key][pin.port_index])

        if pin.block_type_name is not None:
            assert_eq(pin._block_type_name, self.name)

        if pin.block_type_index is not None:
            if pin.block_type_index in self._pins_index:
                assert_eq(pin, self._pins_index[pin.block_type_index])

        # Fill out any unset properties
        # --------------------------------------------
        if pin.block_type_name is None:
            pin._block_type_name = self.name

        if pin.block_type_index is None:
            pin._block_type_index = dict_next_id(self._pins_index)
        self._pins_index[pin.block_type_index] = pin

        if pin.port_key is not None:
            if pin.port_key not in self._ports_index:
                self._ports_index[pin.port_key] = {}

            if pin.port_index is None:
                pin._port_index = dict_next_id(self._ports_index[pin.port_key])
            self._ports_index[pin.port_key][pin.port_index] = pin

    def _add_pin_class(self, pin_class):
        assert_type(pin_class, PinClass)
        for p in pin_class.pins:
            self._could_add_pin(p)

        if pin_class.block_type is None:
            pin_class.block_type = self
        assert self is pin_class.block_type

        for p in pin_class.pins:
            self._add_pin(p)

        if pin_class not in self._pin_classes:
            self._pin_classes.append(pin_class)


class Block(MostlyReadOnly):
    """For <grid_loc> nodes"""

    __slots__ = ["_graph", "_block_type", "_position", "_offset"]

    @property
    def x(self):
        return self.position.x

    @property
    def y(self):
        return self.position.y

    @property
    def pins(self):
        return self.block_type.pins

    @property
    def positions(self):
        for offset in self.block_type.positions:
            yield self.position + offset

    def __init__(self,
                 g=None,
                 block_type_id=None,
                 block_type=None,
                 position=None,
                 offset=Offset(0, 0)):
        assert_type_or_none(g, BlockGrid)
        assert_type_or_none(block_type_id, int)
        assert_type_or_none(block_type, BlockType)
        assert_type_or_none(position, Position)
        assert_type_or_none(offset, Offset)

        if block_type_id is not None:
            if g is not None:
                assert block_type is None
                assert g.block_types is not None
                block_type = g.block_types[block_type_id]
            else:
                raise TypeError("Must provide g with numeric block_type")

        self._graph = g
        self._block_type = block_type
        self._position = position
        self._offset = offset

    @classmethod
    def from_xml(cls, g, grid_loc_node):
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
        pos = Position(
            int(grid_loc_node.attrib["x"]), int(grid_loc_node.attrib["y"]))
        offset = Offset(
            int(grid_loc_node.attrib["width_offset"]),
            int(grid_loc_node.attrib["height_offset"]))
        return Block(
            g=g, block_type_id=block_type_id, position=pos, offset=offset)

    def ptc2pin(self, ptc):
        """Return Pin for the given ptc (Pin.block_type_index)"""
        return self.block_type.pins_index[ptc]

    def __str__(self):
        return '%s@%s' % (self.block_type.name, self.position)


class BlockGrid:
    """
    For <grid>
    Stores blocks (tiles)
    Stores grid + type
    Does not have routing
    """

    def __init__(self):
        # block Pos to BlockType
        self.block_grid = {}
        # block id to BlockType
        self.block_types = LookupMap(BlockType)

    def __repr__(self):
        return "BG(0x{:x})".format(id(self))

    def _next_block_type_id(self):
        return len(self.block_types)

    def add_block_type(self, block_type):
        assert_type_or_none(block_type, BlockType)

        if block_type.id is None:
            block_type.id = self.block_types._next_id()

        bid = block_type.id
        self.block_types.add(block_type)

    def add_block(self, block):
        assert_type_or_none(block, Block)
        assert block.offset == (0, 0), block
        for pos in block.positions:
            assert (pos not in self.block_grid or self.block_grid[pos] is None
                    or self.block_grid[pos] is block)
            self.block_grid[pos] = block

    @property
    def size(self):
        x_max = max(p.x for p in self.block_grid)
        y_max = max(p.y for p in self.block_grid)
        return Size(x_max + 1, y_max + 1)

    def blocks(self, positions):
        """Get the block objects for the given positions.

        Parameters
        ----------
        positions: sequence of Position

        Returns
        -------
        list of Block
        """
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

            block = self.block_grid[pos]
            if block.position != pos:
                continue
            ss.append(block)
        return ss

    def __getitem__(self, pos):
        return self.block_grid[pos]

    def __iter__(self):
        for pos in sorted(self.block_grid):
            block = self.block_grid[pos]
            if block.position != pos:
                continue
            yield self.block_grid[pos]


SegmentTiming = namedtuple("SegmentTiming", ("R_per_meter", "C_per_meter"))


class Segment(MostlyReadOnly):
    """
    A segment.

    Attributes
    ----------
    id : int
    name : str

    timing : SegmentTiming
    """
    __slots__ = [
        "_id",
        "_name",
        "_timing",
    ]

    def __init__(self, id, name, timing=None):
        assert_type(id, int)
        assert_type(name, str)
        assert_type_or_none(timing, SegmentTiming)
        self._id = id
        self._name = name
        self._timing = timing

    @classmethod
    def from_xml(cls, segment_xml):
        """Create Segment object from an ET.Element XML node.

        Parameters
        ----------
        switch_xml : ET._Element

        Returns
        -------
        Segment

        Examples
        --------
        >>> xml_string = '''
        ... <segment id="0" name="span">
        ...     <timing R_per_meter="101" C_per_meter="2.25000005e-14"/>
        ... </segment>
        ... '''
        >>> Segment.from_xml(ET.fromstring(xml_string))
        Segment(id=0, name='span', timing=SegmentTiming(R_per_meter=101.0, C_per_meter=2.25000005e-14))
        """
        assert_type(segment_xml, ET._Element)
        seg_id = int(segment_xml.get('id'))
        name = segment_xml.get('name')

        timing = None
        timings = list(segment_xml.iterfind('timing'))
        if len(timings) == 1:
            timing = timings[0]
            timing_r = float(timing.get('R_per_meter'))
            timing_c = float(timing.get('C_per_meter'))
            timing = SegmentTiming(R_per_meter=timing_r, C_per_meter=timing_c)
        else:
            assert len(timings) == 0
        return cls(seg_id, name, timing)

    def to_xml(self, segments_xml):
        timing_xml = ET.SubElement(segments_xml, 'segment', {
            'id': str(self.id),
            'name': self.name
        })
        if self.timing:
            ET.SubElement(timing_xml, "timing",
                          {k: str(v)
                           for k, v in self.timing.items()})


SwitchTiming = namedtuple("SwitchTiming", ("R", "Cin", "Cout", "Tdel"))
SwitchSizing = namedtuple("SwitchSizing", ("mux_trans_size", "buf_size"))


class SwitchType(enum.Enum):
    MUX = "mux"
    TRISTATE = "tristate"
    PASS_GATE = "pass_gate"
    SHORT = "short"
    BUFFER = "buffer"


class Switch(MostlyReadOnly):
    """A Switch.

    Attributes
    ----------
    id : int
    name : str
    type : SwitchType

    timing : SwitchTiming
    sizing : SwitchSizing
    """
    __slots__ = [
        "_id",
        "_name",
        "_type",
        "_timing",
        "_sizing",
    ]

    def __init__(self,
                 id,
                 type,
                 name,
                 timing=None,
                 sizing=None):
        assert_type(id, int)
        assert_type(type, SwitchType)
        assert_type(name, str)
        assert_type_or_none(timing, SwitchTiming)
        assert_type_or_none(sizing, SwitchSizing)
        self._id = id
        self._name = name
        self._type = type
        self._timing = timing
        self._sizing = sizing

    def to_xml(self, parent_node):
        sw_node = ET.Element("switch", attrib={
            "id": str(self._id),
            "name": self._name,
            "type": self._type.value,
        })
        ET.SubElement(sw_node, "timing", attrib={
            "R": str(self._timing.R),
            "Cin": str(self._timing.Cin),
            "Cout": str(self._timing.Cout),
            "Tdel": str(self._timing.Tdel),
        })
        ET.SubElement(sw_node, "sizing", attrib={
            "mux_trans_size": str(self._sizing.mux_trans_size),
            "buf_size": str(self._sizing.buf_size),
        })
        if parent_node is not None:
            parent_node.append(sw_node)
        return sw_node

    @classmethod
    def from_xml(cls, switch_xml):
        """Create Switch object from an ET._Element XML node.

        Parameters
        ----------
        switch_xml : ET._Element

        Returns
        -------
        Switch

        Examples
        --------

        >>> xml_string = '''
        ... <switch id="0" type="mux" name="buffer">
        ...  <timing R="551" Cin="7.70000012e-16" Cout="4.00000001e-15" Tdel="5.80000006e-11"/>
        ...  <sizing mux_trans_size="2.63073993" buf_size="27.6459007"/>
        ... </switch>
        ... '''
        >>> sw = Switch.from_xml(ET.fromstring(xml_string))
        >>> sw
        Switch(id=0, name='buffer', type=<SwitchType.MUX: 'mux'>, timing=SwitchTiming(R=551.0, Cin=7.70000012e-16, Cout=4.00000001e-15, Tdel=4.00000001e-15), sizing=SwitchSizing(mux_trans_size=2.63073993, buf_size=27.6459007))
        >>> print(ET.tostring(sw.to_xml(None), pretty_print=True).decode('utf-8').strip())
        <switch id="0" name="buffer" type="mux">
          <timing Cin="7.70000012e-16" Cout="4.00000001e-15" R="551.0" Tdel="4.00000001e-15"/>
          <sizing buf_size="27.6459007" mux_trans_size="2.63073993"/>
        </switch>
        """
        assert_type(switch_xml, ET._Element)
        sw_id = int(switch_xml.attrib.get('id'))
        sw_type = SwitchType(switch_xml.attrib.get('type'))
        name = switch_xml.attrib.get('name')

        timing = None
        timings = list(switch_xml.iterfind('timing'))
        if len(timings) == 1:
            timing = timings[0]
            timing_r = float(timing.get('R'))
            timing_cin = float(timing.get('Cin'))
            timing_cout = float(timing.get('Cout'))
            timing_tdel = float(timing.get('Cout'))
            timing = SwitchTiming(timing_r, timing_cin, timing_cout,
                                  timing_tdel)
        else:
            assert len(timings) == 0

        sizing = None
        sizings = list(switch_xml.iterfind('sizing'))
        if len(sizings) == 1:
            sizing = sizings[0]
            sizing_mux_trans_size = float(sizing.get('mux_trans_size'))
            sizing_buf_size = float(sizing.get('buf_size'))
            sizing = SwitchSizing(sizing_mux_trans_size, sizing_buf_size)
        else:
            assert len(sizings) == 0

        return cls(
            id=sw_id,
            type=sw_type,
            name=name,
            timing=timing,
            sizing=sizing)


class LookupMap:
    """Store a way to lookup by ID or name."""

    def __init__(self, obj_type):
        self.obj_type = obj_type
        self._names = {}
        self._ids = {}

    def clear(self):
        self._names.clear()
        self._ids.clear()

    def add(self, obj):
        assert_type(obj, self.obj_type)
        assert_type(obj.id, int)
        assert_type(obj.name, str)

        assert obj.id not in self._ids, obj.id
        assert obj.name not in self._names, obj.name

        self._names[obj.name] = obj
        self._ids[obj.id] = obj

    def __getitem__(self, key):
        if isinstance(key, int):
            return self._ids[key]
        elif isinstance(key, str):
            return self._names[key]

    def __iter__(self):
        return self._names.itervalues()

    @property
    def names(self):
        return self._names.iterkeys()

    @property
    def ids(self):
        return self._ids.iterkeys()

    def next_id(self):
        return max(self._ids.keys()) + 1


class RoutingGraphPrinter:
    @classmethod
    def node(cls, xml_node, block_grid=None):
        """Get a globally unique name for an `node` in the rr_nodes.

        Without a block graph, the name won't include the block type.
        >>> RoutingGraphPrinter.node(ET.fromstring('''
        ... <node id="0" type="SINK" capacity="1">
        ...   <loc xlow="0" ylow="3" xhigh="0" yhigh="3" ptc="0"/>
        ...   <timing R="0" C="0"/>
        ... </node>
        ... '''))
        '0 X000Y003[00].SINK-<'
        >>> RoutingGraphPrinter.node(ET.fromstring('''
        ... <node id="1" type="SOURCE" capacity="1">
        ...   <loc xlow="1" ylow="2" xhigh="1" yhigh="2" ptc="1"/>
        ...   <timing R="0" C="0"/>
        ... </node>
        ... '''))
        '1 X001Y002[01].SRC-->'
        >>> RoutingGraphPrinter.node(ET.fromstring('''
        ... <node id="2" type="IPIN" capacity="1">
        ...   <loc xlow="2" ylow="1" xhigh="2" yhigh="1" side="TOP" ptc="0"/>
        ...   <timing R="0" C="0"/>
        ... </node>
        ... '''))
        '2 X002Y001[00].T-PIN<'
        >>> RoutingGraphPrinter.node(ET.fromstring('''
        ... <node id="6" type="OPIN" capacity="1">
        ...   <loc xlow="3" ylow="0" xhigh="3" yhigh="0" side="RIGHT" ptc="1"/>
        ...   <timing R="0" C="0"/>
        ... </node>
        ... '''))
        '6 X003Y000[01].R-PIN>'

        With a block graph, the name will include the block type.
        >>> bg = simple_test_block_grid()
        >>> RoutingGraphPrinter.node(ET.fromstring('''
        ... <node id="0" type="SINK" capacity="1">
        ...   <loc xlow="0" ylow="3" xhigh="0" yhigh="3" ptc="0"/>
        ...   <timing R="0" C="0"/>
        ... </node>
        ... '''), bg)
        '0 X000Y003_INBLOCK[00].C[3:0]-SINK-<'
        >>> RoutingGraphPrinter.node(ET.fromstring('''
        ... <node id="1" type="SOURCE" capacity="1">
        ...   <loc xlow="1" ylow="2" xhigh="1" yhigh="2" ptc="1"/>
        ...   <timing R="0" C="0"/>
        ... </node>
        ... '''), bg)
        '1 X001Y002_DUALBLK[01].B[0]-SRC-->'
        >>> RoutingGraphPrinter.node(ET.fromstring('''
        ... <node id="2" type="IPIN" capacity="1">
        ...   <loc xlow="2" ylow="1" xhigh="2" yhigh="1" side="TOP" ptc="0"/>
        ...   <timing R="0" C="0"/>
        ... </node>
        ... '''), bg)
        '2 X002Y001_DUALBLK[00].A[0]-T-PIN<'
        >>> RoutingGraphPrinter.node(ET.fromstring('''
        ... <node id="6" type="OPIN" capacity="1">
        ...   <loc xlow="3" ylow="0" xhigh="3" yhigh="0" side="RIGHT" ptc="1"/>
        ...   <timing R="0" C="0"/>
        ... </node>
        ... '''), bg)
        '6 X003Y000_OUTBLOK[01].D[1]-R-PIN>'

        Edges don't require a block graph, as they have the full information on
        the node.
        >>> RoutingGraphPrinter.node(ET.fromstring('''
        ... <node capacity="1" direction="INC_DIR" id="372" type="CHANX">
        ...   <loc ptc="4" xhigh="3" xlow="3" yhigh="0" ylow="0"/>
        ...   <timing C="2.72700004e-14" R="101"/>
        ...   <segment segment_id="1"/>
        ... </node>
        ... '''))
        '372 X003Y000--04->X003Y000'
        >>> RoutingGraphPrinter.node(ET.fromstring('''
        ... <node capacity="1" direction="DEC_DIR" id="373" type="CHANY">
        ...   <loc ptc="5" xhigh="3" xlow="3" yhigh="0" ylow="0"/>
        ...   <timing C="2.72700004e-14" R="101"/>
        ...   <segment segment_id="1"/>
        ... </node>
        ... '''))
        '373 X003Y000<|05||X003Y000'
        >>> RoutingGraphPrinter.node(ET.fromstring('''
        ... <node capacity="1" direction="BI_DIR" id="374" type="CHANX">
        ...   <loc ptc="5" xhigh="3" xlow="3" yhigh="0" ylow="0"/>
        ...   <timing C="2.72700004e-14" R="101"/>
        ...   <segment segment_id="1"/>
        ... </node>
        ... '''))
        '374 X003Y000<-05->X003Y000'

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
        assert_type(xml_node, ET._Element)

        loc_node = list(xml_node.iterfind("./loc"))[0]
        low = Position(
            int(loc_node.attrib["xlow"]), int(loc_node.attrib["ylow"]))
        high = Position(
            int(loc_node.attrib["xhigh"]), int(loc_node.attrib["yhigh"]))
        ptc = int(loc_node.attrib["ptc"])
        edge = loc_node.attrib.get("side", " ")[0]

        if block_grid is not None:
            block = block_grid[low]
        else:
            block = None

        node_id = RoutingGraph._get_xml_id(xml_node)
        type_str = None
        node_type = RoutingNodeType.from_xml(xml_node)
        if False:
            pass
        elif node_type in (RoutingNodeType.CHANX, RoutingNodeType.CHANY):
            direction = xml_node.attrib.get("direction")
            direction_fmt = {
                'INC_DIR': '{f}{f}{ptc:02d}{f}>',
                'DEC_DIR': '<{f}{ptc:02d}{f}{f}',
                'BI_DIR': '<{f}{ptc:02d}{f}>',
            }.get(direction, None)
            assert direction_fmt, "Bad direction %s" % direction
            return "{} X{:03d}Y{:03d}{}X{:03d}Y{:03d}".format(
                node_id,
                low.x, low.y,
                direction_fmt.format(
                    f={
                        RoutingNodeType.CHANX: '-',
                        RoutingNodeType.CHANY: '|'
                    }[node_type],
                    ptc=ptc), high.x, high.y)
        elif node_type is RoutingNodeType.SINK:
            type_str = "SINK-<"
            # FIXME: Check high == block.position + block.block_type.size
        elif node_type is RoutingNodeType.SOURCE:
            type_str = "SRC-->"
            # FIXME: Check high == block.position + block.block_type.size
        elif node_type is RoutingNodeType.IPIN:
            assert edge in "TLRB", edge
            type_str = "{}-PIN<".format(edge)
        elif node_type is RoutingNodeType.OPIN:
            assert edge in "TLRB", edge
            type_str = "{}-PIN>".format(edge)
        else:
            assert False, "Unknown node_type {}".format(node_type)
        assert type_str

        if block_grid is not None:
            block = block_grid[low]
            block_name = "_" + block.block_type.name
            x = block.position.x
            y = block.position.y

            if node_type in (RoutingNodeType.IPIN, RoutingNodeType.OPIN):
                try:
                    ptc_str = "[{:02d}].{}-".format(ptc, block.block_type.pins_index[ptc].name)
                except TypeError:
                    ptc_str = "[{:02d} :-(].".format(ptc)
            elif node_type in (RoutingNodeType.SINK, RoutingNodeType.SOURCE):
                try:
                    pc = block.block_type.pin_classes[ptc]
                    ptc_str = "[{:02d}].{}-".format(ptc, pc.port_name)
                except TypeError:
                    ptc_str = "[{:02d} :-(].".format(ptc)
            else:
                ptc_str = "[{:02d}].".format(ptc)

        else:
            block_name = ""
            x = low.x
            y = low.y
            ptc_str = "[{:02d}].".format(ptc)

        return "{id} X{x:03d}Y{y:03d}{t}{i}{s}".format(
            id=node_id,
            t=block_name, x=x, y=y, i=ptc_str, s=type_str)

    @classmethod
    def edge(cls, routing, xml_node, block_grid=None, flip=False):
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
        >>> rg = RoutingGraph(xml_graph=ET.fromstring(xml_string1))
        >>> RoutingGraphPrinter.edge(rg, ET.fromstring('''
        ... <edge sink_node="1" src_node="0" switch_id="1"/>
        ... '''))
        '0 X000Y003[00].SRC--> ->>- 1 X000Y003||05|>X003Y000'
        >>> RoutingGraphPrinter.edge(rg, ET.fromstring('''
        ... <edge sink_node="1" src_node="0" switch_id="1"/>
        ... '''), bg)
        '0 X000Y003_INBLOCK[00].C[3:0]-SRC--> ->>- 1 X000Y003||05|>X003Y000'
        """
        src_node, snk_node = routing.nodes_for_edge(xml_node)
        if flip:
            s = "{} -<<- {}"
        else:
            s = "{} ->>- {}"
        return s.format(
            cls.node(src_node, block_grid=block_grid),
            cls.node(snk_node, block_grid=block_grid))


class MappingLocalNames(dict):
    """
    Class for keeping track of the local name for a given node.
    """

    def __init__(self, *args, type=ET._Element, **kw):
        self.type = type
        self.localnames = {}
        dict.__init__(self, *args, **kw)

    def add(self, pos, name, value):
        assert_type(value, self.type)
        assert_type(pos, Position)
        assert_type(name, str)

        self[(pos, name)] = value

    def clear(self):
        self.localnames.clear()
        dict.clear(self)

    def __setitem__(self, key, value):
        """
        map[(Position, name)] = type
        """
        assert_type(value, self.type)

        pos, name = key
        assert_type(pos, Position)
        assert_type(name, str)

        if pos not in self.localnames:
            self.localnames[pos] = set()
        if key in self:
            assert_eq(self[key], value, msg="%s already exist!" % (key,))
        self.localnames[pos].add(name)

        dict.__setitem__(self, key, value)

    def __getitem__(self, key):
        """
        map[pos] -> list of node_id
        map[(position, name)] = node_id
        """
        if isinstance(key, Position):
            return self.localnames[key]
        else:
            assert_type(key, tuple)
            assert_eq(len(key), 2)
            assert_type(key[0], Position)
            assert_type(key[1], str)
            return dict.__getitem__(self, key)


class MappingGlobalNames(dict):
    """
    Class for keeping track of the global names for a given node.
    """

    def add(self, name, xml_node):
        self[name] = xml_node

    def __setitem__(self, name, xml_node):
        """
        map[name] = ET._Element
        """
        assert_type(name, str)
        assert_type(xml_node, ET._Element)
        assert name not in self, "{} in {}".format(name, self)
        dict.__setitem__(self, name, xml_node)


_RoutingNodeTiming = namedtuple("RoutingNodeTiming", ("R", "C"))


class RoutingNodeTiming(_RoutingNodeTiming):
    def to_xml(self):
        return ET.Element('timing', {'R': str(self.R), 'C': str(self.C)})


class RoutingNodeType(enum.Enum):
    IPIN = 'IPIN'
    OPIN = 'OPIN'
    SINK = 'SINK'
    SOURCE = 'SOURCE'
    CHANX = 'CHANX'
    CHANY = 'CHANY'

    @classmethod
    def from_xml(cls, xml_node):
        assert xml_node.tag == "node", xml_node
        return RoutingNodeType(xml_node.attrib["type"])

    @property
    def track(self):
        """Is this RoutingNodeType a track?"""
        return self in (self.CHANX, self.CHANY)

    @property
    def output(self):
        """Is this RoutingNodeType an output?"""
        return self in (self.OPIN, self.SOURCE)

    @property
    def input(self):
        """Is this RoutingNodeType an input?"""
        return self in (self.IPIN, self.SINK)

    @property
    def pin(self):
        """Is this RoutingNodeType an pin?"""
        return self in (self.OPIN, self.IPIN)

    @property
    def pin_class(self):
        """Is this RoutingNodeType an pin_class?"""
        return self in (self.SINK, self.SOURCE)

    @property
    def can_sink(self):
        """Can be a destination of an edge."""
        # -> XXX
        return self in (self.IPIN, self.CHANX, self.CHANY)

    @property
    def can_source(self):
        """Can be a source of an edge."""
        # XXX ->
        return self in (self.OPIN, self.CHANX, self.CHANY)


def _metadata(parent_node):
    elements = list(parent_node.iterfind("metadata"))
    if len(elements) == 1:
        return elements[0]
    return None


def _set_metadata(parent_node, key, value, offset=None):
    metadata = _metadata(parent_node)
    if metadata is None:
        metadata = ET.SubElement(parent_node, "metadata")

    attribs = [("name", key)]
    if offset:
        attribs.append(("x_offset", str(offset.width)))
        attribs.append(("y_offset", str(offset.height)))

    metanode = None
    for node in metadata.iterfind("./meta"):
        matches = True
        for n, v in attribs:
            if node.attrib.get(n, None) != v:
                matches = False
                break
        if matches:
            metanode = node
            break
    else:
        metanode = ET.SubElement(metadata, "meta", attrib=dict(attribs))

    for n, v in attribs:
        metanode.attrib[n] = v
    metanode.text = str(value)


_get_metadata_sentry = []
def _get_metadata(parent_node, key, default=_get_metadata_sentry):
    metanode = None

    metadata = _metadata(parent_node)
    if metadata is not None:
        for node in metadata.iterfind("./meta"):
            if node.attrib["name"] == key:
                metanode = node
                break

    if metanode is None:
        if default is not _get_metadata_sentry:
            return default
        else:
            raise ValueError("No metadata {} on\n{}".format(
                key,
                ET.tostring(parent_node, pretty_print=True).decode().strip())
            )

    return metanode.text


class RoutingNodeSide(enum.Enum):
    LEFT = 'LEFT'
    RIGHT = 'RIGHT'
    TOP = 'TOP'
    BOTTOM = 'BOTTOM'


class RoutingNodeDir(enum.Enum):
    INC_DIR = 'INC_DIR'
    DEC_DIR = 'DEC_DIR'
    BI_DIR = 'BI_DIR'


class RoutingNode(ET.ElementBase):
    TAG = "node"

    def set_metadata(self, key, value, offset=None):
        _set_metadata(self, key, value, offset=offset)

    def get_metadata(self, key, default=_get_metadata_sentry):
        return _get_metadata(self, key, default)


class RoutingEdge(ET.ElementBase):
    TAG = "edge"

    def set_metadata(self, key, value, offset=None):
        _set_metadata(self, key, value, offset=offset)

    def get_metadata(self, key, default=_get_metadata_sentry):
        return _get_metadata(self, key, default)


class RoutingGraph:
    """
    The RoutingGraph object keeps track of the actual "graph" found in
    rr_graph.xml files.

    The Graph is represented by two XML node types, they are; `<rr_nodes>` and
    `<rr_edges>` objects which are connected by the ID objects.


    """

    @staticmethod
    def _get_xml_id(xml_node):
        node_id = xml_node.get('id', None)
        if node_id is not None:
            node_id = int(node_id)
        return node_id

    @staticmethod
    def set_metadata(node, key, value, offset=None):
        """
        Examples
        --------
        >>> # Works with edges
        >>> r = simple_test_routing()
        >>> sw = Switch(id=0, type=SwitchType.MUX, name="sw")
        >>> r.create_edge_with_ids(0, 1, sw)
        >>> e1 = r.get_edge_by_id(4)
        >>> # Call directly on the edge
        >>> e1.get_metadata("test", default=":-(")
        ':-('
        >>> e1.set_metadata("test", "123")
        >>> print(ET.tostring(e1, pretty_print=True).decode().strip())
        <edge sink_node="1" src_node="0" switch_id="0" id="4">
          <metadata>
            <meta name="test">123</meta>
          </metadata>
        </edge>
        >>> e1.get_metadata("test", default=":-(")
        '123'
        >>> # Or via the routing object
        >>> r.set_metadata(e1, "test", "234")
        >>> r.get_metadata(e1, "test")
        '234'
        >>> # Exception if no default provided
        >>> r.get_metadata(e1, "not_found")
        Traceback (most recent call last):
            ...
        ValueError: No metadata not_found on
        <edge sink_node="1" src_node="0" switch_id="0" id="4">
          <metadata>
            <meta name="test">234</meta>
          </metadata>
        </edge>
        >>> r.set_metadata(e1, "test", 1)
        >>> # Works with nodes
        >>> n1 = r.get_node_by_id(0)
        >>> # Call directly on the node
        >>> n1.get_metadata("test", default=":-(")
        ':-('
        >>> n1.set_metadata("test", "123")
        >>> print(ET.tostring(n1, pretty_print=True).decode().strip())
        <node capacity="1" id="0" type="SOURCE">
          <loc ptc="0" xhigh="0" xlow="0" yhigh="0" ylow="0"/>
          <timing C="0" R="0"/>
          <metadata>
            <meta name="test">123</meta>
          </metadata>
        </node>
        >>> n1.get_metadata("test", default=":-(")
        '123'
        >>> # Or via the routing object
        >>> r.set_metadata(n1, "test", "234")
        >>> r.get_metadata(n1, "test")
        '234'

        """
        _set_metadata(node, key, value, offset)

    @staticmethod
    def get_metadata(node, key, default=_get_metadata_sentry):
        return _get_metadata(node, key, default)

    def __init__(self, xml_graph=None, verbose=True, clear_fabric=False):
        """
        >>> g = simple_test_graph()
        """
        self.verbose = verbose

        # Lookup XML node for given an ID
        self.id2element = {RoutingNode: {}, RoutingEdge: {}}
        # Names for each node at a given position
        self.localnames = MappingLocalNames(type=ET._Element)
        # Global names for each node
        self.globalnames = MappingGlobalNames()

        self._cache_nodes2edges = {}

        if xml_graph is None:
            xml_graph = ET.Element("rr_graph")
            ET.SubElement(xml_graph, "rr_nodes")
            ET.SubElement(xml_graph, "rr_edges")

        self._xml_graph = xml_graph

        if clear_fabric:
            self.clear()
        else:
            for node in self._xml_parent(RoutingNode):
                self._add_xml_element(node, existing=True)
            for edge in self._xml_parent(RoutingEdge):
                self._add_xml_element(edge, existing=True)
            self._build_cache_node2edge()

    def clear(self):
        """Delete the existing rr_nodes and rr_edges."""
        self._xml_parent(RoutingNode).clear()
        self._xml_parent(RoutingEdge).clear()

        self.id2element[RoutingNode].clear()
        self.id2element[RoutingEdge].clear()

        self.localnames.clear()
        self.globalnames.clear()

        self._cache_nodes2edges.clear()

    def _xml_type(self, xml_node):
        """Get the type of an ET._Element object.

        Parameters
        ----------
        xml_node: RoutingNode or RoutingEdge

        Returns
        -------
        RoutingNode.__class__ or RoutingEdge.__class___
        """
        if xml_node.tag == "node":
            return RoutingNode
        elif xml_node.tag == "edge":
            return RoutingEdge
        else:
            assert False, xml_node.tag

    def _xml_parent(self, xml_type):
        """Get the ET._Element parent for a give type."""
        if xml_type is RoutingNode:
            return single_element(self._xml_graph, 'rr_nodes')
        elif xml_type is RoutingEdge:
            return single_element(self._xml_graph, 'rr_edges')

    def _ids_map(self, xml_type):
        """Get the ID mapping for a give type."""
        return self.id2element[xml_type]

    def _next_id(self, xml_type):
        """Get the next ID available for a give type."""
        return len(self._ids_map(xml_type))

    def _add_xml_element(self, xml_node, existing=False):
        """Add an existing ET._Element object to the map.

        Parameters
        ----------
        xml_node: RoutingNode or RoutingEdge
        """
        xml_type = self._xml_type(xml_node)

        # If the XML node doesn't have an ID, allocate it one.
        node_id = self._get_xml_id(xml_node)
        if node_id is None:
            new_node_id = self._next_id(xml_type)
            xml_node.attrib['id'] = str(new_node_id)
        else:
            new_node_id = node_id

        # Make sure we don't duplicate IDs
        ids2element = self._ids_map(xml_type)
        if new_node_id in ids2element:
            assert xml_node is ids2element[new_node_id], "Error at {}: {} ({}) is not {} ({})".format(
                new_node_id, xml_node,
                ET.tostring(xml_node), ids2element[new_node_id],
                ET.tostring(ids2element[new_node_id]))
        else:
            ids2element[new_node_id] = xml_node

        # FIXME: Make sure the node is included on the XML parent.
        #if node_id is None:
        #   pass
        if not existing:
            parent = self._xml_parent(xml_type)
            parent.append(xml_node)
            self._add_cache_node2edge(xml_node)

    def _add_cache_node2edge(self, xml_node):
        xml_type = self._xml_type(xml_node)
        node_id = self._get_xml_id(xml_node)
        if xml_type == RoutingNode:
            assert node_id not in self._cache_nodes2edges
            self._cache_nodes2edges[node_id] = set()
        elif xml_type == RoutingEdge:
            src_id, snk_id = self.node_ids_for_edge(xml_node)
            self._cache_nodes2edges[src_id].add(node_id)
            self._cache_nodes2edges[snk_id].add(node_id)
        else:
            assert False, "Unknown xml_node {}".format(xml_node)

    def _build_cache_node2edge(self):
        assert len(self._cache_nodes2edges) == 0
        for node in self._ids_map(RoutingNode).values():
            self._add_cache_node2edge(node)

        for edge in self._ids_map(RoutingEdge).values():
            self._add_cache_node2edge(edge)

    def get_by_name(self, name, pos=None, default=_DEFAULT_MARKER):
        """Get the RoutingNode using name (and pos).

        Parameters
        ----------
        name: str
        pos: Position
        default: Optional value to return if not found.

        Returns
        -------
        RoutingNode (ET._Element)

        Examples
        --------
        FIXME: Add example.

        """
        assert_type(name, str)
        assert_type_or_none(pos, Position)

        r = _DEFAULT_MARKER
        if pos is not None:
            r = self.localnames.get((pos, name), _DEFAULT_MARKER)
        if r is _DEFAULT_MARKER:
            r = self.globalnames.get(name, _DEFAULT_MARKER)
        if r is not _DEFAULT_MARKER:
            return r
        if default is not _DEFAULT_MARKER:
            return default
        else:
            raise KeyError("No node named {} globally or locally at {}".format(
                name, pos))

    def get_node_by_id(self, node_id):
        """Get the RoutingNode from a given ID.

        Parameters
        ----------
        node_id: int

        Returns
        -------
        RoutingNode (ET._Element)

        Examples
        --------
        >>> r = simple_test_routing()
        >>> RoutingGraphPrinter.node(r.get_node_by_id(0))
        '0 X000Y000[00].SRC-->'
        >>> RoutingGraphPrinter.node(r.get_node_by_id(1))
        '1 X000Y000[00].R-PIN>'
        >>> RoutingGraphPrinter.node(r.get_node_by_id(2))
        '2 X000Y000<-00->X000Y010'
        >>> RoutingGraphPrinter.node(r.get_node_by_id(3))
        '3 X000Y010[00].L-PIN<'
        >>> RoutingGraphPrinter.node(r.get_node_by_id(4))
        '4 X000Y010[00].SINK-<'
        >>> RoutingGraphPrinter.node(r.get_node_by_id(5))
        Traceback (most recent call last):
            ...
        KeyError: 5

        """
        return self._ids_map(RoutingNode)[node_id]

    def get_edge_by_id(self, node_id):
        """Get the RoutingEdge from a given ID.

        Parameters
        ----------
        node_id: int

        Returns
        -------
        RoutingEdge (ET._Element)

        Examples
        --------
        >>> r = simple_test_routing()
        >>> RoutingGraphPrinter.edge(r, r.get_edge_by_id(0))
        '0 X000Y000[00].SRC--> ->>- 1 X000Y000[00].R-PIN>'
        >>> RoutingGraphPrinter.edge(r, r.get_edge_by_id(1))
        '1 X000Y000[00].R-PIN> ->>- 2 X000Y000<-00->X000Y010'
        >>> RoutingGraphPrinter.edge(r, r.get_edge_by_id(2))
        '2 X000Y000<-00->X000Y010 ->>- 3 X000Y010[00].L-PIN<'
        >>> RoutingGraphPrinter.edge(r, r.get_edge_by_id(3))
        '3 X000Y010[00].L-PIN< ->>- 4 X000Y010[00].SINK-<'
        >>> r.get_edge_by_id(4)
        Traceback (most recent call last):
            ...
        KeyError: 4
        """
        return self._ids_map(RoutingEdge)[node_id]

    @staticmethod
    def node_ids_for_edge(xml_node):
        """Return the node ids associated with given edge.

        Parameters
        ----------
        xml_node: RoutingEdge

        Returns
        -------
        (int, int)
            Source RoutingNode ID, Sink RoutingNode ID

        Example
        -------
        >>> e = ET.fromstring('<edge src_node="0" sink_node="1" switch_id="1"/>')
        >>> RoutingGraph.node_ids_for_edge(e)
        (0, 1)
        """
        assert xml_node.tag == 'edge'
        src_node_id = int(xml_node.attrib.get("src_node"))
        snk_node_id = int(xml_node.attrib.get("sink_node"))
        return src_node_id, snk_node_id

    def nodes_for_edge(self, xml_node):
        """Return all nodes associated with given edge.

        Parameters
        ----------
        xml_node: RoutingEdge

        Returns
        -------
        (RoutingNode, RoutingNode)
            Source RoutingNode, Sink RoutingNode - XML nodes (ET._Element)
            associated with the given edge.

        Example
        --------
        >>> r = simple_test_routing()
        >>> e1 = r.get_edge_by_id(0)
        >>> RoutingGraphPrinter.edge(r, e1)
        '0 X000Y000[00].SRC--> ->>- 1 X000Y000[00].R-PIN>'
        >>> [RoutingGraphPrinter.node(n) for n in r.nodes_for_edge(e1)]
        ['0 X000Y000[00].SRC-->', '1 X000Y000[00].R-PIN>']
        >>> e2 = r.get_edge_by_id(1)
        >>> RoutingGraphPrinter.edge(r, e2)
        '1 X000Y000[00].R-PIN> ->>- 2 X000Y000<-00->X000Y010'
        >>> [RoutingGraphPrinter.node(n) for n in r.nodes_for_edge(e2)]
        ['1 X000Y000[00].R-PIN>', '2 X000Y000<-00->X000Y010']
        """
        src_node_id, snk_node_id = self.node_ids_for_edge(xml_node)

        ids2element = self._ids_map(RoutingNode)
        assert snk_node_id in ids2element, "{:r} in {}".format(
            snk_node_id, ids2element.keys())
        assert src_node_id in ids2element, "{:r} in {}".format(
            src_node_id, ids2element.keys())
        return ids2element[src_node_id], ids2element[snk_node_id]

    def edges_for_allnodes(self):
        """Return a mapping between edges and associated nodes.

        Returns
        -------
        dict[int] -> list of RoutingEdge
            Mapping from RoutingNode ID to XML edges (ET._Element) associated
            with the given node.

        Example
        -------

        """
        return MappingProxyType(self._cache_nodes2edges)

    def edges_for_node(self, xml_node):
        """Return all edges associated with given node.

        Parameters
        ----------
        xml_node: RoutingNode

        Returns
        -------
        list of RoutingEdge
            XML edges (ET._Element) associated with the given node.

        Examples
        --------
        >>> r = simple_test_routing()
        >>> [RoutingGraphPrinter.edge(r, e) for e in r.edges_for_node(r.get_node_by_id(1))]
        ['0 X000Y000[00].SRC--> ->>- 1 X000Y000[00].R-PIN>', '1 X000Y000[00].R-PIN> ->>- 2 X000Y000<-00->X000Y010']
        >>> [RoutingGraphPrinter.edge(r, e) for e in r.edges_for_node(r.get_node_by_id(2))]
        ['1 X000Y000[00].R-PIN> ->>- 2 X000Y000<-00->X000Y010', '2 X000Y000<-00->X000Y010 ->>- 3 X000Y010[00].L-PIN<']
        """
        return [self.get_edge_by_id(i) for i in self.edges_for_allnodes()[self._get_xml_id(xml_node)]]

    ######################################################################
    # Constructor methods
    ######################################################################

    def create_node(self,
                    low,
                    high,
                    ptc,
                    ntype,
                    direction=None,
                    segment_id=None,
                    side=None,
                    timing=None,
                    capacity=1,
                    metadata={}):
        """Create an node.

        Parameters
        ----------
        low : Position
        high : Position
        ptc : int
        ntype : RoutingNodeType

        direction : RoutingNodeDir, optional
        segment_id : int, optional
        side : RoutingNodeSide, optional
        timing : RoutingNodeTiming, optional
        metadata : {str: Any}, optional

        Returns
        -------
        RoutingNode
        """
        if isinstance(ntype, str):
            ntype = RoutingNodeType[ntype]

        # <node>
        attrib = {
            'id': str(self._next_id(RoutingNode)),
            'type': ntype.value,
            'capacity': str(capacity),
        }
        if ntype.track:
            assert direction != None
            attrib['direction'] = direction.value
        elif not ntype.pin_class:
            assert low == high, (low, high)

        node = RoutingNode(attrib=attrib)

        # <loc> needed for all nodes
        attrib = {
            'xlow': str(low.x),
            'ylow': str(low.y),
            'xhigh': str(high.x),
            'yhigh': str(high.y),
            'ptc': str(ptc),
        }
        if ntype.pin:
            assert_type(side, RoutingNodeSide)
            attrib['side'] = side.value
        else:
            assert side is None
        ET.SubElement(node, 'loc', attrib)

        # <timing> needed for all nodes
        if timing is None:
            if ntype.track:
                # Seems to confuse VPR when 0
                # XXX: consider requiring the user to give instead of defaulting
                timing = RoutingNodeTiming(R=1, C=1)
            else:
                timing = RoutingNodeTiming(R=0, C=0)
        assert len(timing) == 2
        assert_type(timing, RoutingNodeTiming)
        assert_type(timing.R, (float, int))
        assert_type(timing.C, (float, int))
        node.append(timing.to_xml())

        # <segment> needed for CHANX/CHANY nodes
        if ntype.track:
            assert_type(segment_id, int)
            ET.SubElement(node, 'segment', {'segment_id': str(segment_id)})

        for offset, values in metadata.items():
            for k, v in values.items():
                node.set_metadata(k, v, offset=offset)

        self._add_xml_element(node)

        return node

    def create_edge_with_ids(self, src_node_id, sink_node_id, switch, metadata={}, bidir=None):
        """Create an RoutingEdge between given IDs for two RoutingNodes.

        Parameters
        ----------
        src_node_id : int
        sink_node_id : int
        switch : Switch
        metadata : {str: Any}, optional

        Returns
        -------
        RoutingEdge (ET._Element)

        Examples
        --------
        >>> r = simple_test_routing()
        >>> sw = Switch(id=0, type=SwitchType.MUX, name="sw")
        >>> r.create_edge_with_ids(0, 1, sw)
        >>> e1 = r.get_edge_by_id(4)
        >>> RoutingGraphPrinter.edge(r, e1)
        '0 X000Y000[00].SRC--> ->>- 1 X000Y000[00].R-PIN>'

        The code protects against invalid edge creation;
        >>> r.create_edge_with_ids(0, 2, sw)
        Traceback (most recent call last):
          ...
        TypeError: RoutingNodeType.SOURCE -> RoutingNodeType.CHANX not valid, Only SOURCE -> OPIN is valid
        0 X000Y000[00].SRC--> b'<node capacity="1" id="0" type="SOURCE"><loc ptc="0" xhigh="0" xlow="0" yhigh="0" ylow="0"/><timing C="0" R="0"/></node>'
          ->
        2 X000Y000<-00->X000Y010 b'<node capacity="1" direction="BI_DIR" id="2" type="CHANX"><loc ptc="0" xhigh="0" xlow="0" yhigh="10" ylow="0"/><timing C="1" R="1"/><segment segment_id="0"/></node>'
        >>> r.create_edge_with_ids(1, 4, sw)
        Traceback (most recent call last):
          ...
        TypeError: RoutingNodeType.OPIN -> RoutingNodeType.SINK not valid, Only OPIN -> IPIN, CHANX, CHANY (IE A sink) is valid
        1 X000Y000[00].R-PIN> b'<node capacity="1" id="1" type="OPIN"><loc ptc="0" side="RIGHT" xhigh="0" xlow="0" yhigh="0" ylow="0"/><timing C="0" R="0"/></node>'
          ->
        4 X000Y010[00].SINK-< b'<node capacity="1" id="4" type="SINK"><loc ptc="0" xhigh="0" xlow="0" yhigh="10" ylow="10"/><timing C="0" R="0"/></node>'
        """

        id2node = self.id2element[RoutingNode]
        assert src_node_id in id2node, src_node_id
        src_node_type = RoutingNodeType.from_xml(id2node[src_node_id])
        assert sink_node_id in id2node, sink_node_id
        sink_node_type = RoutingNodeType.from_xml(id2node[sink_node_id])

        valid, msg = self._is_valid(src_node_type, sink_node_type)
        if not valid:
            src_node = id2node[src_node_id]
            sink_node = id2node[sink_node_id]
            raise TypeError("{} -> {} not valid, {}\n{} {}\n  ->\n{} {}".format(
                src_node_type,
                sink_node_type,
                msg,
                RoutingGraphPrinter.node(src_node),
                ET.tostring(src_node),
                RoutingGraphPrinter.node(sink_node),
                ET.tostring(sink_node),
            ))

        sw_bidir = switch.type in (SwitchType.SHORT, SwitchType.PASS_GATE)
        if bidir is None:
            bidir = sw_bidir
        elif sw_bidir:
            assert bidir, "Switch type {} must be bidir {} ({})".format(
                switch, (sw_bidir, bidir), (sink_node_id, src_node_id))

        self._create_edge_with_ids(src_node_id, sink_node_id, switch, metadata)

        valid, msg = self._is_valid(sink_node_type, src_node_type)
        if valid and bidir:
            self._create_edge_with_ids(sink_node_id, src_node_id, switch, metadata)

    @staticmethod
    def _is_valid(src_node_type, sink_node_type):
        valid = False
        if False:
            pass
        elif src_node_type == RoutingNodeType.IPIN:
            msg = "Only IPIN -> SINK valid"
            valid = (sink_node_type == RoutingNodeType.SINK)
        elif src_node_type == RoutingNodeType.OPIN:
            msg = "Only OPIN -> IPIN, CHANX, CHANY (IE A sink) is valid"
            valid = sink_node_type.can_sink
        elif src_node_type == RoutingNodeType.SINK:
            msg = "SINK can't be a source."
            valid = False
        elif src_node_type == RoutingNodeType.SOURCE:
            msg = "Only SOURCE -> OPIN is valid"
            valid = (sink_node_type == RoutingNodeType.OPIN)
        elif src_node_type == RoutingNodeType.CHANX:
            msg = "Only CHANX -> IPIN, CHANX, CHANY (IE A sink) is valid"
            valid = sink_node_type.can_sink
        elif src_node_type == RoutingNodeType.CHANY:
            msg = "Only CHANY -> IPIN, CHANX, CHANY (IE A sink) is valid"
            valid = sink_node_type.can_sink
        else:
            assert False
        return valid, msg

    def _create_edge_with_ids(self, src_node_id, sink_node_id, switch, metadata={}):
        # <edge src_node="34" sink_node="44" switch_id="1"/>
        assert_type(src_node_id, int)
        assert_type(sink_node_id, int)
        assert_type(switch, Switch)

        edge = RoutingEdge(
            attrib={
                'src_node': str(src_node_id),
                'sink_node': str(sink_node_id),
                'switch_id': str(switch.id)
            })

        for offset, values in metadata.items():
            for k, v in values.items():
                edge.set_metadata(k, v, offset=offset)

        self._add_xml_element(edge)

    def create_edge_with_nodes(self, src_node, sink_node, switch, metadata={}, bidir=None):
        """Create an RoutingEdge between given two RoutingNodes.

        Parameters
        ----------
        src_node : RoutingNode
        sink_node : RoutingNode
        switch : Switch

        Returns
        -------
        RoutingEdge
        """
        # <edge src_node="34" sink_node="44" switch_id="1"/>
        assert_type(src_node, ET._Element)
        assert_eq(src_node.tag, "node")
        assert_type(sink_node, ET._Element)
        assert_eq(sink_node.tag, "node")

        self.create_edge_with_ids(
            self._get_xml_id(src_node),
            self._get_xml_id(sink_node),
            switch,
            metadata=metadata,
            bidir=bidir)


def pin_meta_always_right(*a, **kw):
    return (RoutingNodeSide.RIGHT, Offset(0, 0))


class Graph:
    """
    Top level representation, holds the XML root
    For <rr_graph> node
    """

    def __init__(self,
                 rr_graph_file=None,
                 verbose=False,
                 clear_fabric=False,
                 switch_name=None,
                 pin_meta=pin_meta_always_right):
        """

        Parameters
        ----------
        rr_graph_file : filename
        verbose : bool
        clear_fabric : bool
            Remove the rr_graph (IE All nodes and edges - and thus channels too).
        pin_meta : callable(Block, Pin) -> (RoutingNodeSide, Offset)

        Examples
        --------

        Look at the segments via name or ID number;
        >>> g = simple_test_graph()
        >>> g.segments[0]
        Segment(id=0, name='local', ...)
        >>> g.segments["local"]
        Segment(id=0, name='local', ...)

        Look at the switches via name or ID number;
        >>> g = simple_test_graph()
        >>> g.switches[0]
        Switch(id=0, name='mux', type=<SwitchType.MUX: 'mux'>, ...)
        >>> g.switches[1]
        Switch(id=1, name='__vpr_delayless_switch__', type=<SwitchType.MUX: 'mux'>, ...)
        >>> g.switches["mux"]
        Switch(id=0, name='mux', type=<SwitchType.MUX: 'mux'>, ...)
        >>> g.switches["__vpr_delayless_switch__"]
        Switch(id=1, name='__vpr_delayless_switch__', type=<SwitchType.MUX: 'mux'>, ...)

        Look at the block grid;
        >>> g = simple_test_graph()
        >>> g.block_grid.size
        Size(w=4, h=3)
        >>> g.block_grid[Position(0, 0)]
        Block(..., position=P(x=0, y=0), offset=Offset(w=0, h=0))
        >>> g.block_grid[Position(2, 1)]
        Block(..., position=P(x=2, y=1), offset=Offset(w=0, h=0))
        >>> g.block_grid[Position(4, 4)]
        Traceback (most recent call last):
            ...
        KeyError: P(x=4, y=4)
        >>> g.block_grid.block_types["BLK_IG-IBUF"]
        BlockType(graph=..., id=1, name='BLK_IG-IBUF', size=Size(w=1, h=1), ...)
        >>> g.block_grid.block_types[2]
        BlockType(graph=..., id=2, name='BLK_IG-OBUF', size=Size(w=1, h=1), ...)
        >>> for block in g.block_grid.blocks_for(row=1):
        ...     print(block.position, block.block_type.name)
        P(x=0, y=1) BLK_IG-IBUF
        P(x=1, y=1) BLK_TI-TILE
        P(x=2, y=1) BLK_IG-OBUF
        P(x=3, y=1) EMPTY
        >>> for bt in g.block_grid.block_types_for(row=1):
        ...     print(bt.name)
        BLK_IG-IBUF
        BLK_TI-TILE
        BLK_IG-OBUF
        EMPTY

        """
        self.verbose = verbose

        self.segments = LookupMap(Segment)
        self.switches = LookupMap(Switch)

        # Read in existing file
        if rr_graph_file:
            self.block_grid = BlockGrid()
            self._xml_graph = ET.parse(
                rr_graph_file, ET.XMLParser(remove_blank_text=True))
            self._import_block_types()
            self._import_block_grid()
            self._import_segments()
            self._import_switches()
        else:
            self._xml_graph = ET.Element("rr_graph")
            ET.SubElement(self._xml_graph, "rr_nodes")
            ET.SubElement(self._xml_graph, "rr_edges")

            self.switches.add(
                Switch(
                    id=self.switches.next_id(),
                    type="mux",
                    name="__vpr_delayless_switch__"))

        self.routing = RoutingGraph(
            self._xml_graph, verbose=verbose, clear_fabric=clear_fabric)

        # Recreate the routing nodes for blocks if we cleared the routing
        if clear_fabric:
            switch = self.switches[switch_name]
            self.create_block_pins_fabric(switch=switch, pin_meta=pin_meta)
        else:
            self._index_pin_localnames()

        # Channels import requires rr_nodes
        self.channels = Channels(self.block_grid.size - Size(1, 1))
        if rr_graph_file:
            self._import_xml_channels()

    def _index_pin_localnames(self):
        for node in self.routing._xml_parent(RoutingNode):
            if node.tag == ET.Comment:
                continue

            ntype = node.get('type')
            loc = single_element(node, 'loc')
            pos_low, pos_high = node_pos(node)
            ptc = int(loc.get('ptc'))

            if ntype in ('IPIN', 'OPIN'):
                assert pos_low == pos_high, (pos_low, pos_high)
                pos = pos_low

                # Lookup Block/<grid_loc>
                # ptc is the associated pin ptc value of the block_type
                block = self.block_grid[pos]
                assert_type(block, Block)
                pin = block.ptc2pin(ptc)
                assert pin.name is not None, pin.name
                self.routing.localnames.add(pos, pin.name, node)

    def _import_block_types(self):
        # Create in the block_types information
        for block_type in self._xml_graph.iterfind("./block_types/block_type"):
            BlockType.from_xml(self.block_grid, block_type)

    def _import_block_grid(self):
        for block_xml in self._xml_graph.iterfind("./grid/grid_loc"):
            b = Block.from_xml(self.block_grid, block_xml)
            if b.offset == (0, 0):
                self.block_grid.add_block(b)
        size = self.block_grid.size
        assert size.x > 0
        assert size.y > 0

    def _import_segments(self):
        for segment_xml in self._xml_graph.iterfind("./segments/segment"):
            self.segments.add(Segment.from_xml(segment_xml))

    def _import_switches(self):
        for switch_xml in self._xml_graph.iterfind("./switches/switch"):
            self.switches.add(Switch.from_xml(switch_xml))

    def _import_xml_channels(self):
        self.channels.from_xml_nodes(self.routing._xml_parent(RoutingNode))

    def add_switch(self, sw):
        assert_type(sw, Switch)
        self.switches.add(sw)
        switches = single_element(self._xml_graph, "./switches")
        sw.to_xml(switches)

    def create_block_pins_fabric(self, switch=None, pin_meta=pin_meta_always_right):
        if switch is None:
            switch = self.switches[0]
        self.create_nodes_from_blocks(self.block_grid, switch, pin_meta)

    def set_tooling(self, name, version, comment):
        root = self._xml_graph.getroot()
        root.set("tool_name", name)
        root.set("tool_version", version)
        root.set("tool_comment", comment)

    def create_node_from_pin(self, block, pin, side, offset):
        """Creates an IPIN/OPIN RoutingNode from `class Pin` object.

        Parameters
        ----------
        block : Block
        pin : Pin
        side : RoutingNodeSide
        offset : Offset

        Returns
        -------
        RoutingNode
        """
        assert_type(block, Block)
        assert_type(pin, Pin)
        assert_type(pin.pin_class, PinClass)
        assert_type(pin.pin_class.block_type, BlockType)

        pc = pin.pin_class
        # Connection within the same tile
        pos = block.position + offset

        pin_node = None
        if pc.direction in (PinClassDirection.INPUT, PinClassDirection.CLOCK):
            pin_node = self.routing.create_node(
                pos, pos, pin.ptc, 'IPIN', side=side)
        elif pin.pin_class.direction in (PinClassDirection.OUTPUT, ):
            pin_node = self.routing.create_node(
                pos, pos, pin.ptc, 'OPIN', side=side)
        else:
            assert False, "Unknown dir of {}.{}".format(pin, pin.pin_class)

        assert pin_node != None, pin_node

        if self.verbose:
            print("Adding pin {:55s} on tile ({:12s}, {:12s})@{:4d} {}".format(
                str(pin), str(pos), str(pos), pin.ptc,
                RoutingGraphPrinter.node(pin_node, self.block_grid)))

        self.routing.localnames.add(pos, pin.name, pin_node)

        return pin_node

    def create_node_from_track(self, track, capacity=1):
        """
        Creates the CHANX/CHANY node for a Track object.

        Parameters
        ----------
        track : channels.Track

        Returns
        -------
        RoutingNode

        Examples
        --------
        """
        assert_type(track, Track)
        assert track.idx != None

        track_node = self.routing.create_node(
            track.start,
            track.end,
            track.idx,
            track.type.value,
            direction=track.direction,
            segment_id=track.segment_id,
            capacity=capacity)

        if track.name is not None:
            self.routing.globalnames.add(track.name, track_node)

        return track_node

    def create_nodes_from_pin_class(self, block, pin_class, switch, pin_meta):
        """Creates a SOURCE or SINK RoutingNode from a `class PinClass` object.

        Parameters
        ----------
        block : Block
        pin_class : PinClass
        switch : Switch
        pin_meta : callable(Block, Pin) -> (RoutingNodeSide, Offset)
        """
        assert_type(block, Block)
        assert_type(block.block_type, BlockType)
        assert_type(pin_class, PinClass)
        assert_type(pin_class.block_type, BlockType)
        assert_eq(block.block_type, pin_class.block_type)
        assert_type(switch, Switch)

        pos_low = block.position
        pos_high = block.position + pin_class.block_type.size - Size(1, 1)

        # Assuming only one pin per class for now
        assert len(
            pin_class.pins) == 1, 'Expect one pin per pin class, got %s' % (
                pin_class.pins, )

        pin = pin_class.pins[0]
        if pin_class.direction in (PinClassDirection.INPUT,
                                   PinClassDirection.CLOCK):
            # Sink node
            sink_node = self.routing.create_node(
                pos_low, pos_high, pin.ptc, 'SINK')

            if self.verbose:
                print("Adding snk {:55s} on tile ({:12s}, {:12s}) {}".format(
                    str(pin_class), str(pos_low), str(pos_high),
                    RoutingGraphPrinter.node(sink_node, self.block_grid)))

            for p in pin_class.pins:
                pin_node = self.create_node_from_pin(block, p, *pin_meta(block, p))

                # Edge PIN->SINK
                self.routing.create_edge_with_nodes(
                        pin_node, sink_node, switch)

        elif pin_class.direction in (PinClassDirection.OUTPUT, ):
            # Source node
            src_node = self.routing.create_node(
                pos_low, pos_high, pin.ptc, 'SOURCE')

            if self.verbose:
                print("Adding src {:55s} on tile ({:12s}, {:12s}) {}".format(
                    str(pin_class), str(pos_low), str(pos_high),
                    RoutingGraphPrinter.node(src_node, self.block_grid)))

            for p in pin_class.pins:
                pin_node = self.create_node_from_pin(block, p, *pin_meta(block, p))

                # Edge SOURCE->PIN
                self.routing.create_edge_with_nodes(
                        src_node, pin_node, switch)

        else:
            assert False, "Unknown dir of {} for {}".format(
                pin_class.direction, str(pin_class))

    def create_nodes_from_block(self, block, switch, pin_meta):
        """
        Creates the SOURCE/SINK nodes for each pin class
        Creates the IPIN/OPIN nodes for each pin inside a pin class.
        Creates the edges which connect these together.

        Parameters
        ----------
        block : Block
        switch : Switch
        pin_meta : callable(Block, Pin) -> (RoutingNodeSide, Offset)

        Examples
        --------
        """
        for pc in block.block_type.pin_classes:
            self.create_nodes_from_pin_class(block, pc, switch, pin_meta)

    def create_nodes_from_blocks(self, blocks, switch, pin_meta):
        """
        Parameters
        ----------
        block : Block
        switch : Switch
        pin_meta : callable(Block, Pin) -> (RoutingNodeSide, Offset)
        """
        for block in blocks:
            self.create_nodes_from_block(block, switch, pin_meta)

    def connect_pin_to_track(self, block, pin, track, switch):
        """
        Create an edge from given pin in block to given track with switching properties of switch
        """
        assert_type(block, Block)
        assert_type(pin, Pin)
        assert_type(track, Track)
        assert_type(switch, Switch)

        pin_node = self.routing.localnames[(block.position, pin.name)]
        track_node = self.routing.globalnames[track.name]
        if pin.direction == PinClassDirection.OUTPUT:
            self.routing.create_edge_with_nodes(pin_node, track_node, switch)
        else:
            self.routing.create_edge_with_nodes(track_node, pin_node, switch)

    def connect_track_to_track(self, src, dst, switch):
        assert_type(src, Track)
        assert_type(dst, Track)
        src_node = self.routing.globalnames[src.name]
        dst_node = self.routing.globalnames[dst.name]
        self.routing.create_edge_with_nodes(src_node, dst_node, switch)

    def create_xy_track(self,
                        start,
                        end,
                        segment,
                        idx=None,
                        name=None,
                        typeh=None,
                        direction=None,
                        capacity=1):
        """Create track object and corresponding nodes"""
        if not isinstance(start, Position):
            start = Position(*start)
        assert_type(start, Position)
        if not isinstance(end, Position):
            end = Position(*end)
        assert_type(end, Position)

        track = self.channels.create_xy_track(
            start,
            end,
            segment.id,
            idx=idx,
            name=name,
            typeh=typeh,
            direction=direction)
        track_node = self.create_node_from_track(track, capacity)

        return track, track_node

    def pad_channels(self, segment):
        """Workaround for https://github.com/verilog-to-routing/vtr-verilog-to-routing/issues/339"""
        for track in self.channels.pad_channels(segment):
            self.create_node_from_track(track, capacity=0)

    def extract_pin_meta(self):
        """Export pin placement as pin_meta[(block, pin)] to import when rebuilding pin nodes"""
        sides = MappingLocalNames(type=RoutingNodeSide)
        offsets = MappingLocalNames(type=Offset)
        for block in self.block_grid:
            for pin_class in block.block_type.pin_classes:
                for pin in pin_class.pins:
                    for offset in block.block_type.positions:
                        pos = block.position + offset
                        try:
                            node = self.routing.localnames[(pos, pin.name)]
                        except KeyError:
                            continue

                        assert node != None, "{}:{} not found at {}\n{}".format(block, pin.name, list(block.positions), self.routing.localnames)
                        side = single_element(node, 'loc').get('side')
                        assert side is not None, ET.tostring(node)
                        sides[(block.position, pin.name)] = RoutingNodeSide(side)
                        offsets[(block.position, pin.name)] = offset
        return sides, offsets

    def to_xml(self):
        """Return an ET object representing this rr_graph"""
        #et = ET.fromstring('<rr_graph tool_name="g.py" tool_version="dev" tool_comment="Generated from black magic" />')
        #return et
        self.set_tooling("g.py", "dev", "Generated from black magic")

        # <rr_nodes>, <rr_edges>, and <switches> should be good as is
        # note <rr_nodes> includes channel tracks, but not width definitions

        # FIXME: regenerate <block_types>
        # FIXME: regenerate <grid>

        self.channels.to_xml(self._xml_graph)
        return self._xml_graph

    def connect_all(self, start, end, name, segment, metadata={}, spine=None, switch=None):
        """Add a track which is present at all tiles within a range.

        Returns:
            List of ET.RoutingNode
        """
        assert_type(start, Position)
        assert_type(end, Position)
        assert_type(name, str)
        assert_type(segment, Segment)
        assert_type(metadata, dict)
        assert_type_or_none(spine, int)
        if spine is None:
            spine = start.y + (end.y-start.y)//2

        assert start.x <= end.x, "x - {} < {}".format(start, end)
        assert start.y <= end.y, "y - {} < {}".format(start, end)

        if switch is None:
            switch = self.switches["short"]

        # Vertical wires
        v_tracks = []
        for x in range(start.x, end.x+1):
            spos = Position(x, start.y)
            epos = Position(x, end.y)
            track, track_node = self.create_xy_track(
                spos, epos,
                segment=segment,
                typeh=Track.Type.Y,
                direction=Track.Direction.BI)
            v_tracks.append(track_node)

            for offset, values in metadata.items():
                for k, v in values.items():
                    track_node.set_metadata(k, v, offset=offset)

            for y in range(start.y, end.y+1):
                pos = Position(x, y)
                self.routing.localnames.add(
                    pos, name, track_node)

        # One horizontal wire
        spos = Position(start.x, spine)
        epos = Position(end.x, spine)
        track, track_node = self.create_xy_track(
            spos, epos,
            segment=segment,
            typeh=Track.Type.X,
            direction=Track.Direction.BI)

        for offset, values in metadata.items():
            for k, v in values.items():
                track_node.set_metadata(k, v, offset=offset)

        for x in range(start.x, end.x+1):
            pos = Position(x, spine)
            self.routing.localnames.add(
                pos, name+"_h", track_node)

        assert_eq(len(v_tracks), len(range(start.x, end.x+1)))
        # Connect the vertical wires to the horizontal one to make a single
        # global network
        for i, x in enumerate(range(start.x, end.x+1)):
            pos = Position(x, spine)
            self.routing.create_edge_with_nodes(
                v_tracks[i], track_node, switch, bidir=True)

        return v_tracks + [track_node]


def simple_test_routing():
    """
    >>> r = simple_test_routing()
    """
    routing = RoutingGraph()
    routing.create_node(
        Position(0, 0), Position(0, 0), 0, ntype=RoutingNodeType.SOURCE)
    routing.create_node(
        Position(0, 0),
        Position(0, 0),
        0,
        ntype=RoutingNodeType.OPIN,
        side=RoutingNodeSide.RIGHT)
    routing.create_node(
        Position(0, 0),
        Position(0, 10),
        0,
        ntype=RoutingNodeType.CHANX,
        segment_id=0,
        direction=RoutingNodeDir.BI_DIR)
    routing.create_node(
        Position(0, 10),
        Position(0, 10),
        0,
        ntype=RoutingNodeType.IPIN,
        side=RoutingNodeSide.LEFT)
    routing.create_node(
        Position(0, 10), Position(0, 10), 0, ntype=RoutingNodeType.SINK)
    sw = Switch(id=0, name="sw", type=SwitchType.MUX)
    routing.create_edge_with_ids(0, 1, sw)  # SRC->OPIN
    routing.create_edge_with_ids(1, 2, sw)  # OPIN->CHANX
    routing.create_edge_with_ids(2, 3, sw)  # CHANX->IPIN
    routing.create_edge_with_ids(3, 4, sw)  # IPIN->SINK
    return routing


def simple_test_block_grid():
    """
    >>> bg = simple_test_block_grid()
    """
    bg = BlockGrid()

    # Create a block type with one input and one output pin
    bt = BlockType(g=bg, id=0, name="DUALBLK")
    pci = PinClass(block_type=bt, direction=PinClassDirection.INPUT)
    pi = Pin(pin_class=pci, port_name="A", port_index=0)
    pco = PinClass(block_type=bt, direction=PinClassDirection.OUTPUT)
    po = Pin(pin_class=pco, port_name="B", port_index=0)

    # Create a block type with one input class with 4 pins
    bt = BlockType(g=bg, id=1, name="INBLOCK")
    pci = PinClass(block_type=bt, direction=PinClassDirection.INPUT)
    Pin(pin_class=pci, port_name="C", port_index=0)
    Pin(pin_class=pci, port_name="C", port_index=1)
    Pin(pin_class=pci, port_name="C", port_index=2)
    Pin(pin_class=pci, port_name="C", port_index=3)

    # Create a block type with out input class with 2 pins
    bt = BlockType(g=bg, id=2, name="OUTBLOK")
    pci = PinClass(block_type=bt, direction=PinClassDirection.OUTPUT)
    Pin(pin_class=pci, port_name="D", port_index=0)
    Pin(pin_class=pci, port_name="D", port_index=1)
    Pin(pin_class=pci, port_name="D", port_index=2)
    Pin(pin_class=pci, port_name="D", port_index=3)

    # Add some blocks
    bg.add_block(Block(g=bg, block_type_id=1, position=Position(0, 0)))
    bg.add_block(Block(g=bg, block_type_id=1, position=Position(0, 1)))
    bg.add_block(Block(g=bg, block_type_id=1, position=Position(0, 2)))
    bg.add_block(Block(g=bg, block_type_id=1, position=Position(0, 3)))

    bg.add_block(Block(g=bg, block_type_id=0, position=Position(1, 0)))
    bg.add_block(Block(g=bg, block_type_id=0, position=Position(1, 1)))
    bg.add_block(Block(g=bg, block_type_id=0, position=Position(1, 2)))
    bg.add_block(Block(g=bg, block_type_id=0, position=Position(1, 3)))

    bg.add_block(Block(g=bg, block_type_id=0, position=Position(2, 0)))
    bg.add_block(Block(g=bg, block_type_id=0, position=Position(2, 1)))
    bg.add_block(Block(g=bg, block_type_id=0, position=Position(2, 2)))
    bg.add_block(Block(g=bg, block_type_id=0, position=Position(2, 3)))

    bg.add_block(Block(g=bg, block_type_id=2, position=Position(3, 0)))
    bg.add_block(Block(g=bg, block_type_id=2, position=Position(3, 1)))
    bg.add_block(Block(g=bg, block_type_id=2, position=Position(3, 2)))
    bg.add_block(Block(g=bg, block_type_id=2, position=Position(3, 3)))

    return bg


def simple_test_graph(**kwargs):
    """
    Simple graph, containing one input block, one pass through block and one
    output block, with some routing between them.

    The rr_graph was generated by running the following in the tests directory;
    # make \\
        ARCH=testarch \\
        DEVICE_SUBARCH=wire-bidir-min \\
        DEVICE=1x1.min \\
        ROUTE_CHAN_WIDTH=1 \\
        clean wire.rr_graph.xml

    >>> g = simple_test_graph()
    """

    xml_str = """
<rr_graph tool_name="vpr" tool_version="ga5684b2e4" tool_comment="symbiflow-arch-defs/testarch/devices/wire-bidir-min/arch.merged.xml">
    <channels>
        <channel chan_width_max ="1" x_min="1" y_min="1" x_max="1" y_max="1"/>
        <x_list index ="0" info="1"/>
        <x_list index ="1" info="1"/>
        <y_list index ="0" info="1"/>
        <y_list index ="1" info="1"/>
        <y_list index ="2" info="1"/>
    </channels>
    <switches>
        <switch id="0" type="mux" name="mux">
            <timing R="551" Cin="7.70000012e-16" Cout="4.00000001e-15" Tdel="5.80000006e-11"/>
            <sizing mux_trans_size="2.63073993" buf_size="27.6459007"/>
        </switch>
        <switch id="1" type="mux" name="__vpr_delayless_switch__">
            <timing R="0" Cin="0" Cout="0" Tdel="0"/>
            <sizing mux_trans_size="0" buf_size="0"/>
        </switch>
    </switches>

    <segments>
        <segment id="0" name="local">
            <timing R_per_meter="101" C_per_meter="2.25000005e-14"/>
        </segment>
    </segments>

    <block_types>
        <block_type id="0" name="EMPTY" width="1" height="1">
        </block_type>
        <block_type id="1" name="BLK_IG-IBUF" width="1" height="1">
            <pin_class type="OUTPUT">
                <pin ptc="0">BLK_IG-IBUF.I[0]</pin>
            </pin_class>
        </block_type>
        <block_type id="2" name="BLK_IG-OBUF" width="1" height="1">
            <pin_class type="INPUT">
                <pin ptc="0">BLK_IG-OBUF.O[0]</pin>
            </pin_class>
        </block_type>
        <block_type id="3" name="BLK_TI-TILE" width="1" height="1">
            <pin_class type="INPUT">
                <pin ptc="0">BLK_TI-TILE.IN[0]</pin>
            </pin_class>
            <pin_class type="OUTPUT">
                <pin ptc="1">BLK_TI-TILE.OUT[0]</pin>
            </pin_class>
        </block_type>
    </block_types>

    <grid>
        <grid_loc x="0" y="0" block_type_id="0" width_offset="0" height_offset="0"/>
        <grid_loc x="0" y="1" block_type_id="1" width_offset="0" height_offset="0"/>
        <grid_loc x="0" y="2" block_type_id="0" width_offset="0" height_offset="0"/>
        <grid_loc x="1" y="0" block_type_id="0" width_offset="0" height_offset="0"/>
        <grid_loc x="1" y="1" block_type_id="3" width_offset="0" height_offset="0"/>
        <grid_loc x="1" y="2" block_type_id="0" width_offset="0" height_offset="0"/>
        <grid_loc x="2" y="0" block_type_id="0" width_offset="0" height_offset="0"/>
        <grid_loc x="2" y="1" block_type_id="2" width_offset="0" height_offset="0"/>
        <grid_loc x="2" y="2" block_type_id="0" width_offset="0" height_offset="0"/>
        <grid_loc x="3" y="0" block_type_id="0" width_offset="0" height_offset="0"/>
        <grid_loc x="3" y="1" block_type_id="0" width_offset="0" height_offset="0"/>
        <grid_loc x="3" y="2" block_type_id="0" width_offset="0" height_offset="0"/>
    </grid>

    <rr_nodes>
        <node id="0" type="SOURCE" capacity="1">
            <loc xlow="0" ylow="1" xhigh="0" yhigh="1" ptc="0"/>
            <timing R="0" C="0"/>
        </node>
        <node id="1" type="OPIN" capacity="1">
            <loc xlow="0" ylow="1" xhigh="0" yhigh="1" side="RIGHT" ptc="0"/>
            <timing R="0" C="0"/>
        </node>
        <node id="2" type="SINK" capacity="1">
            <loc xlow="1" ylow="1" xhigh="1" yhigh="1" ptc="0"/>
            <timing R="0" C="0"/>
        </node>
        <node id="3" type="SOURCE" capacity="1">
            <loc xlow="1" ylow="1" xhigh="1" yhigh="1" ptc="1"/>
            <timing R="0" C="0"/>
        </node>
        <node id="4" type="IPIN" capacity="1">
            <loc xlow="1" ylow="1" xhigh="1" yhigh="1" side="RIGHT" ptc="0"/>
            <timing R="0" C="0"/>
        </node>
        <node id="5" type="OPIN" capacity="1">
            <loc xlow="1" ylow="1" xhigh="1" yhigh="1" side="RIGHT" ptc="1"/>
            <timing R="0" C="0"/>
        </node>
        <node id="6" type="SINK" capacity="1">
            <loc xlow="2" ylow="1" xhigh="2" yhigh="1" ptc="0"/>
            <timing R="0" C="0"/>
        </node>
        <node id="7" type="IPIN" capacity="1">
            <loc xlow="2" ylow="1" xhigh="2" yhigh="1" side="RIGHT" ptc="0"/>
            <timing R="0" C="0"/>
        </node>
        <node id="8" type="CHANX" direction="BI_DIR" capacity="1">
            <loc xlow="1" ylow="0" xhigh="1" yhigh="0" ptc="0"/>
            <timing R="101" C="3.60400017e-14"/>
            <segment segment_id="0"/>
        </node>
        <node id="9" type="CHANX" direction="BI_DIR" capacity="1">
            <loc xlow="2" ylow="0" xhigh="2" yhigh="0" ptc="0"/>
            <timing R="101" C="3.60400017e-14"/>
            <segment segment_id="0"/>
        </node>
        <node id="10" type="CHANX" direction="BI_DIR" capacity="1">
            <loc xlow="1" ylow="1" xhigh="1" yhigh="1" ptc="0"/>
            <timing R="101" C="3.60400017e-14"/>
            <segment segment_id="0"/>
        </node>
        <node id="11" type="CHANX" direction="BI_DIR" capacity="1">
            <loc xlow="2" ylow="1" xhigh="2" yhigh="1" ptc="0"/>
            <timing R="101" C="3.60400017e-14"/>
            <segment segment_id="0"/>
        </node>
        <node id="12" type="CHANY" direction="BI_DIR" capacity="1">
            <loc xlow="0" ylow="1" xhigh="0" yhigh="1" ptc="0"/>
            <timing R="101" C="3.60400017e-14"/>
            <segment segment_id="0"/>
        </node>
        <node id="13" type="CHANY" direction="BI_DIR" capacity="1">
            <loc xlow="1" ylow="1" xhigh="1" yhigh="1" ptc="0"/>
            <timing R="101" C="4.48100012e-14"/>
            <segment segment_id="0"/>
        </node>
        <node id="14" type="CHANY" direction="BI_DIR" capacity="1">
            <loc xlow="2" ylow="1" xhigh="2" yhigh="1" ptc="0"/>
            <timing R="101" C="3.28100008e-14"/>
            <segment segment_id="0"/>
        </node>
    </rr_nodes>

    <rr_edges>
        <edge src_node="0" sink_node="1" switch_id="1"/>
        <edge src_node="1" sink_node="12" switch_id="0"/>
        <edge src_node="3" sink_node="5" switch_id="1"/>
        <edge src_node="4" sink_node="2" switch_id="1"/>
        <edge src_node="5" sink_node="13" switch_id="0"/>
        <edge src_node="7" sink_node="6" switch_id="1"/>
        <edge src_node="8" sink_node="9" switch_id="0"/>
        <edge src_node="8" sink_node="13" switch_id="0"/>
        <edge src_node="8" sink_node="12" switch_id="0"/>
        <edge src_node="9" sink_node="8" switch_id="0"/>
        <edge src_node="9" sink_node="14" switch_id="0"/>
        <edge src_node="9" sink_node="13" switch_id="0"/>
        <edge src_node="10" sink_node="11" switch_id="0"/>
        <edge src_node="10" sink_node="13" switch_id="0"/>
        <edge src_node="10" sink_node="12" switch_id="0"/>
        <edge src_node="11" sink_node="10" switch_id="0"/>
        <edge src_node="11" sink_node="14" switch_id="0"/>
        <edge src_node="11" sink_node="13" switch_id="0"/>
        <edge src_node="12" sink_node="10" switch_id="0"/>
        <edge src_node="12" sink_node="8" switch_id="0"/>
        <edge src_node="13" sink_node="11" switch_id="0"/>
        <edge src_node="13" sink_node="9" switch_id="0"/>
        <edge src_node="13" sink_node="10" switch_id="0"/>
        <edge src_node="13" sink_node="8" switch_id="0"/>
        <edge src_node="13" sink_node="4" switch_id="0"/>
        <edge src_node="14" sink_node="11" switch_id="0"/>
        <edge src_node="14" sink_node="9" switch_id="0"/>
        <edge src_node="14" sink_node="7" switch_id="0"/>
    </rr_edges>
</rr_graph>
"""
    return Graph(io.StringIO(xml_str), **kwargs)


def test_create_block_pins_fabric():
    """
    >>> test_create_block_pins_fabric()
    """
    # 2 input pins, 2 output pins
    # - 2 * SINK,   2 * IPIN, 2 edges
    # - 2 * SOURCE, 2 * OPIN, 2 edges
    # Should have added 4 edges to connect edge to pin
    g1 = simple_test_graph()

    # Clear the fabric
    g1.routing.clear()
    assert_eq(len(g1.routing._xml_parent(RoutingNode)), 0)
    assert_eq(len(g1.routing._xml_parent(RoutingEdge)), 0)

    # Create the fabric for the block pins
    g1.create_block_pins_fabric()
    assert_eq(len(g1.routing._xml_parent(RoutingNode)), 8)
    assert_eq(len(g1.routing._xml_parent(RoutingEdge)), 4)

    # Check clearing on import
    g2 = simple_test_graph(clear_fabric=True)
    assert_eq(len(g2.routing._xml_parent(RoutingNode)), 8)
    assert_eq(len(g2.routing._xml_parent(RoutingEdge)), 4)


def node_ptc(node):
    locs = list(node.iterfind("loc"))
    assert len(locs) == 1, locs
    loc = locs[0]
    return int(loc.get('ptc'))


def main():
    import doctest

    print('Doctest begin')
    doctest.testmod(optionflags=doctest.ELLIPSIS)
    print('Doctest end')


if __name__ == "__main__":
    main()
