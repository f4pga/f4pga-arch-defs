#!/usr/bin/env python3

import re
import json
import pprint

from enum import Enum
from collections import namedtuple

import argparse


parser = argparse.ArgumentParser()
parser.add_argument(
        '--start_x', type=int, default=0,
        help='starting x position')
parser.add_argument(
        '--start_y', type=int, default=0,
        help='starting x position')
parser.add_argument(
        '--end_x', type=int, default=2**32,
        help='starting x position')
parser.add_argument(
        '--end_y', type=int, default=2**32,
        help='starting x position')

args = parser.parse_args()


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

class WireDecoder:
    SHORT_REGEX = re.compile("(..)([0-9])(BEG|END)([0-9])")
    LONG_REGEX = re.compile("L(H|V)([0-9]*)")

    LONG_DIRS = {
        'H': 'Horizontal',
        'V': 'Vertical',
    }


wires = []
for y in range(grid_min[1], grid_max[1]+1):

    if y < args.start_y or y > args.end_y:
        continue

    for x in range(grid_min[0], grid_max[0]+1):

        if x < args.start_x or x > args.end_x:
            continue

        coord = (x, y)

        print("================================")
        if not wires_start_map[coord]:
            print("No routing nodes starting in %s (%s)" % (coord, grid[coord]))
            routing_nodes.write("No routing nodes starting in %s (%s)\n" % (coord, grid[coord]))
            routing_nodes.write("-"*75)
            routing_nodes.write("\n")
            continue

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
            route = []
            for a in t:
                route.append((a[-1], a[-2]))
                # (31, 2), 'EL1BEG1', <CompassDir.EE: 'East'>, '-->', <CompassDir.WW: 'West'>, 'EL1END1', (32, 2)
                # (32, 2), 'EL1END1', None, '[ ]', None, None, None
                start = ''
                end   = ''
                if a[0]:
                    start = grid[a[0]]
                if a[-1]:
                    end_pos = a[-1]
                    if (end_pos[1] < args.start_y or end_pos[1] > args.end_y) or (end_pos[0] < args.start_x or end_pos[0] > args.end_x):
                        # (32, 2), 'EL1END1', None, '[ ]', None, None, None
                        a = (a[0], a[1], LEAVE_STR, '[ ]', '', '', a[-1])
                    end = grid[a[-1]]

                s.append("%15s" % start)
                s.append("%8s %30s %15s %s %-15s %-30s %-8s" % a)
                s.append("%-15s\n" % end)

                if a[2] == LEAVE_STR:
                    route = None
                    break

                elif a[2] == END_STR:
                    wires.append(route[:-1])
                    break


            s.append("-"*75)
            s.append("\n")
            s = "".join(s)
            print(s)
            routing_nodes.write(s)


pprint.pprint(wires)


"""
class Blah:
    def __init__(self, x_size, y_size):

        for x in range(0, x_size):
            for y in range(0, y_size):

"""


