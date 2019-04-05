#!/usr/bin/env python3
"""
This file for packing tracks into channels.

It does *not* manage channel XML nodes.

Note channels go between switchboxes. Switchboxes cannot be at the last grid
coordinate.

Therefore, you need a grid size of at least 3 rows or cols to allow any
channels to exist. With a 3 width configuration you would get a channel of
length 0, connecting the switchbox at 0 to the switchbox at 1.

With above in mind, objects here entirely omit the last row/col and placing a
channel in the first is illegal.

Specifically:
 * For CHANX: X=0 is invalid, X=grid.width-1 is invalid
 * For CHANY: Y=0 is invalid, Y=grid.height-1 is invalid
"""

import pprint
import enum
import io
from collections import namedtuple, OrderedDict
import lxml.etree as ET

from . import Position
from . import Size

# FIXME: doctests and static_property are not playing nice together.
#from . import static_property
static_property = property

from . import node_pos, single_element
from ..asserts import assert_eq
from ..asserts import assert_len_eq
from ..asserts import assert_type
from ..asserts import assert_type_or_none


class ChannelNotStraight(TypeError):
    pass


_Track = namedtuple(
    "Track", ("start", "end", "direction", "segment_id", "idx")
)


class Track(_Track):
    """
    Represents a single CHANX or CHANY (track) within a channel.

    IE The tracks of a x_list or y_list entry in <channels> element.

    start: start Pos
    end: end Pos
    idx: XML index integer
    """

    class Type(enum.Enum):
        # Horizontal routing
        X = 'CHANX'
        # Vertical routing
        Y = 'CHANY'

        def __repr__(self):
            return 'Track.Type.' + self.name

    class Direction(enum.Enum):
        INC = 'INC_DIR'
        DEC = 'DEC_DIR'
        BI = 'BI_DIR'

        def __repr__(self):
            return 'Track.Direction.' + self.name

    def __new__(
            cls,
            start,
            end,
            direction=Direction.INC,
            segment_id=0,
            idx=None,
            name=None,
            type_hint=None,
    ):
        """Make most but not all attributes immutable"""

        if not isinstance(start, Position):
            start = Position(*start)
        assert_type(start, Position)
        if not isinstance(end, Position):
            end = Position(*end)
        assert_type(end, Position)

        if start.x != end.x and start.y != end.y:
            raise ChannelNotStraight(
                "Track not straight! {}->{}".format(start, end)
            )

        assert_type(direction, cls.Direction)
        assert_type(segment_id, int)
        assert_type_or_none(idx, int)
        assert_type_or_none(name, str)
        assert_type_or_none(type_hint, cls.Type)

        obj = _Track.__new__(cls, start, end, direction, segment_id, idx)
        obj.name = name
        obj.type_hint = type_hint
        return obj

    @static_property
    def type(self):
        """Type of the channel.

        Returns: Track.Type

        >>> Track((1, 0), (10, 0)).type
        Track.Type.X
        >>> Track((0, 1), (0, 10)).type
        Track.Type.Y
        >>> Track((1, 1), (1, 1)).type
        Traceback (most recent call last):
            ...
        ValueError: Ambiguous type
        >>> Track((1, 1), (1, 1), type_hint=Track.Type.X).type
        Track.Type.X
        >>> Track((1, 1), (1, 1), type_hint=Track.Type.Y).type
        Track.Type.Y

        """
        if self.type_hint:
            return self.type_hint
        guess = self.type_guess
        if guess is None:
            raise ValueError("Ambiguous type")
        return guess

    @static_property
    def type_guess(self):
        """Type of the channel.

        Returns: Track.Type

        >>> Track((1, 0), (10, 0)).type_guess
        Track.Type.X
        >>> Track((0, 1), (0, 10)).type_guess
        Track.Type.Y
        >>> str(Track((1, 1), (1, 1)).type_guess)
        'None'
        """
        if self.start.x == self.end.x and self.start.y == self.end.y:
            return None
        elif self.start.x == self.end.x:
            return Track.Type.Y
        elif self.start.y == self.end.y:
            return Track.Type.X
        else:
            assert False, self

    def positions(self):
        """Generate all positions this track occupies"""
        startx, endx = sorted([self.start.x, self.end.x])
        starty, endy = sorted([self.start.y, self.end.y])

        for x in range(startx, endx + 1):
            for y in range(starty, endy + 1):
                yield Position(x, y)

    @static_property
    def start0(self):
        """The non-constant start coordinate.

        >>> Track((1, 0), (10, 0)).start0
        1
        >>> Track((0, 1), (0, 10)).start0
        1
        >>> Track((1, 1), (1, 1)).start0
        Traceback (most recent call last):
            ...
        ValueError: Ambiguous type
        >>> Track((1, 1), (1, 1), type_hint=Track.Type.X).start0
        1
        >>> Track((10, 0), (1, 0)).start0
        10
        >>> Track((0, 10), (0, 1)).start0
        10
        """
        if self.type == Track.Type.X:
            return self.start.x
        elif self.type == Track.Type.Y:
            return self.start.y
        else:
            assert False

    @static_property
    def end0(self):
        """The non-constant end coordinate.

        >>> Track((1, 0), (10, 0)).end0
        10
        >>> Track((0, 1), (0, 10)).end0
        10
        >>> Track((1, 1), (1, 1)).end0
        Traceback (most recent call last):
            ...
        ValueError: Ambiguous type
        >>> Track((1, 1), (1, 1), type_hint=Track.Type.X).end0
        1
        >>> Track((10, 0), (1, 0)).end0
        1
        >>> Track((0, 10), (0, 1)).end0
        1
        """
        if self.type == Track.Type.X:
            return self.end.x
        elif self.type == Track.Type.Y:
            return self.end.y
        else:
            assert False, self.type

    @static_property
    def common(self):
        """The common coordinate value.

        >>> Track((0, 0), (10, 0)).common
        0
        >>> Track((0, 0), (0, 10)).common
        0
        >>> Track((1, 1), (1, 1)).common
        Traceback (most recent call last):
            ...
        ValueError: Ambiguous type
        >>> Track((1, 1), (1, 1), type_hint=Track.Type.X).common
        1
        >>> Track((10, 0), (0, 0)).common
        0
        >>> Track((0, 10), (0, 0)).common
        0
        >>> Track((4, 10), (4, 0)).common
        4
        """
        if self.type == Track.Type.X:
            assert_eq(self.start.y, self.end.y)
            return self.start.y
        elif self.type == Track.Type.Y:
            assert_eq(self.start.x, self.end.x)
            return self.start.x
        else:
            assert False

    @static_property
    def length(self):
        """Length of the track.

        >>> Track((0, 0), (10, 0)).length
        10
        >>> Track((0, 0), (0, 10)).length
        10
        >>> Track((1, 1), (1, 1)).length
        0
        >>> Track((10, 0), (0, 0)).length
        10
        >>> Track((0, 10), (0, 0)).length
        10
        """
        try:
            return abs(self.end0 - self.start0)
        except ValueError:
            return 0

    def new_idx(self, idx):
        """Create a new channel with the same start/end but new index value.

        >>> s = (1, 4)
        >>> e = (1, 8)
        >>> c1 = Track(s, e, idx=0)
        >>> c2 = c1.new_idx(2)
        >>> assert_eq(c1.start, c2.start)
        >>> assert_eq(c1.end, c2.end)
        >>> c1.idx
        0
        >>> c2.idx
        2
        """
        return self.__class__(
            self.start,
            self.end,
            self.direction,
            self.segment_id,
            idx,
            name=self.name,
            type_hint=self.type_hint,
        )

    def __repr__(self):
        """

        >>> repr(Track((0, 0), (10, 0)))
        'T((0,0), (10,0))'
        >>> repr(Track((0, 0), (0, 10)))
        'T((0,0), (0,10))'
        >>> repr(Track((1, 2), (3, 2), idx=5))
        'T((1,2), (3,2), 5)'
        >>> repr(Track((1, 2), (3, 2), name="ABC"))
        'T(ABC)'
        >>> repr(Track((1, 2), (3, 2), idx=5, name="ABC"))
        'T(ABC,5)'
        """
        if self.name:
            idx_str = ""
            if self.idx != None:
                idx_str = ",{}".format(self.idx)
            return "T({}{})".format(self.name, idx_str)

        idx_str = ""
        if self.idx != None:
            idx_str = ", {}".format(self.idx)
        return "T(({},{}), ({},{}){})".format(
            self.start.x, self.start.y, self.end.x, self.end.y, idx_str
        )

    def __str__(self):
        """

        >>> str(Track((0, 0), (10, 0)))
        'CHANX 0,0->10,0'
        >>> str(Track((0, 0), (0, 10)))
        'CHANY 0,0->0,10'
        >>> str(Track((1, 2), (3, 2), idx=5))
        'CHANX 1,2->3,2 @5'
        >>> str(Track((1, 2), (3, 2), name="ABC"))
        'ABC'
        >>> str(Track((1, 2), (3, 2), idx=5, name="ABC"))
        'ABC@5'
        """
        idx_str = ""
        if self.idx != None:
            idx_str = " @{}".format(self.idx)
        if self.name:
            return "{}{}".format(self.name, idx_str[1:])
        return "{} {},{}->{},{}{}".format(
            self.type.value, self.start.x, self.start.y, self.end.x,
            self.end.y, idx_str
        )


