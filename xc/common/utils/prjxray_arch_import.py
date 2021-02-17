""" Generates the top level VPR arch XML from the Project X-Ray database.

By default this will generate a complete arch XML for all tile types specified.

If the --use_roi flag is passed, only the tiles within the ROI will be included,
and synthetic IO pads will be created and connected to the routing fabric.
The mapping of the pad name to synthetic tile location will be outputted to the
file specified in the --synth_tiles output argument.  This can be used to generate
IO placement spefications to target the synthetic IO pads.

"""
from __future__ import print_function
import argparse
import prjxray.db
from prjxray.roi import Roi
from prjxray.overlay import Overlay
from prjxray import grid_types
import simplejson as json
import sys

import lxml.etree as ET

from prjxray_db_cache import DatabaseCache
from prjxray_tile_import import add_vpr_tile_prefix


def create_synth_io_tile(
        complexblocklist_xml, tiles_xml, tile_name, num_input, num_output
):
    """ Creates synthetic IO pad tiles used to connect ROI inputs and outputs to the routing network.
    """
    tile_xml = ET.SubElement(tiles_xml, 'tile', {
        'name': tile_name,
    })

    pad_name_out = 'outpad'
    port_type_out = 'input'

    pad_name_in = 'inpad'
    port_type_in = 'output'

    port_pin_in = '{}.{}'.format('SYN-INPAD', pad_name_in)
    sub_port_pin_in = '{}.{}'.format('SYN_IN_SUB_TILE', pad_name_in)

    port_pin_out = '{}.{}'.format('SYN-OUTPAD', pad_name_out)
    sub_port_pin_out = '{}.{}'.format('SYN_OUT_SUB_TILE', pad_name_out)

    if num_input != 0:
        sub_tile_xml_in = ET.SubElement(
            tile_xml, 'sub_tile', {
                'name': 'SYN_IN_SUB_TILE',
                'capacity': str(num_input)
            }
        )

        ET.SubElement(
            sub_tile_xml_in, 'fc', {
                'in_type': 'abs',
                'in_val': '2',
                'out_type': 'abs',
                'out_val': '2',
            }
        )

        equivalent_sites_in = ET.SubElement(
            sub_tile_xml_in, 'equivalent_sites'
        )

        site_in = ET.SubElement(
            equivalent_sites_in, 'site', {'pb_type': 'SYN-INPAD'}
        )

        ET.SubElement(
            sub_tile_xml_in, port_type_in, {
                'name': pad_name_in,
                'num_pins': '1',
            }
        )

        ET.SubElement(
            site_in, 'direct', {
                'from': sub_port_pin_in,
                'to': port_pin_in
            }
        )

    if num_output != 0:
        sub_tile_xml_out = ET.SubElement(
            tile_xml, 'sub_tile', {
                'name': 'SYN_OUT_SUB_TILE',
                'capacity': str(num_output)
            }
        )

        ET.SubElement(
            sub_tile_xml_out, 'fc', {
                'in_type': 'abs',
                'in_val': '2',
                'out_type': 'abs',
                'out_val': '2',
            }
        )

        equivalent_sites_out = ET.SubElement(
            sub_tile_xml_out, 'equivalent_sites'
        )

        site_out = ET.SubElement(
            equivalent_sites_out, 'site', {'pb_type': 'SYN-OUTPAD'}
        )

        ET.SubElement(
            sub_tile_xml_out, port_type_out, {
                'name': pad_name_out,
                'num_pins': '1',
            }
        )

        ET.SubElement(
            site_out, 'direct', {
                'from': sub_port_pin_out,
                'to': port_pin_out
            }
        )