"""

	<block_types>
		<block_type id="0" name="EMPTY" width="1" height="1">
		</block_type>
		<block_type id="1" name="BLK_BB-VPR_PAD" width="1" height="1">
			<pin_class type="INPUT">0 <!-- BLK_BB-VPR_PAD.outpad[0]--></pin_class>
			<pin_class type="OUTPUT">1 <!-- BLK_BB-VPR_PAD.inpad[0]--></pin_class>
		</block_type>
		<block_type id="2" name="BLK_MB-CLBLL_L-INT_L" width="1" height="1">
			<pin_class type="INPUT">0 <!-- BLK_MB-CLBLL_L-INT_L.EE2END[0]--></pin_class>
			<pin_class type="INPUT">1 <!-- BLK_MB-CLBLL_L-INT_L.EE2END[1]--></pin_class>
			<pin_class type="INPUT">2 <!-- BLK_MB-CLBLL_L-INT_L.EE2END[2]--></pin_class>
			<pin_class type="INPUT">3 <!-- BLK_MB-CLBLL_L-INT_L.EE2END[3]--></pin_class>
			<pin_class type="INPUT">4 <!-- BLK_MB-CLBLL_L-INT_L.EE4END[0]--></pin_class>
			<pin_class type="INPUT">5 <!-- BLK_MB-CLBLL_L-INT_L.EE4END[1]--></pin_class>
			<pin_class type="INPUT">6 <!-- BLK_MB-CLBLL_L-INT_L.EE4END[2]--></pin_class>
			<pin_class type="INPUT">7 <!-- BLK_MB-CLBLL_L-INT_L.EE4END[3]--></pin_class>
			<pin_class type="INPUT">8 <!-- BLK_MB-CLBLL_L-INT_L.EL1END[0]--></pin_class>
			<pin_class type="INPUT">9 <!-- BLK_MB-CLBLL_L-INT_L.EL1END[1]--></pin_class>
			<pin_class type="INPUT">10 <!-- BLK_MB-CLBLL_L-INT_L.EL1END[2]--></pin_class>
			<pin_class type="INPUT">11 <!-- BLK_MB-CLBLL_L-INT_L.EL1END[3]--></pin_class>
			<pin_class type="INPUT">12 <!-- BLK_MB-CLBLL_L-INT_L.ER1END[0]--></pin_class>
			<pin_class type="INPUT">13 <!-- BLK_MB-CLBLL_L-INT_L.ER1END[1]--></pin_class>
			<pin_class type="INPUT">14 <!-- BLK_MB-CLBLL_L-INT_L.ER1END[2]--></pin_class>
			<pin_class type="INPUT">15 <!-- BLK_MB-CLBLL_L-INT_L.ER1END[3]--></pin_class>
			<pin_class type="INPUT">16 <!-- BLK_MB-CLBLL_L-INT_L.NE2END[0]--></pin_class>
			<pin_class type="INPUT">17 <!-- BLK_MB-CLBLL_L-INT_L.NE2END[1]--></pin_class>
			<pin_class type="INPUT">18 <!-- BLK_MB-CLBLL_L-INT_L.NE2END[2]--></pin_class>
			<pin_class type="INPUT">19 <!-- BLK_MB-CLBLL_L-INT_L.NE2END[3]--></pin_class>
			<pin_class type="INPUT">20 <!-- BLK_MB-CLBLL_L-INT_L.NE6END[0]--></pin_class>
			<pin_class type="INPUT">21 <!-- BLK_MB-CLBLL_L-INT_L.NE6END[1]--></pin_class>
			<pin_class type="INPUT">22 <!-- BLK_MB-CLBLL_L-INT_L.NE6END[2]--></pin_class>
			<pin_class type="INPUT">23 <!-- BLK_MB-CLBLL_L-INT_L.NE6END[3]--></pin_class>
			<pin_class type="INPUT">24 <!-- BLK_MB-CLBLL_L-INT_L.NL1END[0]--></pin_class>
			<pin_class type="INPUT">25 <!-- BLK_MB-CLBLL_L-INT_L.NL1END[1]--></pin_class>
			<pin_class type="INPUT">26 <!-- BLK_MB-CLBLL_L-INT_L.NL1END[2]--></pin_class>
			<pin_class type="INPUT">27 <!-- BLK_MB-CLBLL_L-INT_L.NN2END[0]--></pin_class>
			<pin_class type="INPUT">28 <!-- BLK_MB-CLBLL_L-INT_L.NN2END[1]--></pin_class>
			<pin_class type="INPUT">29 <!-- BLK_MB-CLBLL_L-INT_L.NN2END[2]--></pin_class>
			<pin_class type="INPUT">30 <!-- BLK_MB-CLBLL_L-INT_L.NN2END[3]--></pin_class>
			<pin_class type="INPUT">31 <!-- BLK_MB-CLBLL_L-INT_L.NN6END[0]--></pin_class>
			<pin_class type="INPUT">32 <!-- BLK_MB-CLBLL_L-INT_L.NN6END[1]--></pin_class>
			<pin_class type="INPUT">33 <!-- BLK_MB-CLBLL_L-INT_L.NN6END[2]--></pin_class>
			<pin_class type="INPUT">34 <!-- BLK_MB-CLBLL_L-INT_L.NN6END[3]--></pin_class>
			<pin_class type="INPUT">35 <!-- BLK_MB-CLBLL_L-INT_L.NR1END[0]--></pin_class>
			<pin_class type="INPUT">36 <!-- BLK_MB-CLBLL_L-INT_L.NR1END[1]--></pin_class>
			<pin_class type="INPUT">37 <!-- BLK_MB-CLBLL_L-INT_L.NR1END[2]--></pin_class>
			<pin_class type="INPUT">38 <!-- BLK_MB-CLBLL_L-INT_L.NR1END[3]--></pin_class>
			<pin_class type="INPUT">39 <!-- BLK_MB-CLBLL_L-INT_L.NW2END[0]--></pin_class>
			<pin_class type="INPUT">40 <!-- BLK_MB-CLBLL_L-INT_L.NW2END[1]--></pin_class>
			<pin_class type="INPUT">41 <!-- BLK_MB-CLBLL_L-INT_L.NW2END[2]--></pin_class>
			<pin_class type="INPUT">42 <!-- BLK_MB-CLBLL_L-INT_L.NW2END[3]--></pin_class>
			<pin_class type="INPUT">43 <!-- BLK_MB-CLBLL_L-INT_L.NW6END[0]--></pin_class>
			<pin_class type="INPUT">44 <!-- BLK_MB-CLBLL_L-INT_L.NW6END[1]--></pin_class>
			<pin_class type="INPUT">45 <!-- BLK_MB-CLBLL_L-INT_L.NW6END[2]--></pin_class>
			<pin_class type="INPUT">46 <!-- BLK_MB-CLBLL_L-INT_L.NW6END[3]--></pin_class>
			<pin_class type="INPUT">47 <!-- BLK_MB-CLBLL_L-INT_L.SE2END[0]--></pin_class>
			<pin_class type="INPUT">48 <!-- BLK_MB-CLBLL_L-INT_L.SE2END[1]--></pin_class>
			<pin_class type="INPUT">49 <!-- BLK_MB-CLBLL_L-INT_L.SE2END[2]--></pin_class>
			<pin_class type="INPUT">50 <!-- BLK_MB-CLBLL_L-INT_L.SE2END[3]--></pin_class>
			<pin_class type="INPUT">51 <!-- BLK_MB-CLBLL_L-INT_L.SE6END[0]--></pin_class>
			<pin_class type="INPUT">52 <!-- BLK_MB-CLBLL_L-INT_L.SE6END[1]--></pin_class>
			<pin_class type="INPUT">53 <!-- BLK_MB-CLBLL_L-INT_L.SE6END[2]--></pin_class>
			<pin_class type="INPUT">54 <!-- BLK_MB-CLBLL_L-INT_L.SE6END[3]--></pin_class>
			<pin_class type="INPUT">55 <!-- BLK_MB-CLBLL_L-INT_L.SL1END[0]--></pin_class>
			<pin_class type="INPUT">56 <!-- BLK_MB-CLBLL_L-INT_L.SL1END[1]--></pin_class>
			<pin_class type="INPUT">57 <!-- BLK_MB-CLBLL_L-INT_L.SL1END[2]--></pin_class>
			<pin_class type="INPUT">58 <!-- BLK_MB-CLBLL_L-INT_L.SL1END[3]--></pin_class>
			<pin_class type="INPUT">59 <!-- BLK_MB-CLBLL_L-INT_L.SR1END[0]--></pin_class>
			<pin_class type="INPUT">60 <!-- BLK_MB-CLBLL_L-INT_L.SR1END[1]--></pin_class>
			<pin_class type="INPUT">61 <!-- BLK_MB-CLBLL_L-INT_L.SR1END[2]--></pin_class>
			<pin_class type="INPUT">62 <!-- BLK_MB-CLBLL_L-INT_L.SR1END[3]--></pin_class>
			<pin_class type="INPUT">63 <!-- BLK_MB-CLBLL_L-INT_L.SS2END[0]--></pin_class>
			<pin_class type="INPUT">64 <!-- BLK_MB-CLBLL_L-INT_L.SS2END[1]--></pin_class>
			<pin_class type="INPUT">65 <!-- BLK_MB-CLBLL_L-INT_L.SS2END[2]--></pin_class>
			<pin_class type="INPUT">66 <!-- BLK_MB-CLBLL_L-INT_L.SS2END[3]--></pin_class>
			<pin_class type="INPUT">67 <!-- BLK_MB-CLBLL_L-INT_L.SS6END[0]--></pin_class>
			<pin_class type="INPUT">68 <!-- BLK_MB-CLBLL_L-INT_L.SS6END[1]--></pin_class>
			<pin_class type="INPUT">69 <!-- BLK_MB-CLBLL_L-INT_L.SS6END[2]--></pin_class>
			<pin_class type="INPUT">70 <!-- BLK_MB-CLBLL_L-INT_L.SS6END[3]--></pin_class>
			<pin_class type="INPUT">71 <!-- BLK_MB-CLBLL_L-INT_L.SW2END[0]--></pin_class>
			<pin_class type="INPUT">72 <!-- BLK_MB-CLBLL_L-INT_L.SW2END[1]--></pin_class>
			<pin_class type="INPUT">73 <!-- BLK_MB-CLBLL_L-INT_L.SW2END[2]--></pin_class>
			<pin_class type="INPUT">74 <!-- BLK_MB-CLBLL_L-INT_L.SW2END[3]--></pin_class>
			<pin_class type="INPUT">75 <!-- BLK_MB-CLBLL_L-INT_L.SW6END[0]--></pin_class>
			<pin_class type="INPUT">76 <!-- BLK_MB-CLBLL_L-INT_L.SW6END[1]--></pin_class>
			<pin_class type="INPUT">77 <!-- BLK_MB-CLBLL_L-INT_L.SW6END[2]--></pin_class>
			<pin_class type="INPUT">78 <!-- BLK_MB-CLBLL_L-INT_L.SW6END[3]--></pin_class>
			<pin_class type="INPUT">79 <!-- BLK_MB-CLBLL_L-INT_L.WL1END[0]--></pin_class>
			<pin_class type="INPUT">80 <!-- BLK_MB-CLBLL_L-INT_L.WL1END[1]--></pin_class>
			<pin_class type="INPUT">81 <!-- BLK_MB-CLBLL_L-INT_L.WL1END[2]--></pin_class>
			<pin_class type="INPUT">82 <!-- BLK_MB-CLBLL_L-INT_L.WL1END[3]--></pin_class>
			<pin_class type="INPUT">83 <!-- BLK_MB-CLBLL_L-INT_L.WR1END[0]--></pin_class>
			<pin_class type="INPUT">84 <!-- BLK_MB-CLBLL_L-INT_L.WR1END[1]--></pin_class>
			<pin_class type="INPUT">85 <!-- BLK_MB-CLBLL_L-INT_L.WR1END[2]--></pin_class>
			<pin_class type="INPUT">86 <!-- BLK_MB-CLBLL_L-INT_L.WR1END[3]--></pin_class>
			<pin_class type="INPUT">87 <!-- BLK_MB-CLBLL_L-INT_L.WW2END[0]--></pin_class>
			<pin_class type="INPUT">88 <!-- BLK_MB-CLBLL_L-INT_L.WW2END[1]--></pin_class>
			<pin_class type="INPUT">89 <!-- BLK_MB-CLBLL_L-INT_L.WW2END[2]--></pin_class>
			<pin_class type="INPUT">90 <!-- BLK_MB-CLBLL_L-INT_L.WW2END[3]--></pin_class>
			<pin_class type="INPUT">91 <!-- BLK_MB-CLBLL_L-INT_L.WW4END[0]--></pin_class>
			<pin_class type="INPUT">92 <!-- BLK_MB-CLBLL_L-INT_L.WW4END[1]--></pin_class>
			<pin_class type="INPUT">93 <!-- BLK_MB-CLBLL_L-INT_L.WW4END[2]--></pin_class>
			<pin_class type="INPUT">94 <!-- BLK_MB-CLBLL_L-INT_L.WW4END[3]--></pin_class>
			<pin_class type="INPUT">95 <!-- BLK_MB-CLBLL_L-INT_L.CIN_N[0]--></pin_class>
			<pin_class type="INPUT">96 <!-- BLK_MB-CLBLL_L-INT_L.CIN_N[1]--></pin_class>
			<pin_class type="OUTPUT">97 <!-- BLK_MB-CLBLL_L-INT_L.EE2BEG[0]--></pin_class>
			<pin_class type="OUTPUT">98 <!-- BLK_MB-CLBLL_L-INT_L.EE2BEG[1]--></pin_class>
			<pin_class type="OUTPUT">99 <!-- BLK_MB-CLBLL_L-INT_L.EE2BEG[2]--></pin_class>
			<pin_class type="OUTPUT">100 <!-- BLK_MB-CLBLL_L-INT_L.EE2BEG[3]--></pin_class>
			<pin_class type="OUTPUT">101 <!-- BLK_MB-CLBLL_L-INT_L.EE4BEG[0]--></pin_class>
			<pin_class type="OUTPUT">102 <!-- BLK_MB-CLBLL_L-INT_L.EE4BEG[1]--></pin_class>
			<pin_class type="OUTPUT">103 <!-- BLK_MB-CLBLL_L-INT_L.EE4BEG[2]--></pin_class>
			<pin_class type="OUTPUT">104 <!-- BLK_MB-CLBLL_L-INT_L.EE4BEG[3]--></pin_class>
			<pin_class type="OUTPUT">105 <!-- BLK_MB-CLBLL_L-INT_L.EL1BEG[0]--></pin_class>
			<pin_class type="OUTPUT">106 <!-- BLK_MB-CLBLL_L-INT_L.EL1BEG[1]--></pin_class>
			<pin_class type="OUTPUT">107 <!-- BLK_MB-CLBLL_L-INT_L.EL1BEG[2]--></pin_class>
			<pin_class type="OUTPUT">108 <!-- BLK_MB-CLBLL_L-INT_L.ER1BEG[0]--></pin_class>
			<pin_class type="OUTPUT">109 <!-- BLK_MB-CLBLL_L-INT_L.ER1BEG[1]--></pin_class>
			<pin_class type="OUTPUT">110 <!-- BLK_MB-CLBLL_L-INT_L.ER1BEG[2]--></pin_class>
			<pin_class type="OUTPUT">111 <!-- BLK_MB-CLBLL_L-INT_L.ER1BEG[3]--></pin_class>
			<pin_class type="OUTPUT">112 <!-- BLK_MB-CLBLL_L-INT_L.NE2BEG[0]--></pin_class>
			<pin_class type="OUTPUT">113 <!-- BLK_MB-CLBLL_L-INT_L.NE2BEG[1]--></pin_class>
			<pin_class type="OUTPUT">114 <!-- BLK_MB-CLBLL_L-INT_L.NE2BEG[2]--></pin_class>
			<pin_class type="OUTPUT">115 <!-- BLK_MB-CLBLL_L-INT_L.NE2BEG[3]--></pin_class>
			<pin_class type="OUTPUT">116 <!-- BLK_MB-CLBLL_L-INT_L.NE6BEG[0]--></pin_class>
			<pin_class type="OUTPUT">117 <!-- BLK_MB-CLBLL_L-INT_L.NE6BEG[1]--></pin_class>
			<pin_class type="OUTPUT">118 <!-- BLK_MB-CLBLL_L-INT_L.NE6BEG[2]--></pin_class>
			<pin_class type="OUTPUT">119 <!-- BLK_MB-CLBLL_L-INT_L.NE6BEG[3]--></pin_class>
			<pin_class type="OUTPUT">120 <!-- BLK_MB-CLBLL_L-INT_L.NL1BEG[0]--></pin_class>
			<pin_class type="OUTPUT">121 <!-- BLK_MB-CLBLL_L-INT_L.NL1BEG[1]--></pin_class>
			<pin_class type="OUTPUT">122 <!-- BLK_MB-CLBLL_L-INT_L.NL1BEG[2]--></pin_class>
			<pin_class type="OUTPUT">123 <!-- BLK_MB-CLBLL_L-INT_L.NN2BEG[0]--></pin_class>
			<pin_class type="OUTPUT">124 <!-- BLK_MB-CLBLL_L-INT_L.NN2BEG[1]--></pin_class>
			<pin_class type="OUTPUT">125 <!-- BLK_MB-CLBLL_L-INT_L.NN2BEG[2]--></pin_class>
			<pin_class type="OUTPUT">126 <!-- BLK_MB-CLBLL_L-INT_L.NN2BEG[3]--></pin_class>
			<pin_class type="OUTPUT">127 <!-- BLK_MB-CLBLL_L-INT_L.NN6BEG[0]--></pin_class>
			<pin_class type="OUTPUT">128 <!-- BLK_MB-CLBLL_L-INT_L.NN6BEG[1]--></pin_class>
			<pin_class type="OUTPUT">129 <!-- BLK_MB-CLBLL_L-INT_L.NN6BEG[2]--></pin_class>
			<pin_class type="OUTPUT">130 <!-- BLK_MB-CLBLL_L-INT_L.NN6BEG[3]--></pin_class>
			<pin_class type="OUTPUT">131 <!-- BLK_MB-CLBLL_L-INT_L.NR1BEG[0]--></pin_class>
			<pin_class type="OUTPUT">132 <!-- BLK_MB-CLBLL_L-INT_L.NR1BEG[1]--></pin_class>
			<pin_class type="OUTPUT">133 <!-- BLK_MB-CLBLL_L-INT_L.NR1BEG[2]--></pin_class>
			<pin_class type="OUTPUT">134 <!-- BLK_MB-CLBLL_L-INT_L.NR1BEG[3]--></pin_class>
			<pin_class type="OUTPUT">135 <!-- BLK_MB-CLBLL_L-INT_L.NW2BEG[0]--></pin_class>
			<pin_class type="OUTPUT">136 <!-- BLK_MB-CLBLL_L-INT_L.NW2BEG[1]--></pin_class>
			<pin_class type="OUTPUT">137 <!-- BLK_MB-CLBLL_L-INT_L.NW2BEG[2]--></pin_class>
			<pin_class type="OUTPUT">138 <!-- BLK_MB-CLBLL_L-INT_L.NW2BEG[3]--></pin_class>
			<pin_class type="OUTPUT">139 <!-- BLK_MB-CLBLL_L-INT_L.NW6BEG[0]--></pin_class>
			<pin_class type="OUTPUT">140 <!-- BLK_MB-CLBLL_L-INT_L.NW6BEG[1]--></pin_class>
			<pin_class type="OUTPUT">141 <!-- BLK_MB-CLBLL_L-INT_L.NW6BEG[2]--></pin_class>
			<pin_class type="OUTPUT">142 <!-- BLK_MB-CLBLL_L-INT_L.NW6BEG[3]--></pin_class>
			<pin_class type="OUTPUT">143 <!-- BLK_MB-CLBLL_L-INT_L.SE2BEG[0]--></pin_class>
			<pin_class type="OUTPUT">144 <!-- BLK_MB-CLBLL_L-INT_L.SE2BEG[1]--></pin_class>
			<pin_class type="OUTPUT">145 <!-- BLK_MB-CLBLL_L-INT_L.SE2BEG[2]--></pin_class>
			<pin_class type="OUTPUT">146 <!-- BLK_MB-CLBLL_L-INT_L.SE2BEG[3]--></pin_class>
			<pin_class type="OUTPUT">147 <!-- BLK_MB-CLBLL_L-INT_L.SE6BEG[0]--></pin_class>
			<pin_class type="OUTPUT">148 <!-- BLK_MB-CLBLL_L-INT_L.SE6BEG[1]--></pin_class>
			<pin_class type="OUTPUT">149 <!-- BLK_MB-CLBLL_L-INT_L.SE6BEG[2]--></pin_class>
			<pin_class type="OUTPUT">150 <!-- BLK_MB-CLBLL_L-INT_L.SE6BEG[3]--></pin_class>
			<pin_class type="OUTPUT">151 <!-- BLK_MB-CLBLL_L-INT_L.SL1BEG[0]--></pin_class>
			<pin_class type="OUTPUT">152 <!-- BLK_MB-CLBLL_L-INT_L.SL1BEG[1]--></pin_class>
			<pin_class type="OUTPUT">153 <!-- BLK_MB-CLBLL_L-INT_L.SL1BEG[2]--></pin_class>
			<pin_class type="OUTPUT">154 <!-- BLK_MB-CLBLL_L-INT_L.SL1BEG[3]--></pin_class>
			<pin_class type="OUTPUT">155 <!-- BLK_MB-CLBLL_L-INT_L.SR1BEG[0]--></pin_class>
			<pin_class type="OUTPUT">156 <!-- BLK_MB-CLBLL_L-INT_L.SR1BEG[1]--></pin_class>
			<pin_class type="OUTPUT">157 <!-- BLK_MB-CLBLL_L-INT_L.SR1BEG[2]--></pin_class>
			<pin_class type="OUTPUT">158 <!-- BLK_MB-CLBLL_L-INT_L.SR1BEG[3]--></pin_class>
			<pin_class type="OUTPUT">159 <!-- BLK_MB-CLBLL_L-INT_L.SS2BEG[0]--></pin_class>
			<pin_class type="OUTPUT">160 <!-- BLK_MB-CLBLL_L-INT_L.SS2BEG[1]--></pin_class>
			<pin_class type="OUTPUT">161 <!-- BLK_MB-CLBLL_L-INT_L.SS2BEG[2]--></pin_class>
			<pin_class type="OUTPUT">162 <!-- BLK_MB-CLBLL_L-INT_L.SS2BEG[3]--></pin_class>
			<pin_class type="OUTPUT">163 <!-- BLK_MB-CLBLL_L-INT_L.SS6BEG[0]--></pin_class>
			<pin_class type="OUTPUT">164 <!-- BLK_MB-CLBLL_L-INT_L.SS6BEG[1]--></pin_class>
			<pin_class type="OUTPUT">165 <!-- BLK_MB-CLBLL_L-INT_L.SS6BEG[2]--></pin_class>
			<pin_class type="OUTPUT">166 <!-- BLK_MB-CLBLL_L-INT_L.SS6BEG[3]--></pin_class>
			<pin_class type="OUTPUT">167 <!-- BLK_MB-CLBLL_L-INT_L.SW2BEG[0]--></pin_class>
			<pin_class type="OUTPUT">168 <!-- BLK_MB-CLBLL_L-INT_L.SW2BEG[1]--></pin_class>
			<pin_class type="OUTPUT">169 <!-- BLK_MB-CLBLL_L-INT_L.SW2BEG[2]--></pin_class>
			<pin_class type="OUTPUT">170 <!-- BLK_MB-CLBLL_L-INT_L.SW2BEG[3]--></pin_class>
			<pin_class type="OUTPUT">171 <!-- BLK_MB-CLBLL_L-INT_L.SW6BEG[0]--></pin_class>
			<pin_class type="OUTPUT">172 <!-- BLK_MB-CLBLL_L-INT_L.SW6BEG[1]--></pin_class>
			<pin_class type="OUTPUT">173 <!-- BLK_MB-CLBLL_L-INT_L.SW6BEG[2]--></pin_class>
			<pin_class type="OUTPUT">174 <!-- BLK_MB-CLBLL_L-INT_L.SW6BEG[3]--></pin_class>
			<pin_class type="OUTPUT">175 <!-- BLK_MB-CLBLL_L-INT_L.WL1BEG[0]--></pin_class>
			<pin_class type="OUTPUT">176 <!-- BLK_MB-CLBLL_L-INT_L.WL1BEG[1]--></pin_class>
			<pin_class type="OUTPUT">177 <!-- BLK_MB-CLBLL_L-INT_L.WL1BEG[2]--></pin_class>
			<pin_class type="OUTPUT">178 <!-- BLK_MB-CLBLL_L-INT_L.WR1BEG[0]--></pin_class>
			<pin_class type="OUTPUT">179 <!-- BLK_MB-CLBLL_L-INT_L.WR1BEG[1]--></pin_class>
			<pin_class type="OUTPUT">180 <!-- BLK_MB-CLBLL_L-INT_L.WR1BEG[2]--></pin_class>
			<pin_class type="OUTPUT">181 <!-- BLK_MB-CLBLL_L-INT_L.WR1BEG[3]--></pin_class>
			<pin_class type="OUTPUT">182 <!-- BLK_MB-CLBLL_L-INT_L.WW2BEG[0]--></pin_class>
			<pin_class type="OUTPUT">183 <!-- BLK_MB-CLBLL_L-INT_L.WW2BEG[1]--></pin_class>
			<pin_class type="OUTPUT">184 <!-- BLK_MB-CLBLL_L-INT_L.WW2BEG[2]--></pin_class>
			<pin_class type="OUTPUT">185 <!-- BLK_MB-CLBLL_L-INT_L.WW2BEG[3]--></pin_class>
			<pin_class type="OUTPUT">186 <!-- BLK_MB-CLBLL_L-INT_L.WW4BEG[0]--></pin_class>
			<pin_class type="OUTPUT">187 <!-- BLK_MB-CLBLL_L-INT_L.WW4BEG[1]--></pin_class>
			<pin_class type="OUTPUT">188 <!-- BLK_MB-CLBLL_L-INT_L.WW4BEG[2]--></pin_class>
			<pin_class type="OUTPUT">189 <!-- BLK_MB-CLBLL_L-INT_L.WW4BEG[3]--></pin_class>
			<pin_class type="OUTPUT">190 <!-- BLK_MB-CLBLL_L-INT_L.COUT_N[0]--></pin_class>
			<pin_class type="OUTPUT">191 <!-- BLK_MB-CLBLL_L-INT_L.COUT_N[1]--></pin_class>
			<pin_class type="INPUT">192 <!-- BLK_MB-CLBLL_L-INT_L.GCLK_L_B[0]--></pin_class>
			<pin_class type="INPUT">193 <!-- BLK_MB-CLBLL_L-INT_L.GCLK_L_B[1]--></pin_class>
			<pin_class type="INPUT">194 <!-- BLK_MB-CLBLL_L-INT_L.GCLK_L_B[2]--></pin_class>
			<pin_class type="INPUT">195 <!-- BLK_MB-CLBLL_L-INT_L.GCLK_L_B[3]--></pin_class>
			<pin_class type="INPUT">196 <!-- BLK_MB-CLBLL_L-INT_L.GCLK_L_B[4]--></pin_class>
			<pin_class type="INPUT">197 <!-- BLK_MB-CLBLL_L-INT_L.GCLK_L_B[5]--></pin_class>
			<pin_class type="INPUT">198 <!-- BLK_MB-CLBLL_L-INT_L.GCLK_L_B[6]--></pin_class>
			<pin_class type="INPUT">199 <!-- BLK_MB-CLBLL_L-INT_L.GCLK_L_B[7]--></pin_class>
			<pin_class type="INPUT">200 <!-- BLK_MB-CLBLL_L-INT_L.GCLK_L_B[8]--></pin_class>
			<pin_class type="INPUT">201 <!-- BLK_MB-CLBLL_L-INT_L.GCLK_L_B[9]--></pin_class>
			<pin_class type="INPUT">202 <!-- BLK_MB-CLBLL_L-INT_L.GCLK_L_B[10]--></pin_class>
			<pin_class type="INPUT">203 <!-- BLK_MB-CLBLL_L-INT_L.GCLK_L_B[11]--></pin_class>
			<pin_class type="INPUT">204 <!-- BLK_MB-CLBLL_L-INT_L.GFAN[0]--></pin_class>
			<pin_class type="INPUT">205 <!-- BLK_MB-CLBLL_L-INT_L.GFAN[1]--></pin_class>
			<pin_class type="INPUT">206 <!-- BLK_MB-CLBLL_L-INT_L.CLK_L[0]--></pin_class>
			<pin_class type="INPUT">207 <!-- BLK_MB-CLBLL_L-INT_L.CLK_L[1]--></pin_class>
		</block_type>
		<block_type id="3" name="CLBLL_R" width="1" height="1">
			<pin_class type="INPUT">0 <!-- CLBLL_R.I[0]--></pin_class>
			<pin_class type="OUTPUT">1 <!-- CLBLL_R.O[0]--></pin_class>
		</block_type>
		<block_type id="4" name="CLBLM_L" width="1" height="1">
			<pin_class type="INPUT">0 <!-- CLBLM_L.I[0]--></pin_class>
			<pin_class type="OUTPUT">1 <!-- CLBLM_L.O[0]--></pin_class>
		</block_type>
		<block_type id="5" name="CLBLM_R" width="1" height="1">
			<pin_class type="INPUT">0 <!-- CLBLM_R.I[0]--></pin_class>
			<pin_class type="OUTPUT">1 <!-- CLBLM_R.O[0]--></pin_class>
		</block_type>
		<block_type id="6" name="INT_L" width="1" height="1">
			<pin_class type="INPUT">0 <!-- INT_L.I[0]--></pin_class>
			<pin_class type="OUTPUT">1 <!-- INT_L.O[0]--></pin_class>
		</block_type>
		<block_type id="7" name="INT_R" width="1" height="1">
			<pin_class type="INPUT">0 <!-- INT_R.I[0]--></pin_class>
			<pin_class type="OUTPUT">1 <!-- INT_R.O[0]--></pin_class>
		</block_type>
		<block_type id="8" name="HCLK_L" width="1" height="1">
			<pin_class type="INPUT">0 <!-- HCLK_L.I[0]--></pin_class>
			<pin_class type="OUTPUT">1 <!-- HCLK_L.O[0]--></pin_class>
		</block_type>
		<block_type id="9" name="HCLK_R" width="1" height="1">
			<pin_class type="INPUT">0 <!-- HCLK_R.I[0]--></pin_class>
			<pin_class type="OUTPUT">1 <!-- HCLK_R.O[0]--></pin_class>
		</block_type>
	</block_types>
"""

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
