""" Simple and correct version of Channel formation.

channel.py is actually broken for some track configuration, and generates
an excessive number of dummy tracks to fill empty space (channel.Channel = >2M
versus channel2.Channel ~70k).

"""
from intervaltree import IntervalTree, Interval


class Channel(object):
    """ Packs tracks into ptc tracks

    >>> tracks = [
    ...     (1, 3, 0),
    ...     (1, 1, 1),
    ...     (4, 5, 2),
    ...     (4, 4, 3),
    ...     (0, 10, 4),
    ...     ]
    >>> channel_model = Channel(tracks)
    >>> channel_model.pack_tracks()
    >>> for ptc, tree in enumerate(channel_model.trees):
    ...     print('ptc={}'.format(ptc))
    ...     for itr in tree:
    ...         x, y, idx = tracks[itr[2]]
    ...         assert idx == itr[2]
    ...         print(' tracks[{}] = ({}, {})'.format(itr[2], x, y))
    ptc=0
     tracks[4] = (0, 10)
    ptc=1
     tracks[2] = (4, 5)
     tracks[0] = (1, 3)
    ptc=2
     tracks[3] = (4, 4)
     tracks[1] = (1, 1)
    >>> for ptc, min_v, max_v in channel_model.fill_empty(0, 10):
    ...     print('ptc={} ({}, {})'.format(ptc, min_v, max_v))
    ptc=1 (0, 0)
    ptc=1 (6, 10)
    ptc=2 (0, 0)
    ptc=2 (2, 3)
    ptc=2 (5, 10)
    """

    def __init__(self, tracks):
        """

        Attributes
        ----------
        tracks : list of tuples of (min, max, idx)
        """
        self.trees = []
        self.tracks = sorted(tracks, key=lambda x: x[1] - x[0])

    def _place_track(self, track):
        """Add track to existing interval tree, if there is room (ie doesn't overlap)
        If track won't fit in any existing tree, allocate a new tree for the track"""
        for idx, tree in enumerate(self.trees):
            if not tree.overlaps(track[0], track[1] + 1):
                tree.add(
                    Interval(begin=track[0], end=track[1] + 1, data=track[2])
                )
                return

        self.trees.append(IntervalTree())
        self.trees[-1].add(
            Interval(begin=track[0], end=track[1] + 1, data=track[2])
        )

    def pack_tracks(self):
        """pack all tracks"""
        for track in self.tracks[::-1]:
            self._place_track(track)

    def fill_empty(self, min_value, max_value):
        """Generator that yields tracks for any gaps in the channels.
        """
        for idx, tree in enumerate(self.trees):
            tracks = sorted(tree.items(), key=lambda x: x[0])

            if min_value <= tracks[0].begin - 1:
                yield (idx, min_value, tracks[0].begin - 1)

            for cur_track, next_track in zip(tracks, tracks[1:]):
                if cur_track.end <= next_track.begin - 1:
                    yield (idx, cur_track.end, next_track.begin - 1)

            if tracks[-1].end <= max_value:
                yield (idx, tracks[-1].end, max_value)
