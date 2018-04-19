#!/usr/bin/env python3

'''
This file mainly deals with packing tracks into channels
'''

import enum
import io

from collections import namedtuple

from . import Pos
from . import Size
from . import static_property
from ..asserts import assert_type
from ..asserts import assert_len_eq


class ChannelNotStraight(TypeError):
    pass

_Track = namedtuple("Track", ("start", "end", "idx"))
class Track(_Track):
    '''
    Represents a single ChanX or ChanY (track) within a channel
    ie the tracks of an a x_list or y_list entry in <channels>

    start: start Pos
    end: end Pos
    idx: XML index integer
    '''

    class Type(enum.Enum):
        # Horizontal routing
        X = 'CHANX'
        # Vertical routing
        Y = 'CHANY'

        def __repr__(self):
            return 'Track.Type.'+self.name

    class Direction(enum.Enum):
        INC = 'INC_DIR'
        DEC = 'DEC_DIR'

        def __repr__(self):
            return 'Track.Direction.'+self.name

    def __new__(cls, start, end, idx=None, id_override=None):
        '''Make most but not all attributes immutable'''

        if not isinstance(start, Pos):
            start = Pos(*start)
        if not isinstance(end, Pos):
            end = Pos(*end)

        if start.x != end.x and start.y != end.y:
            raise ChannelNotStraight(
                "Track not straight! {}->{}".format(start, end))

        if idx is not None:
            assert_type(idx, int)

        obj = _Track.__new__(cls, start, end, idx)
        obj.id_override = id_override
        return obj

    @static_property
    def type(self):
        """Type of the channel.

        Returns: Track.Type

        >>> Track((0, 0), (10, 0)).type
        Track.Type.X
        >>> Track((0, 0), (0, 10)).type
        Track.Type.Y
        >>> Track((1, 1), (1, 1)).type
        Track.Type.Y
        """
        if self.start.x == self.end.x:
            return Track.Type.Y
        elif self.start.y == self.end.y:
            return Track.Type.X
        else:
            assert False

    @static_property
    def start0(self):
        """The non-constant start coordinate.

        >>> Track((0, 0), (10, 0)).start0
        0
        >>> Track((0, 0), (0, 10)).start0
        0
        >>> Track((1, 1), (1, 1)).start0
        1
        >>> Track((10, 0), (0, 0)).start0
        10
        >>> Track((0, 10), (0, 0)).start0
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

        >>> Track((0, 0), (10, 0)).end0
        10
        >>> Track((0, 0), (0, 10)).end0
        0
        >>> Track((1, 1), (1, 1)).end0
        1
        >>> Track((10, 0), (0, 0)).end0
        0
        >>> Track((0, 10), (0, 0)).end0
        0
        """
        if self.type == Track.Type.X:
            return self.end.x
        elif self.type == Track.Type.Y:
            return self.end.y
        else:
            assert False

    @static_property
    def common(self):
        """The common coordinate value.

        >>> Track((0, 0), (10, 0)).common
        0
        >>> Track((0, 0), (0, 10)).common
        0
        >>> Track((1, 1), (1, 1)).common
        1
        >>> Track((10, 0), (0, 0)).common
        0
        >>> Track((0, 10), (0, 0)).common
        0
        >>> Track((4, 10), (4, 0)).common
        4
        """
        if self.type == Track.Type.X:
            assert self.start.y == self.end.y
            return self.start.y
        elif self.type == Track.Type.Y:
            assert self.start.x == self.end.x
            return self.start.x
        else:
            assert False

    @static_property
    def direction(self):
        """Direction the channel runs.

        Returns: Track.Direction

        >>> Track((0, 0), (10, 0)).direction
        Track.Direction.INC
        >>> Track((0, 0), (0, 10)).direction
        Track.Direction.INC
        >>> Track((1, 1), (1, 1)).direction
        Track.Direction.INC
        >>> Track((10, 0), (0, 0)).direction
        Track.Direction.DEC
        >>> Track((0, 10), (0, 0)).direction
        Track.Direction.DEC
        """
        if self.end0 < self.start0:
            return Track.Direction.DEC
        else:
            return Track.Direction.INC

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
        return abs(self.end0 - self.start0)

    def update_idx(self, idx):
        """Create a new channel with the same start/end but new index value.

        >>> s = (1, 4)
        >>> e = (1, 8)
        >>> c1 = Track(s, e, 0)
        >>> c2 = c1.update_idx(2)
        >>> assert c1.start == c2.start
        >>> assert c1.end == c2.end
        >>> c1.idx
        0
        >>> c2.idx
        2
        """
        return self.__class__(self.start, self.end, idx, id_override=self.id_override)

    def __repr__(self):
        """

        >>> repr(Track((0, 0), (10, 0)))
        'T((0,0), (10,0))'
        >>> repr(Track((0, 0), (0, 10)))
        'T((0,0), (0,10))'
        >>> repr(Track((1, 2), (3, 2), 5))
        'T((1,2), (3,2), 5)'
        >>> repr(Track((1, 2), (3, 2), None, "ABC"))
        'T(ABC)'
        >>> repr(Track((1, 2), (3, 2), 5, "ABC"))
        'T(ABC,5)'
        """
        if self.id_override:
            idx_str = ""
            if self.idx != None:
                idx_str = ",{}".format(self.idx)
            return "T({}{})".format(self.id_override, idx_str)

        idx_str = ""
        if self.idx != None:
            idx_str = ", {}".format(self.idx)
        return "T(({},{}), ({},{}){})".format(
            self.start.x, self.start.y, self.end.x, self.end.y, idx_str)

    def __str__(self):
        """

        >>> str(Track((0, 0), (10, 0)))
        'CHANX 0,0->10,0'
        >>> str(Track((0, 0), (0, 10)))
        'CHANY 0,0->0,10'
        >>> str(Track((1, 2), (3, 2), 5))
        'CHANX 1,2->3,2 @5'
        >>> str(Track((1, 2), (3, 2), None, "ABC"))
        'ABC'
        >>> str(Track((1, 2), (3, 2), 5, "ABC"))
        'ABC@5'
        """
        idx_str = ""
        if self.idx != None:
            idx_str = " @{}".format(self.idx)
        if self.id_override:
            return "{}{}".format(self.id_override, idx_str[1:])
        return "{} {},{}->{},{}{}".format(
            self.type.value, self.start.x, self.start.y, self.end.x, self.end.y, idx_str)


