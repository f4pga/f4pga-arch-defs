import lxml.etree as ET
import argparse

def get_pb_type_chain(node):
    pb_types = []
    while True:
        parent = node.getparent()

        if parent is None:
            return list(reversed(pb_types))

        if parent.tag == 'pb_type':
            pb_types.append(parent.attrib['name'])

        node = parent

def main():
    parser = argparse.ArgumentParser(description="Converts site local carry chains to fabric global.");
    parser.add_argument('--input_arch_xml', required=True, help="Input arch.xml to specialized.")

    args = parser.parse_args()

    arch_xml = ET.ElementTree()
    root_element = arch_xml.parse(args.input_arch_xml)

    for pat in root_element.iter('pack_pattern'):
        if 'CARRY' in pat.attrib['name']:
            pat.attrib['name'] = '{}.{}'.format(
                    '.'.join(get_pb_type_chain(pat)[:2]),
                    pat.attrib['name'])

    print(ET.tostring(arch_xml, pretty_print=True).decode('utf-8'))

if __name__ == '__main__':
    main()
