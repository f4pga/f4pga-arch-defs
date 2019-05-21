import lxml.etree as ET
import argparse
from sdf_timing import sdfparse
from sdf_timing.utils import get_scale_seconds
from lib.pb_type import get_pb_type_chain
import re
import os


def remove_site_number(site):
    number = re.search(r'\d+$', site)
    if number is not None:
        site = site[:-len(str(number.group()))]
    return site


def get_cell_type_and_instance(bel, location, site, bels):
    if site not in bels:
        return None, None
    if bel not in bels[site]:
        return None, None
    if location not in bels[site][bel]:
        return None, None

    celltype = bels[site][bel][location]['celltype']
    instance = bels[site][bel][location]['instance']

    return celltype, instance


def find_timings(timings, bel, location, site, bels):
    separator = "/"
    celltype, instance = get_cell_type_and_instance(bel, location, site, bels)
    if (celltype is None) or (instance is None):
        return None
    bel_timings = dict()
    cell = timings['cells'][celltype][instance]
    for delay in cell:
        if not cell[delay]['is_absolute']:
            continue
        entry = cell[delay]['delay_paths']['slow']['max']
        bel_timings[delay] = float(entry) * get_scale_seconds('1 ns')

    return bel_timings


def mergedicts(source, destination):
    for key, value in source.items():
        if isinstance(value, dict):
            # get node or create one
            node = destination.setdefault(key, {})
            mergedicts(value, node)
        else:
            destination[key] = value

    return destination


def main():
    parser = argparse.ArgumentParser()

    parser.add_argument(
        '--input_arch', required=True, help="Input arch.xml file"
    )
    parser.add_argument('--sdf_dir', required=True, help="SDF files directory")
    parser.add_argument(
        '--out_arch', required=True, help="Output arch.xml file"
    )
    parser.add_argument(
        '--bels_map',
        required=True,
        help="VPR <-> timing info bels mapping json file"
    )

    args = parser.parse_args()

    arch_xml = ET.ElementTree()
    root_element = arch_xml.parse(args.input_arch)

    # read bels json
    import json
    with open(args.bels_map, 'r') as fp:
        bels = json.load(fp)

    timings = dict()
    files = os.listdir(args.sdf_dir)
    for f in files:
        if not f.endswith('.sdf'):
            continue
        with open(args.sdf_dir + '/' + f, 'r') as fp:
            tmp = sdfparse.parse(fp.read())
            mergedicts(tmp, timings)

    for dm in root_element.iter('delay_matrix'):
        pb_chain = get_pb_type_chain(dm)
        bel = pb_chain[-1]
        location = pb_chain[-2]
        site = remove_site_number(pb_chain[1])
        bel_timings = find_timings(timings, bel, location, site, bels)
        if bel_timings is None:
            continue

        dm.text = dm.text.format(**bel_timings)

    with open(args.out_arch, 'wb') as fp:
        fp.write(ET.tostring(arch_xml))

    #for dm in root_element.iter('delay_constant'):
    #    pb_chain = get_pb_type_chain(dm)
    #    print("found delay for", pb_chain)


if __name__ == "__main__":
    main()
