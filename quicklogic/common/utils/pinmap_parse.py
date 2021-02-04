#!/usr/bin/env python3
import argparse
import csv
import re

from collections import defaultdict
from collections import namedtuple

import lxml.etree as ET

# =============================================================================
class PinMappingData(object):
    """
    Pin mapping data for IO ports in an eFPGA device.

    port_name   - IO port name
    mapped_pin  - User-defined pin name mapped to the given port_name
    type        - Port type
    direction   - Port direction. Valid values - 'INPUT', 'OUTPUT', 'BIDIR'
    assoc_clk   - Clock associated with user-defined pin
    clk_edge    - Clock edge type of the associated clock at which data is available
                Valid value: 'Rising' & 'Falling'
    time_factor - Timing budget allocated for the port.
                Valid value is from 0 (for 0 %) to 1 (for 100%).
    min_time    - Minimum acceptable transition time (in ns) of the given pin.
    """

    def __init__(self, port_name, mapped_pin, type, direction, assoc_clk,
                 clk_edge, time_factor, min_time):
        self.port_name = port_name
        self.mapped_pin = mapped_pin
        self.type = type
        self.direction = direction
        self.assoc_clk = assoc_clk
        self.clk_edge = clk_edge
        self.time_factor = time_factor
        self.min_time = min_time

    def __str__(self):
        return "{Port_name: '%s' mapped_pin: '%s' type: '%s' direction: '%s' assoc_clk: '%s' \
                clk_edge: '%s' time_factor: '%s' min_time: '%s'}"                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                % (self.port_name, \
                self.mapped_pin, self.type, self.direction, self.assoc_clk, \
                    self.clk_edge, self.time_factor, self.min_time)

    def __repr__(self):
        return "{Port_name: '%s' mapped_pin: '%s' type: '%s' direction: '%s' assoc_clk: '%s' clk_edge: '%s' time_factor: '%s' min_time: '%s'}" % (self.port_name, \
                self.mapped_pin, self.type, self.direction, self.assoc_clk, \
                    self.clk_edge, self.time_factor, self.min_time)
"""
Timing data for the clock associated with mapped pin and is common to all pins. 
This data can be overwritten by the similar data present at each pin-mapping level.

clk_edge    - Clock edge type of the associated clock at which data is available
              Valid value: 'Rising' & 'Falling'
time_factor - Timing budget allocated for the port
              Valid value is from 0 (for 0 %) to 1 (for 100%).
min_time    - Minimum acceptable transition time (in ns) of the given pin.
              Default global value is 0.
"""
GlobalTimingData = namedtuple("GlobalTimingData", "clk_edge time_factor min_time")

"""
Device properties present in the pin-mapping xml

name    - Device name
family  - Device family name
size    - Device size
foundry - Foundry name
node    - Technology node
package - Package name for which this pin-mapping is applied
"""
DeviceData = namedtuple("DeviceData", "name family size foundry node package")

"""
Properties defined at Cell section level

port_name   - Port name
type        - Port type
direction   - Port direction. Valid values - 'INPUT', 'OUTPUT', 'BIDIR'
mapped_name - User-defined mapped pin name
clk_edge    - Clock edge type of the associated clock at which data is available
              Valid value: 'Rising' & 'Falling'
time_factor - Timing budget allocated for the port.
              Valid value is from 0 (for 0 %) to 1 (for 100%).
min_time    - Minimum acceptable transition time (in ns) of the given pin.
"""
CellData = namedtuple("CellData", "port_name type direction mapped_name \
                                   clk_edge time_factor min_time"                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               )

# =============================================================================

