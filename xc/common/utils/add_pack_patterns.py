""" Adds specialized pack patterns to avoid unroutable situations during packing

Given an input architecture, this utility will find all the directs that need
to have a specialized pack pattern and adds it to them.

To find the correct direct that needs to be updated there are two different ways:
    1. If the direct belongs to the top level pb_type, the direct can be
       checked against a regular expression specified at the beginning of
       this file or with a string contained in the direct name.
    2. If the direct belongs to an intermediate/leaf pb_type, the port name
       and belonging operational `mode` are checked to select the correct
       direct that needs update.

Currently IOPADs need specialized pack patterns to enable VTR to create molecules
between the various sites of the tile (e.g. ISERDES, IDELAY, IOB33 and OSERDES).

"""

import lxml.etree as ET
import argparse
import re
import itertools

# Regular Expressions to select the directs that need additional pack patterns.
# Being multiple IOB and IOPAD types, the name of the direct changes according
# to different types, hence a regex is needed.
IOPAD_OLOGIC_REGEX = re.compile("OLOGICE3.OQ_to_IOB33[MS]?.O")
IOPAD_OLOGIC_TQ_REGEX = re.compile("OLOGICE3.TQ_to_IOB33[MS]?.T")
IOPAD_ILOGIC_REGEX = re.compile("IOB33[MS]?.I_to_ILOGICE3.D")

# =============================================================================


def get_top_pb_type(element):
    """ Returns the top level pb_type given a subelement of the XML tree."""

    # Already top-level
    parent = element.getparent()
    if parent is not None and parent.tag == "complexblocklist":
        return None

    # Traverse
    while True:
        parent = element.getparent()

        if parent is None:
            return None
        if parent.tag == "complexblocklist":
            assert element.tag == "pb_type", element.tag
            return element

        element = parent


def check_direct(element, list_to_check):
    """ Returns a boolean indicating whether the direct should be update.

        Inputs:
            - element: direct that needs to be checked;
            - list_to_check: operational mode or pb_type and port of the direct to select.
    """

    if element.tag != "direct":
        return False

    interconnect = element.getparent()
    mode_or_pb_type = interconnect.getparent()

    if mode_or_pb_type.tag not in ['mode', 'pb_type']:
        return False

    for mode_or_pb_type_to_check, port_to_check in list_to_check:
        if mode_or_pb_type.attrib[
                'name'] == mode_or_pb_type_to_check and element.attrib[
                    'name'] == port_to_check:
            return True

    return False


def add_pack_pattern(element, pack_pattern_prefix, for_input=None):
    """ Adds the pack pattern to the given direct / mux with a specified
        prefix. """
    top_pb_type = get_top_pb_type(element)

    pack_pattern_name = "{}_{}".format(
        pack_pattern_prefix, top_pb_type.attrib['name']
    )

    if for_input is not None:
        assert for_input in element.attrib['input']
        pack_pattern_in_port = for_input
    else:
        pack_pattern_in_port = element.attrib['input']

    pack_pattern_out_port = element.attrib['output']

    # Check if not already there
    for child in element.findall("pack_pattern"):
        if child.attrib.get("name", None) == pack_pattern_name:
            assert False, (element.attrib["name"], pack_pattern_name,)

    ET.SubElement(
        element,
        'pack_pattern',
        attrib={
            'name': pack_pattern_name,
            'in_port': pack_pattern_in_port,
            'out_port': pack_pattern_out_port
        }
    )


# =============================================================================


def maybe_add_pack_pattern(element, pack_pattern_prefix, list_to_check):
    """
    Adds a pack pattern to the element ("direct" or "mux") that spans the
    connection only if both of its endpoints are found in the list.

    The pack pattern is prefixed with the pack_pattern_prefix and with a name
    of the topmost pb_type in the hierarchy.

    The list_to_check must contain tuples specifying connection endpoints in
    the same way as in the arch.xml ie. "<pb_name>.<port_name>".
    """

    # Check if we have a direct under an interconnect inside a mode/pb_type
    interconnect = element.getparent()
    if interconnect.tag != "interconnect":
        return

    mode_or_pb_type = interconnect.getparent()
    if mode_or_pb_type.tag not in ['mode', 'pb_type']:
        return

    # A direct connection
    if element.tag == "direct":
        inp = element.attrib['input']
        out = element.attrib['output']

        if (inp, out) in list_to_check:
            add_pack_pattern(element, pack_pattern_prefix)

    # A mux connections (match the input)
    elif element.tag == "mux":
        ins = element.attrib['input'].split()
        out = element.attrib['output']

        for inp in ins:
            if (inp, out) in list_to_check:
                add_pack_pattern(element, pack_pattern_prefix, inp)

    # Shouldn't happen
    else:
        assert False, element.tag


