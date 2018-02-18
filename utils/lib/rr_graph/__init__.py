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

_Size = namedtuple("Size", ("x", "y"))
class Size(_Size):
    def __new__(cls, x, y):
        assert x > 0
        assert y > 0
        return Position.__new__(cls, x, y)

    @static_property
    def width(self):
        return self.x

    @static_property
    def height(self):
        return self.y

    def walk(self):
        for x in self.x:
            for y in self.y:
                yield Position(x, y)


class Offset(Size):
    pass
