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
import os.path
import simplejson as json
import sys

import lxml.etree as ET

def create_synth_io_tiles(complexblocklist_xml, pb_name, is_input):
    """ Creates synthetic IO pad tiles used to connect ROI inputs and outputs to the routing network.
    """
    pb_xml = ET.SubElement(complexblocklist_xml, 'pb_type', {
            'name': pb_name,
    })

    ET.SubElement(pb_xml, 'fc', {
            'in_type':'abs',
            'in_val':'2',
            'out_type': 'abs',
            'out_val':'2',
    })

    interconnect_xml = ET.SubElement(pb_xml, 'interconnect')

    if is_input:
        blif_model = '.input'
        pad_name = 'inpad'
        port_type = 'output'
    else:
        blif_model = '.output'
        pad_name = 'outpad'
        port_type = 'input'

    ET.SubElement(pb_xml, port_type, {
        'name': pad_name,
        'num_pins': '1',
    })

    port_pin = '{}.{}'.format(pb_name, pad_name)
    pad_pin = '{}.{}'.format(pad_name, pad_name)

    if not is_input:
        input_name = port_pin
        output_name = pad_pin
    else:
        input_name = pad_pin
        output_name = port_pin

    pin_pb_type = ET.SubElement(pb_xml, 'pb_type', {
            'name': pad_name,
            'blif_model': blif_model,
            'num_pb': '1',
    })
    ET.SubElement(pin_pb_type, port_type, {
            'name': pad_name,
            'num_pins': '1',
    })

    direct_xml = ET.SubElement(interconnect_xml, 'direct', {
            'name': '{}_to_{}'.format(input_name, output_name),
            'input': input_name,
            'output': output_name,
    })

    ET.SubElement(direct_xml, 'delay_constant', {
            'max': '1e-11',
            'in_port': input_name,
            'out_port': output_name,
    })

def add_synthetic_tile(complexblocklist_xml):
    create_synth_io_tiles(complexblocklist_xml, 'BLK_SY-INPAD', is_input=True)
    create_synth_io_tiles(complexblocklist_xml, 'BLK_SY-OUTPAD', is_input=False)

    return {
            'output': 'BLK_SY-INPAD',
            'input': 'BLK_SY-OUTPAD',
    }

