""" Converts FASM out into BELs and nets.

The BELs will be Xilinx tech primatives.
The nets will be wires and the route those wires takes.

"""

import argparse
import sqlite3
import fasm
import re
import prjxray.db
import functools
from prjxray_bram_models import process_bram
from verilog_modeling import Bel, Module, Site


def get_clb_site(db, grid, tile, site):
    gridinfo = grid.gridinfo_at_tilename(tile)
    tile_type = db.get_tile_type(gridinfo.tile_type)

    sites = sorted(tile_type.get_instance_sites(gridinfo), key=lambda x: x.x)

    return sites[int(site[-1])]


def get_lut_init(features, tile_name, slice_name, lut):
    target_feature = '{}.{}.{}LUT.INIT'.format(tile_name, slice_name, lut)

    init = 0

    for f in features:
        if f.feature.startswith(target_feature):
            for canon_f in fasm.canonical_features(f):
                if canon_f.start is None:
                    init |= 1
                else:
                    init |= (1 << canon_f.start)

    return "64'b{:064b}".format(init)


def create_lut(site, lut):
    bel = Bel('LUT6_2', lut + 'LUT')
    bel.set_bel(lut + '6LUT')

    for idx in range(6):
        site.add_sink(bel, 'I{}'.format(idx), '{}{}'.format(lut, idx+1))
        site.add_internal_source(bel, 'O6', lut + 'O6')
        site.add_internal_source(bel, 'O5', lut + 'O5')

    return bel


def decode_dram(site, lut_ram, di):
    lut_modes = {}
    if site.has_feature('WA8USED'):
        assert site.has_feature('WA7USED')
        assert lut_ram['A']
        assert lut_ram['B']
        assert lut_ram['C']
        assert lut_ram['D']

        lut_modes['A'] = 'RAM256X1S'
        lut_modes['B'] = 'RAM256X1S'
        lut_modes['C'] = 'RAM256X1S'
        lut_modes['D'] = 'RAM256X1S'
        return lut_modes

    if site.has_feature('WA7USED'):
        if not lut_ram['A']:
            assert not lut_ram['B']
            assert lut_ram['C']
            assert lut_ram['D']
            lut_modes['A'] = 'LUT'
            lut_modes['B'] = 'LUT'
            lut_modes['C'] = 'RAM128X1S'
            lut_modes['D'] = 'RAM128X1S'

            return lut_modes

        assert lut_ram['B']

        if di['B']:
            lut_modes['A'] = 'RAM128X1S'
            lut_modes['B'] = 'RAM128X1S'
            lut_modes['C'] = 'RAM128X1S'
            lut_modes['D'] = 'RAM128X1S'
        else:
            assert lut_ram['B']
            assert lut_ram['C']
            assert lut_ram['D']

            lut_modes['A'] = 'RAM128X1D'
            lut_modes['B'] = 'RAM128X1D'
            lut_modes['C'] = 'RAM128X1D'
            lut_modes['D'] = 'RAM128X1D'

        return lut_modes

    # Remaining modes:
    # RAM32X1S, RAM32X1D, RAM64X1S, RAM64X1D

    remaining = set('ABCD')

    for lut in 'AC':
        if lut_ram[lut] and di[lut]:
            remaining.remove(lut)

            if site.has_feature('{}LUT.SMALL'.format(lut)):
                lut_modes[lut] = 'RAM32X2S'
            else:
                lut_modes[lut] = 'RAM64X1S'

    for lut in 'BD':
        if not lut_ram[lut]:
            continue

        minus_one = chr(ord(lut)-1)
        if minus_one in remaining:
            if lut_ram[minus_one]:
                remaining.remove(lut)
                remaining.remove(minus_one)
                if site.has_feature('{}LUT.SMALL'.format(lut)):
                    lut_modes[lut] = 'RAM32X1D'
                    lut_modes[minus_one] = 'RAM32X1D'
                else:
                    lut_modes[lut] = 'RAM64X1D'
                    lut_modes[minus_one] = 'RAM64X1D'

        if lut in remaining:
            remaining.remove(lut)
            if site.has_feature('{}LUT.SMALL'.format(lut)):
                lut_modes[lut] = 'RAM32X2S'
            else:
                lut_modes[lut] = 'RAM64X1S'

    for lut in remaining:
        lut_modes[lut] = 'LUT'

    return lut_modes


def ff_bel(site, lut, ff5):
    ffsync = site.has_feature('FFSYNC')
    latch = site.has_feature('LATCH') and not ff5
    zrst = site.has_feature('{}{}FF.ZRST'.format(lut, '5' if ff5 else ''))
    zini = site.has_feature('{}{}FF.ZINI'.format(lut, '5' if ff5 else ''))
    init = int(not zini)

    if latch:
        assert not ffsync

    return {
            (False, False, False) : ('FDPE', 'C', 'CE', 'PRE', init),
            (True, False, False) : ('FDSE', 'C', 'CE', 'S', init),
            (True, False, True) : ('FDRE', 'C', 'CE', 'R', init),
            (False, False, True) : ('FDCE', 'C', 'CE', 'CLR', init),
            (False, True, True) : ('LDCE', 'G', 'GE', 'CLR', init),
            (False, True, False) : ('LDPE', 'G', 'GE', 'PRE', init),
            }[(ffsync, latch, zrst)]

