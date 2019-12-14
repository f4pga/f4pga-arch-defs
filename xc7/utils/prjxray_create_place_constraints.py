""" Convert a PCF file into a VPR io.place file. """
from __future__ import print_function
import argparse
import sys
import vpr_place_constraints
import sqlite3
import lxml.etree as ET


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
        help='The output constraints place file'
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

    args = parser.parse_args()

    for line in args.input:
        args.output.write(line)

    place_constraints = vpr_place_constraints.PlaceConstraints()
    place_constraints.load_loc_sites_from_net_file(args.net)

    grid_capacities = get_tile_capacities(args.arch)

    with sqlite3.connect(args.connection_database) as conn:
        for block, loc in place_constraints.get_loc_sites():
            vpr_loc = get_vpr_coords_from_site_name(conn, loc, grid_capacities)

            place_constraints.constrain_block(
                block, vpr_loc, "Constraining block {}".format(block)
            )

    place_constraints.output_place_constraints(args.output)


if __name__ == '__main__':
    main()