def create_synth_pb_types(model_xml, complexblocklist_xml, is_overlay=False):
    """ Creates synthetic IO pad tiles used to connect ROI inputs and outputs to the routing network.
    """
    pb_xml_in = ET.SubElement(
        complexblocklist_xml, 'pb_type', {
            'name': 'SYN-INPAD',
        }
    )

    pb_xml_out = ET.SubElement(
        complexblocklist_xml, 'pb_type', {
            'name': 'SYN-OUTPAD',
        }
    )

    blif_model_out = '.output'
    pad_name_out = 'outpad'
    port_type_out = 'input'

    blif_model_in = '.input'
    pad_name_in = 'inpad'
    port_type_in = 'output'

    port_pin_in = '{}.{}'.format('SYN-INPAD', pad_name_in)
    pad_pin_in = '{}.{}'.format(pad_name_in, pad_name_in)

    port_pin_out = '{}.{}'.format('SYN-OUTPAD', pad_name_out)
    pad_pin_out = '{}.{}'.format(pad_name_out, pad_name_out)

    input_name_out = port_pin_out
    output_name_out = pad_pin_out

    input_name_in = pad_pin_in
    output_name_in = port_pin_in

    interconnect_xml_in = ET.SubElement(pb_xml_in, 'interconnect')
    interconnect_xml_out = ET.SubElement(pb_xml_out, 'interconnect')

    ET.SubElement(
        pb_xml_in, port_type_in, {
            'name': pad_name_in,
            'num_pins': '1',
        }
    )

    ET.SubElement(
        pb_xml_out, port_type_out, {
            'name': pad_name_out,
            'num_pins': '1',
        }
    )

    if is_overlay:
        # Add model for SYN_IBUF
        ibuf_model = ET.SubElement(model_xml, 'model', {'name': 'SYN_IBUF'})

        ibuf_input_ports = ET.SubElement(ibuf_model, 'input_ports', {})

        ET.SubElement(
            ibuf_input_ports, 'port', {
                'name': 'I',
                'combinational_sink_ports': 'O'
            }
        )

        ibuf_output_ports = ET.SubElement(ibuf_model, 'output_ports', {})

        ET.SubElement(ibuf_output_ports, 'port', {
            'name': 'O',
        })

        # Add model for SYN_OBUF
        obuf_model = ET.SubElement(model_xml, 'model', {'name': 'SYN_OBUF'})

        obuf_input_ports = ET.SubElement(obuf_model, 'input_ports', {})

        ET.SubElement(
            obuf_input_ports, 'port', {
                'name': 'I',
                'combinational_sink_ports': 'O'
            }
        )

        obuf_output_ports = ET.SubElement(obuf_model, 'output_ports', {})

        ET.SubElement(obuf_output_ports, 'port', {
            'name': 'O',
        })

        obuf_pb = ET.SubElement(
            pb_xml_out, 'pb_type', {
                'name': "SYN-OBUF",
                'blif_model': '.subckt SYN_OBUF',
                'num_pb': '1',
            }
        )

        ET.SubElement(obuf_pb, 'input', {
            'name': 'I',
            'num_pins': '1',
        })

        ET.SubElement(obuf_pb, 'output', {
            'name': 'O',
            'num_pins': '1',
        })

        ET.SubElement(
            obuf_pb, 'delay_constant', {
                'max': '1e-11',
                'in_port': 'I',
                'out_port': 'O',
            }
        )

        ibuf_pb = ET.SubElement(
            pb_xml_in, 'pb_type', {
                'name': "SYN-IBUF",
                'blif_model': '.subckt SYN_IBUF',
                'num_pb': '1',
            }
        )

        ET.SubElement(ibuf_pb, 'input', {
            'name': 'I',
            'num_pins': '1',
        })

        ET.SubElement(ibuf_pb, 'output', {
            'name': 'O',
            'num_pins': '1',
        })

        ET.SubElement(
            ibuf_pb, 'delay_constant', {
                'max': '1e-11',
                'in_port': 'I',
                'out_port': 'O',
            }
        )
    pin_pb_type_in = ET.SubElement(
        pb_xml_in, 'pb_type', {
            'name': pad_name_in,
            'blif_model': blif_model_in,
            'num_pb': '1',
        }
    )

    pin_pb_type_out = ET.SubElement(
        pb_xml_out, 'pb_type', {
            'name': pad_name_out,
            'blif_model': blif_model_out,
            'num_pb': '1',
        }
    )

    ET.SubElement(
        pin_pb_type_in, port_type_in, {
            'name': pad_name_in,
            'num_pins': '1',
        }
    )

    ET.SubElement(
        pin_pb_type_out, port_type_out, {
            'name': pad_name_out,
            'num_pins': '1',
        }
    )

    if is_overlay:
        direct_xml_out = ET.SubElement(
            interconnect_xml_out, 'direct', {
                'name': '{}_to_{}'.format('SYN-OBUF.O', 'outpad.outpad'),
                'input': 'SYN-OBUF.O',
                'output': 'outpad.outpad',
            }
        )

        ET.SubElement(
            direct_xml_out, 'pack_pattern', {
                'in_port': 'SYN-OBUF.O',
                'name': '{}to{}'.format('OBUF', 'outpad'),
                'out_port': 'outpad.outpad',
            }
        )

        ET.SubElement(
            interconnect_xml_out, 'direct', {
                'name': '{}_to_{}'.format('SYN-OUTPAD.outpad', 'SYN-OBUF.I'),
                'input': 'SYN-OUTPAD.outpad',
                'output': 'SYN-OBUF.I',
            }
        )

        direct_xml_in = ET.SubElement(
            interconnect_xml_in, 'direct', {
                'name': '{}_to_{}'.format('inpad.inpad', 'SYN-IBUF.I'),
                'input': 'inpad.inpad',
                'output': 'SYN-IBUF.I',
            }
        )

        ET.SubElement(
            direct_xml_in, 'pack_pattern', {
                'in_port': 'inpad.inpad',
                'name': '{}to{}'.format('inpad', 'IBUF'),
                'out_port': 'SYN-IBUF.I',
            }
        )

        ET.SubElement(
            interconnect_xml_in, 'direct', {
                'name': '{}_to_{}'.format('SYN-IBUF.O', 'SYN-INPAD.inpad'),
                'input': 'SYN-IBUF.O',
                'output': 'SYN-INPAD.inpad',
            }
        )
    else:
        direct_xml_out = ET.SubElement(
            interconnect_xml_out, 'direct', {
                'name': '{}_to_{}'.format(input_name_out, output_name_out),
                'input': input_name_out,
                'output': output_name_out,
            }
        )

        ET.SubElement(
            direct_xml_out, 'delay_constant', {
                'max': '1e-11',
                'in_port': input_name_out,
                'out_port': output_name_out,
            }
        )

        direct_xml_in = ET.SubElement(
            interconnect_xml_in, 'direct', {
                'name': '{}_to_{}'.format(input_name_in, output_name_in),
                'input': input_name_in,
                'output': output_name_in,
            }
        )

        ET.SubElement(
            direct_xml_in, 'delay_constant', {
                'max': '1e-11',
                'in_port': input_name_in,
                'out_port': output_name_in,
            }
        )


