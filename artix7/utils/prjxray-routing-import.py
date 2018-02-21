#!/usr/bin/env python3

import json
import os
import pprint
import re

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
        '--database', help='Project X-Ray Database')
parser.add_argument(
        '--read_rr_graph', help='Input rr_graph file')
parser.add_argument(
        '--write_rr_graph', help='Output rr_graph file')

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


def db_open(n):
    p = os.path.join(args.database, n)
    return json.load(open(p))


for conns in db_open("tileconn.json"):
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
for tile_name, tile_details in db_open("tilegrid.json")["tiles"].items():
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


import lxml.etree as ET

# Read in existing file
rr_graph = ET.parse(args.read_rr_graph)

# Delete the nodes and edges
for nodes in rr_graph.iterfind("rr_nodes"):
    for n in list(nodes):
        nodes.remove(n)
for edges in rr_graph.iterfind("rr_edges"):
    for e in list(edges):
        edges.remove(e)
    edges.clear()

# Create in the block_types information
blocktype_pins = {}
for block_type in rr_graph.iterfind("./block_types/block_type"):
    block_id = int(block_type.attrib['id'])
    block_name = block_type.attrib['name'].strip()

    assert block_name not in blocktype_pins
    blocktype_pins[block_name] = {}
    for pin in block_type.iterfind("./pin_class/pin"):
        pin_index = int(pin.attrib["index"])
        pin_ptc = int(pin.attrib["ptc"])
        pin_name = pin.text.strip()
        blocktype_pins[block_name][pin_name] = (pin_ptc, pin.getparent().attrib["type"])

pprint.pprint(blocktype_pins)


# Mapping dictionaries
globalname2node = {}
globalname2nodeid = {}


def add_node(globalname, attribs):
    """Add node with globalname and attributes."""
    # Add common attributes
    attribs['capacity'] =  str(1)

    # Work out the ID for this node and add to the mapping
    assert len(globalname2node) == len(globalname2nodeid)

    attribs['id'] = str(len(globalname2node))

    node = ET.SubElement(nodes, 'node', attribs)

    # Stash in the mappings
    assert globalname not in globalname2node, globalname
    assert globalname not in globalname2nodeid, globalname

    globalname2node[globalname] = node
    globalname2nodeid[globalname] = attribs['id']

    # Add some helpful comments
    if args.verbose:
        node.append(ET.Comment(" {} ".format(globalname)))

    return node


def globalname(pos, name):
    return "GRID_X{}Y{}/{}.{}".format(pos[0], pos[1], grid[pos], name)


def add_edge(src_globalname, dst_globalname):
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


def add_pin(pos, pin_globalname, pin_idx, pin_dir):
    """Add an pin at index i to tile at pos."""

    pin_globalname_a = pin_globalname+"-"+pin_dir

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

    low = list(pos)
    high = list(pos)

    if pin_dir in ("INPUT", "CLOCK"):
        # Pin node
        attribs = {
            'type': 'IPIN',
        }
        node = add_node(pin_globalname, attribs)
        ET.SubElement(node, 'loc', {
            'xlow': str(low[0]), 'ylow': str(low[1]),
            'xhigh': str(high[0]), 'yhigh': str(high[1]),
            'ptc': str(pin_idx),
            'side': 'TOP',
        })
        ET.SubElement(node, 'timing', {'R': str(0), 'C': str(0)})

        # Sink node
        if "INT_R" in pin_globalname:
            low[0]-=1
        elif "INT_L" in pin_globalname:
            high[0]+=1

        attribs = {
            'type': 'SINK',
        }
        node = add_node(pin_globalname_a, attribs)
        ET.SubElement(node, 'loc', {
            'xlow': str(low[0]), 'ylow': str(low[1]),
            'xhigh': str(high[0]), 'yhigh': str(high[1]),
            'ptc': str(pin_idx),
        })
        ET.SubElement(node, 'timing', {'R': str(0), 'C': str(0)})

        # Edge PIN->SINK
        add_edge(pin_globalname, pin_globalname_a)

    elif pin_dir in ("OUTPUT",):
        # Pin node
        attribs = {
            'type': 'OPIN',
        }
        node = add_node(pin_globalname, attribs)
        ET.SubElement(node, 'loc', {
            'xlow': str(low[0]), 'ylow': str(low[1]),
            'xhigh': str(high[0]), 'yhigh': str(high[1]),
            'ptc': str(pin_idx),
            'side': 'TOP',
        })
        ET.SubElement(node, 'timing', {'R': str(0), 'C': str(0)})

        # Source node
        if "INT_R" in pin_globalname:
            low[0]-=1
        elif "INT_L" in pin_globalname:
            high[0]+=1

        attribs = {
            'type': 'SOURCE',
        }
        node = add_node(pin_globalname_a, attribs)
        ET.SubElement(node, 'loc', {
            'xlow': str(low[0]), 'ylow': str(low[1]),
            'xhigh': str(high[0]), 'yhigh': str(high[1]),
            'ptc': str(pin_idx),
        })
        ET.SubElement(node, 'timing', {'R': str(0), 'C': str(0)})

        # Edge SOURCE->PIN
        add_edge(pin_globalname_a, pin_globalname)

    else:
        assert False, "Unknown dir of {} for {}".format(pin_dir, pin_globalname)

    print("Adding pin {:55s} on tile ({:3d}, {:3d})@{:4d}".format(pin_globalname, pos[0], pos[1], pin_idx))


