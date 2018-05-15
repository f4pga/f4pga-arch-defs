#!/usr/bin/env python3

"""
Import the INT tiles (which are just interconnects) information from Project
X-Ray database files.
"""

import argparse
import os
import re
import sys

from collections import namedtuple
from enum import Enum

import lxml.etree as ET

mydir = os.path.dirname(__file__)

sys.path.insert(0, os.path.join(mydir, "..", "..", "utils"))
from lib import mux as mux_lib

##########################################################################
# Work out valid arguments for Project X-Ray database                    #
##########################################################################
prjxray_db = os.path.abspath(os.path.join(mydir, "..", "..", "third_party", "prjxray-db"))

db_types = set()
int_tiles = set()
for d in os.listdir(prjxray_db):
    if d.startswith("."):
        continue
    dpath = os.path.join(prjxray_db, d)
    if not os.path.isdir(dpath):
        continue

    if not os.path.exists(os.path.join(dpath, "settings.sh")):
        continue

    db_types.add(d)

    for f in os.listdir(dpath):
        fpath = os.path.join(dpath, f)
        if not os.path.isfile(fpath):
            continue
        if not fpath.endswith('.db'):
            continue
        if not f.startswith('ppips_'):
            continue

        assert f.startswith('ppips_')
        assert f.endswith('.db')
        tile = f[len('ppips_'):-len('.db')]

        if not tile.startswith('int'):
            continue

        assert len(tile.split('_')) == 2, tile.split('_')
        int_tiles.add(tile.upper())


parser = argparse.ArgumentParser(
    description=__doc__,
    fromfile_prefix_chars='@',
    prefix_chars='-~'
)

parser.add_argument(
    '--part', choices=db_types,
    help="""Project X-Ray database to use.""")

parser.add_argument(
    '--tile', choices=int_tiles,
    help="""INT tile to generate for""")

parser.add_argument(
    '--output-pb-type', nargs='?', type=argparse.FileType('w'), default=sys.stdout,
    help="""File to write the output too.""")

args = parser.parse_args()

buf_dir = os.path.relpath(os.path.abspath(os.path.join(mydir, '..', 'vpr', 'buf')), os.path.dirname(args.output_pb_type.name))

prjxray_part_db = os.path.join(prjxray_db, args.part)

tile_type, tile_dir = args.tile.split('_')
tile_name = "BLK_BB-%s_%s" % (tile_type, tile_dir)

##########################################################################
# Read in the Project X-Ray database and do some processing              #
##########################################################################
def db_open(n):
    return open(os.path.join(prjxray_part_db, "%s_%s_%s.db" % (n, tile_type.lower(), tile_dir.lower())))

class OrderedEnum(Enum):
    def __ge__(self, other):
        if self.__class__ is other.__class__:
            return self.name >= other.value
        return NotImplemented
    def __gt__(self, other):
        if self.__class__ is other.__class__:
            return self.name > other.value
        return NotImplemented
    def __le__(self, other):
        if self.__class__ is other.__class__:
            return self.name <= other.value
        return NotImplemented
    def __lt__(self, other):
        if self.__class__ is other.__class__:
            return self.name < other.value
        return NotImplemented


_SpanWire = namedtuple("SpanWire", ("direction", "length", "ending"))

class SpanWire(_SpanWire):
    class Dir(OrderedEnum):
        N = 'North'
        E = 'East'
        S = 'South'
        W = 'West'
        L = 'Left'
        R = 'Right'

    _Direction = namedtuple("Direction", ("a", "b"))
    class Direction(_Direction):
        @property
        def name(self):
            return "%s%s" % (self.a.name, self.b.name)

    class Ending(OrderedEnum):
        BEG = 'Begins'
        END = 'Ends'

    @classmethod
    def parse(cls, name, extra=""):

        if len(name) != len("SW2END"):
            raise TypeError("Name %r is not correct length (%r)" % (name, extra))

        direction, length, ending = name[:2], name[2], name[3:]
        length = int(length)

        #assert direction[0] in cls.Dir, "%r not in %r" % (direction[0], cls.Dir)
        #assert direction[1] in cls.Dir, "%r not in %r" % (direction[1], cls.Dir)
        #assert ending in cls.Ending

        direction = cls.Direction(cls.Dir[direction[0]], cls.Dir[direction[1]])
        ending = cls.Ending[ending]

        o = cls(direction, length, ending)
        # FIXME: Hrm...
        o.extra = ""
        return o

    @property
    def name(self):
        return "%s%i%s" % (self.direction.name, self.length, self.ending.name)

    def __repr__(self):
        return "<SW: %s%s>" % (self.name, self.extra)

    def __str__(self):
        return self.name

    def __lt__(self, other):
        return str(self) < str(other)

    def __le__(self, other):
        return str(self) <= str(other)

    def __gt__(self, other):
        return str(self) > str(other)

    def __ge__(self, other):
        return str(self) >= str(other)


