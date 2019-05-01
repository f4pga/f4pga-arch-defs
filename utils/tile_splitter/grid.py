""" Grid splitting model with connection database back references. """
from enum import Enum


class Direction(Enum):
    NORTH = 1
    SOUTH = 2
    EAST = 3
    WEST = 4


NORTH = Direction.NORTH
SOUTH = Direction.SOUTH
EAST = Direction.EAST
WEST = Direction.WEST

OPPOSITE_DIRECTIONS = {
    NORTH: SOUTH,
    SOUTH: NORTH,
    EAST: WEST,
    WEST: EAST,
}


def opposite_direction(direction):
    return OPPOSITE_DIRECTIONS[direction]


# Right handed coordinate system, N/S in y, E/W in x, E is x-positive,
# S is y-positive.
DIRECTION_OFFSET = {
    NORTH: [0, -1],
    SOUTH: [0, 1],
    EAST: [1, 0],
    WEST: [-1, 0],
}


def coordinate_in_direction(coord, direction):
    x, y = coord
    dx, dy = DIRECTION_OFFSET[direction]
    x += dx
    y += dy

    if x < 0 or y < 0:
        return None
    else:
        return x, y


class Site(object):
    def __init__(
            self, name, phy_tile_pkey, tile_type_pkey, site_type_pkey,
            site_pkey, x, y
    ):
        self.name = name
        self.phy_tile_pkey = phy_tile_pkey
        self.tile_type_pkey = tile_type_pkey
        self.site_type_pkey = site_type_pkey
        self.site_pkey = site_pkey
        self.x = x
        self.y = y


class Tile(object):
    def __init__(
            self, root_phy_tile_pkeys, phy_tile_pkeys, tile_type_pkey, sites
    ):
        self.root_phy_tile_pkeys = root_phy_tile_pkeys
        self.phy_tile_pkeys = phy_tile_pkeys
        self.tile_type_pkey = tile_type_pkey
        self.sites = sites
        self.split_sites = False
        self.neighboors = {}

    def link_neighboor_in_direction(self, other_tile, direction_to_other_tile):
        if direction_to_other_tile in self.neighboors:
            assert id(self.neighboors[direction_to_other_tile]
                      ) == id(other_tile), (
                          self.neighboors,
                          direction_to_other_tile,
                      )
        self.neighboors[direction_to_other_tile] = other_tile

        direction_to_this_tile = opposite_direction(direction_to_other_tile)
        if direction_to_this_tile in other_tile.neighboors:
            assert id(other_tile.neighboors[direction_to_this_tile]
                      ) == id(self)

        other_tile.neighboors[direction_to_this_tile] = self

    def insert_in_direction(self, other_tile, direction_to_other_tile):
        old_neighboor = self.neighboors.get(direction_to_other_tile, None)

        direction_to_this_tile = opposite_direction(direction_to_other_tile)

        self.neighboors[direction_to_other_tile] = other_tile
        other_tile.neighboors[direction_to_this_tile] = self

        if old_neighboor is not None:
            other_tile.neighboors[direction_to_other_tile] = old_neighboor
            old_neighboor.neighboors[direction_to_this_tile] = other_tile

    def walk_in_direction(self, direction):
        node = self

        while True:
            yield node
            if direction in node.neighboors:
                node = node.neighboors[direction]
            else:
                break


def check_grid_loc(grid_loc_map):
    """ Verifies input grid makes sense.

    Internal grid consistency is defined as:
     - Has an origin location @ (0, 0)
     - Is rectangular
     - Has no gaps.
    """
    xs, ys = zip(*grid_loc_map.keys())

    max_x = max(xs)
    max_y = max(ys)

    for x in range(max_x + 1):
        for y in range(max_y + 1):
            assert (x, y) in grid_loc_map, (x, y)


def build_mesh(current, visited, loc, grid_loc_map):
    """ Stitch grid_loc_map into a double-linked list 2D mesh. """

    for direction in (SOUTH, EAST):
        new_loc = coordinate_in_direction(loc, direction)
        if new_loc in grid_loc_map:
            current.link_neighboor_in_direction(
                grid_loc_map[new_loc], direction
            )
            if id(grid_loc_map[new_loc]) not in visited:
                visited.add(id(grid_loc_map[new_loc]))
                build_mesh(
                    grid_loc_map[new_loc], visited, new_loc, grid_loc_map
                )


