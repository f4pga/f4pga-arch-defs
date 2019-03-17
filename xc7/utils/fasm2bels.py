""" Converts FASM out into BELs and nets.

The BELs will be Xilinx tech primatives.
The nets will be wires and the route those wires takes.

"""

import argparse
import sqlite3
import fasm
import re
from lib.connection_database import get_wire_pkey
import prjxray.db
import functools
from prjxray_make_routes import make_routes

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
        self.prefix = None
        self.site = None

    def set_prefix(self, prefix):
        self.prefix = prefix

    def set_site(self, site):
        self.site = site

    def _prefix_things(self, s):
        if self.prefix is not None:
            return '{}_{}'.format(self.prefix, s)
        else:
            return s

    def output_verilog(self, top, indent='  '):
        connections = {}
        buses = {}

        for wire, connection in self.connections.items():
            if top.is_top_level(connection):
                connection_wire = connection
            else:
                connection_wire = self._prefix_things(connection)

            if '[' in wire:
                bus_name, address = wire.split('[')
                assert address[-1] == ']', address

                if bus_name not in buses:
                    buses[bus_name] = {}

                buses[bus_name][int(address[:-1])] = connection_wire
            else:
                connections[wire] = '{indent}{indent}.{wire}({connection})'.format(indent=indent, wire=wire, connection=connection_wire)

        for bus_name, bus in buses.items():
            bus_wires = [0 for _ in range(max(bus.keys())+1)]

            for idx, _ in enumerate(bus_wires):
                assert idx in bus
                bus_wires[idx] = bus[idx]

            connections[bus_name] = '{indent}{indent}.{bus_name}({connection})'.format(
                indent=indent,
                bus_name=bus_name,
                connection='{{{}}}'.format(', '.join(bus_wires)))

        yield ''

        if self.site is not None:
            yield '{indent}(* KEEP, DONT_TOUCH, LOC = "{site}" *)'.format(
                indent=indent,
                site=self.site)

        yield '{indent}{site} #('.format(indent=indent, site=self.module)

        parameters = []
        for param, value in sorted(self.parameters.items(), key=lambda x: x[0]):
            parameters.append('{indent}{indent}.{param}({value})'.format(indent=indent, param=param, value=value))

        if parameters:
            yield ',\n'.join(parameters)

        yield '{indent}) {name} ('.format(indent=indent, name=self._prefix_things(self.module))

        if connections:
            yield ',\n'.join(connections[port] for port in sorted(connections))

        yield '{indent});'.format(indent=indent)

def get_clb_site(db, grid, tile, site):
    gridinfo = grid.gridinfo_at_tilename(tile)
    tile_type = db.get_tile_type(gridinfo.tile_type)

    sites = sorted(tile_type.get_instance_sites(gridinfo), key=lambda x: x.x)

    return sites[int(site[-1])]

@functools.lru_cache(maxsize=None)
def make_site_pin_map(site_pins):
    site_pin_map = {}

    for site_pin in site_pins:
        site_pin_map[site_pin.name] = site_pin.wire

    return site_pin_map

