#!/usr/bin/env python3

import re
import json
import pprint

from enum import Enum
from collections import namedtuple

class OrderedEnum(Enum):
    def __ge__(self, other):
        if self.__class__ is other.__class__:
            return self.name >= other.name
        if hasattr(other.__class__, "name"):
            return self.name >= other.name
        return NotImplemented
    def __gt__(self, other):
        if self.__class__ is other.__class__:
            return self.name > other.name
        if hasattr(other.__class__, "name"):
            return self.name > other.name
        return NotImplemented
    def __le__(self, other):
        if self.__class__ is other.__class__:
            return self.name <= other.name
        if hasattr(other.__class__, "name"):
            return self.name <= other.name
        return NotImplemented
    def __lt__(self, other):
        if self.__class__ is other.__class__:
            return self.name < other.name
        if hasattr(other.__class__, "name"):
            return self.name < other.name
        return NotImplemented


class CompassDir(OrderedEnum):
    """
    >>> print(repr(CompassDir.NN))
    <CompassDir.NN: 'North'>
    >>> print(str(CompassDir.NN))
    ( 0, -1, NN)
    >>> for d in CompassDir:
    ...     print(OrderedEnum.__str__(d))
    CompassDir.NW
    CompassDir.NN
    CompassDir.NE
    CompassDir.EE
    CompassDir.SE
    CompassDir.SS
    CompassDir.SW
    CompassDir.WW
    >>> for y in (-1, 0, 1):
    ...     for x in (-1, 0, 1):
    ...         print(
    ...             "(%2i %2i)" % (x, y),
    ...             str(CompassDir.from_coords(x, y)),
    ...             str(CompassDir.from_coords((x, y))),
    ...             )
    (-1 -1) (-1, -1, NW) (-1, -1, NW)
    ( 0 -1) ( 0, -1, NN) ( 0, -1, NN)
    ( 1 -1) ( 1, -1, NE) ( 1, -1, NE)
    (-1  0) (-1,  0, WW) (-1,  0, WW)
    ( 0  0) None None
    ( 1  0) ( 1,  0, EE) ( 1,  0, EE)
    (-1  1) (-1,  1, SW) (-1,  1, SW)
    ( 0  1) ( 0,  1, SS) ( 0,  1, SS)
    ( 1  1) ( 1,  1, SE) ( 1,  1, SE)
    >>> print(str(CompassDir.NN.flip()))
    ( 0,  1, SS)
    >>> print(str(CompassDir.SE.flip()))
    (-1, -1, NW)
    """
    NW = 'North West'
    NN = 'North'
    NE = 'North East'
    EE = 'East'
    SE = 'South East'
    SS = 'South'
    SW = 'South West'
    WW = 'West'
    # Single letter aliases
    N = NN
    E = EE
    S = SS
    W = WW

    @property
    def distance(self):
        return sum(a*a for a in self.coords)

    def __init__(self, *args, **kw):
        self.__cords = None
        pass

    @property
    def coords(self):
        if not self.__cords:
            self.__cords = self.convert_to_coords[self]
        return self.__cords

    @property
    def x(self):
        return self.coords[0]

    @property
    def y(self):
        return self.coords[-1]

    def __iter__(self):
        return iter(self.coords)

    def __getitem__(self, k):
        return self.coords[k]

    @classmethod
    def from_coords(cls, x, y=None):
        if y is None:
            return cls.from_coords(*x)
        return cls.convert_from_coords[(x, y)]

    def flip(self):
        return self.from_coords(self.flip_coords[self.coords])

    def __add__(self, o):
        return (o[0]+self.x, o[1]+self.y)

    def __radd__(self, o):
        return (o[0]+self.x, o[1]+self.y)

    def __str__(self):
        return "(%2i, %2i, %s)" % (self.x, self.y, self.name)


CompassDir.convert_to_coords = {}
CompassDir.convert_from_coords = {}
CompassDir.flip_coords = {}
CompassDir.straight = []
CompassDir.angled = []
for d in list(CompassDir) + [None]:
    if d is None:
        x,y = 0, 0
    else:
        if d.name[0] == 'N':
            y = -1
        elif d.name[0] == 'S':
            y = 1
        else:
            assert d.name[0] in ('E', 'W')
            y = 0

        if d.name[1] == 'E':
            x = 1
        elif d.name[1] == 'W':
            x = -1
        else:
            assert d.name[1] in ('N', 'S')
            x = 0

    CompassDir.convert_to_coords[d] = (x, y)
    CompassDir.convert_from_coords[(x, y)] = d
    CompassDir.flip_coords[(x, y)] = (-1*x, -1*y)

    length = x*x + y*y
    if length == 1:
        CompassDir.straight.append(d)
    elif length == 2:
        CompassDir.angled.append(d)