def cleanup_slice(top, site):
    """ Perform post-routing cleanups required for SLICE.

    Cleanups:
     - Detect if CARRY4 is required.  If not, remove from site.

    """
    carry4 = site.maybe_get_bel('CARRY4')

    if carry4 is None:
        return

    # Simplest check is if the CARRY4 has output in used by either the OUTMUX
    # or the FFMUX, if any of these muxes are enable, CARRY4 must remain.
    for lut in 'ABCD':
        if site.has_feature('{}FFMUX.XOR'.format(lut)):
            return

        if site.has_feature('{}FFMUX.CY'.format(lut)):
            return

        if site.has_feature('{}OUTMUX.XOR'.format(lut)):
            return

        if site.has_feature('{}OUTMUX.CY'.format(lut)):
            return

    # No outputs in the SLICE use CARRY4, check if the COUT line is in use.
    for sink in top.find_sinks_from_source(site, 'COUT'):
        return

    top.remove_bel(site, carry4)

def process_slice(top, s):
    """
    Available options:

    LUT/DRAM/SRL:
    SLICE[LM]_X[01].[ABCD]LUT.INIT[63:0]
    SLICEM_X0.[ABCD]LUT.RAM
    SLICEM_X0.[ABCD]LUT.SMALL
    SLICEM_X0.[ABCD]LUT.SRL

    FF:
    SLICE[LM]_X[01].[ABCD]5?FF.ZINI
    SLICE[LM]_X[01].[ABCD]5?FF.ZRST
    SLICE[LM]_X[01].CLKINV
    SLICE[LM]_X[01].FFSYNC
    SLICE[LM]_X[01].LATCH
    SLICE[LM]_X[01].CEUSEDMUX
    SLICE[LM]_X[01].SRUSEDMUX

    CARRY4:
    SLICE[LM]_X[01].PRECYINIT = AX|CIN|C0|C1

    Muxes:
    SLICE[LM]_X[01].CARRY4.ACY0
    SLICE[LM]_X[01].CARRY4.BCY0
    SLICE[LM]_X[01].CARRY4.CCY0
    SLICE[LM]_X[01].CARRY4.DCY0
    SLICE[LM]_X[01].[ABCD]5FFMUX.IN_[AB]
    SLICE[LM]_X[01].[ABCD]AFFMUX = [ABCD]X|CY|XOR|F[78]|O5|O6
    SLICE[LM]_X[01].[ABCD]OUTMUX = CY|XOR|F[78]|O5|O6|[ABCD]5Q
    SLICEM_X0.WA7USED
    SLICEM_X0.WA8USED
    SLICEM_X0.WEMUX.CE
    """

    aparts = s[0].feature.split('.')
    site = Site(s, get_clb_site(top.db, top.grid, tile=aparts[0], site=aparts[1]))

    mlut = aparts[1].startswith('SLICEM')

    def connect_ce_sr(bel, ce, sr):
        if site.has_feature('CEUSEDMUX'):
            site.add_sink(bel, ce, 'CE')
        else:
            bel.connections[ce] = 1

        if site.has_feature('SRUSEDMUX'):
            site.add_sink(bel, sr, 'SR')
        else:
            bel.connections[sr] = 0

    IS_C_INVERTED = int(site.has_feature('CLKINV'))

    if mlut:
        if site.has_feature('WEMUX.CE'):
            WE = 'WE'
        else:
            WE = 'CE'

    if site.has_feature('DLUT.RAM'):
        # Must be a SLICEM to have RAM set.
        assert mlut
    else:
        for row in 'ABC':
            assert not site.has_feature('{}LUT.RAM')

    # SRL not currently supported
    for row in 'ABCD':
        assert not site.has_feature('{}LUT.SRL')

    muxes = set(('F7AMUX', 'F7BMUX', 'F8MUX'))

    luts = {}
    # Add BELs for LUTs/RAMs
    if site.has_feature('DLUT.RAM'):
        for lut in 'ABCD':
            luts[lut] = create_lut(site, lut)
            luts[lut].parameters['INIT'] = get_lut_init(s, aparts[0], aparts[1], lut)
            site.add_bel(luts[lut])
    else:
        # DRAM is active.  Determine what BELs are in use.
        lut_ram = {}
        for lut in 'ABCD':
            lut_ram[lut] = site.has_feature('{}LUT.RAM')

        di = {}
        for lut in 'ABC':
            di[lut] = site.has_feature('DI1MUX.{}I'.format(lut))

        lut_modes = decode_dram(site, lut_ram, di)

        if lut_modes['D'] == 'RAM256X1S':
            ram256 = Bel('RAM256X1S')
            site.add_sink(ram256, 'WE', WE)
            site.add_sink(ram256, 'WCLK', 'CLK')
            site.add_sink(ram256, 'D', 'DI')

            for idx in range(6):
                site.add_sink(ram256, 'A[{}]'.format(idx), "D{}".format(idx+1))

            site.add_sink(ram256, 'A[6]', "CX")
            site.add_sink(ram256, 'A[7]', "BX")
            site.add_internal_source(ram256, 'O', 'F8MUX_O')

            ram256.parameters['INIT'] = (
                    get_lut_init(s, aparts[0], aparts[1], 'D') |
                    (get_lut_init(s, aparts[0], aparts[1], 'C') << 64) |
                    (get_lut_init(s, aparts[0], aparts[1], 'B') << 128) |
                    (get_lut_init(s, aparts[0], aparts[1], 'A') << 192)
                    )

            site.add_bel(ram256)

            muxes = set()

            del lut_modes['A']
            del lut_modes['B']
            del lut_modes['C']
            del lut_modes['D']
        elif lut_modes['D'] == 'RAM128X1S':
            ram128 = Bel('RAM128X1S')
            site.add_sink(ram128, 'WE', WE)
            site.add_sink(ram128, 'WCLK', "CLK")
            site.add_sink(ram128, 'D', "DI")

            for idx in range(6):
                site.add_sink(ram128, 'A{}'.format(idx), "D{}".format(idx+1))

            site.add_sink(ram128, 'A6', "CX")
            site.add_internal_source(ram128, 'O', 'F7BMUX_O')

            ram128.parameters['INIT'] = (
                    get_lut_init(s, aparts[0], aparts[1], 'D') |
                    (get_lut_init(s, aparts[0], aparts[1], 'C') << 64))

            site.add_bel(ram128)
            muxes.remove('F7BMUX')

            del lut_modes['C']
            del lut_modes['D']

            if lut_modes['B'] == 'RAM128X1S':
                ram128 = Bel('RAM128X1S')
                site.add_sink(ram128, 'WE', WE)
                site.add_sink(ram128, 'WCLK', "CLK")
                site.add_sink(ram128, 'D', "BI")

                for idx in range(6):
                    site.adD_sink(ram128, 'A{}'.format(idx), "B{}".format(idx+1))

                site.add_sink(ram128, 'A6', "AX")

                site.add_internal_source(ram128, 'O', 'F7AMUX_O')

                ram128.parameters['INIT'] = (
                        get_lut_init(s, aparts[0], aparts[1], 'B') |
                        (get_lut_init(s, aparts[0], aparts[1], 'A') << 64))

                site.add_bel(ram128)

                muxes.remove('F7AMUX')

                del lut_modes['A']
                del lut_modes['B']

        elif lut_modes['D'] == 'RAM128X1D':
            ram128 = Bel('RAM128X1D')

            site.add_sink(ram128, 'WE', WE)
            site.add_sink(ram128, 'WCLK', "CLK")
            site.add_sink(ram128, 'D', "DI")

            for idx in range(6):
                site.add_sink(ram128, 'A[{}]'.format(idx), "D{}".format(idx+1))
                site.add_sink(ram128, 'DPRA[{}]'.format(idx), "C{}".format(idx+1))

            site.add_sink(ram128, 'A[6]', "CX")
            site.add_sink(ram128, 'DPRA[6]', "AX")

            site.add_internal_source(ram128, 'SPO', 'F7AMUX_O')
            site.add_internal_source(ram128, 'DPO', 'F7BMUX_O')

            ram128.parameters['INIT'] = (
                    get_lut_init(s, aparts[0], aparts[1], 'D') |
                    (get_lut_init(s, aparts[0], aparts[1], 'C') << 64))

            other_init = (
                    get_lut_init(s, aparts[0], aparts[1], 'B') |
                    (get_lut_init(s, aparts[0], aparts[1], 'A') << 64))

            assert ram128.parameters['INIT'] == other_init

            site.add_bel(ram128)

            muxes.remove('F7AMUX')
            muxes.remove('F7BMUX')

            del lut_modes['A']
            del lut_modes['B']
            del lut_modes['C']
            del lut_modes['D']

        for lut in 'BD':
            minus_one = chr(ord(lut)-1)

            if lut_modes[lut] == 'RAM64X1D':
                assert lut_modes[minus_one] == lut_modes[lut]

                ram64 = Bel('RAM64X1D')

                site.add_sink(ram64, 'WE', WE)
                site.add_sink(ram64, 'WCLK', "CLK")
                site.add_sink(ram64, 'D', lut + "I")

                for idx in range(6):
                    site.add_sink(ram64, 'A{}'.format(idx), "{}{}".format(lut, idx+1))
                    site.add_sink(ram64, 'DPRA{}'.format(idx), "{}{}".format(minus_one, idx+1))

                site.add_internal_source(ram64, 'SPO', lut + "O6")
                site.add_internal_source(ram64, 'DPO', minus_one + "O6")

                ram64.parameters['INIT'] = get_lut_init(s, aparts[0], aparts[1], lut)
                other_init = get_lut_init(s, aparts[0], aparts[1], minus_one)

                assert ram64.parameters['INIT'] == other_init

                site.add_bel(ram64)

                del lut_modes[lut]
                del lut_modes[minus_one]
            elif lut_modes[lut] == 'RAM32X1D':
                ram32 = Bel('RAM32X1D')

                site.add_sink(ram32, 'WE', WE)
                site.add_sink(ram32, 'WCLK', "CLK")
                site.add_sink(ram32, 'D', lut + "I")

                for idx in range(5):
                    site.add_sink(ram64, 'A{}'.format(idx), "{}{}".format(lut, idx+1))
                    site.add_sink(ram64, 'DPRA{}'.format(idx), "{}{}".format(minus_one, idx+1))

                site.add_sink(ram32, 'SPO', lut + "O6")
                site.add_sink(ram32, 'DPO', minus_one + "O6")

                ram32.parameters['INIT'] = get_lut_init(s, aparts[0], aparts[1], lut)
                other_init = get_lut_init(s, aparts[0], aparts[1], minus_one)

                site.add_bel(ram32)

                del lut_modes[lut]
                del lut_modes[minus_one]

        for lut in 'ABCD':
            if lut not in lut_modes:
                continue

            if lut_modes[lut] == 'LUT':
                luts[lut] = create_lut(site, lut)
                luts[lut].parameters['INIT'] = get_lut_init(s, aparts[0], aparts[1], lut)
                site.add_bel(luts[lut])
            elif lut_modes[lut] == 'RAM64X1S':
                ram64 = Bel('RAM64X1S')

                site.add_sink(ram64, 'WE', WE)
                site.add_sink(ram64, 'WCLK', "CLK")
                site.add_sink(ram64, 'D', lut + "I")

                for idx in range(6):
                    site.add_sink(ram64, 'A{}'.format(idx), "{}{}".format(lut, idx+1))

                site.add_internal_source(ram64, 'O', lut + "O6")

                ram64.parameters['INIT'] = get_lut_init(s, aparts[0], aparts[1], lut)
                other_init = get_lut_init(s, aparts[0], aparts[1], minus_one)

                assert ram64.parameters['INIT'] == other_init

                site.add_bel(ram64)
            elif lut_modes[lut] == 'RAM32X2S':
                ram32 = Bel('RAM32X1S')

                site.add_sink(ram32, 'WE', WE)
                site.add_sink(ram32, 'WCLK', "CLK")
                site.add_sink(ram32, 'D', lut + "I")

                for idx in range(5):
                    site.add_sink(ram32, 'A{}'.format(idx), "{}{}".format(lut, idx+1))

                site.add_internal_source(ram32 ,'O', lut + "O6")

                ram32.parameters['INIT'] = get_lut_init(s, aparts[0], aparts[1], lut)

                site.add_bel(ram32)
            else:
                assert False, lut_modes[lut]

    need_f8 = site.has_feature('BFFMUX.F8') or site.has_feature('BOUTMUX.F8')
    need_f7a = site.has_feature('AFFMUX.F7') or site.has_feature('AOUTMUX.F7')
    need_f7b = site.has_feature('CFFMUX.F7') or site.has_feature('COUTMUX.F7')

    for mux in sorted(muxes):
        if mux == 'F7AMUX':
            if not need_f8 and not need_f7a:
                continue
            else:
                bel_type = 'MUXF7'
                opin = 'O'

            f7amux = Bel(bel_type, 'MUXF7A')
            f7amux.set_bel('F7AMUX')

            site.connect_internal(f7amux, 'I0', 'BO6')
            site.connect_internal(f7amux, 'I1', 'AO6')
            site.add_sink(f7amux, 'S', 'AX')

            site.add_internal_source(f7amux, opin, 'F7AMUX_O')

            site.add_bel(f7amux)
        elif mux == 'F7BMUX':
            if not need_f8 and not need_f7b:
                continue
            else:
                bel_type = 'MUXF7'
                opin = 'O'

            f7bmux = Bel(bel_type, 'MUXF7B')
            f7bmux.set_bel('F7BMUX')

            site.connect_internal(f7bmux, 'I0', 'DO6')
            site.connect_internal(f7bmux, 'I1', 'CO6')
            site.add_sink(f7bmux, 'S', 'CX')

            site.add_internal_source(f7bmux, opin, 'F7BMUX_O')

            site.add_bel(f7bmux)
        elif mux == 'F8MUX':
            if not need_f8:
                continue
            else:
                bel_type = 'MUXF8'
                opin = 'O'

            f8mux = Bel(bel_type)

            site.connect_internal(f8mux, 'I0', 'F7BMUX_O')
            site.connect_internal(f8mux, 'I1', 'F7AMUX_O')
            site.add_sink(f8mux, 'S', 'BX')

            site.add_internal_source(f8mux, opin, 'F8MUX_O')

            site.add_bel(f8mux)
        else:
            assert False, mux

    can_have_carry4 = True
    for lut in 'ABCD':
        if site.has_feature(lut + 'O6'):
            can_have_carry4 = False
            break

    if can_have_carry4:
        bel = Bel('CARRY4')

        for idx in range(4):
            lut = chr(ord('A') + idx)
            if site.has_feature('CARRY4.{}CY0'.format(lut)):
                source = lut + 'O5'
                site.connect_internal(bel, 'DI[{}]'.format(idx), source)
            else:
                site.add_sink(bel, 'DI[{}]'.format(idx), lut + 'X')

            source = lut + 'O6'

            site.connect_internal(bel, 'S[{}]'.format(idx), source)

            site.add_internal_source(bel, 'O[{}]'.format(idx), lut + '_XOR')

            co_pin = 'CO[{}]'.format(idx)
            if idx == 3:
                site.add_source(bel, co_pin, 'COUT')
            else:
                site.add_internal_source(bel, co_pin, lut + '_CY')

        if site.has_feature('PRECYINIT.AX'):
            site.add_sink(bel, 'CYINIT', 'AX')
            bel.unused_connections.add('CI')

        elif site.has_feature('PRECYINIT.C0'):
            bel.connections['CYINIT'] = 0
            bel.unused_connections.add('CI')

        elif site.has_feature('PRECYINIT.C1'):
            bel.connections['CYINIT'] = 1
            bel.unused_connections.add('CI')

        elif site.has_feature('PRECYINIT.CIN'):
            bel.unused_connections.add('CYINIT')
            site.add_sink(bel, 'CI', 'CIN')

        else:
            assert False

        site.add_bel(bel, name='CARRY4')

    ff5_bels = {}
    for lut in 'ABCD':
        if site.has_feature('{}OUTMUX.{}5Q'.format(lut, lut)):
            # 5FF in use, emit
            name, clk, ce, sr, init = ff_bel(site, lut, ff5=True)
            ff5 = Bel(name, "{}5_{}".format(lut, name))
            ff5_bels[lut] = ff5
            ff5.set_bel(lut + '5FF')

            if site.has_feature('{}5FFMUX.IN_A'.format(lut)):
                site.connect_internal(ff5, 'D', lut + 'O5')
            elif site.has_feature('{}5FFMUX.IN_B'.format(lut)):
                site.add_sink(ff5, 'D', lut + 'X')

            site.add_sink(ff5, clk, "CLK")

            connect_ce_sr(ff5, ce, sr)

            site.add_internal_source(ff5, 'Q', lut + '5Q')
            ff5.parameters['INIT'] = init
            ff5.parameters['IS_C_INVERTED'] = IS_C_INVERTED

            site.add_bel(ff5)

    for lut in 'ABCD':
        name, clk, ce, sr, init = ff_bel(site, lut, ff5=False)
        ff = Bel(name, "{}_{}".format(lut, name))
        ff.set_bel(lut + 'FF')

        if site.has_feature('{}FFMUX.{}X'.format(lut, lut)):
            site.add_sink(ff, 'D', lut + 'X')

        elif lut == 'A' and site.has_feature('AFFMUX.F7'):
            site.connect_internal(ff, 'D', 'F7AMUX_O')

        elif lut == 'C' and site.has_feature('CFFMUX.F7'):
            site.connect_internal(ff, 'D', 'F7BMUX_O')

        elif lut == 'B' and site.has_feature('BFFMUX.F8'):
            site.connect_internal(ff, 'D', 'F8MUX_O')

        elif site.has_feature('{}FFMUX.O5'.format(lut)):
            site.connect_internal(ff, 'D', lut + 'O5')

        elif site.has_feature('{}FFMUX.O6'.format(lut)):
            site.connect_internal(ff, 'D', lut + 'O6')

        elif site.has_feature('{}FFMUX.CY'.format(lut)):
            assert can_have_carry4
            if lut != 'D':
                site.connect_internal(ff, 'D', lut + '_CY')
            else:
                ff.connections['D'] = 'COUT'
        elif site.has_feature('{}FFMUX.XOR'.format(lut)):
            assert can_have_carry4
            site.connect_internal(ff, 'D', lut + '_XOR')
        else:
            continue

        site.add_source(ff, 'Q', lut + 'Q')
        site.add_sink(ff, clk, "CLK")

        connect_ce_sr(ff, ce, sr)

        ff.parameters['INIT'] = init
        ff.parameters['IS_C_INVERTED'] = IS_C_INVERTED

        site.add_bel(ff)

    for lut in 'ABCD':
        if lut + 'O6' in site.internal_sources:
            site.add_output_from_internal(lut, lut + 'O6')

    for lut in 'ABCD':
        output_wire = lut + 'MUX'
        if site.has_feature('{}OUTMUX.{}5Q'.format(lut, lut)):
            site.add_output_from_internal(output_wire, lut + '5Q')

        elif lut == 'A' and site.has_feature('AOUTMUX.F7'):
            site.add_output_from_internal(output_wire, 'F7AMUX_O')

        elif lut == 'C' and site.has_feature('COUTMUX.F7'):
            site.add_output_from_internal(output_wire, 'F7BMUX_O')

        elif lut == 'B' and site.has_feature('BOUTMUX.F8'):
            site.add_output_from_internal(output_wire, 'F8MUX_O')

        elif site.has_feature('{}OUTMUX.O5'.format(lut)):
            site.add_output_from_internal(output_wire, lut + 'O5')

        elif site.has_feature('{}OUTMUX.O6'.format(lut)):
            # Note: There is a dedicated O6 output.  Fixed routing requires
            # treating xMUX.O6 as a routing connection.
            site.add_output_from_output(output_wire, lut)

        elif site.has_feature('{}OUTMUX.CY'.format(lut)):
            assert can_have_carry4
            if lut != 'D':
                site.add_output_from_internal(output_wire, lut + '_CY')
            else:
                site.add_output_from_output(output_wire, 'COUT')

        elif site.has_feature('{}OUTMUX.XOR'.format(lut)):
            assert can_have_carry4
            site.add_output_from_internal(output_wire, lut + '_XOR')
        else:
            continue

    site.set_post_route_cleanup_function(cleanup_slice)
    top.add_site(site)