# Short alias.
T = Track


class ChannelGrid(dict):
    """
    Functionality:
     * Manages single type of track (either `CHANX` or `CHANY`).
     * Manages channel width along grid.
     * Allocates tracks within channels.

    The `ChannelGrid` is indexed by `Position` and returns a sequence width all
    the `Track`s at that position.
    """

    def __init__(self, size, chan_type):
        """
        size: Size representing tile grid width/height
        chan_type: of Channels.Type
        """
        self.chan_type = chan_type
        self.size = Size(*size)

        self.clear()

    @property
    def width(self):
        """Grid width

        >>> g = ChannelGrid((6, 7), Track.Type.Y)
        >>> g.width
        6
        """
        return self.size.width

    @property
    def height(self):
        """Grid height

        >>> g = ChannelGrid((6, 7), Track.Type.Y)
        >>> g.height
        7
        """
        return self.size.height

    def column(self, x):
        """Get a y coordinate indexed list giving tracks at that x + y position"""
        column = []
        for y in range(0, self.height):
            column.append(self[Position(x, y)])
        return column

    def row(self, y):
        """Get an x coordinate indexed list giving tracks at that x + y position"""
        row = []
        for x in range(0, self.width):
            row.append(self[Position(x, y)])
        return row

    """
    dim_*: CHANX/CHANY abstraction functions
    These can be used to write code that is not aware of specifics related to CHANX vs CHANY
    """

    def dim_rc(self):
        """Get dimension a, the number of row/col positions"""
        return {
            Track.Type.X: self.height,
            Track.Type.Y: self.width,
        }[self.chan_type]

    def dim_chanl(self):
        """Get dimension b, the number of valid track positions within a specific channel"""
        return {
            Track.Type.X: self.width,
            Track.Type.Y: self.height,
        }[self.chan_type]

    def foreach_position(self):
        """Generate all valid placement positions (exclude border)"""
        xmin, ymin = {
            Track.Type.X: (1, 0),
            Track.Type.Y: (0, 1),
        }[self.chan_type]

        for row in range(ymin, self.height):
            for col in range(xmin, self.width):
                yield Position(col, row)

    def foreach_track(self):
        """Generate all current legal channel positions (exclude border)"""
        for pos in self.foreach_position():
            for ti, t in enumerate(self[pos]):
                yield (pos, ti, t)

    def slicen(self):
        """Get grid width or height corresponding to chanx/chany type"""
        return {
            Track.Type.X: self.height,
            Track.Type.Y: self.width,
        }[self.chan_type]

    def slice(self, i):
        """Get row or col corresponding to chanx/chany type"""
        return {
            Track.Type.X: self.row,
            Track.Type.Y: self.column,
        }[self.chan_type](
            i
        )

    def track_slice(self, t):
        """Get the row or column the track runs along"""
        return {
            Track.Type.X: self.row,
            Track.Type.Y: self.column,
        }[t.type](
            t.common
        )

    def tracks(self):
        """Get all channels in a set"""
        ret = set()
        for _pos, _ti, t in self.foreach_track():
            ret.add(t)
        return ret

    def validate_pos(self, pos, msg=''):
        """
        A channel must go between switchboxes (where channels can cross)
        Channels are upper right of tile
        Therefore, the first position in a channel cannot have a track because there is no proceeding switchbox
        """
        if msg:
            msg = msg + ': '
        # Gross error out of grid
        if pos.x < 0 or pos.y < 0 or pos.x >= self.width or pos.y >= self.height:
            raise ValueError(
                "%sGrid %s, point %s out of grid size coordinate" %
                (msg, self.size, pos)
            )

        if self.chan_type == Track.Type.X and pos.x == 0:
            raise ValueError("%sInvalid CHANX x=0 point %s" % (msg, pos))
        if self.chan_type == Track.Type.Y and pos.y == 0:
            raise ValueError("%sInvalid CHANY y=0 point %s" % (msg, pos))

    def create_track(self, t, idx=None):
        """
        Channel allocator
        Finds an optimal place to put the channel, increasing the channel width if necessary
        If idx is given, it must go there
        Throw exception if location is already occupied

        >>> g = ChannelGrid((11, 11), Track.Type.X)
        >>> # Adding the first channel
        >>> g.create_track(Track((1, 6), (4, 6), name="A"))
        T(A,0)
        >>> g[(1,6)]
        [T(A,0)]
        >>> g[(2,6)]
        [T(A,0)]
        >>> g[(4,6)]
        [T(A,0)]
        >>> g[(5,6)]
        [None]
        >>> # Adding second non-overlapping second channel
        >>> g.create_track(Track((5, 6), (7, 6), name="B"))
        T(B,0)
        >>> g[(4,6)]
        [T(A,0)]
        >>> g[(5,6)]
        [T(B,0)]
        >>> g[(7,6)]
        [T(B,0)]
        >>> g[(8,6)]
        [None]
        >>> # Adding third channel which overlaps with second channel
        >>> g.create_track(Track((5, 6), (7, 6), name="T"))
        T(T,1)
        >>> g[(4,6)]
        [T(A,0), None]
        >>> g[(5,6)]
        [T(B,0), T(T,1)]
        >>> g[(7,6)]
        [T(B,0), T(T,1)]
        >>> # Adding a channel which overlaps, but is a row over
        >>> g.create_track(Track((5, 7), (7, 7), name="D"))
        T(D,0)
        >>> g[(5,6)]
        [T(B,0), T(T,1)]
        >>> g[(5,7)]
        [T(D,0)]
        >>> # Adding fourth channel which overlaps both the first
        >>> # and second+third channel
        >>> g.create_track(Track((3, 6), (6, 6), name="E"))
        T(E,2)
        >>> g[(2,6)]
        [T(A,0), None, None]
        >>> g[(3,6)]
        [T(A,0), None, T(E,2)]
        >>> g[(6,6)]
        [T(B,0), T(T,1), T(E,2)]
        >>> g[(7,6)]
        [T(B,0), T(T,1), None]
        >>> # This channel fits in the hole left by the last one.
        >>> g.create_track(Track((1, 6), (3, 6), name="F"))
        T(F,1)
        >>> g[(1,6)]
        [T(A,0), T(F,1), None]
        >>> g[(2,6)]
        [T(A,0), T(F,1), None]
        >>> g[(3,6)]
        [T(A,0), T(F,1), T(E,2)]
        >>> g[(4,6)]
        [T(A,0), None, T(E,2)]
        >>> # Add another channel which causes a hole
        >>> g.create_track(Track((1, 6), (7, 6), name="G"))
        T(G,3)
        >>> g[(1,6)]
        [T(A,0), T(F,1), None, T(G,3)]
        >>> g[(2,6)]
        [T(A,0), T(F,1), None, T(G,3)]
        >>> g[(3,6)]
        [T(A,0), T(F,1), T(E,2), T(G,3)]
        >>> g[(4,6)]
        [T(A,0), None, T(E,2), T(G,3)]
        >>> g[(5,6)]
        [T(B,0), T(T,1), T(E,2), T(G,3)]
        >>> g[(6,6)]
        [T(B,0), T(T,1), T(E,2), T(G,3)]
        >>> g[(7,6)]
        [T(B,0), T(T,1), None, T(G,3)]
        >>> g[(8,6)]
        [None, None, None, None]
        """
        assert t.idx == None
        force_idx = idx

        self.validate_pos(t.start, 'start')
        self.validate_pos(t.end, 'end')

        if t.type_guess != self.chan_type:
            if t.length != 0:
                raise TypeError(
                    "Can only add channels of type {} which {} ({}) is not.".
                    format(self.chan_type, t, t.type)
                )
            else:
                t.type_hint = self.chan_type

        l = self.track_slice(t)
        assert_len_eq(l)

        # Find start and end
        s, e = min(t.start0, t.end0), max(t.start0, t.end0)
        assert e >= s, (e, '>=', s)
        assert s < len(l), (s, '<', len(l), l)
        assert e < len(l), (e + 1, '<', len(l), l)

        # Find a idx that this channel fits.
        # Normally start at first channel (0) unless forcing to a specific channel
        max_idx = force_idx if force_idx is not None else 0
        while True:
            # Check each position if the track can fit
            # Expanding channel width as required index grows
            for p in l[s:e + 1]:
                while len(p) < max_idx + 1:
                    p.append(None)
                # Can't place here?
                if p[max_idx] != None:
                    # Grow track width
                    if force_idx is not None:
                        raise IndexError(
                            "Can't fit channel at index %d" % force_idx
                        )
                    max_idx += 1
                    break
            # Was able to place into all locations
            else:
                break

        # Make sure everything has the same length.
        for p in l:
            while len(p) < max_idx + 1:
                p.append(None)
        assert_len_eq(l)

        t = t.new_idx(max_idx)
        assert t.idx == max_idx
        for p in l[s:e + 1]:
            p[t.idx] = t
        return t

    def pretty_print(self):
        """
        If type == Track.Type.X

          A--AC-C
          B-----B

          D--DE-E
          F-----F

        If type == Track.Type.Y

          AB  DF
          ||  ||
          ||  ||
          A|  D|
          C|  E|
          ||  ||
          CB  EF

        """

        def get_str(t):
            if not t:
                s = ""
            elif t.name:
                s = t.name
            else:
                s = str(t)
            return s

        # Work out how many characters the largest label takes up.
        s_maxlen = 1
        for row in range(0, self.height):
            for col in range(0, self.width):
                for t in self[(col, row)]:
                    s_maxlen = max(s_maxlen, len(get_str(t)))

        assert s_maxlen > 0, s_maxlen
        s_maxlen += 3
        if self.chan_type == Track.Type.Y:
            beg_fmt = "{:^%i}" % s_maxlen
            end_fmt = beg_fmt
            mid_fmt = beg_fmt.format("||")
        elif self.chan_type == Track.Type.X:
            beg_fmt = "{:>%i}>" % (s_maxlen - 1)
            end_fmt = "->{:<%i}" % (s_maxlen - 2)
            mid_fmt = "-" * s_maxlen
        else:
            assert False
        non_fmt = " " * s_maxlen
        """
        rows[row][col][c]
        row: global row location
        col: column of output
        c: character showing occupation along a track
        Channel width may vary across tiles, but all columns within that region should have the same length
        """
        rows = []
        for y in range(0, self.height):
            cols = []
            for x in range(0, self.width):
                # Header
                hdri = {Track.Type.X: x, Track.Type.Y: y}[self.chan_type]
                channels = [("|{: ^%i}" % (s_maxlen - 1)).format(hdri)]

                for t in self[(x, y)]:
                    if not t:
                        fmt = non_fmt
                    elif t.start == t.end:
                        s = get_str(t)
                        channels.append(
                            "{} ".format(
                                "".join(
                                    [
                                        beg_fmt.format(s),
                                        mid_fmt.format(s),
                                        end_fmt.format(s),
                                    ]
                                )[:s_maxlen - 1]
                            )
                        )
                        continue
                    elif t.start == (x, y):
                        fmt = beg_fmt
                    elif t.end == (x, y):
                        fmt = end_fmt
                    else:
                        fmt = mid_fmt

                    channels.append(fmt.format(get_str(t)))
                cols.append(channels)
            rows.append(cols)

        # Dump the track state as a string
        f = io.StringIO()

        def p(*args, **kw):
            print(*args, file=f, **kw)

        if self.chan_type == Track.Type.X:
            for r in range(0, len(rows)):
                assert_len_eq(rows[r])
                # tracks + 1 for header
                track_rows = len(rows[r][0])
                for tracki in range(0, track_rows):
                    for c in range(0, len(rows[r])):
                        p(rows[r][c][tracki], end="")
                    # Close header
                    if tracki == 0:
                        p("|", end="")
                    p()
                p("\n")
        elif self.chan_type == Track.Type.Y:
            for r in range(0, len(rows)):
                # tracks + 1 for header
                for c in range(0, len(rows[r])):
                    track_cols = len(rows[r][c])
                    p("|*", end="")
                    for tracki in range(0, track_cols):
                        p(rows[r][c][tracki], end="")
                        # Close header
                        if tracki == 0:
                            p("|", end="")
                    p("  ", end="")
                p("")
                #p("|*|")
        else:
            assert False

        return f.getvalue()

    def clear(self):
        """Remove tracks from all currently occupied positions, making channel width 0"""
        for x in range(0, self.width):
            for y in range(0, self.height):
                self[Position(x, y)] = []

    def check(self):
        """Self integrity check"""
        # Verify uniform track length
        if self.chan_type == Track.Type.X:
            for y in range(self.height):
                assert_len_eq(self.row(y))
        elif self.chan_type == Track.Type.Y:
            for x in range(self.width):
                assert_len_eq(self.column(x))
        else:
            assert False

    def density(self):
        """Return (number occupied positions, total number positions)"""
        occupied = 0
        net = 0
        for _pos, _ti, t in self.foreach_track():
            net += 1
            if t is not None:
                occupied += 1
        return occupied, net

    def fill_empty(self, segment_id, name=None):
        tracks = []
        for pos, ti, t in self.foreach_track():
            if t is None:
                tracks.append(
                    self.create_track(
                        Track(
                            pos,
                            pos,
                            segment_id=segment_id,
                            name=name,
                            type_hint=self.chan_type,
                            direction=Track.Direction.BI
                        ),
                        idx=ti
                    )
                )
        return tracks

    def channel_widths(self):
        """Return (min channel width, max channel width, row/col widths)"""
        cwmin = float('+inf')
        cwmax = float('-inf')
        xy_list = []
        for i in range(self.slicen()):
            # track width should be consistent along a slice
            # just take the first element
            loc = self.slice(i)[0]
            cwmin = min(cwmin, len(loc))
            cwmax = max(cwmax, len(loc))
            xy_list.append(len(loc))
        return (cwmin, cwmax, xy_list)

    def assert_width(self, width):
        """Assert all channels have specified --route_chan_width"""
        for pos in self.foreach_position():
            tracks = self[pos]
            assert len(
                tracks
            ) == width, 'Bad width Position(x=%d, y=%d): expect %d, got %d' % (
                pos.x, pos.y, width, len(tracks)
            )

    def assert_full(self):
        """Assert all allocated channels are fully occupied"""
        self.check()
        #occupied, net = self.density()
        #print("Occupied %d / %d" % (occupied, net))
        for pos, ti, t in self.foreach_track():
            assert t is not None, 'Unoccupied Position(x=%d, y=%d) track=%d' % (
                pos.x, pos.y, ti
            )


