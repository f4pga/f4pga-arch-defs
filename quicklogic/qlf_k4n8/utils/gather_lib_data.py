#!/usr/bin/env python3
"""
Gather data from given lib file. This data is then used to populate JSON file
that has delay numbers for some parameters related to F2A and A2F pins.
"""
import argparse
from collections import defaultdict

# =============================================================================


def main():
    """
    Gather lib information from the given library file
    """
    parser = argparse.ArgumentParser(
        description='Gather lib information from the given library file.'
    )
    parser.add_argument(
        "--lib",
        "-l",
        "-L",
        type=str,
        required=True,
        help='Specify input lib file'
    )

    args = parser.parse_args()

    lib_fp = open(args.lib, newline='')

    for line in lib_fp:
        if line.find("bus ( gfpga_pad_IO_A2F") != -1:
            a2f_process_lib_data(lib_fp)
        elif line.find("bus ( gfpga_pad_IO_F2A") != -1:
            f2a_process_lib_data(lib_fp)


# =============================================================================


def f2a_process_lib_data(lib_fp):
    """
    Process F2A pin lib_data
    """
    f2a_data_max = defaultdict(set)
    f2a_data_min = defaultdict(set)
    max_transition = set()
    capacitance = set()
    for f2a_line in lib_fp:

        pin_pos = f2a_line.find("pin(\"")
        if pin_pos != -1:

            for pin_line in lib_fp:
                if pin_line.find("rising_edge") != -1:
                    f2a_data_max, f2a_data_min = f2a_timing_type(
                        lib_fp, pin_line, "rising_edge", f2a_data_max,
                        f2a_data_min
                    )
                elif pin_line.find("max_transition") != -1:
                    val_list = pin_line.split(' : ')
                    max_transition.add(
                        float(val_list[1].split(' ;')[0].strip())
                    )
                elif pin_line.find("capacitance") != -1:
                    val_list = pin_line.split(' : ')
                    capacitance.add(float(val_list[1].split(' ;')[0].strip()))
                elif pin_line.find("end of bus") != -1:
                    break

            print(
                'F2A {} least_val: {}, highest_val: {}'.format(
                    "max_transition", next(iter(sorted(max_transition))),
                    sorted(max_transition).pop()
                )
            )
            print(
                'F2A {} least_val: {}, highest_val: {}'.format(
                    "capacitance", next(iter(sorted(capacitance))),
                    sorted(capacitance).pop()
                )
            )
            print(
                'F2A {} least_val: {}, highest_val: {}'.format(
                    "rising_edge_cell_rise_val",
                    next(iter(sorted(f2a_data_min['rising_edge_cell_rise']))),
                    sorted(f2a_data_max['rising_edge_cell_rise']).pop()
                )
            )
            print(
                'F2A {} least_val: {}, highest_val: {}'.format(
                    "rising_edge_cell_fall_val",
                    next(iter(sorted(f2a_data_min['rising_edge_cell_fall']))),
                    sorted(f2a_data_max['rising_edge_cell_fall']).pop()
                )
            )
            print(
                'F2A {} least_val: {}, highest_val: {}'.format(
                    "rising_edge_rise_tran_val",
                    next(iter(sorted(f2a_data_min['rising_edge_rise_tran']))),
                    sorted(f2a_data_max['rising_edge_rise_tran']).pop()
                )
            )
            print(
                'F2A {} least_val: {}, highest_val: {}'.format(
                    "rising_edge_fall_tran_val",
                    next(iter(sorted(f2a_data_min['rising_edge_fall_tran']))),
                    sorted(f2a_data_max['rising_edge_fall_tran']).pop()
                )
            )
            break


# =============================================================================


