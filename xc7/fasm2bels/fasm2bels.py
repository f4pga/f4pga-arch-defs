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
import os.path
import sqlite3
import subprocess
import tempfile

import fasm
import fasm.output
from prjxray import fasm_disassembler
from prjxray import bitstream
import prjxray.db

from .bram_models import process_bram
from .clb_models import process_clb
from .clk_models import process_hrow, process_bufg
from .connection_db_utils import create_maybe_get_wire, maybe_add_pip, \
        get_tile_type
from .iob_models import process_iobs
from .verilog_modeling import Module


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
        'HCLK_L': null_process,
        'HCLK_R': null_process,
        'CLK_BUFG_REBUF': null_process,
        'CLK_BUFG_BOT_R': process_bufg,
        'CLK_BUFG_TOP_R': process_bufg,
        'CLK_HROW_BOT_R': process_hrow,
        'CLK_HROW_TOP_R': process_hrow,
        'HCLK_CMT': null_process,
        'HCLK_CMT_L': null_process,
        'BRAM_L': process_bram,
        'BRAM_R': process_bram,
        }


def process_tile(top, tile, tile_features):
    """ Process a tile emits BELs to module top. """
    tile_type = get_tile_type(top.conn, tile)

    PROCESS_TILE[tile_type](top.conn, top, tile, tile_features)


def find_io_standards(feature):
    """ Scan given feature and return list of possible IOSTANDARDs. """

    if 'IOB' not in feature:
        return

    for part in feature.split('.'):
        if 'LVCMOS' in part or 'LVTTL' in part:
            return part.split('_')

def bit2fasm(db_root, db, grid, bit_file, fasm_file, bitread, part):
    """ Convert bitstream to FASM file. """
    part_yaml = os.path.join(db_root, '{}.yaml'.format(part))
    with tempfile.NamedTemporaryFile() as f:
        bits_file = f.name
        subprocess.check_output(
            '{} --part_file {} -o {} -z -y {}'.format(
                bitread, part_yaml, bits_file, bit_file),
            shell=True)

        disassembler = fasm_disassembler.FasmDisassembler(db)

        with open(bits_file) as f:
            bitdata = bitstream.load_bitdata(f)

    model = fasm.output.merge_and_sort(
        disassembler.find_features_in_bitstream(bitdata, verbose=True),
        zero_function=disassembler.is_zero_feature,
        sort_key=grid.tile_key,
    )

    with open(fasm_file, 'w') as f:
        print(fasm.fasm_tuple_to_string(model, canonical=False), end='',
                file=f)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--connection_database', required=True,
            help="Path to SQLite3 database for given FASM file part.")
    parser.add_argument('--db_root', required=True,
            help="Path to prjxray database for given FASM file part.")
    parser.add_argument('--allow_orphan_sinks', action='store_true',
            help="Allow sinks to have no connection.")
    parser.add_argument('--iostandard',
            help="Specify IOSTANDARD to use in event of no clear IOSTANDARD from FASM file.")
    parser.add_argument('--fasm_file',
            help="FASM file to convert BELs and routes.",
            required=True)
    parser.add_argument('--bit_file',
            help="Bitstream file to convert to FASM.")
    parser.add_argument('--bitread',
            help="Path to bitread executable, required if --bit_file is provided.")
    parser.add_argument(
        '--part', help="Name of part being targetted, required if --bit_file is provided.")
    parser.add_argument('verilog_file',
            help="Filename of output verilog file")
    parser.add_argument('tcl_file',
            help="Filename of output tcl script.")

    args = parser.parse_args()

    conn = sqlite3.connect('file:{}?mode=ro'.format(args.connection_database),
            uri=True)

    db = prjxray.db.Database(args.db_root)
    grid = db.grid()

    if args.bit_file:
        bit2fasm(args.db_root, db, grid, args.bit_file, args.fasm_file, args.bitread,
                args.part)

    tiles = {}

    maybe_get_wire = create_maybe_get_wire(conn)

    top = Module(db, grid, conn)

    iostandards = []

    if args.iostandard:
        iostandards.append([args.iostandard])

    for fasm_line in fasm.parse_fasm_filename(args.fasm_file):
        if not fasm_line.set_feature:
            continue

        possible_iostandards = find_io_standards(fasm_line.set_feature.feature)
        if possible_iostandards is not None:
            iostandards.append(possible_iostandards)

        parts = fasm_line.set_feature.feature.split('.')
        tile = parts[0]

        if tile not in tiles:
            tiles[tile] = []

        tiles[tile].append(fasm_line.set_feature)

        if len(parts) == 3:
            maybe_add_pip(top, maybe_get_wire, fasm_line.set_feature)

    top.set_iostandard(iostandards)

    for tile, tile_features in tiles.items():
        process_tile(top, tile, tile_features)

    top.make_routes(allow_orphan_sinks=args.allow_orphan_sinks)

    with open(args.verilog_file, 'w') as f:
        for l in top.output_verilog():
            print(l, file=f)

    with open(args.tcl_file, 'w') as f:
        for l in top.output_bel_locations():
            print(l, file=f)

        for l in top.output_nets():
            print(l, file=f)


if __name__ == "__main__":
    main()
