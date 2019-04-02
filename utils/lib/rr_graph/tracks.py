from collections import namedtuple
import pprint
from enum import Enum


class Direction(Enum):
    NO_SIDE = 0
    LEFT = 1
    RIGHT = 2
    TOP = 3
    BOTTOM = 4


Track = namedtuple('Track', 'direction x_low x_high y_low y_high')


def print_tracks(tracks):
    pprint.pprint(tracks)


def make_tracks(xs, ys, points):
    """ Give a list of xs columns and ys rows and points, return a list of
        Track's and connections between the tracks.

        An assert will fail if each point in the point list is not covered by
        a column in xs or a row in ys.

        Connections will be models as indicies into the track list.

        Return:
        [Track], [(index into track list, index into track list)]

    >>> pos = [
    ... (0,0),        (2,0),
    ... (0,1), (1,1), (2,1),
    ... (0,2),        (2,2),
    ... (0,3), (1,3), (2,3),
    ... (0,4),        (2,4),
    ... ]
    >>> xs = [0, 2]
    >>> ys = [1, 3]
    >>> tracks, connections = make_tracks(xs, ys, pos)
    >>> print_tracks(tracks)
    [Track(direction='Y', x_low=0, x_high=0, y_low=0, y_high=4),
     Track(direction='Y', x_low=2, x_high=2, y_low=0, y_high=4),
     Track(direction='X', x_low=0, x_high=2, y_low=1, y_high=1),
     Track(direction='X', x_low=0, x_high=2, y_low=3, y_high=3)]
    >>> print(connections)
    [(3, 0), (2, 0), (2, 1)]

    >>> pos = [
    ... (68,48), (69,48),
    ... (68,49), (69,49),
    ...          (69,50),
    ...          (69,51),
    ...          (69,52),
    ...          (69,53), (70,53), (71,53), (72,53)]
    >>> xs = [68, 69]
    >>> ys = [53]
    >>> tracks, connections = make_tracks(xs, ys, pos)
    >>> print_tracks(tracks)
    [Track(direction='Y', x_low=68, x_high=68, y_low=48, y_high=53),
     Track(direction='Y', x_low=69, x_high=69, y_low=48, y_high=53),
     Track(direction='X', x_low=68, x_high=72, y_low=53, y_high=53)]
    >>> print(connections)
    [(2, 0), (2, 1)]


    """
    x_set = set(xs)
    y_set = set(ys)

    for x, y in points:
        assert x in x_set or y in y_set

    all_xs, all_ys = zip(*points)
    x_min = min(all_xs)
    x_max = max(all_xs)
    y_min = min(all_ys)
    y_max = max(all_ys)

    tracks = []
    x_tracks = []
    y_tracks = []
    for x in xs:
        tracks.append(
            Track(
                direction='Y',
                x_low=x,
                x_high=x,
                y_low=y_min,
                y_high=y_max,
            )
        )
        y_tracks.append(len(tracks) - 1)

    for y in ys:
        tracks.append(
            Track(
                direction='X',
                x_low=x_min,
                x_high=x_max,
                y_low=y,
                y_high=y,
            )
        )
        x_tracks.append(len(tracks) - 1)

    if len(tracks) == 1:
        return tracks, []

    # If there is more than 1 track, there must be a track in each dimension
    assert len(xs) >= 1 and len(ys) >= 1

    connections = set()

    # Always just connect X tracks to the first Y track, and Y tracks to the
    # first X tracks.
    #
    # To dedup connections, the x channel track will appear first in the
    # connection list.
    for idx, track in enumerate(tracks):
        if track.direction == 'X':
            connections.add((idx, y_tracks[0]))
        else:
            assert track.direction == 'Y'
            connections.add((x_tracks[0], idx))

    return tracks, list(connections)


class Tracks(object):
    def __init__(self, tracks, track_connections):
        self.tracks = tracks
        self.track_connections = track_connections

    def verify_tracks(self):
        """ Verify that all tracks are connected to all other tracks. """
        track_connections = {}

        for idx, _ in enumerate(self.tracks):
            track_connections[idx] = set((idx, ))

        for conn_a, conn_b in self.track_connections:
            if track_connections[conn_a] is track_connections[conn_b]:
                continue

            assert self.tracks[conn_a].direction != self.tracks[conn_b
                                                                ].direction

            track_connections[conn_a] |= track_connections[conn_b]

            for track_idx in track_connections[conn_a]:
                track_connections[track_idx] = track_connections[conn_a]

        assert len(
            set(id(s) for s in track_connections.values())
        ) == 1, track_connections

    def is_wire_adjacent_to_track(self, idx, coord):
        track = self.tracks[idx]
        wire_x, wire_y = coord

        if track.direction == 'X':
            pin_top = track.y_low == wire_y
            pin_bottom = track.y_low == wire_y - 1
            adjacent_channel = (
                (pin_top or pin_bottom)
                and (track.x_low <= wire_x and wire_x <= track.x_high)
            )

            if adjacent_channel:
                if pin_top:
                    return Direction.TOP
                elif pin_bottom:
                    return Direction.BOTTOM
                else:
                    assert False, (coord, track)
            else:
                return Direction.NO_SIDE

        elif track.direction == 'Y':
            pin_right = track.x_low == wire_x
            pin_left = track.x_low == wire_x - 1
            adjacent_channel = (
                (pin_right or pin_left)
                and (track.y_low <= wire_y and wire_y <= track.y_high)
            )

            if adjacent_channel:
                if pin_right:
                    return Direction.RIGHT
                elif pin_left:
                    return Direction.LEFT
                else:
                    assert False, (coord, track)
            else:
                return Direction.NO_SIDE
        else:
            assert False, track

    def get_tracks_for_wire_at_coord(self, coord):
        """ Returns which track indicies and direction a wire at a coord can
            be connected too. """

        wire_x, wire_y = coord

        for idx, track in enumerate(self.tracks):
            pin_dir = self.is_wire_adjacent_to_track(idx, coord)
            if pin_dir != Direction.NO_SIDE:
                yield (idx, pin_dir)


def main():
    import doctest

    print('Doctest begin')
    doctest.testmod(optionflags=doctest.ELLIPSIS)
    print('Doctest end')


if __name__ == "__main__":
    main()
