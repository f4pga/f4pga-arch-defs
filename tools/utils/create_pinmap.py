import json
import csv
import argparse
from collections import namedtuple


def get_module_ports(j, module):
    if module not in j['modules']:
        raise LookupError(
            'module %s not in module list %s' %
            (module, ', '.join(j['modules'].keys()))
        )

    for port in j['modules'][module]['ports']:
        bits = j['modules'][module]['ports'][port]['bits']
        if len(bits) > 1:
            for idx, _ in enumerate(bits):
                yield j['modules'][module]['ports'][port][
                    'direction'], '%s[%d]' % (port, idx)
        else:
            yield j['modules'][module]['ports'][port]['direction'], port


Pin = namedtuple('Pin', 'name is_clock is_input is_output')


def get_free_pin(available_pins, direction):
    possible_pins = []
    for pin in available_pins:
        if pin.is_input and not pin.is_clock and direction == 'input':
            possible_pins.append(pin)
        if pin.is_output and direction == 'output':
            possible_pins.append(pin)
    assert possible_pins, "Did not find any *%s* pins in:\n%s" % (
        direction, "\n  ".join(str(x) for x in available_pins)
    )
    return possible_pins.pop(0)


def main():
    parser = argparse.ArgumentParser(
        description='Creates a pinmap file for a module for a given package.'
    )

    parser.add_argument('--design_json', help='Yosys JSON design input.')
    parser.add_argument('--pinmap_csv', help='CSV pinmap definition.')
    parser.add_argument(
        '--module', help='Name of module to generate pindef for.'
    )

    args = parser.parse_args()

    # Read in the pin map
    pins = []
    with open(args.pinmap_csv) as f:
        for row in csv.DictReader(f):
            if 'is_clock' in row:
                is_clock = int(row['is_clock']) != 0
            else:
                is_clock = False

            if 'is_input' in row:
                is_input = int(row['is_input']) != 0
            else:
                is_input = True

            if 'is_output' in row:
                is_output = int(row['is_output']) != 0
            else:
                is_output = True

            pins.append(
                Pin(
                    name=row['name'],
                    is_clock=is_clock,
                    is_input=is_input,
                    is_output=is_output,
                )
            )

    available_pins = list(pins)

    # Read in the design and assign pins
    import sys
    with open(args.design_json) as f:
        j = json.load(f)
        for direction, port in get_module_ports(j, args.module):
            pin = get_free_pin(available_pins, direction)
            sys.stderr.write(
                "Assigned %s to %s # %s\n" % (port, pin.name, direction)
            )
            print('set_io %s %s' % (port, pin.name))
            available_pins.remove(pin)


if __name__ == '__main__':
    main()
