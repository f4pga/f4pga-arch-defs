#!/usr/bin/env python3
# Run `python3 -m unittest utils.lib.rr_graph.tests.test_channel`
import unittest

from ..channel import Track, T, ChannelGrid

class TestGraph(unittest.TestCase):
    def test_track_type(self):
        self.assertEqual(
            Track.Type.X,
            Track((1, 0), (10, 0)).type
        )
        self.assertEqual(
            Track.Type.Y,
            Track((0, 1), (0, 10)).type
        )
        with self.assertRaises(ValueError):
            Track((1, 1), (1, 1)).type

        self.assertEqual(
            Track.Type.X,
            Track((1, 1), (1, 1), type_hint=Track.Type.X).type
        )
        self.assertEqual(
            Track.Type.Y,
            Track((1, 1), (1, 1), type_hint=Track.Type.Y).type
        )
    
    def test_track_type_guess(self):
        self.assertEqual(
            Track.Type.X,
            Track((1, 0), (10, 0)).type_guess
        )
        self.assertEqual(
            Track.Type.Y,
            Track((0, 1), (0, 10)).type_guess
        )
        self.assertEqual(
            'None',
            str(Track((1, 1), (1, 1)).type_guess)
        )

    def test_track_start0(self):
        self.assertEqual(
            1,
            Track((1, 0), (10, 0)).start0
        )
        self.assertEqual(
            1,
            Track((0, 1), (0, 10)).start0
        )
        with self.assertRaises(ValueError):
            Track((1, 1), (1, 1)).start0

        self.assertEqual(
            1,
            Track((1, 1), (1, 1), type_hint=Track.Type.X).start0
        )
        self.assertEqual(
            10,
            Track((10, 0), (1, 0)).start0
        )
        self.assertEqual(
            10,
            Track((0, 10), (0, 1)).start0
        )

    def test_track_end0(self):
        self.assertEqual(
            10,
            Track((1, 0), (10, 0)).end0
        )
        self.assertEqual(
            10,
            Track((0, 1), (0, 10)).end0
        )
        with self.assertRaises(ValueError):
            Track((1, 1), (1, 1)).end0

        self.assertEqual(
            1,
            Track((1, 1), (1, 1), type_hint=Track.Type.X).end0
        )
        self.assertEqual(
            1,
            Track((10, 0), (1, 0)).end0
        )
        self.assertEqual(
            1,
            Track((0, 10), (0, 1)).end0
        )
    
    def test_track_common(self):
        self.assertEqual(
            0,
            Track((0, 0), (10, 0)).common
        )
        self.assertEqual(
            0,
            Track((0, 0), (0, 10)).common
        )
        with self.assertRaises(ValueError):
            Track((1, 1), (1, 1)).common

        self.assertEqual(
            1,
            Track((1, 1), (1, 1), type_hint=Track.Type.X).common
        )
        self.assertEqual(
            0,
            Track((10, 0), (0, 0)).common
        )
        self.assertEqual(
            0,
            Track((0, 10), (0, 0)).common
        )
        self.assertEqual(
            4,
            Track((4, 10), (4, 0)).common
        )

    def test_track_length(self):
        self.assertEqual(
            10,
            Track((0, 0), (10, 0)).length
        )
        self.assertEqual(
            10,
            Track((0, 0), (0, 10)).length
        )
        self.assertEqual(
            0,
            Track((1, 1), (1, 1)).length
        )
        self.assertEqual(
            10,
            Track((10, 0), (0, 0)).length
        )
        self.assertEqual(
            10,
            Track((0, 10), (0, 0)).length
        )

    def test_track_new_idx(self):
        s = (1, 4)
        e = (1, 8)
        c1 = Track(s, e, idx=0)
        c2 = c1.new_idx(2)
        self.assertEqual(
            c1.start,
            c2.start
        )
        self.assertEqual(
            c1.end,
            c2.end
        )
        self.assertEqual(
            0,
            c1.idx
        )
        self.assertEqual(
            2,
            c2.idx
        )

    def test_track_repr(self):
        self.assertEqual(
            'T((0,0), (10,0))',
            repr(Track((0, 0), (10, 0)))
        )
        self.assertEqual(
            'T((0,0), (0,10))',
            repr(Track((0, 0), (0, 10)))
        )
        self.assertEqual(
            'T((1,2), (3,2), 5)',
            repr(Track((1, 2), (3, 2), idx=5))
        )
        self.assertEqual(
            'T(ABC)',
            repr(Track((1, 2), (3, 2), name="ABC"))
        )
        self.assertEqual(
            'T(ABC,5)',
            repr(Track((1, 2), (3, 2), idx=5, name="ABC"))
        )

    def test_track_str(self):
        self.assertEqual(
            'CHANX 0,0->10,0',
            str(Track((0, 0), (10, 0)))
        )
        self.assertEqual(
            'CHANY 0,0->0,10',
            str(Track((0, 0), (0, 10)))
        )
        self.assertEqual(
            'CHANX 1,2->3,2 @5',
            str(Track((1, 2), (3, 2), idx=5))
        )
        self.assertEqual(
            'ABC',
            str(Track((1, 2), (3, 2), name="ABC"))
        )
        self.assertEqual(
            'ABC@5',
            str(Track((1, 2), (3, 2), idx=5, name="ABC"))
        )

    def test_channelgrid_width(self):
        g = ChannelGrid((6, 7), Track.Type.Y)
        self.assertEqual(
            6,
            g.width
        )
        self.assertEqual(
            7,
            g.height
        )
    
    def test_channelgrid_create_track(self):
        g = ChannelGrid((11, 11), Track.Type.X)
        # Adding the first channel
        g.create_track(Track((1, 6), (4, 6), name="A"))
        self.assertEqual(
            '[T(A,0)]',
            str(g[(1,6)])
        )
        self.assertEqual(
            '[T(A,0)]',
            str(g[(2,6)])
        )
        self.assertEqual(
            '[T(A,0)]',
            str(g[(4,6)])
        )
        self.assertEqual(
            '[None]',
            str(g[(5,6)])
        )

        # Adding second non-overlapping second channel
        g.create_track(Track((5, 6), (7, 6), name="B"))
        self.assertEqual(
            '[T(A,0)]',
            str(g[(4,6)])
        )
        self.assertEqual(
            '[T(B,0)]',
            str(g[(5,6)])
        )
        self.assertEqual(
            '[T(B,0)]',
            str(g[(7,6)])
        )
        self.assertEqual(
            '[None]',
            str(g[(8,6)])
        )

        # Adding third channel which overlaps with second channel
        g.create_track(Track((5, 6), (7, 6), name="T"))
        self.assertEqual(
            '[T(A,0), None]',
            str(g[(4,6)])
        )
        self.assertEqual(
            '[T(B,0), T(T,1)]',
            str(g[(5,6)])
        )
        self.assertEqual(
            '[T(B,0), T(T,1)]',
            str(g[(7,6)])
        )

        # Adding a channel which overlaps, but is a row over
        g.create_track(Track((5, 7), (7, 7), name="D"))
        self.assertEqual(
            '[T(B,0), T(T,1)]',
            str(g[(5,6)])
        )
        self.assertEqual(
            '[T(D,0)]',
            str(g[(5,7)])
        )
        
        # Adding fourth channel which overlaps both the first
        # and second+third channel
        g.create_track(Track((3, 6), (6, 6), name="E"))
        self.assertEqual(
            '[T(A,0), None, None]',
            str(g[(2,6)])
        )
        self.assertEqual(
            '[T(A,0), None, T(E,2)]',
            str(g[(3,6)])
        )
        self.assertEqual(
            '[T(B,0), T(T,1), T(E,2)]',
            str(g[(6,6)])
        )
        self.assertEqual(
            '[T(B,0), T(T,1), None]',
            str(g[(7,6)])
        )

        # This channel fits in the hole left by the last one.
        g.create_track(Track((1, 6), (3, 6), name="F"))
        self.assertEqual(
            '[T(A,0), T(F,1), None]',
            str(g[(1,6)])
        )
        self.assertEqual(
            '[T(A,0), T(F,1), None]',
            str(g[(2,6)])
        )
        self.assertEqual(
            '[T(A,0), T(F,1), T(E,2)]',
            str(g[(3,6)])
        )
        self.assertEqual(
            '[T(A,0), None, T(E,2)]',
            str(g[(4,6)])
        )

        # Add another channel which causes a hole
        g.create_track(Track((1, 6), (7, 6), name="G"))
        self.assertEqual(
            '[T(A,0), T(F,1), None, T(G,3)]',
            str(g[(1,6)])
        )
        self.assertEqual(
            '[T(A,0), T(F,1), None, T(G,3)]',
            str(g[(2,6)])
        )
        self.assertEqual(
            '[T(A,0), T(F,1), T(E,2), T(G,3)]',
            str(g[(3,6)])
        )
        self.assertEqual(
            '[T(A,0), None, T(E,2), T(G,3)]',
            str(g[(4,6)])
        )
        self.assertEqual(
            '[T(B,0), T(T,1), T(E,2), T(G,3)]',
            str(g[(5,6)])
        )
        self.assertEqual(
            '[T(B,0), T(T,1), T(E,2), T(G,3)]',
            str(g[(6,6)])
        )
        self.assertEqual(
            '[T(B,0), T(T,1), None, T(G,3)]',
            str(g[(7,6)])
        )
        self.assertEqual(
            '[None, None, None, None]',
            str(g[(8,6)])
        )


if __name__ == "__main__":
    unittest.main()