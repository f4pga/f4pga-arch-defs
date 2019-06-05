#!/usr/bin/env python3

import enum
import io
import pprint
import sys

from types import MappingProxyType


def frozendict(*args, **kwargs):
    """Version of a dictionary which can't be changed."""
    return MappingProxyType(dict(*args, **kwargs))


class MostlyReadOnly:
    """Object which is **mostly** read only. Can set if not already set.

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
    AttributeError: 'MyRO' object has no attribute 'missing'
    >>> a.missing = 1
    Traceback (most recent call last):
        ...
    AttributeError: missing not found on <class 'lib.collections_extra.MyRO'>
    >>> a.missing
    Traceback (most recent call last):
        ...
    AttributeError: 'MyRO' object has no attribute 'missing'
    """

    def __setattr__(self, key, new_value=None):
        if key.startswith("_"):
            current_value = getattr(self, key[1:])
            if new_value == current_value:
                return
            elif current_value is not None:
                raise AttributeError(
                    "{} is already set to {}, can't be changed".format(
                        key, current_value
                    )
                )
            return super().__setattr__(key, new_value)

        if "_" + key not in self.__class__.__slots__:
            raise AttributeError(
                "{} not found on {}".format(key, self.__class__)
            )

        self.__setattr__("_" + key, new_value)

    def __getattr__(self, key):
        if "_" + key not in self.__class__.__slots__:
            super().__getattribute__(key)

        value = getattr(self, "_" + key, None)
        if isinstance(value,
                      (tuple, int, bytes, str, type(None), MostlyReadOnly)):
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
                "Unable to return {}, don't now how to make type {} (from {!r}) read only."
                .format(key, type(value), value)
            )

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


class OrderedEnum(enum.Enum):
    def __ge__(self, other):
        if self.__class__ is other.__class__:
            return self.name >= other.name
        if hasattr(other.__class__, "name"):
            return self.name >= other.name
        return NotImplemented

    def __gt__(self, other):
        if self.__class__ is other.__class__:
            return self.name > other.name
        if hasattr(other.__class__, "name"):
            return self.name > other.name
        return NotImplemented

    def __le__(self, other):
        if self.__class__ is other.__class__:
            return self.name <= other.name
        if hasattr(other.__class__, "name"):
            return self.name <= other.name
        return NotImplemented

    def __lt__(self, other):
        if self.__class__ is other.__class__:
            return self.name < other.name
        if hasattr(other.__class__, "name"):
            return self.name < other.name
        return NotImplemented


class CompassDir(OrderedEnum):
    """
    >>> print(repr(CompassDir.NN))
    <CompassDir.NN: 'North'>
    >>> print(str(CompassDir.NN))
    ( 0, -1, NN)
    >>> for d in CompassDir:
    ...     print(OrderedEnum.__str__(d))
    CompassDir.NW
    CompassDir.NN
    CompassDir.NE
    CompassDir.EE
    CompassDir.SE
    CompassDir.SS
    CompassDir.SW
    CompassDir.WW
    >>> for y in (-1, 0, 1):
    ...     for x in (-1, 0, 1):
    ...         print(
    ...             "(%2i %2i)" % (x, y),
    ...             str(CompassDir.from_coords(x, y)),
    ...             str(CompassDir.from_coords((x, y))),
    ...             )
    (-1 -1) (-1, -1, NW) (-1, -1, NW)
    ( 0 -1) ( 0, -1, NN) ( 0, -1, NN)
    ( 1 -1) ( 1, -1, NE) ( 1, -1, NE)
    (-1  0) (-1,  0, WW) (-1,  0, WW)
    ( 0  0) None None
    ( 1  0) ( 1,  0, EE) ( 1,  0, EE)
    (-1  1) (-1,  1, SW) (-1,  1, SW)
    ( 0  1) ( 0,  1, SS) ( 0,  1, SS)
    ( 1  1) ( 1,  1, SE) ( 1,  1, SE)
    >>> print(str(CompassDir.NN.flip()))
    ( 0,  1, SS)
    >>> print(str(CompassDir.SE.flip()))
    (-1, -1, NW)
    """
    NW = 'North West'
    NN = 'North'
    NE = 'North East'
    EE = 'East'
    SE = 'South East'
    SS = 'South'
    SW = 'South West'
    WW = 'West'
    # Single letter aliases
    N = NN
    E = EE
    S = SS
    W = WW

    @property
    def distance(self):
        return sum(a * a for a in self.coords)

    def __init__(self, *args, **kw):
        self.__cords = None
        pass

    @property
    def coords(self):
        if not self.__cords:
            self.__cords = self.convert_to_coords[self]
        return self.__cords

    @property
    def x(self):
        return self.coords[0]

    @property
    def y(self):
        return self.coords[-1]

    def __iter__(self):
        return iter(self.coords)

    def __getitem__(self, k):
        return self.coords[k]

    @classmethod
    def from_coords(cls, x, y=None):
        if y is None:
            return cls.from_coords(*x)
        return cls.convert_from_coords[(x, y)]

    def flip(self):
        return self.from_coords(self.flip_coords[self.coords])

    def __add__(self, o):
        return o.__class__(o[0] + self.x, o[1] + self.y)

    def __radd__(self, o):
        return o.__class__(o[0] + self.x, o[1] + self.y)

    def __str__(self):
        return "(%2i, %2i, %s)" % (self.x, self.y, self.name)


CompassDir.convert_to_coords = {}
CompassDir.convert_from_coords = {}
CompassDir.flip_coords = {}
CompassDir.straight = []
CompassDir.angled = []
for d in list(CompassDir) + [None]:
    if d is None:
        x, y = 0, 0
    else:
        if d.name[0] == 'N':
            y = -1
        elif d.name[0] == 'S':
            y = 1
        else:
            assert d.name[0] in ('E', 'W')
            y = 0

        if d.name[1] == 'E':
            x = 1
        elif d.name[1] == 'W':
            x = -1
        else:
            assert d.name[1] in ('N', 'S')
            x = 0

    CompassDir.convert_to_coords[d] = (x, y)
    CompassDir.convert_from_coords[(x, y)] = d
    CompassDir.flip_coords[(x, y)] = (-1 * x, -1 * y)

    length = x * x + y * y
    if length == 1:
        CompassDir.straight.append(d)
    elif length == 2:
        CompassDir.angled.append(d)

if __name__ == "__main__":
    import doctest
    failure_count, test_count = doctest.testmod()
    assert test_count > 0
    assert failure_count == 0, "Doctests failed!"
