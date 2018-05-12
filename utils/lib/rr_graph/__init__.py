#!/usr/bin/env python3
from collections import namedtuple


class static_property(object):
    """
    Descriptor (non-data) for building an attribute on-demand on first use.
    """

    def __init__(self, factory):
        """
        <factory> is called such: factory(instance) to build the attribute.
        """
        self._attr_name = factory.__name__
        self._factory = factory
        self.__doc__ = factory.__doc__

    def __get__(self, instance, owner):
        if instance is None:
            return self

        # Build the attribute.
        attr = self._factory(instance)

        # Cache the value; hide ourselves.
        setattr(instance, self._attr_name, attr)

        return attr


# FIXME: define operators
Position = namedtuple("P", ("x", "y"))
P = Position  # Even shorter alias

_Size = namedtuple("Size", ("w", "h"))


class Size(_Size):
    """
    >>> s = Size(2, 3)
    >>> s
    Size(w=2, h=3)
    >>> p = Position(4, 5)
    >>> s + p
    P(x=6, y=8)
    >>> s + s
    Size(w=4, h=6)
    >>> s + 1
    Traceback (most recent call last):
       ...
    TypeError: unsupported operand type(s) for +: 'Size' and 'int'
    """

    def __new__(cls, w, h):
        assert w >= 0
        assert h >= 0
        return _Size.__new__(cls, w, h)

    @static_property
    def width(self):
        return self.w

    @static_property
    def height(self):
        return self.h

    @static_property
    def x(self):
        return self.w

    @static_property
    def y(self):
        return self.h

    def walk(self):
        for x in range(0, self.x):
            for y in range(0, self.y):
                yield Position(x, y)

    def __add__(self, o):
        if isinstance(o, Position):
            return o.__class__(o.x + self.x, o.y + self.y)
        elif isinstance(o, Size):
            return o.__class__(o.x + self.x, o.y + self.y)
        return NotImplemented

    def __radd__(self, o):
        if isinstance(o, Position):
            return o.__class__(o.x + self.x, o.y + self.y)
        elif isinstance(o, Size):
            return o.__class__(o.x + self.x, o.y + self.y)
        return NotImplemented

    def __sub__(self, o):
        if isinstance(o, Position):
            return o.__class__(self.x - o.x, self.y - o.y)
        elif isinstance(o, Size):
            return o.__class__(self.x - o.x, self.y - o.y)
        return NotImplemented

    def __rsub__(self, o):
        if isinstance(o, Position):
            return o.__class__(o.x - self.x, o.y - self.y)
        elif isinstance(o, Size):
            return o.__class__(o.x - self.x, o.y - self.y)
        return NotImplemented


S = Size


class Offset(Size):
    pass


O = Offset


def single_element(parent, name):
    '''Return given single XML child entry in parent'''
    elements = list(parent.iterfind(name))
    assert len(elements) == 1, elements
    return elements[0]


def node_pos(node):
    # node as node_xml
    loc = single_element(node, 'loc')
    pos_low = Position(int(loc.get('xlow')), int(loc.get('ylow')))
    pos_high = Position(int(loc.get('xhigh')), int(loc.get('yhigh')))
    return pos_low, pos_high