def process_clb(conn, top, tile_name, features):
    slices = {
            '0': [],
            '1': [],
            }

    for f in features:
        parts = f.feature.split('.')

        if not parts[1].startswith('SLICE'):
            continue

        slices[parts[1][-1]].append(f)

    for s in slices:
        if len(slices[s]) > 0:
            process_slice(top, slices[s])

def create_maybe_get_wire(conn):
    c = conn.cursor()

    @functools.lru_cache(maxsize=None)
    def get_tile_type_pkey(tile):
        c.execute('SELECT pkey, tile_type_pkey FROM tile WHERE name = ?',
                (tile,))
        return c.fetchone()

    @functools.lru_cache(maxsize=None)
    def maybe_get_wire(tile, wire):
        tile_pkey, tile_type_pkey = get_tile_type_pkey(tile)

        c.execute('SELECT pkey FROM wire_in_tile WHERE tile_type_pkey = ? and name = ?',
                (tile_type_pkey, wire))

        result = c.fetchone()

        if result is None:
            return None

        wire_in_tile_pkey = result[0]

        c.execute('SELECT pkey FROM wire WHERE tile_pkey = ? AND wire_in_tile_pkey = ?',
                (tile_pkey, wire_in_tile_pkey))

        return c.fetchone()[0]

    return maybe_get_wire


