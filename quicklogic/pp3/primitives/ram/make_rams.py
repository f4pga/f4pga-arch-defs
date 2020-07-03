#!/usr/bin/env python3
import argparse
import os
import re
import json

import lxml.etree as ET
import sdf_timing.sdfparse
from sdf_timing.utils import get_scale_seconds

# =============================================================================

# RAM 2x1 ports, their widths and associated clocks.
# FIXME: Read that from the techfile or phy_db.pickle
RAM_2X1_PORTS = {
    "input":
        [
            # RAM part 1, port 1
            ["WIDTH_SELECT1_0", 2, None],
            ["CLK1EN_0", 1, None],  #"CLK1_0"],
            ["CS1_0", 1, None],  #"CLK1_0"],
            ["A1_0", 11, "CLK1_0"],
            ["WD_0", 18, "CLK1_0"],
            ["WEN1_0", 2, "CLK1_0"],
            ["P1_0", 1, "CLK1_0"],

            # RAM part 1, port 2
            ["WIDTH_SELECT2_0", 2, None],
            ["CLK2EN_0", 1, None],  #"CLK2_0"],
            ["CS2_0", 1, None],  #"CLK2_0"],
            ["A2_0", 11, "CLK2_0"],
            ["P2_0", 1, "CLK2_0"],

            # RAM part 1, common
            ["CONCAT_EN_0", 1, None],
            ["PIPELINE_RD_0", 1, None],
            ["FIFO_EN_0", 1, None],
            ["DIR_0", 1, None],
            ["SYNC_FIFO_0", 1, None],
            ["ASYNC_FLUSH_0", 1, None],

            # RAM part 2, port 1
            ["WIDTH_SELECT1_1", 2, None],
            ["CLK1EN_1", 1, None],  #"CLK1_1"],
            ["CS1_1", 1, None],  #"CLK1_1"],
            ["A1_1", 11, "CLK1_1"],
            ["WD_1", 18, "CLK1_1"],
            ["WEN1_1", 2, "CLK1_1"],
            ["P1_1", 1, "CLK1_1"],

            # RAM part 2, port 2
            ["WIDTH_SELECT2_1", 2, None],
            ["CLK2EN_1", 1, None],  #"CLK2_1"],
            ["CS2_1", 1, None],  #"CLK2_1"],
            ["A2_1", 11, "CLK2_1"],
            ["P2_1", 1, "CLK2_1"],

            # RAM part 2, common
            ["CONCAT_EN_1", 1, None],
            ["PIPELINE_RD_1", 1, None],
            ["FIFO_EN_1", 1, None],
            ["DIR_1", 1, None],
            ["SYNC_FIFO_1", 1, None],
            ["ASYNC_FLUSH_1", 1, None],

            # Common, unknown
            ["DS", 1, None],
            ["DS_RB1", 1, None],
            ["LS", 1, None],
            ["LS_RB1", 1, None],
            ["SD", 1, None],
            ["SD_RB1", 1, None],
            ["RMA", 4, None],
            ["RMB", 4, None],
            ["RMEA", 1, None],
            ["RMEB", 1, None],
            ["TEST1A", 1, None],
            ["TEST1B", 1, None],
        ],
    "clock":
        [
            # RAM part 1
            ["CLK1_0", 1, None],
            ["CLK2_0", 1, None],

            # RAM part 2
            ["CLK1_1", 1, None],
            ["CLK2_1", 1, None],
        ],
    "output":
        [
            # RAM part 1, port 1
            ["Almost_Full_0", 1, "CLK1_0"],
            ["PUSH_FLAG_0", 4, "CLK1_0"],

            # RAM part 1, port 2
            ["Almost_Empty_0", 1, "CLK2_0"],
            ["POP_FLAG_0", 4, "CLK2_0"],
            ["RD_0", 18, "CLK2_0"],

            # RAM part 2, port 1
            ["Almost_Full_1", 1, "CLK1_1"],
            ["PUSH_FLAG_1", 4, "CLK1_1"],

            # RAM part 2, port 2
            ["Almost_Empty_1", 1, "CLK2_1"],
            ["POP_FLAG_1", 4, "CLK2_1"],
            ["RD_1", 18, "CLK2_1"],
        ],
}

# A list of non-routable ports
RAM_2X1_NON_ROUTABLE_PORTS = {
    "input":
        [
            ["CLK1S_0", 1, None],
            ["CLK2S_0", 1, None],
            ["CLK1S_1", 1, None],
            ["CLK2S_1", 1, None],
            ["ASYNC_FLUSH_S0", 1, None],
            ["ASYNC_FLUSH_S1", 1, None],
        ]
}

# A list of non-routable ports
RAM_2X1_COMMON_PORTS = [
    "DS",
    "DS_RB1",
    "LS",
    "LS_RB1",
    "SD",
    "SD_RB1",
    "RMA",
    "RMB",
    "RMEA",
    "RMEB",
    "TEST1A",
    "TEST1B",
]

# A list of ports relevant only in RAM mode
RAM_PORTS = [
    "WEN1",
    "WEN2",
    "A1",
    "A2",
]

# A list of ports relevant only in FIFO mode
FIFO_PORTS = [
    "DIR",
    "SYNC_FIFO",
    "ASYNC_FLUSH",
    "P1",
    "P2",
    "Almost_Full",
    "Almost_Empty",
    "PUSH_FLAG",
    "POP_FLAG",
]

