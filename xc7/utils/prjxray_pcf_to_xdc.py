""" Converts simple PCF file to simple XDC file.

Assumes one IOSTANDARD for entire file.  If something else is required,
recommend just using explicit XDC.

"""
import argparse
from lib.parse_pcf import parse_simple_pcf


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--pcf', required=True, help="Input PCF file")
    parser.add_argument('--xdc', required=True, help="Output PCF file")
    parser.add_argument(
        '--iostandard', required=True, help="IOSTANDARD to use"
    )

    args = parser.parse_args()

    with open(args.pcf) as f, open(args.xdc, 'w') as f_out:
        for pcf_constraint in parse_simple_pcf(f):
            print(
                'set_property -dict "PACKAGE_PIN {pin} IOSTANDARD {iostandard}" [get_ports {port}]'
                .format(
                    pin=pcf_constraint.pad,
                    port=pcf_constraint.net,
                    iostandard=args.iostandard
                ),
                file=f_out
            )


if __name__ == "__main__":
    main()
