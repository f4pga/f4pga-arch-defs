#!/usr/bin/env python3

"""
Import the top level CLB interconnect information from Project X-Ray database
files.
"""

import argparse
import os
import re
import sys

import lxml.etree as ET

##########################################################################
# Work out valid arguments for Project X-Ray database                    #
##########################################################################
mydir = os.path.dirname(__file__)
prjxray_db = os.path.abspath(os.path.join(mydir, "..", "..", "third_party", "prjxray-db"))

db_types = set()
clb_tiles = set()
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

        if not tile.startswith('clb'):
            continue

        assert len(tile.split('_')) == 2, tile.split('_')
        clb_tiles.add(tile.upper())


parser = argparse.ArgumentParser(
    description=__doc__,
    fromfile_prefix_chars='@',
    prefix_chars='-~'
)

parser.add_argument(
    '--part', choices=db_types,
    help="""Project X-Ray database to use.""")

parser.add_argument(
    '--tile', choices=clb_tiles,
    help="""CLB tile to generate for""")

parser.add_argument(
    '--output-pb-type', nargs='?', type=argparse.FileType('w'), default=sys.stdout,
    help="""File to write the output too.""")

parser.add_argument(
    '--output-model', nargs='?', type=argparse.FileType('w'), default=sys.stdout,
    help="""File to write the output too.""")

args = parser.parse_args()

prjxray_part_db = os.path.join(prjxray_db, args.part)

tile_type, tile_dir = args.tile.split('_')

##########################################################################
# Read in the Project X-Ray database and do some processing              #
##########################################################################
def db_open(n):
    return open(os.path.join(prjxray_part_db, "%s_%s_%s.db" % (n, tile_type.lower(), tile_dir.lower())))

wires_internal = {}

prefix_re = re.compile("^(.*[^0-9])([0-9]+)$")

def process_wire(wire_name):
    """Extract data from the wire name and added to global database."""
    orig_wire_name = wire_name
    assert wire_name.startswith(tile_type), wire_name
    wire_name = wire_name[len(tile_type+'_'):]

    # Wires which end in _N are from neighbours, so shouldn't prepended with slice name.
    if wire_name.endswith("_N"):
        pass
    elif wire_name.startswith("L_"):
        wire_name = "CLBLL_L."+wire_name[2:]
    elif wire_name.startswith("M_"):
        wire_name = "CLBLL_M."+wire_name[2:]
    elif wire_name.startswith("LL_"):
        wire_name = "CLBLL_LL."+wire_name[3:]

    # Special case the LUT inputs as they look like a bus but we don't want to
    # treat them like one.
    for lutin in ('A1', 'A2', 'A3', 'A4', 'A5', 'A6',
                  'B1', 'B2', 'B3', 'B4', 'B5', 'B6',
                  'C1', 'C2', 'C3', 'C4', 'C5', 'C6',
                  'D1', 'D2', 'D3', 'D4', 'D5', 'D6',
                  ):
        if wire_name.endswith(lutin):
            prefix, num = wire_name, None
            break
    else:
        # Figure out if the wire is part of a bus?
        g = prefix_re.match(wire_name)
        if not g:
            prefix, num = wire_name, None
        else:
            prefix, num = g.groups()
            num = int(num)

    name = prefix

    if name not in wires_internal:
        wires_internal[name] = set()
    wires_internal[name].add(num)
    return name, num


connections = {}

def ppips():
    for line in db_open('ppips').readlines():
        yield line
    if tile_type == "CLBLL":
        yield "CLBLL_L.CLBLL_L_CIN.CLBLL_L_CIN_N always\n"
        yield "CLBLL_L.CLBLL_LL_CIN.CLBLL_LL_CIN_N always\n"
    elif tile_type == "CLBLM":
        #yield "CLBLL_M.CLBLL_M_CIN.CLBLL_M_CIN_N always\n"
        #yield "CLBLL_M.CLBLL_L_CIN.CLBLL_L_CIN_N always\n"
        pass

# Read in all the Pseudo PIP definitions.
for line in ppips():
    assert line.startswith('%s_%s.' % (tile_type, tile_dir)), line
    name, bits = line.strip().split(' ', maxsplit=1)
    _, net_to, net_from = name.split('.')

    if bits != "always":
        print("Skipping line: %r" % line)
        continue

    net_to = process_wire(net_to)
    net_from = process_wire(net_from)
    connections[net_from] = net_to

# Work out the direction of all wires.
# All wires are uni-directional, so we know the input/output stuff from that.
clbll_inputs = set()
slice_inputs = set()

slice_outputs = set()
clbll_outputs = set()

