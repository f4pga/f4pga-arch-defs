""" Convert a PCF file into a VPR io.place file. """
from __future__ import print_function
import argparse
import eblif
import sys
import csv
import vpr_place_constraints
import lxml.etree as ET
import constraint
import prjxray.db

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
            "sources": frozenset(("O", )),
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
            "sources": frozenset(("O", )),
            "sinks": frozenset(),
            "type": "IBUF",
        },
    "IBUFDS_GTE2_VPR":
        {
            "sources": frozenset(("O", )),
            "sinks": frozenset(),
            "type": "IBUFDS_GTE2",
        },
    "GTPE2_COMMON_VPR":
        {
            "sources": frozenset(),
            "sinks": frozenset(("GTREFCLK0", "GTREFCLK1")),
            "type": "GTPE2_COMMON",
        },
    "GTPE2_CHANNEL_VPR":
        {
            "sources": frozenset(("TXOUTCLK", "RXOUTCLK")),
            "sinks": frozenset(),
            "type": "GTPE2_CHANNEL",
        },
}

GTP_PRIMITIVES = ["IBUFDS_GTE2", "GTPE2_COMMON", "GTPE2_CHANNEL"]


def eprint(*args, **kwargs):
    print(*args, file=sys.stderr, **kwargs)


def get_cmt(cmt_dict, loc):
    """Returns the clock region of an input location."""
    for k, v in cmt_dict.items():
        for (x, y) in v['vpr_loc']:
            if x == loc[0] and y == loc[1]:
                return v['clock_region']

    return None


class VprGrid(object):
    """This class contains a set of dictionaries helpful
    to have a fast lookup at the various coordinates mapping."""

    def __init__(self, vpr_grid_map, graph_limit):
        self.site_dict = dict()
        self.site_type_dict = dict()
        self.cmt_dict = dict()
        self.tile_dict = dict()
        self.vpr_loc_cmt = dict()
        self.canon_loc = dict()

        if graph_limit is not None:
            limits = graph_limit.split(",")
            xmin, ymin, xmax, ymax = [int(x) for x in limits]

        with open(vpr_grid_map, 'r') as csv_vpr_grid:
            csv_reader = csv.DictReader(csv_vpr_grid)
            for row in csv_reader:
                site_name = row['site_name']
                site_type = row['site_type']
                phy_tile = row['physical_tile']
                vpr_x = row['vpr_x']
                vpr_y = row['vpr_y']
                can_x = row['canon_x']
                can_y = row['canon_y']
                clk_region = row['clock_region']
                connected_to_site = row['connected_to_site']

                if graph_limit is not None:
                    if int(can_x) < xmin or int(can_x) > xmax:
                        continue
                    if int(can_y) < ymin or int(can_y) > ymax:
                        continue

                clk_region = None if not clk_region else int(clk_region)

                # Generating the site dictionary
                self.site_dict[site_name] = {
                    'type': site_type,
                    'tile': phy_tile,
                    'vpr_loc': (int(vpr_x), int(vpr_y)),
                    'canon_loc': (int(can_x), int(can_y)),
                    'clock_region': clk_region,
                    'connected_to_site': connected_to_site,
                }

                # Generating site types dictionary.
                if site_type not in self.site_type_dict:
                    self.site_type_dict[site_type] = []

                self.site_type_dict[site_type].append(
                    (site_name, phy_tile, clk_region)
                )

                # Generating the cmt dictionary.
                # Each entry has:
                #   - canonical location
                #   - a list of vpr coordinates
                #   - clock region
                if phy_tile not in self.cmt_dict:
                    self.cmt_dict[phy_tile] = {
                        'canon_loc': (int(can_x), int(can_y)),
                        'vpr_loc': [(int(vpr_x), int(vpr_y))],
                        'clock_region': clk_region,
                    }
                else:
                    self.cmt_dict[phy_tile]['vpr_loc'].append(
                        (int(vpr_x), int(vpr_y))
                    )

                # Generating the tile dictionary.
                # Each tile has a list of (site, site_type) pairs
                if phy_tile not in self.tile_dict:
                    self.tile_dict[phy_tile] = []

                self.tile_dict[phy_tile].append((site_name, site_type))

                self.vpr_loc_cmt[(int(vpr_x), int(vpr_y))] = clk_region

                self.canon_loc[(int(vpr_x),
                                int(vpr_y))] = (int(can_x), int(can_y))

    def get_site_dict(self):
        return self.site_dict

    def get_site_type_dict(self):
        return self.site_type_dict

    def get_cmt_dict(self):
        return self.cmt_dict

    def get_tile_dict(self):
        return self.tile_dict

    def get_vpr_loc_cmt(self):
        """
        Returns a dictionary containing the mapping between
        VPR physical locations to the belonging clock region.

        Dictionary content:
            - key   : (x, y) coordinate on the VPR grid
            - value : clock region corresponding to the (x, y) coordinates
        """
        return self.vpr_loc_cmt

    def get_canon_loc(self):
        return self.canon_loc