def create_synth_constant_tiles(
        model_xml, complexblocklist_xml, tiles_xml, pb_name, signal
):
    """ Creates synthetic constant tile generates some constant signal.

    Routing import will create a global network to fan this signal to local
    constant sources.
    """
    pb_xml = ET.SubElement(
        complexblocklist_xml, 'pb_type', {
            'name': pb_name,
        }
    )

    tile_xml = ET.SubElement(tiles_xml, 'tile', {
        'name': pb_name,
    })

    sub_tile_xml = ET.SubElement(tile_xml, 'sub_tile', {'name': pb_name})

    equivalent_sites = ET.SubElement(sub_tile_xml, 'equivalent_sites')
    site = ET.SubElement(equivalent_sites, 'site', {'pb_type': pb_name})

    ET.SubElement(
        sub_tile_xml, 'fc', {
            'in_type': 'abs',
            'in_val': '2',
            'out_type': 'abs',
            'out_val': '2',
        }
    )

    interconnect_xml = ET.SubElement(pb_xml, 'interconnect')

    blif_model = '.subckt ' + signal
    port_type = 'output'
    pin_name = signal

    ET.SubElement(pb_xml, port_type, {
        'name': pin_name,
        'num_pins': '1',
    })

    ET.SubElement(
        sub_tile_xml, port_type, {
            'name': pin_name,
            'num_pins': '1',
        }
    )

    port_pin = '{}.{}'.format(pb_name, pin_name)
    pad_pin = '{}.{}'.format(pin_name, pin_name)

    ET.SubElement(site, 'direct', {'from': port_pin, 'to': port_pin})

    input_name = pad_pin
    output_name = port_pin

    pin_pb_type = ET.SubElement(
        pb_xml, 'pb_type', {
            'name': pin_name,
            'blif_model': blif_model,
            'num_pb': '1',
        }
    )
    ET.SubElement(
        pin_pb_type, port_type, {
            'name': pin_name,
            'num_pins': '1',
        }
    )

    direct_xml = ET.SubElement(
        interconnect_xml, 'direct', {
            'name': '{}_to_{}'.format(input_name, output_name),
            'input': input_name,
            'output': output_name,
        }
    )

    ET.SubElement(
        direct_xml, 'delay_constant', {
            'max': '1e-11',
            'in_port': input_name,
            'out_port': output_name,
        }
    )

    model = ET.SubElement(model_xml, 'model', {
        'name': signal,
    })

    ET.SubElement(model, 'input_ports')
    output_ports = ET.SubElement(model, 'output_ports')
    ET.SubElement(output_ports, 'port', {
        'name': pin_name,
    })


def get_phy_tiles(conn, tile_pkey):
    """ Returns the locations of all physical tiles for specified tile. """
    c = conn.cursor()
    c2 = conn.cursor()

    phy_locs = []
    for (phy_tile_pkey, ) in c.execute("""
SELECT phy_tile_pkey FROM tile_map WHERE tile_pkey = ?""", (tile_pkey, )):
        c2.execute(
            "SELECT grid_x, grid_y FROM phy_tile WHERE pkey = ?",
            (phy_tile_pkey, )
        )
        loc = c2.fetchone()
        phy_locs.append(grid_types.GridLoc(*loc))

    return phy_locs


def is_in_roi(conn, roi, tile_pkey):
    """ Returns if the specified tile is in the ROI. """
    phy_locs = get_phy_tiles(conn, tile_pkey)
    return any(roi.tile_in_roi(loc) for loc in phy_locs)


# Map instance type (e.g. IOB_X1Y10) to:
# - Which coordinates are required (e.g. X, Y or X and Y)
# - Modulus on the coordinates
#
# For example, IO sites only need the Y coordinate, use a modulus of 2.
# So IOB_X1Y10 becomes IOB_Y0, IOB_X1Y11 becomes IOB_Y1, etc.
# Setting modulo to 0 results in omitting modulo operation.
PREFIX_REQUIRED = {
    "IOB": ("Y", 2),
    "IDELAY": ("Y", 2),
    "ILOGIC": ("Y", 2),
    "OLOGIC": ("Y", 2),
    "BUFGCTRL": ("XY", (2, 16)),
    "SLICEM": ("X", 2),
    "SLICEL": ("X", 2),
    "GTPE2_COMMON": ("XY", (0, 0)),
    "GTPE2_CHANNEL": ("XY", (0, 0)),
    "IBUFDS_GTE2": ("XY", (0, 0)),
    "IPAD": ("XY", (0, 0)),
    "OPAD": ("XY", (0, 0)),
}


def make_prefix(site, x, y, from_site_name=False):
    """ Make tile FASM prefix for a given site. """
    if from_site_name:
        site_type, _ = site.split('_')
    else:
        site_type = site

    prefix_required = PREFIX_REQUIRED[site_type]

    if prefix_required[0] == 'Y':
        mod_y = prefix_required[1]
        y_formula = "y{}".format(" % mod_y") if mod_y else "y"
        return site_type, '{}_Y{}'.format(site_type, eval(y_formula))
    elif prefix_required[0] == 'X':
        mod_x = prefix_required[1]
        x_formula = "x{}".format(" % mod_x") if mod_x else "x"
        return site_type, '{}_X{}'.format(site_type, eval(x_formula))
    elif prefix_required[0] == 'XY':
        mod_x, mod_y = prefix_required[1]
        x_formula = "x{}".format(" % mod_x") if mod_x else "x"
        y_formula = "y{}".format(" % mod_y") if mod_y else "y"
        return site_type, '{}_X{}Y{}'.format(site_type, eval(x_formula),
                                             eval(y_formula))
    else:
        assert False, (site_type, prefix_required)


