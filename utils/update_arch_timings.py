#!/usr/bin/env python3
import lxml.etree as ET
import argparse
from sdf_timing import sdfparse
from sdf_timing.utils import get_scale_seconds
from lib.pb_type import get_pb_type_chain
import re
import os
import sys

# Adds output to stderr to track if timing data for a particular BEL was found
# in bels.json
DEBUG = False

def eprint(*args, **kwargs):
    print(*args, file=sys.stderr, **kwargs)

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


def gen_all_possibilities(pattern):
    """
    Generates all possible combinations of a pattern if it contains a
    wildcard string in braces eg. "LUT[ABCD]" will yield in "LUTA", "LUTB"
    and so on.

    >>> list(gen_all_possibilities("LUT"))
    ['LUT']

    >>> list(gen_all_possibilities("LUT[ABCD]"))
    ['LUTA', 'LUTB', 'LUTC', 'LUTD']
    """

    # Match the regex
    match = re.match(r"(.*)\[([A-Za-z0-9]+)\](.*)", pattern)

    # Generate combinations
    if match is not None:
        for c in match.group(2):
            yield match.group(1) + c + match.group(3)

    # Not a regex
    else:
        yield pattern


def get_cell_types_and_instances(bel, location, site, bels):
    """This function searches for a bel type and instance
       translation between VPR and Vivado. The translation
       is defined in the `bels` dictionary. If translation
       is found a list of celltypes and bel instances is returned,
       None otherwise"""
    if site not in bels:
        if DEBUG:
            eprint(
                "Site '{}' not found among '{}'".format(
                    site, ", ".join(bels.keys())
                )
            )
        return None
    if bel not in bels[site]:
        if DEBUG:
            eprint(
                "Bel '{}' not found among '{}'".format(
                    bel, ", ".join(bels[site].keys())
                )
            )
        return None
    if location not in bels[site][bel]:
        if DEBUG:
            eprint(
                "Location '{}' not found among '{}'".format(
                    location, ", ".join(bels[site][bel].keys())
                )
            )
        return None

    # Generate a list of tuples (celltype, instance)
    cells = []
    for pattern in bels[site][bel][location]:
        for names in gen_all_possibilities(pattern):
            cells.append(tuple(names.split(".")))

    return cells


def find_timings(timings, bel, location, site, bels, corner, speed_type):
    """This function returns all the timings associated with
       the selected `bel` in `location` and `site`. If timings
       are not found, empty dict is returned"""

    def get_timing(cell, delay, corner, speed_type):
        """
        Gets timing for a particular cornet case. If not fount then chooses
        the next best one.
        """
        entries = cell[delay]['delay_paths'][corner.lower()]
        entry = entries.get(speed_type, None)

        if speed_type == 'min':
            if entry is None:
                entry = entries.get('avg', None)
            if entry is None:
                entry = entries.get('max', None)

        elif speed_type == 'avg':
            if entry is None:
                entry = entries.get('max', None)
            if entry is None:
                entry = entries.get('min', None)

        elif speed_type == 'max':
            if entry is None:
                entry = entries.get('avg', None)
            if entry is None:
                entry = entries.get('min', None)

        if entry is None:
            # if we failed with desired corner, try the opposite
            newcorner = 'FAST' if corner == 'SLOW' else 'SLOW'
            entry = get_timing(cell, delay, newcorner, speed_type)
            assert entry is not None, (delay, corner, speed_type)
        return entry

    # Get cells, reverse the list so former timings will be overwritten by
    # latter ones.
    cells = get_cell_types_and_instances(bel, location, site, bels)
    if cells is None:
        return None

    cells.reverse()

    # Gather CELLs
    cell = dict()
    for ct, inst in cells:
        cell = mergedicts(timings['cells'][ct][inst], cell)

    # Gather timings
    bel_timings = dict()
    for delay in cell:
        if cell[delay]['is_absolute']:
            entry = get_timing(cell, delay, corner.lower(), speed_type)
        elif cell[delay]['is_timing_check']:
            if cell[delay]['type'] == "setuphold":
                # 'setup' and 'hold' are identical
                entry = get_timing(cell, delay, 'setup', speed_type)
            else:
                entry = get_timing(cell, delay, 'nominal', speed_type)
        bel_timings[delay] = float(entry) * get_scale_seconds('1 ns')

    return bel_timings


def get_bel_timings(element, timings, bels, corner, speed_type):
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

    result = find_timings(
        timings, bel, location, site, bels, corner, speed_type
    )

    if DEBUG:
        print(site, bel, location, result is not None, file=sys.stderr)

    return result


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
            try:
                tmp = sdfparse.parse(fp.read())
            except Exception as ex:
                print("{}:".format(args.sdf_dir + '/' + f), file=sys.stderr)
                print(repr(ex), file=sys.stderr)
                raise
            mergedicts(tmp, timings)

    if DEBUG:
        with open("/tmp/dump.json", 'w') as fp:
            json.dump(timings, fp, indent=4)

    for dm in root_element.iter('delay_matrix'):
        if dm.attrib['type'] == 'max':
            bel_timings = get_bel_timings(dm, timings, bels, 'SLOW', 'max')
        elif dm.attrib['type'] == 'min':
            bel_timings = get_bel_timings(dm, timings, bels, 'FAST', 'min')
        else:
            assert dm.attrib['type']

        if bel_timings is None:
            continue

        dm.text = dm.text.format(**bel_timings)

    for dc in root_element.iter('delay_constant'):
        format_s = dc.attrib['max']
        max_tim = get_bel_timings(dc, timings, bels, 'SLOW', 'max')
        if max_tim is not None:
            dc.attrib['max'] = format_s.format(**max_tim)

        min_tim = get_bel_timings(dc, timings, bels, 'FAST', 'min')
        if min_tim is not None:
            dc.attrib['min'] = format_s.format(**min_tim)

    for tq in root_element.iter('T_clock_to_Q'):
        format_s = tq.attrib['max']
        max_tim = get_bel_timings(tq, timings, bels, 'SLOW', 'max')
        if max_tim is not None:
            tq.attrib['max'] = format_s.format(**max_tim)

        min_tim = get_bel_timings(tq, timings, bels, 'FAST', 'min')
        if min_tim is not None:
            tq.attrib['min'] = format_s.format(**min_tim)

    for ts in root_element.iter('T_setup'):
        bel_timings = get_bel_timings(ts, timings, bels, 'SLOW', 'max')
        if bel_timings is None:
            continue
        ts.attrib['value'] = ts.attrib['value'].format(**bel_timings)

    for th in root_element.iter('T_hold'):
        bel_timings = get_bel_timings(th, timings, bels, 'FAST', 'min')
        if bel_timings is None:
            continue
        th.attrib['value'] = th.attrib['value'].format(**bel_timings)

    with open(args.out_arch, 'wb') as fp:
        fp.write(ET.tostring(arch_xml))


if __name__ == "__main__":
    main()