class ClockPlacer(object):
    def __init__(
            self,
            vpr_grid,
            io_locs,
            blif_data,
            roi,
            graph_limit,
            allow_bufg_logic_sources=False
    ):

        self.roi = roi
        self.cmt_to_bufg_tile = {}
        self.bufg_from_cmt = {
            'TOP': [],
            'BOT': [],
        }
        self.pll_cmts = set()
        self.gtp_cmts = set()

        cmt_dict = vpr_grid.get_cmt_dict()
        site_type_dict = vpr_grid.get_site_type_dict()

        try:
            top_cmt_tile = next(
                k for k, v in cmt_dict.items() if k.startswith('CLK_BUFG_TOP')
            )
            _, thresh_top_y = cmt_dict[top_cmt_tile]['canon_loc']
        except StopIteration:
            thresh_top_y = None

        try:
            bot_cmt_tile = next(
                k for k, v in cmt_dict.items() if k.startswith('CLK_BUFG_BOT')
            )
            _, thresh_bot_y = cmt_dict[bot_cmt_tile]['canon_loc']
        except StopIteration:
            thresh_bot_y = None

        if graph_limit is None:
            assert thresh_top_y is not None, "BUFG sites in the top half of the device not found"
            assert thresh_bot_y is not None, "BUFG sites in the bottom half of the device not found"
        else:
            assert thresh_top_y is not None or thresh_bot_y is not None, (
                "The device grid does not contain any BUFG sites"
            )

        for k, v in cmt_dict.items():
            clock_region = v['clock_region']
            x, y = v['canon_loc']
            if clock_region is None:
                continue
            elif clock_region in self.cmt_to_bufg_tile:
                continue
            elif thresh_top_y is not None and y <= thresh_top_y:
                self.cmt_to_bufg_tile[clock_region] = "TOP"
            elif thresh_bot_y is not None and y >= thresh_bot_y:
                self.cmt_to_bufg_tile[clock_region] = "BOT"

        for _, _, clk_region in site_type_dict['PLLE2_ADV']:
            self.pll_cmts.add(clk_region)

        if any(site in GTP_PRIMITIVES for site in site_type_dict):
            assert "IBUFDS_GTE2" in site_type_dict
            for _, _, clk_region in site_type_dict['IBUFDS_GTE2']:
                self.gtp_cmts.add(clk_region)

        self.input_pins = {}
        if not self.roi:
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

        if "subckt" not in blif_data.keys():
            return

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
                'subckt': bel,
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
                        assert_out = (
                            cname, port, self.clock_cmts[cname],
                            self.input_pins[port]
                        )
                        assert self.clock_cmts[cname] == self.input_pins[
                            port], assert_out
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
                if sink not in ports:
                    continue

                sink_net = ports[sink]
                if sink_net == '$true' or sink_net == '$false':
                    continue

                clock['sink_nets'].append(sink_net)

                if sink_net not in self.input_pins and sink_net not in self.clock_sources:

                    # Allow BUFGs to be driven by generic sources but only
                    # when enabled.
                    if bel == "BUFGCTRL_VPR" and allow_bufg_logic_sources:
                        continue

                    # The clock source comes from logic, disallow that
                    eprint(
                        "The clock net '{}' driving '{}' sources at logic which is not allowed!"
                        .format(sink_net, bel)
                    )
                    exit(-1)

                if sink_net in self.input_pins:
                    if sink_net not in self.clock_sources:
                        self.clock_sources[sink_net] = []

                self.clock_sources[sink_net].append(cname)

    def assign_cmts(self, vpr_grid, blocks, block_locs):
        """ Assign CMTs to subckt's that require it (e.g. BURF/PLL/MMCM). """

        problem = constraint.Problem()

        site_dict = vpr_grid.get_site_dict()
        vpr_loc_cmt = vpr_grid.get_vpr_loc_cmt()

        # Any clocks that have LOC's already defined should be respected.
        # Store the parent CMT in clock_cmts.
        for block, loc in block_locs.items():
            if block in self.clock_blocks:

                clock = self.clock_blocks[block]
                if CLOCKS[clock['subckt']]['type'] == 'BUFGCTRL':
                    pass
                else:
                    site = site_dict[loc.replace('"', '')]
                    assert site is not None, (block, loc)

                    clock_region_pkey = site["clock_region"]

                    if block in self.clock_cmts:
                        assert clock_region_pkey == self.clock_cmts[block], (
                            block, clock_region_pkey
                        )
                    else:
                        self.clock_cmts[block] = clock_region_pkey

        # Any clocks that were previously constrained must be preserved
        for block, (loc_x, loc_y, _) in blocks.items():
            if block in self.clock_blocks:

                clock = self.clock_blocks[block]
                if CLOCKS[clock['subckt']]['type'] == 'BUFGCTRL':
                    pass
                else:
                    cmt = vpr_loc_cmt[(loc_x, loc_y)]

                    if block in self.clock_cmts:
                        assert cmt == self.clock_cmts[block], (block, cmt)
                    else:
                        self.clock_cmts[block] = cmt

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

                if CLOCKS[clock['subckt']]['type'] == 'PLLE2_ADV':
                    problem.addConstraint(
                        lambda cmt: cmt in self.pll_cmts, (clock_name, )
                    )

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
            self, canon_grid, vpr_grid, loc_in_use, block_locs, blocks,
            grid_capacities
    ):
        self.assign_cmts(vpr_grid, blocks, block_locs)

        site_type_dict = vpr_grid.get_site_type_dict()

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
                    canon_grid, vpr_grid, loc, grid_capacities
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
        canon_grid, vpr_grid, site_name, grid_capacities
):
    site_name = site_name.replace('"', '')

    site_dict = vpr_grid.get_site_dict()
    canon_loc = vpr_grid.get_canon_loc()

    tile = site_dict[site_name]['tile']

    capacity = 0
    x, y = site_dict[site_name]['vpr_loc']
    canon_x, canon_y = canon_loc[(x, y)]

    if (x, y) in grid_capacities.keys():
        capacity = grid_capacities[(x, y)]

    if not capacity:
        # If capacity is zero it means that the site is out of
        # the ROI, hence the site needs to be skipped.
        return None
    elif capacity == 1:
        return (x, y, 0)
    else:
        sites = list(
            canon_grid.gridinfo_at_loc((canon_x, canon_y)).sites.keys()
        )
        assert capacity == len(sites), (tile, capacity, (x, y))

        instance_idx = sites.index(site_name)

        return (x, y, instance_idx)


