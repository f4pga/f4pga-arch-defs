import lxml.etree as ET
import argparse
import re

IOPAD_OLOGIC_REGEX = re.compile("OLOGICE3.OQ_to_IOB33[MS]?.O")
IOPAD_ILOGIC_REGEX = re.compile("IOB33[MS]?.I_to_ILOGICE3.D")


def get_top_pb_type(element):
    top_pb_type = element.getparent()

    while True:
        next_parent = top_pb_type.getparent()

        if next_parent.tag in 'complexblocklist':
            return top_pb_type

        top_pb_type = next_parent


def check_correct_direct(element, list_to_check):
    interconnect = element.getparent()
    mode = interconnect.getparent()

    if mode.tag not in 'mode':
        return False

    for mode_to_check, port_to_check in list_to_check:
        if mode.attrib['name'] == mode_to_check and element.attrib[
                'name'] == port_to_check:
            return True

    return False


def add_pack_pattern(direct, pack_pattern_prefix):
    top_pb_type = get_top_pb_type(direct)

    pack_pattern_name = "{}_{}".format(
        pack_pattern_prefix, top_pb_type.attrib['name']
    )
    pack_pattern_in_port = direct.attrib['input']
    pack_pattern_out_port = direct.attrib['output']

    ET.SubElement(
        direct,
        'pack_pattern',
        attrib={
            'name': pack_pattern_name,
            'in_port': pack_pattern_in_port,
            'out_port': pack_pattern_out_port
        }
    )


def main():
    parser = argparse.ArgumentParser(
        description="Adds needed pack patterns to the architecture file."
    )
    parser.add_argument('--in_arch', required=True, help="Input arch.xml")

    args = parser.parse_args()

    arch_xml = ET.ElementTree()
    root_element = arch_xml.parse(args.in_arch)

    for direct in root_element.iter('direct'):
        if 'name' not in direct.attrib:
            continue

        direct_name = direct.attrib['name']

        # Adding OSERDES pack patterns
        if IOPAD_OLOGIC_REGEX.match(direct_name) or check_correct_direct(
                direct, [('NO_OBUF', 'O'), ('OSERDES', 'OQ')]):
            add_pack_pattern(direct, 'OSERDES')

        # Adding ISERDES pack patterns
        if IOPAD_ILOGIC_REGEX.match(direct_name) or check_correct_direct(
                direct, [('NO_IBUF', 'I'), ('ISERDES', 'D')]):
            add_pack_pattern(direct, 'ISERDES')

        # Adding IOSERDES pack patterns (using IOBUF)
        if IOPAD_OLOGIC_REGEX.match(direct_name) or IOPAD_ILOGIC_REGEX.match(
                direct_name) or check_correct_direct(direct, [
                    ('IOBUF', 'I'),
                    ('IOBUF', 'inpad.inpad_to_IOBUF_VPR.IOPAD_$inp'),
                    ('IOBUF', 'O'),
                    ('IOBUF', 'IOBUF_VPR.IOPAD_$out_to_outpad.outpad'),
                    ('ISERDES', 'D'), ('OSERDES', 'OQ')
                ]):
            add_pack_pattern(direct, 'IOSERDES')

    print(ET.tostring(arch_xml, pretty_print=True).decode('utf-8'))


if __name__ == "__main__":
    main()
