#!/usr/bin/env python3
'''
This file mainly deals with packing tracks into channels
It does not manage channel XML nodes

Note channels go between switchboxes
Switchboxes cannot be at the last grid coordinate
Therefore, you need a grid size of at least 3 rows or cols to allow a channel
This channel would be of length 0, connecting the switchbox at 0 to the switchbox at 1

With above in mind, objects here entirely omit the last row/col
and placing a channel in the first is illegal
Specifically:
-CHANX: X=0 is invalid, X=grid.width-1 is invalid
-CHANY: Y=0 is invalid, Y=grid.height-1 is invalid
'''

import enum
import io
from collections import namedtuple, OrderedDict
import lxml.etree as ET

from . import Position
from . import Size
from . import static_property
from . import node_pos, single_element
from ..asserts import assert_type
from ..asserts import assert_len_eq


class ChannelNotStraight(TypeError):
    pass


class Segment:
    '''An rr_graph <segment>'''
    def __init__(self, id, name, timing=None):
        self.id = id
        self.name = name
        if timing:
            assert len(timing) == 2 and 'R_per_meter' in timing and 'C_per_meter' in timing
            self.timing = timing

    @classmethod
    def from_xml(cls, segment_xml):
        '''
        Example:
        <segment id="0" name="span">
            <timing R_per_meter="101" C_per_meter="2.25000005e-14"/>
        </segment>
        '''
        assert_type(segment_xml, ET._Element)
        sid = int(segment_xml.get('id'))
        name = segment_xml.get('name')

        timing = None
        timings = list(segment_xml.iterfind('timing'))
        if len(timings) == 1:
            timing = timings[0]
            timing_r = float(timing.get('R_per_meter'))
            timing_c = float(timing.get('C_per_meter'))
            timing = {'R_per_meter':timing_r, 'C_per_meter':timing_c}
        else:
            assert len(timings) == 0
        return Segment(sid, name, timing)

    def to_xml(self, segments_xml):
        timing_xml = ET.SubElement(segments_xml, 'segment', {
            'id': str(self.id),
            'name': self.name
        })
        if self.timing:
            ET.SubElement(
                timing_xml, "timing", {k: str(v) for k, v in self.timing.items()})