# A clock map for FIFO operating in DIR=1 mode
FIFO_CLOCK_MAP = {
    "CLK1_0": "CLK2_0",
    "CLK2_0": "CLK1_0",
    "CLK1_1": "CLK2_1",
    "CLK2_1": "CLK1_1",
    "CLK1": "CLK2",
    "CLK2": "CLK1",
}

# A list of non-splitable ports
NON_SPLITABLE_PORTS = [
    "WIDTH_SELECT1_0",
    "WIDTH_SELECT2_0",
    "WIDTH_SELECT1_1",
    "WIDTH_SELECT2_1",
    "WIDTH_SELECT1",
    "WIDTH_SELECT2",
]

# =============================================================================


def yield_ram_modes(ram_tree):
    """
    Yields all possible combinations of ram modes. Generated strings contain
    comma separated control signal conditions.
    """

    def inner(d, cond_prefix=None):
        for k, v in d.items():
            if not cond_prefix:
                cond = k
            else:
                cond = cond_prefix + "," + k

            if v is None:
                yield cond
            else:
                yield from inner(v, cond)

    yield from inner(ram_tree)


def make_mode_name(cond):
    """
    Formats a mode name given a condition set
    """

    name = []
    for c in cond.split(","):
        sig, val = [s.strip() for s in c.strip().split("=")]

        # If the signal name ends with a digit, replace it with a letter
        # FIXME: Assuming start from 1
        if sig[-1].isdigit():
            n = int(sig[-1])
            sig = sig[:-1] + "_" + chr(ord('A') + n - 1)

        # Abbreviate the signal
        fields = sig.split("_")
        sig = "".join([f[0] for f in fields])

        # Append the value
        sig += val
        name.append(sig)

    return "_".join(name)


# =============================================================================


def filter_cells(
        timings, cond, part=None, normalized_names=False, debug=False
):
    """
    Filters SDF timings basing on conditions present in cell type names.

    If a negated condition from the condition list is found in a cell type
    then that cell type is rejected.
    """

    # Make false condition strings
    cond_strs = []
    for c in cond.split(","):
        sig, val = [s.strip() for s in c.strip().split("=")]

        # There appears to be a single CONCAT_EN_0 condition for both cells.
        # Handle it here separately
        if sig == "CONCAT_EN":
            nval = str(1 - int(val))
            cond_strs.append(sig + "_0" + "_EQ_" + nval)
            continue

        # For a single part
        if part is not None:

            assert part in [0, 1], part
            part_str = "_{}".format(int(part))

            # Single bit
            # "<param>_EQ_<!val>"
            nval = str(1 - int(val))
            cond_strs.append(sig + part_str + "_EQ_" + nval)

            # Single bit of a multi-bit parameter
            # "<param>_<bit_idx>_EQ_<!bit_val>"
            # FIXME: Assuming 2-bit max !!
            for b in range(4):
                nval = str(int((int(val) & (1 << b)) == 0))
                if normalized_names:
                    cond_strs.append(sig + part_str + str(b) + "_EQ_" + nval)
                else:
                    cond_strs.append(
                        sig + part_str + "[{}]".format(b) + "_EQ_" + nval
                    )

            # Reject the other part completely
            other_part_str = "_{}".format(int(1 - part))

            cond_strs.append(sig + other_part_str + "_EQ_0")
            cond_strs.append(sig + other_part_str + "_EQ_1")

            # FIXME: Assuming 2-bit max !!
            for b in range(4):
                if normalized_names:
                    cond_strs.append(sig + other_part_str + str(b) + "_EQ_0")
                    cond_strs.append(sig + other_part_str + str(b) + "_EQ_1")
                else:
                    cond_strs.append(
                        sig + other_part_str + "[{}]".format(b) + "_EQ_0"
                    )
                    cond_strs.append(
                        sig + other_part_str + "[{}]".format(b) + "_EQ_1"
                    )

        # For both parts
        else:

            # Assume that control parameters must be equal for both parts
            nval = str(1 - int(val))
            cond_strs.append(sig + "_0" + "_EQ_" + nval)
            cond_strs.append(sig + "_1" + "_EQ_" + nval)

            for b in range(4):
                nval = str(int((int(val) & (1 << b)) == 0))
                if normalized_names:
                    cond_strs.append(sig + "_0" + str(b) + "_EQ_" + nval)
                    cond_strs.append(sig + "_1" + str(b) + "_EQ_" + nval)
                else:
                    cond_strs.append(
                        sig + "_0" + "[{}]".format(b) + "_EQ_" + nval
                    )
                    cond_strs.append(
                        sig + "_1" + "[{}]".format(b) + "_EQ_" + nval
                    )

    # DEBUG
    if debug:
        print(cond)
        for s in cond_strs:
            print("", "!" + s)

    # Filter
    cells = {}
    for cell_type, cell_data in timings.items():

        if debug:
            print("", "check", cell_type)

        # If any of the false conditions is found in the cell_type then the
        # cell is rejected
        reject = False
        for s in cond_strs:
            if s in cell_type:
                if debug:
                    print(" ", "reject", s)
                reject = True

        # The cell is ok
        if not reject:
            if debug:
                print(" ", "OK")
            assert cell_type not in cells
            cells[cell_type] = cell_data

    return cells


def filter_instances(timings, name):
    """
    Filters a single cell instance from the given timing data
    """

    cells = {}
    for cell_type, cell_data in timings.items():

        # Don't have that instance
        if name not in cell_data:
            continue

        # Leave only the one that we are looking for
        cells[cell_type] = {name: cell_data[name]}

    return cells


