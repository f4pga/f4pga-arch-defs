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

##########################################################################
# Work out valid arguments for Project X-Ray database                    #
##########################################################################
mydir = os.path.dirname(__file__)
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

prjxray_part_db = os.path.join(prjxray_db, args.part)

tile_type, tile_dir = args.tile.split('_')
tile_name = "TILE_%s_%s" % (tile_type, tile_dir)

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


_SpanWire = namedtuple("SpanWire", ("direction", "length", "ending", "extra"))

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
    def parse(cls, name):
        extra = None
        if "_" in name:
            name, extra = name.split("_")

        if len(name) != len("SW2END"):
            raise TypeError("Name %r is not correct length" % name)

        direction, length, ending = name[:2], name[2], name[3:]
        length = int(length)

        #assert direction[0] in cls.Dir, "%r not in %r" % (direction[0], cls.Dir)
        #assert direction[1] in cls.Dir, "%r not in %r" % (direction[1], cls.Dir)
        #assert ending in cls.Ending

        direction = cls.Direction(cls.Dir[direction[0]], cls.Dir[direction[1]])
        ending = cls.Ending[ending]

        return cls(direction, length, ending, extra)

    @property
    def name(self):
        if self.extra:
            extra = "_"+self.extra
        else:
            extra = ""
        return "%s%i%s%s" % (self.direction.name, self.length, self.ending.name, extra)

    def __repr__(self):
        return "<SW: %s>" % (self.name)

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


prefix_re = re.compile("^(.*[^0-9])([0-9]+)(_[^0-9NESWRL]+|)$")

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

def process_wire(wire_name):
    g = prefix_re.match(wire_name)
    if not g:
        print("Skipping!", wire_name)
        return None
        #return (wire_name, -1)

    prefix, num, extra = g.groups()
    bits = prefix.split("_")

    try:
        num = int(num)
    except ValueError:
        num = 0

    if "GFAN" in bits[0] or "GCLK" in bits[0]:
        if extra:
            return None
            #prefix = "%s--%s" % (prefix, extra)
        if "WEST" in wire_name:
            return None
        return add_wire("clock", prefix, num)
    elif "LH" in bits[0] or "LV" in bits[0]:
        assert not extra, extra
        return None
        #return add_wire("long", prefix, num)
    elif len(bits) == 1:
        assert not extra, extra
        return add_wire("span", SpanWire.parse(prefix), num)
    elif bits[-1] in ("L","ALT"):
        # FIXME: Temporary hack to work around bounce wires..
        if prefix == "BYP_ALT":
            prefix = "BYP_L"
        if prefix == "FAN_ALT":
            prefix = "FAN_L"
        assert not extra, extra
        return add_wire("local", prefix, num)
    elif bits[-1] in ("BOUNCE", "ALT"):
        assert not extra, extra
        return None
        #return add_wire("local", prefix, num)
    elif bits[-1] in ("", "N", "E", "S", "W"):
        if prefix.endswith("_"):
            prefix = prefix[:-1]
        assert not extra, extra
        return None
        #return add_wire("neigh", prefix, num)
    else:
        return None
        #return add_wire("unknown", wire_name, 0)


def add_connection(conn_type, net_from, net_to):
    if not net_from or not net_to:
        return

    if net_from == net_to:
        print("WARNING: Trying to add connection from wire %s to itself" % (net_from,))

    # FIXME: Disable the random bypass and similar wires...
    if not isinstance(net_to[0], SpanWire) and not net_to[0].endswith("_L"):
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
    print((net_from_name, net_from), (net_to_name, net_to))
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

    if isinstance(net_from, SpanWire):
        assert net_from.ending == SpanWire.Ending.END, net_from

    if isinstance(net_to, SpanWire):
        assert net_from.ending == SpanWire.Ending.BEG, net_from

    add_connection("mux", net_from, net_to)


for wire_type in sorted(wires_by_type):
    if not wires_by_type[wire_type]:
        continue
    print()
    print("-"*75)
    print("%s Wires" % wire_type.title())
    print("-"*75)
    for wire, pins in sorted(wires_by_type[wire_type].items()):
        if len(pins) > 1:
            while min(pins) > 0:
                new_pin = min(pins) - 1
                print("WARNING: Padding %s with extra pin %s" % (wire, new_pin))
                pins.add(new_pin)
                connections_map['mux'][(wire, new_pin)] = []
        print(repr(wire), pins)

print()
print()

# FAN_BOUNCE_S3_6 is just FAN_BOUNCE6 from the tile above.

pb_type_xml = ET.Element(
    'pb_type', {
        'name': tile_name,
        'num_pb': str(1),
    })

interconnect_xml = ET.Element('interconnect')

pb_type_xml.append(ET.Comment(" Tile Interconnects "))

# Add the pin locations on the right side of the tile to connect to the INT_X tile
pinloc_clbside_string = []
pinloc_fabside_string = []

# INT connect directly to fabric on "fabside"
# But only to the CLBLL on "side"
fc_xml = ET.SubElement(pb_type_xml, "fc", {
    'default_in_type':  "frac", "default_in_val":  "1.0",
    'default_out_type': "frac", "default_out_val": "1.0",
})


