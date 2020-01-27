#!/usr/bin/env python3
import re
import itertools
from collections import defaultdict

import lxml.etree as ET

from data_structs import *

# =============================================================================


def get_pin_name(name):
    """
    Returns the pin name and its index in bus. If a pin is not a member of
    a bus then the index is 0.
    """

    match = re.match(r"(.*)\[([0-9]+)\]$", name)
    if match:
        return match(1), int(match(2))
    else:
        return name, 0

# =============================================================================

def add_ports(xml_parent, pins):
    """
    Adds ports to the tile/pb_type tag. Also returns the pins grouped by
    direction and into buses.
    """

    # Group pins into buses
    pinlists = {
        "input":  defaultdict(lambda: 0),
        "output": defaultdict(lambda: 0),
        "clock":  defaultdict(lambda: 0),
    }

    for pin in pins:
        if pin.direction == PinDirection.INPUT:
            if pin.is_clock:
                pinlist = pinlists["clock"]
            else:
                pinlist = pinlists["input"]
        elif pin.direction == PinDirection.OUTPUT:
            pinlist = pinlists["output"]
        else:
            assert False, pin

        name, idx = get_pin_name(pin.name)
        pinlist[name] = max(pinlist[name], idx + 1)

    # Generate the pinout
    for tag, pinlist in pinlists.items():
        for pin, count in pinlist.items():
            ET.SubElement(xml_parent, tag, {
                "name": pin,
                "num_pins": str(count)
            })

    return pinlists


# =============================================================================


def make_top_level_model(tile_type, nsmap):
    xml_models = ET.Element("models", nsmap=nsmap)

    # Include cells
    xi_include = "{{{}}}include".format(nsmap["xi"])
    for cell_type, cell_count in tile_type.cells.items():
        name = cell_type.lower()
        pb_type_file = "../../primitives/{}/{}.model.xml".format(name, name)
        ET.SubElement(xml_models, xi_include, {
            "href": pb_type_file,
            "xpointer": "xpointer(models/child::node())",
        })

    return xml_models


def make_top_level_pb_type(tile_type, nsmap):
    """
    Generates top-level pb_type wrapper for cells of a given tile type.
    """
    pb_name = "PB-{}".format(tile_type.type.upper())
    xml_pb = ET.Element("pb_type", {
        "name": pb_name
    }, nsmap=nsmap)

    # Ports
    pinlists = add_ports(xml_pb, tile_type.pins)

    # Include cells
    xi_include = "{{{}}}include".format(nsmap["xi"])
    for cell_type, cell_count in tile_type.cells.items():
        xml_sub = ET.SubElement(xml_pb, "pb_type", {
            "name": cell_type.upper(),
            "num_pb": str(cell_count)
        })

        name = cell_type.lower()
        pb_type_file = "../../primitives/{}/{}.pb_type.xml".format(name, name)
        ET.SubElement(xml_sub, xi_include, {
            "href": pb_type_file,
            "xpointer": "xpointer(pb_type/child::node())",
        })


    def tile_pin_to_cell_pin(name):
        match = re.match(r"^([A-Za-z_]+)([0-9]+)_(.*)$", name)
        assert match is not None, name

        return "{}[{}].{}".format(match.group(1), match.group(2), match.group(3))

    # Generate the interconnect
    xml_ic = ET.SubElement(xml_pb, "interconnect")

    for pin, count in itertools.chain(pinlists["clock"].items(), pinlists["input"].items()):
        for i in range(count):
            pin_name = pin if count == 1 else "{}[{}]".format(pin, i)
            inp = pin_name
            out = tile_pin_to_cell_pin(pin_name)

            ET.SubElement(xml_ic, "direct", {
                "name": "{}_to_{}".format(inp, out),
                "input": inp,
                "output": out
            })

    for pin, count in pinlists["output"].items():
        for i in range(count):
            pin_name = pin if count == 1 else "{}[{}]".format(pin, i)
            inp = tile_pin_to_cell_pin(pin_name)
            out = pin_name

            ET.SubElement(xml_ic, "direct", {
                "name": "{}_to_{}".format(inp, out),
                "input": inp,
                "output": out
            })

    return xml_pb


def make_top_level_tile(tile_type):
    """
    Makes a tile definition for the given tile
    """
    pb_name = tile_type.type.upper()
    xml_tile = ET.Element("tile", {
        "name": "TL-{}".format(pb_name),
    })

    # Top-level ports
    pinlists = add_ports(xml_tile, tile_type.pins)
    all_pins = {**pinlists["clock"], **pinlists["input"], **pinlists["output"]}

    # Equivalent sites
    xml_equiv = ET.SubElement(xml_tile, "equivalent_sites")

    xml_site = ET.SubElement(xml_equiv, "site", {
        "pb_type": "PB-{}".format(pb_name),
        "pin_mapping": "custom"
    })

    for pin, count in all_pins.items():
        for i in range(count):
            pin_name = pin if count == 1 else "{}.{}[{}]".format(pb_name, pin, i)
            ET.SubElement(xml_site, "direct", {
                "from": pin_name,
                "to":   pin_name
            })

    # TODO: Add "fc" override for direct tile-to-tile connections if any.

    # Pin locations
    pins_by_loc = {
        "left":   [],
        "right":  [],
        "bottom": [],
        "top":    []
    }

    # FIXME: Make all of them go bottom right now. In the end we should use
    # pin location (side) assignment per tile type.
    for pin, count in all_pins.items():
        for i in range(count):
            pin_name = pin if count == 1 else "{}.{}[{}]".format(pb_name, pin, i)
            pins_by_loc["bottom"].append(pin_name)

    # Dump pin locations
    xml_pinloc = ET.SubElement(xml_tile, "pinlocations", {"pattern": "custom"})
    for loc, pins in pins_by_loc.items():
        if len(pins):
            xml_loc = ET.SubElement(xml_pinloc, loc)
            xml_loc.text = " ".join(["{}.{}".format(pb_name, pin) for pin in pins])

    # Switchbox locations
    # This is actually not needed in the end but has to be present to make
    # the VPR happy
    ET.SubElement(xml_tile, "switchbox_locations", {"pattern": "all"})

    return xml_tile
