""" Convert a PCF file into a VPR io.place file. """
from __future__ import print_function
import argparse
import eblif
import sys
import vpr_place_constraints
import sqlite3
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
        }
}


class ClockPlacer(object):
    def __init__(self, conn, io_locs, blif_data):
        c = conn.cursor()

        self.cmt_to_bufg_tile = {}
        self.bufg_from_cmt = {
            'TOP': [],
            'BOT': [],
        }

        for (cmt, ) in c.execute("""
SELECT DISTINCT clock_region_pkey
FROM phy_tile
WHERE grid_y <= (
    SELECT grid_y
    FROM phy_tile
    WHERE name LIKE "CLK_BUFG_TOP%"
)
AND
    clock_region_pkey IS NOT NULL;
    """):
            self.cmt_to_bufg_tile[cmt] = "TOP"
            self.bufg_from_cmt["TOP"].append(cmt)

        for (cmt, ) in c.execute("""
SELECT DISTINCT clock_region_pkey
FROM phy_tile
WHERE grid_y >= (
    SELECT grid_y
    FROM phy_tile
    WHERE name LIKE "CLK_BUFG_BOT%"
)
AND
    clock_region_pkey IS NOT NULL;
    """):
            self.cmt_to_bufg_tile[cmt] = "BOT"
            self.bufg_from_cmt["BOT"].append(cmt)

        self.input_pins = {}
        for input_pin in blif_data['inputs']['args']:
            loc = io_locs[input_pin]
            c.execute(
                """
SELECT DISTINCT clock_region_pkey
FROM phy_tile
WHERE pkey IN (
    SELECT phy_tile_pkey
    FROM tile_map
    WHERE tile_pkey IN (
        SELECT pkey FROM tile WHERE grid_x = ? AND grid_y = ?
    )
);""", (loc[0], loc[1])
            )
            self.input_pins[input_pin] = c.fetchone()[0]

        self.clock_blocks = {}

        self.clock_sources = {}
        self.clock_sources_cname = {}

        self.clock_cmts = {}

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
                assert sink in ports, cname
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

    def assign_cmts(self, conn, blocks):
        """ Assign CMTs to subckt's that require it (e.g. BURF/PLL/MMCM). """

        problem = constraint.Problem()

        for clock_name, clock in self.clock_blocks.items():
            if CLOCKS[clock['subckt']]['type'] == 'BUFGCTRL':
                problem.addVariable(
                    clock_name, list(self.bufg_from_cmt.keys())
                )
            else:
                problem.addVariable(
                    clock_name, list(self.cmt_to_bufg_tile.keys())
                )

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

        c = conn.cursor()
        for block, loc in blocks.items():
            if block in self.clock_blocks:

                clock = self.clock_blocks[block]
                if CLOCKS[clock['subckt']]['type'] == 'BUFGCTRL':
                    pass
                else:
                    c.execute(
                        """
SELECT clock_region_pkey
FROM phy_tile
WHERE pkey IN (
    SELECT phy_tile_pkey
    FROM site_instance
    WHERE name = ?
);
    """, (loc.replace('"', ''), )
                    )
                    result = c.fetchone()
                    assert result is not None, (block, loc)
                    clock_region_pkey = result[0]

                    problem.addConstraint(
                        lambda clock: clock == clock_region_pkey, (block, )
                    )

        solutions = problem.getSolutions()
        assert len(solutions) > 0

        self.clock_cmts = solutions[0]

    def place_clocks(
            self, conn, loc_in_use, block_locs, blocks, grid_capacities
    ):
        self.assign_cmts(conn, block_locs)

        c = conn.cursor()

        # Key is (type, clock_region_pkey)
        available_placements = {}
        available_locs = {}
        vpr_locs = {}

        for clock_type in CLOCKS.values():
            c.execute(
                """
SELECT site_instance.name, phy_tile.name, phy_tile.clock_region_pkey
FROM site_instance
INNER JOIN site ON site_instance.site_pkey = site.pkey
INNER JOIN site_type ON site.site_type_pkey = site_type.pkey
INNER JOIN phy_tile ON site_instance.phy_tile_pkey = phy_tile.pkey
WHERE site_type.name = ?;""", (clock_type['type'], )
            )

            for loc, tile_name, clock_region_pkey in c:
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
                    conn, loc, grid_capacities
                )
                available_locs[key].append(vpr_loc)
                vpr_locs[loc] = vpr_loc

        for clock_name, clock in self.clock_blocks.items():
            # All clocks should have an assigned CMTs at this point.
            assert clock_name in self.clock_cmts, clock_name

            bel_type = CLOCKS[clock['subckt']]['type']

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


