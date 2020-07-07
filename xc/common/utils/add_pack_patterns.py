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
IOPAD_OLOGIC_OQ_REGEX = re.compile("OLOGICE3.OQ_to_IOB33[MS]?.O")
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
            assert False, (
                element.attrib["name"],
                pack_pattern_name,
            )

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
            add_pack_pattern(direct, 'T_INV_to_OBUFT')

        maybe_add_pack_pattern(
            direct, 'T_INV_to_OBUFT', [
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
        if IOPAD_OLOGIC_OQ_REGEX.match(dir_name):
            add_pack_pattern(direct, 'ODDR_to_OBUFT')

        maybe_add_pack_pattern(
            direct, 'ODDR_to_OBUFT', [
                ('ODDR_OQ.Q', 'OLOGIC_OFF.OQ'),
                ('OLOGIC_OFF.OQ', 'OLOGICE3.OQ'),
                ('IOB33M.O', 'IOB33_MODES.O'),
                ('IOB33S.O', 'IOB33_MODES.O'),
                ('IOB33.O', 'IOB33_MODES.O'),
                ('IOB33_MODES.O', 'OBUFT_VPR.I'),
                ('OBUFT_VPR.O', 'outpad.outpad'),
            ]
        )

        # Adding ODDR.OQ via OBUF/OBUFT + TQ via T_INV pack patterns
        if IOPAD_OLOGIC_OQ_REGEX.match(dir_name):
            add_pack_pattern(direct, 'ODDR_to_T_INV_to_OBUFT')
        if IOPAD_OLOGIC_TQ_REGEX.match(dir_name):
            add_pack_pattern(direct, 'ODDR_to_T_INV_to_OBUFT')

        maybe_add_pack_pattern(
            direct, 'ODDR_to_T_INV_to_OBUFT', [
                ('ODDR_OQ.Q', 'OLOGIC_OFF.OQ'),
                ('OLOGIC_OFF.OQ', 'OLOGICE3.OQ'),
                ('IOB33M.O', 'IOB33_MODES.O'),
                ('IOB33S.O', 'IOB33_MODES.O'),
                ('IOB33.O', 'IOB33_MODES.O'),
                ('IOB33_MODES.O', 'OBUFT_VPR.I'),
                ('OBUFT_VPR.O', 'outpad.outpad'),
                ('T_INV.TO', 'OLOGIC_TFF.TQ'),
                ('OLOGIC_TFF.TQ', 'OLOGICE3.TQ'),
                ('IOB33M.T', 'IOB33_MODES.T'),
                ('IOB33S.T', 'IOB33_MODES.T'),
                ('IOB33.T', 'IOB33_MODES.T'),
                ('IOB33_MODES.T', 'OBUFT_VPR.T'),
            ]
        )

        # Adding ODDR.TQ via OBUFT pack patterns
        if IOPAD_OLOGIC_TQ_REGEX.match(dir_name):
            add_pack_pattern(direct, 'TDDR_to_OBUFT')

        maybe_add_pack_pattern(
            direct, 'TDDR_to_OBUFT', [
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
        # OSERDES (No TQ)
        #

        # Adding OSERDES (no TQ) via NO_OBUF pack patterns
        if IOPAD_OLOGIC_OQ_REGEX.match(dir_name):
            add_pack_pattern(direct, 'OSERDES_to_NO_OBUF')

        maybe_add_pack_pattern(
            direct, 'OSERDES_to_NO_OBUF', [
                ('OSERDESE2_NO_TQ.OQ', 'OLOGICE3.OQ'),
                ('IOB33M.O', 'IOB33_MODES.O'),
                ('IOB33S.O', 'IOB33_MODES.O'),
                ('IOB33.O', 'IOB33_MODES.O'),
                ("IOB33_MODES.O", "outpad.outpad"),
            ]
        )

        # Adding OSERDES (no TQ) via OBUF/OBUFT pack patterns
        if IOPAD_OLOGIC_OQ_REGEX.match(dir_name):
            add_pack_pattern(direct, 'OSERDES_to_OBUF')

        maybe_add_pack_pattern(
            direct, 'OSERDES_to_OBUF', [
                ('OSERDESE2_NO_TQ.OQ', 'OLOGICE3.OQ'),
                ('IOB33M.O', 'IOB33_MODES.O'),
                ('IOB33S.O', 'IOB33_MODES.O'),
                ('IOB33.O', 'IOB33_MODES.O'),
                ('IOB33_MODES.O', 'OBUFT_VPR.I'),
                ('OBUFT_VPR.O', 'outpad.outpad'),
            ]
        )

        # Adding OSERDES (no TQ) via OBUFT and OBUFT.TQ via T_INV pack patterns
        if IOPAD_OLOGIC_OQ_REGEX.match(dir_name):
            add_pack_pattern(direct, 'OSERDES_T_INV_to_OBUF')
        if IOPAD_OLOGIC_TQ_REGEX.match(dir_name):
            add_pack_pattern(direct, 'OSERDES_T_INV_to_OBUF')

        maybe_add_pack_pattern(
            direct, 'OSERDES_T_INV_to_OBUF', [
                ('OSERDESE2_NO_TQ.OQ', 'OLOGICE3.OQ'),
                ('IOB33M.O', 'IOB33_MODES.O'),
                ('IOB33S.O', 'IOB33_MODES.O'),
                ('IOB33.O', 'IOB33_MODES.O'),
                ('IOB33_MODES.O', 'OBUFT_VPR.I'),
                ('OBUFT_VPR.O', 'outpad.outpad'),

                ('T_INV.TO', 'OLOGICE3.TQ'),
                ('IOB33M.T', 'IOB33_MODES.T'),
                ('IOB33S.T', 'IOB33_MODES.T'),
                ('IOB33.T', 'IOB33_MODES.T'),
                ('IOB33_MODES.T', 'OBUFT_VPR.T'),
            ]
        )

        # Adding OSERDES via IOBUF pack patterns
        if IOPAD_OLOGIC_OQ_REGEX.match(dir_name):
            add_pack_pattern(direct, 'OSERDES_to_IOBUF')

        maybe_add_pack_pattern(
            direct, 'OSERDES_to_IOBUF', [
                ('OSERDESE2_NO_TQ.OQ', 'OLOGICE3.OQ'),
                ('IOB33M.O', 'IOB33_MODES.O'),
                ('IOB33S.O', 'IOB33_MODES.O'),
                ('IOB33.O', 'IOB33_MODES.O'),
                ('IOB33_MODES.O', 'IOBUF_VPR.I'),
                ('IOBUF_VPR.IOPAD_$out', 'outpad.outpad'),
                ('inpad.inpad', 'IOBUF_VPR.IOPAD_$inp'),
            ]
        )

        # Adding OSERDES via differential OBUFDS/OBUFTDS pack patterns
        if "IOPAD_M" in top_name:
            if IOPAD_OLOGIC_OQ_REGEX.match(dir_name):
                add_pack_pattern(direct, 'OSERDES_to_OBUFDS')

            maybe_add_pack_pattern(
                direct, 'OSERDES_to_OBUFDS', [
                    ('OSERDESE2_NO_TQ.OQ', 'OLOGICE3.OQ'),
                    ('IOB33M.O', 'IOB33_MODES.O'),
                    ('IOB33_MODES.O', 'OBUFTDS_M_VPR.I'),
                    ('OBUFTDS_M_VPR.O', 'outpad.outpad'),
                ]
            )

        # Adding OSERDES via differential IOBUFDS pack patterns
        if "IOPAD_M" in top_name:
            if IOPAD_OLOGIC_OQ_REGEX.match(dir_name):
                add_pack_pattern(direct, 'OSERDES_to_IOBUFDS')

            maybe_add_pack_pattern(
                direct, 'OSERDES_to_IOBUFDS', [
                    ('OSERDESE2_NO_TQ.OQ', 'OLOGICE3.OQ'),
                    ('IOB33M.O', 'IOB33_MODES.O'),
                    ('IOB33_MODES.O', 'IOBUFDS_M_VPR.I'),
                    ('IOBUFDS_M_VPR.IOPAD_$out', 'outpad.outpad'),
                    ('inpad.inpad', 'IOBUFDS_M_VPR.IOPAD_$inp'),
                ]
            )

        #
        # OSERDES (with TQ)
        #

        # Adding OSERDES via OBUFT pack patterns
        if IOPAD_OLOGIC_OQ_REGEX.match(dir_name):
            add_pack_pattern(direct, 'OSERDES_TQ_to_OBUF')

        maybe_add_pack_pattern(
            direct, 'OSERDES_TQ_to_OBUF', [
                ('OSERDESE2.OQ', 'OLOGICE3.OQ'),
                ('IOB33M.O', 'IOB33_MODES.O'),
                ('IOB33S.O', 'IOB33_MODES.O'),
                ('IOB33.O', 'IOB33_MODES.O'),
                ('IOB33_MODES.O', 'OBUFT_VPR.I'),
                ('OBUFT_VPR.O', 'outpad.outpad'),
            ]
        )

        # Adding OSERDES via IOBUF pack patterns
        if IOPAD_OLOGIC_OQ_REGEX.match(dir_name):
            add_pack_pattern(direct, 'OSERDES_TQ_to_IOBUF')

        maybe_add_pack_pattern(
            direct, 'OSERDES_TQ_to_IOBUF', [
                ('OSERDESE2.OQ', 'OLOGICE3.OQ'),
                ('IOB33M.O', 'IOB33_MODES.O'),
                ('IOB33S.O', 'IOB33_MODES.O'),
                ('IOB33.O', 'IOB33_MODES.O'),
                ('IOB33_MODES.O', 'IOBUF_VPR.I'),
                ('IOBUF_VPR.IOPAD_$out', 'outpad.outpad'),
                ('inpad.inpad', 'IOBUF_VPR.IOPAD_$inp'),
            ]
        )
        # Adding OSERDES via differential OBUFTDS pack patterns
        if "IOPAD_M" in top_name:
            if IOPAD_OLOGIC_OQ_REGEX.match(dir_name):
                add_pack_pattern(direct, 'OSERDES_TQ_to_OBUFDS')

            maybe_add_pack_pattern(
                direct, 'OSERDES_TQ_to_OBUFDS', [
                    ('OSERDESE2.OQ', 'OLOGICE3.OQ'),
                    ('IOB33M.O', 'IOB33_MODES.O'),
                    ('IOB33_MODES.O', 'OBUFTDS_M_VPR.I'),
                    ('OBUFTDS_M_VPR.O', 'outpad.outpad'),
                ]
            )

        # Adding OSERDES via differential IOBUFDS pack patterns
        if "IOPAD_M" in top_name:
            if IOPAD_OLOGIC_OQ_REGEX.match(dir_name):
                add_pack_pattern(direct, 'OSERDES_TQ_to_IOBUFDS')

            maybe_add_pack_pattern(
                direct, 'OSERDES_TQ_to_IOBUFDS', [
                    ('OSERDESE2.OQ', 'OLOGICE3.OQ'),
                    ('IOB33M.O', 'IOB33_MODES.O'),
                    ('IOB33_MODES.O', 'IOBUFDS_M_VPR.I'),
                    ('IOBUFDS_M_VPR.IOPAD_$out', 'outpad.outpad'),
                    ('inpad.inpad', 'IOBUFDS_M_VPR.IOPAD_$inp'),
                ]
            )

        #
        # IDDR
        #
        for use_idelay in [False, True]:

            if use_idelay:
                name = "IDDR_to_IDELAY"
                connections = [('ILOGICE3.DDLY', 'IFF.D')]

            else:
                name = "IDDR"
                connections = [('ILOGICE3.D', 'IFF.D')]

            # Adding IDDR via IBUF pack patterns
            if not use_idelay and IOPAD_ILOGIC_REGEX.match(dir_name):
                add_pack_pattern(direct, name + '_to_IBUF')

            if use_idelay and ('I_to_IDELAYE2' in dir_name
                               or 'DATAOUT_to_ILOGICE3' in dir_name):
                add_pack_pattern(direct, name + '_to_IBUF')

            maybe_add_pack_pattern(
                direct, name + '_to_IBUF', [
                    ('inpad.inpad', 'IBUF_VPR.I'),
                    ('IBUF_VPR.O', 'IOB33_MODES.I'),
                    ('IOB33_MODES.I', 'IOB33.I'),
                    ('IOB33_MODES.I', 'IOB33M.I'),
                    ('IOB33_MODES.I', 'IOB33S.I'),
                ] + connections
            )

            # TODO: IDDR via IOBUF, IDDR via IOBUFDS

        #
        # ISERDES
        #
        for use_idelay in [False, True]:

            if use_idelay:
                name = "ISERDESE2_to_IDELAY"
                connections = [('ILOGICE3.DDLY', 'ISERDESE2_IDELAY.DDLY')]

            else:
                name = "ISERDESE2"
                connections = [('ILOGICE3.D', 'ISERDESE2_NO_IDELAY.D')]

            # Adding ISERDES via NO_IBUF pack patterns
            if not use_idelay and IOPAD_ILOGIC_REGEX.match(dir_name):
                add_pack_pattern(direct, name + '_to_NO_IBUF')

            if use_idelay and ('I_to_IDELAYE2' in dir_name
                               or 'DATAOUT_to_ILOGICE3' in dir_name):
                add_pack_pattern(direct, name + '_to_NO_IBUF')

            maybe_add_pack_pattern(
                direct, name + '_to_NO_IBUF', [
                    ("inpad.inpad", "IOB33_MODES.I"),
                    ('IOB33_MODES.I', 'IOB33.I'),
                    ('IOB33_MODES.I', 'IOB33M.I'),
                    ('IOB33_MODES.I', 'IOB33S.I'),
                ] + connections
            )

            # Adding ISERDES via IBUF pack patterns
            if not use_idelay and IOPAD_ILOGIC_REGEX.match(dir_name):
                add_pack_pattern(direct, name + '_to_IBUF')

            if use_idelay and ('I_to_IDELAYE2' in dir_name
                               or 'DATAOUT_to_ILOGICE3' in dir_name):
                add_pack_pattern(direct, name + '_to_IBUF')

            maybe_add_pack_pattern(
                direct, name + '_to_IBUF', [
                    ('inpad.inpad', 'IBUF_VPR.I'),
                    ('IBUF_VPR.O', 'IOB33_MODES.I'),
                    ('IOB33_MODES.I', 'IOB33.I'),
                    ('IOB33_MODES.I', 'IOB33M.I'),
                    ('IOB33_MODES.I', 'IOB33S.I'),
                ] + connections
            )

            # Adding ISERDES via IOBUF pack patterns
            if not use_idelay and IOPAD_ILOGIC_REGEX.match(dir_name):
                add_pack_pattern(direct, name + '_to_IOBUF')

            if use_idelay and ('I_to_IDELAYE2' in dir_name
                               or 'DATAOUT_to_ILOGICE3' in dir_name):
                add_pack_pattern(direct, name + '_to_IOBUF')

            maybe_add_pack_pattern(
                direct, name + '_to_IOBUF', [
                    ('IOBUF_VPR.IOPAD_$out', 'outpad.outpad'),
                    ('inpad.inpad', 'IOBUF_VPR.IOPAD_$inp'),
                    ('IOBUF_VPR.O', 'IOB33_MODES.I'),
                    ('IOB33_MODES.I', 'IOB33.I'),
                    ('IOB33_MODES.I', 'IOB33M.I'),
                    ('IOB33_MODES.I', 'IOB33S.I'),
                ] + connections
            )

            # Adding ISERDES via differential IOBUFDS pack patterns
            if "IOPAD_M" in top_name:
                if not use_idelay and IOPAD_ILOGIC_REGEX.match(dir_name):
                    add_pack_pattern(direct, name + '_to_IOBUFDS')

                if use_idelay and ('I_to_IDELAYE2' in dir_name
                                   or 'DATAOUT_to_ILOGICE3' in dir_name):
                    add_pack_pattern(direct, name + '_to_IOBUFDS')

                maybe_add_pack_pattern(
                    direct, name + '_to_IOBUFDS', [
                        ('IOBUFDS_M_VPR.IOPAD_$out', 'outpad.outpad'),
                        ('inpad.inpad', 'IOBUFDS_M_VPR.IOPAD_$inp'),
                        ('IOBUFDS_M_VPR.O', 'IOB33_MODES.I'),
                        ('IOB33_MODES.I', 'IOB33M.I'),
                    ] + connections
                )

        #
        # IDELAY only
        #

        # TODO: Need to change sth in the arch.

    print(ET.tostring(arch_xml, pretty_print=True).decode('utf-8'))


if __name__ == "__main__":
    main()