class Channels:
    """Holds all channels for the whole grid (X + Y)"""

    def __init__(self, size):
        self.size = size
        self.x = ChannelGrid(size, Track.Type.X)
        self.y = ChannelGrid(size, Track.Type.Y)

    def create_diag_track(self, start, end, segment_id, idx=None):
        # Actually these can be tuple as well
        #assert_type(start, Pos)
        #assert_type(end, Pos)

        # Create track(s)
        try:
            return (self.create_xy_track(start, end, segment_id, idx=idx), )
        except ChannelNotStraight as _e:
            assert idx is None, idx
            corner = (start.x, end.y)
            ta = self.create_xy_track(start, corner, segment_id)[0]
            tb = self.create_xy_track(corner, end, segment_id)[0]
            return (ta, tb)

    def create_xy_track(
            self,
            start,
            end,
            segment_id,
            idx=None,
            name=None,
            typeh=None,
            direction=None
    ):
        """
        idx: None to automatically allocate
        """
        # Actually these can be tuple as well
        #assert_type(start, Pos)
        #assert_type(end, Pos)

        # Create track(s)
        # Will throw exception if not straight
        t = Track(
            start,
            end,
            segment_id=segment_id,
            name=name,
            type_hint=typeh,
            direction=direction
        )

        # Add the track to associated channel list
        # Get the track now with the index assigned
        t = {
            Track.Type.X: self.x.create_track,
            Track.Type.Y: self.y.create_track
        }[t.type](
            t, idx=idx
        )
        #print('create %s %s to %s idx %s' % (t.type, start, end, idx))

        assert t.idx != None
        if typeh:
            assert t.type == typeh, (t.type.value, typeh)
        return t

    def pad_channels(self, segment_id):
        tracks = []
        tracks.extend(self.x.fill_empty(segment_id))
        tracks.extend(self.y.fill_empty(segment_id))
        return tracks

    def pretty_print(self):
        s = ''
        s += 'X\n'
        s += self.x.pretty_print()
        s += 'Y\n'
        s += self.y.pretty_print()
        return s

    def clear(self):
        """Remove all channels"""
        self.x.clear()
        self.y.clear()

    def from_xml_nodes(self, nodes_xml):
        """Add channels from <nodes> CHANX/CHANY"""
        for node_xml in nodes_xml:
            ntype = node_xml.get('type')
            if ntype not in ('CHANX', 'CHANY'):
                continue
            ntype_e = Track.Type(ntype)

            direction = Track.Direction(node_xml.get('direction'))

            loc = single_element(node_xml, 'loc')
            idx = int(loc.get('ptc'))
            pos_low, pos_high = node_pos(node_xml)
            #print('Importing %s @ %s:%s :: %d' % (ntype, pos_low, pos_high, idx))

            segment_xml = single_element(node_xml, 'segment')
            segment_id = int(segment_xml.get('segment_id'))

            # idx will get assigned when adding to track
            try:
                _track = self.create_xy_track(
                    pos_low,
                    pos_high,
                    segment_id,
                    idx=idx,
                    # XML has no name concept. Should it?
                    name=None,
                    typeh=ntype_e,
                    direction=direction
                )
            except:
                print("Bad XML: %s" % (ET.tostring(node_xml)))
                raise

    def to_xml_channels(self, channels_xml):
        channels_xml.clear()

        # channel entry
        cw_xmin, cw_xmax, x_lists = self.x.channel_widths()
        cw_ymin, cw_ymax, y_lists = self.y.channel_widths()
        cw_max = max(cw_xmax, cw_ymax)
        ET.SubElement(
            channels_xml, 'channel', {
                'chan_width_max': str(cw_max),
                'x_min': str(cw_xmin),
                'x_max': str(cw_xmax),
                'y_min': str(cw_ymin),
                'y_max': str(cw_ymax),
            }
        )
        # x_list / y_list tries
        for i, info in enumerate(x_lists):
            ET.SubElement(
                channels_xml, 'x_list', {
                    'index': str(i),
                    'info': str(info)
                }
            )
        for i, info in enumerate(y_lists):
            ET.SubElement(
                channels_xml, 'y_list', {
                    'index': str(i),
                    'info': str(info)
                }
            )

    def to_xml(self, xml_graph):
        self.to_xml_channels(single_element(xml_graph, 'channels'))