def maybe_add_pip(top, maybe_get_wire, feature):
    if feature.value != 1:
        return

    parts = feature.feature.split('.')
    assert len(parts) == 3

    sink_wire = maybe_get_wire(parts[0], parts[2])
    if sink_wire is None:
        return

    src_wire = maybe_get_wire(parts[0], parts[1])
    if src_wire is None:
        return

    top.active_pips.add((sink_wire, src_wire))

def get_iob_site(db, grid, tile, site):
    gridinfo = grid.gridinfo_at_tilename(tile)
    tile_type = db.get_tile_type(gridinfo.tile_type)

    sites = sorted(tile_type.get_instance_sites(gridinfo), key=lambda x: x.y)

    if len(sites) == 1:
        iob_site = sites[0]
    else:
        iob_site = sites[1-int(site[-1])]

    loc = grid.loc_of_tilename(tile)

    if gridinfo.tile_type.startswith('LIOB33'):
        dx = 1
    elif gridinfo.tile_type.startswith('RIOB33'):
        dx = -1
    else:
        assert False, gridinfo.tile_type

    iologic_tile = grid.tilename_at_loc((loc.grid_x+dx, loc.grid_y))
    ioi3_gridinfo = grid.gridinfo_at_loc((loc.grid_x+dx, loc.grid_y))

    ioi3_tile_type = db.get_tile_type(ioi3_gridinfo.tile_type)
    ioi3_sites = ioi3_tile_type.get_instance_sites(ioi3_gridinfo)

    ilogic_site = None
    ologic_site = None

    target_ilogic_site = iob_site.name.replace('IOB', 'ILOGIC')
    target_ologic_site = iob_site.name.replace('IOB', 'OLOGIC')

    for site in ioi3_sites:
        if site.name == target_ilogic_site:
            assert ilogic_site is None
            ilogic_site = site

        if site.name == target_ologic_site:
            assert ologic_site is None
            ologic_site = site

    assert ilogic_site is not None
    assert ologic_site is not None

    return iob_site, iologic_tile, ilogic_site, ologic_site