def find_timings(timings, src_pin, dst_pin):
    path_timings = {}

    for cell_type, cell_data in timings.items():

        # FIXME: Skip falling edges
        if "FALLING" in cell_type:
            continue

        for inst_name, inst_data in cell_data.items():
            for tname, tdata in inst_data.items():

                # Got matching pins
                if src_pin in tdata["from_pin"]:
                    if dst_pin in tdata["to_pin"]:

                        if tname in path_timings:
                            print("new", cell_type)
                            print("old", path_timings[tname][0])
                            # FIXME
                            continue

                        path_timings[tname] = (
                            cell_type,
                            inst_name,
                            tdata,
                        )

    return path_timings


# =============================================================================


def make_single_ram(ports):
    """
    Makes port definition for a single RAM cell (not 2x1)
    """

    new_ports = {
        "input": set(),
        "clock": set(),
        "output": set(),
    }

    for key in ["input", "clock", "output"]:
        all_port_names = set([p[0] for p in ports[key]])

        for name, width, assoc_clock in ports[key]:

            # Make a generic associated clock name
            if assoc_clock is not None:
                if assoc_clock.endswith("_0"):
                    base_assoc_clock = assoc_clock[:-2]
                if assoc_clock.endswith("_1"):
                    base_assoc_clock = assoc_clock[:-2]
            else:
                base_assoc_clock = None

            # Make a generic port name
            if name.endswith("_0"):
                base = name[:-2]
                if (base + "_1") in all_port_names:
                    new_ports[key].add((base, width, base_assoc_clock))

            elif name.endswith("_1"):
                base = name[:-2]
                if (base + "_0") in all_port_names:
                    new_ports[key].add((base, width, base_assoc_clock))

            # This is a common port for both RAMs, add it unchanged
            else:
                assert key == "input", (
                    key,
                    name,
                    width,
                    assoc_clock,
                )
                new_ports[key].add((
                    name,
                    width,
                    assoc_clock,
                ))

    return new_ports


def remap_clocks(ports, clock_map):
    """
    Remaps clock dependencies of all ports and returns a new port map.
    Does not remap clocks for "P1" and "P2" ports.
    """

    new_ports = {
        "input": set(),
        "clock": set(),
        "output": set(),
    }

    for key in ["input", "clock", "output"]:
        for name, width, assoc_clock in ports[key]:

            # P1 and P2 are not subject to the remap
            if "P1" not in name and "P2" not in name:

                # Remap the associated clock
                if assoc_clock in clock_map:
                    assoc_clock = clock_map[assoc_clock]

            new_ports[key].add((
                name,
                width,
                assoc_clock,
            ))

    return new_ports


def filter_ports(ports, ports_to_filter):
    """
    Removes timing relation from ports of a model
    """

    # Make a copy
    new_ports = dict()

    for key in ["input", "clock", "output"]:
        new_ports[key] = []

        for name, width, assoc_clock in ports[key]:
            if key in ["input", "output"]:
                if name.endswith("_0") or name.endswith("_1"):
                    generic_name = name[:-2]
                    if generic_name in ports_to_filter:
                        assoc_clock = None

                if name in ports_to_filter:
                    assoc_clock = None

            new_ports[key].append((
                name,
                width,
                assoc_clock,
            ))

    return new_ports


# =============================================================================


def make_pin_name(port, index):
    """
    Formats a pin name of a multi-bit port
    """
    return "{}_b{}".format(port, index)


def split_port_bit_index(name):
    """
    Extracts bit index from the port
    """

    m = re.match(r"(?P<name>.*)(_b(?P<bit>[0-9]+))$", name)
    if m is not None:
        return m.group("name"), int(m.group("bit")),

    return name, None


def parse_port_name(name):
    """
    Parses a port name. Returns the base name, cell index and bit index.

    >>> parse_port_name("A_PORT")
    ('A_PORT', None, None)
    >>> parse_port_name("A_PORT_0")
    ('A_PORT', 0, None)
    >>> parse_port_name("A_PORT_b31")
    ('A_PORT', None, 31)
    >>> parse_port_name("A_PORT_0_b15")
    ('A_PORT', 0, 15)
    """

    # A multi-bit port
    m = re.match(r"(?P<name>.*)(_b(?P<bit>[0-9]+))$", name)
    if m is not None:
        port = m.group("name")
        bit = int(m.group("bit"))
    else:
        port = name
        bit = None

    # A port of a sub-cell
    m = re.match(r"(?P<name>.*)(_(?P<cell>[0-9]+))$", port)
    if m is not None:
        return m.group("name"), int(m.group("cell")), bit

    return port, None, bit


def split_ports(ports):
    """
    Splits multi-bit ports into single-bit
    """

    split_ports = dict()
    for key in ports.keys():

        split_ports[key] = list()

        for name, width, assoc_clock in ports[key]:
            if width == 1 or name in NON_SPLITABLE_PORTS:
                split_ports[key].append((
                    name,
                    width,
                    assoc_clock,
                ))
            else:
                for i in range(width):
                    split_ports[key].append(
                        (make_pin_name(name, i), 1, assoc_clock)
                    )

    return split_ports