def TX(start, end, idx=None, name=None, direction=None, segment_id=None):
    if direction is None:
        direction = Track.Direction.INC
    if segment_id is None:
        segment_id = 0
    return T(
        start,
        end,
        direction=direction,
        segment_id=segment_id,
        idx=idx,
        name=name,
        type_hint=Track.Type.X,
    )


def TY(start, end, idx=None, name=None, direction=None, segment_id=None):
    if direction is None:
        direction = Track.Direction.INC
    if segment_id is None:
        segment_id = 0
    return T(
        start,
        end,
        direction=direction,
        segment_id=segment_id,
        idx=idx,
        name=name,
        type_hint=Track.Type.Y,
    )


def docprint(x):
    pprint.pprint(x.splitlines())


def create_test_channel_grid():
    g = ChannelGrid((6, 3), Track.Type.X)
    g.create_track(TX((1, 0), (5, 0), name="AA"))
    g.create_track(TX((1, 0), (3, 0), name="BB"))
    g.create_track(TX((2, 0), (5, 0), name="CC"))
    g.create_track(TX((1, 0), (1, 0), name="DD"))

    g.create_track(TX((1, 1), (3, 1), name="aa"))
    g.create_track(TX((4, 1), (5, 1), name="bb"))
    g.create_track(TX((1, 1), (5, 1), name="cc"))

    g.check()
    return g


