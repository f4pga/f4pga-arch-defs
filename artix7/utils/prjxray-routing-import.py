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
        '--end_x', type=int, default=-1,
        help='starting x position')
parser.add_argument(
        '--end_y', type=int, default=-1,
        help='starting x position')
parser.add_argument(
        '--verbose', action='store_const', const=True, default=False)

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


if args.end_x == -1:
    args.end_x = grid_max[0]
if args.end_y == -1:
    args.end_y = grid_max[1]


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

print("\n"*4)

print(len(wires), "routing nodes found")
pprint.pprint(wires)

# Work out how wide each channel is going to be...
channel_count = {}
for w in wires:
    for p, __ in w:
        channel_count[p] = channel_count.get(p,0) + 1

pprint.pprint(channel_count)


import lxml.etree as ET
rr_graph = ET.Element(
    'rr_graph',
    dict(tool_name="icebox", tool_version="???", tool_comment="Generated for {} device".format("Artix-7")),
)

# Mapping dictionaries
globalname2node = {}
globalname2nodeid = {}


nodes = ET.SubElement(rr_graph, 'rr_nodes')
def add_node(globalname, attribs):
    """Add node with globalname and attributes."""
    # Add common attributes
    attribs['capacity'] =  str(1)

    # Work out the ID for this node and add to the mapping
    attribs['id'] = str(len(globalname2node))

    node = ET.SubElement(nodes, 'node', attribs)

    # Stash in the mappings
    assert globalname not in globalname2node
    assert globalname not in globalname2nodeid
    globalname2node[globalname] = node
    globalname2nodeid[globalname] = attribs['id']

    # Add some helpful comments
    if args.verbose:
        node.append(ET.Comment(" {} ".format(globalname)))

    return node


edges = ET.SubElement(rr_graph, 'rr_edges')
def add_edge(src_globalname, dst_globalname, bidir=False):
    src_node_id = globalname2nodeid[src_globalname]
    dst_node_id = globalname2nodeid[dst_globalname]

    attribs = {
        'src_node': str(src_node_id),
        'sink_node': str(dst_node_id),
        'switch_id': str(0),
    }
    e = ET.SubElement(edges, 'edge', attribs)

    # Add some helpful comments
    if args.verbose:
        e.append(ET.Comment(" {} -> {} ".format(src_globalname, dst_globalname)))
        globalname2node[src_globalname].append(ET.Comment(" this -> {} ".format(dst_globalname)))
        globalname2node[dst_globalname].append(ET.Comment(" {} -> this ".format(src_globalname)))


def add_pin(pos, pinname, dir, idx):
    """Add an pin at index i to tile at pos."""

    """
        <node id="0" type="SINK" capacity="1">
                <loc xlow="0" ylow="1" xhigh="0" yhigh="1" ptc="0"/>
                <timing R="0" C="0"/>
        </node>
        <node id="2" type="IPIN" capacity="1">
                <loc xlow="0" ylow="1" xhigh="0" yhigh="1" side="TOP" ptc="0"/>
                <timing R="0" C="0"/>
        </node>
    """
    gname = "(%s,%s)-%s" % (pos, pinname)
    gname_pin = "(%s,%s)-%s-pin" % (pos, pinname)

    add_globalname2localname(gname, pos, localname)

    if dir == "out":
        # Sink node
        attribs = {
            'type': 'SINK',
        }
        node = add_node(gname, attribs)
        ET.SubElement(node, 'loc', {
            'xlow': str(pos[0]), 'ylow': str(pos[1]),
            'xhigh': str(pos[0]), 'yhigh': str(pos[1]),
            'ptc': str(idx),
        })
        ET.SubElement(node, 'timing', {'R': str(0), 'C': str(0)})

        # Pin node
        attribs = {
            'type': 'IPIN',
        }
        node = add_node(gname_pin, attribs)
        ET.SubElement(node, 'loc', {
            'xlow': str(pos[0]), 'ylow': str(pos[1]),
            'xhigh': str(pos[0]), 'yhigh': str(pos[1]),
            'ptc': str(idx),
            'side': 'TOP',
        })
        ET.SubElement(node, 'timing', {'R': str(0), 'C': str(0)})

        # Edge between pin node
        add_edge(gname, gname_pin)

    elif dir == "in":
        # Source node
        attribs = {
            'type': 'SOURCE',
        }
        node = add_node(gname, attribs)
        ET.SubElement(node, 'loc', {
            'xlow': str(pos[0]), 'ylow': str(pos[1]),
            'xhigh': str(pos[0]), 'yhigh': str(pos[1]),
            'ptc': str(idx),
        })
        ET.SubElement(node, 'timing', {'R': str(0), 'C': str(0)})

        # Pin node
        attribs = {
            'type': 'OPIN',
        }
        node = add_node(gname_pin, attribs)
        ET.SubElement(node, 'loc', {
            'xlow': str(pos[0]), 'ylow': str(pos[1]),
            'xhigh': str(pos[0]), 'yhigh': str(pos[1]),
            'ptc': str(idx),
            'side': 'TOP',
        })
        ET.SubElement(node, 'timing', {'R': str(0), 'C': str(0)})

        # Edge between pin node
        add_edge(gname_pin, gname)

    else:
        assert False, "Unknown dir of {} for {}".format(dir, gname)

    print("Adding pin {} on tile {}@{}".format(gname, pos, idx))


