""" Convert a PCF file into a VPR io.place file. """
from __future__ import print_function
import argparse
import eblif
import sys
import vpr_place_constraints
import lxml.etree as ET
import constraint

CLOCKS = {
    "PLLE2_ADV_VPR":
        {
            "sinks":
                frozenset(("CLKFBIN", "CLKIN1", "CLKIN2", "DCLK")),
            "sources":
                frozenset(
                    (
                        "CLKFBOUT", "CLKOUT0", "CLKOUT1", "CLKOUT2", "CLKOUT3",
                        "CLKOUT4", "CLKOUT5"
                    )
                ),
            "type":
                "PLLE2_ADV",
        },
    "BUFGCTRL_VPR":
        {
            "sinks": frozenset(("I0", "I1")),
            "sources": frozenset(("O")),
            "type": "BUFGCTRL",
        },
    "PS7_VPR":
        {
            "sinks":
                frozenset(
                    (
                        "DMA0ACLK",
                        "DMA1ACLK",
                        "DMA2ACLK",
                        "DMA3ACLK",
                        "EMIOENET0GMIIRXCLK",
                        "EMIOENET0GMIITXCLK",
                        "EMIOENET1GMIIRXCLK",
                        "EMIOENET1GMIITXCLK",
                        "EMIOSDIO0CLKFB",
                        "EMIOSDIO1CLKFB",
                        "EMIOSPI0SCLKI",
                        "EMIOSPI1SCLKI",
                        "EMIOTRACECLK",
                        "EMIOTTC0CLKI[0]",
                        "EMIOTTC0CLKI[1]",
                        "EMIOTTC0CLKI[2]",
                        "EMIOTTC1CLKI[0]",
                        "EMIOTTC1CLKI[1]",
                        "EMIOTTC1CLKI[2]",
                        "EMIOWDTCLKI",
                        "FCLKCLKTRIGN[0]",
                        "FCLKCLKTRIGN[1]",
                        "FCLKCLKTRIGN[2]",
                        "FCLKCLKTRIGN[3]",
                        "MAXIGP0ACLK",
                        "MAXIGP1ACLK",
                        "SAXIACPACLK",
                        "SAXIGP0ACLK",
                        "SAXIGP1ACLK",
                        "SAXIHP0ACLK",
                        "SAXIHP1ACLK",
                        "SAXIHP2ACLK",
                        "SAXIHP3ACLK",
                    )
                ),
            "sources":
                frozenset(
                    (
                        "FCLKCLK[0]",
                        "FCLKCLK[1]",
                        "FCLKCLK[2]",
                        "FCLKCLK[3]",
                        "EMIOSDIO0CLK",
                        "EMIOSDIO1CLK",
                        # There are also EMIOSPI[01]CLKO and EMIOSPI[01]CLKTN but seem
                        # to be more of a GPIO outputs than clock sources for the FPGA
                        # fabric.
                    )
                ),
            "type":
                "PS7",
        },
    "IBUF_VPR":
        {
            "sources": frozenset(("O")),
            "sinks": frozenset(),
            "type": "IBUF",
        }
}