def test_x_auto():
    """
    >>> docprint(test_x_auto())
    ['| 0  | 1  | 2  | 3  | 4  | 5  |',
     '       AA>---------------->AA ',
     '       BB>------>BB           ',
     '       DD   CC>----------->CC ',
     '',
     '',
     '| 0  | 1  | 2  | 3  | 4  | 5  |',
     '       aa>------>aa   bb>->bb ',
     '       cc>---------------->cc ',
     '',
     '',
     '| 0  | 1  | 2  | 3  | 4  | 5  |',
     '',
     '']
    """
    g = create_test_channel_grid()
    return g.pretty_print()


def test_pad():
    """
    >>> docprint(test_pad())
    ['| 0  | 1  | 2  | 3  | 4  | 5  |',
     '       AA>---------------->AA ',
     '       BB>------>BB   XX   XX ',
     '       DD   CC>----------->CC ',
     '',
     '',
     '| 0  | 1  | 2  | 3  | 4  | 5  |',
     '       aa>------>aa   bb>->bb ',
     '       cc>---------------->cc ',
     '',
     '',
     '| 0  | 1  | 2  | 3  | 4  | 5  |',
     '',
     '']
    """
    g = create_test_channel_grid()
    g.fill_empty(0, name='XX')
    g.check()
    return g.pretty_print()