# Nice short alias..
T = Track


class ChannelGrid(dict):
    '''
    Functionality:
    -Manages single type of track (either chanx or chany)
    -Channel width along grid
    -Manages track allocation within channels
    -A track allocator

    dict is indexed by Pos() objects
    This returns a list indicaitng all the tracks at that position
    '''
    def __init__(self, size, chan_type):
        '''
        size: Size representing tile grid width/height
        chan_type: of Channels.Type
        '''
        self.chan_type = chan_type
        self.size = Size(*size)

        for x in range(0, self.width):
            for y in range(0, self.height):
                self[Pos(x,y)] = []

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
        '''Get a y coordinate indexed list giving tracks at that x + y position'''
        column = []
        for y in range(0, self.height):
            column.append(self[Pos(x, y)])
        return column

    def row(self, y):
        '''Get an x coordinate indexed list giving tracks at that x + y position'''
        row = []
        for x in range(0, self.width):
            row.append(self[Pos(x, y)])
        return row

    def track_slice(self, t):
        '''Get the row or column the track runs along'''
        return {
            Track.Type.X: self.row,
            Track.Type.Y: self.column
        }[t.type](t.common)

    def add_track(self, t):
        """
        Channel allocator
        Finds an optimal place to put the channel, increasing the channel width if necessary

        >>> g = ChannelGrid((10, 10), Track.Type.X)
        >>> # Adding the first channel
        >>> g.add_track(Track((0, 5), (3, 5), None, "A"))
        T(A,0)
        >>> g[(0,5)]
        [T(A,0)]
        >>> g[(1,5)]
        [T(A,0)]
        >>> g[(3,5)]
        [T(A,0)]
        >>> g[(4,5)]
        [None]
        >>> # Adding second non-overlapping second channel
        >>> g.add_track(Track((4, 5), (6, 5), None, "B"))
        T(B,0)
        >>> g[(3,5)]
        [T(A,0)]
        >>> g[(4,5)]
        [T(B,0)]
        >>> g[(6,5)]
        [T(B,0)]
        >>> g[(7,5)]
        [None]
        >>> # Adding third channel which overlaps with second channel
        >>> g.add_track(Track((4, 5), (6, 5), None, "T"))
        T(T,1)
        >>> g[(3,5)]
        [T(A,0), None]
        >>> g[(4,5)]
        [T(B,0), T(T,1)]
        >>> g[(6,5)]
        [T(B,0), T(T,1)]
        >>> # Adding a channel which overlaps, but is a row over
        >>> g.add_track(Track((4, 6), (6, 6), None, "D"))
        T(D,0)
        >>> g[(4,5)]
        [T(B,0), T(T,1)]
        >>> g[(4,6)]
        [T(D,0)]
        >>> # Adding fourth channel which overlaps both the first
        >>> # and second+third channel
        >>> g.add_track(Track((2, 5), (5, 5), None, "E"))
        T(E,2)
        >>> g[(1,5)]
        [T(A,0), None, None]
        >>> g[(2,5)]
        [T(A,0), None, T(E,2)]
        >>> g[(5,5)]
        [T(B,0), T(T,1), T(E,2)]
        >>> g[(6,5)]
        [T(B,0), T(T,1), None]
        >>> # This channel fits in the hole left by the last one.
        >>> g.add_track(Track((0, 5), (2, 5), None, "F"))
        T(F,1)
        >>> g[(0,5)]
        [T(A,0), T(F,1), None]
        >>> g[(1,5)]
        [T(A,0), T(F,1), None]
        >>> g[(2,5)]
        [T(A,0), T(F,1), T(E,2)]
        >>> g[(3,5)]
        [T(A,0), None, T(E,2)]
        >>> # Add another channel which causes a hole
        >>> g.add_track(Track((0, 5), (6, 5), None, "G"))
        T(G,3)
        >>> g[(0,5)]
        [T(A,0), T(F,1), None, T(G,3)]
        >>> g[(1,5)]
        [T(A,0), T(F,1), None, T(G,3)]
        >>> g[(2,5)]
        [T(A,0), T(F,1), T(E,2), T(G,3)]
        >>> g[(3,5)]
        [T(A,0), None, T(E,2), T(G,3)]
        >>> g[(4,5)]
        [T(B,0), T(T,1), T(E,2), T(G,3)]
        >>> g[(5,5)]
        [T(B,0), T(T,1), T(E,2), T(G,3)]
        >>> g[(6,5)]
        [T(B,0), T(T,1), None, T(G,3)]
        >>> g[(7,5)]
        [None, None, None, None]
        """
        assert t.idx == None

        if t.type != self.chan_type:
            if t.length != 0:
                raise TypeError(
                    "Can only add channels of type {} which {} ({}) is not.".format(
                        self.chan_type, t, t.type))
            else:
                t.type = self.chan_type

        l = self.track_slice(t)
        assert_len_eq(l)

        s = t.start0
        e = t.end0
        if t.direction == Track.Direction.DEC:
            e, s = s, e

        assert e >= s

        assert s < len(l), (s, '<', len(l), l)
        assert e < len(l), (e+1, '<', len(l), l)

        # Find a idx that this channel fits.
        max_idx = 0
        while True:
            for p in l[s:e+1]:
                while len(p) < max_idx+1:
                    p.append(None)
                if p[max_idx] != None:
                    max_idx += 1
                    break
            else:
                break

        # Make sure everything has the same length.
        for p in l:
            while len(p) < max_idx+1:
                p.append(None)

        assert_len_eq(l)

        t = t.update_idx(max_idx)
        assert t.idx == max_idx
        for p in l[s:e+1]:
            p[t.idx] = t
        return t

    def check(self):
        '''Self integrity check
        Verify uniform track length'''
        if self.chan_type == Track.Type.X:
            for y in range(self.height):
                assert_len_eq(self.row(y))
        elif self.chan_type == Track.Type.Y:
            for x in range(self.width):
                assert_len_eq(self.column(x))
        else:
            assert False

    def pretty_print(self):
        """
        If type == Track.Type.X

          A--AC-T
          B-----B

          D--DE-E
          F-----F

        If type == Track.Type.Y

          AB  DF
          ||  ||
          ||  ||
          A|  D|
          T|  E|
          ||  ||
          CB  EF

        """

        def get_str(t):
            if not t:
                s = ""
            elif t.id_override:
                s = t.id_override
            else:
                s = str(t)
            return s

        # Work out how many characters the largest label takes up.
        s_maxlen = 1
        for row in range(0, self.height):
            for col in range(0, self.width):
                for t in self[(col,row)]:
                    s_maxlen = max(s_maxlen, len(get_str(t)))

        assert s_maxlen > 0, s_maxlen
        s_maxlen += 3
        if self.chan_type == Track.Type.Y:
            beg_fmt = "{:^%i}" % s_maxlen
            end_fmt = beg_fmt
            mid_fmt = beg_fmt.format("||")
        elif self.chan_type == Track.Type.X:
            beg_fmt  = "{:>%i}>" % (s_maxlen-1)
            end_fmt = "->{:<%i}" % (s_maxlen-2)
            mid_fmt = "-"*s_maxlen
        else:
            assert False
        non_fmt = " "*s_maxlen

        '''
        rows[row][col][c]
        row: global row location
        col: column of output
        c: character showing occupation along a track
        Channel width may vary across tiles, but all columns within that region should have the same length
        '''
        rows = []
        for y in range(0, self.height):
            cols = []
            for x in range(0, self.width):
                # Header
                hdri = {Track.Type.X: x, Track.Type.Y: y}[self.chan_type]
                channels = [("|{: ^%i}" % (s_maxlen-1)).format(hdri)]

                for t in self[(x,y)]:
                    if not t:
                        fmt = non_fmt
                    elif t.start == t.end:
                        s = get_str(t)
                        channels.append("{} ".format("".join([
                                beg_fmt.format(s),
                                mid_fmt.format(s),
                                end_fmt.format(s),
                            ])[:s_maxlen-1]))
                        continue
                    elif t.start == (x,y):
                        fmt = beg_fmt
                    elif t.end == (x,y):
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


