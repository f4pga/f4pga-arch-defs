""" Simple and correct version of Channel formation.

channel.py is actually broken for some track configuration, and generates
an excessive number of dummy tracks to fill empty space (channel.Channel = >2M
versus channel2.Channel ~70k).

"""
from intervaltree import IntervalTree, Interval

class Channel(object):
    def __init__(self, tracks):
        self.trees = []
        self.tracks = sorted(tracks, key=lambda x: x[1] - x[0])

    def place_track(self, track):
        for idx, tree in enumerate(self.trees):
            if not tree.overlaps(track[0], track[1]):
                tree.add(Interval(begin=track[0], end=track[1]+1, data=track[2]))
                return

        self.trees.append(IntervalTree())
        self.trees[-1].add(Interval(begin=track[0], end=track[1]+1, data=track[2]))

    def pack_tracks(self):
        for track in self.tracks[::-1]:
            self.place_track(track)

    def fill_empty(self, min_value, max_value):
        for idx, tree in enumerate(self.trees):
            tracks = list(tree.items())

            if min_value <= tracks[0].begin-1:
                yield (idx, min_value, tracks[0].begin-1)

            for cur_track, next_track in zip(tracks, tracks[1:]):
                if cur_track.end <= next_track.begin-1:
                    yield (idx, cur_track.end, next_track.begin-1)

            if tracks[-1].end <= max_value:
                yield (idx, tracks[-1].end, max_value)