import doctest
doctest.testmod()



compass = {}
def add(tile_from, dir, tile_to, pairs):
    if tile_from not in compass:
        compass[tile_from] = {}

    pairs = set(tuple(a) for a in pairs)

    lookup = (dir, tile_to)
    if lookup in compass[tile_from]:
        assert pairs == compass[tile_from][lookup], (
            tile_from, dir, tile_to, pairs, compass[tile_from][lookup])
    else:
        compass[tile_from][lookup] = pairs


for conns in json.load(open("tileconn.json")):
    assert "grid_deltas" in conns and len(conns["grid_deltas"]) == 2
    assert "tile_types" in conns and len(conns["tile_types"]) == 2
    assert "wire_pairs" in conns

    tile_from, tile_to = conns["tile_types"]
    dir = CompassDir.from_coords(conns["grid_deltas"])
    if not dir:
        print("Skipping %s -> %s" % (tile_from, tile_to))
        continue

    print("%20s" % tile_from, dir, tile_to)

    add(tile_from, dir, tile_to, conns["wire_pairs"])
    dir = dir.flip()
    add(tile_to, dir, tile_from, ((b,a) for a,b in conns["wire_pairs"]))

tile_types = list(compass.keys())

has_conns_compass = {}
no_conns_compass = {}
for tile_type_a in tile_types:
    print()
    print("%s type" % tile_type_a)
    no_conns_compass[tile_type_a] = {}
    has_conns_compass[tile_type_a] = {}
    for dir in CompassDir.straight:
        has_connections = []
        no_connections = []

        for tile_type_b in tile_types:
            look_for = (dir, tile_type_b)

            if look_for in compass[tile_type_a].keys():
                has_connections.append(tile_type_b)
            else:
                no_connections.append(tile_type_b)

        print("On %s has connections to [%-30s] and none to %i other tile types" % (dir, " ".join(has_connections), len(no_connections)))

        assert len(has_connections) + len(no_connections) == len(tile_types)

        no_conns_compass[tile_type_a][dir] = no_connections
        has_conns_compass[tile_type_a][dir] = has_connections

grid = {}
for tile_name, tile_details in json.load(open("tilegrid.json"))["tiles"].items():
    assert "grid_x" in tile_details, (tile_name, tile_details)
    assert "grid_y" in tile_details, (tile_name, tile_details)
    assert "type" in tile_details, (tile_name, tile_details)

    grid[(tile_details["grid_x"], tile_details["grid_y"])] = tile_details["type"]

grid_min = (min(x for x,y in grid), min(y for x,y in grid))
grid_max = (max(x for x,y in grid), max(y for x,y in grid))

print()
print(grid_min, "to", grid_max)
print()


def wire_type(a):
    if isinstance(a, tuple):
        a = a[0]
    if isinstance(a, SpanWire):
        return a.Ending
    return None


annoying_wires = re.compile("(_[NSLR][0-9])")

neigh_map = {}
starting_groups = {}
wires_start_map = {}
wires_compass_map = {}

def find_wire_type(wire_name, wire_coord, leaves_via):
    if len(leaves_via) == 2:
        return "PASS"
    if len(leaves_via) != 1:
        assert False, "Unknown wires: %s %s" % (wire_name, leaves_via)

    if "END" in wire_name:
        return "END"
    elif "BEG" in wire_name:
        return "START"

    if wire_coord[0] == grid_max[0] or wire_coord[1] == grid_max[1] or wire_coord[0] == grid_min[0] or wire_coord[1] == grid_min[1]:
        return "LEAVES"

    if "CLK" in wire_name or "FAN" in wire_name:
        return "CLOCK"

    if "COUT_N" in wire_name:
        assert grid[wire_coord].startswith("CLB")
        return "SPECIAL" # "START"
    if "CIN" in wire_name:
        assert grid[wire_coord].startswith("CLB")
        return "SPECIAL" # "END"

    if "CLB" in wire_name:
        assert grid[wire_coord].startswith("CLB")
        return "SPECIAL" # "START"
    if "CLB" in leaves_via[0][-1]:
        assert grid[wire_coord].startswith("INT")
        return "SPECIAL" # "END"

    if wire_name.startswith("LV") or wire_name.startswith("LH"):
        return "LONGEND"

    print("Unknown wire on %s (%s): %s %s" % (wire_coord, grid[wire_coord], wire_name, leaves_via))
    return "PASS"