def make_model(model_name, ports):
    """
    Makex a model XML given the port definition
    """

    # The model root
    xml_model = ET.Element("model", {
        "name": model_name,
    })

    # Port lists
    xml_ports = {
        "input": ET.SubElement(xml_model, "input_ports"),
        "output": ET.SubElement(xml_model, "output_ports"),
    }
    xml_ports["clock"] = xml_ports["input"]

    # Emits a XML tag for a port
    def add_port(xml_parent, name, width, assoc_clock):

        # A clock
        if key == "clock":
            assert assoc_clock is None, (name, width, assoc_clock)
            attrs = {"is_clock": "1"}

        # An input / output
        else:
            if assoc_clock is not None:
                attrs = {"clock": assoc_clock}
            else:
                attrs = dict()

        ET.SubElement(xml_parent, "port", {"name": name, **attrs})

    # Add ports
    for key in ["clock", "input", "output"]:
        for name, width, assoc_clock in ports[key]:
            add_port(xml_ports[key], name, width, assoc_clock)

    return xml_model


def make_pb_type(
        pb_name,
        ports,
        model_name,
        timings=None,
        timescale=1.0,
        normalized_names=False
):

    stats = {
        "total_timings": 0,
        "missing_timings": 0,
    }

    # The pb_type tag
    if model_name:
        attrs = {"blif_model": ".subckt {}".format(model_name)}
    else:
        attrs = dict()

    xml_pb = ET.Element("pb_type", {"name": pb_name, "num_pb": "1", **attrs})

    # Ports
    for key in ["clock", "input", "output"]:
        for name, width, *data in ports[key]:
            ET.SubElement(
                xml_pb, key, {
                    "name": name,
                    "num_pins": str(width),
                }
            )

    # Timings
    if timings is not None:

        # Setup and hold
        for name, width, assoc_clock in ports["input"]:
            if assoc_clock is None:
                continue

            # Split the port and its bit index (if any)
            alias, bit = split_port_bit_index(name)

            # Find all timing paths for that port
            path_timings = find_timings(timings, assoc_clock, alias.upper())

            # Bit index suffix
            if bit is not None:
                if normalized_names:
                    suffix = "{}".format(bit)
                else:
                    suffix = "[{}]".format(bit)
            else:
                suffix = ""

            # Setup
            for key in path_timings:

                if key.startswith("setup") and key.endswith(suffix):
                    tim = path_timings[key][2]
                    delay = tim["delay_paths"]["nominal"]["avg"] * timescale
                    break

                if key.startswith("setuphold") and key.endswith(suffix):
                    tim = path_timings[key][2]
                    print("SETUPHOLD", tim)
                    exit(-1)
                    delay = tim["delay_paths"]["nominal"]["avg"] * timescale
                    break

            else:
                delay = 1e-10
                stats["missing_timings"] += 1
                print(
                    "WARNING: No setup timing for '{}'->'{}' for pb_type '{}'".
                    format(alias + suffix, assoc_clock, pb_name)
                )

            stats["total_timings"] += 1

            ET.SubElement(
                xml_pb, "T_setup", {
                    "port": name,
                    "clock": assoc_clock,
                    "value": "{:+e}".format(delay)
                }
            )

            # Hold
            for key in path_timings:

                if key.startswith("hold") and key.endswith(suffix):
                    tim = path_timings[key][2]
                    delay = tim["delay_paths"]["nominal"]["avg"] * timescale
                    break

                if key.startswith("setuphold") and key.endswith(suffix):
                    tim = path_timings[key][2]
                    print("SETUPHOLD", tim)
                    exit(-1)
                    delay = tim["delay_paths"]["nominal"]["avg"] * timescale
                    break

            else:
                delay = 1e-10
                stats["missing_timings"] += 1
                print(
                    "WARNING: No hold timing for '{}'->'{}' for pb_type '{}'".
                    format(alias + suffix, assoc_clock, pb_name)
                )

            stats["total_timings"] += 1

            ET.SubElement(
                xml_pb, "T_hold", {
                    "port": name,
                    "clock": assoc_clock,
                    "value": "{:+e}".format(delay)
                }
            )

        # Clock to Q
        for name, width, assoc_clock in ports["output"]:
            if assoc_clock is None:
                continue

            # Split the port and its bit index (if any)
            alias, bit = split_port_bit_index(name)

            # Find all timing paths for that port
            path_timings = find_timings(timings, assoc_clock, alias.upper())

            # Index suffixes
            # Bit index suffix
            if bit is not None:
                if normalized_names:
                    suffix = "{}".format(bit)
                else:
                    suffix = "[{}]".format(bit)
            else:
                suffix = ""

            # "Clock to Q"
            for key in path_timings:

                if key.startswith("iopath") and key.endswith(suffix):
                    tim = path_timings[key][2]
                    delay_min = tim["delay_paths"]["slow"]["min"] * timescale
                    delay_max = tim["delay_paths"]["slow"]["max"] * timescale
                    break

            else:
                delay_min = 1e-10
                delay_max = 1e-10
                stats["missing_timings"] += 1
                print(
                    "WARNING: No \"clock to Q\" timing for '{}'->'{}' for pb_type '{}'"
                    .format(assoc_clock, alias + suffix, pb_name)
                )

            stats["total_timings"] += 1

            ET.SubElement(
                xml_pb, "T_clock_to_Q", {
                    "port": name,
                    "clock": assoc_clock,
                    "min": "{:+e}".format(delay_min),
                    "max": "{:+e}".format(delay_max)
                }
            )

    return xml_pb, stats


# =============================================================================


