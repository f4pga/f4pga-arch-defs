import os
import lxml.etree as ET

XI_URL = "http://www.w3.org/2001/XInclude"
XI_INCLUDE = "{%s}include" % XI_URL

VPR_TILE_PREFIX = 'BLK-TL-'


def add_vpr_tile_prefix(tile):
    """ Add tile prefix.

    This avoids namespace collision when embedding a site (e.g. SLICEL) as a
    tile.
    """
    return VPR_TILE_PREFIX + tile


def object_ref(pb_name, pin_name, pb_idx=None, pin_idx=None):
    pb_addr = ''
    if pb_idx is not None:
        pb_addr = '[{}]'.format(pb_idx)

    pin_addr = ''
    if pin_idx is not None:
        pin_addr = '[{}]'.format(pin_idx)

    return '{}{}.{}{}'.format(pb_name, pb_addr, pin_name, pin_addr)


def add_pinlocations(
        tile_name, xml, fc_xml, pin_assignments, wires, sub_tile_name=None
):
    """ Adds the pin locations.

    It requires the ports of the physical tile which are retrieved
    by the pb_type.xml definition.
    """
    pinlocations_xml = ET.SubElement(
        xml, 'pinlocations', {
            'pattern': 'custom',
        }
    )

    sides = {}
    for pin in wires:
        for side in pin_assignments['pin_directions'][tile_name][pin]:
            if side not in sides:
                sides[side] = []

            if sub_tile_name is not None:
                name = sub_tile_name
            else:
                name = tile_name

            sides[side].append(object_ref(add_vpr_tile_prefix(name), pin))

    for side, pins in sides.items():
        ET.SubElement(pinlocations_xml, 'loc', {
            'side': side.lower(),
        }).text = ' '.join(pins)

    direct_pins = set()
    for direct in pin_assignments['direct_connections']:
        if direct['from_pin'].split('.')[0] == tile_name:
            direct_pins.add(direct['from_pin'].split('.')[1])

        if direct['to_pin'].split('.')[0] == tile_name:
            direct_pins.add(direct['to_pin'].split('.')[1])

    for fc_override in direct_pins:
        ET.SubElement(
            fc_xml, 'fc_override', {
                'fc_type': 'frac',
                'fc_val': '0.0',
                'port_name': fc_override,
            }
        )


def add_fc(xml):
    fc_xml = ET.SubElement(
        xml, 'fc', {
            'in_type': 'abs',
            'in_val': '2',
            'out_type': 'abs',
            'out_val': '2',
        }
    )

    return fc_xml


def add_switchblock_locations(xml):
    ET.SubElement(xml, 'switchblock_locations', {
        'pattern': 'all',
    })


def start_sub_tile(sub_tile_name, pin_assignments, input_wires, output_wires):
    sub_tile_xml = ET.Element(
        'sub_tile', {
            'name': add_vpr_tile_prefix(sub_tile_name),
            'capacity': "1",
        }
    )

    # Input definitions for the TILE
    sub_tile_xml.append(ET.Comment(" Sub Tile Inputs "))
    for name in sorted(input_wires):
        input_type = 'input'

        if name.startswith('CLK_BUFG_'):
            if name.endswith('I0') or name.endswith('I1'):
                input_type = 'clock'
        elif 'CLK' in name:
            input_type = 'clock'

        ET.SubElement(
            sub_tile_xml,
            input_type,
            {
                'name': name,
                'num_pins': '1'
            },
        )

    # Output definitions for the TILE
    sub_tile_xml.append(ET.Comment(" Sub Tile Outputs "))
    for name in sorted(output_wires):
        ET.SubElement(
            sub_tile_xml,
            'output',
            {
                'name': name,
                'num_pins': '1'
            },
        )

    return sub_tile_xml