def test_x_manual():
    """
    >>> pprint.pprint(test_x_manual().splitlines())
    ['| 0  | 1  | 2  | 3  | 4  | 5  |',
     '       AA>---------------->AA ',
     '       BB>------>BB           ',
     '       DD   CC>----------->CC ',
     '',
     '',
     '| 0  | 1  | 2  | 3  | 4  | 5  |',
     '       aa>------>aa   bb>->bb ',
     '       cc>---------------->cc ',
     '',
     '',
     '| 0  | 1  | 2  | 3  | 4  | 5  |',
     '',
     '']
    """
    g = ChannelGrid((6, 3), Track.Type.X)
    g.create_track(TX((1, 0), (5, 0), name="AA"), idx=0)
    g.create_track(TX((1, 0), (3, 0), name="BB"), idx=1)
    g.create_track(TX((2, 0), (5, 0), name="CC"), idx=2)
    g.create_track(TX((1, 0), (1, 0), name="DD"), idx=2)

    g.create_track(TX((1, 1), (3, 1), name="aa"), idx=0)
    g.create_track(TX((4, 1), (5, 1), name="bb"), idx=0)
    g.create_track(TX((1, 1), (5, 1), name="cc"), idx=1)

    try:
        g.create_track(TX((1, 1), (5, 1), name="dd"), idx=1)
        assert False, "Should have failed to place"
    except IndexError:
        pass

    g.check()
    return g.pretty_print()