def auto_interconnect(pb_type):
    """
    Automatically generates an interconnect that connects matching ports of
    a child pb_type to its parent. Moreover, when a child pb_type is suffixed
    with sth. like "_0" then parent ports with the same suffix are matched.
    """

    def get_ports(pb, type):
        """
        Yields pb_type ports of the given type
        """
        for port in pb.findall(type):
            yield port.attrib["name"], int(port.attrib["num_pins"]),

    # Get parent for the interconnect (can be either "mode" or "pb_type")
    if pb_type.tag == "mode":
        ic_parent = pb_type
    else:
        ic_parent = child.getparent()

    # Get logical parent (must be a "pb_type")
    if ic_parent.tag == "pb_type":
        pb_parent = ic_parent
    else:
        pb_parent = ic_parent.getparent()
        assert pb_parent.tag == "pb_type"

    # Get all children (if pb_type is "mode")
    if pb_type.tag == "mode":
        pb_children = list(pb_type.findall("pb_type"))
    else:
        pb_children = [pb_type]

    # Upstream ports
    parent_name = pb_parent.attrib["name"]
    parent_ports = set([(*p, "I") for p in get_ports(pb_parent, "input")])
    parent_ports |= set([(*p, "I") for p in get_ports(pb_parent, "clock")])
    parent_ports |= set([(*p, "O") for p in get_ports(pb_parent, "output")])

    # Downstream ports
    children = {}
    for child in pb_children:
        name = child.attrib["name"]
        ports = set([(*p, "I") for p in get_ports(child, "input")])
        ports |= set([(*p, "I") for p in get_ports(child, "clock")])
        ports |= set([(*p, "O") for p in get_ports(child, "output")])

        children[name] = ports

    # Adds a connection
    def add_connection(xml, iname, oname, reverse=False):
        if reverse:
            ET.SubElement(
                xml, "direct", {
                    "name": "{}_to_{}".format(oname, iname),
                    "input": oname,
                    "output": iname
                }
            )
        else:
            ET.SubElement(
                xml, "direct", {
                    "name": "{}_to_{}".format(iname, oname),
                    "input": iname,
                    "output": oname
                }
            )

    # Create the interconnect
    ic = ET.SubElement(ic_parent, "interconnect")

    for child in sorted(children.keys()):
        child_ports = sorted(list(children[child]), key=lambda x: x[0])

        # Get the child cell index
        m = re.match(r"(.*)(_(?P<idx>[0-9]+))$", child)
        if m is not None:
            child_index = int(m.group("idx"))
        else:
            child_index = None

        # Loop over all child ports
        for dn_port, dn_width, dn_type in child_ports:

            # Got a 1-to-1 match
            if (dn_port, dn_width, dn_type) in parent_ports:
                iname = "{}.{}".format(parent_name, dn_port)
                oname = "{}.{}".format(child, dn_port)
                add_connection(ic, iname, oname, dn_type == "O")
                continue

            # Parse the child port name
            dn_alias, dn_index, dn_bit = parse_port_name(dn_port)

            # Got a match with the child cell index
            up_port = "{}_{}".format(dn_alias, child_index)
            if (up_port, dn_width, dn_type) in parent_ports:
                iname = "{}.{}".format(parent_name, up_port)
                oname = "{}.{}".format(child, dn_port)
                add_connection(ic, iname, oname, dn_type == "O")
                continue

            # The downstream port is split into bits
            if dn_bit is not None:

                # Try without the cell index
                ports = [(*p, ) for p in parent_ports if p[0] == dn_alias]
                assert len(ports) < 2, ports

                if ports:
                    up_port, up_width, up_type = ports[0]
                    iname = "{}.{}[{}]".format(parent_name, up_port, dn_bit)
                    oname = "{}.{}".format(child, dn_port)
                    add_connection(ic, iname, oname, dn_type == "O")
                    continue

                up_alias = "{}_{}".format(dn_alias, dn_index)
                ports = [(*p, ) for p in parent_ports if p[0] == up_alias]
                assert len(ports) < 2, ports

                if ports:
                    up_port, up_width, up_type = ports[0]
                    iname = "{}.{}[{}]".format(parent_name, up_port, dn_bit)
                    oname = "{}.{}".format(child, dn_port)
                    add_connection(ic, iname, oname, dn_type == "O")
                    continue

            # Couldn't find a matching port
            print(
                "ERROR: No matching parent port in '{}' for '{}.{}'".format(
                    parent_name, child, dn_port
                )
            )

    return ic


# =============================================================================


def make_ports(ports, separator=",\n"):
    verilog = ""

    for key in ["clock", "input", "output"]:
        if key == "clock":
            type = "input"
        else:
            type = key

        verilog += "\n"

        for name, width, assoc_clock in ports[key]:
            if width > 1:
                verilog += "  {:<6} [{:2d}:0] {}{}".format(
                    type, width - 1, name, separator
                )
            else:
                verilog += "  {:<6}        {}{}".format(type, name, separator)

    return verilog


def make_ram2x1_instance(ports, separator=",\n"):
    verilog = ""

    verilog += "\n   ram8k_2x1_cell I1 ( \n"

    for key in ["clock", "input", "output"]:
        for name, width, assoc_clock in ports[key]:
            if name not in RAM_2X1_COMMON_PORTS:
                if name.endswith("_0") or name.endswith("_1"):
                    verilog += "      .{}({}){}".format(name, name, separator)
                else:
                    verilog += "      .{}_0({}){}".format(
                        name, name, separator
                    )

    verilog = verilog[:-2] + ");\n\n"

    return verilog