def get_drive(iostandard, drive):
    parts = drive.split('.')

    drive = parts[-1]
    assert drive[0] == 'I', drive

    if '_' not in drive:
        return int(drive[1:])
    else:
        assert iostandard in ['LVCMOS18', 'LVCMOS33', 'LVTTL']
        drives = sorted([int(d[1:]) for d in drive.split('_')])

        if iostandard == 'LVCMOS18':
            return min(drives)

        if drives == [12, 16]:
            if iostandard == 'LVCMOS33':
                return 12
            else:
                return 16
        elif drives == [8, 12]:
            return 8


def add_output_parameters(bel, site):
    assert 'IOSTANDARD' in bel.parameters

    if site.has_feature('SLEW.FAST'):
        bel.parameters['SLEW'] = '"FAST"'
    elif site.has_feature('SLEW.SLOW'):
        bel.parameters['SLEW'] = '"SLOW"'
    else:
        assert False

    drive = None
    for f in site.set_features:
        if 'DRIVE' in f:
            assert drive is None
            drive  = f
            break

    iostandard = bel.parameters['IOSTANDARD']
    assert iostandard[0] == '"'
    assert iostandard[-1] == '"'
    assert iostandard[1:-1] in drive

    bel.parameters['DRIVE'] = get_drive(iostandard[1:-1], drive)


