""" Converts FASM out into BELs and nets.

The BELs will be Xilinx tech primatives.
The nets will be wires and the route those wires takes.

"""

import argparse
import sqlite3

import fasm
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
    tile_type = get_tile_type(top.conn, tile)

    PROCESS_TILE[tile_type](top.conn, top, tile, tile_features)


def add_io_standards(iostandards, feature):
    if 'IOB' not in feature:
        return

    for part in feature.split('.'):
        if 'LVCMOS' in part or 'LVTTL' in part:
            iostandards.append(part.split('_'))

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--connection_database', required=True)
    parser.add_argument('--db_root', required=True)
    parser.add_argument('--allow_orphan_sinks', action='store_true')
    parser.add_argument('--iostandard')
    parser.add_argument('fasm_file')
    parser.add_argument('verilog_file')
    parser.add_argument('tcl_file')

    args = parser.parse_args()

    conn = sqlite3.connect('file:{}?mode=ro'.format(args.connection_database), uri=True)

    db = prjxray.db.Database(args.db_root)
    grid = db.grid()

    tiles = {}

    maybe_get_wire = create_maybe_get_wire(conn)

    top = Module(db, grid, conn)

    iostandards = []

    if args.iostandard:
        iostandards.append([args.iostandard])

    for fasm_line in fasm.parse_fasm_filename(args.fasm_file):
        if not fasm_line.set_feature:
            continue

        add_io_standards(iostandards, fasm_line.set_feature.feature)

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
    top.handle_post_route_cleanup()

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