# Add a connection for the carry out to make it an output
#connections[('%s_%s.COUT_N' % (tile_type, tile_dir), None)] = ("CARRY_OUT", None)

# CLBLL_L_COUT_N
# CLBLL_LL_COUT_N
# CLBLL_L_COUT->CLBLL_L_COUT_N

for name, pins in wires_internal.items():
    #if "COUT" in name:
    #    continue
    if name.startswith("CLB"):
        inputs = slice_outputs
        outputs = slice_inputs
    else:
        inputs = clbll_inputs
        outputs = clbll_outputs

    input = True
    for p in pins:
        if (name, p) in connections:
            assert input == True
        else:
            input = False

    wire = (name, tuple(pins))
    if input:
        inputs.add(wire)
    else:
        outputs.add(wire)

##########################################################################
# Hard code some settings                                                #
##########################################################################
# CLBLL's have two slices internally.
if tile_type.startswith('CLBLL'):
    # CLBLL's have two SLICELs, one called CLBLL_L and one called CLBLL_LL
    slice0_name = 'CLBLL_L'
    slice0_type = 'SLICEL'
    slice1_name = 'CLBLL_LL'
    slice1_type = 'SLICEL'
elif tile_type.startswith('CLBLM'):
    # CLBLM's have one SLICELs called CLBLL_L and one SLICEM called CLBLL_M
    slice0_name = 'CLBLM_M'
    slice0_type = 'SLICEM'
    slice1_name = 'CLBLM_L'
    slice1_type = 'SLICEL'
else:
    assert False, tile_type

slice_model = "../../primitives/%s/model.xml"
slice_pbtype = "../../primitives/%s/pb_type.xml"

xi_url = "http://www.w3.org/2001/XInclude"
ET.register_namespace('xi', xi_url)
xi_include = "{%s}include" % xi_url

##########################################################################
# Generate the model.xml file                                            #
##########################################################################


model_xml = ET.Element(
    'models', nsmap = {'xi': xi_url},
)

def add_model_include(name):
    ET.SubElement(model_xml, xi_include, {
        'href': slice_model % name.lower(),
        'xpointer': "xpointer(models/*)"})

add_model_include(slice0_type)

if slice1_type != slice0_type:
    add_model_include(slice1_type)

model_str = ET.tostring(model_xml, pretty_print=True).decode('utf-8')
args.output_model.write(model_str)
args.output_model.close()

##########################################################################
# Generate the pb_type.xml file                                          #
##########################################################################

def add_direct(xml, input, output):
    ET.SubElement(xml, 'direct', {'name': '%-30s' % output, 'input': '%-30s' % input, 'output': '%-30s' % output})

tile_name = "TILE_%s_%s" % (tile_type, tile_dir)

pb_type_xml = ET.Element(
    'pb_type', {
        'name': tile_name,
        'num_pb': str(1),
    },
    nsmap = {'xi': xi_url},
)

def fmt(wire, pin):
    if pin is None:
        return wire
    return '%s[%s]' % (wire, pin)

interconnect_xml = ET.Element('interconnect')


pb_type_xml.append(ET.Comment(" Tile Inputs "))
interconnect_xml.append(ET.Comment(" Tile->Slice "))
for name, pins in sorted(clbll_inputs):
    if name == "FAN":
        assert pins == (6, 7)
        pins = tuple(range(8))
    assert pins == (None,) or pins == tuple(range(len(pins))), "Wrong pins for {} {} should be {}".format(name, pins, list(range(len(pins))))

    # Input definitions for the TILE
    input_type = 'input'
    if 'CLK' in name:
        input_type = 'clock'
    ET.SubElement(
        pb_type_xml,
        input_type,
        {'name': '%-20s' % name, 'num_pins': str(len(pins))},
    )

    for p in pins:
        if (name, p) not in connections:
            continue
        # Connections from the TILE to the CLBLL_XX
        add_direct(interconnect_xml, '%s.%s' % (tile_name, fmt(name, p)), fmt(*connections[(name, p)]))

pb_type_xml.append(ET.Comment(" Tile Outputs "))
for name, pins in sorted(clbll_outputs):
    # Output definitions for the TILE
    ET.SubElement(
        pb_type_xml,
        'output',
        {'name': '%-20s' % name, 'num_pins': str(len(pins))},
    )

# Add the pin locations on the right side of the tile to connect to the INT_X tile
side_pinloc_string = []
top_pinloc_string = []
bot_pinloc_string = []
for name, pins in sorted(clbll_inputs) + sorted(clbll_outputs):
    if name.endswith("_N"):
        if "IN" in name:
            bot_pinloc_string.append("%s.%s" % (tile_name, name))
        elif "OUT" in name:
            top_pinloc_string.append("%s.%s" % (tile_name, name))
        else:
            assert False, "Unknown neighbour pin %r" % name
        continue
    side_pinloc_string.append("%s.%s" % (tile_name, name))

