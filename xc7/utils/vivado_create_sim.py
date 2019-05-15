""" Utility for generating TCL script to launch simulation on Vivado
"""
import argparse


def create_sim(f_out, args):
    print("""
launch_simulation
""", file=f_out)

    clock_pins = args.clock_pins.split(';')
    clock_periods = args.clock_periods.split(';')
    assert len(clock_pins) == len(clock_periods)
    for clock_pin, clock_period in zip(clock_pins, map(float, clock_periods)):
        print(
            """
add_force {{/{top}/{pin}}} -radix hex {{0 0ns}} {{1 {half_period}ns}} -repeat_every {period}ns
""".format(
                top=args.top,
                pin=clock_pin,
                half_period=clock_period / 2.0,
                period=clock_period,
            ),
            file=f_out
        )

    print("""
restart
run 1us
run 1us
""", file=f_out)


def main():
    parser = argparse.ArgumentParser(description=__doc__)

    parser.add_argument('--top', help="Top-level module name.", required=True)
    parser.add_argument(
        '--clock_pins',
        help="Semi-colon seperated list of clock pins.",
        required=True
    )
    parser.add_argument(
        '--clock_periods',
        help="Semi-colon seperated list of clock periods (in ns).",
        required=True
    )
    parser.add_argument(
        '--output_tcl', help="Filename of output TCL file.", required=True
    )

    args = parser.parse_args()
    with open(args.output_tcl, 'w') as f:
        create_sim(f, args)


if __name__ == "__main__":
    main()