def a2f_process_lib_data(lib_fp):
    """
    Process A2F pin lib_data
    """
    a2f_data_max = defaultdict(set)
    a2f_data_min = defaultdict(set)

    max_transition = set()
    capacitance = set()
    for a2f_line in lib_fp:

        pin_pos = a2f_line.find("pin(\"")
        if pin_pos != -1:

            for pin_line in lib_fp:
                if pin_line.find("setup_rising") != -1:
                    a2f_data_max, a2f_data_min = a2f_timing_type(
                        lib_fp, pin_line, "setup_rising", a2f_data_max,
                        a2f_data_min
                    )
                elif pin_line.find("hold_rising") != -1:
                    a2f_data_max, a2f_data_min = a2f_timing_type(
                        lib_fp, pin_line, "hold_rising", a2f_data_max,
                        a2f_data_min
                    )
                elif pin_line.find("max_transition") != -1:
                    val_list = pin_line.split(' : ')
                    max_transition.add(
                        float(val_list[1].split(' ;')[0].strip())
                    )
                elif pin_line.find("capacitance") != -1:
                    val_list = pin_line.split(' : ')
                    capacitance.add(float(val_list[1].split(' ;')[0].strip()))
                elif pin_line.find("end of bus gfpga_pad_IO_A2F") != -1:
                    break

            print(
                'A2F {} least_val: {}, highest_val: {}'.format(
                    "max_transition", next(iter(sorted(max_transition))),
                    sorted(max_transition).pop()
                )
            )
            print(
                'A2F {} least_val: {}, highest_val: {}'.format(
                    "capacitance", next(iter(sorted(capacitance))),
                    sorted(capacitance).pop()
                )
            )
            print(
                'A2F {} least_val: {}, highest_val: {}'.format(
                    "setup_rising_rise_constraint_val",
                    next(
                        iter(
                            sorted(
                                a2f_data_min['setup_rising_rise_constraint']
                            )
                        )
                    ),
                    sorted(a2f_data_max['setup_rising_rise_constraint']).pop()
                )
            )
            print(
                'A2F {} least_val: {}, highest_val: {}'.format(
                    "setup_rising_fall_constraint_val",
                    next(
                        iter(
                            sorted(
                                a2f_data_min['setup_rising_fall_constraint']
                            )
                        )
                    ),
                    sorted(a2f_data_max['setup_rising_fall_constraint']).pop()
                )
            )
            print(
                'A2F {} least_val: {}, highest_val: {}'.format(
                    "hold_rising_rise_constraint_val",
                    next(
                        iter(
                            sorted(
                                a2f_data_min['hold_rising_rise_constraint']
                            )
                        )
                    ),
                    sorted(a2f_data_max['hold_rising_rise_constraint']).pop()
                )
            )
            print(
                'A2F {} least_val: {}, highest_val: {}'.format(
                    "hold_rising_fall_constraint_val",
                    next(
                        iter(
                            sorted(
                                a2f_data_min['hold_rising_fall_constraint']
                            )
                        )
                    ),
                    sorted(a2f_data_max['hold_rising_fall_constraint']).pop()
                )
            )
            break


# =============================================================================


def a2f_timing_type(lib_fp, pin_line, type_str, a2f_data_max, a2f_data_min):
    """
    Collect A2F pin data
    """
    type_pos = pin_line.find(type_str)
    if type_pos != -1:
        for type_line in lib_fp:
            rise_pos = type_line.find("rise_constraint")
            if rise_pos != -1:
                for constraint_line in lib_fp:
                    if constraint_line.find("}") != -1:
                        break

                    if constraint_line.find('values') != -1:
                        val_set = set()
                        val_set = populate_set(constraint_line, val_set)

                        for val_line in lib_fp:
                            if val_line.find(");") != -1:
                                val_set = populate_set(val_line, val_set)
                                break

                            val_set = populate_set(val_line, val_set)

                        if type_str == "setup_rising":
                            a2f_data_max['setup_rising_rise_constraint'].add(
                                sorted(val_set).pop()
                            )
                            a2f_data_min['setup_rising_rise_constraint'].add(
                                next(iter(sorted(val_set)))
                            )
                        else:
                            a2f_data_max['hold_rising_rise_constraint'].add(
                                sorted(val_set).pop()
                            )
                            a2f_data_min['hold_rising_rise_constraint'].add(
                                next(iter(sorted(val_set)))
                            )
                        break
                break

        for type_line in lib_fp:
            fall_pos = type_line.find("fall_constraint")
            if fall_pos != -1:
                for constraint_line in lib_fp:
                    if constraint_line.find("}") != -1:
                        break

                    if constraint_line.find('values') != -1:
                        val_set = set()
                        val_set = populate_set(constraint_line, val_set)

                        for val_line in lib_fp:
                            if val_line.find(");") != -1:
                                val_set = populate_set(val_line, val_set)
                                break

                            val_set = populate_set(val_line, val_set)

                        if type_str == "setup_rising":
                            a2f_data_max['setup_rising_fall_constraint'].add(
                                sorted(val_set).pop()
                            )
                            a2f_data_min['setup_rising_fall_constraint'].add(
                                next(iter(sorted(val_set)))
                            )
                        else:
                            a2f_data_max['hold_rising_fall_constraint'].add(
                                sorted(val_set).pop()
                            )
                            a2f_data_min['hold_rising_fall_constraint'].add(
                                next(iter(sorted(val_set)))
                            )
                        break
                break

    return a2f_data_max, a2f_data_min