class ClockPlacer(object):
    def __init__(self, cmt_dict, io_locs, blif_data):
        def get_cmt(cmt_dict, loc):
            for k, v in cmt_dict.items():
                for (x, y) in v['vpr_loc']:
                    if x == loc[0] and y == loc[1]:
                        return v['clock_region']

            return None

        self.cmt_to_bufg_tile = {}
        self.bufg_from_cmt = {
            'TOP': [],
            'BOT': [],
        }

        top_cmt_tile = next(
            k for k, v in cmt_dict.items() if k.startswith('CLK_BUFG_TOP')
        )
        bot_cmt_tile = next(
            k for k, v in cmt_dict.items() if k.startswith('CLK_BUFG_BOT')
        )

        _, thresh_top_y = cmt_dict[top_cmt_tile]['canon_loc']
        _, thresh_bot_y = cmt_dict[bot_cmt_tile]['canon_loc']

        for k, v in cmt_dict.items():
            clock_region = v['clock_region']
            x, y = v['canon_loc']
            if clock_region is None:
                continue
            elif clock_region in self.cmt_to_bufg_tile:
                continue
            elif y <= thresh_top_y:
                self.cmt_to_bufg_tile[clock_region] = "TOP"
            elif y >= thresh_bot_y:
                self.cmt_to_bufg_tile[clock_region] = "BOT"

        self.input_pins = {}
        for input_pin in blif_data['inputs']['args']:
            if input_pin not in io_locs.keys():
                continue

            loc = io_locs[input_pin]

            cmt = get_cmt(cmt_dict, loc)

            assert cmt is not None, loc

            self.input_pins[input_pin] = cmt

        self.clock_blocks = {}

        self.clock_sources = {}
        self.clock_sources_cname = {}

        self.clock_cmts = {}

        if "subckt" in blif_data.keys():
            for subckt in blif_data["subckt"]:
                if 'cname' not in subckt:
                    continue
                bel = subckt['args'][0]

                assert 'cname' in subckt and len(subckt['cname']) == 1, subckt

                if bel not in CLOCKS:
                    continue

                cname = subckt['cname'][0]

                clock = {
                    'name': cname,
                    'subckt': subckt['args'][0],
                    'sink_nets': [],
                    'source_nets': [],
                }

                sources = CLOCKS[bel]['sources']

                ports = dict(
                    arg.split('=', maxsplit=1) for arg in subckt['args'][1:]
                )

                for source in sources:
                    source_net = ports[source]
                    if source_net == '$true' or source_net == '$false':
                        continue

                    self.clock_sources[source_net] = []
                    self.clock_sources_cname[source_net] = cname
                    clock['source_nets'].append(source_net)

                self.clock_blocks[cname] = clock

                # Both PS7 and BUFGCTRL has specialized constraints,
                # do not bind based on input pins.
                if bel not in ['PS7_VPR', 'BUFGCTRL_VPR']:
                    for port in ports.values():
                        if port not in io_locs:
                            continue

                        if cname in self.clock_cmts:
                            assert self.clock_cmts[cname] == self.input_pins[
                                port], (
                                    cname, port, self.clock_cmts[cname],
                                    self.input_pins[port]
                                )
                        else:
                            self.clock_cmts[cname] = self.input_pins[port]

            for subckt in blif_data["subckt"]:
                if 'cname' not in subckt:
                    continue

                bel = subckt['args'][0]
                if bel not in CLOCKS:
                    continue

                sinks = CLOCKS[bel]['sinks']
                ports = dict(
                    arg.split('=', maxsplit=1) for arg in subckt['args'][1:]
                )

                assert 'cname' in subckt and len(subckt['cname']) == 1, subckt
                cname = subckt['cname'][0]
                clock = self.clock_blocks[cname]

                for sink in sinks:
                    assert sink in ports, (
                        cname,
                        sink,
                    )
                    sink_net = ports[sink]
                    if sink_net == '$true' or sink_net == '$false':
                        continue

                    clock['sink_nets'].append(sink_net)

                    assert sink_net in self.input_pins or sink_net in self.clock_sources, (
                        sink_net, self.input_pins, self.clock_sources.keys()
                    )

                    if sink_net in self.input_pins:
                        if sink_net not in self.clock_sources:
                            self.clock_sources[sink_net] = []

                    self.clock_sources[sink_net].append(cname)

    def assign_cmts(self, site_dict, blocks):
        """ Assign CMTs to subckt's that require it (e.g. BURF/PLL/MMCM). """

        problem = constraint.Problem()

        # Any clocks that have LOC's already defined should be respected.
        # Store the parent CMT in clock_cmts.
        for block, loc in blocks.items():
            if block in self.clock_blocks:

                clock = self.clock_blocks[block]
                if CLOCKS[clock['subckt']]['type'] == 'BUFGCTRL':
                    pass
                else:
                    clock_region_pkey = site_dict[loc.replace('"', '')]
                    assert clock_region_pkey is not None, (block, loc)

                    if block in self.clock_cmts:
                        assert clock_region_pkey == self.clock_cmts[block], (
                            block, clock_region_pkey
                        )
                    else:
                        self.clock_cmts[block] = clock_region_pkey

        # Non-clock IBUF's increase the solution space if they are not
        # constrainted by a LOC.  Given that non-clock IBUF's don't need to
        # solved for, remove them.
        unused_blocks = set()
        any_variable = False
        for clock_name, clock in self.clock_blocks.items():
            used = False
            if CLOCKS[clock['subckt']]['type'] != 'IBUF':
                used = True

            for source_net in clock['source_nets']:
                if len(self.clock_sources[source_net]) > 0:
                    used = True
                    break

            if not used:
                unused_blocks.add(clock_name)
                continue

            if CLOCKS[clock['subckt']]['type'] == 'BUFGCTRL':
                problem.addVariable(
                    clock_name, list(self.bufg_from_cmt.keys())
                )
                any_variable = True
            else:
                # Constrained objects have a domain of 1
                if clock_name in self.clock_cmts:
                    problem.addVariable(
                        clock_name, (self.clock_cmts[clock_name], )
                    )
                    any_variable = True
                else:
                    problem.addVariable(
                        clock_name, list(self.cmt_to_bufg_tile.keys())
                    )
                    any_variable = True

        # Remove unused blocks from solutions.
        for clock_name in unused_blocks:
            del self.clock_blocks[clock_name]

        for net in self.clock_sources:
            for clock_name in self.clock_sources[net]:
                clock = self.clock_blocks[clock_name]

                if net in self.input_pins:
                    if CLOCKS[clock['subckt']]['type'] == 'BUFGCTRL':
                        # BUFGCTRL do not get a CMT, instead they get either top or
                        # bottom.
                        problem.addConstraint(
                            lambda clock: clock == self.cmt_to_bufg_tile[
                                self.input_pins[net]], (clock_name, )
                        )
                    else:
                        problem.addConstraint(
                            lambda clock: clock == self.input_pins[net],
                            (clock_name, )
                        )
                else:
                    source_clock_name = self.clock_sources_cname[net]
                    source_block = self.clock_blocks[source_clock_name]
                    is_net_bufg = CLOCKS[source_block['subckt']
                                         ]['type'] == 'BUFGCTRL'
                    if is_net_bufg:
                        continue

                    if CLOCKS[clock['subckt']]['type'] == 'BUFGCTRL':
                        # BUFG's need to be in the right half.
                        problem.addConstraint(
                            lambda source, sink_bufg: self.cmt_to_bufg_tile[
                                source] == sink_bufg,
                            (source_clock_name, clock_name)
                        )
                    else:
                        problem.addConstraint(
                            lambda source, sink: source == sink,
                            (source_clock_name, clock_name)
                        )

        if any_variable:
            solutions = problem.getSolutions()
            assert len(solutions) > 0

            self.clock_cmts.update(solutions[0])

    def place_clocks(
            self, site_dict, site_type_dict, tile_dict, loc_in_use, block_locs,
            blocks, grid_capacities
    ):
        self.assign_cmts(site_dict, block_locs)

        # Key is (type, clock_region_pkey)
        available_placements = {}
        available_locs = {}
        vpr_locs = {}

        for clock_type in CLOCKS.values():
            if clock_type == 'IBUF' or clock_type['type'] not in site_type_dict:
                continue

            for loc, tile_name, clock_region_pkey in site_type_dict[
                    clock_type['type']]:
                if clock_type['type'] == 'BUFGCTRL':
                    if '_TOP_' in tile_name:
                        key = (clock_type['type'], 'TOP')
                    elif '_BOT_' in tile_name:
                        key = (clock_type['type'], 'BOT')
                else:
                    key = (clock_type['type'], clock_region_pkey)

                if key not in available_placements:
                    available_placements[key] = []
                    available_locs[key] = []

                available_placements[key].append(loc)
                vpr_loc = get_vpr_coords_from_site_name(
                    site_dict, tile_dict, loc, grid_capacities
                )

                if vpr_loc is None:
                    continue

                available_locs[key].append(vpr_loc)
                vpr_locs[loc] = vpr_loc

        for clock_name, clock in self.clock_blocks.items():

            # All clocks should have an assigned CMTs at this point.
            assert clock_name in self.clock_cmts, clock_name

            bel_type = CLOCKS[clock['subckt']]['type']

            # Skip LOCing the PS7. There is only one
            if bel_type == "PS7":
                continue

            if bel_type == 'IBUF':
                continue

            key = (bel_type, self.clock_cmts[clock_name])

            if clock_name in blocks:
                # This block has a LOC constraint from the user, verify that
                # this LOC constraint makes sense.
                assert blocks[clock_name] in available_locs[key], (
                    clock_name, blocks[clock_name], available_locs[key]
                )
                continue

            loc = None
            for potential_loc in sorted(available_placements[key]):
                # This block has no existing placement, make one
                vpr_loc = vpr_locs[potential_loc]
                if vpr_loc in loc_in_use:
                    continue

                loc_in_use.add(vpr_loc)
                yield clock_name, potential_loc
                loc = potential_loc
                break

            # No free LOC!!!
            assert loc is not None, (clock_name, available_placements[key])

    def has_clock_nets(self):
        return self.clock_sources


