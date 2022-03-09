#!/usr/bin/env python3
# Run `python3 -m unittest utils.lib.rr_graph.tests.test_channel`
import unittest

from ..grid import Site, Tile, Grid, check_grid_loc, EAST


class TestGrid(unittest.TestCase):
    def test_good_grids(self):
        check_grid_loc({
            (0, 0): None,
        })

        check_grid_loc({
            (0, 0): None,
            (0, 1): None,
        })

        check_grid_loc({
            (0, 0): None,
            (1, 0): None,
        })

        check_grid_loc(
            {
                (0, 0): None,
                (1, 0): None,
                (1, 1): None,
                (0, 1): None,
            }
        )

    def test_bad_grids(self):
        self.assertRaises(ValueError, lambda: check_grid_loc({}))
        self.assertRaises(
            AssertionError, lambda: check_grid_loc({(0, 1): None})
        )
        self.assertRaises(
            AssertionError, lambda:
            check_grid_loc({
                (0, 0): None,
                (1, 0): None,
                (0, 1): None,
            })
        )

    def test_round_trip(self):
        grid_loc_map = {}
        NUM_X = 5
        NUM_Y = 8
        for x in range(NUM_X):
            for y in range(NUM_Y):
                coord_idx = x + y * NUM_X
                grid_loc_map[(x, y)] = Tile(
                    root_phy_tile_pkeys=[coord_idx],
                    phy_tile_pkeys=[coord_idx],
                    tile_type_pkey=coord_idx,
                    sites=[],
                )

        empty_tile_type_pkey = NUM_X * NUM_Y

        grid = Grid(grid_loc_map, empty_tile_type_pkey)
        output_grid_loc_map = grid.output_grid()

        for x in range(NUM_X):
            for y in range(NUM_Y):
                coord_idx = x + y * NUM_X
                self.assertEqual(
                    coord_idx, output_grid_loc_map[(x, y)].tile_type_pkey
                )

    def test_tile_split(self):
        grid_loc_map = {}
        NUM_X = 5
        NUM_Y = 8
        for x in range(NUM_X):
            for y in range(NUM_Y):
                coord_idx = x + y * NUM_X

                sites = [
                    Site(
                        name='{}, {}'.format(x, y),
                        phy_tile_pkey=coord_idx,
                        tile_type_pkey=x,
                        site_type_pkey=x,
                        site_pkey=2 * x,
                        x=0,
                        y=0,
                    ),
                    Site(
                        name='{}, {}'.format(x, y),
                        phy_tile_pkey=coord_idx,
                        tile_type_pkey=x,
                        site_type_pkey=x,
                        site_pkey=2 * x + 1,
                        x=0,
                        y=1,
                    ),
                ]

                grid_loc_map[(x, y)] = Tile(
                    root_phy_tile_pkeys=[coord_idx],
                    phy_tile_pkeys=[coord_idx],
                    tile_type_pkey=x,
                    sites=sites,
                )

        empty_tile_type_pkey = NUM_X * NUM_Y

        grid = Grid(grid_loc_map, empty_tile_type_pkey)

        grid.split_tile_type(
            tile_type_pkey=3,
            tile_type_pkeys=[
                NUM_X,
                NUM_X + 1,
            ],
            split_direction=EAST,
            split_map={
                (0, 0): 0,
                (0, 1): 1,
            },
        )

        output_grid_loc_map = grid.output_grid()

        assert (NUM_X, NUM_Y - 1) in output_grid_loc_map
        assert (NUM_X + 1, NUM_Y - 1) not in output_grid_loc_map
        assert (NUM_X, NUM_Y) not in output_grid_loc_map

        for y in range(NUM_Y):
            self.assertFalse(output_grid_loc_map[(0, y)].split_sites)
            self.assertFalse(output_grid_loc_map[(2, y)].split_sites)

            self.assertListEqual(
                output_grid_loc_map[(3, y)].root_phy_tile_pkeys,
                [3 + y * NUM_X],
            )
            self.assertListEqual(
                output_grid_loc_map[(3, y)].phy_tile_pkeys,
                [3 + y * NUM_X],
            )
            self.assertTrue(output_grid_loc_map[(3, y)].split_sites, y)
            self.assertEqual(1, len(output_grid_loc_map[(3, y)].sites))

            self.assertListEqual(
                output_grid_loc_map[(4, y)].root_phy_tile_pkeys,
                [],
            )
            self.assertListEqual(
                output_grid_loc_map[(4, y)].phy_tile_pkeys,
                [3 + y * NUM_X],
            )
            self.assertTrue(output_grid_loc_map[(4, y)].split_sites)
            self.assertEqual(1, len(output_grid_loc_map[(4, y)].sites))

            self.assertFalse(output_grid_loc_map[(NUM_X, y)].split_sites)

    def test_tile_split_progressive(self):
        grid_loc_map = {}
        NUM_X = 5
        NUM_Y = 8
        for x in range(NUM_X):
            for y in range(NUM_Y):
                coord_idx = x + y * NUM_X

                sites = [
                    Site(
                        name='{}, {}'.format(x, y),
                        phy_tile_pkey=coord_idx,
                        tile_type_pkey=x,
                        site_type_pkey=x,
                        site_pkey=2 * x,
                        x=0,
                        y=0,
                    ),
                    Site(
                        name='{}, {}'.format(x, y),
                        phy_tile_pkey=coord_idx,
                        tile_type_pkey=x,
                        site_type_pkey=x,
                        site_pkey=2 * x + 1,
                        x=0,
                        y=1,
                    ),
                ]

                grid_loc_map[(x, y)] = Tile(
                    root_phy_tile_pkeys=[coord_idx],
                    phy_tile_pkeys=[coord_idx],
                    tile_type_pkey=coord_idx,
                    sites=sites,
                )

        empty_tile_type_pkey = NUM_X * NUM_Y

        grid = Grid(grid_loc_map, empty_tile_type_pkey)

        for y in range(NUM_Y):
            grid.split_tile_type(
                tile_type_pkey=3 + y * NUM_X,
                tile_type_pkeys=[
                    NUM_X * NUM_Y + 1,
                    NUM_X * NUM_Y + 2,
                ],
                split_direction=EAST,
                split_map={
                    (0, 0): 0,
                    (0, 1): 1,
                },
            )

        output_grid_loc_map = grid.output_grid()

        assert (NUM_X, NUM_Y - 1) in output_grid_loc_map
        assert (NUM_X + 1, NUM_Y - 1) not in output_grid_loc_map
        assert (NUM_X, NUM_Y) not in output_grid_loc_map

        for y in range(NUM_Y):
            self.assertFalse(output_grid_loc_map[(0, y)].split_sites)
            self.assertFalse(output_grid_loc_map[(2, y)].split_sites)

            self.assertListEqual(
                output_grid_loc_map[(3, y)].root_phy_tile_pkeys,
                [3 + y * NUM_X],
            )
            self.assertListEqual(
                output_grid_loc_map[(3, y)].phy_tile_pkeys,
                [3 + y * NUM_X],
            )
            self.assertTrue(output_grid_loc_map[(3, y)].split_sites, y)
            self.assertEqual(1, len(output_grid_loc_map[(3, y)].sites))

            self.assertListEqual(
                output_grid_loc_map[(4, y)].root_phy_tile_pkeys,
                [],
            )
            self.assertListEqual(
                output_grid_loc_map[(4, y)].phy_tile_pkeys,
                [3 + y * NUM_X],
            )
            self.assertTrue(output_grid_loc_map[(4, y)].split_sites)
            self.assertEqual(1, len(output_grid_loc_map[(4, y)].sites))

            self.assertFalse(output_grid_loc_map[(NUM_X, y)].split_sites)
