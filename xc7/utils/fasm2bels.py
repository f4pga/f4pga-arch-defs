""" Converts FASM out into BELs and nets.

The BELs will be Xilinx tech primatives.
The nets will be wires and the route those wires takes.

"""

import argparse
import sqlite3
import fasm
from lib.connection_database import get_wire_pkey
import prjxray.db
import functools

class Net(object):
    def __init__(self, source):
        self.source = source
        self.sinks = {}

    def add_sink(self, sink, route):
        self.sinks[sink] = route

class Bel(object):
    def __init__(self, module):
        self.module = module
        self.connections = {}
        self.parameters = {}
        self.prefix = ''

    def set_prefix(self, prefix):
        self.prefix = prefix

def get_clb_site(db, grid, tile, site):
    gridinfo = grid.gridinfo_at_tilename(tile)
    tile_type = db.get_tile_type(gridinfo.tile_type)

    sites = sorted(tile_type.get_instance_sites(gridinfo))

    return sites[int(site[-1])]

class Module(object):
    def __init__(self, db, grid, conn):
        self.db = db
        self.grid = grid
        self.conn = conn
        self.bels = []
        self.nets = {}

        self.unrouted_sinks = set()
        self.unrouted_sources = set()
        self.active_pips = set()

    def add_site(self, tile, site, bels, outputs, sinks, sources, internal_sources):
        prefix = '{}_{}'.format(tile, site)

        # Sanity check BEL connections
        for bel in bels:
            for wire in bel.values():
                assert wire in sinks or wire in sources or wire in internal_sources

            bel.set_prefix(prefix)
            bel.set_site(site)

        self.bels.extend(bels)

        assert len(internal_sources ^ sinks) == 0
        assert len(internal_sources ^ sources) == 0

        for wire in sinks:
            self.unrouted_sinks(get_wire_pkey(self.conn, tile, wire))

        for wire in sources:
            self.unrouted_sources(get_wire_pkey(self.conn, tile, wire))


def get_lut_init(features, tile_name, slice_name, lut):
    target_feature = '{}.{}.{}LUT.INIT'.format(tile_name, slice_name, lut)

    init = 0

    for f in features:
        if f.feature == target_feature:
            for canon_f in fasm.canonical_features(f):
                if canon_f.start is None:
                    init |= 1
                else:
                    init |= (1 << canon_f.start)

    return init

def create_lut(lut, internal_sources):
    bel = Bel('LUT6_2')

    for idx in range(6):
        bel.connections['I{}'.format(idx)] = '{}{}'.format(lut, idx+1)
        bel.connections['O6'.format(idx)] = lut + 'O6'
        bel.connections['O5'.format(idx)] = lut + 'O5'
        internal_sources.add(lut + 'O6')
        internal_sources.add(lut + 'O5')

    return bel

def decode_dram(features, lut_ram, di):
    lut_modes = {}
    if 'WA8USED' in features:
        assert 'WA7USED' in features
        assert lut_ram['A']
        assert lut_ram['B']
        assert lut_ram['C']
        assert lut_ram['D']

        lut_modes['A'] = 'RAM256X1S'
        lut_modes['B'] = 'RAM256X1S'
        lut_modes['C'] = 'RAM256X1S'
        lut_modes['D'] = 'RAM256X1S'
        return lut_modes

    if 'WA7USED' in features:
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

            if '{}LUT.SMALL'.format(lut) in features:
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
                if '{}LUT.SMALL'.format(lut) in features:
                    lut_modes[lut] = 'RAM32X1D'
                    lut_modes[minus_one] = 'RAM32X1D'
                else:
                    lut_modes[lut] = 'RAM64X1D'
                    lut_modes[minus_one] = 'RAM64X1D'
            else:
                if '{}LUT.SMALL'.format(lut) in features:
                    lut_modes[lut] = 'RAM32X2S'
                else:
                    lut_modes[lut] = 'RAM64X1S'

    for lut in remaining:
        lut_modes[lut] = 'LUT'

    return lut_modes