def get_site_prefixes(conn, tile_pkey):
    cur = conn.cursor()

    site_prefixes = {}
    cur.execute(
        """
WITH
  sites_in_tile(site_pkey) AS (
    SELECT
      DISTINCT wire_in_tile.site_pkey
    FROM
      wire_in_tile
    INNER JOIN site ON site.pkey = wire_in_tile.site_pkey
    WHERE
      wire_in_tile.tile_type_pkey = (SELECT tile_type_pkey FROM tile WHERE pkey = ?)
    AND
      wire_in_tile.phy_tile_type_pkey IN (SELECT tile_type_pkey FROM phy_tile WHERE pkey IN
        (SELECT phy_tile_pkey FROM tile_map WHERE tile_pkey = ?))
    AND
      site_pin_pkey IS NOT NULL)
SELECT site_instance.name, site_instance.x_coord, site_instance.y_coord
FROM site_instance
WHERE
  site_instance.site_pkey IN (SELECT site_pkey FROM sites_in_tile)
AND
  site_instance.phy_tile_pkey IN (SELECT phy_tile_pkey FROM tile_map WHERE tile_pkey = ?);
  """, (tile_pkey, tile_pkey, tile_pkey)
    )
    for site_name, x, y in cur:
        site_type, prefix = make_prefix(site_name, x, y, from_site_name=True)
        assert site_type not in site_prefixes
        site_prefixes[site_type] = prefix

    return site_prefixes


def create_capacity_prefix(c, tile_prefix, tile_pkey, tile_capacity):
    """ Create FASM prefixes for all sites located within specified tile.

    This function should be invoke when the relevant tile has capacity > 1
    and therefore there should be prefixes for each instance.

    """
    c.execute(
        """
SELECT site_type.name, site_instance.x_coord, site_instance.y_coord
FROM site_instance
INNER JOIN site ON site_instance.site_pkey = site.pkey
INNER JOIN site_type ON site.site_type_pkey = site_type.pkey
WHERE site_instance.phy_tile_pkey IN (
  SELECT
    phy_tile_pkey
  FROM
    tile
  WHERE
    pkey = ?
)
ORDER BY site_instance.x_coord, site_instance.y_coord, site_type.name;""",
        (tile_pkey, )
    )

    prefixes = []
    for site_type, x, y in c:
        _, prefix = make_prefix(site_type, x, y)

        if "SLICE" in site_type:
            prefixes.append('{}.{}'.format(tile_prefix, prefix))
        else:
            prefixes.append('{}.{}.{}'.format(tile_prefix, site_type, prefix))

    assert len(prefixes
               ) == tile_capacity, (tile_pkey, tile_capacity, len(prefixes))

    return " ".join(prefixes)


def get_fasm_tile_prefix(conn, g, tile_pkey, site_as_tile_pkey, tile_capacity):
    """ Returns FASM prefix of specified tile. """
    c = conn.cursor()

    c.execute(
        """
SELECT
    phy_tile.name,
    tile_type.name
FROM phy_tile
INNER JOIN tile_type
ON phy_tile.tile_type_pkey = tile_type.pkey
WHERE
    phy_tile.pkey IN (SELECT phy_tile_pkey FROM tile_map WHERE tile_pkey = ?);
        """, (tile_pkey, )
    )

    # If this tile has multiples phy_tile's, make sure only one has bitstream
    # data, otherwise the tile split was invalid.
    tile_type_map = {}
    for tilename, tile_type in c:
        gridinfo = g.gridinfo_at_tilename(tilename)
        is_vbrk = gridinfo.tile_type.find('VBRK') != -1
        is_pss = gridinfo.tile_type.startswith('PSS')

        # VBRK and PSS* tiles are known to have no bitstream data.
        if not is_vbrk and not is_pss and not gridinfo.bits:
            print(
                '*** WARNING *** Tile {} appears to be missing bitstream data.'
                .format(tilename),
                file=sys.stderr
            )

        if gridinfo.bits:
            # Each VPR tile can only have one prefix.
            # If this assumption is violated, a more dramatic
            # restructing is required.
            tile_type_map[tile_type] = tilename

    if len(tile_type_map) > 1:
        assert tile_capacity == 1
        tile_type_map.update(get_site_prefixes(conn, tile_pkey))
        return lambda single_xml: attach_multiple_prefixes_to_tile(
            single_xml, tile_type_map
        )
    else:
        assert len(tile_type_map) == 1, tile_pkey

        tile_prefix = list(tile_type_map.values())[0]

        # If this tile is site_as_tile, add an additional prefix of the site
        # that is embedded in the tile.
        if site_as_tile_pkey is not None:
            assert tile_capacity == 1
            c.execute(
                "SELECT site_pkey FROM site_as_tile WHERE pkey = ?",
                (site_as_tile_pkey, )
            )
            site_pkey = c.fetchone()[0]

            c.execute(
                """
                SELECT site_type_pkey, x_coord FROM site WHERE pkey = ?
                """, (site_pkey, )
            )
            site_type_pkey, x = c.fetchone()

            c.execute(
                "SELECT name FROM site_type WHERE pkey = ?",
                (site_type_pkey, )
            )
            site_type_name = c.fetchone()[0]

            tile_prefix = '{}.{}_X{}'.format(tile_prefix, site_type_name, x)

        if tile_capacity > 1:
            tile_prefix = create_capacity_prefix(
                c, tile_prefix, tile_pkey, tile_capacity
            )

        return lambda single_xml: attach_prefix_to_tile(
            single_xml, tile_prefix
        )


def attach_prefix_to_tile(single_xml, fasm_tile_prefix):
    meta = ET.SubElement(single_xml, 'metadata')
    ET.SubElement(
        meta, 'meta', {
            'name': 'fasm_prefix',
        }
    ).text = fasm_tile_prefix


