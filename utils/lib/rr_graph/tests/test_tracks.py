import unittest
from ..tracks import Track, Tracks, Direction


class TracksTests(unittest.TestCase):
    def setUp(self):
        trk_array = [
            Track(direction='Y', x_low=1, x_high=1, y_low=1, y_high=5),
            Track(direction='X', x_low=1, x_high=3, y_low=1, y_high=1),
            Track(direction='Y', x_low=3, x_high=3, y_low=1, y_high=4),
        ]
        cnx_array = [(0, 1), (1, 2)]
        self.trks = Tracks(trk_array, cnx_array)

    def test_verify_tracks(self):
        self.trks.verify_tracks()

    def test_verify_tracks_not_connected(self):
        self.trks.tracks.append(
            Track(direction='X', x_low=1, x_high=3, y_low=4, y_high=4)
        )

        with self.assertRaises(AssertionError):
            self.trks.verify_tracks()

    def test_verify_tracks_directon_error(self):
        self.trks.tracks.append(
            Track(direction='Y', x_low=1, x_high=1, y_low=5, y_high=6)
        )
        self.trks.track_connections.append((0, 3))

        with self.assertRaises(AssertionError):
            self.trks.verify_tracks()

    def test_adjacent_simple(self):

        self.assertEqual(
            self.trks.is_wire_adjacent_to_track(0, (1, 1)), Direction.RIGHT
        )
        self.assertEqual(
            self.trks.is_wire_adjacent_to_track(0, (2, 1)), Direction.LEFT
        )
        self.assertEqual(
            self.trks.is_wire_adjacent_to_track(0, (5, 2)), Direction.NO_SIDE
        )

        self.assertEqual(
            self.trks.is_wire_adjacent_to_track(1, (2, 1)), Direction.TOP
        )
        self.assertEqual(
            self.trks.is_wire_adjacent_to_track(1, (2, 2)), Direction.BOTTOM
        )
        self.assertEqual(
            self.trks.is_wire_adjacent_to_track(1, (5, 2)), Direction.NO_SIDE
        )

    def test_adjacenet_assert(self):
        trk_array = [
            Track(direction='Y', x_low=1, x_high=1, y_low=1, y_high=5),
            Track(direction='X', x_low=1, x_high=3, y_low=1, y_high=1),
            Track(direction='foobar', x_low=3, x_high=3, y_low=1, y_high=4),
        ]
        cnx_array = [(0, 1), (1, 2)]
        trks = Tracks(trk_array, cnx_array)
        with self.assertRaises(AssertionError):
            trks.is_wire_adjacent_to_track(2, (3, 1))

    def test_get_tracks(self):

        dirs = [d for d in self.trks.get_tracks_for_wire_at_coord((1, 1))]
        self.assertEqual(
            sorted(dirs), [(0, Direction.RIGHT), (1, Direction.TOP)]
        )