class Grid(object):
    def __init__(self, grid_loc_map, empty_tile_type_pkey):
        check_grid_loc(grid_loc_map)
        self.origin = grid_loc_map[(0, 0)]
        build_mesh(self.origin, set(), (0, 0), grid_loc_map)
        self.items = grid_loc_map.values()
        self.empty_tile_type_pkey = empty_tile_type_pkey

    def column(self, x):
        top_of_column = self.origin

        for _ in range(x):
            top_of_column = top_of_column.neighboors[EAST]

        return top_of_column

    def row(self, y):
        right_of_row = self.origin

        for _ in range(y):
            right_of_row = right_of_row.neighboors[SOUTH]

    def split_tile(self, tile, tile_type_pkeys, split_direction):
        assert len(tile.sites) == len(tile_type_pkeys)

        sites = tile.sites
        tile.tile_type_pkey = self.empty_tile_type_pkey
        new_tiles = []

        for idx, tile in enumerate(tile.walk_in_direction(split_direction)):
            new_tiles.append(tile)

            if idx + 1 > len(tile_type_pkeys):
                break

        for tile, site, new_tile_type_pkey in zip(new_tiles, sites,
                                                  tile_type_pkeys):
            assert tile.tile_type_pkey == self.empty_tile_type_pkey
            tile.tile_type_pkey = new_tile_type_pkey
            tile.sites = [site]
            tile.split_sites = True

    def insert_empty_column(self, top_of_column, insert_in_direction):
        assert NORTH not in top_of_column.neighboors

        empty_tiles = []
        for tile in top_of_column.walk_in_direction(SOUTH):
            empty_tile = Tile(
                root_phy_tile_pkeys=[],
                phy_tile_pkeys=tile.phy_tile_pkeys,
                tile_type_pkey=self.empty_tile_type_pkey,
                sites=[]
            )
            empty_tiles.append(empty_tile)

            tile.insert_in_direction(empty_tile, insert_in_direction)

        for a, b in zip(empty_tiles, empty_tiles[1:]):
            a.link_neighboor_in_direction(b, SOUTH)

        self.check_grid()

    def split_column(
            self, top_of_column, tile_type_pkey, tile_type_pkeys,
            split_direction
    ):
        # Find how many empty tiles are required to support the split
        num_cols_to_insert = 0
        for tile in top_of_column.walk_in_direction(SOUTH):
            if tile.tile_type_pkey != tile_type_pkey:
                continue

            for idx, tile_in_split in enumerate(
                    tile.walk_in_direction(split_direction)):
                if idx == 0:
                    continue
                else:
                    if tile.tile_type_pkey != self.empty_tile_type_pkey:
                        num_cols_to_insert = max(num_cols_to_insert, idx)

                    if idx + 1 >= len(tile_type_pkeys):
                        break

        for _ in range(num_cols_to_insert):
            self.insert_empty_column(top_of_column, split_direction)

        for tile in top_of_column.walk_in_direction(SOUTH):
            if tile.tile_type_pkey != tile_type_pkey:
                continue

            self.split_tile(tile, tile_type_pkeys, split_direction)

    def split_tile_type(
            self, tile_type_pkey, tile_type_pkeys, split_direction
    ):
        tiles_seen = set()
        tiles = []
        top_of_columns_to_split = []

        for tile in self.items:
            if id(tile) in tiles_seen:
                continue

            if tile.tile_type_pkey == tile_type_pkey:
                # Found a column that needs to be split, walk to the bottom of
                # the column, then back to the top.
                for tile in tile.walk_in_direction(SOUTH):
                    pass

                for tile in tile.walk_in_direction(NORTH):
                    if id(tile) not in tiles_seen:
                        tiles_seen.add(id(tile))
                        if tile.tile_type_pkey == tile_type_pkey:
                            tiles.append(tile)

                top_of_columns_to_split.append(tile)

        num_sites_arr = [len(tile.sites) for tile in tiles]
        num_sites_to_split = max(num_sites_arr)
        assert num_sites_to_split > 1
        assert min(num_sites_arr) == num_sites_to_split
        assert len(tile_type_pkeys) == num_sites_to_split

        for top_of_column in top_of_columns_to_split:
            self.split_column(
                top_of_column, tile_type_pkey, tile_type_pkeys, split_direction
            )

    def output_grid(self):
        grid_loc_map = {}
        for x, tile in enumerate(self.origin.walk_in_direction(EAST)):
            for y, tile in enumerate(tile.walk_in_direction(SOUTH)):
                grid_loc_map[(x, y)] = tile

        check_grid_loc(grid_loc_map)

        return grid_loc_map

    def check_grid(self):
        self.output_grid()