class Module(object):
    def __init__(self, db, grid, conn):
        self.iostandard = None
        self.db = db
        self.grid = grid
        self.conn = conn
        self.bels = []

        # Map of wire_pkey to Verilog wire.
        self.wire_pkey_to_wire = {}

        # wire_pkey of sinks that are not connected to their routing.
        self.unrouted_sinks = set()

        # wire_pkey of sources that are not connected to their routing.
        self.unrouted_sources = set()

        # Known active pips, tuples of sink and source wire_pkey's.
        # The sink wire_pkey is a net with the source wire_pkey.
        self.active_pips = set()

        self.root_in = set()
        self.root_out = set()
        self.root_inout = set()

        self.wires = set()
        self.wire_assigns = {}

    def set_iostandard(self, iostandards):
        possible_iostandards = set(iostandards[0])

        for l in iostandards:
            possible_iostandards &= set(l)

        if len(possible_iostandards) != 1:
            raise RuntimeError('Ambigous IOSTANDARD, must specify possibilities: {}'.format(possible_iostandards))

        self.iostandard = possible_iostandards.pop()

    def add_top_in_port(self, tile, site, name):
        port = '{}_{}_{}'.format(tile, site, name)
        self.root_in.add(port)
        return port

    def add_top_out_port(self, tile, site, name):
        port = '{}_{}_{}'.format(tile, site, name)
        self.root_out.add(port)
        return port

    def add_top_inout_port(self, tile, site, name):
        port = '{}_{}_{}'.format(tile, site, name)
        self.root_inout.add(port)
        return port

    def is_top_level(self, wire):
        return wire in self.root_in or wire in self.root_out or wire in self.root_inout

    def add_site(self, tile, site, bels, outputs, sinks, sources, internal_sources):
        prefix = '{}_{}'.format(tile, site.name)

        site_pin_map = make_site_pin_map(frozenset(site.site_pins))

        # Sanity check BEL connections
        for bel in bels:
            bel.set_prefix(prefix)
            bel.set_site(site.name)

            for wire in bel.connections.values():
                if wire == 0 or wire == 1:
                    continue

                assert wire in sinks or \
                       wire in sources or \
                       wire in internal_sources or \
                       self.is_top_level(wire), wire

        for wire in internal_sources:
            prefix_wire = prefix + '_' + wire
            self.wires.add(prefix_wire)

        for wire in sinks:
            if wire is self.is_top_level(wire):
                continue

            prefix_wire = prefix + '_' + wire
            self.wires.add(prefix_wire)
            wire_pkey = get_wire_pkey(self.conn, tile, site_pin_map[wire])
            self.wire_pkey_to_wire[wire_pkey] = prefix_wire
            self.unrouted_sinks.add(wire_pkey)

        for wire in sources:
            if wire is self.is_top_level(wire):
                continue

            prefix_wire = prefix + '_' + wire
            self.wires.add(prefix_wire)
            wire_pkey = get_wire_pkey(self.conn, tile, site_pin_map[wire])
            self.wire_pkey_to_wire[wire_pkey] = prefix_wire
            self.unrouted_sources.add(wire_pkey)

        self.bels.extend(bels)

        for source_wire, sink_wire in outputs.items():
            self.wires.add(prefix + '_' + source_wire)
            self.wire_assigns[prefix + '_' + source_wire] = prefix + '_' + sink_wire

        assert len(internal_sources & sinks) == 0, (internal_sources & sinks)
        assert len(internal_sources & sources) == 0, (internal_sources & sources)


    def output_verilog(self):
        root_module_args = []
        for in_wire in sorted(self.root_in):
            root_module_args.append('  input ' + in_wire)
        for out_wire in sorted(self.root_out):
            root_module_args.append('  output ' + out_wire)
        for inout_wire in sorted(self.root_inout):
            root_module_args.append('  inout ' + inout_wire)

        yield 'module top('

        yield ',\n'.join(root_module_args)

        yield '  )'

        for wire in sorted(self.wires):
            yield '  wire {};'.format(wire)

        for bel in self.bels:
            print('')
            for l in bel.output_verilog(self, indent='  '):
                yield l

        for lhs, rhs in self.wire_assigns.items():
            yield '  assign {} = {};'.format(lhs, rhs)

        yield 'endmodule'


    def make_routes(self):
        for sink_wire, src_wire in make_routes(self.db, self.conn, self.wire_pkey_to_wire, self.unrouted_sinks, self.unrouted_sources, self.active_pips):
            self.wire_assigns[sink_wire] = src_wire


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
        CE = 'CE'
    else:
        CE = 1

    if 'SRUSEDMUX' in features:
        SR = 'SR'
    else:
        SR = 0

    IS_C_INVERTED = int('CLKINV' in features)

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
            luts[lut].parameters['INIT'] = get_lut_init(s, aparts[0], aparts[1], lut)
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
            sinks.add('CLK')
            ram256.connections['D'] = "DI"

            for idx in range(6):
                ram256.connections['A[{}]'.format(idx)] = "D{}".format(idx+1)

            ram256.connections['A[6]'] = "CX"
            ram256.connections['A[7]'] = "BX"
            ram256.connections['O'] = 'F8MUX_O'

            ram256.parameters['INIT'] = (
                    get_lut_init(s, aparts[0], aparts[1], 'D') |
                    (get_lut_init(s, aparts[0], aparts[1], 'C') << 64) |
                    (get_lut_init(s, aparts[0], aparts[1], 'B') << 128) |
                    (get_lut_init(s, aparts[0], aparts[1], 'A') << 192)
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
            sinks.add('CLK')
            ram128.connections['D'] = "DI"

            for idx in range(6):
                ram128.connections['A{}'.format(idx)] = "D{}".format(idx+1)

            ram128.connections['A6'] = "CX"
            ram128.connections['O'] = 'F7BMUX_O'

            ram128.parameters['INIT'] = (
                    get_lut_init(s, aparts[0], aparts[1], 'D') |
                    (get_lut_init(s, aparts[0], aparts[1], 'C') << 64))

            bels.append(ram128)
            internal_sources.add(ram128.connections['O'])

            muxes.remove('F7BMUX')

            del lut_modes['C']
            del lut_modes['D']

            if lut_modes['B'] == 'RAM128X1S':
                ram128 = Bel('RAM128X1S')
                ram128.connections['WE'] = WE
                ram128.connections['WCLK'] = "CLK"
                sinks.add('CLK')
                ram128.connections['D'] = "BI"

                for idx in range(6):
                    ram128.connections['A{}'.format(idx)] = "B{}".format(idx+1)

                ram128.connections['A6'] = "AX"
                ram128.connections['O'] = 'F7AMUX_O'

                ram128.parameters['INIT'] = (
                        get_lut_init(s, aparts[0], aparts[1], 'B') |
                        (get_lut_init(s, aparts[0], aparts[1], 'A') << 64))

                bels.append(ram128)
                internal_sources.add(ram128.connections['O'])

                muxes.remove('F7AMUX')

                del lut_modes['A']
                del lut_modes['B']

        elif lut_modes['D'] == 'RAM128X1D':
            ram128 = Bel('RAM128X1D')

            ram128.connections['WE'] = WE
            ram128.connections['WCLK'] = "CLK"
            sinks.add('CLK')
            ram128.connections['D'] = "DI"

            for idx in range(6):
                ram128.connections['A[{}]'.format(idx)] = "D{}".format(idx+1)
                ram128.connections['DPRA[{}]'.format(idx)] = "C{}".format(idx+1)

            ram128.connections['A[6]'] = "CX"
            ram128.connections['DPRA[6]'] = "AX"
            ram128.connections['SPO'] = 'F7AMUX_O'
            ram128.connections['DPO'] = 'F7BMUX_O'

            ram128.parameters['INIT'] = (
                    get_lut_init(s, aparts[0], aparts[1], 'D') |
                    (get_lut_init(s, aparts[0], aparts[1], 'C') << 64))

            other_init = (
                    get_lut_init(s, aparts[0], aparts[1], 'B') |
                    (get_lut_init(s, aparts[0], aparts[1], 'A') << 64))

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
                sinks.add('CLK')
                ram64.connections['D'] = lut + "I"

                for idx in range(6):
                    ram64.connections['A{}'.format(idx)] = "{}{}".format(lut, idx+1)
                    ram64.connections['DPRA{}'.format(idx)] = "{}{}".format(minus_one, idx+1)

                ram64.connections['SPO'] = lut + "O6"
                ram64.connections['DPO'] = minus_one + "O6"

                ram64.parameters['INIT'] = get_lut_init(s, aparts[0], aparts[1], lut)
                other_init = get_lut_init(s, aparts[0], aparts[1], minus_one)

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
                sinks.add('CLK')
                ram32.connections['D'] = lut + "I"

                for idx in range(5):
                    ram64.connections['A{}'.format(idx)] = "{}{}".format(lut, idx+1)
                    ram64.connections['DPRA{}'.format(idx)] = "{}{}".format(minus_one, idx+1)

                ram32.connections['SPO'] = lut + "O6"
                ram32.connections['DPO'] = minus_one + "O6"

                ram32.parameters['INIT'] = get_lut_init(s, aparts[0], aparts[1], lut)
                other_init = get_lut_init(s, aparts[0], aparts[1], minus_one)

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
                luts[lut].parameters['INIT'] = get_lut_init(s, aparts[0], aparts[1], lut)
                bels.append(luts[lut])
            elif lut_modes[lut] == 'RAM64X1S':
                ram64 = Bel('RAM64X1S')

                ram64.connections['WE'] = WE
                ram64.connections['WCLK'] = "CLK"
                sinks.add('CLK')
                ram64.connections['D'] = lut + "I"

                for idx in range(6):
                    ram64.connections['A{}'.format(idx)] = "{}{}".format(lut, idx+1)

                ram64.connections['O'] = lut + "O6"

                ram64.parameters['INIT'] = get_lut_init(s, parts[0], aparts[1], lut)
                other_init = get_lut_init(s, aparts[0], aparts[1], minus_one)

                assert ram64.parameters['INIT'] == other_init

                bels.append(ram64)
                internal_sources.add(ram64.connections['O'])
            elif lut_modes[lut] == 'RAM32X2S':
                ram32 = Bel('RAM32X1S')

                ram32.connections['WE'] = WE
                ram32.connections['WCLK'] = "CLK"
                sinks.add('CLK')
                ram32.connections['D'] = lut + "I"

                for idx in range(5):
                    ram64.connections['A{}'.format(idx)] = "{}{}".format(lut, idx+1)

                ram32.connections['O'] = lut + "O6"

                ram32.parameters['INIT'] = get_lut_init(s, aparts[0], aparts[1], lut)

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
            f8mux.connections['I1'] = 'F7AMUX_O'
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
                sources.add('COUT')
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
            bel.connections['CYINIT'] = 0

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
            sinks.add('CLK')
            ff5.connections[ce] = CE
            ff5.connections[sr] = SR

            if CE == 'CE':
                sinks.add('CE')

            if SR == 'SR':
                sinks.add('SR')

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
            continue

        ff.connections['D'] = source
        ff.connections['Q'] = lut + 'Q'
        sources.add(ff.connections['Q'])
        ff.connections[clk] = "CLK"
        sinks.add('CLK')
        ff.connections[ce] = CE
        ff.connections[sr] = SR

        if CE == 'CE':
            sinks.add('CE')

        if SR == 'SR':
            sinks.add('SR')

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
            continue

        outputs[lut + 'MUX'] = source
        sources.add(lut + 'MUX')

    top.add_site(aparts[0], get_clb_site(top.db, top.grid, aparts[0], aparts[1]), bels, outputs, sinks, sources, internal_sources)


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


def add_output_parameters(bel, features):
    assert 'IOSTANDARD' in bel.parameters

    if 'SLEW.FAST' in features:
        bel.parameters['SLEW'] = 'FAST'
    elif 'SLEW.SLOW' in features:
        bel.parameters['SLEW'] = 'SLOW'
    else:
        assert False

    drive = None
    for f in features:
        if 'DRIVE' in f:
            assert drive is None
            drive  = f
            break

    assert bel.parameters['IOSTANDARD'] in drive

    bel.parameters['DRIVE'] = get_drive(bel.parameters['IOSTANDARD'], drive)


def process_iob(top, iob):
    assert top.iostandard is not None

    bels = []
    sinks = set()
    sources = set()
    internal_sources = set()
    outputs = {}

    aparts = iob[0].feature.split('.')

    features = set()
    for f in iob:
        if f.value == 0:
            continue

        parts = f.feature.split('.')
        assert parts[0] == aparts[0]
        assert parts[1] == aparts[1]
        features.add('.'.join(parts[2:]))

    site, iologic_tile, ilogic_site, ologic_site = get_iob_site(top.db, top.grid, aparts[0], aparts[1])

    INTERMDISABLE_USED = 'INTERMDISABLE.I' in features
    IBUFDISABLE_USED = 'IBUFDISABLE.I' in features

    top_wire = None
    ilogic_active = False
    ologic_active = False

    if 'IN_ONLY' in features:
        if 'ZINV_D' not in features:
            return

        ilogic_active = True

        # Options are:
        # IBUF, IBUF_IBUFDISABLE, IBUF_INTERMDISABLE
        if INTERMDISABLE_USED:
            bel = Bel('IBUF_INTERMDISABLE')
            bel.connections['INTERMDISABLE'] = 'INTERMDISABLE'
            sinks.add('INTERMDISABLE')

            if IBUFDISABLE_USED:
                IBUFDISABLE = 'IBUFDISABLE'
                sinks.add('IBUFDISABLE')
            else:
                IBUFDISABLE = 0
            bel.connections['IBUFDISABLE'] = IBUFDISABLE
        elif IBUFDISABLE_USED:
            bel = Bel('IBUF_IBUFDISABLE')
            bel.connections['IBUFDISABLE'] = 'IBUFDISABLE'
            sinks.add('IBUFDISABLE')
        else:
            bel = Bel('IBUF')

        top_wire = top.add_top_in_port(aparts[0], site.name, 'I')
        bel.connections['I'] = top_wire
        bel.connections['O'] = 'I'
        sources.add('I')

        bel.parameters['IOSTANDARD'] = top.iostandard

        bels.append(bel)
    elif 'INOUT' in features:
        assert 'ZINV_D' in features

        ilogic_active = True
        ologic_active = True

        # Options are:
        # IOBUF or IOBUF_INTERMDISABLE
        if INTERMDISABLE_USED or IBUFDISABLE_USED:
            bel = Bel('IOBUF_INTERMDISABLE')

            if INTERMDISABLE_USED:
                INTERMDISABLE = 'INTERMDISABLE'
                sinks.add('INTERMDISABLE')
            else:
                INTERMDISABLE = 0

            bel.connections['INTERMDISABLE'] = INTERMDISABLE

            if IBUFDISABLE_USED:
                IBUFDISABLE = 'IBUFDISABLE'
                sinks.add('IBUFDISABLE')
            else:
                IBUFDISABLE = 0

            bel.connections['IBUFDISABLE'] = IBUFDISABLE
        else:
            bel = Bel('IOBUF')

        top_wire = top.add_top_inout_port(aparts[0], site.name, 'IO')
        bel.connections['IO'] = top_wire

        bel.connections['O'] = 'I'
        sources.add('I')

        bel.connections['T'] = 'T'
        sinks.add('T')

        bel.connections['I'] = 'O'
        sinks.add('O')

        bel.parameters['IOSTANDARD'] = top.iostandard

        add_output_parameters(bel, features)

        bels.append(bel)
    else:
        has_output = False
        for f in features:
            if 'DRIVE' in f:
                has_output = True
                break

        if not has_output:
            # Naked pull options are not supported
            assert 'PULLTYPE.PULLDOWN' in features
        else:
            # TODO: Could be a OBUFT?
            bel = Bel('OBUF')
            top_wire = top.add_top_out_port(aparts[0], site.name, 'O')
            bel.connections['O'] = top_wire
            bel.connections['I'] = 'O'
            sinks.add('O')

            bel.parameters['IOSTANDARD'] = top.iostandard

            add_output_parameters(bel, features)
            bels.append(bel)
            ologic_active = True

    if top_wire is not None:
        if 'PULLTYPE.PULLDOWN' in features:
            bel = Bel('PULLDOWN')
            bel.connections['O'] = top_wire
            bels.append(bel)
        elif 'PULLTYPE.KEEPER' in features:
            bel = Bel('KEEPER')
            bel.connections['O'] = top_wire
            bels.append(bel)
        elif 'PULLTYPE.PULLUP' in features:
            bel = Bel('PULLUP')
            bel.connections['O'] = top_wire
            bels.append(bel)

    top.add_site(aparts[0], site, bels, outputs,
            sinks, sources, internal_sources)

    if ilogic_active:
        # TODO: Handle IDDR or ISERDES
        top.add_site(
                iologic_tile,
                ilogic_site,
                [], {'O': 'D'},
                sinks=set(('D',)),
                sources=set(('O',)),
                internal_sources=set())

    if ologic_active:
        # TODO: Handle ODDR or OSERDES
        top.add_site(
                iologic_tile,
                ologic_site,
                [], {'OQ': 'D1'},
                sinks=set(('D1',)),
                sources=set(('OQ',)),
                internal_sources=set())


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

        bels = []
        sinks = set()
        sources = set()
        internal_sources = set()
        outputs = {}

        bel = Bel('BUFGCTRL')
        bel.parameters['IS_IGNORE0_INVERTED'] = int('IS_IGNORE0_INVERTED' in set_features)
        bel.parameters['IS_IGNORE1_INVERTED'] = int('IS_IGNORE1_INVERTED' in set_features)
        bel.parameters['IS_CE0_INVERTED'] = int('ZINV_CE0' not in set_features)
        bel.parameters['IS_CE1_INVERTED'] = int('ZINV_CE1' not in set_features)
        bel.parameters['IS_S0_INVERTED'] = int('ZINV_S0' not in set_features)
        bel.parameters['IS_S1_INVERTED'] = int('ZINV_S1' not in set_features)
        bel.parameters['PRESELECT_I0'] = int('ZPRESELECT_I0' not in set_features)
        bel.parameters['PRESELECT_I1'] = int('PRESELECT_I1' in set_features)
        bel.parameters['INIT_OUT'] = int('INIT_OUT' in set_features)

        for sink in ('I0', 'I1', 'S0', 'S1', 'CE0', 'CE1', 'IGNORE0', 'IGNORE1'):
            bel.connections[sink] = sink
            sinks.add(sink)

        bel.connections['O'] = 'O'
        sources.add('O')

        bels.append(bel)

        site = get_bufg_site(top.db, top.grid, tile, features[0].feature.split('.')[2])
        top.add_site(tile, site, bels, outputs,
                sinks, sources, internal_sources)


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

        bels = []
        sinks = set()
        sources = set()
        internal_sources = set()
        outputs = {}

        bel = Bel('BUFHCE')
        if 'CE_TYPE.ASYNC' in set_features:
            bel.parameters['CE_TYPE'] = 'ASYNC'
        else:
            bel.parameters['CE_TYPE'] = 'SYNC'
        bel.parameters['IS_CE_INVERTED'] = int('ZINV_CE' not in set_features)
        bel.parameters['INIT_OUT'] = int('INIT_OUT' in set_features)

        for sink in ('I', 'CE'):
            bel.connections[sink] = sink
            sinks.add(sink)

        bel.connections['O'] = 'O'
        sources.add('O')

        bels.append(bel)

        site = get_bufhce_site(top.db, top.grid, tile, features[0].feature.split('.')[2])
        top.add_site(tile, site, bels, outputs,
                sinks, sources, internal_sources)

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
    parser.add_argument('--iostandard')
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
            }

    top.set_iostandard(iostandards)

    for tile in tiles:
        tile_type = get_tile_type(tile)

        process_tile[tile_type](conn, top, tile, tiles[tile])

    top.make_routes()

    for l in top.output_verilog():
        print(l)


if __name__ == "__main__":
    main()
