#!/usr/bin/env python3
"""
Functions for dealing with groups of points.
"""

import math
import string
import sys

import enum
from collections import defaultdict
from collections import namedtuple

from ..asserts import assert_eq
from ..asserts import assert_type

from . import Position, P


_NamedPosition = namedtuple("NamedPosition", ["pos", "names"])
class NamedPosition(_NamedPosition):
    """Class to store a position and a set of names associated with it."""
    def __new__(cls, pos, names):
        assert_type(pos, Position)
        assert_type(names, list)
        for n in names:
            assert_type(n, str)
        return _NamedPosition.__new__(cls, pos, names)

    @property
    def x(self):
        return self.pos.x

    @property
    def y(self):
        return self.pos.y

    @property
    def first(self):
        assert len(self.names) > 0, self.names
        return self.names[0]

    def __str__(self):
        return "NP({},{},{})".format(
            self.pos.x, self.pos.y,
            ",".join(repr(n) for n in self.names),
        )

    def __repr__(self):
        return self.__str__()


def NP(x, y, *n):
    n = list(n)
    if not n:
        n = ["{}+{}".format(string.ascii_letters[x], string.ascii_letters[y])]
    return NamedPosition(Position(x, y), n)


class StraightSegment(list):
    class Type(enum.Enum):
        V = '|'
        H = '-'
        S = 'o'

        def __repr__(self):
            return 'StraightSegment.Type.' + self.name

    def __new__(cls, direction, positions):
        assert_type(direction, StraightSegment.Type)
        if direction == StraightSegment.Type.S:
            assert len(positions) == 1, (
                "Stubs must only have one position not {}".format(positions))
        else:
            for p in positions:
                assert_type(p, (Position, NamedPosition))
                if direction == StraightSegment.Type.V:
                    assert_eq(p[0].x, p.x)
                elif direction == StraightSegment.Type.H:
                    assert_eq(p[0].y, p.y)
                else:
                    assert False, "Unknown direction {}".format(direction)
        obj = list.__new__(cls, positions)
        obj.direction = direction
        return obj

    def __init__(self, direction, positions):
        pass

    @property
    def d(self):
        return self.direction

    def __str__(self):
        return "{} {}".format(self.direction.value, list.__repr__(self))

    def __repr__(self):
        return "{}({}, {})".format(
            self.__class__.__name__,
            self.direction,
            list.__repr__(self),
        )

    def y_range(self):
        y_pos = [p.y for p in self]
        return min(y_pos), max(y_pos)

    def x_range(self):
        x_pos = [p.x for p in self]
        return min(x_pos), max(x_pos)

    def along(self, pos):
        assert len(self) > 0
        assert_type(pos, (NamedPosition, Position))

        if len(self) == 1:
            assert self.d == StraightSegment.Type.S, (self, pos)
            return (pos.x == self[0].x) or (pos.y == self[0].y)
        elif self.d == StraightSegment.Type.V:
            return pos.x == self[0].x
        elif self.d == StraightSegment.Type.H:
            return pos.y == self[0].y
        else:
            assert False, "Weird segment %s" % self

    def get_at(self, pos):
        for p in self:
            if p.x == pos.x and p.y == pos.y:
                return p
        raise ValueError("Nothing found at {} {}".format(pos, self))

    def has_at(self, pos):
        try:
            self.get_at(pos)
            return True
        except ValueError:
            return False

    def replace(self, pos):
        for i, p in enumerate(self):
            if pos.x != p.x or pos.y != p.y:
                continue
            self[i] = pos
            return True
        return False

    def append(self, pos):
        if len(self) == 1:
            if pos.x == self[0].x:
                self.direction = StraightSegment.Type.V
            elif pos.y == self[0].y:
                self.direction = StraightSegment.Type.H
            else:
                assert False, (self, pos)
        list.append(self, pos)

    def extend_to(self, pos):
        pclass = self[0].pos.__class__
        if self.d == StraightSegment.Type.H:
            return pclass(pos.x, self[0].y)
        elif self.d == StraightSegment.Type.V:
            return pclass(self[0].x, pos.y)
        elif self.d == StraightSegment.Type.S:
            return pclass(self[0].x, pos.y)
            #assert pos.x == self[0].x or pos.y == self[0].y, (pos, self)
            #return pclass(*pos)
        assert self.d != StraightSegment.Type.S, self
        assert False, self