def process_iob(top, iob):
    assert top.iostandard is not None

    aparts = iob[0].feature.split('.')
    iob_site, iologic_tile, ilogic_site, ologic_site = get_iob_site(top.db,
            top.grid, aparts[0], aparts[1])

    site = Site(iob, iob_site)

    INTERMDISABLE_USED = site.has_feature('INTERMDISABLE.I')
    IBUFDISABLE_USED = site.has_feature('IBUFDISABLE.I')

    top_wire = None
    ilogic_active = False
    ologic_active = False

    if site.has_feature('IN_ONLY'):
        if not site.has_feature('ZINV_D'):
            return

        ilogic_active = True

        # Options are:
        # IBUF, IBUF_IBUFDISABLE, IBUF_INTERMDISABLE
        if INTERMDISABLE_USED:
            bel = Bel('IBUF_INTERMDISABLE')

            site.add_sink(bel, 'INTERMDISABLE', 'INTERMDISABLE')

            if IBUFDISABLE_USED:
                site.add_sink(bel, 'IBUFDISABLE', 'IBUFDISABLE')
            else:
                bel.connections['IBUFDISABLE'] = 0

        elif IBUFDISABLE_USED:
            bel = Bel('IBUF_IBUFDISABLE')
            site.add_sink(bel, 'IBUFDISABLE', 'IBUFDISABLE')
        else:
            bel = Bel('IBUF')

        top_wire = top.add_top_in_port(aparts[0], iob_site.name, 'IPAD')
        bel.connections['I'] = top_wire

        # Note this looks weird, but the BEL pin is O, and the site wire is
        # called I, so it is in fact correct.
        site.add_source(bel, bel_pin='O', source='I')

        bel.parameters['IOSTANDARD'] = '"{}"'.format(top.iostandard)

        site.add_bel(bel)
    elif site.has_feature('INOUT'):
        assert site.has_feature('ZINV_D')

        ilogic_active = True
        ologic_active = True

        # Options are:
        # IOBUF or IOBUF_INTERMDISABLE
        if INTERMDISABLE_USED or IBUFDISABLE_USED:
            bel = Bel('IOBUF_INTERMDISABLE')

            if INTERMDISABLE_USED:
                site.add_sink(bel, 'INTERMDISABLE', 'INTERMDISABLE')
            else:
                bel.connections['INTERMDISABLE'] = 0

            if IBUFDISABLE_USED:
                site.add_sink(bel, 'IBUFDISABLE', 'IBUFDISABLE')
            else:
                bel.connections['IBUFDISABLE'] = 0
        else:
            bel = Bel('IOBUF')

        top_wire = top.add_top_inout_port(aparts[0], iob_site.name, 'IOPAD')
        bel.connections['IO'] = top_wire

        # Note this looks weird, but the BEL pin is O, and the site wire is
        # called I, so it is in fact correct.
        site.add_source(bel, bel_pin='O', source='I')

        site.add_sink(bel, 'T', 'T')

        # Note this looks weird, but the BEL pin is I, and the site wire is
        # called O, so it is in fact correct.
        site.add_sink(bel, bel_pin='I', sink='O')

        bel.parameters['IOSTANDARD'] = '"{}"'.format(top.iostandard)

        add_output_parameters(bel, site)

        site.add_site(bel)
    else:
        has_output = False
        for f in site.set_features:
            if 'DRIVE' in f:
                has_output = True
                break

        if not has_output:
            # Naked pull options are not supported
            assert site.has_feature('PULLTYPE.PULLDOWN')
        else:
            # TODO: Could be a OBUFT?
            bel = Bel('OBUF')
            top_wire = top.add_top_out_port(aparts[0], iob_site.name, 'OPAD')
            bel.connections['O'] = top_wire

            # Note this looks weird, but the BEL pin is I, and the site wire
            # is called O, so it is in fact correct.
            site.add_sink(bel, bel_pin='I', sink='O')

            bel.parameters['IOSTANDARD'] = '"{}"'.format(top.iostandard)

            add_output_parameters(bel, site)
            site.add_bel(bel)
            ologic_active = True

    if top_wire is not None:
        if site.has_feature('PULLTYPE.PULLDOWN'):
            bel = Bel('PULLDOWN')
            bel.connections['O'] = top_wire
            site.add_bel(bel)
        elif site.has_feature('PULLTYPE.KEEPER'):
            bel = Bel('KEEPER')
            bel.connections['O'] = top_wire
            site.add_bel(bel)
        elif site.has_feature('PULLTYPE.PULLUP'):
            bel = Bel('PULLUP')
            bel.connections['O'] = top_wire
            site.add_bel(bel)

    top.add_site(site)

    if ilogic_active:
        # TODO: Handle IDDR or ISERDES
        site = Site(iob, tile=iologic_tile, site=ilogic_site)
        site.sources['O'] = None
        site.sinks['D'] = []
        site.outputs['O'] = 'D'
        top.add_site(site)

    if ologic_active:
        # TODO: Handle ODDR or OSERDES
        site = Site(iob, tile=iologic_tile, site=ologic_site)
        site.sources['OQ'] = None
        site.sinks['D1'] = []
        site.outputs['OQ'] = 'D1'
        top.add_site(site)