prefix_re = re.compile("^(.*?[^0-9_])(_[NESWRL][0-9]+_|_[NS]|)([0-9]+)(_[^0-9]+|)$")

wires_by_type = {
    'all':      {},
    'clock':    {},
    'long':     {},
    'span':     {},
    'local':    {},
    'neigh':    {},
    'unknown':  {},
}

def add_wire(wire_type, wire, num):
    wires = wires_by_type[wire_type]
    if wire not in wires:
        wires[wire] = set()
    wires[wire].add(num)
    return (wire, num)

connections_map = {
    'mux': {},
    'direct': {},
}

def process_wire(orig_wire_name):
    """
    >>>
    """

    #print(">>> {}".format(repr(wire_name)))

    # FIXME: Horrible hack to work around INT_R's have FAN0 while INT_L's have
    # FAN_L0 which collides with XXX_L names.
    #wire_name = re.sub("(FAN|BYP|CLK|CTRL|IMUX)(_L)?([0-9])", "\\1_IN\\3", wire_name)
    wire_name = re.sub("_L(.)", "\\1", orig_wire_name)

    g = prefix_re.match(wire_name)
    if not g:
        print("Skipping!", orig_wire_name)
        return None
        #return (wire_name, -1)

    prefix, extra_conn, num, extra_dir = g.groups()
    bits = prefix.split("_")

    if extra_conn.endswith("_"):
        assert extra_conn.endswith("_"), extra_conn
        extra_conn = extra_conn[:-1]

    try:
        num = int(num)
    except ValueError:
        num = 0

    if bits[0] in ("GCLK",):
        if not extra_dir:
            prefix += extra_dir
        return add_wire("clock", prefix, num)
    elif bits[0] in ("BYP", "LOGIC"):
        #if bits[0] in ("BYP",):
        #    return None
        #if bits[-1] in ("ALT",):
        #    return None
        assert not extra_dir, extra_dir
        return add_wire("local", prefix, num)
    elif bits[0] in ("FAN", "CLK", "CTRL", "IMUX"):
        #if bits[-1] in ("ALT","BOUNCE"):
        #    return None
        assert not extra_dir, extra_dir
        return add_wire("local", prefix, num)
    elif bits[0] in ("LH", "LV", "LVB"):
        assert not extra_dir, extra_dir
        return None
        #return add_wire("long", prefix, num)
    elif bits[0] in ("GFAN",):
        return None
    else:
        assert len(bits) == 1, bits
        assert not extra_dir, extra_dir
        return add_wire("span", SpanWire.parse(bits[0], extra_conn), num)
        #return add_wire("unknown", wire_name, 0)


def add_connection(conn_type, net_from, net_to):
    if not net_from or not net_to:
        return

    if isinstance(net_from[0], SpanWire):
        if net_from[0].ending != SpanWire.Ending.END:
            print("Starting wire not an ending!", net_from, "->", net_to)
            return

    if isinstance(net_to[0], SpanWire):
        if net_to[0].ending != SpanWire.Ending.BEG:
            print("Ending wire not a beginning!", net_from, "->", net_to)
            return

    if net_from == net_to:
        print("WARNING: Trying to add connection from wire %s to itself" % (net_from,))
        return

    assert conn_type in connections_map
    connections = connections_map[conn_type]

    if net_to not in connections:
        connections[net_to] = []

    assert net_from not in connections[net_to], (net_from, net_to, line, connections[net_to])
    connections[net_to].append(net_from)


for line in db_open('ppips').readlines():
    assert line.startswith("%s_%s." % (tile_type, tile_dir)), line
    name, bits = line.split(' ', maxsplit=1)
    _, net_to_name, net_from_name = name.split('.')

    if bits.strip() != "always":
        continue

    net_to = process_wire(net_to_name)
    net_from = process_wire(net_from_name)
    if net_from and isinstance(net_from, str):
        print(net_from, net_to)

    add_connection("direct", net_from, net_to)