mux_names = set()

for span_wire, pins in sorted(wires_by_type['span'].items(), key=lambda i: (i[0].ending.name, i[0].direction.name, i[0].length)):
    ET.SubElement(
        pb_type_xml,
        {SpanWire.Ending.END: 'input',
         SpanWire.Ending.BEG: 'output'}[span_wire.ending],
        {'name': span_wire.name, 'num_pins': str(len(pins))},
    )

    pinloc_fabside_string.append(span_wire.name)

    if span_wire.ending == SpanWire.Ending.BEG:
        interconnect_xml.append(ET.Comment(" Output muxes for %s " % (span_wire,)))

    for pin in pins:
        if span_wire.ending == SpanWire.Ending.BEG:
            mux_name = "%s.%s[%s]" % (tile_name, span_wire.name, pin)

            assert mux_name not in mux_names
            mux_names.add(mux_name)

            dest = connections_map['mux'][(span_wire, pin)]
            if not dest:
                print("WARNING: No connections for %s" % mux_name)
                continue
            assert len(dest) > 1
            ET.SubElement(
                interconnect_xml,
                'mux', {
                    'name': mux_name,
                    'input': " ".join("%s.%s[%s]" % (tile_name, w, i) for w, i in sorted(dest)),
                    'output': mux_name,
                },
            )
        else:
            assert (span_wire, pin) not in connections_map['mux'] or not connections_map['mux'][(span_wire, pin)]


for clock_wire, pins in sorted(wires_by_type['clock'].items()):
    ET.SubElement(
        pb_type_xml,
        'clock',
        {'name': clock_wire, 'num_pins': str(len(pins))},
    )
    pinloc_fabside_string.append(clock_wire)

    for pin in pins:
        assert (clock_wire, pin) not in connections_map['mux'] or not connections_map['mux'][(clock_wire, pin)]


pb_type_xml.append(ET.Comment(" Local Interconnects "))
for local_wire, pins in sorted(wires_by_type['local'].items()):

    if local_wire.endswith("_L"):
        pinloc_clbside_string.append(local_wire)
        # <fc_override fc_type="abs" fc_val="2" port_name="I0"  segment_name="local" />
    else:
        pinloc_fabside_string.append(local_wire)

    # Local pins don't connect to fabric.
    ET.SubElement(fc_xml, "fc_override", {"fc_type": "abs", "fc_val": "0", "port_name": local_wire})

    found = False
    for pin in pins:
        has_mux    = (local_wire, pin) in connections_map['mux']
        has_direct = (local_wire, pin) in connections_map['direct']
        found = found or (has_mux or has_direct)

    if found:
        wire_type = "output"
    else:
        wire_type = "input"
        if "CLK" in local_wire:
            wire_type = "clock"

    continous = (set(range(len(pins))) == pins)

    ET.SubElement(
        pb_type_xml,
        wire_type,
        {'name': local_wire, 'num_pins': str(len(pins))},
    )

    if found:
        interconnect_xml.append(ET.Comment(" Output muxes for %s " % (local_wire,)))

        for pin in pins:
            has_mux    = (local_wire, pin) in connections_map['mux']
            has_direct = (local_wire, pin) in connections_map['direct']

            mux_name = "%s.%s[%s]" % (tile_name, local_wire, pin)
            assert mux_name not in mux_names
            mux_names.add(mux_name)

            if has_mux:
                dest = connections_map['mux'][(local_wire, pin)]
                ET.SubElement(
                    interconnect_xml,
                    'mux', {
                        'name': mux_name,
                        'input': " ".join("%s.%s[%s]" % (tile_name, w, i) for w, i in sorted(dest)),
                        'output': mux_name,
                    },
                )
            elif has_direct:
                dest = connections_map['direct'][(local_wire, pin)]
                ET.SubElement(
                    interconnect_xml,
                    'direct', {
                        'name': mux_name,
                        'input': " ".join("%s.%s[%s]" % (tile_name, w, i) for w, i in sorted(dest)),
                        'output': mux_name,
                    },
                )
            else:
                print("WARNING: No connection for pin %s on wire %s" % (pin, local_wire))

# Add the pin location information
pin_clbside, pin_fabside = {"L": ("left","right"), "R": ("right","left")}[tile_dir]
pinloc = ET.SubElement(pb_type_xml, 'pinlocations', {'pattern': 'custom'})

pinloc_clbside_xml = ET.SubElement(pinloc, "loc", {"side": pin_clbside, "xoffset": "0", "yoffset": "0"})
pinloc_clbside_xml.text = " ".join("%s.%s" % (tile_name, p) for p in pinloc_clbside_string)

pinloc_fabside_xml = ET.SubElement(pinloc, "loc", {"side": pin_fabside, "xoffset": "0", "yoffset": "0"})
pinloc_fabside_xml.text = " ".join("%s.%s" % (tile_name, p) for p in pinloc_fabside_string)

pb_type_xml.append(interconnect_xml)

pb_type_str = ET.tostring(pb_type_xml, pretty_print=True).decode('utf-8')
args.output_pb_type.write(pb_type_str)
args.output_pb_type.close()