def main():
    mydir = os.path.dirname(__file__)
    prjxray_db = os.path.abspath(os.path.join(mydir, "..", "..", "third_party", "prjxray-db"))

    db_types = prjxray.db.get_available_databases(prjxray_db)

    parser = argparse.ArgumentParser(description="Generate arch.xml")
    parser.add_argument(
        '--part', choices=[os.path.basename(db_type) for db_type in db_types],
        help="""Project X-Ray database to use.""")
    parser.add_argument(
            '--output-arch', nargs='?', type=argparse.FileType('w'),
            help="""File to output arch.""")
    parser.add_argument('--tile-types', help="Semi-colon seperated tile types.")
    parser.add_argument(
            '--pin_assignments', required=True, type=argparse.FileType('r'))
    parser.add_argument(
            '--use_roi', required=False)
    parser.add_argument(
            '--synth_tiles', required=False)
    parser.add_argument(
            '--device', required=True)

    args = parser.parse_args()

    tile_types = args.tile_types.split(',')

    tile_model = "../../tiles/{0}/{0}.model.xml"
    tile_pbtype = "../../tiles/{0}/{0}.pb_type.xml"

    xi_url = "http://www.w3.org/2001/XInclude"
    ET.register_namespace('xi', xi_url)
    xi_include = "{%s}include" % xi_url

    arch_xml = ET.Element(
            'architecture', {},
        nsmap = {'xi': xi_url},
    )

    model_xml = ET.SubElement(arch_xml, 'models')
    for tile_type in tile_types:
        ET.SubElement(model_xml, xi_include, {
            'href': tile_model.format(tile_type.lower()),
            'xpointer':"xpointer(models/child::node())",
        })

    complexblocklist_xml = ET.SubElement(arch_xml, 'complexblocklist')
    for tile_type in tile_types:
        ET.SubElement(complexblocklist_xml, xi_include, {
            'href': tile_pbtype.format(tile_type.lower()),
        })

    layout_xml = ET.SubElement(arch_xml, 'layout')
    db = prjxray.db.Database(os.path.join(prjxray_db, args.part))
    g = db.grid()
    x_min, x_max, y_min, y_max = g.dims()

    name = '{}-test'.format(args.device)
    fixed_layout_xml = ET.SubElement(layout_xml, 'fixed_layout', {
            'name': name,
            'height': str(y_max+1),
            'width': str(x_max+1),
    })

    only_emit_roi = False
    roi_inputs = []
    roi_outputs = []

    synth_tiles = {}
    synth_tiles['tiles'] = {}
    if args.use_roi:
        only_emit_roi = True
        with open(args.use_roi) as f:
            j = json.load(f)

        roi = Roi(
                db=db,
                x1=j['info']['GRID_X_MIN'],
                y1=j['info']['GRID_Y_MIN'],
                x2=j['info']['GRID_X_MAX'],
                y2=j['info']['GRID_Y_MAX'],
                )

        synth_tiles['info'] = j['info']
        for port in j['ports']:
            if port['name'].startswith('dout['):
                roi_outputs.append(port)
                port_type = 'input'
                is_clock = False
            elif port['name'].startswith('din['):
                roi_inputs.append(port)
                is_clock = False
                port_type = 'output'
            elif port['name'].startswith('clk'):
                roi_inputs.append(port)
                port_type = 'output'
                is_clock = True
            else:
                assert False, port

            tile, wire = port['wire'].split('/')

            # Make sure connecting wire is not in ROI!
            loc = g.loc_of_tilename(tile)
            if roi.tile_in_roi(loc):
                # Or if in the ROI, make sure it has no sites.
                gridinfo = g.gridinfo_at_tilename(tile)
                assert len(db.get_tile_type(gridinfo.tile_type).get_sites()) == 0, tile



            if tile not in synth_tiles['tiles']:
                synth_tiles['tiles'][tile] = {
                        'pins': [],
                        'loc': g.loc_of_tilename(tile),
                }

            synth_tiles['tiles'][tile]['pins'].append({
                    'roi_name': port['name'].replace('[', '_').replace(']','_'),
                    'wire': wire,
                    'pad': port['pin'],
                    'port_type': port_type,
                    'is_clock': is_clock,
            })

        with open(args.synth_tiles, 'w') as f:
            json.dump(synth_tiles, f)

        synth_tile_map = add_synthetic_tile(complexblocklist_xml)

    for loc in g.tile_locations():
        gridinfo = g.gridinfo_at_loc(loc)
        tile = g.tilename_at_loc(loc)

        if tile in synth_tiles['tiles']:
            synth_tile = synth_tiles['tiles'][tile]

            assert len(synth_tile['pins']) == 1

            vpr_tile_type = synth_tile_map[synth_tile['pins'][0]['port_type']]
        elif only_emit_roi and not roi.tile_in_roi(loc):
            # This tile is outside the ROI, skip it.
            continue
        elif gridinfo.tile_type in tile_types:
            # We want to import this tile type.
            vpr_tile_type = 'BLK_TI-{}'.format(gridinfo.tile_type)
        else:
            # We don't want this tile
            continue

        is_vbrk = gridinfo.tile_type.find('VBRK') != -1

        # VBRK tiles are known to have no bitstream data.
        if not is_vbrk and not gridinfo.bits:
            print('*** WARNING *** Skipping tile {} because it lacks bitstream data.'.format(tile),
                    file=sys.stderr)

        single_xml = ET.SubElement(fixed_layout_xml, 'single', {
                'priority': '1',
                'type': vpr_tile_type,
                'x': str(loc[0]),
                'y': str(loc[1]),
        })
        meta = ET.SubElement(single_xml, 'metadata')
        ET.SubElement(meta, 'meta', {
                'name': 'fasm_prefix',
        }).text = tile

    device_xml = ET.SubElement(arch_xml, 'device')

    ET.SubElement(device_xml, 'sizing', {
            "R_minW_nmos":"6065.520020",
            "R_minW_pmos":"18138.500000",
    })
    ET.SubElement(device_xml, 'area', {
            "grid_logic_tile_area":"14813.392",
    })
    ET.SubElement(device_xml, 'connection_block', {
            "input_switch_name":"buffer",
    })
    ET.SubElement(device_xml, 'switch_block', {
            "type":"wilton",
            "fs":"3",
    })
    chan_width_distr_xml = ET.SubElement(device_xml, 'chan_width_distr')

    ET.SubElement(chan_width_distr_xml, 'x', {
            'distr':'uniform',
            'peak':'1.0',
    })
    ET.SubElement(chan_width_distr_xml, 'y', {
            'distr':'uniform',
            'peak':'1.0',
    })

    switchlist_xml = ET.SubElement(arch_xml, 'switchlist')

    ET.SubElement(switchlist_xml, 'switch', {
                  'type':'mux',
                  'name':'routing',
                  "R":"551", "Cin":".77e-15",  "Cout":"4e-15", "Tdel":"6.8e-12",
                  "mux_trans_size":"2.630740",
                  "buf_size":"27.645901"
                  })
    ET.SubElement(switchlist_xml, 'switch', {
                  'type':'mux',
                  'name':'buffer',
                  "R":"551", "Cin":".77e-15",  "Cout":"4e-15", "Tdel":"6.8e-12",
                  "mux_trans_size":"2.630740",
                  "buf_size":"27.645901"
                  })

    segmentlist_xml = ET.SubElement(arch_xml, 'segmentlist')

    # VPR requires a segment, so add one.
    dummy_xml = ET.SubElement(segmentlist_xml, 'segment', {
            'name': 'dummy',
            'length': '12',
            'freq': '1.0',
            'type': 'bidir',
            'Rmetal':'101',
            'Cmetal':'22.5e15',
    })
    ET.SubElement(dummy_xml, 'wire_switch', {
            'name': 'routing',
    })
    ET.SubElement(dummy_xml, 'opin_switch', {
            'name': 'routing',
    })
    ET.SubElement(dummy_xml, 'sb', {
            'type': 'pattern',
    }).text = ' '.join('1' for _ in range(13))
    ET.SubElement(dummy_xml, 'cb', {
            'type': 'pattern',
    }).text = ' '.join('1' for _ in range(12))

    directlist_xml = ET.SubElement(arch_xml, 'directlist')

    pin_assignments = json.load(args.pin_assignments)

    # Choose smallest distance for block to block connections with multiple
    # direct_connections.  VPR cannot handle multiple block to block connections.
    directs = {}
    for direct in pin_assignments['direct_connections']:
        key = (direct['from_pin'], direct['to_pin'])

        if key not in directs:
            directs[key] = []

        directs[key].append((abs(direct['x_offset']) + abs(direct['y_offset']), direct))

    for direct in directs.values():
        _, direct = min(direct, key=lambda v: v[0])

        if direct['from_pin'].split('.')[0] not in tile_types:
            continue
        if direct['to_pin'].split('.')[0] not in tile_types:
            continue

        if direct['x_offset'] == 0 and direct['y_offset'] == 0:
            continue

        ET.SubElement(directlist_xml, 'direct', {
                'name': '{}_to_{}_dx_{}_dy_{}'.format(direct['from_pin'], direct['to_pin'], direct['x_offset'], direct['y_offset']),
                'from_pin': 'BLK_TI-' + direct['from_pin'],
                'to_pin': 'BLK_TI-' + direct['to_pin'],
                'x_offset': str(direct['x_offset']),
                'y_offset': str(direct['y_offset']),
                'z_offset': '0',
                'switch_name': direct['switch_name'],
        })


    arch_xml_str = ET.tostring(arch_xml, pretty_print=True).decode('utf-8')
    args.output_arch.write(arch_xml_str)
    args.output_arch.close()

if __name__ == '__main__':
    main()