def constrain_special_ios(
        canon_grid, vpr_grid, io_blocks, blif_data, blocks, place_constraints
):
    """
    There are special IOs which need extra handling when dealing with placement constraints.

    For instance, the IBUFDS_GTE2 primitive must be placed in correspondance with the location
    of its input PADs, as no other route exists other than that.

    This function reads the connectivity of the top level nets, which have been previously
    constrained, and correctly constrains those blocks which require special handling.
    """

    if "subckt" not in blif_data:
        return

    BEL_TYPES = ["IBUFDS_GTE2_VPR", "GTPE2_CHANNEL_VPR"]
    SPECIAL_IPADS = ["IPAD_GTP_VPR"]

    special_io_map = dict()
    for subckt in blif_data["subckt"]:
        if 'cname' not in subckt:
            continue
        bel = subckt['args'][0]

        if bel not in SPECIAL_IPADS:
            continue

        top_net = None
        renamed_net = None
        for port in subckt['args'][1:]:
            port_name, net = port.split("=")

            if port_name == "I":
                assert net in io_blocks, (net, io_blocks)
                top_net = net
            elif port_name == "O":
                renamed_net = net
            else:
                assert False, "ERROR: Special IPAD ports not recognized!"

        special_io_map[renamed_net] = top_net

    blocks_to_constrain = set()
    for subckt in blif_data["subckt"]:
        if 'cname' not in subckt:
            continue
        bel = subckt['args'][0]

        if bel not in BEL_TYPES:
            continue

        assert 'cname' in subckt and len(subckt['cname']) == 1, subckt
        cname = subckt['cname'][0]

        for port in subckt['args'][1:]:
            _, net = port.split("=")

            if net not in special_io_map:
                continue

            net = special_io_map[net]
            if net in io_blocks:
                x, y, z = io_blocks[net]

                canon_loc = vpr_grid.get_canon_loc()[(x, y)]

                gridinfo = canon_grid.gridinfo_at_loc(canon_loc)
                sites = list(gridinfo.sites.keys())
                site_name = sites[z]

                connected_io_site = vpr_grid.get_site_dict(
                )[site_name]['connected_to_site']
                assert connected_io_site, (site_name, bel, cname)

                new_z = sites.index(connected_io_site)
                loc = (x, y, new_z)

                blocks_to_constrain.add((cname, loc))

    for block, vpr_loc in blocks_to_constrain:
        place_constraints.constrain_block(
            block, vpr_loc, "Constraining block {}".format(block)
        )

        blocks[block] = vpr_loc


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
    parser.add_argument('--db_root', required=True)
    parser.add_argument('--part', required=True)
    parser.add_argument(
        "--blif",
        '-b',
        type=argparse.FileType('r'),
        required=True,
        help='BLIF / eBLIF file'
    )
    parser.add_argument('--roi', action='store_true', help='Using ROI')
    parser.add_argument(
        "--allow-bufg-logic-sources",
        action="store_true",
        help="When set allows BUFGs to be driven by logic"
    )
    parser.add_argument('--graph_limit', help='Graph limit parameters')

    args = parser.parse_args()

    db = prjxray.db.Database(args.db_root, args.part)
    canon_grid = db.grid()

    io_blocks = {}
    loc_in_use = set()
    for line in args.input:
        args.output.write(line)

        if line[0] == '#':
            continue
        block, x, y, z = line.strip().split()[0:4]

        io_blocks[block] = (int(x), int(y), int(z))
        loc_in_use.add(io_blocks[block])

    place_constraints = vpr_place_constraints.PlaceConstraints(args.net)
    place_constraints.load_loc_sites_from_net_file()

    grid_capacities = get_tile_capacities(args.arch)

    eblif_data = eblif.parse_blif(args.blif)

    vpr_grid = VprGrid(args.vpr_grid_map, args.graph_limit)

    # Constrain IO blocks and LOCed resources
    blocks = {}
    block_locs = {}
    for block, loc in place_constraints.get_loc_sites():
        vpr_loc = get_vpr_coords_from_site_name(
            canon_grid, vpr_grid, loc, grid_capacities
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

    # Constrain blocks directly connected to IO in the same x, y location
    constrain_special_ios(
        canon_grid, vpr_grid, io_blocks, eblif_data, blocks, place_constraints
    )

    # Constrain clock resources
    clock_placer = ClockPlacer(
        vpr_grid, io_blocks, eblif_data, args.roi, args.graph_limit,
        args.allow_bufg_logic_sources
    )
    if clock_placer.has_clock_nets():
        for block, loc in clock_placer.place_clocks(canon_grid, vpr_grid,
                                                    loc_in_use, block_locs,
                                                    blocks, grid_capacities):
            vpr_loc = get_vpr_coords_from_site_name(
                canon_grid, vpr_grid, loc, grid_capacities
            )
            place_constraints.constrain_block(
                block, vpr_loc, "Constraining clock block {}".format(block)
            )
    """ Constrain IDELAYCTRL sites

    Prior to the invocation of this script, the IDELAYCTRL sites must have been
    replicated accordingly to the IDELAY specifications.
    There can be three different usage combinations of IDELAYCTRL and IDELAYs in a design:
        1. IODELAYs and IDELAYCTRLs can be constrained to banks as needed,
           through an in-design LOC constraint.
           Manual replication of the constrained IDELAYCTRLs is necessary to provide a
           controller for each bank.
        2. IODELAYs and a single IDELAYCTRL can be left entirely unconstrained,
           becoming a default group. The IDELAYCTRLis replicated depending on bank usage.
           Replication must have happened prior to this step
        3. One or more IODELAY_GROUPs can be defined that contain IODELAYs and a single
           IDELAYCTRL each. These components can be otherwise unconstrained and the IDELAYCTRL
           for each group has to be replicated as needed (depending on bank usage).
           NOTE: IODELAY_GROUPS are not enabled at the moment.
    """
    idelayctrl_cmts = set()
    idelay_instances = place_constraints.get_used_instances("IDELAYE2")
    for inst in idelay_instances:
        x, y, z = io_blocks[inst]
        idelayctrl_cmt = vpr_grid.get_vpr_loc_cmt()[(x, y)]
        idelayctrl_cmts.add(idelayctrl_cmt)

    idelayctrl_instances = place_constraints.get_used_instances("IDELAYCTRL")

    assert len(idelayctrl_cmts) == len(
        idelayctrl_instances
    ), "The number of IDELAYCTRL blocks and IO banks with IDELAYs used do not match."

    idelayctrl_sites = dict()
    for site_name, _, clk_region in vpr_grid.get_site_type_dict(
    )['IDELAYCTRL']:
        if clk_region in idelayctrl_cmts:
            idelayctrl_sites[clk_region] = site_name

    # Check and remove user constrained IDELAYCTRLs
    for idelayctrl_block in idelayctrl_instances:
        if idelayctrl_block in blocks.keys():
            x, y, _ = blocks[idelayctrl_block]
            idelayctrl_cmt = vpr_grid.get_vpr_loc_cmt()[(x, y)]

            assert idelayctrl_cmt in idelayctrl_cmts

            idelayctrl_cmts.remove(idelayctrl_cmt)
            idelayctrl_instances.remove(idelayctrl_block)

    # TODO: Add possibility to bind IDELAY banks to IDELAYCTRL sites using
    #       the IDELAY_GROUP attribute.
    for cmt, idelayctrl_block in zip(idelayctrl_cmts, idelayctrl_instances):
        x, y = vpr_grid.get_site_dict()[idelayctrl_sites[cmt]]['vpr_loc']
        vpr_loc = (x, y, 0)

        place_constraints.constrain_block(
            idelayctrl_block, vpr_loc,
            "Constraining idelayctrl block {}".format(idelayctrl_block)
        )

    if len(idelayctrl_instances) > 0:
        print(
            "Warning: IDELAY_GROUPS parameters are currently being ignored!",
            file=sys.stderr
        )

    place_constraints.output_place_constraints(args.output)


if __name__ == '__main__':
    main()