def add_channel_filler(pos, chantype):
    x,y = pos
    current_len = len(channels[chantype][(x,y)])
    fillername = "{}-{},{}+{}-filler".format(chantype,x,y,current_len)
    add_channel(fillername, pos, pos, '0', _chantype=chantype)
    new_len = len(channels[chantype][(x,y)])
    assert current_len + 1 == new_len, new_len


def add_channel(globalname, start, end, segtype, _chantype=None):
    x_start, y_start = start
    x_end, y_end = end

    # Y channel as X is constant
    if x_start == x_end and (_chantype is None or _chantype == "CHANY"):
        assert x_start == x_end
        assert _chantype is None or _chantype == "CHANY"
        chantype = 'CHANY'
        w_start, w_end = y_start, y_end

    # X channel as Y is constant
    elif y_start == y_end and (_chantype is None or _chantype == "CHANX"):
        assert y_start == y_end
        assert _chantype is None or _chantype == "CHANX"
        chantype = 'CHANX'
        w_start, w_end = x_start, x_end

    # Going to need two channels to make this work..
    else:
        assert _chantype is None
        start_channelname = add_channel(
            globalname+"_Y", (x_start, y_start), (x_start, y_end), segtype)[0]
        end_channelname = add_channel(
            globalname+"_X", (x_start, y_end), (x_end, y_end), segtype)[-1]
        add_edge(globalname+"_Y", globalname+"_X")
        return start_channelname, end_channelname

    assert _chantype is None or chantype == _chantype, (chantype, _chantype)

    if w_start > w_end:
        chandir = "DEC_DIR"
    elif w_start < w_end:
        chandir = "INC_DIR"
    elif w_start == w_end and _chantype != None:
        chandir = "INC_DIR"
    else:
        assert False, (globalname, start, end, segtype, _chantype)

    attribs = {
        'direction': chandir,
        'type': chantype,
    }
    node = add_node(globalname, attribs)

    # <loc xlow="int" ylow="int" xhigh="int" yhigh="int" side="{LEFT|RIGHT|TOP|BOTTOM}" ptc="int">
    channels_for_type = channels[chantype]

    idx = 0
    for x in range(x_start, x_end+1):
        for y in range(y_start, y_end+1):
            idx = max(idx, len(channels_for_type[(x,y)]))

    for x in range(x_start, x_end+1):
        for y in range(y_start, y_end+1):
            while len(channels_for_type[(x,y)]) < idx and _chantype == None:
                add_channel_filler((x,y), chantype)
            channels_for_type[(x,y)].append(globalname)

    # xlow, xhigh, ylow, yhigh - Integer coordinates of the ends of this routing source.
    # ptc - This is the pin, track, or class number that depends on the rr_node type.

    # side - { LEFT | RIGHT | TOP | BOTTOM }
    # For IPIN and OPIN nodes specifies the side of the grid tile on which the node
    # is located. Purely cosmetic?
    ET.SubElement(node, 'loc', {
        'xlow': str(x_start), 'ylow': str(y_start),
        'xhigh': str(x_end), 'yhigh': str(y_end),
        'ptc': str(idx),
    })
    ET.SubElement(node, 'segment', {'segment_id': str(segtype)})

    print("Adding channel {} from {} -> {} pos {}".format(globalname, start, end, idx))
    return globalname, globalname