def get_tile_capacities(arch_xml_filename):
    arch = ET.parse(arch_xml_filename, ET.XMLParser(remove_blank_text=True))
    root = arch.getroot()

    tile_capacities = {}
    for el in root.iter('tile'):
        tile_name = el.attrib['name']

        tile_capacities[tile_name] = 0

        for sub_tile in el.iter('sub_tile'):
            capacity = 1

            if 'capacity' in sub_tile.attrib:
                capacity = int(sub_tile.attrib['capacity'])

            tile_capacities[tile_name] += capacity

    grid = {}
    for el in root.iter('single'):
        x = int(el.attrib['x'])
        y = int(el.attrib['y'])
        grid[(x, y)] = tile_capacities[el.attrib['type']]

    return grid


def get_vpr_coords_from_site_name(
        site_dict, tile_dict, site_name, grid_capacities
):
    site_name = site_name.replace('"', '')
    tile = site_dict[site_name]['tile']

    capacity = 0
    x, y = site_dict[site_name]['vpr_loc']

    capacity = grid_capacities[(x, y)]

    if not capacity:
        # If capacity is zero it means that the site is out of
        # the ROI, hence the site needs to be skipped.
        return None
    elif capacity == 1:
        return (x, y, 0)
    else:
        sites = tile_dict[tile]
        assert capacity == len(sites), (tile, capacity, (x, y))

        instance_idx = None
        for idx, (a_site_name, syte_type) in enumerate(sites):
            if a_site_name == site_name:
                assert instance_idx is None, (tile, site_name)
                instance_idx = idx
                break

        assert instance_idx is not None, (tile, site_name)

        return (x, y, instance_idx)


