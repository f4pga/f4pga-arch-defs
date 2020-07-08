""" Utility for generating TCL script to generate bitstream, project and
checkpoint from fasm2v output.
"""
import argparse


def create_runme(f_out, args):
    print(
        """
create_project -force -part {part} design design

read_verilog {bit_v}
synth_design -top {top}

write_checkpoint -force design_{name}_pre_source.dcp

read_xdc {bit_xdc}
""".format(
            name=args.name,
            bit_v=args.verilog,
            top=args.top,
            bit_xdc=args.routing_xdc,
            part=args.part
        ),
        file=f_out
    )

    if args.clock_pins or args.clock_periods:
        clock_pins = args.clock_pins.split(';')
        clock_periods = args.clock_periods.split(';')
        assert len(clock_pins) == len(clock_periods)
        for clock_pin, clock_period in zip(clock_pins, map(float,
                                                           clock_periods)):
            print(
                """
create_clock -period {period} -name {pin} -waveform {{0.000 {half_period}}} [get_ports {pin}]
""".format(
                    period=clock_period,
                    pin=clock_pin,
                    half_period=clock_period / 2,
                ),
                file=f_out
            )

    if args.additional_xdc:
        print("source {}".format(args.additional_xdc), file=f_out)

    print(
        """

write_checkpoint -force design_{name}_pre_route.dcp
save_project_as -force design_{name}.xpr
close_project

open_checkpoint design_{name}_pre_route.dcp

set conflict_nets [get_nets -filter {{ ROUTE_STATUS == "CONFLICTS" }}]
if {{$conflict_nets != ""}} {{
    puts "There are conflicting nets!"

    foreach net $conflict_nets {{
        puts $net
    }}
    error "Exiting!"
}}

set unrouted_nets [get_nets -filter {{ ROUTE_STATUS == "UNROUTED" }}]

set antenna_nets [get_nets -filter {{ ROUTE_STATUS == "ANTENNAS" }}]

set partial_nets [get_nets -filter {{ ROUTE_STATUS == "PARTIAL" }}]

set nets_to_route "$unrouted_nets $antenna_nets $partial_nets"

set_property IS_ENABLED 0 [get_drc_checks *]

report_route_status
foreach net $nets_to_route {{
    route_design -nets [get_nets $net]
}}

set_property IS_ENABLED 1 [get_drc_checks *]
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property BITSTREAM.GENERAL.PERFRAMECRC YES [current_design]
set_property IS_ENABLED 0 [get_drc_checks {{LUTLP-1}}]

report_utilization -file design_{name}_utilization.rpt
report_clock_utilization -file design_{name}_clock_utilization.rpt
report_timing_summary -datasheet -max_paths 10 -file design_{name}_timing_summary.rpt
report_power -file design_{name}_power.rpt
report_route_status -file design_{name}_route_status.rpt

write_checkpoint -force design_{name}.dcp
write_bitstream -force design_{name}.bit
save_project_as -force design_{name}.xpr

report_timing_summary
""".format(name=args.name),
        file=f_out
    )


def main():
    parser = argparse.ArgumentParser(description=__doc__)

    parser.add_argument(
        '--name', help="Name to postfix outputs.", required=True
    )
    parser.add_argument(
        '--verilog', help="Input verilog file to build.", required=True
    )
    parser.add_argument(
        '--routing_xdc',
        help="TCL script to run after synthesis to add static routing.",
        required=True
    )
    parser.add_argument('--top', help="Top-level module name.", required=True)
    parser.add_argument(
        '--part', help="Part number to build for.", required=True
    )
    parser.add_argument(
        '--clock_pins',
        help="Semi-colon seperated list of clock pins.",
        required=False
    )
    parser.add_argument(
        '--clock_periods',
        help="Semi-colon seperated list of clock periods (in ns).",
        required=False
    )
    parser.add_argument(
        '--output_tcl', help="Filename of output TCL file.", required=True
    )
    parser.add_argument(
        '--additional_xdc',
        help="Filename of additional XDC file.",
    )

    args = parser.parse_args()
    with open(args.output_tcl, 'w') as f:
        create_runme(f, args)


if __name__ == "__main__":
    main()
