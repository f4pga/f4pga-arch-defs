"""Import timing information from icestorm generated SDF file and updates
timing in the architecture file.
"""

import argparse
from sdf_timing.sdfparse import parse as sdf_parse
import lxml.etree as ET
import re
import logging
from collections import namedtuple


class PinMap(namedtuple('PinMap', 'sdf arch is_clk')):
    """Mapping of names between sdf file and arch_def. Contains names in each
    location and if it is a clock. This used to generate correct timing
    annotations for the VPR xml architecture.
    """


"""
Full mapping for mapping between architecture definition names and sdf information

keys are names of pb_type, values are tuple of sdf cell type and list of PinMaps
"""
_arch_to_sdf = {
    'LUT4':
        (
            'LogicCell40', [
                PinMap('in0', 'in[0]', False),
                PinMap('in1', 'in[1]', False),
                PinMap('in2', 'in[2]', False),
                PinMap('in3', 'in[3]', False),
                PinMap('lcout', 'out', False)
            ]
        ),
    'SB_LUT4':
        (
            'LogicCell40', [
                PinMap('in0', 'I0', False),
                PinMap('in1', 'I1', False),
                PinMap('in2', 'I2', False),
                PinMap('in3', 'I3', False),
                PinMap('lcout', 'O', False)
            ]
        ),
    'SB_RAM256x16':
        (
            'SB_RAM40_4K', [
                PinMap('RDATA[0]', 'RDATA[0]', False),
                PinMap('RDATA[1]', 'RDATA[1]', False),
                PinMap('RDATA[2]', 'RDATA[2]', False),
                PinMap('RDATA[3]', 'RDATA[3]', False),
                PinMap('RDATA[4]', 'RDATA[4]', False),
                PinMap('RDATA[5]', 'RDATA[5]', False),
                PinMap('RDATA[6]', 'RDATA[6]', False),
                PinMap('RDATA[7]', 'RDATA[7]', False),
                PinMap('RDATA[8]', 'RDATA[8]', False),
                PinMap('RDATA[9]', 'RDATA[9]', False),
                PinMap('RDATA[10]', 'RDATA[10]', False),
                PinMap('RDATA[11]', 'RDATA[11]', False),
                PinMap('RDATA[12]', 'RDATA[12]', False),
                PinMap('RDATA[13]', 'RDATA[13]', False),
                PinMap('RDATA[14]', 'RDATA[14]', False),
                PinMap('RDATA[15]', 'RDATA[15]', False),
                PinMap('RCLK', 'RCLK', True),
                PinMap('RE', 'RE', False),
                PinMap('RCLKE', 'RCLKE', False),
                PinMap('RADDR[0]', 'RADDR[0]', False),
                PinMap('RADDR[1]', 'RADDR[1]', False),
                PinMap('RADDR[2]', 'RADDR[2]', False),
                PinMap('RADDR[3]', 'RADDR[3]', False),
                PinMap('RADDR[4]', 'RADDR[4]', False),
                PinMap('RADDR[5]', 'RADDR[5]', False),
                PinMap('RADDR[6]', 'RADDR[6]', False),
                PinMap('RADDR[7]', 'RADDR[7]', False),
                PinMap('RADDR[8]', 'RADDR[8]', False),
                PinMap('RADDR[9]', 'RADDR[9]', False),
                PinMap('RADDR[10]', 'RADDR[10]', False),
                PinMap('WDATA[0]', 'WDATA[0]', False),
                PinMap('WDATA[1]', 'WDATA[1]', False),
                PinMap('WDATA[2]', 'WDATA[2]', False),
                PinMap('WDATA[3]', 'WDATA[3]', False),
                PinMap('WDATA[4]', 'WDATA[4]', False),
                PinMap('WDATA[5]', 'WDATA[5]', False),
                PinMap('WDATA[6]', 'WDATA[6]', False),
                PinMap('WDATA[7]', 'WDATA[7]', False),
                PinMap('WDATA[8]', 'WDATA[8]', False),
                PinMap('WDATA[9]', 'WDATA[9]', False),
                PinMap('WDATA[10]', 'WDATA[10]', False),
                PinMap('WDATA[11]', 'WDATA[11]', False),
                PinMap('WDATA[12]', 'WDATA[12]', False),
                PinMap('WDATA[13]', 'WDATA[13]', False),
                PinMap('WDATA[14]', 'WDATA[14]', False),
                PinMap('WDATA[15]', 'WDATA[15]', False),
                PinMap('WCLK', 'WCLK', True),
                PinMap('WE', 'WE', False),
                PinMap('WCLKE', 'WCLKE', False),
                PinMap('WADDR[0]', 'WADDR[0]', False),
                PinMap('WADDR[1]', 'WADDR[1]', False),
                PinMap('WADDR[2]', 'WADDR[2]', False),
                PinMap('WADDR[3]', 'WADDR[3]', False),
                PinMap('WADDR[4]', 'WADDR[4]', False),
                PinMap('WADDR[5]', 'WADDR[5]', False),
                PinMap('WADDR[6]', 'WADDR[6]', False),
                PinMap('WADDR[7]', 'WADDR[7]', False),
                PinMap('WADDR[8]', 'WADDR[8]', False),
                PinMap('WADDR[9]', 'WADDR[9]', False),
                PinMap('WADDR[10]', 'WADDR[10]', False),
                PinMap('MASK[0]', 'MASK[0]', False),
                PinMap('MASK[1]', 'MASK[1]', False),
                PinMap('MASK[2]', 'MASK[2]', False),
                PinMap('MASK[3]', 'MASK[3]', False),
                PinMap('MASK[4]', 'MASK[4]', False),
                PinMap('MASK[5]', 'MASK[5]', False),
                PinMap('MASK[6]', 'MASK[6]', False),
                PinMap('MASK[7]', 'MASK[7]', False),
                PinMap('MASK[8]', 'MASK[8]', False),
                PinMap('MASK[9]', 'MASK[9]', False),
                PinMap('MASK[10]', 'MASK[10]', False),
                PinMap('MASK[11]', 'MASK[11]', False),
                PinMap('MASK[12]', 'MASK[12]', False),
                PinMap('MASK[13]', 'MASK[13]', False),
                PinMap('MASK[14]', 'MASK[14]', False),
                PinMap('MASK[15]', 'MASK[15]', False),
            ]
        ),
    'SB_CARRY': ('ICE_CARRY_IN_MUX', [])
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

    parser.add_argument('-v', type=bool, help='verbose output')

    logging.basicConfig(level=logging.WARNING)

    args = parser.parse_args()
    timing = sdf_parse(args.read_sdf.read())

    tree = ET.parse(args.read_arch_xml, ET.XMLParser(remove_blank_text=True))

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
    #root = tree.getroot()
    for el in tree.iter('pb_type'):
        pb_name = el.attrib['name']
        # insert timing tags from SDF file
        if pb_name in _arch_to_sdf.keys():
            cell_name, pin_table = _arch_to_sdf.get(pb_name, None)
            for timing in flat_timing[cell_name]:

                def try_translate_pin(table, timing, name):
                    res = [
                        entry for entry in table if entry.sdf == timing[name]
                    ]
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
                    attribs = {
                        'clock': frompin.arch,
                        'port': '{}.{}'.format(pb_name, topin.arch),
                        'value': get_pessimistic(timing)
                    }
                    hold_setup_el = ET.SubElement(
                        el, 'T_{}'.format(timing['type']), attribs
                    )
                    # hold_setup_el.tail = '\n'
                    logging.info(ET.tostring(hold_setup_el))
                elif timing['type'] == 'iopath':
                    topin = try_translate_pin(pin_table, timing, 'to_pin')
                    frompin = try_translate_pin(pin_table, timing, 'from_pin')
                    if topin is None or frompin is None:
                        continue
                    if frompin.is_clk:
                        attribs = {
                            'clock': '{}'.format(frompin.arch),
                            'port': '{}.{}'.format(pb_name, topin.arch),
                            'max': get_pessimistic(timing)
                        }
                        iopath_el = ET.SubElement(el, 'T_clock_to_Q', attribs)
                        # iopath_el.tail = '\n'
                    else:
                        attribs = {
                            'in_port': '{}.{}'.format(pb_name, frompin.arch),
                            'out_port': '{}.{}'.format(pb_name, topin.arch),
                            'max': get_pessimistic(timing)
                        }
                        iopath_el = ET.SubElement(
                            el, 'delay_constant', attribs
                        )
                        # iopath_el.tail = '\n'
                    logging.info(ET.tostring(iopath_el))
                elif timing['type'] == 'recovery':
                    pass
                elif timing['type'] == 'removal':
                    pass

    xml_str = ET.tostring(tree, pretty_print=True).decode('utf-8')
    args.write_arch_xml.write(xml_str)


if __name__ == '__main__':
    main()