def straight_longest(positions):
    """Get the largest straight section from a group of positions.

    Arguments:
        positions : [(Position, [str, ...]), ...]

    Returns:
        (StraightSegment([Position|NamedPosition, ...]), [Position|NamedPosition, ...])

    >>> s, r = straight_longest([P(1,0),])
    >>> print(str(s))
    o [P(x=1, y=0)]

    >>> s, r = straight_longest([
    ...         P(1,0),
    ... P(0,1), P(1,1), P(2, 1), P(3, 1),
    ... P(0,2), P(1,2), P(2, 2), P(3, 2),
    ...         P(1,3),
    ... ])
    >>> print(str(s))
    - [P(x=0, y=2), P(x=1, y=2), P(x=2, y=2), P(x=3, y=2)]
    >>> s, r = straight_longest(r)
    >>> print(str(s))
    - [P(x=0, y=1), P(x=1, y=1), P(x=2, y=1), P(x=3, y=1)]
    >>> s, r = straight_longest(r)
    >>> print(str(s))
    | [P(x=1, y=0), P(x=1, y=3)]
    >>> r
    []

    >>> s, r = straight_longest([
    ...         P(1,0),
    ... P(0,1), P(1,1), P(2, 1),
    ...         P(1,2),
    ... ])
    >>> print(str(s))
    - [P(x=0, y=1), P(x=1, y=1), P(x=2, y=1)]
    >>> s, r = straight_longest(r)
    >>> print(str(s))
    | [P(x=1, y=0), P(x=1, y=2)]
    >>> r
    []

    >>> s, r = straight_longest([
    ...         P(1,0),
    ... P(0,1),         P(10, 1),
    ...         P(1,5),
    ... ])
    >>> print(str(s))
    - [P(x=0, y=1), P(x=10, y=1)]
    >>> s, r = straight_longest(r)
    >>> print(str(s))
    | [P(x=1, y=0), P(x=1, y=5)]
    >>> r
    []

    >>> s, r = straight_longest([
    ... P(0,0), P(1,0),
    ... P(0,1),         P(2, 1),
    ... P(0,2), P(1,2),
    ... P(0,3), P(1,3), P(2, 3),
    ... P(0,4), P(1,4),
    ... P(0,5),         P(2, 5),
    ... P(0,6), P(1,6),
    ... ])
    >>> print(str(s))
    | [P(x=0, y=0), P(x=0, y=1), P(x=0, y=2), P(x=0, y=3), P(x=0, y=4), P(x=0, y=5), P(x=0, y=6)]
    >>> s, r = straight_longest(r)
    >>> print(str(s))
    | [P(x=1, y=0), P(x=1, y=2), P(x=1, y=3), P(x=1, y=4), P(x=1, y=6)]
    >>> s, r = straight_longest(r)
    >>> print(str(s))
    | [P(x=2, y=1), P(x=2, y=3), P(x=2, y=5)]
    >>> r
    []

    """
    assert_type(positions, list)

    # Count how frequently each x and y coordinate is found.
    coordinate_count = {
        'x': defaultdict(int),
        'y': defaultdict(int),
    }
    for pos in positions:
        assert_type(pos, (Position, NamedPosition))
        coordinate_count['x'][pos.x] += 1
        coordinate_count['y'][pos.y] += 1

    # If out the most common x and v coordinates
    x_val = list(sorted((c, x) for x, c in coordinate_count['x'].items()))
    y_val = list(sorted((c, y) for y, c in coordinate_count['y'].items()))

    # Work out the direction this segment will run
    if x_val[-1][0] > y_val[-1][0]:
        direction = StraightSegment.Type.V
    else:
        direction = StraightSegment.Type.H

    # Work out which positions are on this segment
    segment = StraightSegment(direction, [])
    not_in_segment = []
    if direction == StraightSegment.Type.V:
        x_pos = x_val[-1][1]
        for pos in positions:
            if pos.x != x_pos:
                not_in_segment.append(pos)
                continue
            segment.append(pos)
    elif direction == StraightSegment.Type.H:
        direction = "-"
        y_pos = y_val[-1][1]
        for pos in positions:
            if pos.y != y_pos:
                not_in_segment.append(pos)
                continue
            segment.append(pos)

    # Single length segments are "stubs"
    if len(segment) == 1:
        segment.direction = StraightSegment.Type.S

    return segment, not_in_segment