# Map the following tile types to a more general name
TYPE_REMAP = {
    "LIOI3_SING": "IOI3_TILE",
    "LIOI3": "IOI3_TILE",
    "LIOI3_TBYTESRC": "IOI3_TILE",
    "LIOI3_TBYTETERM": "IOI3_TILE",
    "RIOI3_SING": "IOI3_TILE",
    "RIOI3": "IOI3_TILE",
    "RIOI3_TBYTESRC": "IOI3_TILE",
    "RIOI3_TBYTETERM": "IOI3_TILE",
    "LIOB33": "IOB_TILE",
    "LIOB33_SING": "IOB_TILE",
    "RIOB33": "IOB_TILE",
    "RIOB33_SING": "IOB_TILE",
}


def attach_multiple_prefixes_to_tile(single_xml, tile_type_map):
    meta = ET.SubElement(single_xml, 'metadata')
    ET.SubElement(meta, 'meta', {
        'name': 'fasm_placeholders',
    }).text = '\n' + '\n'.join(
        '{} : {}'.format(TYPE_REMAP.get(k, k), v)
        for k, v in tile_type_map.items()
    ) + '\n'


def get_tiles(
        conn, g, roi, synth_loc_map, synth_tile_map, tile_types, tile_capacity
):
    """ Yields tiles in grid.

    Yields
    ------
    vpr_tile_type : str
        VPR tile type at this grid location.
    grid_x, grid_y : int
        Grid coordinate of tile
    metadata_function : function that takes lxml.Element
        Function for attaching metadata tags to <single> elements.
        Function must be supplied, but doesn't need to add metadata if not
        required.

    """
    c = conn.cursor()
    c2 = conn.cursor()

    only_emit_roi = roi is not None

    for tile_pkey, grid_x, grid_y, phy_tile_pkey, tile_type_pkey, site_as_tile_pkey in c.execute(
            """
        SELECT pkey, grid_x, grid_y, phy_tile_pkey, tile_type_pkey, site_as_tile_pkey FROM tile
        """):

        if phy_tile_pkey is not None:
            c2.execute(
                "SELECT prohibited FROM site_instance WHERE phy_tile_pkey = ?",
                (phy_tile_pkey, )
            )

            any_prohibited_sites = any(
                prohibited for (prohibited, ) in c2.fetchall()
            )

            # Skip generation of tiles containing prohibited sites
            if any_prohibited_sites:
                continue

        # Just output synth tiles, no additional processing is required here.
        if (grid_x, grid_y) in synth_loc_map:
            vpr_tile_type = synth_loc_map[(grid_x, grid_y)]

            yield vpr_tile_type, grid_x, grid_y, lambda x: None
            continue

        c2.execute(
            "SELECT name FROM tile_type WHERE pkey = ?", (tile_type_pkey, )
        )
        tile_type = c2.fetchone()[0]
        if tile_type not in tile_types:
            # We don't want this tile
            continue

        if only_emit_roi and not is_in_roi(conn, roi, tile_pkey):
            # Tile is outside ROI, skip it
            continue

        vpr_tile_type = add_vpr_tile_prefix(tile_type)

        # For Zynq PSS* tiles do not emit fasm prefixes
        if tile_type.startswith('PSS'):

            def get_none_tile_prefix(single_xml):
                return None

            meta_fun = get_none_tile_prefix
        else:
            meta_fun = get_fasm_tile_prefix(
                conn, g, tile_pkey, site_as_tile_pkey, tile_capacity[tile_type]
            )

        yield vpr_tile_type, grid_x, grid_y, meta_fun


def add_constant_synthetic_tiles(model_xml, complexblocklist_xml, tiles_xml):
    synth_tile_types = {}
    create_synth_constant_tiles(
        model_xml, complexblocklist_xml, tiles_xml, 'SYN-VCC', 'VCC'
    )
    create_synth_constant_tiles(
        model_xml, complexblocklist_xml, tiles_xml, 'SYN-GND', 'GND'
    )

    synth_tile_types['VCC'] = 'SYN-VCC'
    synth_tile_types['GND'] = 'SYN-GND'

    return synth_tile_types


def add_direct(directlist_xml, direct):
    direct_dict = {
        'name':
            '{}_to_{}_dx_{}_dy_{}_dz_{}'.format(
                direct['from_pin'], direct['to_pin'], direct['x_offset'],
                direct['y_offset'], direct['z_offset']
            ),
        'from_pin':
            add_vpr_tile_prefix(direct['from_pin']),
        'to_pin':
            add_vpr_tile_prefix(direct['to_pin']),
        'x_offset':
            str(direct['x_offset']),
        'y_offset':
            str(direct['y_offset']),
        'z_offset':
            str(direct['z_offset']),
    }

    # If the switch is a delayless_switch, the switch name
    # needs to be avoided as VPR automatically assigns
    # the delayless switch to this direct connection
    if direct['switch_name'] != '__vpr_delayless_switch__':
        direct_dict['switch_name'] = direct['switch_name']

    ET.SubElement(directlist_xml, 'direct', direct_dict)


