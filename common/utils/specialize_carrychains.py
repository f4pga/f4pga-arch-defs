import lxml.etree as ET
import argparse
from lib.pb_type import get_pb_type_chain


def specialized_chain_name(pat):
    return '.'.join(get_pb_type_chain(pat)[:2])


def specialize_chain(pat):
    pat.attrib['name'] = '{}.{}'.format(
        specialized_chain_name(pat), pat.attrib['name']
    )


def main():
    parser = argparse.ArgumentParser(
        description="Converts site local carry chains to fabric global."
    )
    parser.add_argument(
        '--input_arch_xml',
        required=True,
        help="Input arch.xml to specialized."
    )

    args = parser.parse_args()

    arch_xml = ET.ElementTree()
    root_element = arch_xml.parse(args.input_arch_xml)

    tiles = {}
    for pat in root_element.iter('pack_pattern'):
        if 'CARRY' in pat.attrib['name']:
            pb_types = get_pb_type_chain(pat)
            if pb_types[0] not in tiles:
                tiles[pb_types[0]] = []

            tiles[pb_types[0]].append(pat)

    # Specialize first chain in each tile, and delete the rest.
    for tile, pats in tiles.items():
        patterns = []
        for idx, pat in enumerate(pats):
            parts = get_pb_type_chain(pat)
            if len(parts) > 1:
                patterns.append((idx, parts[1]))
            else:
                patterns.append((idx, ''))

        pat_indices, _ = zip(*sorted(patterns, key=lambda x: x[1]))
        chain_to_keep = specialized_chain_name(pats[pat_indices[0]])

        for pat_idx in pat_indices:
            pat = pats[pat_idx]

            if specialized_chain_name(pat) == chain_to_keep:
                specialize_chain(pat)
            else:
                pat.getparent().remove(pat)

    print(ET.tostring(arch_xml, pretty_print=True).decode('utf-8'))


if __name__ == '__main__':
    main()
