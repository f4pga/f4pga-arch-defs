""" Simple and correct version of Channel formation.

channel.py is actually broken for some track configuration, and generates
an excessive number of dummy tracks to fill empty space (channel.Channel = >2M
versus channel2.Channel ~70k).

"""


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
     tracks[0] = (1, 3)
     tracks[2] = (4, 5)
    ptc=2
     tracks[1] = (1, 1)
     tracks[3] = (4, 4)
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

    def _start_track(self, track):
        self.trees.append([track])

    def _add_track_to_tree(self, track, idx=-1):
        self.trees[idx].append(track)

    def _verify_trees(self):
        for tree in self.trees:
            for a, b in zip(tree, tree[1:]):
                assert a[1] <= b[0]

    def pack_tracks(self):
        """pack all tracks

        Algorithm:

         1. Sort tracks by length, shortest tracks first.  Popping from back
            of python lists is O(1).
         2. Create stack for each starting values, inserting in length order.
         3. Starting with the lowest starting value, greedly pack tracks
            Algorithm weaknesses:
             - Linear scan for lowest starting value
             - Linear scan for packing

            Both weaknesses are O(Number grid dim * Number of tracks) in
            pathological case, however grid dimensions tend to be fairly small,
            (e.g. 50T is 150), so scans are practically fast.

            If the grid dimension size grows large, revisit how to find the
            lowest starting value and next bucket pack.  Relevant operation is
            given coordinate, find next largest non-empty bucket.
         3a. Pop largest track from smallest starting value, creating a new
             channel
         3b. Pop largest track starting from end of previous track until no
             tracks can follow.
         3c. Repeat 3 until everything is packed.

        """

        by_low = {}

        def pop(low):
            track = by_low[low].pop()

            if len(by_low[low]) == 0:
                del by_low[low]

            return track

        for low, high, key in self.tracks:
            if low not in by_low:
                by_low[low] = []

            by_low[low].append((high, key))

        if len(by_low) > 0:
            high = max(by_low)

        while len(by_low) > 0:
            track_low = min(by_low)
            track_high, key = pop(track_low)

            self._start_track((track_low, track_high, key))

            while track_high is not None:
                start = track_high + 1
                track_high = None
                for track_low in range(start, high + 1):
                    if track_low in by_low:
                        track_high, key = pop(track_low)
                        self._add_track_to_tree((track_low, track_high, key))
                        break

        self._verify_trees()

    def fill_empty(self, min_value, max_value):
        """Generator that yields tracks for any gaps in the channels.
        """
        for idx, tree in enumerate(self.trees):
            tracks = sorted(tree, key=lambda x: x[0])

            if min_value <= tracks[0][0] - 1:
                yield (idx, min_value, tracks[0][0] - 1)

            for cur_track, next_track in zip(tracks, tracks[1:]):
                if cur_track[1] + 1 <= next_track[0] - 1:
                    yield (idx, cur_track[1] + 1, next_track[0] - 1)

            if tracks[-1][1] + 1 <= max_value:
                yield (idx, tracks[-1][1] + 1, max_value)