# Build a neighbour look up table
for y in range(grid_min[1], grid_max[1]+1):
    for x in range(grid_min[0], grid_max[0]+1):
        coord = (x, y)
        wires_start_map[coord] = set()

        tile_type = grid[coord]

        print()
        print("Tile %s is %s" % (coord, tile_type))

        if tile_type == "NULL":
            print("Skipping %s as NULL tile" % (coord,))
            continue

        neighbours = {}
        for dir in CompassDir.straight:
            neigh_coord = coord + dir
            print(coord, dir, neigh_coord, end=" ")
            if neigh_coord[0] < grid_min[0] or neigh_coord[1] < grid_min[1] or neigh_coord[0] > grid_max[0] or neigh_coord[1] > grid_max[1]:
                print("Skipping %s (%s) as outside grid" % (dir, neigh_coord))
                continue

            neigh_type = grid[neigh_coord]
            if neigh_type == "NULL":
                print("Skipping %s (%s) as NULL tile"  % (dir, neigh_coord))
                continue

            if neigh_type in no_conns_compass[tile_type][dir]:
                print("Skipping %s (%s) as %s tile has no connections to %s" % (
                    dir, neigh_coord, neigh_type, tile_type))
                continue

            print()
            neighbours[dir] = grid[neigh_coord]

        print("Tile: %10s (%20s) has connected neighbours: %s" % (coord, tile_type, neighbours))

        tile_compass = compass[tile_type]
        wires = set()
        wires_compass = {}
        for dir, neigh_type in neighbours.items():
            for wa, wb in tile_compass[(dir, neigh_type)]:
                if annoying_wires.search(wa):
                    continue
                if annoying_wires.search(wb):
                    continue

                wires.add(wa)
                if wa not in wires_compass:
                    wires_compass[wa] = []
                wires_compass[wa].append((dir, wb))

        wires_compass_map[coord] = wires_compass

        wires_start = set()
        wires_end = set()
        wires_pass = set()
        for wa, leaves_via in wires_compass.items():
            wire_type = find_wire_type(wa, coord, leaves_via)
            if wire_type == "START":
                wires_start.add(wa)
            elif wire_type == "LONGEND":
                wires_start.add(wa)
                wires_end.add(wa)
            elif wire_type == "END":
                wires_end.add(wa)
            elif wire_type in ("PASS", "LEAVES", "SPECIAL", "CLOCK", "LOGIC"):
                wires_pass.add(wa)
            else:
                assert False, "Unknown type: %s (%s %s)" % (wire_type, wa, leaves_via)

        wires_start_map[coord] = wires_start
        print("""\
Tile: %10s (%20s) has wires (%i total), %i passing thru and
    %s starting - [%s]
    %s ending   - [%s]
    %s passing  - [%s]""" % (
                coord, tile_type, len(wires), len(wires_pass),
                len(wires_start), " ".join(sorted(wires_start)),
                len(wires_end),   " ".join(sorted(wires_end)),
                len(wires_pass),  " ".join(sorted(wires_pass)),
            )
        )

        """
        wires_start_groups = []
        for w in wires_start.keys():
            wires_start_groups.append((w, tuple(wires_start[w])))
        wires_start_groups = tuple(sorted(wires_start_groups))

        if wires_start_groups not in starting_groups:
            starting_groups[wires_start_groups] = {}
        if tile_type not in starting_groups[wires_start_groups]:
            starting_groups[wires_start_groups][tile_type] = []
        starting_groups[wires_start_groups][tile_type].append(coord)

        #assert len(wires) == len(wires_start)+len(wires_end)+len(wires_pass)
        """

START_STR = '(  START   )'
END_STR   = '(   END    )'
LEAVE_STR = '(  LEAVES  )'

def assert_startname(wire_name):
    assert "BEG" in wire_name or wire_name.startswith("LH") or wire_name.startswith("LV"), wire_name

def assert_endname(wire_name):
    assert "END" in wire_name or wire_name.startswith("LH") or wire_name.startswith("LV"), wire_name

