"""Import timing information from icestorm generated SDF file and updates
timing in the architecture file.
"""

import argparse
from sdf_timing.sdfparse import parse as sdf_parse
import lxml.etree as ET
import re
import logging
from collections import namedtuple

class pin_map(namedtuple('pin_map', 'sdf arch is_clk')):
    """
    """

"""
arch_name  - (sdfcelltype, [pin_map ] )
"""

_arch_to_sdf = {
    'BLK_IG-LUT4': ('LogicCell40', [
        pin_map('in0', 'in[0]', False),
        pin_map('in1', 'in[1]', False),
        pin_map('in2', 'in[2]', False),
        pin_map('in3', 'in[3]', False),
        pin_map('lcout', 'out', False)
    ]
    ),
    'BLK_IG-SB_LUT4': ('LogicCell40', [
        pin_map('in0', 'I0', False),
        pin_map('in1', 'I1', False),
        pin_map('in2', 'I2', False),
        pin_map('in3', 'I3', False),
        pin_map('lcout', 'O', False)
    ]
    ),
    'SB_RAM256x16': ('SB_RAM40_4K', [
        pin_map('RDATA[0]', 'RDATA[0]', False),
        pin_map('RDATA[1]', 'RDATA[1]', False),
        pin_map('RDATA[2]', 'RDATA[2]', False),
        pin_map('RDATA[3]', 'RDATA[3]', False),
        pin_map('RDATA[4]', 'RDATA[4]', False),
        pin_map('RDATA[5]', 'RDATA[5]', False),
        pin_map('RDATA[6]', 'RDATA[6]', False),
        pin_map('RDATA[7]', 'RDATA[7]', False),
        pin_map('RDATA[8]', 'RDATA[8]', False),
        pin_map('RDATA[9]', 'RDATA[9]', False),
        pin_map('RDATA[10]', 'RDATA[10]', False),
        pin_map('RDATA[11]', 'RDATA[11]', False),
        pin_map('RDATA[12]', 'RDATA[12]', False),
        pin_map('RDATA[13]', 'RDATA[13]', False),
        pin_map('RDATA[14]', 'RDATA[14]', False),
        pin_map('RDATA[15]', 'RDATA[15]', False),
        pin_map('RCLK', 'RCLK', True),
        pin_map('RE', 'RE', False),
        pin_map('RCLKE', 'RCLKE', False),
        pin_map('RADDR[0]', 'RADDR[0]', False),
        pin_map('RADDR[1]', 'RADDR[1]', False),
        pin_map('RADDR[2]', 'RADDR[2]', False),
        pin_map('RADDR[3]', 'RADDR[3]', False),
        pin_map('RADDR[4]', 'RADDR[4]', False),
        pin_map('RADDR[5]', 'RADDR[5]', False),
        pin_map('RADDR[6]', 'RADDR[6]', False),
        pin_map('RADDR[7]', 'RADDR[7]', False),
        pin_map('RADDR[8]', 'RADDR[8]', False),
        pin_map('RADDR[9]', 'RADDR[9]', False),
        pin_map('RADDR[10]', 'RADDR[10]', False),

        pin_map('WDATA[0]', 'WDATA[0]', False),
        pin_map('WDATA[1]', 'WDATA[1]', False),
        pin_map('WDATA[2]', 'WDATA[2]', False),
        pin_map('WDATA[3]', 'WDATA[3]', False),
        pin_map('WDATA[4]', 'WDATA[4]', False),
        pin_map('WDATA[5]', 'WDATA[5]', False),
        pin_map('WDATA[6]', 'WDATA[6]', False),
        pin_map('WDATA[7]', 'WDATA[7]', False),
        pin_map('WDATA[8]', 'WDATA[8]', False),
        pin_map('WDATA[9]', 'WDATA[9]', False),
        pin_map('WDATA[10]', 'WDATA[10]', False),
        pin_map('WDATA[11]', 'WDATA[11]', False),
        pin_map('WDATA[12]', 'WDATA[12]', False),
        pin_map('WDATA[13]', 'WDATA[13]', False),
        pin_map('WDATA[14]', 'WDATA[14]', False),
        pin_map('WDATA[15]', 'WDATA[15]', False),
        pin_map('WCLK', 'WCLK', True),
        pin_map('WE', 'WE', False),
        pin_map('WCLKE', 'WCLKE', False),
        pin_map('WADDR[0]', 'WADDR[0]', False),
        pin_map('WADDR[1]', 'WADDR[1]', False),
        pin_map('WADDR[2]', 'WADDR[2]', False),
        pin_map('WADDR[3]', 'WADDR[3]', False),
        pin_map('WADDR[4]', 'WADDR[4]', False),
        pin_map('WADDR[5]', 'WADDR[5]', False),
        pin_map('WADDR[6]', 'WADDR[6]', False),
        pin_map('WADDR[7]', 'WADDR[7]', False),
        pin_map('WADDR[8]', 'WADDR[8]', False),
        pin_map('WADDR[9]', 'WADDR[9]', False),
        pin_map('WADDR[10]', 'WADDR[10]', False),

        pin_map('MASK[0]', 'MASK[0]', False),
        pin_map('MASK[1]', 'MASK[1]', False),
        pin_map('MASK[2]', 'MASK[2]', False),
        pin_map('MASK[3]', 'MASK[3]', False),
        pin_map('MASK[4]', 'MASK[4]', False),
        pin_map('MASK[5]', 'MASK[5]', False),
        pin_map('MASK[6]', 'MASK[6]', False),
        pin_map('MASK[7]', 'MASK[7]', False),
        pin_map('MASK[8]', 'MASK[8]', False),
        pin_map('MASK[9]', 'MASK[9]', False),
        pin_map('MASK[10]', 'MASK[10]', False),
        pin_map('MASK[11]', 'MASK[11]', False),
        pin_map('MASK[12]', 'MASK[12]', False),
        pin_map('MASK[13]', 'MASK[13]', False),
        pin_map('MASK[14]', 'MASK[14]', False),
        pin_map('MASK[15]', 'MASK[15]', False),

    ]
    ),
    'SB_CARRY': ('ICE_CARRY_IN_MUX', [
    ]
    )
}