# =============================================================================


def main():
    parser = argparse.ArgumentParser(
        description="Adds needed pack patterns to the architecture file."
    )
    parser.add_argument('--in_arch', required=True, help="Input arch.xml")

    args = parser.parse_args()

    arch_xml = ET.ElementTree()
    xml_parser = ET.XMLParser(remove_blank_text=True)
    root_element = arch_xml.parse(args.in_arch, xml_parser)

    gen = itertools.chain(
        root_element.iter('direct'), root_element.iter('mux')
    )
    for direct in gen:
        if 'name' not in direct.attrib:
            continue

        top_parent = get_top_pb_type(direct)
        if top_parent is not None:
            top_name = top_parent.attrib["name"]
        else:
            top_name = ""

        dir_name = direct.attrib['name']

        #
        # OBUFT
        #

        # Adding OBUFT.TQ via T_INV helper primitive
        if IOPAD_OLOGIC_TQ_REGEX.match(dir_name):
            add_pack_pattern(direct, 'T_INV_OBUFT')

        maybe_add_pack_pattern(
            direct, 'T_INV_OBUFT', [
                ('T_INV.TO', 'OLOGIC_TFF.TQ'),
                ('OLOGIC_TFF.TQ', 'OLOGICE3.TQ'),
                ('IOB33M.T', 'IOB33_MODES.T'),
                ('IOB33S.T', 'IOB33_MODES.T'),
                ('IOB33.T', 'IOB33_MODES.T'),
                ('IOB33_MODES.T', 'OBUFT_VPR.T'),
                ('OBUFT_VPR.O', 'outpad.outpad'),
            ]
        )

        #
        # ODDR
        #

        # Adding ODDR.OQ via OBUF/OBUFT pack patterns
        if IOPAD_OLOGIC_REGEX.match(dir_name):
            add_pack_pattern(direct, 'ODDR_OQ_OBUFT')

        maybe_add_pack_pattern(
            direct, 'ODDR_OQ_OBUFT', [
                ('ODDR_OQ.Q', 'OLOGIC_OFF.OQ'),
                ('OLOGIC_OFF.OQ', 'OLOGICE3.OQ'),
                ('IOB33M.O', 'IOB33_MODES.O'),
                ('IOB33S.O', 'IOB33_MODES.O'),
                ('IOB33.O', 'IOB33_MODES.O'),
                ('IOB33_MODES.O', 'OBUFT_VPR.I'),
                ('OBUFT_VPR.O', 'outpad.outpad'),
            ]
        )

        # Adding ODDR.TQ via OBUFT pack patterns
        if IOPAD_OLOGIC_TQ_REGEX.match(dir_name):
            add_pack_pattern(direct, 'ODDR_TQ_OBUFT')

        maybe_add_pack_pattern(
            direct, 'ODDR_TQ_OBUFT', [
                ('ODDR_TQ.Q', 'OLOGIC_TFF.TQ'),
                ('OLOGIC_TFF.TQ', 'OLOGICE3.TQ'),
                ('IOB33M.T', 'IOB33_MODES.T'),
                ('IOB33S.T', 'IOB33_MODES.T'),
                ('IOB33.T', 'IOB33_MODES.T'),
                ('IOB33_MODES.T', 'OBUFT_VPR.T'),
                ('OBUFT_VPR.O', 'outpad.outpad'),
            ]
        )

        # TODO: "TDDR" via IOBUF, OBUFTDS, IOBUFDS

        # TODO: ODDR+"TDDR" via OBUFT, IOBUF, OBUFTDS, IOBUFDS

        #
        # OSERDES
        #

        # Adding OSERDES via NO_OBUF pack patterns
        if IOPAD_OLOGIC_REGEX.match(dir_name) or check_direct(direct, [
            ('OSERDES', 'OQ'),
            ('IOB33S', 'O'),
            ('IOB33M', 'O'),
            ('IOB33', 'O'),
            ('NO_OBUF', 'O'),
        ]):
            add_pack_pattern(direct, 'OSERDES_NO_OBUF')

        # Adding OSERDES via OBUF/OBUFT pack patterns
        if IOPAD_OLOGIC_REGEX.match(dir_name) or check_direct(direct, [
            ('OSERDES', 'OQ'),
            ('IOB33S', 'O'),
            ('IOB33M', 'O'),
            ('IOB33', 'O'),
            ('OBUFT', 'IOB33_MODES.O_to_OBUFT_VPR.I'),
            ('OBUFT', 'OBUFT_VPR.O_to_outpad.outpad'),
        ]):
            add_pack_pattern(direct, 'OSERDES_OBUFT')

        # TODO: OSERDES via OBUFT

        # Adding OSERDES via IOBUF pack patterns
        if IOPAD_OLOGIC_REGEX.match(dir_name) or check_direct(direct, [
            ('OSERDES', 'OQ'),
            ('IOB33S', 'O'),
            ('IOB33M', 'O'),
            ('IOB33', 'O'),
            ('IOBUF', 'O_to_IOBUF_VPR.I'),
            ('IOBUF', 'IOBUF_VPR.IOPAD_$out_to_outpad.outpad'),
            ('IOBUF', 'inpad.inpad_to_IOBUF_VPR.IOPAD_$inp'),
        ]):
            add_pack_pattern(direct, 'OSERDES_IOBUF')

        # TODO: OSERDES via OBUFDS

        # Adding OSERDES to differential OBUFTDS pack patterns
        if "IOPAD_M" in top_name:
            if "OQ_to_IOB33M" in dir_name or check_direct(direct, [
                ('OBUFTDS_M', 'I'),
                ('OBUFTDS_M', 'O'),
                ('OSERDES', 'OQ'),
                ('IOB33M', 'I'),
                ('IOB33M', 'O'),
            ]):
                add_pack_pattern(direct, 'OSERDES_OBUFTDS_M')

        # Adding OSERDES to differential IOBUFDS pack patterns
        if "IOPAD_M" in top_name:
            if "OQ_to_IOB33M" in dir_name or check_direct(direct, [
                ('IOBUFDS_M', 'I'),
                ('IOBUFDS_M', 'IOPAD_$inp'),
                ('IOBUFDS_M', 'IOPAD_$out'),
                ('OSERDES', 'OQ'),
                ('IOB33M', 'I'),
                ('IOB33M', 'O'),
            ]):
                add_pack_pattern(direct, 'OSERDES_IOBUFDS_M')

        #
        # IDDR
        #

        # Adding IDDR via IBUF pack patterns
        if IOPAD_ILOGIC_REGEX.match(dir_name):
            add_pack_pattern(direct, 'IDDR_IBUF')

        maybe_add_pack_pattern(direct, 'IDDR_IBUF', [
            ('inpad.inpad',     'IBUF_VPR.I'),
            ('IBUF_VPR.O',      'IOB33_MODES.I'),
            ('IOB33_MODES.I',   'IOB33.I'),
            ('IOB33_MODES.I',   'IOB33M.I'),
            ('IOB33_MODES.I',   'IOB33S.I'),
            ('ILOGICE3.D',      'IFF.D')
        ])

        # TODO: IDDR via IOBUF, IDDR via IOBUFDS

        # Adding IDDR+IDELAY via IBUF pack patterns
        if 'I_to_IDELAYE2' in dir_name:
            add_pack_pattern(direct, 'IDDR_IDELAY_IBUF')

        maybe_add_pack_pattern(direct, 'IDDR_IDELAY_IBUF', [
            ('inpad.inpad',     'IBUF_VPR.I'),
            ('IBUF_VPR.O',      'IOB33_MODES.I'),
            ('IOB33_MODES.I',   'IOB33.I'),
            ('IOB33_MODES.I',   'IOB33M.I'),
            ('IOB33_MODES.I',   'IOB33S.I'),
            ('IDELAYE2.DATAOUT','ILOGICE3.DDLY'),
            ('ILOGICE3.DDLY',   'IFF.D')
        ])

        # TODO: IDDR+IDELAY via IOBUF, IDDR+IDELAY via IOBUFDS

        #
        # ISERDES, no IDELAY
        #

        # Adding ISERDES via NO_IBUF
        if IOPAD_ILOGIC_REGEX.match(dir_name) or check_direct(direct, [
            ('NO_IBUF', 'I'),
            ('ISERDES_NO_IDELAY', 'D'),
            ('IOB33S', 'I'),
            ('IOB33S', 'O'),
            ('IOB33M', 'I'),
            ('IOB33M', 'O'),
            ('IOB33', 'I'),
            ('IOB33', 'O'),
        ]):
            add_pack_pattern(direct, 'ISERDES_NO_IBUF')

        # Adding IOSERDES pack patterns (using IOBUF)
        if IOPAD_OLOGIC_REGEX.match(dir_name) or IOPAD_ILOGIC_REGEX.match(
                dir_name) or check_direct(direct, [
                    ('IOBUF', 'O_to_IOBUF_VPR.I'),
                    ('IOBUF', 'inpad.inpad_to_IOBUF_VPR.IOPAD_$inp'),
                    ('IOBUF', 'I_to_IOBUF_VPR.O'),
                    ('IOBUF', 'IOBUF_VPR.IOPAD_$out_to_outpad.outpad'),
                    ('IOB33S', 'I'), ('IOB33S', 'O'), ('IOB33M', 'I'),
                    ('IOB33M', 'O'), ('IOB33', 'I'), ('IOB33', 'O'),
                    ('ISERDES_NO_IDELAY', 'D'), ('OSERDES', 'OQ')
                ]):
            add_pack_pattern(direct, 'IOSERDES')

        # Adding ISERDES via differential IOBUFDS pack patterns
        if "IOPAD_M" in top_name:
            if "I_to_ILOGICE3" in dir_name or check_direct(direct, [
                ('IOBUFDS_M', 'O'),
                ('IOBUFDS_M', 'IOPAD_$inp'),
                ('IOBUFDS_M', 'IOPAD_$out'),
                ('ISERDES_NO_IDELAY', 'D'),
                ('IOB33M', 'I'),
                ('IOB33M', 'O'),
            ]):
                add_pack_pattern(direct, 'ISERDES_IOBUFDS_M')

        #
        # ISERDES + IDELAY
        #

        # Adding ISERDES+IDELAY via NO_IBUF pack patterns
        if 'DATAOUT_to_ILOGICE3' in dir_name or 'I_to_IDELAYE2' in dir_name or check_direct(
                direct, [
                    ('NO_IBUF', 'I'),
                    ('ISERDES_IDELAY', 'DDLY'),
                    ('IOB33S', 'I'),
                    ('IOB33S', 'O'),
                    ('IOB33M', 'I'),
                    ('IOB33M', 'O'),
                    ('IOB33', 'I'),
                    ('IOB33', 'O'),
                ]):
            add_pack_pattern(direct, 'ISERDES_IDELAY_NO_IBUF')

        # Adding IOSERDES with IDELAY pack patterns (using IOBUF)
        if IOPAD_OLOGIC_REGEX.match(
                dir_name
        ) or 'DATAOUT_to_ILOGICE3' in dir_name or 'I_to_IDELAYE2' in dir_name or check_direct(
                direct, [('IOBUF', 'O_to_IOBUF_VPR.I'),
                         ('IOBUF', 'inpad.inpad_to_IOBUF_VPR.IOPAD_$inp'),
                         ('IOBUF', 'I_to_IOBUF_VPR.O'),
                         ('IOBUF', 'IOBUF_VPR.IOPAD_$out_to_outpad.outpad'),
                         ('IOB33S', 'I'), ('IOB33S', 'O'), ('IOB33M', 'I'),
                         ('IOB33M', 'O'), ('IOB33', 'I'), ('IOB33', 'O'),
                         ('ISERDES_IDELAY', 'DDLY'), ('OSERDES', 'OQ')]):
            add_pack_pattern(direct, 'ISERDES_IDELAY_IOBUF')

        # Adding ISERDES+IDELAY via differential IOBUFDS pack patterns
        if "IOPAD_M" in top_name:
            if 'DATAOUT_to_ILOGICE3' in dir_name or 'I_to_IDELAYE2' in dir_name or check_direct(
                    direct, [
                        ('IOBUFDS_M', 'O'),
                        ('IOBUFDS_M', 'IOPAD_$inp'),
                        ('IOBUFDS_M', 'IOPAD_$out'),
                        ('ISERDES_IDELAY', 'DDLY'),
                        ('IOB33M', 'I'),
                        ('IOB33M', 'O'),
                    ]):
                add_pack_pattern(direct, 'ISERDES_IDELAY_IOBUFDS_M')

        #
        # IDELAY only
        #

        # TODO: Need to change sth in the arch.

    print(ET.tostring(arch_xml, pretty_print=True).decode('utf-8'))


if __name__ == "__main__":
    main()