def insert_constant_tiles(conn, model_xml, complexblocklist_xml, tiles_xml):
    c = conn.cursor()

    # Always add 'GND' and 'VCC' synth tiles
    synth_tile_map = add_constant_synthetic_tiles(
        model_xml, complexblocklist_xml, tiles_xml
    )
    synth_loc_map = {}

    c.execute('SELECT pkey FROM tile_type WHERE name = "NULL";')
    null_tile_type_pkey = c.fetchone()[0]

    # Get all 'NULL' tile locations
    c.execute(
        """
    SELECT grid_x, grid_y
    FROM phy_tile
    WHERE tile_type_pkey = ?
    ORDER BY grid_y, grid_x ASC
    LIMIT 2
""", (null_tile_type_pkey, )
    )

    locs = list(c.fetchall())
    assert len(locs) >= 2

    loc = {'VCC': locs[0], 'GND': locs[1]}

    c.execute(
        """
    SELECT pkey, tile_type_pkey FROM phy_tile
    WHERE grid_x = ? AND grid_y = ?""", loc['VCC']
    )
    vcc_phy_tile_pkey, vcc_tile_type_pkey = c.fetchone()
    assert vcc_tile_type_pkey == null_tile_type_pkey, vcc_tile_type_pkey

    c.execute(
        """
    SELECT pkey, grid_x, grid_y FROM tile WHERE phy_tile_pkey = ?
    """, (vcc_phy_tile_pkey, )
    )
    results = c.fetchall()
    assert len(results) == 1, results
    _, vcc_grid_x, vcc_grid_y = results[0]
    synth_loc_map[(vcc_grid_x, vcc_grid_y)] = synth_tile_map['VCC']

    c.execute(
        """
    SELECT pkey, tile_type_pkey FROM phy_tile
    WHERE grid_x = ? AND grid_y = ?""", loc['GND']
    )
    gnd_phy_tile_pkey, gnd_tile_type_pkey = c.fetchone()
    assert gnd_tile_type_pkey == null_tile_type_pkey

    c.execute(
        """
    SELECT pkey, grid_x, grid_y FROM tile WHERE phy_tile_pkey = ?
    """, (gnd_phy_tile_pkey, )
    )
    results = c.fetchall()
    assert len(results) == 1, results
    _, gnd_grid_x, gnd_grid_y = results[0]
    synth_loc_map[(gnd_grid_x, gnd_grid_y)] = synth_tile_map['GND']

    return synth_tile_map, synth_loc_map


