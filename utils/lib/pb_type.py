#!/usr/bin/env python3
"""Functions for working with pb_type.xml files."""

from typing import Dict, Tuple, List, Union
from io import StringIO

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

CarryName = str


def xps(s):
    """XML Parse String (internal helper function)."""
    return ET.parse(StringIO(s)).getroot()


def get_blif_model(pbtype_tag: ET.Element) -> str:
    """Get the blif_model string.

    Supports both `blif_model` attribute and `<blif_model>` tag.

    >>> print(get_blif_model(xps('''<pb_type />''')))
    None
    >>> get_blif_model(xps('''<pb_type blif_model="hello"/>'''))
    'hello'
    >>> get_blif_model(xps('''\\
    ...   <pb_type><blif_model>hello</blif_model></pb_type>
    ... '''))
    'hello'
    """

    model = ""
    blif_model = pbtype_tag.find("blif_model")
    if blif_model is not None:
        model = blif_model.text
    if 'blif_model' in pbtype_tag.attrib:
        model = pbtype_tag.attrib['blif_model']
    model = model.strip()
    if model:
        return model


def find_leaf(root: ET.Element) -> ET.Element:
    """Find first leaf pb_type tag (otherwise None)."""

    def all_pbtype_tags(root):
        if root.tag == "pb_type":
            yield root
        yield from root.findall(".//pb_type")

    for pbtype_tag in all_pbtype_tags(root):
        if get_blif_model(pbtype_tag):
            return pbtype_tag


def ports(
        pbtype_tag: ET.Element, assert_leaf=False
) -> Tuple[PBTypeName, List[ClockPort], List[InputPort], List[OutputPort],
           Dict[CarryName, Tuple[InputPort, OutputPort]]]:
    """Get the clock, input and output pins from a pb_type.

    Returns
    -------
    ([("clock_name",  width), ...],
     [("input_name",  width), ...],
     [("output_name", width), ...],
     {"carry_name": ("input port", "output_port"), ...})
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

    carry = {}

    def set_carry(name, in_port=None, out_port=None):
        if name not in carry:
            carry[name] = [None, None]
        if in_port is not None:
            assert carry[name][0] is None, (
                "Can't set {}: Carry {} in port already {}".format(
                    in_port, name, carry[name][0]
                )
            )
            carry[name][0] = in_port
        if out_port is not None:
            assert carry[name][
                -1
            ] is None, "Can't set {}: Carry {} out port already {}".format(
                out_port, name, carry[name][-1]
            )
            carry[name][-1] = out_port

    inputs = []
    for input_tag in pbtype_tag.findall("input"):
        name = input_tag.attrib['name']
        num_pins = int(input_tag.attrib['num_pins'])

        carry_tag = input_tag.find("pack_pattern[@type='carry']")
        if carry_tag is not None:
            assert carry_tag.attrib['type'] == 'carry'
            assert num_pins == 1
            set_carry(carry_tag.attrib['name'], in_port=name)
            continue

        inputs.append((name, num_pins))

    outputs = []
    for output_tag in pbtype_tag.findall("output"):
        name = output_tag.attrib['name']
        num_pins = int(output_tag.attrib['num_pins'])

        carry_tag = output_tag.find("pack_pattern[@type='carry']")
        if carry_tag is not None:
            assert carry_tag.attrib['type'] == 'carry'
            assert num_pins == 1
            set_carry(carry_tag.attrib['name'], out_port=name)
            continue

        outputs.append(
            (output_tag.attrib['name'], int(output_tag.attrib['num_pins']))
        )

    return pbtype_name, clocks, inputs, outputs, {
        k: tuple(v)
        for k, v in carry.items()
    }


def get_pb_type_chain(node):
    pb_types = []
    while True:
        parent = node.getparent()

        if parent is None:
            return list(reversed(pb_types))

        if parent.tag == 'pb_type':
            pb_types.append(parent.attrib['name'])

        node = parent