for x in range(args.start_x, args.end_x+1):
    for y in range(args.start_y, args.end_y+1):
        tile_type = grid[(x, y)]
        print(x,y,tile_type)
        # Create the pins here...
        #add_pin(pos, pinname, dir, idx)


def gname(pos, name):
    return "GRID_X{}Y{}/{}.{}".format(pos[0], pos[1], grid[pos], name)


for w in wires:
    start = w[0]
    name, x, index = re.match("^(..[0-9]*)(.*)([0-9]+)$", start[-1]).groups()
    if name.startswith("L"):
        assert x == ""
        wire_type = "long"
    else:
        assert x == "BEG"
        wire_type = "short"

    # Name routing nodes after their starting node
    #global_name = "(%s,%s)-%s[%s]" % (start[0][0], start[0][1], name, index)
    names = []
    for pos, name in w:
        names.append(gname(pos, name))
    wire_global_name = "->>".join(names)
    print(wire_global_name)

    start_pos = w[0][0]
    end_pos = w[-1][0]

    # Y channel as X is constant
    if start_pos[0] == end_pos[0]:
        channel_start = add_channel(
            wire_global_name,
            'CHANY', start_pos, end_pos, 'WIRE')
        channel_end = channel_start

    # X channel as Y is constant
    elif start_pos[1] != end_pos[1]:
        channel_start = add_channel(
            wire_global_name,
            'CHANX', start_pos, end_pos, 'WIRE')
        channel_end = channel_start

    # Going to need two channels to make this work..
    else:
        mid_pos = (start_pos[0], end_pos[1])
        channel_start = add_channel(
            wire_global_name+"_Y",
            'CHANY', start_pos, mid_pos, 'WIRE')
        channel_end = add_channel(
            wire_global_name+"_X",
            'CHANX', mid_pos, end_pos, 'WIRE')

    add_edge(gname(start_pos, start[-1]), channel_start)
    add_edge(channel_end, gname(end_pos, w[-1][-1]))