def ff_bel(features, lut, ff5):
    ffsync = 'FFSYNC' in features
    latch = ('LATCH' in features) and not ff5
    zrst = '{}{}FF.ZRST'.format(lut, '5' if ff5 else '') in features
    zini = '{}{}FF.ZINI'.format(lut, '5' if ff5 else '') in features
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

    bels = []
    sinks = set()
    sources = set()
    internal_sources = set()

    aparts = s[0].feature.split('.')
    mlut = aparts[1].startswith('SLICEM')

    features = set()
    for f in s:
        if f.value == 0:
            continue

        parts = f.feature.split('.')
        assert parts[0] == aparts[0]
        assert parts[1] == aparts[1]
        features.add('.'.join(parts[2:]))

    if 'CEUSEDMUX' in features:
        sinks.add('CE')
        CE = 'CE'
    else:
        CE = 1

    if 'SRUSEDMUX' in features:
        sinks.add('SR')
        SR = 'SR'
    else:
        SR = 0

    IS_C_INVERTED = int('CLKINV' in features)

    sinks.add('CLK')
    if mlut:
        if 'WEMUX.CE' not in features:
            sinks.add('WE')
            WE = 'WE'
        else:
            sinks.add('CE')
            WE = 'CE'

    if 'PRECYINIT.CIN' in features:
        sinks.add('CIN')

    for row in 'ABCD':
        sinks.add('{}X'.format(row))
        for lut in range(6):
            sinks.add('{}{}'.format(row, lut+1))

        if mlut:
            sinks.add('{}I'.format(row))

    if 'DLUT.RAM' in features:
        # Must be a SLICEM to have RAM set.
        assert mlut
    else:
        for row in 'ABC':
            assert '{}LUT.RAM' not in features

    # SRL not currently supported
    for row in 'ABCD':
        assert '{}LUT.SRL' not in features

    muxes = set(('F7AMUX', 'F7BMUX', 'F8MUX'))

    luts = {}
    # Add BELs for LUTs/RAMs
    if 'DLUT.RAM' not in features:
        for lut in 'ABCD':
            luts[lut] = create_lut(lut, internal_sources)
            luts[lut].parameters['INIT'] = get_lut_init(s, parts[0], aparts[0], lut)
            bels.append(luts[lut])
    else:
        # DRAM is active.  Determine what BELs are in use.
        lut_ram = {}
        for lut in 'ABCD':
            lut_ram[lut] = '{}LUT.RAM'.format(lut) in features

        di = {}
        for lut in 'ABC':
            di[lut] = 'DI1MUX.{}I'.format(lut) in features

        lut_modes = decode_dram(features, lut_ram, di)

        if lut_modes['D'] == 'RAM256X1S':
            ram256 = Bel('RAM256X1S')
            ram256.connections['WE'] = WE
            ram256.connections['WCLK'] = "CLK"
            ram256.connections['D'] = "DI"

            for idx in range(6):
                ram256.connections['A[{}]'.format(idx)] = "D{}".format(idx+1)

            ram256.connections['A[6]'] = "CX"
            ram256.connections['A[7]'] = "BX"
            ram256.connections['O'] = 'F8MUX_O'

            ram256.parameters['INIT'] = (
                    get_lut_init(s, parts[0], aparts[0], 'D') |
                    (get_lut_init(s, parts[0], aparts[0], 'C') << 64) |
                    (get_lut_init(s, parts[0], aparts[0], 'B') << 128) |
                    (get_lut_init(s, parts[0], aparts[0], 'A') << 192)
                    )

            bels.append(ram256)
            internal_sources.add(ram256.connections['O'])

            muxes = set()

            del lut_modes['A']
            del lut_modes['B']
            del lut_modes['C']
            del lut_modes['D']
        elif lut_modes['D'] == 'RAM128X1S':
            ram128 = Bel('RAM128X1S')
            ram128.connections['WE'] = WE
            ram128.connections['WCLK'] = "CLK"
            ram128.connections['D'] = "DI"

            for idx in range(6):
                ram128.connections['A{}'.format(idx)] = "D{}".format(idx+1)

            ram128.connections['A6'] = "CX"
            ram128.connections['O'] = 'F7BMUX_O'

            ram128.parameters['INIT'] = (
                    get_lut_init(s, parts[0], aparts[0], 'D') |
                    (get_lut_init(s, parts[0], aparts[0], 'C') << 64))

            bels.append(ram128)
            internal_sources.add(ram128.connections['O'])

            muxes.remove('F7BMUX')

            del lut_modes['C']
            del lut_modes['D']

            if lut_modes['B'] == 'RAM128X1S':
                ram128 = Bel('RAM128X1S')
                ram128.connections['WE'] = WE
                ram128.connections['WCLK'] = "CLK"
                ram128.connections['D'] = "BI"

                for idx in range(6):
                    ram128.connections['A{}'.format(idx)] = "B{}".format(idx+1)

                ram128.connections['A6'] = "AX"
                ram128.connections['O'] = 'F7AMUX_O'

                ram128.parameters['INIT'] = (
                        get_lut_init(s, parts[0], aparts[0], 'B') |
                        (get_lut_init(s, parts[0], aparts[0], 'A') << 64))

                bels.append(ram128)
                internal_sources.add(ram128.connections['O'])

                muxes.remove('F7AMUX')

                del lut_modes['A']
                del lut_modes['B']

        elif lut_modes['D'] == 'RAM128X1D':
            ram128 = Bel('RAM128X1D')

            ram128.connections['WE'] = WE
            ram128.connections['WCLK'] = "CLK"
            ram128.connections['D'] = "DI"

            for idx in range(6):
                ram128.connections['A[{}]'.format(idx)] = "D{}".format(idx+1)
                ram128.connections['DPRA[{}]'.format(idx)] = "C{}".format(idx+1)

            ram128.connections['A[6]'] = "CX"
            ram128.connections['DPRA[6]'] = "AX"
            ram128.connections['SPO'] = 'F7AMUX_O'
            ram128.connections['DPO'] = 'F7BMUX_O'

            ram128.parameters['INIT'] = (
                    get_lut_init(s, parts[0], aparts[0], 'D') |
                    (get_lut_init(s, parts[0], aparts[0], 'C') << 64))

            other_init = (
                    get_lut_init(s, parts[0], aparts[0], 'B') |
                    (get_lut_init(s, parts[0], aparts[0], 'A') << 64))

            assert ram128.parameters['INIT'] == other_init

            bels.append(ram128)
            internal_sources.add(ram128.connections['SPO'])
            internal_sources.add(ram128.connections['DPO'])

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

                ram64.connections['WE'] = WE
                ram64.connections['WCLK'] = "CLK"
                ram64.connections['D'] = lut + "I"

                for idx in range(6):
                    ram64.connections['A{}'.format(idx)] = "{}{}".format(lut, idx+1)
                    ram64.connections['DPRA{}'.format(idx)] = "{}{}".format(minus_one, idx+1)

                ram64.connections['SPO'] = lut + "O6"
                ram64.connections['DPO'] = minus_one + "O6"

                ram64.parameters['INIT'] = get_lut_init(s, parts[0], aparts[0], lut)
                other_init = get_lut_init(s, parts[0], aparts[0], minus_one)

                assert ram64.parameters['INIT'] == other_init

                bels.append(ram64)
                internal_sources.add(ram64.connections['SPO'])
                internal_sources.add(ram64.connections['DPO'])

                del lut_modes[lut]
                del lut_modes[minus_one]
            elif lut_modes[lut] == 'RAM32X1D':
                ram32 = Bel('RAM32X1D')

                ram32.connections['WE'] = WE
                ram32.connections['WCLK'] = "CLK"
                ram32.connections['D'] = lut + "I"

                for idx in range(5):
                    ram64.connections['A{}'.format(idx)] = "{}{}".format(lut, idx+1)
                    ram64.connections['DPRA{}'.format(idx)] = "{}{}".format(minus_one, idx+1)

                ram32.connections['SPO'] = lut + "O6"
                ram32.connections['DPO'] = minus_one + "O6"

                ram32.parameters['INIT'] = get_lut_init(s, parts[0], aparts[0], lut)
                other_init = get_lut_init(s, parts[0], aparts[0], minus_one)

                bels.append(ram32)
                internal_sources.add(ram32.connections['SPO'])
                internal_sources.add(ram32.connections['DPO'])

                del lut_modes[lut]
                del lut_modes[minus_one]

        for lut in 'ABCD':
            if lut not in lut_modes:
                continue

            if lut_modes[lut] == 'LUT':
                luts[lut] = create_lut(lut, internal_sources)
                luts[lut].parameters['INIT'] = get_lut_init(s, parts[0], aparts[0], lut)
                bels.append(luts[lut])
            elif lut_modes[lut] == 'RAM64X1S':
                ram64 = Bel('RAM64X1S')

                ram64.connections['WE'] = WE
                ram64.connections['WCLK'] = "CLK"
                ram64.connections['D'] = lut + "I"

                for idx in range(6):
                    ram64.connections['A{}'.format(idx)] = "{}{}".format(lut, idx+1)

                ram64.connections['O'] = lut + "O6"

                ram64.parameters['INIT'] = get_lut_init(s, parts[0], aparts[0], lut)
                other_init = get_lut_init(s, parts[0], aparts[0], minus_one)

                assert ram64.parameters['INIT'] == other_init

                bels.append(ram64)
                internal_sources.add(ram64.connections['O'])
            elif lut_modes[lut] == 'RAM32X2S':
                ram32 = Bel('RAM32X1S')

                ram32.connections['WE'] = WE
                ram32.connections['WCLK'] = "CLK"
                ram32.connections['D'] = lut + "I"

                for idx in range(5):
                    ram64.connections['A{}'.format(idx)] = "{}{}".format(lut, idx+1)

                ram32.connections['O'] = lut + "O6"

                ram32.parameters['INIT'] = get_lut_init(s, parts[0], aparts[0], lut)

                bels.append(ram32)
                internal_sources.add(ram32.connections['O'])
            else:
                assert False, lut_modes[lut]

    for mux in sorted(muxes):
        if mux == 'F7AMUX':
            f7amux = Bel('MUXF7')

            assert 'AO6' in internal_sources
            assert 'BO6' in internal_sources
            f7amux.connections['I0'] = 'BO6'
            f7amux.connections['I1'] = 'AO6'
            f7amux.connections['S'] = 'AX'
            f7amux.connections['O'] = 'F7AMUX_O'

            bels.append(f7amux)
            internal_sources.add(f7amux.connections['O'])
        elif mux == 'F7BMUX':
            f7bmux = Bel('MUXF7')

            assert 'CO6' in internal_sources
            assert 'DO6' in internal_sources
            f7bmux.connections['I0'] = 'DO6'
            f7bmux.connections['I1'] = 'CO6'
            f7bmux.connections['S'] = 'CX'
            f7bmux.connections['O'] = 'F7BMUX_O'

            bels.append(f7bmux)
            internal_sources.add(f7bmux.connections['O'])
        elif mux == 'F8MUX':
            f8mux = Bel('MUXF8')

            assert 'F7AMUX_O' in internal_sources
            assert 'F7BMUX_O' in internal_sources
            f8mux.connections['I0'] = 'F7BMUX_O'
            f8mux.connections['I1'] = 'F7AMUX_I0'
            f8mux.connections['S'] = 'BX'
            f8mux.connections['O'] = 'F8MUX_O'

            bels.append(f8mux)
            internal_sources.add(f8mux.connections['O'])
        else:
            assert False, mux

    can_have_carry4 = True
    for lut in 'ABCD':
        if lut + 'O6' not in internal_sources:
            can_have_carry4 = False
            break

    if can_have_carry4:
        bel = Bel('CARRY4')

        for idx in range(4):
            lut = chr(ord('A') + idx)
            if 'CARRY4.{}CY0'.format(lut) in features:
                source = lut + 'O5'
                assert source in internal_sources
                bel.connections['DI[{}]'.format(idx)] = source
            else:
                bel.connections['DI[{}]'.format(idx)] = lut + 'X'

            source = lut + 'O6'
            assert source in internal_sources
            bel.connections['S[{}]'.format(idx)] = source

            bel.connections['O[{}]'.format(idx)] = lut + '_XOR'
            internal_sources.add(bel.connections['O[{}]'.format(idx)])

            if idx == 3:
                bel.connections['CO[{}]'.format(idx)] = 'COUT'
            else:
                bel.connections['CO[{}]'.format(idx)] = lut + '_CY'
                internal_sources.add(bel.connections['CO[{}]'.format(idx)])

        if 'PRECYINIT.AX' in features:
            bel.connections['CYINIT'] = 'AX'
        elif 'PRECYINIT.C0' in features:
            bel.connections['CYINIT'] = 0
        elif 'PRECYINIT.C1' in features:
            bel.connections['CYINIT'] = 1
        elif 'PRECYINIT.CIN' in features:
            bel.connections['CYINIT'] = 'CIN'
        else:
            assert False

        bels.append(bel)

    for lut in 'ABCD':
        if '{}OUTMUX.{}5Q'.format(lut, lut) in features:
            # 5FF in use, emit
            name, clk, ce, sr, init = ff_bel(features, lut, ff5=True)
            ff5 = Bel(name)

            if '{}5FFMUX.IN_A'.format(lut) in features:
                source = lut + 'O5'
                assert source in internal_sources
            elif '{}5FFMUX.IN_B'.format(lut) in features:
                source = lut + 'X'

            ff5.connections['D'] = source
            ff5.connections[clk] = "CLK"
            ff5.connections[ce] = CE
            ff5.connections[sr] = SR
            ff5.connections['Q'] = lut + '5Q'
            ff5.parameters['INIT'] = init
            ff5.parameters['IS_C_INVERTED'] = IS_C_INVERTED
            internal_sources.add(ff5.connections['Q'])

            bels.append(ff5)

    for lut in 'ABCD':
        name, clk, ce, sr, init = ff_bel(features, lut, ff5=False)
        ff = Bel(name)

        if '{}FFMUX.{}X'.format(lut, lut) in features:
            source = lut + 'X'
        elif lut == 'A' and 'AFFMUX.F7' in features:
            source = 'F7AMUX_O'
            assert source in internal_sources
        elif lut == 'C' and 'CFFMUX.F7' in features:
            source = 'F7BMUX_O'
            assert source in internal_sources
        elif lut == 'B' and 'BFFMUX.F8' in features:
            source = 'F8MUX_O'
            assert source in internal_sources
        elif '{}FFMUX.O5'.format(lut) in features:
            source = lut + 'O5'
            assert source in internal_sources
        elif '{}FFMUX.O6'.format(lut) in features:
            source = lut + 'O6'
            assert source in internal_sources
        elif '{}FFMUX.CY'.format(lut) in features:
            assert can_have_carry4
            if lut != 'D':
                source = lut + '_CY'
                assert source in internal_sources
            else:
                source = 'COUT'
                sources.add(source)
        elif '{}FFMUX.XOR'.format(lut) in features:
            assert can_have_carry4
            source = lut + '_XOR'
            assert source in internal_sources
        else:
            assert False

        ff.connections['D'] = source
        ff.connections['Q'] = lut + 'Q'
        sources.add(ff.connections['Q'])
        ff.connections[clk] = "CLK"
        ff.connections[ce] = CE
        ff.connections[sr] = SR
        ff.parameters['INIT'] = init
        ff.parameters['IS_C_INVERTED'] = IS_C_INVERTED

        bels.append(ff)

    outputs = {}
    for lut in 'ABCD':
        if lut + 'O6' in internal_sources:
            outputs[lut] = lut + 'O6'
            sources.add(lut)

    for lut in 'ABCD':
        if '{}OUTMUX.{}5Q'.format(lut, lut) in features:
            source = lut + '5Q'
            assert source in internal_sources
        elif lut == 'A' and 'AFFMUX.F7' in features:
            source = 'F7AMUX_O'
            assert source in internal_sources
        elif lut == 'C' and 'CFFMUX.F7' in features:
            source = 'F7BMUX_O'
            assert source in internal_sources
        elif lut == 'B' and 'BFFMUX.F8' in features:
            source = 'F8MUX_O'
            assert source in internal_sources
        elif '{}OUTMUX.O5'.format(lut) in features:
            source = lut + 'O5'
            assert source in internal_sources
        elif '{}OUTMUX.O6'.format(lut) in features:
            source = lut + 'O6'
            assert source in internal_sources
        elif '{}OUTMUX.CY'.format(lut) in features:
            assert can_have_carry4
            if lut != 'D':
                source = lut + '_CY'
                assert source in internal_sources
            else:
                source = 'COUT'
        elif '{}OUTMUX.XOR'.format(lut) in features:
            assert can_have_carry4
            source = lut + '_XOR'
            assert source in internal_sources
        else:
            assert False

        outputs[lut + 'MUX'] = source
        sources.add(lut + 'MUX')

    top.add_site(aparts[0], get_clb_site(top.db, top.grid, aparts[0], aparts[1]), bels, outputs, sinks, sources, internal_sources)