vpr_type_map = {}
vpr_type_map["INT_L"] = "BLK_MB-CLBLL_L-INT_L"
vpr_type_map["INT_R"] = "BLK_MB-INT_R-CLBLL_R"


def vpr_map_x(x):
    return x-args.start_x+3

def vpr_map_y(y):
    return y-args.start_y+1

def vpr_map_pos(pos):
    return (vpr_map_x(pos[0]), vpr_map_y(pos[1]))

channels = {'CHANX': {}, 'CHANY': {}}
for x in range(args.start_x, args.end_x+1):
    for y in range(args.start_y, args.end_y+1):
        vx, vy = vpr_map_pos((x,y))
        channels['CHANX'][(vx,vy)] = []
        channels['CHANY'][(vx,vy)] = []


for i, x in enumerate(range(args.start_x, args.end_x+1)):
    for j, y in enumerate(range(args.start_y, args.end_y+1)):
        pos = (x,y)
        tile_type = grid[pos]

        if tile_type not in vpr_type_map:
            continue

        tile_type = vpr_type_map[tile_type]
        for pin_vprname, (pin_idx, pin_dir) in sorted(blocktype_pins[tile_type].items(), key=lambda x: x[-1]):
            pin_localname = pin_vprname.split(".")[-1].replace('[', '').replace(']', '')

            pin_globalname = globalname(pos, pin_localname)
            add_pin(vpr_map_pos(pos), pin_globalname, pin_idx, pin_dir)


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
        names.append(globalname(pos, name))

    wire_global_name = "->>".join(names)
    print()
    print(wire_global_name)
    if "LV" in wire_global_name or "LH" in wire_global_name:
        print("Skipping")
        continue

    start_pos = w[0][0]
    end_pos = w[-1][0]

    start_channelname, end_channelname = add_channel(wire_global_name, vpr_map_pos(start_pos), vpr_map_pos(end_pos), "1")

    add_edge(globalname(start_pos, start[-1]), start_channelname)
    add_edge(end_channelname, globalname(end_pos, w[-1][-1]))


# Work out how wide each channel is going to be...
channel_count = {'CHANY': {}, 'CHANX': {}}
channel_max_width = {'CHANY': 0, 'CHANX': 0}
for i in 'CHANY', 'CHANX':
    for x,y in sorted(channels[i]):
        channel_count[i][(x,y)] = len(channels[i][(x,y)])
        channel_max_width[i] = max(channel_max_width[i], channel_count[i][(x,y)])


print("Max channels")
pprint.pprint(channel_count)
print(channel_max_width)
for i in ['CHANY', 'CHANX']:
    for x,y in sorted(channels[i]):
        while len(channels[i][(x,y)]) < channel_max_width[i]:
            add_channel_filler((x,y), i)

channel = rr_graph.findall('.//channel')[0]
#assert "chan_width_max" in channel.attrib
#assert "x_min" in channel.attrib
#assert "y_min" in channel.attrib
#assert "x_max" in channel.attrib
#assert "y_max" in channel.attrib
#channel_max_width_str = str(channel_max_width)
#channel.attrib["chan_width_max"] = channel_max_width_str
#channel.attrib["x_min"] = channel_max_width_str
#channel.attrib["y_min"] = channel_max_width_str
#channel.attrib["x_max"] = channel_max_width_str
#channel.attrib["y_max"] = channel_max_width_str
#
#for n in rr_graph.findall(".//x_list"):
#    n.attrib["info"] = channel_max_width_str
#
#for n in rr_graph.findall(".//y_list"):
#    n.attrib["info"] = channel_max_width_str
#    index = int(n.attrib["index"])
#    if (index, -1) in channel_count:

pprint.pprint(channels)

with open(args.write_rr_graph, "wb") as f:
    rr_graph.write(f, pretty_print=True)