for line in db_open('segbits').readlines():
    assert line.startswith("%s_%s." % (tile_type, tile_dir)), line
    name, bits = line.split(' ', maxsplit=1)
    _, net_to_name, net_from_name = name.split('.')

    net_to = process_wire(net_to_name)
    net_from = process_wire(net_from_name)

    if not net_to:
        continue

    add_connection("mux", net_from, net_to)


for wire_type in sorted(wires_by_type):
    if not wires_by_type[wire_type]:
        continue
    print()
    print("-"*75)
    print("%s Wires" % wire_type.title())
    print("-"*75)
    for wire, pins in sorted(wires_by_type[wire_type].items()):
        mpin = max(pins)+1
        if wire_type == 'span':
            assert mpin <= 4
            mpin = 4

        print(repr(wire), pins)
        pins_should = list(range(0, mpin))
        if pins_should == pins:
            continue

        for p in pins_should:
            if p in pins:
                continue

            print("WARNING: Padding %s with extra pin %s" % (wire, p))
            pins.add(p)

print()
print()

# FAN_BOUNCE_S3_6 is just FAN_BOUNCE6 from the tile above.

xi_url = "http://www.w3.org/2001/XInclude"
ET.register_namespace('xi', xi_url)
xi_include = "{%s}include" % xi_url

pb_type_xml = ET.Element(
    'pb_type', {
        'name': tile_name,
        'num_pb': str(1),
    },
    nsmap = {'xi': xi_url})


interconnect_xml = ET.Element('interconnect')

pb_type_xml.append(ET.Comment(" Tile Interconnects "))

mux_names = set()
net_dirs = {
    'inputs': set(),
    'outputs': set(),
}

# Figure out direction of span wires
for span_wire in wires_by_type['span']:
    if span_wire.ending == SpanWire.Ending.END:
        net_dirs['inputs'].add(span_wire)
    elif span_wire.ending == SpanWire.Ending.BEG:
        net_dirs['outputs'].add(span_wire)
    else:
        assert False

# Clocks always input
for clock_wire in wires_by_type['clock']:
    net_dirs['inputs'].add(clock_wire)

# Local wires
for local_wire, pins in wires_by_type['local'].items():
    if "LOGIC_OUTS" in local_wire:
        net_dirs['inputs'].add(local_wire)
    else:
        net_dirs['outputs'].add(local_wire)


def add_direct(src, dst):
    ET.SubElement(
        interconnect_xml,
        'direct', {
            'name': "%-30s" % dst,
            'input': "%-30s" % src,
            'output': "%-30s" % dst,
        },
    )


for span_wire, pins in sorted(wires_by_type['span'].items(), key=lambda i: (i[0].ending.name, i[0].direction.name, i[0].length)):
    if span_wire.ending == SpanWire.Ending.END:
        assert span_wire in net_dirs['inputs']
        wire_dir = 'input'
    elif span_wire.ending == SpanWire.Ending.BEG:
        assert span_wire in net_dirs['outputs']
        wire_dir = 'output'
    else:
        assert False

    ET.SubElement(
        pb_type_xml,
        wire_dir,
        {'name': span_wire.name, 'num_pins': str(len(pins))},
    )

    for pin in pins:
        if span_wire in net_dirs['outputs']:
            interconnect_xml.append(ET.Comment(" Connections for %s%s output mux " % (span_wire,pin)))

            dst_wire_name = "%s.%s[%s]" % (tile_name, span_wire.name, pin)
            mux_name  = "BEL_RX-%s%s"  % (span_wire.name, pin)

            assert mux_name not in mux_names
            mux_names.add(mux_name)

            srcs = connections_map['mux'][(span_wire, pin)]
            if not srcs:
                warn = "WARNING: No connection for pin %s on span wire %s" % (pin, span_wire)
                interconnect_xml.append(ET.Comment(" %s " % warn))
                print(warn)
                continue
            assert len(srcs) > 1

            port_names = [
                mux_lib.ModulePort(mux_lib.MuxPinType.OUTPUT, "OUT", 1, 0),
            ]
            for src_wire, index in sorted(srcs):
                if src_wire in net_dirs['inputs']:
                    src_wire_name = "%s.%s[%s]" % (tile_name, src_wire, index)
                else:
                    assert src_wire in net_dirs['outputs']
                    src_wire_name = "BEL_RX-%s%s.OUT" % (src_wire, index)

                mux_wire_name = "%s%s" % (src_wire, index)
                add_direct(src_wire_name, "%s.%s" % (mux_name, mux_wire_name))
                port_names.append(
                    mux_lib.ModulePort(mux_lib.MuxPinType.INPUT, mux_wire_name, 1, 0),
                )

            pb_type_xml.append(mux_lib.pb_type_xml(
                mux_lib.MuxType.ROUTING, mux_name, port_names))

            add_direct("%s.OUT" % mux_name, dst_wire_name)
        else:
            assert (span_wire, pin) not in connections_map['mux'] or not connections_map['mux'][(span_wire, pin)]