class Channels:
    '''Holds all channels for the whole grid (X + Y)'''
    def __init__(self, size):
        self.size = size
        self.x = ChannelGrid(size, Track.Type.X)
        self.y = ChannelGrid(size, Track.Type.Y)

    def create_track(self, start, end):
        # Actually these can be tuple as well
        #assert_type(start, Pos)
        #assert_type(end, Pos)

        # Create track(s)
        try:
            t = Track(start, end)
        except ChannelNotStraight as e:
            corner = (start.x, end.y)
            # Recursive call to create + add
            ta = self.create_track(start, corner)[0]
            tb = self.create_track(corner, end)[0]
            return (ta, tb)

        # Add the track to associated channel list
        {
            Track.Type.X: self.x.add_track,
            Track.Type.Y: self.y.add_track
        }[t.type](t)

        # debug print?
        '''
        #l = self.track_slice(t)
        l = {
            Track.Type.X: self.x.row,
            Track.Type.Y: self.y.column
        }[t.type](t.common)
        '''
        return (t,)

if __name__ == "__main__":
    import doctest
    print('doctest: begin')
    doctest.testmod()
    print('doctest: end')

    if 1:
        g = ChannelGrid((5,2), Track.Type.X)
        g.add_track(T((0,0), (4,0), None, "AA"))
        g.add_track(T((0,0), (2,0), None, "BB"))
        g.add_track(T((1,0), (4,0), None, "CC"))
        g.add_track(T((0,0), (0,0), None, "DD"))

        g.add_track(T((0,1), (2,1), None, "aa"))
        g.add_track(T((3,1), (4,1), None, "bb"))
        g.add_track(T((0,1), (4,1), None, "cc"))

        print()
        g.check()
        print(g.pretty_print())

    if 1:
        print()
        print()

        g = ChannelGrid((2,5), Track.Type.Y)
        g.add_track(T((0,0), (0,4), None, "AA"))
        g.add_track(T((0,0), (0,2), None, "BB"))
        g.add_track(T((0,1), (0,4), None, "CC"))
        g.add_track(T((0,0), (0,0), None, "DD"))

        g.add_track(T((1,0), (1,2), None, "aa"))
        g.add_track(T((1,3), (1,4), None, "bb"))
        g.add_track(T((1,0), (1,4), None, "cc"))

        print()
        g.check()
        print(g.pretty_print())

    if 1:
        print()
        print()

        c = Channels(Pos(5,3))
        c.create_track(Pos(0,0), Pos(3,0))
        c.create_track(Pos(0,0), Pos(1,0))
        c.create_track(Pos(0,0), Pos(0,2))
        #c.create_track(Pos(0,0), Pos(4,1))
        print("X")
        print(c.x.pretty_print())
        print()
        print("Y")
        print(c.y.pretty_print())
        print()
