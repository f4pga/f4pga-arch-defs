import lxml.etree as ET
import argparse
from sdf_timing import sdfparse
from sdf_timing.utils import get_scale_seconds
import re
import os


def remove_site_number(site):
    number = re.search(r'\d+$', site)
    if number is not None:
        site = site[:-len(str(number.group()))]
    return site


def get_cell_type(bel, site):
    if bel.endswith("5LUT") and site == "SLICEL":
        return "LUT5"
    if bel.endswith("5LUT") and site == "SLICEM":
        return "LUT_OR_MEM5LRAM"

    return None


def find_timings(timings, bel, site):

    separator = "/"
    celltype = get_cell_type(bel, site)
    if celltype is None:
        return None

    cells = timings['cells'][celltype]
    cellsite = None
    for cell in cells:
        if (site in cell.split(separator)) and (bel in cell.split(separator)):
            cellsite = cell
            break
        if site == cell:
            cellsite = site
            # do not break here as we may still find more precise
            # site/bel location
    if cellsite is None:
        return None

    bel_timings = dict()
    for delay in cells[cellsite]:
        if not cells[cellsite][delay]['is_absolute']:
            continue
        entry = cells[cellsite][delay]['delay_paths']['slow']['max']
        bel_timings[delay] = float(entry) * get_scale_seconds('1 ns')

    return bel_timings


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

    parser = argparse.ArgumentParser()

    parser.add_argument(
        '--input_arch', required=True, help="Input arch.xml file"
    )
    parser.add_argument('--sdf_dir', required=True, help="SDF files directory")
    parser.add_argument(
        '--out_arch', required=True, help="Output arch.xml file"
    )

    args = parser.parse_args()

    arch_xml = ET.ElementTree()
    root_element = arch_xml.parse(args.input_arch)

    timings = dict()
    files = os.listdir(args.sdf_dir)
    for f in files:
        if not f.endswith('.sdf'):
            continue
        with open(args.sdf_dir + '/' + f, 'r') as fp:
            tmp = sdfparse.parse(fp.read())
            if 'cells' in timings:
                if 'cells' in tmp:
                    timings['cells'].update(tmp['cells'])
            else:
                timings.update(tmp)

    for dm in root_element.iter('delay_matrix'):
        pb_chain = get_pb_type_chain(dm)
        bel = pb_chain[-1]
        site = remove_site_number(pb_chain[1])
        bel_timings = find_timings(timings, bel, site)
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