def trace_wire(wire_name, coord):
    assert_startname(wire_name)

    trace = [('', '', '', "[ ]", START_STR, wire_name, coord)]

    while True:
        left_coord, left_name, left_via, _, enters_via, enters_name, enters_coord = trace[-1]

        print()
        print(enters_via, enters_name, enters_coord)

        possible_leaving_dirs = list(wires_compass_map[enters_coord][enters_name])
        print("possible_leaving_dirs", possible_leaving_dirs, (enters_via, left_name))

        enters_type = find_wire_type(enters_name, enters_coord, possible_leaving_dirs)
        if enters_type == "START" or (enters_type == "LONGEND" and enters_via == START_STR):
            assert_startname(enters_name)
            assert len(possible_leaving_dirs) == 1, possible_leaving_dirs
            assert enters_via == START_STR, (enters_via, trace[-1])
        elif enters_type == "END" or (enters_type == "LONGEND" and enters_via != START_STR):
            assert_endname(enters_name)
            assert len(possible_leaving_dirs) == 1, possible_leaving_dirs
            trace.append((enters_coord, enters_name, END_STR, "[ ]", '', '', ''))
            break
        elif enters_type == "LEAVES":
            assert len(possible_leaving_dirs) == 1, possible_leaving_dirs
            trace.append((enters_coord, enters_name, LEAVE_STR, "[ ]", '', '', ''))
            break
        elif enters_type == "PASS":
            assert len(possible_leaving_dirs) == 2, possible_leaving_dirs
        else:
            assert False, "Unknown wire type: %s (%s %s %s)" % (
                    enters_type, enters_name, enters_coord, possible_leaving_dirs)

        actual_leaving_via = [i for i in possible_leaving_dirs if i != (enters_via, left_name)]
        print("   actual_leaving_via", actual_leaving_via)
        assert len(actual_leaving_via) == 1, (possible_leaving_dirs, enters_via, actual_leaving_via)

        new_left_coord = enters_coord
        new_left_name = enters_name
        new_left_via = actual_leaving_via[0][0]
        new_enters_via = new_left_via.flip()
        new_enters_name = actual_leaving_via[0][-1]
        new_enters_coord = new_left_coord + new_left_via

        assert new_enters_name in wires_compass_map[new_enters_coord], (new_enters_name, wires_compass_map[new_enters_coord])

        print(new_enters_via, new_enters_name, new_enters_coord)
        trace.append((new_left_coord, new_left_name, new_left_via, "-->", new_enters_via, new_enters_name, new_enters_coord))

    return trace

routing_nodes = open("routing.txt", "w")

for y in range(grid_min[1], grid_max[1]+1):
    for x in range(grid_min[0], grid_max[0]+1):
        coord = (x, y)

        print("================================")
        if not wires_start_map[coord]:
            print("No routing nodes starting in %s (%s)" % (coord, grid[coord]))
            routing_nodes.write("No routing nodes starting in %s (%s)\n" % (coord, grid[coord]))
            routing_nodes.write("-"*75)
            routing_nodes.write("\n")
        for w in sorted(wires_start_map[coord]):
            print("Starting to trace %s from %s" % (w, coord))
            try:
                t = trace_wire(w, coord)
            except AssertionError as e:
                print("ERROR:", "Issue tracing %s from %s" % (w, coord), str(e))
                continue
            print()
            print("SUCCESS!")
            print("-"*75)

            s = ["Trace for %s from %s (%s)\n" % (w, coord, grid[coord])]
            for a in t:
                # (31, 2), 'EL1BEG1', <CompassDir.EE: 'East'>, '-->', <CompassDir.WW: 'West'>, 'EL1END1', (32, 2)
                # (32, 2), 'EL1END1', None, '[ ]', None, None, None
                start = ''
                end   = ''
                if a[0]:
                    start = grid[a[0]]
                if a[-1]:
                    end = grid[a[-1]]
                s.append("%15s" % start)
                s.append("%8s %30s %15s %s %-15s %-30s %-8s" % a)
                s.append("%-15s\n" % end)

            s.append("-"*75)
            s.append("\n")
            s = "".join(s)
            print(s)
            routing_nodes.write(s)


#print()
#for s in starting_groups:
#    print(s)
#    for i in starting_groups[s]:
#        print(i, end=" ")
#        print(sorted(starting_groups[s][i]))
#    print()
#
#for y in range(grid_min[1], grid_max[1]+1):
#    for x in range(grid_min[0], grid_max[0]+1):
#        pass
#for wire_end in tiles_wires:
#
#    current_wire = wire_end
#    while "end" not in current_wire:
#