pins = {
    'INT_L': {
        "EE2END[0]": 0,
        "EE2END[1]": 1,
        "EE2END[2]": 2,
        "EE2END[3]": 3,
        "EE4END[0]": 4,
        "EE4END[1]": 5,
        "EE4END[2]": 6,
        "EE4END[3]": 7,
        "EL1END[0]": 8,
        "EL1END[1]": 9,
        "EL1END[2]": 10,
        "EL1END[3]": 11,
        "ER1END[0]": 12,
        "ER1END[1]": 13,
        "ER1END[2]": 14,
        "ER1END[3]": 15,
        "NE2END[0]": 16,
        "NE2END[1]": 17,
        "NE2END[2]": 18,
        "NE2END[3]": 19,
        "NE6END[0]": 20,
        "NE6END[1]": 21,
        "NE6END[2]": 22,
        "NE6END[3]": 23,
        "NL1END[0]": 24,
        "NL1END[1]": 25,
        "NL1END[2]": 26,
        "NN2END[0]": 27,
        "NN2END[1]": 28,
        "NN2END[2]": 29,
        "NN2END[3]": 30,
        "NN6END[0]": 31,
        "NN6END[1]": 32,
        "NN6END[2]": 33,
        "NN6END[3]": 34,
        "NR1END[0]": 35,
        "NR1END[1]": 36,
        "NR1END[2]": 37,
        "NR1END[3]": 38,
        "NW2END[0]": 39,
        "NW2END[1]": 40,
        "NW2END[2]": 41,
        "NW2END[3]": 42,
        "NW6END[0]": 43,
        "NW6END[1]": 44,
        "NW6END[2]": 45,
        "NW6END[3]": 46,
        "SE2END[0]": 47,
        "SE2END[1]": 48,
        "SE2END[2]": 49,
        "SE2END[3]": 50,
        "SE6END[0]": 51,
        "SE6END[1]": 52,
        "SE6END[2]": 53,
        "SE6END[3]": 54,
        "SL1END[0]": 55,
        "SL1END[1]": 56,
        "SL1END[2]": 57,
        "SL1END[3]": 58,
        "SR1END[0]": 59,
        "SR1END[1]": 60,
        "SR1END[2]": 61,
        "SR1END[3]": 62,
        "SS2END[0]": 63,
        "SS2END[1]": 64,
        "SS2END[2]": 65,
        "SS2END[3]": 66,
        "SS6END[0]": 67,
        "SS6END[1]": 68,
        "SS6END[2]": 69,
        "SS6END[3]": 70,
        "SW2END[0]": 71,
        "SW2END[1]": 72,
        "SW2END[2]": 73,
        "SW2END[3]": 74,
        "SW6END[0]": 75,
        "SW6END[1]": 76,
        "SW6END[2]": 77,
        "SW6END[3]": 78,
        "WL1END[0]": 79,
        "WL1END[1]": 80,
        "WL1END[2]": 81,
        "WL1END[3]": 82,
        "WR1END[0]": 83,
        "WR1END[1]": 84,
        "WR1END[2]": 85,
        "WR1END[3]": 86,
        "WW2END[0]": 87,
        "WW2END[1]": 88,
        "WW2END[2]": 89,
        "WW2END[3]": 90,
        "WW4END[0]": 91,
        "WW4END[1]": 92,
        "WW4END[2]": 93,
        "WW4END[3]": 94,
        "CIN_N[0]": 95,
        "CIN_N[1]": 96,
        "EE2BEG[0]": 97,
        "EE2BEG[1]": 98,
        "EE2BEG[2]": 99,
        "EE2BEG[3]": 100,
        "EE4BEG[0]": 101,
        "EE4BEG[1]": 102,
        "EE4BEG[2]": 103,
        "EE4BEG[3]": 104,
        "EL1BEG[0]": 105,
        "EL1BEG[1]": 106,
        "EL1BEG[2]": 107,
        "ER1BEG[0]": 108,
        "ER1BEG[1]": 109,
        "ER1BEG[2]": 110,
        "ER1BEG[3]": 111,
        "NE2BEG[0]": 112,
        "NE2BEG[1]": 113,
        "NE2BEG[2]": 114,
        "NE2BEG[3]": 115,
        "NE6BEG[0]": 116,
        "NE6BEG[1]": 117,
        "NE6BEG[2]": 118,
        "NE6BEG[3]": 119,
        "NL1BEG[0]": 120,
        "NL1BEG[1]": 121,
        "NL1BEG[2]": 122,
        "NN2BEG[0]": 123,
        "NN2BEG[1]": 124,
        "NN2BEG[2]": 125,
        "NN2BEG[3]": 126,
        "NN6BEG[0]": 127,
        "NN6BEG[1]": 128,
        "NN6BEG[2]": 129,
        "NN6BEG[3]": 130,
        "NR1BEG[0]": 131,
        "NR1BEG[1]": 132,
        "NR1BEG[2]": 133,
        "NR1BEG[3]": 134,
        "NW2BEG[0]": 135,
        "NW2BEG[1]": 136,
        "NW2BEG[2]": 137,
        "NW2BEG[3]": 138,
        "NW6BEG[0]": 139,
        "NW6BEG[1]": 140,
        "NW6BEG[2]": 141,
        "NW6BEG[3]": 142,
        "SE2BEG[0]": 143,
        "SE2BEG[1]": 144,
        "SE2BEG[2]": 145,
        "SE2BEG[3]": 146,
        "SE6BEG[0]": 147,
        "SE6BEG[1]": 148,
        "SE6BEG[2]": 149,
        "SE6BEG[3]": 150,
        "SL1BEG[0]": 151,
        "SL1BEG[1]": 152,
        "SL1BEG[2]": 153,
        "SL1BEG[3]": 154,
        "SR1BEG[0]": 155,
        "SR1BEG[1]": 156,
        "SR1BEG[2]": 157,
        "SR1BEG[3]": 158,
        "SS2BEG[0]": 159,
        "SS2BEG[1]": 160,
        "SS2BEG[2]": 161,
        "SS2BEG[3]": 162,
        "SS6BEG[0]": 163,
        "SS6BEG[1]": 164,
        "SS6BEG[2]": 165,
        "SS6BEG[3]": 166,
        "SW2BEG[0]": 167,
        "SW2BEG[1]": 168,
        "SW2BEG[2]": 169,
        "SW2BEG[3]": 170,
        "SW6BEG[0]": 171,
        "SW6BEG[1]": 172,
        "SW6BEG[2]": 173,
        "SW6BEG[3]": 174,
        "WL1BEG[0]": 175,
        "WL1BEG[1]": 176,
        "WL1BEG[2]": 177,
        "WR1BEG[0]": 178,
        "WR1BEG[1]": 179,
        "WR1BEG[2]": 180,
        "WR1BEG[3]": 181,
        "WW2BEG[0]": 182,
        "WW2BEG[1]": 183,
        "WW2BEG[2]": 184,
        "WW2BEG[3]": 185,
        "WW4BEG[0]": 186,
        "WW4BEG[1]": 187,
        "WW4BEG[2]": 188,
        "WW4BEG[3]": 189,
        "COUT_N[0]": 190,
        "COUT_N[1]": 191,
        "GCLK_L_B[0]": 192,
        "GCLK_L_B[1]": 193,
        "GCLK_L_B[2]": 194,
        "GCLK_L_B[3]": 195,
        "GCLK_L_B[4]": 196,
        "GCLK_L_B[5]": 197,
        "GCLK_L_B[6]": 198,
        "GCLK_L_B[7]": 199,
        "GCLK_L_B[8]": 200,
        "GCLK_L_B[9]": 201,
        "GCLK_L_B[10]": 202,
        "GCLK_L_B[11]": 203,
        "GFAN[0]": 204,
        "GFAN[1]": 205,
        "CLK_L[0]": 206,
        "CLK_L[1]": 207,
    }
}

"""
    0: "CLBLL_R.I[0]",
    1: "CLBLL_R.O[0]",

    0: "CLBLM_L.I[0]",
    1: "CLBLM_L.O[0]",

    0: "CLBLM_R.I[0]",
    1: "CLBLM_R.O[0]",

    0: "INT_L.I[0]",
    1: "INT_L.O[0]",

    0: "INT_R.I[0]",
    1: "INT_R.O[0]",

    0: "HCLK_L.I[0]",
    1: "HCLK_L.O[0]",

    0: "HCLK_R.I[0]",
    1: "HCLK_R.O[0]",

'IO': {
    "BLK_BB-VPR_PAD.outpad[0]": 0,
    "BLK_BB-VPR_PAD.inpad[0]": 1,
},
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
