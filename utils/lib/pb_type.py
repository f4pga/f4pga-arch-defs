
from typing import Tuple, List

Name = str
Width = int
Port = Tuple[Name, Width]
ClockPort = Port
InputPort = Port
OutputPort = Port


def ports(filename) -> Tuple[List[ClockPort], List[InputPort], List[OutputPort]]:
    """Get the clock, input and output pins from a leaf pb_type.

    Returns
    -------
    [("clock_name", width), ...], [("input_name", width), ...], [("output_name", width), ...]
    """

    pbtype_xml = ET.parse(filename)
    pbtype_tag = pbtype_xml.getroot()

    pbtype_name = pbtype_tag.attrib['name']
    assert 'blif_model' in pbtype_tag.attrib, pbtype_tag.attrib
    assert pbtype_tag.attrib['num_pb'] == "1", pbtype_tag.attrib['num_pb']

    clocks = []
    for clock_tag in pbtype_tag.findall("clock"):
        clocks.append((clock_tag.attrib['name'], int(clock_tag.attrib['num_pins'])))

    inputs = []
    for input_tag in pbtype_tag.findall("input"):
        inputs.append((input_tag.attrib['name'], int(input_tag.attrib['num_pins'])))

    outputs = []
    for output_tag in pbtype_tag.findall("output"):
        outputs.append((output_tag.attrib['name'], int(output_tag.attrib['num_pins'])))

    return clocks, inputs, outputs