def print_segments(segs):
    for s in segs:
        print(s)

def print_conns(conns):
    for p, (aname, bname)  in sorted(conns.items()):
        print("{}x{} {}<->{}".format(p.x, p.y, aname, bname))


def decompose_into_straight_lines(positions):
    """
    Takes a network and converts it to a list of straight segments.


    Arguments:
        positions : [(Position, [str, ...]), ...]

    >>> # Single element
    >>> pos = [NP(1,0),]
    >>> conns, segs = decompose_into_straight_lines(pos)
    >>> for s in segs:
    ...     print(s)
    o [NP(1,0,'b+a')]

    >>> # Single horizontal line
    >>> pos = [NP(1,0), NP(2,0)]
    >>> conns, segs = decompose_into_straight_lines(pos)
    >>> for s in segs:
    ...     print(s)
    - [NP(1,0,'b+a'), NP(2,0,'c+a')]

    >>> # Single vertical line
    >>> pos = [NP(1,2), NP(1,3)]
    >>> conns, segs = decompose_into_straight_lines(pos)
    >>> for s in segs:
    ...     print(s)
    | [NP(1,2,'b+c'), NP(1,3,'b+d')]

    >>> # Cross shape
    >>> pos = [
    ...           NP(1,0),
    ...  NP(0,1), NP(1,1), NP(2, 1),
    ...           NP(1,2),
    ... ]
    >>> conns, segs = decompose_into_straight_lines(pos)
    >>> print_segments(segs)
    - [NP(0,1,'a+b'), NP(1,1,'b+b'), NP(2,1,'c+b')]
    | [NP(1,0,'b+a'), NP(1,1,'b+b_x'), NP(1,2,'b+c')]
    >>> print_conns(conns)
    1x1 b+b<->b+b_x

    >>> # Cross with two horizontal bars
    >>> pos = [
    ...           NP(1,0),
    ...  NP(0,1), NP(1,1), NP(2, 1), NP(3, 1),
    ...  NP(0,2), NP(1,2), NP(2, 2), NP(3, 2),
    ...           NP(1,3),
    ... ]
    >>> conns, segs = decompose_into_straight_lines(pos)
    >>> print_segments(segs)
    - [NP(0,1,'a+b'), NP(1,1,'b+b'), NP(2,1,'c+b'), NP(3,1,'d+b')]
    - [NP(0,2,'a+c'), NP(1,2,'b+c'), NP(2,2,'c+c'), NP(3,2,'d+c')]
    | [NP(1,0,'b+a'), NP(1,1,'b+b_x'), NP(1,2,'b+c_x'), NP(1,3,'b+d')]
    >>> print_conns(conns)
    1x1 b+b<->b+b_x
    1x2 b+c<->b+c_x

    >>> # Cross with unequal horizontal bars
    >>> pos = [
    ...           NP(1,0),
    ...  NP(0,1), NP(1,1), NP(2, 1), NP(3, 1),
    ...  NP(0,2), NP(1,2), NP(2, 2),
    ...           NP(1,3),
    ... ]
    >>> conns, segs = decompose_into_straight_lines(pos)
    >>> print_segments(segs)
    - [NP(0,1,'a+b'), NP(1,1,'b+b'), NP(2,1,'c+b'), NP(3,1,'d+b')]
    - [NP(0,2,'a+c'), NP(1,2,'b+c'), NP(2,2,'c+c')]
    | [NP(1,0,'b+a'), NP(1,1,'b+b_x'), NP(1,2,'b+c_x'), NP(1,3,'b+d')]
    >>> print_conns(conns)
    1x1 b+b<->b+b_x
    1x2 b+c<->b+c_x

    >>> # FIXME: Cross with missing middle
    >>> pos = [
    ...           NP(1,0),
    ...  NP(0,1),          NP(10, 1),
    ...           NP(1,5),
    ... ]
    >>> try:
    ...     conns, segs = decompose_into_straight_lines(pos)
    ... except AssertionError:
    ...     pass

    >>> # 3 straight lines
    >>> pos = [
    ...  NP(0,0), NP(1,0),
    ...  NP(0,1),          NP(2,1),
    ...  NP(0,2), NP(1,2),
    ...  NP(0,3), NP(1,3), NP(2,3),
    ...  NP(0,4), NP(1,4),
    ...  NP(0,5),          NP(2,5),
    ...  NP(0,6), NP(1,6),
    ... ]
    >>> conns, segs = decompose_into_straight_lines(pos)
    >>> print_segments(segs)
    | [NP(0,0,'a+a'), NP(0,1,'a+b'), NP(0,2,'a+c'), NP(0,3,'a+d'), NP(0,4,'a+e'), NP(0,5,'a+f'), NP(0,6,'a+g')]
    - [NP(0,3,'a+d_x'), NP(1,3,'b+d_x'), NP(2,3,'c+d_x')]
    | [NP(1,0,'b+a'), NP(1,2,'b+c'), NP(1,3,'b+d'), NP(1,4,'b+e'), NP(1,6,'b+g')]
    | [NP(2,1,'c+b'), NP(2,3,'c+d'), NP(2,5,'c+f')]
    >>> print_conns(conns)
    0x3 a+d<->a+d_x
    1x3 b+d<->b+d_x
    2x3 c+d<->c+d_x

    >>> # H shaped
    >>> pos = [
    ...  NP(0,0),          NP(2,0),
    ...  NP(0,1),          NP(2,1),
    ...  NP(0,2),          NP(2,2),
    ...  NP(0,3), NP(1,3), NP(2,3),
    ...  NP(0,4),          NP(2,4),
    ... ]
    >>> conns, segs = decompose_into_straight_lines(pos)
    >>> print_segments(segs)
    | [NP(0,0,'a+a'), NP(0,1,'a+b'), NP(0,2,'a+c'), NP(0,3,'a+d'), NP(0,4,'a+e')]
    - [NP(0,3,'a+d_x'), NP(1,3,'b+d'), NP(2,3,'c+d_x')]
    | [NP(2,0,'c+a'), NP(2,1,'c+b'), NP(2,2,'c+c'), NP(2,3,'c+d'), NP(2,4,'c+e')]
    >>> print_conns(conns)
    0x3 a+d<->a+d_x
    2x3 c+d<->c+d_x

    >>> # Corner shape
    >>> pos = [
    ...  NP(0,1,'io_0/D_IN_0'), NP(1,1,'neigh_op_lft_0','neigh_op_lft_4'),
    ...                         NP(1,2,'neigh_op_bnl_0','neigh_op_bnl_4'),
    ... ]
    >>> conns, segs = decompose_into_straight_lines(pos)
    >>> print_segments(segs)
    - [NP(0,1,'io_0/D_IN_0'), NP(1,1,'neigh_op_lft_0','neigh_op_lft_4')]
    | [NP(1,1,'neigh_op_lft_0_x'), NP(1,2,'neigh_op_bnl_0','neigh_op_bnl_4')]
    >>> print_conns(conns)
    1x1 neigh_op_lft_0<->neigh_op_lft_0_x

    >>> # Going around corners
    >>> pos = [
    ...                            NP(1,0,'span4_horz_r_4'), NP(2,0,'span4_horz_r_8'), NP(3,0,'span4_horz_r_12'), NP(4,0,'span4_horz_l_12'),
    ...  NP(0,1,'span4_vert_b_0'),
    ... ]
    >>> conns, segs = decompose_into_straight_lines(pos)
    >>> print_segments(segs)
    - [NP(0,0,'span4_horz_r_4_to_span4_vert_b_0'), NP(1,0,'span4_horz_r_4'), NP(2,0,'span4_horz_r_8'), NP(3,0,'span4_horz_r_12'), NP(4,0,'span4_horz_l_12')]
    | [NP(0,0,'span4_horz_r_4_to_span4_vert_b_0_x'), NP(0,1,'span4_vert_b_0')]
    >>> print_conns(conns)
    0x0 span4_horz_r_4_to_span4_vert_b_0<->span4_horz_r_4_to_span4_vert_b_0_x

    >>> pos = [
    ...                            NP(1,0,'span4_horz_r_4'), NP(2,0,'span4_horz_r_8'), NP(3,0,'span4_horz_r_12'),
    ...  NP(0,1,'span4_vert_b_0'),
    ...  NP(0,2,'span4_vert_b_0'),
    ... ]
    >>> conns, segs = decompose_into_straight_lines(pos)
    >>> print_segments(segs)
    - [NP(0,0,'span4_horz_r_4_to_span4_vert_b_0'), NP(1,0,'span4_horz_r_4'), NP(2,0,'span4_horz_r_8'), NP(3,0,'span4_horz_r_12')]
    | [NP(0,0,'span4_horz_r_4_to_span4_vert_b_0_x'), NP(0,1,'span4_vert_b_0'), NP(0,2,'span4_vert_b_0')]
    >>> print_conns(conns)
    0x0 span4_horz_r_4_to_span4_vert_b_0<->span4_horz_r_4_to_span4_vert_b_0_x

    >>> pos = [
    ...  NP(10,0,'span4_horz_r_4'), NP(12,0,'span4_horz_r_8'), NP(13,0,'span4_horz_r_12'),
    ...                                                                                    NP(14,1,'span4_vert_b_0'),
    ...                                                                                    NP(14,2,'span4_vert_b_0'),
    ... ]
    >>> conns, segs = decompose_into_straight_lines(pos)
    >>> print_segments(segs)
    - [NP(10,0,'span4_horz_r_4'), NP(12,0,'span4_horz_r_8'), NP(13,0,'span4_horz_r_12'), NP(14,0,'span4_horz_r_12_to_span4_vert_b_0')]
    | [NP(14,0,'span4_horz_r_12_to_span4_vert_b_0_x'), NP(14,1,'span4_vert_b_0'), NP(14,2,'span4_vert_b_0')]
    >>> print_conns(conns)
    14x0 span4_horz_r_12_to_span4_vert_b_0<->span4_horz_r_12_to_span4_vert_b_0_x

    >>> # FIXME: This is a bit weird
    >>> # Make sure NP(1,2) isn't in the output...
    >>> pos = [
    ... NP(0,0),          NP(2,0),
    ... NP(0,1), NP(1,1), NP(2,1),
    ... NP(0,2),          NP(2,2),
    ... NP(0,3), NP(1,3), NP(2,3),
    ... NP(0,4),          NP(2,4),
    ... ]
    >>> conns, segs = decompose_into_straight_lines(pos)
    >>> print_segments(segs)
    | [NP(0,0,'a+a'), NP(0,1,'a+b'), NP(0,2,'a+c'), NP(0,3,'a+d'), NP(0,4,'a+e')]
    - [NP(0,3,'a+d_x'), NP(1,3,'b+d_x'), NP(2,3,'c+d_x')]
    | [NP(1,1,'b+b'), NP(1,3,'b+d')]
    | [NP(2,0,'c+a'), NP(2,1,'c+b'), NP(2,2,'c+c'), NP(2,3,'c+d'), NP(2,4,'c+e')]
    >>> print_conns(conns)
    0x3 a+d<->a+d_x
    1x3 b+d<->b+d_x
    2x3 c+d<->c+d_x

    >>> # FIXME: This is weird?
    >>> pos = [
    ...  NP(0,16,'span4_vert_t_12'),
    ...                              NP(1,17,'span4_horz_l_12'),
    ... ]
    >>> conns, segs = decompose_into_straight_lines(pos)
    >>> print_segments(segs)
    - [NP(0,16,'span4_vert_t_12'), NP(1,16,'span4_horz_l_12_to_span4_vert_t_12_x')]
    | [NP(1,16,'span4_horz_l_12_to_span4_vert_t_12'), NP(1,17,'span4_horz_l_12')]
    >>> print_conns(conns)
    1x16 span4_horz_l_12_to_span4_vert_t_12<->span4_horz_l_12_to_span4_vert_t_12_x

    """
    assert len(positions) > 0, positions
    for pos in positions:
        assert_type(pos, NamedPosition)

    npclass = positions[0].__class__
    pclass = positions[0].pos.__class__

    # position_used_by[position] = (NamedPosition, StraightSegment)
    position_used_by = {}
    segments = {
        '|': [],
        '-': [],
        'o': [],
        'ALL': [],
    }
    # connections[position] = (namea, nameb)
    connections = {}

    def add_segment(s, is_spine=False):
        assert len(s) > 0, (s, is_spine)
        assert_type(s, StraightSegment)
        for np in s:
            assert_type(np, NamedPosition)
            if not is_spine:
                assert np.pos not in position_used_by, (np.pos, s, position_used_by[np.pos])
                position_used_by[np.pos] = (np, s)

        for p, (other_p, other_s) in position_used_by.items():
            assert p.x == other_p.x, (p, other_p)
            assert p.y == other_p.y, (p, other_p)
            if s is other_s:
                continue

            if not s.along(p):
                continue

            assert p not in connections, (p, connections)

            current_name = other_p.names[0]
            new_name = current_name+'_x'

            connection_p = npclass(p, [new_name])
            if is_spine:
                s.replace(connection_p)
            else:
                s.append(connection_p)
            connections[p] = (current_name, new_name)
        s.sort()
        #print(s)
        segments['ALL'].append(s)
        segments[s.d.value].append(s)

    # Convert the positions into straight lines.
    remaining = list(positions)
    while len(remaining) > 0:
        assert_type(remaining, list)
        straight_segment, remaining = straight_longest(remaining)
        add_segment(straight_segment)

    if len(segments['ALL']) == 1:
        assert len(connections) == 0, (segments, connections)
        return connections, segments['ALL']

    # FIXME: Hack for dealing with the corner case
    if len(segments['ALL']) == 2 and len(connections) == 0:
        longest = segments['ALL'][0]
        other = []
        for seg in segments['ALL'][1:]:
            if len(longest) < len(seg):
                longest, seg = seg, longest
            other.append(seg)

        #assert len(other) == 1, (longest, other)
        #assert len(longest) > 1, (longest, other)
        pointa, pointb = straight_closet(longest, other[0])
        corner_point = longest.extend_to(pointb)
        corner_name = "{}_to_{}".format(pointa.names[0], pointb.names[0])
        longest.append(npclass(corner_point, [corner_name]))
        longest.sort()
        other[0].append(npclass(corner_point, [corner_name+"_x"]))
        other[0].sort()
        connections[corner_point] = (corner_name, corner_name+"_x")

    """
    # FIXME: Check all the segments are connected together
    for_checking = list(segments['ALL'])
    connected = [for_checking.pop(0)]
    while len(for_checking) > 0:
        point = None
        for seg1 in for_checking:
            for seg2 in connected:
                test_point = common_point(seg1, seg2)
                if test_point is not None:
                    point = test_point
                    connected.append(seg2)
                    break
        if point is not None:
            for_checking.remove(connected[-1])
        else:
            assert False, (for_checking, connected)
    """

    # Check connections
    # If they are all vertical or horizontal, we need to create a spine.
    if len(connections) == 0 and len(segments['-']) > 0:
        assert len(segments['|']) == 0
        for seg in segments['o']:
            seg.direction = StraightSegment.Type.H
            segments['-'].append(seg)

        x_pos = defaultdict(int)
        for seg in segments['-']:
            assert len(seg) > 0, seg
            for p in seg:
                x_pos[p.x] += 1

        x = list(sorted((m, x) for x, m in x_pos.items()))[-1][-1]

        spine = StraightSegment(StraightSegment.Type.V, [])
        for seg in segments['-']:
            p = pclass(x, seg.y_range()[0])
            spine.append(npclass(
                p, names=[seg.get_at(p).first]))
        add_segment(spine, True)

    elif len(connections) == 0 and len(segments['|']) > 0:
        assert len(segments['-']) == 0
        for seg in segments['o']:
            seg.direction = StraightSegment.Type.V
            segments['|'].append(seg)

        y_pos = defaultdict(int)
        for seg in segments['|']:
            assert len(seg) > 0, seg
            for p in seg:
                y_pos[p.y] += 1

        y = list(sorted((m, y) for y, m in y_pos.items()))[-1][-1]

        spine = StraightSegment(StraightSegment.Type.H, [])
        for seg in segments['|']:
            assert len(seg) > 0, seg
            p = pclass(seg.x_range()[0], y)
            spine.append(npclass(
                p, names=[seg.get_at(p).first]))
        add_segment(spine, True)

    segments['ALL'].sort()
    return connections, segments['ALL']


