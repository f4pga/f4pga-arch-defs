#!/usr/bin/env python3
"""Functions for working with pb_type.xml files."""

from typing import Tuple, List, Union

import lxml.etree as ET

PBTypeName = str
PortName = str
PortWidth = int

SinglePinPort = PortName
MultiPinPort = Tuple[PortName, PortWidth]

Port = Union[SinglePinPort, MultiPinPort]

ClockPort = Port
InputPort = Port
OutputPort = Port


def find_leaf(root: ET.Element):
    """Find first leaf pb_type tag (otherwise None)."""

    def all_pbtype_tags(root):
        if root.tag == "pb_type":
            yield root
        yield from root.findall("pb_type")

    for pbtype_tag in all_pbtype_tags(root):
        if 'blif_model' in pbtype_tag.attrib:
            if '.subckt' in pbtype_tag.attrib['blif_model']:
                return pbtype_tag


def ports(
        pbtype_tag: ET.Element, assert_leaf=False
) -> Tuple[PBTypeName, List[ClockPort], List[InputPort], List[OutputPort]]:
    """Get the clock, input and output pins from a leaf pb_type.

    Returns
    -------
    [("clock_name", width), ...], [("input_name", width), ...], [("output_name", width), ...]
    """
    assert pbtype_tag.tag == "pb_type", "Unknown tag {}\n{}".format(
        pbtype_tag.tag, ET.dump(pbtype_tag)
    )

    pbtype_name = pbtype_tag.attrib['name']

    clocks = []
    for clock_tag in pbtype_tag.findall("clock"):
        clocks.append(
            (clock_tag.attrib['name'], int(clock_tag.attrib['num_pins']))
        )

    inputs = []
    for input_tag in pbtype_tag.findall("input"):
        inputs.append(
            (input_tag.attrib['name'], int(input_tag.attrib['num_pins']))
        )

    outputs = []
    for output_tag in pbtype_tag.findall("output"):
        outputs.append(
            (output_tag.attrib['name'], int(output_tag.attrib['num_pins']))
        )

    return pbtype_name, clocks, inputs, outputs