def get_scale(timescale):
    """Convert sdf timescale to scale factor

    >>> get_scale('1.0 fs')
    1e-15

    >>> get_scale('1ps')
    1e-12

    >>> get_scale('10 ns')
    1e-08

    >>> get_scale('10.0 us')
    9.999999999999999e-06

    >>> get_scale('100.0ms')
    0.1

    >>> get_scale('100 s')
    100.0

    """
    mm = re.match(r'(10{0,2})(\.0)? *([munpf]?s)', timescale)
    sc_lut = {
        's': 1.0,
        'ms': 1e-3,
        'us': 1e-6,
        'ns': 1e-9,
        'ps': 1e-12,
        'fs': 1e-15,
    }
    ret = None
    if mm:
        base, _, sc = mm.groups()
        ret = int(base) * sc_lut[sc]
    return ret


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        '--read_sdf',
        type=argparse.FileType('r'),
        help='sdf file to read timing from'
    )
    parser.add_argument(
        '--read_arch_xml',
        type=argparse.FileType('r'),
        help='arch xml file to read and update/add timing'
    )
    parser.add_argument(
        '--write_arch_xml',
        type=argparse.FileType('w'),
        help='arch xml file to write with updaed timing calues'
    )

    parser.add_argument(
        '-v',
        type=bool,
        help='verbose output'
    )

    logging.basicConfig(level=logging.INFO)

    args = parser.parse_args()
    timing = sdf_parse(args.read_sdf.read())

    tree = ET.parse(args.read_arch_xml)

    scale = get_scale(timing['header']['timescale'])
    #logging.info('sdf scale set to', scale)

    # flatten cells to list of max
    flat_timing = dict()
    for cell_name, cell in timing['cells'].items():
        flat_timing[cell_name] = []
        for instance_key, instance in cell.items():
            assert instance_key == '*', \
               'For iCE40 expect only wildcard instance {} in cell {}'.format(
                   instance_key, cell_name
               )
            for _, path in instance.items():
                flat_timing[cell_name].append(path)

    for key, time_list in flat_timing.items():
        logging.debug(key)
        for delay in time_list:
            logging.debug(delay)

    # look up parsed sdf on in from_pin, to_pin, and type
    def lookup_timing(timing_list, type, to_pin, from_pin):
        ret = []
        for xx in timing_list:
            if type == xx['type'] and xx['to_pin'].startswith(
                    to_pin) and xx['from_pin'].startswith(from_pin):
                ret.append(xx)
            else:
                pass
        return ret

    def get_pessimistic(timing):
        vals = []
        for del_type in timing['delay_paths'].values():
            for dels in del_type.values():
                vals.append(dels)
        max_del = max(vals)
        return str(max_del * scale)

    # TODO: need to take max across negedge and posedge

    # remove all existing tags and warn on them

    # iterate over existing arch and update/add delay tags
    for el in tree.iter():
        if el.tag == 'pb_type':
            pb_name = el.attrib['name']
            # insert timing tags from SDF file
            if pb_name in _arch_to_sdf.keys():
                cell_name, pin_table = _arch_to_sdf.get(pb_name, None)
                for timing in flat_timing[cell_name]:
                    def try_translate_pin(table, timing, name):
                        res = [entry for entry in table if entry.sdf == timing[name]]
                        assert len(res) <= 1

                        if len(res) == 1:
                            return res[0]
                        else:
                            return None

                    if timing['type'] == 'hold' or timing['type'] == 'setup':
                        topin = try_translate_pin(pin_table, timing, 'to_pin')
                        frompin = try_translate_pin(pin_table, timing, 'from_pin')
                        if topin is None or frompin is None:
                            continue
                        attribs = {'clock': frompin.arch,
                                   'port': '{}.{}'.format(pb_name, topin.arch),
                                   'value': get_pessimistic(timing)
                        }
                        hold_setup_el = ET.SubElement(el, 'T_hold', attribs)
                        logging.info(ET.tostring(hold_setup_el))
                    elif timing['type'] == 'iopath':
                        topin = try_translate_pin(pin_table, timing, 'to_pin')
                        frompin = try_translate_pin(pin_table, timing, 'from_pin')
                        if topin is None or frompin is None:
                            continue
                        if frompin.is_clk:
                            attribs = {'clock': '{}'.format(frompin.arch),
                            'port': '{}.{}'.format(pb_name, topin.arch),
                            'max': get_pessimistic(timing)
                            }
                            iopath_el = ET.SubElement(el, 'T_clock_to_Q', attribs)
                        else:
                            attribs = {'in_port': '{}.{}'.format(pb_name, frompin.arch),
                            'out_port': '{}.{}'.format(pb_name, topin.arch),
                            'max': get_pessimistic(timing)
                            }
                            iopath_el = ET.SubElement(el, 'delay_constant', attribs)
                        logging.info(ET.tostring(iopath_el))
                    elif timing['type'] == 'recovery':
                        pass
                    elif timing['type'] == 'removal':
                        pass
                    # T_clock_to_Q

    tree.write(args.write_arch_xml.name)

if __name__ == '__main__':
    main()