_Track = namedtuple(
    "Track", ("start", "end", "idx", "type_hint", "direction_hint", "segment"))


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
            return 'Track.Type.' + self.name

    class Direction(enum.Enum):
        INC = 'INC_DIR'
        DEC = 'DEC_DIR'
        BI = 'BI_DIR'

        def __repr__(self):
            return 'Track.Direction.' + self.name

    def __new__(cls,
                start,
                end,
                idx=None,
                id_override=None,
                type_hint=None,
                direction_hint=None,
                segment=None):
        '''Make most but not all attributes immutable'''

        if not isinstance(start, Position):
            start = Position(*start)
        if not isinstance(end, Position):
            end = Position(*end)

        if start.x != end.x and start.y != end.y:
            raise ChannelNotStraight("Track not straight! {}->{}".format(
                start, end))

        if idx is not None:
            assert_type(idx, int)

        obj = _Track.__new__(cls, start, end, idx, type_hint, direction_hint,
                             segment)
        obj.id_override = id_override

        # Verify not ambiguous
        obj.type
        obj.direction
        # And check for consistency if its not ambiguous
        assert obj.type_guess is None or obj.type_guess == obj.type
        if direction_hint != Track.Direction.BI:
            assert obj.direction_guess is None or obj.direction_guess == obj.direction, "Guess: %s, got: %s" % (
                obj.direction_guess, obj.direction)

        return obj

    @static_property
    def type(self):
        """Type of the channel.

        Returns: Track.Type

        >>> Track((1, 0), (10, 0)).type
        Track.Type.X
        >>> Track((0, 1), (0, 10)).type
        Track.Type.Y
        >>> Track((1, 1), (1, 1)).type_guess
        None
        """
        if self.type_hint:
            return self.type_hint
        guess = self.type_guess
        if guess is None:
            return ValueError("Ambiguous type")
        return guess

    @static_property
    def type_guess(self):
        if self.start.x == self.end.x and self.start.y == self.end.y:
            return None
        elif self.start.x == self.end.x:
            return Track.Type.Y
        elif self.start.y == self.end.y:
            return Track.Type.X
        else:
            assert False

    @static_property
    def start0(self):
        """The non-constant start coordinate.

        >>> Track((1, 0), (10, 0)).start0
        1
        >>> Track((0, 1), (0, 10)).start0
        1
        # >>> Track((1, 1), (1, 1)).start0
        # 1
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
        # >>> Track((1, 1), (1, 1)).end0
        # 1
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
        if self.direction_hint:
            return self.direction_hint
        guess = self.direction_guess
        if guess is None:
            raise ValueError("Ambiguous direction")
        return guess

    @static_property
    def direction_guess(self):
        if self.end0 == self.start0:
            return None
        elif self.end0 < self.start0:
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
        return self.__class__(
            self.start,
            self.end,
            idx,
            id_override=self.id_override,
            type_hint=self.type_hint,
            direction_hint=self.direction_hint,
            segment=self.segment)

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
        return "T(({},{}), ({},{}){})".format(self.start.x, self.start.y,
                                              self.end.x, self.end.y, idx_str)

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
        return "{} {},{}->{},{}{}".format(self.type.value, self.start.x,
                                          self.start.y, self.end.x, self.end.y,
                                          idx_str)


# Short alias.
T = Track


class ChannelGrid(dict):
    '''
    Functionality:
    -Manages single type of track (either chanx or chany)
    -Channel width along grid
    -Manages track allocation within channels
    -A track allocator

    dict is indexed by Position() objects
    This returns a list indicating all the tracks at that position
    '''

    def __init__(self, size, chan_type):
        '''
        size: Size representing tile grid width/height
        chan_type: of Channels.Type
        '''
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
        '''Get a y coordinate indexed list giving tracks at that x + y position'''
        column = []
        for y in range(0, self.height):
            column.append(self[Position(x, y)])
        return column

    def row(self, y):
        '''Get an x coordinate indexed list giving tracks at that x + y position'''
        row = []
        for x in range(0, self.width):
            row.append(self[Position(x, y)])
        return row

    '''
    dim_*: CHANX/CHANY abstraction functions
    These can be used to write code that is not aware of specifics related to CHANX vs CHANY
    '''

    def dim_rc(self):
        '''Get dimension a, the number of row/col positions'''
        return {
            Track.Type.X: self.height,
            Track.Type.Y: self.width,
        }[self.chan_type]

    def dim_chanl(self):
        '''Get dimension b, the number of valid track positions within a specific channel'''
        return {
            Track.Type.X: self.width,
            Track.Type.Y: self.height,
        }[self.chan_type]

    def gen_valid_pos(self):
        '''Generate all valid placement positions (exclude border)'''
        xmin, ymin = {
            Track.Type.X: (1, 0),
            Track.Type.Y: (0, 1),
        }[self.chan_type]

        for row in range(ymin, self.height):
            for col in range(xmin, self.width):
                yield Position(col, row)

    def gen_valid_track(self):
        '''Generate all current legal channel positions (exclude border)'''
        for pos in self.gen_valid_pos():
            for ti, t in enumerate(self[pos]):
                yield (pos, ti, t)

    def slicen(self):
        '''Get grid width or height corresponding to chanx/chany type'''
        return {
            Track.Type.X: self.height,
            Track.Type.Y: self.width,
        }[self.chan_type]

    def slice(self, i):
        '''Get row or col corresponding to chanx/chany type'''
        return {
            Track.Type.X: self.row,
            Track.Type.Y: self.column,
        }[self.chan_type](i)

    def track_slice(self, t):
        '''Get the row or column the track runs along'''
        return {
            Track.Type.X: self.row,
            Track.Type.Y: self.column,
        }[t.type](t.common)

    def tracks(self):
        '''Get all channels in a set'''
        ret = set()
        for _pos, _ti, t in self.gen_valid_track():
            ret.add(t)
        return ret

    def validate_pos(self, pos, msg=''):
        '''
        A channel must go between switchboxes (where channels can cross)
        Channels are upper right of tile
        Therefore, the first position in a channel cannot have a track because there is no proceeding switchbox
        '''
        if msg:
            msg = msg + ': '
        # Gross error out of grid
        if pos.x < 0 or pos.y < 0 or pos.x >= self.width or pos.y >= self.height:
            raise ValueError(
                "%sGrid %s, point %s out of grid size coordinate" %
                (msg, self.size, pos))

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
        >>> g.create_track(Track((1, 6), (4, 6), None, "A"))
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
        >>> g.create_track(Track((5, 6), (7, 6), None, "B"))
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
        >>> g.create_track(Track((5, 6), (7, 6), None, "T"))
        T(T,1)
        >>> g[(4,6)]
        [T(A,0), None]
        >>> g[(5,6)]
        [T(B,0), T(T,1)]
        >>> g[(7,6)]
        [T(B,0), T(T,1)]
        >>> # Adding a channel which overlaps, but is a row over
        >>> g.create_track(Track((5, 7), (7, 7), None, "D"))
        T(D,0)
        >>> g[(5,6)]
        [T(B,0), T(T,1)]
        >>> g[(5,7)]
        [T(D,0)]
        >>> # Adding fourth channel which overlaps both the first
        >>> # and second+third channel
        >>> g.create_track(Track((3, 6), (6, 6), None, "E"))
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
        >>> g.create_track(Track((1, 6), (3, 6), None, "F"))
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
        >>> g.create_track(Track((1, 6), (7, 6), None, "G"))
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

        if t.type != self.chan_type:
            if t.length != 0:
                raise TypeError(
                    "Can only add channels of type {} which {} ({}) is not.".
                    format(self.chan_type, t, t.type))
            else:
                t.type = self.chan_type

        l = self.track_slice(t)
        assert_len_eq(l)

        # Find start and end
        # TODO: BI should maybe sort
        s, e = {
            Track.Direction.BI: (t.start0, t.end0),
            Track.Direction.INC: (t.start0, t.end0),
            Track.Direction.DEC: (t.end0, t.start0),
        }[t.direction]
        assert e >= s
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
                            "Can't fit channel at index %d" % force_idx)
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

        t = t.update_idx(max_idx)
        assert t.idx == max_idx
        for p in l[s:e + 1]:
            p[t.idx] = t
        return t

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
                channels = [("|{: ^%i}" % (s_maxlen - 1)).format(hdri)]

                for t in self[(x, y)]:
                    if not t:
                        fmt = non_fmt
                    elif t.start == t.end:
                        s = get_str(t)
                        channels.append("{} ".format("".join([
                            beg_fmt.format(s),
                            mid_fmt.format(s),
                            end_fmt.format(s),
                        ])[:s_maxlen - 1]))
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
        '''Remove tracks from all currently occupied positions, making channel width 0'''
        for x in range(0, self.width):
            for y in range(0, self.height):
                self[Position(x, y)] = []

    def check(self):
        '''Self integrity check'''
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
        '''Return (number occupied positions, total number positions)''' 
        occupied = 0
        net = 0
        for _pos, _ti, t in self.gen_valid_track():
            net += 1
            if t is not None:
                occupied += 1
        return occupied, net

    def channel_widths(self):
        '''Return (min channel width, max channel width, row/col widths)'''
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
        '''Assert all channels have specified --route_chan_width'''
        for pos in self.gen_valid_pos():
            tracks = self[pos]
            assert len(
                tracks
            ) == width, 'Bad width Position(x=%d, y=%d): expect %d, got %d' % (
                pos.x, pos.y, width, len(tracks))

    def assert_full(self):
        '''Assert all allocated channels are fully occupied'''
        self.check()
        #occupied, net = self.density()
        #print("Occupied %d / %d" % (occupied, net))
        for pos, ti, t in self.gen_valid_track():
            assert t is not None, 'Unoccupied Position(x=%d, y=%d) track=%d' % (
                pos.x, pos.y, ti)


class Channels:
    '''Holds all channels for the whole grid (X + Y)'''

    def __init__(self, size):
        self.size = size
        self.x = ChannelGrid(size, Track.Type.X)
        self.y = ChannelGrid(size, Track.Type.Y)
        # id to segment dict
        self.segment_i2seg = {}
        self.segment_s2seg = {}

    def create_diag_track(self, start, end, segment, idx=None):
        # Actually these can be tuple as well
        #assert_type(start, Pos)
        #assert_type(end, Pos)

        # Create track(s)
        try:
            return (self.create_xy_track(start, end, segment, idx=idx), )
        except ChannelNotStraight as _e:
            assert idx is None, idx
            corner = (start.x, end.y)
            ta = self.create_xy_track(start, corner, segment)[0]
            tb = self.create_xy_track(corner, end, segment)[0]
            return (ta, tb)

    def create_xy_track(self,
                        start, end, segment,
                        idx=None, id_override=None,
                        type=None, direction=None):
        '''
        idx: None to automatically allocate
        '''
        # Actually these can be tuple as well
        #assert_type(start, Pos)
        #assert_type(end, Pos)

        # Create track(s)
        # Will throw exception if not straight
        t = Track(
            start, end,
            segment=segment, id_override=id_override,
            type_hint=type, direction_hint=direction)

        # Add the track to associated channel list
        # Get the track now with the index assigned
        t = {
            Track.Type.X: self.x.create_track,
            Track.Type.Y: self.y.create_track
        }[t.type](
            t, idx=idx)
        #print('create %s %s to %s idx %s' % (t.type, start, end, idx))

        assert t.idx != None
        if type:
            assert t.type == type, (t.type.value, type)
        return t

    def pretty_print(self):
        s = ''
        s += 'X\n'
        s += self.x.pretty_print()
        s += 'Y\n'
        s += self.y.pretty_print()
        return s

    def clear(self):
        '''Remove all channels'''
        self.x.clear()
        self.y.clear()
        self.segment_i2seg.clear()

    def from_xml_segments(self, segments_xml):
        '''Add segments from <segments>'''
        for segment_xml in segments_xml.iterfind('segment'):
            self.add_segment(Segment.from_xml(segment_xml))

    def add_segment(self, segment):
        self.segment_i2seg[segment.id] = segment
        self.segment_s2seg[segment.name] = segment

    def from_xml_nodes(self, nodes_xml):
        '''Add channels from <nodes> CHANX/CHANY'''
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
            segment = self.segment_i2seg[segment_id]

            # idx will get assinged when adding to track
            try:
                _track = self.create_xy_track(
                    pos_low,
                    pos_high,
                    segment,
                    idx=idx,
                    # XML has no name concept. Should it?
                    id_override=None,
                    type=ntype_e,
                    direction=direction)
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
            })
        # x_list / y_list tries
        for i, info in enumerate(x_lists):
            ET.SubElement(channels_xml, 'x_list', {
                'index': str(i),
                'info': str(info)
            })
        for i, info in enumerate(y_lists):
            ET.SubElement(channels_xml, 'y_list', {
                'index': str(i),
                'info': str(info)
            })

    def to_xml_segments(self, segments_xml):
        # FIXME: hack. Get proper segment support
        # for now add a summy segment for which all nodes are associated
        segments_xml.clear()
        for _i, segment in sorted(self.segment_i2seg.items()):
            segment.to_xml(segments_xml)

    def create_segment(self, name, timing=None):
        segment = Segment(len(self.segment_i2seg), name, timing=timing)
        self.add_segment(segment)
        return segment

    def to_xml(self, xml_graph):
        self.to_xml_channels(single_element(xml_graph, 'channels'))
        self.to_xml_segments(single_element(xml_graph, 'segments'))


def TX(start,
        end,
        idx=None,
        id_override=None,
        direction_hint=None,
        segment=None):
    if start == end and direction_hint is None:
        direction_hint = Track.Direction.INC
    return T(start, end, idx=idx,
             id_override=id_override,
             type_hint=Track.Type.X,
             direction_hint=direction_hint,
             segment=segment)


def TY(start,
        end,
        idx=None,
        id_override=None,
        direction_hint=None,
        segment=None):
    if start == end and direction_hint is None:
        direction_hint = Track.Direction.INC
    return T(start, end, idx=idx,
             id_override=id_override,
             type_hint=Track.Type.Y,
             direction_hint=direction_hint,
             segment=segment)


def test_x_auto():
    g = ChannelGrid((6, 3), Track.Type.X)
    g.create_track(TX((1, 0), (5, 0), None, "AA"))
    g.create_track(TX((1, 0), (3, 0), None, "BB"))
    g.create_track(TX((2, 0), (5, 0), None, "CC"))
    g.create_track(TX((1, 0), (1, 0), None, "DD"))

    g.create_track(TX((1, 1), (3, 1), None, "aa"))
    g.create_track(TX((4, 1), (5, 1), None, "bb"))
    g.create_track(TX((1, 1), (5, 1), None, "cc"))

    print()
    g.check()
    print(g.pretty_print())

def test_x_manual():
    g = ChannelGrid((6, 3), Track.Type.X)
    g.create_track(TX((1, 0), (5, 0), None, "AA"), idx=0)
    g.create_track(TX((1, 0), (3, 0), None, "BB"), idx=1)
    g.create_track(TX((2, 0), (5, 0), None, "CC"), idx=2)
    g.create_track(TX((1, 0), (1, 0), None, "DD"), idx=2)

    g.create_track(TX((1, 1), (3, 1), None, "aa"), idx=0)
    g.create_track(TX((4, 1), (5, 1), None, "bb"), idx=0)
    g.create_track(TX((1, 1), (5, 1), None, "cc"), idx=1)

    try:
        g.create_track(T((1, 1), (5, 1), None, "dd"), idx=1)
        assert False, "Should have failed to place"
    except IndexError:
        pass

    print()
    g.check()
    print(g.pretty_print())

def test_y_auto():
    g = ChannelGrid((3, 6), Track.Type.Y)
    g.create_track(TY((0, 1), (0, 5), None, "AA"))
    g.create_track(TY((0, 1), (0, 3), None, "BB"))
    g.create_track(TY((0, 2), (0, 5), None, "CC"))
    g.create_track(TY((0, 1), (0, 1), None, "DD"))

    g.create_track(TY((1, 1), (1, 3), None, "aa"))
    g.create_track(TY((1, 4), (1, 5), None, "bb"))
    g.create_track(TY((1, 1), (1, 5), None, "cc"))

    print()
    g.check()
    print(g.pretty_print())

def test_segment():
    segment = Segment(0, 'awesomesauce', timing={'R_per_meter':420, 'C_per_meter':3.e-14})
    c = Channels(Position(6, 4))
    c.create_xy_track(Position(1, 0), Position(4, 0), segment)
    c.create_xy_track(Position(1, 0), Position(2, 0), segment)
    c.create_xy_track(Position(0, 1), Position(0, 3), segment)
    print("X")
    print(c.x.pretty_print())
    print()
    print("Y")
    print(c.y.pretty_print())

if __name__ == "__main__":
    import doctest
    print('doctest: begin')
    doctest.testmod()
    print('doctest: end')

    test_x_auto()
    test_x_manual()
    print()
    print()
    test_y_auto()
    print()
    print()
    test_segment()