def start_tile(
        tile_name,
        pin_assignments,
        input_wires=None,
        output_wires=None,
        sites=None,
):
    """ Starts a pb_type by adding input, clock and output tags. """
    assert bool(input_wires) == bool(output_wires)
    assert bool(sites) != bool(input_wires)

    tile_xml = ET.Element(
        'tile',
        {
            'name': add_vpr_tile_prefix(tile_name),
        },
        nsmap={'xi': XI_URL},
    )

    if sites is not None:
        for site_type in sites.keys():
            num_sub_tile = 0
            for site in sites[site_type]:
                sub_tile_name = "{}_{}_{}".format(
                    tile_name, site_type, num_sub_tile
                )

                site, input_wires, output_wires = site

                sub_tile_xml = start_sub_tile(
                    sub_tile_name, pin_assignments, input_wires, output_wires
                )

                fc_xml = add_fc(sub_tile_xml)

                add_pinlocations(
                    tile_name,
                    sub_tile_xml,
                    fc_xml,
                    pin_assignments,
                    set(input_wires) | set(output_wires),
                    sub_tile_name=sub_tile_name
                )

                equivalent_sites_xml = ET.Element('equivalent_sites')

                site_xml = ET.Element(
                    'site', {
                        'pb_type': add_vpr_tile_prefix(site.type),
                        'pin_mapping': 'custom'
                    }
                )

                for site_pin in site.site_pins:
                    add_tile_direct(
                        site_xml,
                        tile=object_ref(
                            add_vpr_tile_prefix(sub_tile_name),
                            site_pin.wire,
                        ),
                        pb_type=object_ref(
                            pb_name=add_vpr_tile_prefix(site.type),
                            pin_name=site_pin.name,
                        ),
                    )

                equivalent_sites_xml.append(site_xml)
                sub_tile_xml.append(equivalent_sites_xml)

                tile_xml.append(sub_tile_xml)

                num_sub_tile = num_sub_tile + 1
    else:
        sub_tile_xml = start_sub_tile(
            tile_name, pin_assignments, input_wires, output_wires
        )

        fc_xml = add_fc(sub_tile_xml)

        add_pinlocations(
            tile_name, sub_tile_xml, fc_xml, pin_assignments,
            set(input_wires) | set(output_wires)
        )
        tile_xml.append(sub_tile_xml)

    return tile_xml


def start_pb_type(
        pb_type_name,
        pin_assignments,
        input_wires,
        output_wires,
):
    """ Starts a pb_type by adding input, clock and output tags. """
    pb_type_xml = ET.Element(
        'pb_type',
        {
            'name': add_vpr_tile_prefix(pb_type_name),
        },
        nsmap={'xi': XI_URL},
    )

    pb_type_xml.append(ET.Comment(" Tile Inputs "))

    # Input definitions for the TILE
    for name in sorted(input_wires):
        input_type = 'input'

        if name.startswith('CLK_BUFG_'):
            if name.endswith('I0') or name.endswith('I1'):
                input_type = 'clock'
        elif 'CLK' in name:
            input_type = 'clock'

        ET.SubElement(
            pb_type_xml,
            input_type,
            {
                'name': name,
                'num_pins': '1'
            },
        )

    pb_type_xml.append(ET.Comment(" Tile Outputs "))
    for name in sorted(output_wires):
        # Output definitions for the TILE
        ET.SubElement(
            pb_type_xml,
            'output',
            {
                'name': name,
                'num_pins': '1'
            },
        )

    pb_type_xml.append(ET.Comment(" Internal Sites "))

    return pb_type_xml


def add_tile_direct(xml, tile, pb_type):
    """ Add a direct tag to the interconnect_xml. """
    ET.SubElement(xml, 'direct', {'from': tile, 'to': pb_type})


def remove_vpr_tile_prefix(name):
    """ Removes tile prefix.

    Raises
    ------
    Assert error if name does not start with VPR_TILE_PREFIX
    """
    assert name.startswith(VPR_TILE_PREFIX)
    return name[len(VPR_TILE_PREFIX):]


def write_xml(fname, xml):
    """ Writes XML to disk. """
    pb_type_str = ET.tostring(xml, pretty_print=True).decode('utf-8')

    dirname, basefname = os.path.split(fname)
    os.makedirs(dirname, exist_ok=True)
    with open(fname, 'w') as f:
        f.write(pb_type_str)
        f.close()


class ModelXml(object):
    """ Simple model.xml writter. """

    def __init__(self, f, site_directory):
        self.f = f
        self.model_xml = ET.Element(
            'models',
            nsmap={'xi': XI_URL},
        )
        self.site_model = site_directory + "/{0}/{1}.model.xml"

    def add_model_include(self, site_type, instance_name):
        ET.SubElement(
            self.model_xml, XI_INCLUDE, {
                'href':
                    self.site_model.format(
                        site_type.lower(), instance_name.lower()
                    ),
                'xpointer':
                    "xpointer(models/child::node())"
            }
        )

    def write_model(self):
        write_xml(self.f, self.model_xml)


def add_direct(xml, input, output):
    """ Add a direct tag to the interconnect_xml. """
    ET.SubElement(
        xml, 'direct', {
            'name': '{}_to_{}'.format(input, output),
            'input': input,
            'output': output
        }
    )