def process_iobs(conn, top, tile, features):
    iobs = {
            '0': [],
            '1': [],
            }

    for f in features:
        parts = f.feature.split('.')

        if not parts[1].startswith('IOB_Y'):
            continue

        iobs[parts[1][-1]].append(f)

    for iob in iobs:
        if len(iobs[iob]) > 0:
            process_iob(top, iobs[iob])

def null_process(conn, top, tile, tiles):
    pass

def get_bufg_site(db, grid, tile, generic_site):
    y = int(generic_site[generic_site.find('Y')+1:])
    if '_TOP_' in tile:
        y += 16

    site_name = 'BUFGCTRL_X0Y{}'.format(y)

    gridinfo = grid.gridinfo_at_tilename(tile)

    tile = db.get_tile_type(gridinfo.tile_type)

    for site in tile.get_instance_sites(gridinfo):
        if site.name == site_name:
            return site

    assert False, (tile, generic_site)

BUFHCE_RE = re.compile('BUFHCE_X([0-9]+)Y([0-9]+)')

def bufhce_xy(site):
    m = BUFHCE_RE.fullmatch(site)
    assert m is not None, site

    return int(m.group(1)), int(m.group(2))

def get_bufhce_site(db, grid, tile, generic_site):
    x, y = bufhce_xy(generic_site)

    gridinfo = grid.gridinfo_at_tilename(tile)

    tile = db.get_tile_type(gridinfo.tile_type)

    for site in tile.get_instance_sites(gridinfo):
        instance_x, instance_y = bufhce_xy(site.name)

        if instance_x == x and y == (instance_y % 12):
            return site

    assert False, (tile, generic_site)