def test_y_auto():
    """
    >>> docprint(test_y_auto())
    ['|*| 0  |                 |*| 0  |            |*| 0  |  ',
     '|*| 1  | AA   BB   DD    |*| 1  | aa   cc    |*| 1  |  ',
     '|*| 2  | ||   ||   CC    |*| 2  | ||   ||    |*| 2  |  ',
     '|*| 3  | ||   BB   ||    |*| 3  | aa   ||    |*| 3  |  ',
     '|*| 4  | ||        ||    |*| 4  | bb   ||    |*| 4  |  ',
     '|*| 5  | AA        CC    |*| 5  | bb   cc    |*| 5  |  ']
    """
    g = ChannelGrid((3, 6), Track.Type.Y)
    g.create_track(TY((0, 1), (0, 5), name="AA"))
    g.create_track(TY((0, 1), (0, 3), name="BB"))
    g.create_track(TY((0, 2), (0, 5), name="CC"))
    g.create_track(TY((0, 1), (0, 1), name="DD"))

    g.create_track(TY((1, 1), (1, 3), name="aa"))
    g.create_track(TY((1, 4), (1, 5), name="bb"))
    g.create_track(TY((1, 1), (1, 5), name="cc"))

    g.check()
    return g.pretty_print()


if __name__ == "__main__":
    import doctest
    print('doctest: begin')
    doctest.testmod()
    print('doctest: end')
