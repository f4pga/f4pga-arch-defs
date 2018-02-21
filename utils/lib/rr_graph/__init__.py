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

    def __get__(self, instance, owner):
        # Build the attribute.
        attr = self._factory(instance)

        # Cache the value; hide ourselves.
        setattr(instance, self._attr_name, attr)

        return attr


Position = namedtuple("P", ("x", "y"))
Pos = Position # Shorter Alias
P = Position   # Even shorter alias

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
            return o.__class__(o.x+self.x, o.y+self.y)
        elif isinstance(o, Size):
            return o.__class__(o.x+self.x, o.y+self.y)
        return NotImplemented

    def __radd__(self, o):
        if isinstance(o, Position):
            return o.__class__(o.x+self.x, o.y+self.y)
        elif isinstance(o, Size):
            return o.__class__(o.x+self.x, o.y+self.y)
        return NotImplemented


class Offset(Size):
    pass