def make_specify(ports, separator=";\n"):
    verilog = ""

    verilog += "\n  specify\n"
    for key in ["clock", "input", "output"]:
        if key == "clock":
            type = "input"
        else:
            type = key

        for name, width, assoc_clock in ports[key]:
            if key == "input":
                if assoc_clock != None:
                    verilog += "      $setup({}, posedge {}, \"\"){}".format(
                        name, assoc_clock, separator
                    )
                    verilog += "      $hold(posedge {}, {}, \"\"){}".format(
                        assoc_clock, name, separator
                    )
            elif key == "output":
                if assoc_clock != None:
                    verilog += "      ({}*>{})=\"\"{}".format(
                        assoc_clock, name, separator
                    )

    verilog += "  endspecify\n\n"

    return verilog


def make_blackbox(name, ports, specify_ports):

    # Header
    verilog = """
`timescale 1ns/10ps
(* blackbox *)
module {} (
""".format(name)

    # Ports
    verilog += make_ports(ports)
    verilog = verilog[:-2] + "\n"
    verilog += ");\n"

    #Specify
    verilog += make_specify(specify_ports)

    #RAM2x1 cell instance
    verilog += make_ram2x1_instance(ports)

    # Footer
    verilog += "endmodule\n"

    return verilog


def make_techmap(conditions):

    # The original cell name
    cell_name = "ram8k_2x1_cell_macro"

    # Header
    verilog = "module {} (\n".format(cell_name)

    # Ports
    map_ports = {}
    for key, ports in RAM_2X1_PORTS.items():
        map_ports[key] = list(ports)
        if key in RAM_2X1_NON_ROUTABLE_PORTS:
            map_ports[key] += RAM_2X1_NON_ROUTABLE_PORTS[key]

    verilog += make_ports(map_ports)
    verilog = verilog[:-2] + "\n"
    verilog += ");\n"

    verilog += "\n"

    # Gather significant control parameters
    control_signals = set()
    for condition in conditions:
        for cond_str in condition.split(","):
            sig, val = cond_str.split("=")
            for part in [0, 1]:
                part_sig = "{}_{}".format(sig, part)
                control_signals.add(part_sig)

    # Techmap special parameters
    for sig in sorted(control_signals):
        verilog += "  parameter _TECHMAP_CONSTMSK_{}_ = 1'bx;\n".format(sig)
        verilog += "  parameter _TECHMAP_CONSTVAL_{}_ = 1'bx;\n".format(sig)

    verilog += "\n"

    # Split condition strings for single and dual ram modes
    sing_conditions = [c for c in conditions if "CONCAT_EN=0" in c]
    dual_conditions = [c for c in conditions if "CONCAT_EN=1" in c]

    # Split RAM mode
    verilog_cond = []
    verilog_cond.append("(_TECHMAP_CONSTVAL_CONCAT_EN_0_ == 1'b0)")
    verilog_cond.append("(_TECHMAP_CONSTVAL_CONCAT_EN_1_ == 1'b0)")
    verilog_cond = " && ".join(verilog_cond)
    verilog += "  // Split RAM\n"
    verilog += "  generate if({}) begin\n".format(verilog_cond)

    # Each part is independent
    model_ports = split_ports(RAM_2X1_PORTS)

    for part in [0, 1]:
        verilog += "    // RAM {}\n".format(part)
        for i, condition in enumerate(sing_conditions):

            # Case condition
            verilog_cond = []
            for condition_str in condition.split(","):
                sig, val = condition_str.split("=")

                if sig == "CONCAT_EN":
                    continue

                cond_part = "(_TECHMAP_CONSTVAL_{}_{}_ == {})".format(
                    sig, part, val
                )
                verilog_cond.append(cond_part)

            verilog_cond = " && ".join(verilog_cond)
            if i == 0:
                verilog += "    if ({}) begin\n".format(verilog_cond)
            else:
                verilog += "    end else if ({}) begin\n".format(verilog_cond)

            # Instance
            mode_name = make_mode_name(condition)
            model_name = "RAM_" + mode_name + "_VPR"

            verilog += "        {} RAM_{} (\n".format(model_name, part)

            # Ports mapped to the part
            for key in ["clock", "input", "output"]:
                for name, width, assoc_clock in model_ports[key]:

                    # Parse the port name
                    alias, index, bit = parse_port_name(name)

                    # Not for that part
                    if index is not None and part != index:
                        continue

                    if index is None:
                        pname = alias
                    else:
                        pname = "{}_{}".format(alias, index)

                    if bit is not None:
                        portspec = "{}_b{}".format(alias, bit)
                        sigspec = "{}[{}]".format(pname, bit)
                    else:
                        portspec = alias
                        sigspec = pname

                    verilog += "        .{}({}),\n".format(portspec, sigspec)

            verilog = verilog[:-2] + "\n"
            verilog += "        );\n"

        # Error catcher
        verilog += """
    end else begin
      wire _TECHMAP_FAIL_;
    end
"""

    # Non-split (concatenated) RAM mode
    verilog_cond = []
    verilog_cond.append("(_TECHMAP_CONSTVAL_CONCAT_EN_0_ == 1'b1)")
    # verilog_cond.append("(_TECHMAP_CONSTVAL_CONCAT_EN_1_ == 1'b1)") # It appears that only CONCAT_EN_0 needs to be set
    verilog_cond = " && ".join(verilog_cond)
    verilog += "  // Concatenated RAM\n"
    verilog += "  end else if({}) begin\n".format(verilog_cond)

    for i, condition in enumerate(dual_conditions):

        # Case condition
        verilog_cond = []
        for condition_str in condition.split(","):
            sig, val = condition_str.split("=")

            if sig == "CONCAT_EN":
                continue

            cond_part = "(_TECHMAP_CONSTVAL_{}_0_ == {})".format(sig, val)
            cond_part = "(_TECHMAP_CONSTVAL_{}_1_ == {})".format(sig, val)
            verilog_cond.append(cond_part)

        verilog_cond = " && ".join(verilog_cond)
        if i == 0:
            verilog += "    if ({}) begin\n".format(verilog_cond)
        else:
            verilog += "    end else if ({}) begin\n".format(verilog_cond)

        # Instance
        mode_name = make_mode_name(condition)
        model_name = "RAM_" + mode_name + "_VPR"

        verilog += "      {} RAM (\n".format(model_name)

        # Ports always mapped 1-to-1
        for key in ["clock", "input", "output"]:
            for name, width, assoc_clock in model_ports[key]:

                # Parse the port name
                alias, index, bit = parse_port_name(name)

                if index is None:
                    pname = alias
                else:
                    pname = "{}_{}".format(alias, index)

                if bit is not None:
                    portspec = "{}_b{}".format(pname, bit)
                    sigspec = "{}[{}]".format(pname, bit)
                else:
                    portspec = pname
                    sigspec = pname

                verilog += "        .{}({}),\n".format(portspec, sigspec)

        verilog = verilog[:-2] + "\n"
        verilog += "      );\n"

    # Error catcher
    verilog += """
    end else begin
      wire _TECHMAP_FAIL_;
    end
"""

    # Error handler for unexpected configuration
    verilog += """
  end else begin
    wire _TECHMAP_FAIL_;

  end endgenerate

"""

    # Footer
    verilog += "endmodule\n"

    return verilog


