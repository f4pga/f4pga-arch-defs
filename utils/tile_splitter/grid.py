""" Grid splitting model with connection database back references.

The Grid object provides methods to manipulate a 2D grid of Tile objects, that
contain zero or more Site objects. Site objects are considered immutable.

To construct the Grid object, the initial grid and an empty_tile_type_pkey must
be provided.  The initial grid should be provided as a map of 2 element int
tuples to Tile objects.  Tile objects should already contain their initial
sites prior to construction of the Grid object.

"""
from enum import Enum
from collections import namedtuple


class Direction(Enum):
    """ Grid directions. """
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

# Zipper direction when splitting in a direction
SPLIT_NEXT_DIRECTIONS = {
    NORTH: EAST,
    SOUTH: EAST,
    EAST: SOUTH,
    WEST: SOUTH,
}


def opposite_direction(direction):
    """ Return opposite direction of given direction.

    >>> opposite_direction(NORTH)
    <Direction.SOUTH: 2>
    >>> opposite_direction(SOUTH)
    <Direction.NORTH: 1>
    >>> opposite_direction(EAST)
    <Direction.WEST: 4>
    >>> opposite_direction(WEST)
    <Direction.EAST: 3>

    """
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
    """ Given a coordinate, returns a new coordinate 1 step in direction.

    Coordinate system is right handed, N/S in y, E/W in x.  E is x-positive.
    S is y-positive.

    Parameters
    ----------
    coord : Tuple of 2 ints
        Starting coordinate
    direction : Direction
        Direction to add unit vector.

    Returns
    -------
    Tuple of 2 ints
        Coordinate 1 unit step in specified direction.  Will return none if
        x or y coordinate is negative.

    Examples
    --------

    >>> coordinate_in_direction((0, 0), SOUTH)
    (0, 1)
    >>> coordinate_in_direction((0, 0), EAST)
    (1, 0)
    >>> coordinate_in_direction((1, 1), SOUTH)
    (1, 2)
    >>> coordinate_in_direction((1, 1), NORTH)
    (1, 0)
    >>> coordinate_in_direction((1, 1), EAST)
    (2, 1)
    >>> coordinate_in_direction((1, 1), WEST)
    (0, 1)

    # Returns None for negative coordinates.
    >>> coordinate_in_direction((0, 0), NORTH)
    >>> coordinate_in_direction((1, 0), NORTH)
    >>> coordinate_in_direction((0, 0), WEST)
    >>> coordinate_in_direction((0, 1), WEST)

    """
    x, y = coord
    dx, dy = DIRECTION_OFFSET[direction]
    x += dx
    y += dy

    if x < 0 or y < 0:
        return None
    else:
        return x, y


class Site(namedtuple('Site', ('name', 'phy_tile_pkey', 'tile_type_pkey',
                               'site_type_pkey', 'site_pkey', 'x', 'y'))):
    """ Object to hold back reference information for a site. """
    pass