for clock_wire, pins in sorted(wires_by_type['clock'].items()):
    ET.SubElement(
        pb_type_xml,
        'clock',
        {'name': clock_wire, 'num_pins': str(len(pins))},
    )

    for pin in pins:
        assert (clock_wire, pin) not in connections_map['mux'] or not connections_map['mux'][(clock_wire, pin)], "{} found in {}".format((clock_wire, pin), connections_map['mux'][(clock_wire, pin)])


pb_type_xml.append(ET.Comment(" Local Interconnects "))
for local_wire, pins in sorted(wires_by_type['local'].items()):
    continous = (set(range(len(pins))) == pins)

    if local_wire in net_dirs['inputs']:
        for pin in pins:
            assert (local_wire, pin) not in connections_map['mux']
            assert (local_wire, pin) not in connections_map['direct'], ((local_wire, pin), connections_map['direct'][(local_wire, pin)])
        wire_type = "input"
    else:
        wire_type = "output"

    ET.SubElement(
        pb_type_xml,
        wire_type,
        {'name': local_wire, 'num_pins': str(len(pins))},
    )

    if wire_type == "input":
        continue

    for pin in pins:
        interconnect_xml.append(ET.Comment(" Connections for %s%s local " % (local_wire,pin)))

        # Outputs should all have muxes...
        use_mux = True
        if (local_wire, pin) in connections_map['mux']:
            srcs = connections_map['mux'][(local_wire, pin)]
        elif (local_wire, pin) in connections_map['direct']:
            srcs = connections_map['direct'][(local_wire, pin)]
        else:
            warn = "WARNING: No connection for pin %s on output local wire %s" % (pin, local_wire)
            interconnect_xml.append(ET.Comment(" %s " % warn))
            print(warn)
            continue

        local_wire_name = "%s.%s[%s]" % (tile_name, local_wire, pin)

        mux_name = "BEL_RX-%s%s" % (local_wire, pin)
        assert mux_name not in mux_names
        mux_names.add(mux_name)

        if len(srcs) == 1:
            print("INFO:", "Only 1 source for %s%s: %r" % (local_wire,pin,srcs))
        if len(srcs) == 0:
            print("WARNING:", "No sources for %s%s: %r" % (local_wire,pin,srcs))

        port_names = [
            mux_lib.ModulePort(mux_lib.MuxPinType.OUTPUT, "OUT", 1, 0),
        ]
        for src_wire, index in sorted(srcs):
            if src_wire in net_dirs["outputs"]:
                src_wire_name = "BEL_RX-%s%s.OUT" % (src_wire, index)
            else:
                src_wire_name = "%s.%s[%s]" % (tile_name, src_wire, index)
            mux_wire_name = "%s%s" % (src_wire, index)

            add_direct(src_wire_name, "%s.%s" % (mux_name, mux_wire_name))
            port_names.append(
                mux_lib.ModulePort(mux_lib.MuxPinType.INPUT, mux_wire_name, 1, 0),
            )

        pb_type_xml.append(mux_lib.pb_type_xml(
            mux_lib.MuxType.ROUTING, mux_name, port_names))

        add_direct("%s.OUT" % mux_name, local_wire_name)

pb_type_xml.append(interconnect_xml)

pb_type_str = ET.tostring(pb_type_xml, pretty_print=True).decode('utf-8')
args.output_pb_type.write(pb_type_str)
args.output_pb_type.close()
