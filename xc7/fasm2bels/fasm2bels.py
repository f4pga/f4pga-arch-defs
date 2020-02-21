""" Converts FASM out into BELs and nets.

If given --bitstream argument, will convert bitstream to FASM first, then
convert FASM to BELs and nets.

The BELs will be Xilinx tech primatives.
The nets will be wires and the route those wires takes.

Output is a Verilog file and a TCL script.  Procedure to use the input in
Vivado is roughly:

    create_project -force -part <part> design design
    read_verilog <verilog file name>
    synth_design -top top
    source <tcl script file name>

"""

import argparse
import csv
import os.path
import sqlite3
import subprocess
import tempfile
import json

import fasm
import fasm.output
from fasm import SetFasmFeature
from prjxray import fasm_disassembler
from prjxray import bitstream
import prjxray.db

from .cmt_models import process_pll
from .bram_models import process_bram
from .clb_models import process_clb
from .clk_models import process_hrow, process_bufg
from .connection_db_utils import create_maybe_get_wire, maybe_add_pip, \
        get_tile_type
from .iob_models import process_iobs
from .ioi_models import process_ioi
from .hclk_ioi3_models import process_hclk_ioi3
from .pss_models import get_ps7_site, insert_ps7
from .verilog_modeling import Module
from .net_map import create_net_list

import lib.rr_graph_xml.graph2 as xml_graph2
from lib.parse_pcf import parse_simple_pcf
import eblif


def null_process(conn, top, tile, tiles):
    pass


PROCESS_TILE = {
    'CLBLL_L': process_clb,
    'CLBLL_R': process_clb,
    'CLBLM_L': process_clb,
    'CLBLM_R': process_clb,
    'INT_L': null_process,
    'INT_R': null_process,
    'LIOB33': process_iobs,
    'RIOB33': process_iobs,
    'LIOB33_SING': process_iobs,
    'RIOB33_SING': process_iobs,
    'LIOI3': process_ioi,
    'RIOI3': process_ioi,
    'LIOI3_SING': process_ioi,
    'RIOI3_SING': process_ioi,
    'LIOI3_TBYTESRC': process_ioi,
    'RIOI3_TBYTESRC': process_ioi,
    'LIOI3_TBYTETERM': process_ioi,
    'RIOI3_TBYTETERM': process_ioi,
    'HCLK_L': null_process,
    'HCLK_R': null_process,
    'HCLK_L_BOT_UTURN': null_process,
    'HCLK_R_BOT_UTURN': null_process,
    'CLK_BUFG_REBUF': null_process,
    'CLK_BUFG_BOT_R': process_bufg,
    'CLK_BUFG_TOP_R': process_bufg,
    'CLK_HROW_BOT_R': process_hrow,
    'CLK_HROW_TOP_R': process_hrow,
    'HCLK_CMT': null_process,
    'HCLK_CMT_L': null_process,
    'HCLK_IOI3': process_hclk_ioi3,
    'BRAM_L': process_bram,
    'BRAM_R': process_bram,
    'CMT_TOP_R_UPPER_T': process_pll,
    'CMT_TOP_L_UPPER_T': process_pll,
    'CFG_CENTER_MID': null_process,
}


def process_tile(top, tile, tile_features):
    """ Process a tile emits BELs to module top. """
    tile_type = get_tile_type(top.conn, tile)

    PROCESS_TILE[tile_type](top.conn, top, tile, tile_features)


# A map of wires that require "SING" in their name for [LR]IOI3_SING tiles.
IOI_SING_WIRES = {
    "IOI_IOCLK0": "IOI_SING_IOCLK0",
    "IOI_IOCLK1": "IOI_SING_IOCLK1",
    "IOI_IOCLK2": "IOI_SING_IOCLK2",
    "IOI_IOCLK3": "IOI_SING_IOCLK3",
    "IOI_LEAF_GCLK0": "IOI_SING_LEAF_GCLK0",
    "IOI_LEAF_GCLK1": "IOI_SING_LEAF_GCLK1",
    "IOI_LEAF_GCLK2": "IOI_SING_LEAF_GCLK2",
    "IOI_LEAF_GCLK3": "IOI_SING_LEAF_GCLK3",
    "IOI_LEAF_GCLK4": "IOI_SING_LEAF_GCLK4",
    "IOI_LEAF_GCLK5": "IOI_SING_LEAF_GCLK5",
    "IOI_RCLK_FORIO0": "IOI_SING_RCLK_FORIO0",
    "IOI_RCLK_FORIO1": "IOI_SING_RCLK_FORIO1",
    "IOI_RCLK_FORIO2": "IOI_SING_RCLK_FORIO2",
    "IOI_RCLK_FORIO3": "IOI_SING_RCLK_FORIO3",
    "IOI_TBYTEIN": "IOI_SING_TBYTEIN",
}