class Tile(object):
    """ Tile instance within the grid.

    Attributes
    ----------
    root_phy_tile_pkeys : list of ints
        The list of root_phy_tile_pkey's.

        By default a tile typically has one root phy_tile_pkey, which is the
        phy_tile this initial represents.

        If two Tile objects are merged, the root_phy_tile_pkeys are also merged.
        If a Tile object is split, only one of the split tiles will take all
        of the root_phy_tile_pkeys, and the other tiles will have no
        root_phy_tile_pkeys.

        Invariant: Each phy_tile_pkey will appear in 1 and only 1 Tile
        object's root_phy_tile_pkeys list.

        Because of the invariant, the root_phy_tile_pkeys list can be used as
        a default assignment of children of the relevant phy_tile_pkey items
        (e.g. wires, pips, sites, etc).

    phy_tile_pkeys : list of ints
        The list of phy_tile_pkey's.  This is the list of all phy_tile_pkey's
        that are involved in this tile via either a tile merge or split.

        By default a tile typically has one phy_tile_pkey, which is the
        phy_tile this initial represents.

        If two Tile objects are split, all output tiles will get a copy of the
        original phy_tile_pkeys list.  This attribute can be used to determine
        what phy_tile_pkeys were used to make this tile.

    sites : list of Site objects
        This is the list of Site's contained within this tile.  This should
        be initial set to the Site objects contained within the original
        phy_tile.

        Invariant: Each Site object will be contained within exactly one Tile
        object.

    split_sites : boolean
        True if this tile was split.

        Invariant: Each split tile will contain exactly one Site object.
        Invariant: Two tiles that were split cannot be merged, otherwise the
        resulting Tile will have two Sites, potentially from different
        phy_tile_pkey, which cannot be presented using FASm prefixes.

    neighboors : Map of Direction to Tile object
        Linked list pointers to neighboors tiles.

        Invariant: Underlying linked link should be rectangular after an
        operation on the grid.  An single operation on the Tile will typically
        invalidate the overall grid, it is up to the Grid object to enforce
        the rectangular constraint.

        Invariant: Underlying linked link must not be circular.

    """

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
        """ Connect this tile to another tile in a specific direction.

        It is legal to call this method on an existing connection, but it is
        not legal to call this method to replace an existing connection.

        Parameters
        ----------
        other_tile : Tile object
            Other Tile object to connect in specified direction.
        direction_to_other_tile : Direction
            Direction to connect other tile.
        """
        if direction_to_other_tile in self.neighboors:
            assert id(
                self.neighboors[direction_to_other_tile]
            ) == id(other_tile), (self.neighboors, direction_to_other_tile)
        self.neighboors[direction_to_other_tile] = other_tile

        direction_to_this_tile = opposite_direction(direction_to_other_tile)
        if direction_to_this_tile in other_tile.neighboors:
            assert id(other_tile.neighboors[direction_to_this_tile]
                      ) == id(self)

        other_tile.neighboors[direction_to_this_tile] = self

    def insert_in_direction(self, other_tile, direction_to_other_tile):
        """ Insert a tile in a specified direction.

        Parameters
        ----------
        other_tile : Tile object
            Other Tile object to insert in specified direction.
        direction_to_other_tile : Direction
            Direction to insert other tile.

        """
        old_neighboor = self.neighboors.get(direction_to_other_tile, None)

        direction_to_this_tile = opposite_direction(direction_to_other_tile)

        self.neighboors[direction_to_other_tile] = other_tile
        other_tile.neighboors[direction_to_this_tile] = self

        if old_neighboor is not None:
            other_tile.neighboors[direction_to_other_tile] = old_neighboor
            old_neighboor.neighboors[direction_to_this_tile] = other_tile

    def walk_in_direction(self, direction):
        """ Walk in specified direction from this Tile node.

        Parameters
        ----------

        direction : Direction
            Direction to walk in.

        Yields
        ------

        tile : Tile
            Tile in specified direction.  First Tile object will always be the
            tile whose walk_in_direction was invoked.  When the end of the grid
            is encounted, no more tiles will be yielded.
        """

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

    Parameters
    ----------
    grid_loc_map : Dict of 2 int tuple to Tile objects
        Grid being checked.

    Raises
    ------
    AssertionError
        If provided grid does not conform to assumptions about grid.

    """
    xs, ys = zip(*grid_loc_map.keys())

    max_x = max(xs)
    max_y = max(ys)

    for x in range(max_x + 1):
        for y in range(max_y + 1):
            assert (x, y) in grid_loc_map, (x, y)


def build_mesh(current, visited, loc, grid_loc_map):
    """ Stitch grid_loc_map into a double-linked list 2D mesh.

    Modifies Tile object neighboors attributes to form a doubly linked list
    2D mesh.

    It is strongly recommended that grid_loc_map be passed to check_grid_loc
    prior to calling build_mesh to verify grid invariants.

    Parameters
    ----------
    current : Tile object
    visited : set of python object id's
        Should be empty on root invocation.
    loc : Location of current Tile object argument
    grid_loc_map : Dict of 2 int tuple to Tile objects
        Grid being converted to linked list form.

    """

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
    """ Object for manipulating a 2D grid of Tile objects.

    Parameters
    ----------

    grid_loc_map : Dict of 2 int tuple to Tile objects
        Initial grid of Tile objects.
    empty_tile_type_pkey : int
        tile_type_pkey to use when creating new empty tiles during tile splits.

    """

    def __init__(self, grid_loc_map, empty_tile_type_pkey):
        # Make sure initial grid is sane
        check_grid_loc(grid_loc_map)

        # Keep root object of grid.
        self.origin = grid_loc_map[(0, 0)]

        # Convert grid to doubly-linked list.
        build_mesh(self.origin, set(), (0, 0), grid_loc_map)

        # Keep list of all Tile objects for convience.
        self.items = grid_loc_map.values()

        self.empty_tile_type_pkey = empty_tile_type_pkey

    def column(self, x):
        """ Return Tile object at top of column.

        Parameters
        ----------
        x : int
            0 based column to retrive.

        Returns
        -------
        top_of_column : Tile
            Tile object at top of column

        """
        top_of_column = self.origin

        for _ in range(x):
            top_of_column = top_of_column.neighboors[EAST]

        return top_of_column

    def row(self, y):
        """ Return Tile object at right of row.

        Parameters
        ----------
        y : int
            0 based row to retrive.

        Returns
        -------
        right_of_row : Tile
            Tile object at right of row

        """
        right_of_row = self.origin

        for _ in range(y):
            right_of_row = right_of_row.neighboors[SOUTH]

    def split_tile(self, tile, tile_type_pkeys, split_direction, split_map):
        """ Split tile in specified direction.

        This method requires that the tiles required to perform the split (e.g.
        len(tile_type_pkeys)-1 tiles in split_direction from tile) have
        tile_type_pkey == empty_tile_type_pkey, e.g. they are empty tiles.

        If empty tiles must be inserted into the grid to accomidate the split,
        this must be done prior to calling this method.

        Parameters
        ----------
        tile : Tile object
            Tile being split
        tile_type_pkeys : List of int
            List of new tile_type_pkeys to be used after the tile split.
            The tile being split will become tile_type_pkeys[0], the next tile
            in split_direction will become tile_type_pkeys[1], etc.

            len(tile_type_pkeys) must equal len(tile.sites) to ensure that each
            tile output from the split has a new tile type.
        split_direction : Direction
            Which direction from tile should the split occur.

        """
        sites = tile.sites
        tile.tile_type_pkey = self.empty_tile_type_pkey
        phy_tile_pkeys = set(tile.phy_tile_pkeys)
        new_tiles = []

        for idx, tile in enumerate(tile.walk_in_direction(split_direction)):
            assert tile.tile_type_pkey == self.empty_tile_type_pkey, (
                tile.tile_type_pkey
            )
            tile.phy_tile_pkeys = []

            new_tiles.append(tile)

            if idx + 1 >= len(tile_type_pkeys):
                break

        for tile, new_tile_type_pkey in zip(new_tiles, tile_type_pkeys):
            assert tile.tile_type_pkey == self.empty_tile_type_pkey

            tile.tile_type_pkey = new_tile_type_pkey
            tile.phy_tile_pkeys = list(
                set(tile.phy_tile_pkeys) | phy_tile_pkeys
            )
            tile.sites = []
            tile.split_sites = True

        for site in sites:
            site_idx = split_map[site.x, site.y]
            assert site_idx < len(tile_type_pkeys), (
                site, site_idx, tile_type_pkeys
            )
            new_tiles[site_idx].sites.append(site)

    def insert_empty(self, top, insert_in_direction):
        """ Insert empty row/colum.

        Insert a row/column of empty tiles from the tiles in the row/column specified
        by top_of_row/column tile.  The new empty tiles will have tile_type_pkey
        set to empty_tile_type_pkey, and have phy_tile_pkeys of the tile they
        were inserted from.

        Parameters
        ----------
        top_of_row/column : Tile object
            Tile at top of row/column adjcent to where new row/column should be
            inserted.
        insert_in_direction : Direction
            Direction to insert empty tiles, from perspective of the row/column
            specified by top_of_row/column.

        """
        # Verify that insert direction is not the same as zipper direction.
        next_dir = SPLIT_NEXT_DIRECTIONS[insert_in_direction]

        # Verify that top is in fact the top of the zipper
        assert OPPOSITE_DIRECTIONS[next_dir] not in top.neighboors

        empty_tiles = []
        for tile in top.walk_in_direction(next_dir):
            empty_tile = Tile(
                root_phy_tile_pkeys=[],
                phy_tile_pkeys=list(tile.phy_tile_pkeys),
                tile_type_pkey=self.empty_tile_type_pkey,
                sites=[]
            )
            empty_tiles.append(empty_tile)

            tile.insert_in_direction(empty_tile, insert_in_direction)

        for a, b in zip(empty_tiles, empty_tiles[1:]):
            a.link_neighboor_in_direction(b, next_dir)

        self.check_grid()

    def split_in_dir(
            self,
            top,
            tile_type_pkey,
            tile_type_pkeys,
            split_direction,
            split_map,
    ):
        """ Split row/column of tiles.

        Splits specified tile types into new row/column by first inserting any
        required empty row/column in the split direction, and then performing
        the split.

        Parameters
        ----------
        top_of_row/column : Tile object
            Tile at top of row/column where split should be performed.
        tile_type_pkey : Tile type to split.
        tile_type_pkeys : Refer to split_tile documentation.
        split_direction : Direction
            Direction to insert perform split.  New row/column will be inserted
            in that direction to accomidate the tile split.

        """
        next_dir = SPLIT_NEXT_DIRECTIONS[split_direction]

        # Find how many empty tiles are required to support the split
        num_to_insert = 0
        for tile in top.walk_in_direction(next_dir):
            if tile.tile_type_pkey != tile_type_pkey:
                continue

            for idx, tile_in_split in enumerate(
                    tile.walk_in_direction(split_direction)):
                if idx == 0:
                    continue
                else:
                    if tile_in_split.tile_type_pkey != self.empty_tile_type_pkey:
                        num_to_insert = max(num_to_insert, idx)

                    if idx + 1 >= len(tile_type_pkeys):
                        break

        for _ in range(num_to_insert):
            self.insert_empty(top, split_direction)

        for tile in top.walk_in_direction(next_dir):
            if tile.tile_type_pkey != tile_type_pkey:
                continue

            self.split_tile(tile, tile_type_pkeys, split_direction, split_map)

    def split_tile_type(
            self, tile_type_pkey, tile_type_pkeys, split_direction, split_map
    ):
        """ Split a specified tile type within grid.

        Splits specified tile types by finding each column that contains the
        relevant tile type, and spliting each column.

        Parameters
        ----------
        tile_type_pkey : Tile type to split.
        tile_type_pkeys : Refer to split_tile documentation.
        split_direction : Direction
            Direction to insert perform split.

        """
        tiles_seen = set()
        tiles = []
        tops_to_split = []

        next_dir = SPLIT_NEXT_DIRECTIONS[split_direction]

        for tile in self.items:
            if id(tile) in tiles_seen:
                continue

            if tile.tile_type_pkey == tile_type_pkey:
                # Found a row/column that needs to be split, walk to the bottom of
                # the row/column, then back to the top.
                for tile in tile.walk_in_direction(next_dir):
                    pass

                for tile in tile.walk_in_direction(
                        OPPOSITE_DIRECTIONS[next_dir]):
                    if id(tile) not in tiles_seen:
                        tiles_seen.add(id(tile))
                        if tile.tile_type_pkey == tile_type_pkey:
                            tiles.append(tile)

                tops_to_split.append(tile)

        for top in tops_to_split:
            self.split_in_dir(
                top, tile_type_pkey, tile_type_pkeys, split_direction,
                split_map
            )

    def output_grid(self):
        """ Convert grid back to coordinate lookup form.

        Returns
        -------
        grid_loc_map : Dict of 2 int tuple to Tile objects
            Output grid of Tile objects.

        """
        grid_loc_map = {}
        for x, tile in enumerate(self.origin.walk_in_direction(EAST)):
            for y, tile in enumerate(tile.walk_in_direction(SOUTH)):
                grid_loc_map[(x, y)] = tile

        check_grid_loc(grid_loc_map)

        return grid_loc_map

    def check_grid(self):
        """ Verifies that grid linked list model still represents valid grid.
        """
        self.output_grid()