pinloc = ET.SubElement(pb_type_xml, 'pinlocations', {'pattern': 'custom'})

side_pinloc = ET.SubElement(pinloc, "loc", {"side": {"L": "right", "R": "left"}[tile_dir], "xoffset": "0", "yoffset": "0"})
side_pinloc.text = " ".join(side_pinloc_string)

top_pinloc = ET.SubElement(pinloc, "loc", {"side": "top", "xoffset": "0", "yoffset": "0"})
top_pinloc.text = " ".join(top_pinloc_string)

bot_pinloc = ET.SubElement(pinloc, "loc", {"side": "bottom", "xoffset": "0", "yoffset": "0"})
bot_pinloc.text = " ".join(bot_pinloc_string)

# CLBs don't connect directly to fabric
fc = ET.SubElement(pb_type_xml, "fc", {
    'default_in_type':  "abs", "default_in_val":  "1",
    'default_out_type': "abs", "default_out_val": "1",
})

# Add the internal slices to this CLB
pb_type_xml.append(ET.Comment(" Internal Slices "))

# Internal pb_type definition for the first slice
slice0_xml = ET.SubElement(pb_type_xml, 'pb_type', {'name': slice0_name, 'num_pb': '1'})
ET.SubElement(slice0_xml, xi_include, {'href': slice_pbtype % slice0_type.lower()})
slice0_interconnect_xml = ET.Element('interconnect')
slice0_interconnect_xml.append(ET.Comment(" Slice->Cell "))

# Internal pb_type definition for the second slice
slice1_xml = ET.SubElement(pb_type_xml, 'pb_type', {'name': slice1_name, 'num_pb': '1'})
ET.SubElement(slice1_xml, xi_include, {'href': slice_pbtype % slice0_type.lower()})
slice1_interconnect_xml = ET.Element('interconnect')
slice1_interconnect_xml.append(ET.Comment(" Slice->Cell "))

for name, pins in sorted(slice_inputs):
    if name.startswith(slice0_name+'.'):
        slice_type = slice0_type
        slice_xml = slice0_xml
        slice_interconnect_xml = slice0_interconnect_xml
    elif name.startswith(slice1_name+'.'):
        slice_type = slice1_type
        slice_xml = slice1_xml
        slice_interconnect_xml = slice1_interconnect_xml
    else:
        assert False, name

    # Input pins for the CLBLL_X
    input_type = 'input'
    if 'CLK' in name:
        input_type = 'clock'
    ET.SubElement(
        slice_xml,
        input_type, {'name': ' %-6s' % name.split('.')[-1], 'num_pins': str(len(pins))},
    )

    # Connections from CLBLL_X type to the contained SLICEL/SLICEM
    for p in pins:
        input_name = fmt(name, p)
        add_direct(slice_interconnect_xml, input_name, '%s.%s' % (slice_type, input_name.split('.')[-1]))

slice0_interconnect_xml.append(ET.Comment(" Cell->Slice "))
slice1_interconnect_xml.append(ET.Comment(" Cell->Slice "))
interconnect_xml.append(ET.Comment(" Slice->Tile "))

for name, pins in sorted(slice_outputs):
    if name.startswith(slice0_name+'.'):
        slice_type = slice0_type
        slice_xml = slice0_xml
        slice_interconnect_xml = slice0_interconnect_xml
    elif name.startswith(slice1_name+'.'):
        slice_type = slice1_type
        slice_xml = slice1_xml
        slice_interconnect_xml = slice1_interconnect_xml
    else:
        assert False

    # Output pins for the CLBLL_X
    ET.SubElement(
        slice_xml,
        'output', {'name': '%-6s' % name.split('.')[-1], 'num_pins': str(len(pins))},
    )

    for p in pins:
        output_name = fmt(name, p)
        # Connections from SLICEL/SLICEM to the containing CLBLL_X type
        add_direct(slice_interconnect_xml, ('%s.%s' % (slice_type, output_name.split('.')[-1])), output_name)
        # Connections from the CLBLL_XX to the TILE
        add_direct(interconnect_xml, output_name, '%s.%s' % (tile_name, fmt(*connections[(name, p)])))

slice0_xml.append(slice0_interconnect_xml)
slice1_xml.append(slice1_interconnect_xml)
pb_type_xml.append(interconnect_xml)

pb_type_str = ET.tostring(pb_type_xml, pretty_print=True).decode('utf-8')
args.output_pb_type.write(pb_type_str)
args.output_pb_type.close()