def process_set_feature(set_feature):
    """
    Processes fasm features as they are read from the file and modifies them
    if it is required.
    """

    # Get tile name
    parts = set_feature.feature.split(".")
    tile = parts[0]

    # Some wires in [LR]IOI3_SING tiles have different names than in regular
    # IOI3 tiles. Rename them in PIP features.
    if "IOI3_SING" in tile and len(parts) == 3:

        # Rename wires
        wires = [parts[1], parts[2]]
        for i, wire in enumerate(wires):

            # The connection database contains only wires with suffix "0" for
            # SING tiles. Change the wire name accordingly.
            wire = wire.replace("_1", "_0")
            wire = wire.replace("ILOGIC1", "ILOGIC0")
            wire = wire.replace("IDELAY1", "IDELAY0")
            wire = wire.replace("OLOGIC1", "OLOGIC0")

            # Add the "SING" part to wire name if applicable.
            if wire in IOI_SING_WIRES:
                wire = IOI_SING_WIRES[wire]

            wires[i] = wire

        # Return the modified PIP feature
        feature = "{}.{}.{}".format(tile, wires[0], wires[1])

        return SetFasmFeature(
            feature=feature,
            start=set_feature.start,
            end=set_feature.end,
            value=set_feature.value,
            value_format=set_feature.value_format
        )

    # Return unchanged feature
    return set_feature


def find_io_standards(feature):
    """ Scan given feature and return list of possible IOSTANDARDs. """

    if 'IOB' not in feature:
        return

    for part in feature.split('.'):
        if 'LVCMOS' in part or 'LVTTL' in part:
            return part.split('_')


def bit2fasm(db_root, db, grid, bit_file, fasm_file, bitread, part):
    """ Convert bitstream to FASM file. """
    part_yaml = os.path.join(db_root, part, 'part.yaml')
    with tempfile.NamedTemporaryFile() as f:
        bits_file = f.name
        subprocess.check_output(
            '{} --part_file {} -o {} -z -y {}'.format(
                bitread, part_yaml, bits_file, bit_file
            ),
            shell=True
        )

        disassembler = fasm_disassembler.FasmDisassembler(db)

        with open(bits_file) as f:
            bitdata = bitstream.load_bitdata(f)

    model = fasm.output.merge_and_sort(
        disassembler.find_features_in_bitstream(bitdata, verbose=True),
        zero_function=disassembler.is_zero_feature,
        sort_key=grid.tile_key,
    )

    with open(fasm_file, 'w') as f:
        print(
            fasm.fasm_tuple_to_string(model, canonical=False), end='', file=f
        )


def load_io_sites(db_root, part, pcf):
    """ Load map of sites to signal names from pcf and part pin definitions.

    Args:
        db_root (str): Path to database root folder
        part (str): Part name being targeted.
        pcf (str): Full path to pcf file for this bitstream.

    Returns:
        Dict from pad site name to net name.

    """
    pin_to_signal = {}
    with open(pcf) as f:
        for pcf_constraint in parse_simple_pcf(f):
            assert pcf_constraint.pad not in pin_to_signal, pcf_constraint.pad
            pin_to_signal[pcf_constraint.pad] = pcf_constraint.net

    site_to_signal = {}

    with open(os.path.join(db_root, part, 'package_pins.csv')) as f:
        for d in csv.DictReader(f):
            if d['pin'] in pin_to_signal:
                site_to_signal[d['site']] = pin_to_signal[d['pin']]
                del pin_to_signal[d['pin']]

    assert len(pin_to_signal) == 0, pin_to_signal.keys()

    return site_to_signal