def process_clb(conn, top, tile_name, features):
    c = conn.cursor()
    c.execute("SELECT pkey, tile_type_pkey FROM tile WHERE name = ?;", (tile_name,))
    result = c.fetchone()
    assert result is not None, tile_name

    tile_pkey, tile_type_pkey = result
    slices = {
            '0': [],
            '1': [],
            }

    for f in features:
        parts = f.feature.split('.')

        assert parts[1].startswith('SLICE')

        slices[parts[1][-1]].append(f)

    for s, features in slices:
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

    sink_wire = maybe_get_wire(parts[0], parts[1])
    if sink_wire is None:
        return

    src_wire = maybe_get_wire(parts[0], parts[2])
    if src_wire is None:
        return

    top.active_pips.add((src_wire, sink_wire))


def process_int(conn, top, tile, tiles):
    pass

def process_iob(conn, top, tile, tiles):
    pass

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--connection_database', required=True)
    parser.add_argument('--db_root', required=True)
    parser.add_argument('fasm_file')

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

    for fasm_line in fasm.parse_fasm_filename(args.fasm_file):
        if not fasm_line.set_feature:
            continue

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
            'INT_L': process_int,
            'INT_R': process_int,
            'LIOB33': process_iob,
            'RIOB33': process_iob,
            }

    for tile in tiles:
        tile_type = get_tile_type(tile)

        process_tile[tile_type](conn, top, tile, tiles[tile])



if __name__ == "__main__":
    main()