def straight_ends(positions):
    """Get the ends of a straight line.

    >>> straight_ends([P(0,1), P(1,1)])
    (P(x=0, y=1), P(x=1, y=1))

    >>> straight_ends([P(0,1), P(1,1), P(2,1)])
    (P(x=0, y=1), P(x=2, y=1))

    >>> straight_ends([P(1,0), P(1,1), P(1,2)])
    (P(x=1, y=0), P(x=1, y=2))

    >>> straight_ends([P(1,1), P(1,1)])
    (P(x=1, y=1), P(x=1, y=1))

    >>> # FIXME: Is this the correct behaviour?
    >>> straight_ends([P(1,1), P(1,4)])
    (P(x=1, y=1), P(x=1, y=4))

    >>> straight_ends([P(0,0), P(1,1)])
    Traceback (most recent call last):
      ...
    TypeError: Not straight x:{0, 1} y:{0, 1}
    >>> straight_ends([P(0,0), P(1,1), P(0,2)])
    Traceback (most recent call last):
      ...
    TypeError: Not straight x:{0, 1} y:{0, 1, 2}

    """
    pclass = positions[0].__class__

    x_pos = set(p.x for p in positions)
    y_pos = set(p.y for p in positions)

    if len(x_pos) > 1:
        if len(y_pos) != 1:
            raise TypeError("Not straight x:{} y:{}".format(x_pos, y_pos))
    if len(y_pos) > 1:
        if len(x_pos) != 1:
            raise TypeError("Not straight x:{} y:{}".format(x_pos, y_pos))

    start = pclass(min(x_pos), min(y_pos))
    end = pclass(max(x_pos), max(y_pos))

    assert start.x == end.x or start.y == end.y, "{} {}".format(
        start, end)

    return start, end


def distance(p1, p2):
    return math.sqrt((p2.x - p1.x)**2+(p2.y - p1.y)**2)


def straight_closet(line1, line2):
    """

    # >>> straight_intersection((P(0, 0), P(0, 10)), (P(0, 0), P(10, 0)))
    # P(x=0, y=0)
    # >>> straight_intersection((P(10, 0), P(10, 10)), (P(0, 0), P(10, 0)))
    # P(x=10, y=0)
    # >>> straight_intersection((P(5, 0), P(5, 10)), (P(0, 0), P(10, 0)))
    # P(x=5, y=0)
    # >>> straight_intersection((P(0, 5), P(10, 5)), (P(5, 0), P(5, 10)))
    # P(x=5, y=5)

    """
    min_d = sys.maxsize
    pa, pb = None, None

    for p1 in line1:
        for p2 in line2:
            d = distance(p1, p2)
            if d < min_d:
                pa, pb = p1, p2
                min_d = d

    assert pa != None, "{} {}".format(line1, line2)
    assert pb != None, "{} {}".format(line1, line2)
    return pa, pb


def main():
    import doctest

    print('Doctest begin')
    doctest.testmod(optionflags=doctest.ELLIPSIS)
    print('Doctest end')


if __name__ == "__main__":
    main()