def get_tile_capacities(arch_xml_filename):
    arch = ET.parse(arch_xml_filename, ET.XMLParser(remove_blank_text=True))
    root = arch.getroot()

    tile_capacities = {}
    for el in root.iter('tile'):
        tile_name = el.attrib['name']
        capacity = 1

        if 'capacity' in el.attrib:
            capacity = int(el.attrib['capacity'])

        tile_capacities[tile_name] = capacity

    grid = {}
    for el in root.iter('single'):
        x = int(el.attrib['x'])
        y = int(el.attrib['y'])
        grid[(x, y)] = tile_capacities[el.attrib['type']]

    return grid


def get_vpr_coords_from_site_name(conn, site_name, grid_capacities):
    site_name = site_name.replace('"', '')

    cur = conn.cursor()
    cur.execute(
        """
SELECT DISTINCT tile.pkey, tile.grid_x, tile.grid_y
FROM site_instance
INNER JOIN wire_in_tile
ON
  site_instance.site_pkey = wire_in_tile.site_pkey
INNER JOIN wire
ON
  wire.phy_tile_pkey = site_instance.phy_tile_pkey
AND
  wire_in_tile.pkey = wire.wire_in_tile_pkey
INNER JOIN tile
ON tile.pkey = wire.tile_pkey
WHERE
  site_instance.name = ?;""", (site_name, )
    )

    results = cur.fetchall()
    assert len(results) == 1

    tile_pkey, x, y = results[0]

    capacity = grid_capacities[(x, y)]

    if capacity == 1:
        return (x, y, 0)
    else:
        cur.execute(
            """
SELECT site_instance.name
FROM site_instance
INNER JOIN site ON site_instance.site_pkey = site.pkey
INNER JOIN site_type ON site.site_type_pkey = site_type.pkey
WHERE
  site_instance.phy_tile_pkey IN (
    SELECT
      phy_tile_pkey
    FROM
      tile
    WHERE
      pkey = ?
  )
AND
  site_instance.site_pkey IN (
    SELECT
      wire_in_tile.site_pkey
    FROM
      wire_in_tile
    WHERE
      wire_in_tile.pkey IN (
      SELECT
        wire_in_tile_pkey
      FROM
        wire
      WHERE
        tile_pkey = ?
      )
    )
ORDER BY site_type.name, site_instance.x_coord, site_instance.y_coord;
            """, (tile_pkey, tile_pkey)
        )

        instance_idx = None
        for idx, (a_site_name, ) in enumerate(cur):
            if a_site_name == site_name:
                assert instance_idx is None, (tile_pkey, site_name)
                instance_idx = idx
                break

        assert instance_idx is not None, (tile_pkey, site_name)

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
        '--connection_database',
        help='Database of fabric connectivity',
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

    with sqlite3.connect(args.connection_database) as conn:
        blocks = {}
        block_locs = {}
        for block, loc in place_constraints.get_loc_sites():
            vpr_loc = get_vpr_coords_from_site_name(conn, loc, grid_capacities)
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

        clock_placer = ClockPlacer(conn, io_blocks, eblif_data)
        for block, loc in clock_placer.place_clocks(
                conn, loc_in_use, block_locs, blocks, grid_capacities):
            vpr_loc = get_vpr_coords_from_site_name(conn, loc, grid_capacities)
            place_constraints.constrain_block(
                block, vpr_loc, "Constraining clock block {}".format(block)
            )

    place_constraints.output_place_constraints(args.output)


if __name__ == '__main__':
    main()