def parse_io(xml_io, orientation, globalTimingData):

    assert xml_io is not None

    cells = {}

    io_row = ""
    io_col = ""
    xml_row_cols = {}
    if orientation in ("TOP", "BOTTOM"):
        io_row = xml_io.get("row")
        if io_row is None:
            side=""
            if orientation is "TOP":
                side="TOP_IO"
            elif orientation is "BOTTOM":
                side="BOTTOM_IO"
            print(
                "ERROR: No mandatory attribute 'row' defined in '", side,
                "' section"
            )
            return None

        xml_row_cols = xml_io.findall("COL")
        assert xml_row_cols is not None
    elif orientation in ("LEFT", "RIGHT"):
        io_col = xml_io.get("col")
        if io_col is None:
            side = ""
            if orientation is "LEFT":
                side = "LEFT_IO"
            elif orientation is "RIGHT":
                side = "RIGHT_IO"
            print(
                "ERROR: No mandatory attribute 'col' defined in '", side,
                "' section"
            )
            return None

        xml_row_cols = xml_io.findall("ROW")
        assert xml_row_cols is not None

    for xml_curr_io in xml_row_cols:
        if orientation in ("TOP", "BOTTOM"):
            io_col = xml_curr_io.get("num")
            if io_col is None:
                print("ERROR: No mandatory attribute 'num' defined in 'COL' section")
                return None
        elif orientation in ("LEFT", "RIGHT"):
            io_row = xml_curr_io.get("num")
            if io_row is None:
                print("ERROR: No mandatory attribute 'num' defined in 'ROW' section")
                return None

        for xml_cell in xml_curr_io.findall("CELL"):
            cell = {}

            cellData = CellData(
                port_name=xml_cell.get("port_name"),
                type=xml_cell.get("type"),
                direction=xml_cell.get("direction"),
                mapped_name=xml_cell.get("mapped_name"),
                clk_edge=xml_cell.get("clk_edge"),
                time_factor=xml_cell.get("time_factor"),
                min_time=xml_cell.get("min_time")
            )

            pinmaps = {}
            for xml_pinmap in xml_cell.findall("Pinmap"):
                port_name=xml_pinmap.get("name")
                mapped_pin=xml_pinmap.get("mapped_name")
                assoc_clk=xml_pinmap.get("assoc_clk")
                clk_edge=xml_pinmap.get("clk_edge")
                time_factor=xml_pinmap.get("time_factor")
                min_time=xml_pinmap.get("min_time")

                if clk_edge is None:
                    if cellData.clk_edge is not None:
                        clk_edge = cellData.clk_edge
                    else:
                        clk_edge = globalTimingData.clk_edge

                if time_factor is None:
                    if cellData.time_factor is not None:
                        time_factor = cellData.time_factor
                    else:
                        time_factor = globalTimingData.time_factor

                if min_time is None:
                    if cellData.min_time is not None:
                        min_time = cellData.min_time
                    else:
                        min_time = globalTimingData.min_time

                # define properties for scalar pins
                scalar_ports = vec_to_scalar(port_name)
                scalar_mapped_pins = vec_to_scalar(mapped_pin)

                for (port, pin) in zip(scalar_ports, scalar_mapped_pins):
                    pinMapObj = PinMappingData(
                        port, pin, cellData.type,
                        cellData.direction, assoc_clk, clk_edge, time_factor,
                        min_time
                    )
                    pinmaps[port] = pinMapObj

            cell[cellData.port_name] = {
                "attributes": cellData,
                "pinmaps": pinmaps
            }

            cells[io_col, io_row, cellData.port_name] = cell

    return cells

# =============================================================================

def vec_to_scalar(port_name):
    scalar_ports = []
    if port_name is not None and ':' in port_name:
        open_brace = port_name.find('[')
        close_brace = port_name.find(']')
        if open_brace is -1 or close_brace is -1:
            print(
                "ERROR: Invalid portname : '", port_name,
                "' specified. Bus ports should contain [ ] to specify range"
            )
            return None
        bus = port_name[open_brace + 1:close_brace]
        lsb = int(bus[:bus.find(':')])
        msb = int(bus[bus.find(':')+1:])
        if lsb > msb:
            for i in range(msb, lsb+1):
                currPortName = port_name[:open_brace] + '[' + str(i) + ']'
                scalar_ports.append(currPortName)
        else:
            for i in range(lsb, msb+1):
                currPortName = port_name[:open_brace] + '[' + str(i) + ']'
                scalar_ports.append(currPortName)
    else:
        scalar_ports.append(port_name)

    return scalar_ports