def load_net_list(conn, rr_graph_file, route_file):
    xml_graph = xml_graph2.Graph(
        rr_graph_file,
        build_pin_edges=False,
        rebase_nodes=False,
        filter_nodes=False,
    )
    graph = xml_graph.graph

    net_map = {}
    with open(route_file) as f:
        for net in create_net_list(conn, graph, f):
            net_map[net.wire_pkey] = net.name

    return net_map


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        '--connection_database',
        required=True,
        help="Path to SQLite3 database for given FASM file part."
    )
    parser.add_argument(
        '--db_root',
        required=True,
        help="Path to prjxray database for given FASM file part."
    )
    parser.add_argument(
        '--allow_orphan_sinks',
        action='store_true',
        help="Allow sinks to have no connection."
    )
    parser.add_argument(
        '--prune-unconnected-ports',
        action='store_true',
        help="Prune top-level I/O ports that are not connected to any logic."
    )
    parser.add_argument(
        '--fasm_file',
        help="FASM file to convert BELs and routes.",
        required=True
    )
    parser.add_argument(
        '--bit_file', help="Bitstream file to convert to FASM."
    )
    parser.add_argument(
        '--bitread',
        help="Path to bitread executable, required if --bit_file is provided."
    )
    parser.add_argument(
        '--part',
        help="Name of part being targeted, required if --bit_file is provided."
    )
    parser.add_argument(
        '--allow-non-dedicated-clk-routes',
        action='store_true',
        help="Effectively sets CLOCK_DEDICATED_ROUTE to FALSE on all nets."
    )
    parser.add_argument(
        '--iostandard',
        default=None,
        help=
        "Default IOSTANDARD to use for IO buffers if it cannot be determined from fasm and eblif."
    )
    parser.add_argument(
        '--drive',
        type=int,
        default=None,
        help=
        "Default DRIVE to use for IO buffers if it cannot be determined from fasm and eblif."
    )
    parser.add_argument('--top', default="top", help="Root level module name.")
    parser.add_argument('--pcf', help="Mapping of top-level pins to pads.")
    parser.add_argument('--route_file', help="VPR route output file.")
    parser.add_argument('--rr_graph', help="Real or virt xc7 graph")
    parser.add_argument('--eblif', help="EBLIF file used to generate design")
    parser.add_argument('verilog_file', help="Filename of output verilog file")
    parser.add_argument('tcl_file', help="Filename of output tcl script.")

    args = parser.parse_args()

    conn = sqlite3.connect(
        'file:{}?mode=ro'.format(args.connection_database), uri=True
    )

    db = prjxray.db.Database(args.db_root, args.part)
    grid = db.grid()

    if args.bit_file:
        bit2fasm(
            args.db_root, db, grid, args.bit_file, args.fasm_file,
            args.bitread, args.part
        )

    tiles = {}

    maybe_get_wire = create_maybe_get_wire(conn)

    top = Module(db, grid, conn, name=args.top)
    if args.pcf:
        top.set_site_to_signal(
            load_io_sites(args.db_root, args.part, args.pcf)
        )

    if args.route_file:
        assert args.rr_graph
        net_map = load_net_list(conn, args.rr_graph, args.route_file)
        top.set_net_map(net_map)

    if args.part:
        with open(os.path.join(args.db_root, args.part, 'part.json')) as f:
            part_data = json.load(f)
            top.set_io_banks(part_data['iobanks'])

    if args.eblif:
        with open(args.eblif) as f:
            parsed_eblif = eblif.parse_blif(f)

        top.add_to_cname_map(parsed_eblif)
        top.make_iosettings_map(parsed_eblif)

    top.set_default_iostandard(args.iostandard, args.drive)

    for fasm_line in fasm.parse_fasm_filename(args.fasm_file):
        if not fasm_line.set_feature:
            continue

        set_feature = process_set_feature(fasm_line.set_feature)

        parts = set_feature.feature.split('.')
        tile = parts[0]

        if tile not in tiles:
            tiles[tile] = []

        tiles[tile].append(set_feature)

        if len(parts) == 3:
            maybe_add_pip(top, maybe_get_wire, set_feature)

    for tile, tile_features in tiles.items():
        process_tile(top, tile, tile_features)

    # Check if the PS7 is present in the tilegrid. If so then insert it.
    pss_tile, ps7_site = get_ps7_site(db)
    if pss_tile is not None and ps7_site is not None:

        # First load the PS7 ports
        fname = os.path.join(args.db_root, "ps7_ports.json")
        with open(fname, "r") as fp:
            ps7_ports = json.load(fp)

        # Insert the PS7
        insert_ps7(top, pss_tile, ps7_site, ps7_ports)

    top.make_routes(allow_orphan_sinks=args.allow_orphan_sinks)

    if args.prune_unconnected_ports:
        top.prune_unconnected_ports()

    if args.allow_non_dedicated_clk_routes:
        top.add_extra_tcl_line(
            "set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets]"
        )

    with open(args.verilog_file, 'w') as f:
        for l in top.output_verilog():
            print(l, file=f)

    with open(args.tcl_file, 'w') as f:
        for l in top.output_bel_locations():
            print(l, file=f)

        for l in top.output_nets():
            print(l, file=f)

        for l in top.output_disabled_drcs():
            print(l, file=f)

        for l in top.output_extra_tcl():
            print(l, file=f)


if __name__ == "__main__":
    main()