# =============================================================================


def f2a_timing_type(lib_fp, pin_line, type_str, f2a_data_max, f2a_data_min):
    """
    Collect F2A pin data
    """
    type_pos = pin_line.find(type_str)
    if type_pos != -1:
        for type_line in lib_fp:
            rise_pos = type_line.find("cell_rise")
            if rise_pos != -1:
                for constraint_line in lib_fp:
                    if constraint_line.find("}") != -1:
                        break

                    if constraint_line.find('values') != -1:
                        val_set = set()
                        val_set = populate_set(constraint_line, val_set)

                        for val_line in lib_fp:
                            if val_line.find(");") != -1:
                                val_set = populate_set(val_line, val_set)
                                break

                            val_set = populate_set(val_line, val_set)

                        f2a_data_max['rising_edge_cell_rise'].add(
                            sorted(val_set).pop()
                        )
                        f2a_data_min['rising_edge_cell_rise'].add(
                            next(iter(sorted(val_set)))
                        )

                        break
                break

        for type_line in lib_fp:
            fall_pos = type_line.find("rise_transition")
            if fall_pos != -1:
                for constraint_line in lib_fp:
                    if constraint_line.find("}") != -1:
                        break

                    if constraint_line.find('values') != -1:
                        val_set = set()
                        val_set = populate_set(constraint_line, val_set)

                        for val_line in lib_fp:
                            if val_line.find(");") != -1:
                                val_set = populate_set(val_line, val_set)
                                break

                            val_set = populate_set(val_line, val_set)

                        f2a_data_max['rising_edge_rise_tran'].add(
                            sorted(val_set).pop()
                        )
                        f2a_data_min['rising_edge_rise_tran'].add(
                            next(iter(sorted(val_set)))
                        )
                        break
                break

        for type_line in lib_fp:
            fall_pos = type_line.find("cell_fall")
            if fall_pos != -1:
                for constraint_line in lib_fp:
                    if constraint_line.find("}") != -1:
                        break

                    if constraint_line.find('values') != -1:
                        val_set = set()
                        val_set = populate_set(constraint_line, val_set)

                        for val_line in lib_fp:
                            if val_line.find(");") != -1:
                                val_set = populate_set(val_line, val_set)
                                break

                            val_set = populate_set(val_line, val_set)

                        f2a_data_max['rising_edge_cell_fall'].add(
                            sorted(val_set).pop()
                        )
                        f2a_data_min['rising_edge_cell_fall'].add(
                            next(iter(sorted(val_set)))
                        )
                        break
                break

        for type_line in lib_fp:
            fall_pos = type_line.find("fall_transition")
            if fall_pos != -1:
                for constraint_line in lib_fp:
                    if constraint_line.find("}") != -1:
                        break

                    if constraint_line.find('values') != -1:
                        val_set = set()
                        val_set = populate_set(constraint_line, val_set)

                        for val_line in lib_fp:
                            if val_line.find(");") != -1:
                                val_set = populate_set(val_line, val_set)
                                break

                            val_set = populate_set(val_line, val_set)

                        f2a_data_max['rising_edge_fall_tran'].add(
                            sorted(val_set).pop()
                        )
                        f2a_data_min['rising_edge_fall_tran'].add(
                            next(iter(sorted(val_set)))
                        )
                        break
                break

    return f2a_data_max, f2a_data_min


# =============================================================================


def populate_set(line, val_set):
    """
    Collects values and put it in a set
    """
    pos = line.find("\"")
    pos1 = line.rfind("\"")
    sub = line[pos + 1:pos1]
    val_list = sub.split(',')
    for val in val_list:
        val_set.add(float(val.strip()))

    return val_set


# =============================================================================

if __name__ == '__main__':
    main()