def main():
    parser = argparse.ArgumentParser(description="Generate arch.xml")
    parser.add_argument(
        '--db_root', required=True, help="Project X-Ray database to use."
    )
    parser.add_argument('--part', required=True, help="FPGA part")
    parser.add_argument(
        '--output-arch',
        nargs='?',
        type=argparse.FileType('w'),
        help="""File to output arch."""
    )
    parser.add_argument(
        '--tile-types', required=True, help="Semi-colon seperated tile types."
    )
    parser.add_argument(
        '--pb_types',
        required=True,
        help="Semi-colon seperated pb_types types."
    )
    parser.add_argument(
        '--pin_assignments', required=True, type=argparse.FileType('r')
    )
    parser.add_argument('--use_roi', required=False)
    parser.add_argument('--use_overlay', required=False)
    parser.add_argument('--device', required=True)
    parser.add_argument('--synth_tiles', required=False)
    parser.add_argument('--connection_database', required=True)
    parser.add_argument(
        '--graph_limit',
        help='Limit grid to specified dimensions in x_min,y_min,x_max,y_max',
    )

    args = parser.parse_args()

    tile_types = args.tile_types.split(',')
    pb_types = args.pb_types.split(',')

    model_xml_spec = "../../tiles/{0}/{0}.model.xml"
    pbtype_xml_spec = "../../tiles/{0}/{0}.pb_type.xml"
    tile_xml_spec = "../../tiles/{0}/{0}.tile.xml"

    xi_url = "http://www.w3.org/2001/XInclude"
    ET.register_namespace('xi', xi_url)
    xi_include = "{%s}include" % xi_url

    arch_xml = ET.Element(
        'architecture',
        {},
        nsmap={'xi': xi_url},
    )

    model_xml = ET.SubElement(arch_xml, 'models')
    for pb_type in pb_types:
        ET.SubElement(
            model_xml, xi_include, {
                'href': model_xml_spec.format(pb_type.lower()),
                'xpointer': "xpointer(models/child::node())",
            }
        )

    tiles_xml = ET.SubElement(arch_xml, 'tiles')
    tile_capacity = {}
    for tile_type in tile_types:
        uri = tile_xml_spec.format(tile_type.lower())
        ET.SubElement(tiles_xml, xi_include, {
            'href': uri,
        })

        with open(uri) as f:
            tile_xml = ET.parse(f, ET.XMLParser())

            tile_root = tile_xml.getroot()
            assert tile_root.tag == 'tile'
            tile_capacity[tile_type] = 0

            for sub_tile in tile_root.iter('sub_tile'):
                if 'capacity' in sub_tile.attrib:
                    tile_capacity[tile_type] += int(
                        sub_tile.attrib['capacity']
                    )
                else:
                    tile_capacity[tile_type] += 1

    complexblocklist_xml = ET.SubElement(arch_xml, 'complexblocklist')
    for pb_type in pb_types:
        ET.SubElement(
            complexblocklist_xml, xi_include, {
                'href': pbtype_xml_spec.format(pb_type.lower()),
            }
        )

    layout_xml = ET.SubElement(arch_xml, 'layout')
    db = prjxray.db.Database(args.db_root, args.part)
    g = db.grid()

    synth_tiles = {}
    synth_tiles['tiles'] = {}
    synth_loc_map = {}
    synth_tile_map = {}
    roi = None
    if args.use_roi:
        with open(args.use_roi) as f:
            j = json.load(f)

        with open(args.synth_tiles) as f:
            synth_tiles = json.load(f)

        roi = Roi(
            db=db,
            x1=j['info']['GRID_X_MIN'],
            y1=j['info']['GRID_Y_MIN'],
            x2=j['info']['GRID_X_MAX'],
            y2=j['info']['GRID_Y_MAX'],
        )

        for _, tile_info in synth_tiles['tiles'].items():
            if tile_info['pins'][0]['port_type'] in ['GND', 'VCC']:
                continue

            assert tuple(tile_info['loc']) not in synth_loc_map
            tile_name = tile_info['tile_name']
            num_input = len(
                list(
                    filter(
                        lambda t: t['port_type'] == 'output', tile_info['pins']
                    )
                )
            )
            num_output = len(
                list(
                    filter(
                        lambda t: t['port_type'] == 'input', tile_info['pins']
                    )
                )
            )

            create_synth_io_tile(
                complexblocklist_xml, tiles_xml, tile_name, num_input,
                num_output
            )

            synth_loc_map[tuple(tile_info['loc'])] = tile_name

        create_synth_pb_types(model_xml, complexblocklist_xml)

        synth_tile_map = add_constant_synthetic_tiles(
            model_xml, complexblocklist_xml, tiles_xml
        )

        for _, tile_info in synth_tiles['tiles'].items():
            if tile_info['pins'][0]['port_type'] not in ['GND', 'VCC']:
                continue

            assert tuple(tile_info['loc']) not in synth_loc_map

            vpr_tile_type = synth_tile_map[tile_info['pins'][0]['port_type']]
            synth_loc_map[tuple(tile_info['loc'])] = vpr_tile_type

    elif args.graph_limit:
        x_min, y_min, x_max, y_max = map(int, args.graph_limit.split(','))
        roi = Roi(
            db=db,
            x1=x_min,
            y1=y_min,
            x2=x_max,
            y2=y_max,
        )
    elif args.use_overlay:
        with open(args.use_overlay) as f:
            j = json.load(f)

        with open(args.synth_tiles) as f:
            synth_tiles = json.load(f)

        region_dict = dict()
        for r in synth_tiles['info']:
            bounds = (
                r['GRID_X_MIN'], r['GRID_X_MAX'], r['GRID_Y_MIN'],
                r['GRID_Y_MAX']
            )
            region_dict[r['name']] = bounds

        roi = Overlay(region_dict=region_dict)

        for _, tile_info in synth_tiles['tiles'].items():
            if tile_info['pins'][0]['port_type'] in ['GND', 'VCC']:
                continue

            assert tuple(tile_info['loc']) not in synth_loc_map
            tile_name = tile_info['tile_name']
            num_input = len(
                list(
                    filter(
                        lambda t: t['port_type'] == 'output', tile_info['pins']
                    )
                )
            )
            num_output = len(
                list(
                    filter(
                        lambda t: t['port_type'] == 'input', tile_info['pins']
                    )
                )
            )

            create_synth_io_tile(
                complexblocklist_xml, tiles_xml, tile_name, num_input,
                num_output
            )

            synth_loc_map[tuple(tile_info['loc'])] = tile_name

        create_synth_pb_types(model_xml, complexblocklist_xml, True)

    with DatabaseCache(args.connection_database, read_only=True) as conn:
        c = conn.cursor()

        if 'GND' not in synth_tile_map:
            synth_tile_map, synth_loc_map_const = insert_constant_tiles(
                conn, model_xml, complexblocklist_xml, tiles_xml
            )

            synth_loc_map.update(synth_loc_map_const)

        # Find the grid extent.
        y_max = 0
        x_max = 0
        for grid_x, grid_y in c.execute("SELECT grid_x, grid_y FROM tile"):
            x_max = max(grid_x + 2, x_max)
            y_max = max(grid_y + 2, y_max)

        name = '{}-test'.format(args.device)
        fixed_layout_xml = ET.SubElement(
            layout_xml, 'fixed_layout', {
                'name': name,
                'height': str(y_max),
                'width': str(x_max),
            }
        )

        for vpr_tile_type, grid_x, grid_y, metadata_function in get_tiles(
                conn=conn,
                g=g,
                roi=roi,
                synth_loc_map=synth_loc_map,
                synth_tile_map=synth_tile_map,
                tile_types=tile_types,
                tile_capacity=tile_capacity,
        ):
            single_xml = ET.SubElement(
                fixed_layout_xml, 'single', {
                    'priority': '1',
                    'type': vpr_tile_type,
                    'x': str(grid_x),
                    'y': str(grid_y),
                }
            )
            metadata_function(single_xml)

        switchlist_xml = ET.SubElement(arch_xml, 'switchlist')

        for name, internal_capacitance, drive_resistance, intrinsic_delay, \
                switch_type in c.execute("""
SELECT
    name,
    internal_capacitance,
    drive_resistance,
    intrinsic_delay,
    switch_type
FROM
    switch
WHERE
    name != "__vpr_delayless_switch__";"""):

            attrib = {
                'type': switch_type,
                'name': name,
                "R": str(drive_resistance),
                "Cin": str(0),
                "Cout": str(0),
                "Tdel": str(intrinsic_delay),
            }

            if internal_capacitance != 0:
                attrib["Cinternal"] = str(internal_capacitance)

            if False:
                attrib["mux_trans_size"] = str(0)
                attrib["buf_size"] = str(0)

            ET.SubElement(switchlist_xml, 'switch', attrib)

        segmentlist_xml = ET.SubElement(arch_xml, 'segmentlist')

        # VPR requires a segment, so add one.
        dummy_xml = ET.SubElement(
            segmentlist_xml, 'segment', {
                'name': 'dummy',
                'length': '2',
                'freq': '1.0',
                'type': 'bidir',
                'Rmetal': '0',
                'Cmetal': '0',
            }
        )
        ET.SubElement(dummy_xml, 'wire_switch', {
            'name': 'buffer',
        })
        ET.SubElement(dummy_xml, 'opin_switch', {
            'name': 'buffer',
        })
        ET.SubElement(dummy_xml, 'sb', {
            'type': 'pattern',
        }).text = ' '.join('1' for _ in range(3))
        ET.SubElement(dummy_xml, 'cb', {
            'type': 'pattern',
        }).text = ' '.join('1' for _ in range(2))

        for (name, length) in c.execute("SELECT name, length FROM segment"):
            if length is None:
                length = 1

            segment_xml = ET.SubElement(
                segmentlist_xml, 'segment', {
                    'name': name,
                    'length': str(length),
                    'freq': '1.0',
                    'type': 'bidir',
                    'Rmetal': '0',
                    'Cmetal': '0',
                }
            )
            ET.SubElement(segment_xml, 'wire_switch', {
                'name': 'buffer',
            })
            ET.SubElement(segment_xml, 'opin_switch', {
                'name': 'buffer',
            })
            ET.SubElement(segment_xml, 'sb', {
                'type': 'pattern',
            }).text = ' '.join('1' for _ in range(length + 1))
            ET.SubElement(segment_xml, 'cb', {
                'type': 'pattern',
            }).text = ' '.join('1' for _ in range(length))

    ET.SubElement(
        switchlist_xml,
        'switch',
        {
            'type': 'mux',
            'name': 'buffer',
            "R": "551",
            "Cin": ".77e-15",
            "Cout": "4e-15",
            # TODO: This value should be the "typical" pip switch delay from
            # This value is the dominate term in the inter-cluster delay
            # estimate.
            "Tdel": "0.178e-9",
            "mux_trans_size": "2.630740",
            "buf_size": "27.645901"
        }
    )

    device_xml = ET.SubElement(arch_xml, 'device')

    ET.SubElement(
        device_xml, 'sizing', {
            "R_minW_nmos": "6065.520020",
            "R_minW_pmos": "18138.500000",
        }
    )
    ET.SubElement(device_xml, 'area', {
        "grid_logic_tile_area": "14813.392",
    })
    ET.SubElement(
        device_xml, 'connection_block', {
            "input_switch_name": "buffer",
        }
    )
    ET.SubElement(device_xml, 'switch_block', {
        "type": "wilton",
        "fs": "3",
    })
    chan_width_distr_xml = ET.SubElement(device_xml, 'chan_width_distr')

    ET.SubElement(
        chan_width_distr_xml, 'x', {
            'distr': 'uniform',
            'peak': '1.0',
        }
    )
    ET.SubElement(
        chan_width_distr_xml, 'y', {
            'distr': 'uniform',
            'peak': '1.0',
        }
    )

    directlist_xml = ET.SubElement(arch_xml, 'directlist')

    pin_assignments = json.load(args.pin_assignments)

    # Choose smallest distance for block to block connections with multiple
    # direct_connections.  VPR cannot handle multiple block to block connections.
    directs = {}
    for direct in pin_assignments['direct_connections']:
        key = (direct['from_pin'], direct['to_pin'])

        if key not in directs:
            directs[key] = []

        directs[key].append(
            (abs(direct['x_offset']) + abs(direct['y_offset']), direct)
        )

    ALLOWED_ZERO_OFFSET_DIRECT = [
        "GTP_CHANNEL_0",
        "GTP_CHANNEL_1",
        "GTP_CHANNEL_2",
        "GTP_CHANNEL_3",
    ]

    zero_offset_directs = dict()

    for direct in directs.values():
        _, direct = min(direct, key=lambda v: v[0])
        from_tile = direct['from_pin'].split('.')[0]
        to_tile = direct['to_pin'].split('.')[0]

        if from_tile not in tile_types:
            continue
        if to_tile not in tile_types:
            continue

        # In general, the Z offset is 0, except for special cases
        # such as for the GTP tiles, where there are direct connections
        # within the same (x, y) cooredinates, but between different sub_tiles
        direct['z_offset'] = 0

        if direct['x_offset'] == 0 and direct['y_offset'] == 0:
            if from_tile == to_tile and from_tile in ALLOWED_ZERO_OFFSET_DIRECT:
                if from_tile not in zero_offset_directs:
                    zero_offset_directs[from_tile] = list()

                zero_offset_directs[from_tile].append(direct)

            continue

        add_direct(directlist_xml, direct)

    for tile, directs in zero_offset_directs.items():
        uri = tile_xml_spec.format(tile_type.lower())
        ports = list()

        with open(uri) as f:
            tile_xml = ET.parse(f, ET.XMLParser())

            tile_root = tile_xml.getroot()

            for capacity, sub_tile in enumerate(tile_root.iter('sub_tile')):
                for in_port in sub_tile.iter('input'):
                    ports.append((in_port.attrib["name"], capacity))
                for out_port in sub_tile.iter('output'):
                    ports.append((out_port.attrib["name"], capacity))
                for clk_port in sub_tile.iter('clock'):
                    ports.append((clk_port.attrib["name"], capacity))

        for direct in directs:
            from_port = direct['from_pin'].split('.')[1]
            to_port = direct['to_pin'].split('.')[1]

            from_port_capacity = None
            to_port_capacity = None
            for port, capacity in ports:
                if port == from_port:
                    from_port_capacity = capacity
                if port == to_port:
                    to_port_capacity = capacity

            assert from_port_capacity is not None and to_port_capacity is not None
            direct["z_offset"] = to_port_capacity - from_port_capacity

            add_direct(directlist_xml, direct)

    arch_xml_str = ET.tostring(arch_xml, pretty_print=True).decode('utf-8')
    args.output_arch.write(arch_xml_str)
    args.output_arch.close()


if __name__ == '__main__':
    main()