def main():
    parser = argparse.ArgumentParser(
        description='Convert a PCF file into a VPR io.place file.'
    )
    parser.add_argument(
        "--input",
        '-i',
        "-I",
        type=argparse.FileType('r'),
        default=sys.stdout,
        help='The input constraints place file'
    )
    parser.add_argument(
        "--output",
        '-o',
        "-O",
        type=argparse.FileType('w'),
        default=sys.stdout,
        help='The output constraints place file'
    )
    parser.add_argument(
        "--net",
        '-n',
        type=argparse.FileType('r'),
        required=True,
        help='top.net file'
    )
    parser.add_argument(
        '--vpr_grid_map',
        help='Map of canonical to VPR grid locations',
        required=True
    )
    parser.add_argument('--arch', help='Arch XML', required=True)
    parser.add_argument(
        "--blif",
        '-b',
        type=argparse.FileType('r'),
        required=True,
        help='BLIF / eBLIF file'
    )

    args = parser.parse_args()

    io_blocks = {}
    loc_in_use = set()
    for line in args.input:
        args.output.write(line)

        if line[0] == '#':
            continue
        block, x, y, z = line.strip().split()[0:4]

        io_blocks[block] = (int(x), int(y), int(z))
        loc_in_use.add(io_blocks[block])

    place_constraints = vpr_place_constraints.PlaceConstraints()
    place_constraints.load_loc_sites_from_net_file(args.net)

    grid_capacities = get_tile_capacities(args.arch)

    eblif_data = eblif.parse_blif(args.blif)

    site_dict = dict()
    site_type_dict = dict()
    cmt_dict = dict()
    tile_dict = dict()
    with open(args.vpr_grid_map, 'r') as f:
        # Skip first header row
        next(f)
        for l in f:
            site_name, site_type, phy_tile, vpr_x, vpr_y, can_x, can_y, clk_region = l.split(
                ','
            )

            clk_region = clk_region.rstrip()
            clk_region = None if clk_region == 'None' else int(clk_region)

            site_dict[site_name] = {
                'type': site_type,
                'tile': phy_tile,
                'vpr_loc': (int(vpr_x), int(vpr_y)),
                'canon_loc': (int(can_x), int(can_y)),
                'clock_region': clk_region,
            }

            if site_type not in site_type_dict:
                site_type_dict[site_type] = []

            site_type_dict[site_type].append((site_name, phy_tile, clk_region))

            if phy_tile not in cmt_dict:
                cmt_dict[phy_tile] = {
                    'canon_loc': (int(can_x), int(can_y)),
                    'vpr_loc': [(int(vpr_x), int(vpr_y))],
                    'clock_region': clk_region,
                }
            else:
                cmt_dict[phy_tile]['vpr_loc'].append((int(vpr_x), int(vpr_y)))

            if phy_tile not in tile_dict:
                tile_dict[phy_tile] = []

            tile_dict[phy_tile].append((site_name, site_type))

    blocks = {}
    block_locs = {}
    for block, loc in place_constraints.get_loc_sites():
        vpr_loc = get_vpr_coords_from_site_name(
            site_dict, tile_dict, loc, grid_capacities
        )
        loc_in_use.add(vpr_loc)

        if block in io_blocks:
            assert io_blocks[block] == vpr_loc, (
                block, vpr_loc, io_blocks[block]
            )

        blocks[block] = vpr_loc
        block_locs[block] = loc

        place_constraints.constrain_block(
            block, vpr_loc, "Constraining block {}".format(block)
        )

    clock_placer = ClockPlacer(cmt_dict, io_blocks, eblif_data)
    if clock_placer.has_clock_nets():
        for block, loc in clock_placer.place_clocks(
                site_dict, site_type_dict, tile_dict, loc_in_use, block_locs,
                blocks, grid_capacities):
            vpr_loc = get_vpr_coords_from_site_name(
                site_dict, tile_dict, loc, grid_capacities
            )
            place_constraints.constrain_block(
                block, vpr_loc, "Constraining clock block {}".format(block)
            )

    place_constraints.output_place_constraints(args.output)


if __name__ == '__main__':
    main()
