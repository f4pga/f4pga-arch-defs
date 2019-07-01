#!/usr/bin/env python3
import lxml.etree as ET
import argparse
from sdf_timing import sdfparse
from sdf_timing.utils import get_scale_seconds
from lib.pb_type import get_pb_type_chain
import re
import os


def mergedicts(source, destination):
    """This function recursively merges two dictionaries:
       `source` into `destination"""
    for key, value in source.items():
        if isinstance(value, dict):
            # get node or create one
            node = destination.setdefault(key, {})
            mergedicts(value, node)
        else:
            destination[key] = value

    return destination


def remove_site_number(site):
    """Some sites are numbered in the VPR arch definitions.
       This happens for e.g. SLICE0. This function removes
       trailing numbers from the name"""
    number = re.search(r'\d+$', site)
    if number is not None:
        site = site[:-len(str(number.group()))]
    return site


def get_cell_types_and_instance(bel, location, site, bels):
    """This function searches for a bel type and instance
       translation between VPR and Vivado. The translation
       is defined in the `bels` dictionary. If translation
       is found celltypes list and bel instance is returned,
       `None` otherwise"""
    if site not in bels:
        return None, None
    if bel not in bels[site]:
        return None, None
    if location not in bels[site][bel]:
        return None, None

    celltypes = (bels[site][bel][location]['celltype']).split()
    instance = bels[site][bel][location]['instance']

    return celltypes, instance


def find_timings(timings, bel, location, site, bels, routing=False):
    """This function returns all the timings associated with
       the selected `bel` in `location` and `site`. If timings
       are not found, `None` is returned"""
    if routing:
        celltype = [bel]
        instance = site
    else:
        celltype, instance = get_cell_types_and_instance(
            bel, location, site, bels
        )
        if (celltype is None) or (instance is None):
            return None
    bel_timings = dict()
    cell = dict()
    for ct in celltype:
        cell = mergedicts(timings['cells'][ct][instance], cell)
    for delay in cell:
        if cell[delay]['is_absolute']:
            entry = cell[delay]['delay_paths']['slow']['max']
        elif cell[delay]['is_timing_check']:
            entry = cell[delay]['delay_paths']['nominal']['max']
        bel_timings[delay] = float(entry) * get_scale_seconds('1 ns')

    return bel_timings


def get_bel_timings(element, timings, bels):
    """This function returns all the timings for an arch.xml
       `element`. It determines the bel location by traversing
       the pb_type chain"""
    pb_chain = get_pb_type_chain(element)
    if len(pb_chain) == 1:
        return None

    if 'max' in element.attrib and element.attrib['max'].startswith(
            '{interconnect'):
        bel = 'ROUTING_BEL'
    else:
        bel = pb_chain[-1]
    location = pb_chain[-2]
    site = remove_site_number(pb_chain[1])
    return find_timings(
        timings, bel, location, site, bels, bel == 'ROUTING_BEL'
    )


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

    with open("/tmp/dump.json", 'w') as fp:
        json.dump(timings, fp, indent=4)

    for dm in root_element.iter('delay_matrix'):
        bel_timings = get_bel_timings(dm, timings, bels)
        if bel_timings is None:
            continue
        dm.text = dm.text.format(**bel_timings)

    for dc in root_element.iter('delay_constant'):
        bel_timings = get_bel_timings(dc, timings, bels)
        if bel_timings is None:
            continue
        dc.attrib['max'] = dc.attrib['max'].format(**bel_timings)

    for tq in root_element.iter('T_clock_to_Q'):
        bel_timings = get_bel_timings(tq, timings, bels)
        if bel_timings is None:
            continue
        tq.attrib['max'] = tq.attrib['max'].format(**bel_timings)

    for ts in root_element.iter('T_setup'):
        bel_timings = get_bel_timings(ts, timings, bels)
        if bel_timings is None:
            continue
        ts.attrib['value'] = ts.attrib['value'].format(**bel_timings)

    for th in root_element.iter('T_hold'):
        bel_timings = get_bel_timings(th, timings, bels)
        if bel_timings is None:
            continue
        th.attrib['value'] = ts.attrib['value'].format(**bel_timings)

    with open(args.out_arch, 'wb') as fp:
        fp.write(ET.tostring(arch_xml))


if __name__ == "__main__":
    main()