def process_bufg(conn, top, tile, features):
    bufgs = {}
    for f in features:
        parts = f.feature.split('.')

        if parts[1] != 'BUFGCTRL':
            continue

        if parts[2] not in bufgs:
            bufgs[parts[2]] = []

        bufgs[parts[2]].append(f)

    for bufg, features in bufgs.items():
        set_features = set()

        for f in features:
            if f.value == 0:
                continue

            parts = f.feature.split('.')

            set_features.add('.'.join(parts[3:]))

        if 'IN_USE' not in set_features:
            continue

        bufg_site = get_bufg_site(top.db, top.grid, tile, features[0].feature.split('.')[2])
        site = Site(
                features,
                site=bufg_site)

        bel = Bel('BUFGCTRL')
        bel.parameters['IS_IGNORE0_INVERTED'] = int(not 'IS_IGNORE0_INVERTED' in set_features)
        bel.parameters['IS_IGNORE1_INVERTED'] = int(not 'IS_IGNORE1_INVERTED' in set_features)
        bel.parameters['IS_CE0_INVERTED'] = int('ZINV_CE0' not in set_features)
        bel.parameters['IS_CE1_INVERTED'] = int('ZINV_CE1' not in set_features)
        bel.parameters['IS_S0_INVERTED'] = int('ZINV_S0' not in set_features)
        bel.parameters['IS_S1_INVERTED'] = int('ZINV_S1' not in set_features)
        bel.parameters['PRESELECT_I0'] = int('ZPRESELECT_I0' not in set_features)
        bel.parameters['PRESELECT_I1'] = int('PRESELECT_I1' in set_features)
        bel.parameters['INIT_OUT'] = int('INIT_OUT' in set_features)

        for sink in ('I0', 'I1', 'S0', 'S1', 'CE0', 'CE1', 'IGNORE0', 'IGNORE1'):
            site.add_sink(bel, sink, sink)

        site.add_source(bel,'O', 'O')

        site.add_bel(bel)

        top.add_site(site)


def process_hrow(conn, top, tile, features):
    bufhs = {}
    for f in features:
        parts = f.feature.split('.')

        if parts[1] != 'BUFHCE':
            continue

        if parts[2] not in bufhs:
            bufhs[parts[2]] = []

        bufhs[parts[2]].append(f)

    for bufh, features in bufhs.items():
        set_features = set()

        for f in features:
            if f.value == 0:
                continue

            parts = f.feature.split('.')

            set_features.add('.'.join(parts[3:]))

        if 'IN_USE' not in set_features:
            continue

        bufhce_site = get_bufhce_site(top.db, top.grid, tile,
                features[0].feature.split('.')[2])
        site = Site(features, site=bufhce_site)

        bel = Bel('BUFHCE')
        if 'CE_TYPE.ASYNC' in set_features:
            bel.parameters['CE_TYPE'] = '"ASYNC"'
        else:
            bel.parameters['CE_TYPE'] = '"SYNC"'
        bel.parameters['IS_CE_INVERTED'] = int('ZINV_CE' not in set_features)
        bel.parameters['INIT_OUT'] = int('INIT_OUT' in set_features)

        for sink in ('I', 'CE'):
            site.add_sink(bel, sink, sink)

        site.add_source(bel, 'O', 'O')

        site.add_bel(bel)

        top.add_site(site)

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

    def get_tile_type(tile_name):
        c = conn.cursor()

        c.execute("""
SELECT name FROM tile_type WHERE pkey = (
    SELECT tile_type_pkey FROM tile WHERE name = ?);""", (tile_name,))

        return c.fetchone()[0]

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

    process_tile = {
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

    top.set_iostandard(iostandards)

    for tile in tiles:
        tile_type = get_tile_type(tile)

        process_tile[tile_type](conn, top, tile, tiles[tile])

    top.make_routes(allow_orphan_sinks=args.allow_orphan_sinks)
    top.handle_post_route_cleanup()

    with open(args.verilog_file, 'w') as f:
        for l in top.output_verilog():
            print(l, file=f)

    with open(args.tcl_file, 'w') as f:
        for bel in top.get_bels():
            print("""
set cell [get_cells {cell}]
if {{ $cell == {{}} }} {{
    error "Failed to find cell!"
}}
set_property LOC [get_sites {site}] $cell""".format(
                cell=bel.get_cell(),
                site=bel.site), file=f)

            if bel.bel is not None:
                print('set_property BEL "[get_property SITE_TYPE [get_sites {site}]].{bel}" $cell'.format(
                    site=bel.site,
                    bel=bel.bel,
                    ), file=f)

        for l in top.output_nets():
            print(l, file=f)


if __name__ == "__main__":
    main()