# =============================================================================


def main():

    # Parse arguments
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--mode-defs",
        type=str,
        default="ram_modes.json",
        help="A JSON file defining RAM modes"
    )
    parser.add_argument(
        "--sdf", type=str, required=True, help="An SDF file with timing data"
    )
    parser.add_argument(
        "--xml-path", type=str, default="./", help="Output path for XML files"
    )
    parser.add_argument(
        "--vlog-path",
        type=str,
        default="./",
        help="Output path for Verilog files"
    )

    args = parser.parse_args()

    # Load the RAM mode tree definition
    with open(args.mode_defs, "r") as fp:
        ram_tree = json.load(fp)

    # Load RAM timings
    with open(args.sdf, "r") as fp:
        ram_timings = sdf_timing.sdfparse.parse(fp.read())
        timescale = get_scale_seconds(ram_timings["header"]["timescale"])

    # Make port definition for a single ram
    ram_ports_sing = make_single_ram(RAM_2X1_PORTS)

    # Gather all RAM instances
    instances = set()
    for v in ram_timings["cells"].values():
        instances |= set(v.keys())

    # Use not normalized names in SDFs (i.e. with brackets)
    # TODO: Make this an argument
    normalized_names = False

    xml_models = {}

    # Generate a pb_type tree for each instance
    for instance in instances:
        print(instance)

        # Initialize the top-level pb_type XML
        xml_pb_root = make_pb_type("RAM", RAM_2X1_PORTS, None)[0]

        # Wrapper pb_type for split RAM (CONCAT_EN=0)
        xml_mode = ET.SubElement(xml_pb_root, "mode", {"name": "SING"})

        xml_sing = [
            make_pb_type("RAM_0", ram_ports_sing, None)[0],
            make_pb_type("RAM_1", ram_ports_sing, None)[0],
        ]

        for x in xml_sing:
            xml_mode.append(x)

        ic = auto_interconnect(xml_mode)
        xml_mode.append(ic)

        # Wrapper pb_type for non-split RAM (CONCAT_EN=1)
        xml_mode = ET.SubElement(xml_pb_root, "mode", {"name": "DUAL"})
        xml_dual = make_pb_type("RAM_DUAL", RAM_2X1_PORTS, None)[0]
        xml_mode.append(xml_dual)

        ic = auto_interconnect(xml_mode)
        xml_mode.append(ic)

        # Get timings for this instance
        all_timings = filter_instances(ram_timings["cells"], instance)

        total_timings = 0
        missing_timings = 0

        # Generate RAM modes
        for cond in yield_ram_modes(ram_tree):
            print("", cond)

            mode_name = make_mode_name(cond)
            model_name = "RAM_" + mode_name + "_VPR"

            # CONCAT_EN=0 - the 2x1 RAM is split into two
            if "CONCAT_EN=0" in cond:

                if "FIFO_EN=0" in cond:
                    model_ports = filter_ports(ram_ports_sing, FIFO_PORTS)
                else:
                    model_ports = filter_ports(ram_ports_sing, RAM_PORTS)
                    if "DIR=1" in cond:
                        model_ports = remap_clocks(model_ports, FIFO_CLOCK_MAP)

                # For each part
                for part in [0, 1]:

                    # Filter timings basing on the generated set of conditions
                    # and RAM part
                    timings = filter_cells(
                        all_timings,
                        cond,
                        part,
                        normalized_names=normalized_names
                    )

                    # DEBUG
                    #                    print(" RAM_" + str(part))
                    #                    for cname, cdata in timings.items():
                    #                        print(" ", cname)
                    #                        for iname, idata in cdata.items():
                    #                            for tname, tdata in idata.items():
                    #                                print("  ", tname, "src={}, dst={}".format(tdata["from_pin"], tdata["to_pin"]))

                    # Make the mode XML
                    xml_mode = ET.SubElement(
                        xml_sing[part], "mode", {"name": mode_name}
                    )

                    # Make the pb_type XML
                    pb_name = "RAM_{}_{}".format(part, mode_name)
                    xml_pb, stats = make_pb_type(
                        pb_name,
                        split_ports(model_ports),
                        model_name,
                        timings,
                        timescale,
                        normalized_names=normalized_names,
                    )
                    xml_mode.append(xml_pb)

                    total_timings += stats["total_timings"]
                    missing_timings += stats["missing_timings"]

                    # Make the interconnect
                    ic = auto_interconnect(xml_mode)
                    xml_mode.append(ic)

                # Make the model XML
                xml_model = make_model(model_name, split_ports(model_ports))
                xml_models[model_name] = xml_model

            # CONCAT_EN=1 - keep the 2x1 RAM as one
            elif "CONCAT_EN=1" in cond:

                if "FIFO_EN=0" in cond:
                    model_ports = filter_ports(RAM_2X1_PORTS, FIFO_PORTS)
                else:
                    model_ports = filter_ports(RAM_2X1_PORTS, RAM_PORTS)
                    if "DIR=1" in cond:
                        model_ports = remap_clocks(model_ports, FIFO_CLOCK_MAP)

                # Filter timings
                timings = filter_cells(
                    all_timings, cond, None, normalized_names=normalized_names
                )

                # DEBUG
                #                print(" Dual RAM")
                #                for cname, cdata in timings.items():
                #                    print(" ", cname)
                #                    for iname, idata in cdata.items():
                #                        for tname, tdata in idata.items():
                #                            print("  ", tname, "src={}, dst={}".format(tdata["from_pin"], tdata["to_pin"]))

                # Make the mode XML
                xml_mode = ET.SubElement(xml_dual, "mode", {"name": mode_name})

                # Make the pb_type XML
                pb_name = "RAM_" + mode_name
                xml_pb, stats = make_pb_type(
                    pb_name,
                    split_ports(model_ports),
                    model_name,
                    timings,
                    timescale,
                    normalized_names=normalized_names,
                )
                xml_mode.append(xml_pb)

                total_timings += stats["total_timings"]
                missing_timings += stats["missing_timings"]

                # Make the interconnect
                ic = auto_interconnect(xml_mode)
                xml_mode.append(ic)

                # Make the model XML
                xml_model = make_model(model_name, split_ports(model_ports))
                xml_models[model_name] = xml_model

            # Should not happen
            else:
                assert False, cond

        # Serialize the pb_type XML
        fname = os.path.join(args.xml_path, instance.lower() + ".pb_type.xml")
        ET.ElementTree(xml_pb_root).write(fname, pretty_print=True)

        print("total timings  : {}".format(total_timings))
        print(
            "missing timings: {} {:.2f}%".format(
                missing_timings, 100.0 * missing_timings / total_timings
            )
        )

    # Write models XML
    xml_model_root = ET.Element("models")
    for key in sorted(list(xml_models.keys())):
        xml_model_root.append(xml_models[key])

    fname = os.path.join(args.xml_path, "ram.model.xml")
    ET.ElementTree(xml_model_root).write(fname, pretty_print=True)

    # Make blackboxes
    blackboxes = {}
    for cond in yield_ram_modes(ram_tree):
        mode_name = make_mode_name(cond)
        model_name = "RAM_" + mode_name + "_VPR"

        # CONCAT_EN=0 - the 2x1 RAM is split into two
        if "CONCAT_EN=0" in cond:
            if "DIR=1" in cond:
                ports = remap_clocks(ram_ports_sing, FIFO_CLOCK_MAP)
            else:
                ports = ram_ports_sing

            if "FIFO_EN=0" in cond:
                model_ports = filter_ports(ram_ports_sing, FIFO_PORTS)
            else:
                model_ports = filter_ports(ram_ports_sing, RAM_PORTS)
                if "DIR=1" in cond:
                    model_ports = remap_clocks(model_ports, FIFO_CLOCK_MAP)

            verilog = make_blackbox(
                model_name, split_ports(ports), split_ports(model_ports)
            )
            blackboxes[model_name] = verilog

        # CONCAT_EN=1 - keep the 2x1 RAM as one
        elif "CONCAT_EN=1" in cond:
            if "DIR=1" in cond:
                ports = remap_clocks(RAM_2X1_PORTS, FIFO_CLOCK_MAP)
            else:
                ports = RAM_2X1_PORTS

            if "FIFO_EN=0" in cond:
                model_ports = filter_ports(RAM_2X1_PORTS, FIFO_PORTS)
            else:
                model_ports = filter_ports(RAM_2X1_PORTS, RAM_PORTS)
                if "DIR=1" in cond:
                    model_ports = remap_clocks(model_ports, FIFO_CLOCK_MAP)

            verilog = make_blackbox(
                model_name, split_ports(ports), split_ports(model_ports)
            )
            blackboxes[model_name] = verilog

    # Write blackbox definitions
    fname = os.path.join(args.vlog_path, "ram_sim.v")
    with open(fname, "w") as fp:
        for k, v in blackboxes.items():
            fp.write(v)

    # Make techmap
    techmap = make_techmap(list(yield_ram_modes(ram_tree)))
    fname = os.path.join(args.vlog_path, "ram_map.v")
    with open(fname, "w") as fp:
        fp.write(techmap)


if __name__ == "__main__":
    main()
