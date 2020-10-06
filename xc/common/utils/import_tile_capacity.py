""" Generates project xray. """
from lib.pb_type_xml import start_heterogeneous_tile, add_switchblock_locations
import lxml.etree as ET


def import_tile_capacity(args, db, pin_assignments, get_wires):

    tile_type = db.get_tile_type(args.tile_type)

    sites = {}

    pb_types = args.pb_types.split(',')

    equivalent_sites_dict = dict()
    for pb_type in pb_types:
        try:
            site, equivalent_sites = pb_type.split("/")
        except ValueError:
            site = pb_type
            equivalent_sites = None

        sites[site] = []

        equivalent_sites_dict[site] = equivalent_sites.split(
            ':'
        ) if equivalent_sites else []

    for site in tile_type.get_sites():
        if site.type not in sites.keys():
            continue

        site_type = db.get_site_type(site.type)
        input_wires, output_wires = get_wires(site, site_type)

        sites[site.type].append((site, input_wires, output_wires))

    tile_xml = start_heterogeneous_tile(
        args.tile_type,
        pin_assignments,
        sites,
        equivalent_sites_dict,
    )

    add_switchblock_locations(tile_xml)

    with open('{}/{}.tile.xml'.format(args.output_directory,
                                      args.tile_type.lower()), 'w') as f:
        tile_str = ET.tostring(tile_xml, pretty_print=True).decode('utf-8')
        f.write(tile_str)