# =============================================================================

def parse_io_cells(xml_root, globalTimingData):
    """
    Parses the "IO" section of the pinmapfile. Returns a dict indexed by IO cell
    names which contains cell types and their locations in the device grid.
    """

    cells = {}

    # Get the "IO" section
    xml_io = xml_root.find("IO")
    if xml_io is None:
        print("ERROR: No mandatory 'IO' section defined in 'DEVICE' section")
        return None

    xml_top_io = xml_io.find("TOP_IO")
    if xml_top_io is not None:
        currcells = parse_io(xml_top_io, "TOP", globalTimingData)
        cells["TOP"] = currcells

    xml_bottom_io = xml_io.find("BOTTOM_IO")
    if xml_bottom_io is not None:
        currcells = parse_io(xml_bottom_io, "BOTTOM", globalTimingData)
        cells["BOTTOM"] = currcells

    xml_left_io = xml_io.find("LEFT_IO")
    if xml_left_io is not None:
        currcells = parse_io(xml_left_io, "LEFT", globalTimingData)
        cells["LEFT"] = currcells

    xml_right_io = xml_io.find("RIGHT_IO")
    if xml_right_io is not None:
        currcells = parse_io(xml_right_io, "RIGHT", globalTimingData)
        cells["RIGHT"] = currcells

    return cells


# ============================================================================


def read_pinmapfile_data(pinmapfile):
    """
    Loads and parses a pinmap file
    """

    # Read and parse the XML archfile
    parser = ET.XMLParser(resolve_entities=False, strip_cdata=False)
    xml_tree = ET.parse(pinmapfile, parser)
    xml_root = xml_tree.getroot()

    if xml_root.get("name") is None:
        print("ERROR: No mandatory attribute 'name' specified in 'DEVICE' section")
        return None

    if xml_root.get("family") is None:
        print("ERROR: No mandatory attribute 'family' specified in 'DEVICE' section")
        return None

    if xml_root.get("size") is None:
        print(
            "ERROR: No mandatory attribute 'size' specified in 'DEVICE' section"
        )
        return None

    if xml_root.get("foundry") is None:
        print(
            "ERROR: No mandatory attribute 'foundry' specified in 'DEVICE' section"
        )
        return None

    if xml_root.get("node") is None:
        print("ERROR: No mandatory attribute 'node' specified in 'DEVICE' section")
        return None

    if xml_root.get("package") is None:
        print(
            "ERROR: No mandatory attribute 'package' specified in 'DEVICE' section"
        )
        return None

    deviceData = DeviceData(
        name = xml_root.get("name"),
        family = xml_root.get("family"),
        size = xml_root.get("size"),
        foundry = xml_root.get("foundry"),
        node = xml_root.get("node"),
        package = xml_root.get("package")
    )

    globalTimingData = GlobalTimingData(
        clk_edge=xml_root.get("clk_edge", "Rising"),
        time_factor=xml_root.get("time_factor", "0.75"),
        min_time=xml_root.get("min_time", "0")
    )

    # Parse IO cells
    io_cells = parse_io_cells(xml_root, globalTimingData)

    # Parse pinmap
    #pin_map = parse_pinmap(xml_root)

    return deviceData, io_cells


# =============================================================================


def main():

    # Parse arguments
    parser = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter
    )

    parser.add_argument(
        "--pinmapfile",
        type=str,
        required=True,
        help="Input pin-mapping file"
    )
    parser.add_argument(
        "-o",
        type=str,
        default="pinmap.csv",
        help="Output pinmap CSV file"
    )

    args = parser.parse_args()

    # Load all the necessary data from the pinmapfile
    deviceData, io_cells = read_pinmapfile_data(args.pinmapfile)

    print("Device: ", deviceData)
    print("Cells pin-mapping: ", io_cells)

    # Generate the pinmap CSV
    #generate_pinmap_csv(pin_map[args.package], io_cells, vpr_grid_map, args.o)


if __name__ == "__main__":
    main()