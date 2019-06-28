import fasm
from .verilog_modeling import Bel, Site


def get_clb_site(db, grid, tile, site):
    """ Return the prjxray.tile.Site object for the given CLB site. """
    gridinfo = grid.gridinfo_at_tilename(tile)
    tile_type = db.get_tile_type(gridinfo.tile_type)

    sites = sorted(tile_type.get_instance_sites(gridinfo), key=lambda x: x.x)

    return sites[int(site[-1])]


def get_lut_init(features, tile_name, slice_name, lut):
    """ Return the INIT value for the specified LUT. """
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
    """ Create the BEL for the specified LUT. """
    bel = Bel('LUT6_2', lut + 'LUT', priority=3)
    bel.set_bel(lut + '6LUT')

    for idx in range(6):
        site.add_sink(bel, 'I{}'.format(idx), '{}{}'.format(lut, idx + 1))

    site.add_internal_source(bel, 'O6', lut + 'O6')
    site.add_internal_source(bel, 'O5', lut + 'O5')

    return bel


def get_srl32_init(features, tile_name, slice_name, srl):

    lut_init = get_lut_init(features, tile_name, slice_name, srl)
    bits = lut_init.replace("64'b", "")

    return "32'b{}".format(bits[::2])


def create_srl32(site, srl):
    bel = Bel('SRLC32E', srl + 'SRL', priority=3)
    bel.set_bel(srl + '6LUT')

    site.add_sink(bel, 'CLK', 'CLK')
    site.add_sink(bel, 'D', '{}I'.format(srl))

    for idx in range(5):
        site.add_sink(bel, 'A[{}]'.format(idx), '{}{}'.format(srl, idx + 2))

    site.add_internal_source(bel, 'Q', srl + 'O6')

    return bel


def decode_dram(site):
    """ Decode the modes of each LUT in the slice based on set features.

    Returns dictionary of lut position (e.g. 'A') to lut mode.
    """
    lut_ram = {}
    for lut in 'ABCD':
        lut_ram[lut] = site.has_feature('{}LUT.RAM'.format(lut))

    di = {}
    for lut in 'ABC':
        di[lut] = site.has_feature('{}LUT.DI1MUX.{}I'.format(lut, lut))

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

        minus_one = chr(ord(lut) - 1)
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
    """ Returns FF information for given FF.

    site (Site): Site object
    lut (str): FF in question (e.g. 'A')
    ff5 (bool): True if the 5FF versus the FF.

    Returns tuple of (module name, clock pin, clock enable pin, reset pin,
        init parameter).

    """
    ffsync = site.has_feature('FFSYNC')
    latch = site.has_feature('LATCH') and not ff5
    zrst = site.has_feature('{}{}FF.ZRST'.format(lut, '5' if ff5 else ''))
    zini = site.has_feature('{}{}FF.ZINI'.format(lut, '5' if ff5 else ''))
    init = int(not zini)

    if latch:
        assert not ffsync

    return {
        (False, False, False): ('FDPE', 'C', 'CE', 'PRE', init),
        (True, False, False): ('FDSE', 'C', 'CE', 'S', init),
        (True, False, True): ('FDRE', 'C', 'CE', 'R', init),
        (False, False, True): ('FDCE', 'C', 'CE', 'CLR', init),
        (False, True, True): ('LDCE', 'G', 'GE', 'CLR', init),
        (False, True, False): ('LDPE', 'G', 'GE', 'PRE', init),
    }[(ffsync, latch, zrst)]


def cleanup_slice(top, site):
    """ Perform post-routing cleanups required for SLICE.

    Cleanups:
     - Detect if CARRY4 is required.  If not, remove from site.
     - Remove connections to CARRY4 that are not in used (e.g. if C[3] and
       CO[3] are not used, disconnect S[3] and DI[2]).

    """
    carry4 = site.maybe_get_bel('CARRY4')

    if carry4 is None:
        return

    # Simplest check is if the CARRY4 has output in used by either the OUTMUX
    # or the FFMUX, if any of these muxes are enable, CARRY4 must remain.
    co_in_use = [False for _ in range(4)]
    o_in_use = [False for _ in range(4)]
    for idx, lut in enumerate('ABCD'):
        if site.has_feature('{}FFMUX.XOR'.format(lut)):
            o_in_use[idx] = True

        if site.has_feature('{}FFMUX.CY'.format(lut)):
            co_in_use[idx] = True

        if site.has_feature('{}OUTMUX.XOR'.format(lut)):
            o_in_use[idx] = True

        if site.has_feature('{}OUTMUX.CY'.format(lut)):
            co_in_use[idx] = True

    # No outputs in the SLICE use CARRY4, check if the COUT line is in use.
    for sink in top.find_sinks_from_source(site, 'COUT'):
        co_in_use[idx] = True
        break

    for idx in [3, 2, 1, 0]:
        if co_in_use[idx] or o_in_use[idx]:
            for odx in range(idx):
                co_in_use[odx] = True
                o_in_use[odx] = True

            break

    if not any(co_in_use) and not any(o_in_use):
        # No outputs in use, remove entire BEL
        top.remove_bel(site, carry4)
    else:
        for idx in range(4):
            if not o_in_use[idx] and not co_in_use[idx]:
                sink_wire_pkey = site.remove_internal_sink(
                    carry4, 'S[{}]'.format(idx)
                )
                if sink_wire_pkey is not None:
                    top.remove_sink(sink_wire_pkey)

                sink_wire_pkey = site.remove_internal_sink(
                    carry4, 'DI[{}]'.format(idx)
                )
                if sink_wire_pkey is not None:
                    top.remove_sink(sink_wire_pkey)


def process_slice(top, s):
    """ Convert SLICE features in Bel and Site objects.

    """
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
    site = Site(
        s, get_clb_site(top.db, top.grid, tile=aparts[0], site=aparts[1])
    )

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
            WE = 'CE'
        else:
            WE = 'WE'

    if site.has_feature('DLUT.RAM'):
        # Must be a SLICEM to have RAM set.
        assert mlut
    else:
        for row in 'ABC':
            assert not site.has_feature('{}LUT.RAM'.format(row))

    muxes = set(('F7AMUX', 'F7BMUX', 'F8MUX'))

    luts = {}
    srls = {}
    # Add BELs for LUTs/RAMs
    if not site.has_feature('DLUT.RAM'):
        for row in 'ABCD':

            # SRL
            if site.has_feature('{}LUT.SRL'.format(row)):

                # Cannot have both SRL and DRAM
                assert not site.has_feature('{}LUT.RAM'.format(row))

                # SRL32
                if not site.has_feature('{}LUT.SMALL'.format(row)):
                    srls[row] = create_srl32(site, row)
                    srls[row].parameters['INIT'] = get_srl32_init(
                        s, aparts[0], aparts[1], row
                    )

                    site.add_sink(srls[row], 'CE', WE)

                    site.add_bel(srls[row])

                # 2x SRL16
                else:
                    assert False, "SRL16 not supported yet!"

            # LUT
            else:
                luts[row] = create_lut(site, row)
                luts[row].parameters['INIT'] = get_lut_init(
                    s, aparts[0], aparts[1], row
                )
                site.add_bel(luts[row])
    else:
        # DRAM is active.  Determine what BELs are in use.
        lut_modes = decode_dram(site)

        if lut_modes['D'] == 'RAM256X1S':
            ram256 = Bel('RAM256X1S', priority=3)
            site.add_sink(ram256, 'WE', WE)
            site.add_sink(ram256, 'WCLK', 'CLK')
            site.add_sink(ram256, 'D', 'DI')

            for idx in range(6):
                site.add_sink(
                    ram256, 'A[{}]'.format(idx), "D{}".format(idx + 1)
                )

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
            ram128 = Bel('RAM128X1S', name='RAM128X1S_CD', priority=3)
            site.add_sink(ram128, 'WE', WE)
            site.add_sink(ram128, 'WCLK', "CLK")
            site.add_sink(ram128, 'D', "DI")

            for idx in range(6):
                site.add_sink(ram128, 'A{}'.format(idx), "D{}".format(idx + 1))

            site.add_sink(ram128, 'A6', "CX")
            site.add_internal_source(ram128, 'O', 'F7BMUX_O')

            ram128.parameters['INIT'] = (
                get_lut_init(s, aparts[0], aparts[1], 'D') |
                (get_lut_init(s, aparts[0], aparts[1], 'C') << 64)
            )

            site.add_bel(ram128)
            muxes.remove('F7BMUX')

            del lut_modes['C']
            del lut_modes['D']

            if lut_modes['B'] == 'RAM128X1S':
                ram128 = Bel('RAM128X1S', name='RAM128X1S_AB', priority=4)
                site.add_sink(ram128, 'WE', WE)
                site.add_sink(ram128, 'WCLK', "CLK")
                site.add_sink(ram128, 'D', "BI")

                for idx in range(6):
                    site.adD_sink(
                        ram128, 'A{}'.format(idx), "B{}".format(idx + 1)
                    )

                site.add_sink(ram128, 'A6', "AX")

                site.add_internal_source(ram128, 'O', 'F7AMUX_O')

                ram128.parameters['INIT'] = (
                    get_lut_init(s, aparts[0], aparts[1], 'B') |
                    (get_lut_init(s, aparts[0], aparts[1], 'A') << 64)
                )

                site.add_bel(ram128)

                muxes.remove('F7AMUX')

                del lut_modes['A']
                del lut_modes['B']

        elif lut_modes['D'] == 'RAM128X1D':
            ram128 = Bel('RAM128X1D', priority=3)

            site.add_sink(ram128, 'WE', WE)
            site.add_sink(ram128, 'WCLK', "CLK")
            site.add_sink(ram128, 'D', "DI")

            for idx in range(6):
                site.add_sink(
                    ram128, 'A[{}]'.format(idx), "D{}".format(idx + 1)
                )
                site.add_sink(
                    ram128, 'DPRA[{}]'.format(idx), "C{}".format(idx + 1)
                )

            site.add_sink(ram128, 'A[6]', "CX")
            site.add_sink(ram128, 'DPRA[6]', "AX")

            site.add_internal_source(ram128, 'SPO', 'F7AMUX_O')
            site.add_internal_source(ram128, 'DPO', 'F7BMUX_O')

            ram128.parameters['INIT'] = (
                get_lut_init(s, aparts[0], aparts[1], 'D') |
                (get_lut_init(s, aparts[0], aparts[1], 'C') << 64)
            )

            other_init = (
                get_lut_init(s, aparts[0], aparts[1], 'B') |
                (get_lut_init(s, aparts[0], aparts[1], 'A') << 64)
            )

            assert ram128.parameters['INIT'] == other_init

            site.add_bel(ram128)

            muxes.remove('F7AMUX')
            muxes.remove('F7BMUX')

            del lut_modes['A']
            del lut_modes['B']
            del lut_modes['C']
            del lut_modes['D']

        for priority, lut in zip([4, 3], 'BD'):
            minus_one = chr(ord(lut) - 1)

            if lut_modes[lut] == 'RAM64X1D':
                assert lut_modes[minus_one] == lut_modes[lut]

                ram64 = Bel(
                    'RAM64X1D',
                    name='RAM64X1D_' + minus_one + lut,
                    priority=priority
                )
                ram64.set_bel(minus_one + '6LUT')

                site.add_sink(ram64, 'WE', WE)
                site.add_sink(ram64, 'WCLK', "CLK")
                site.add_sink(ram64, 'D', lut + "I")

                for idx in range(6):
                    site.add_sink(
                        ram64, 'A{}'.format(idx), "{}{}".format(lut, idx + 1)
                    )
                    site.add_sink(
                        ram64, 'DPRA{}'.format(idx),
                        "{}{}".format(minus_one, idx + 1)
                    )

                site.add_internal_source(ram64, 'SPO', lut + "O6")
                site.add_internal_source(ram64, 'DPO', minus_one + "O6")

                ram64.parameters['INIT'] = get_lut_init(
                    s, aparts[0], aparts[1], lut
                )
                other_init = get_lut_init(s, aparts[0], aparts[1], minus_one)

                assert ram64.parameters['INIT'] == other_init

                site.add_bel(ram64)

                del lut_modes[lut]
                del lut_modes[minus_one]
            elif lut_modes[lut] == 'RAM32X1D':
                ram32 = Bel(
                    'RAM32X1D',
                    name='RAM32X1D_' + minus_one + lut,
                    priority=priority
                )

                site.add_sink(ram32, 'WE', WE)
                site.add_sink(ram32, 'WCLK', "CLK")
                site.add_sink(ram32, 'D', lut + "I")

                for idx in range(5):
                    site.add_sink(
                        ram32, 'A{}'.format(idx), "{}{}".format(lut, idx + 1)
                    )
                    site.add_sink(
                        ram32, 'DPRA{}'.format(idx),
                        "{}{}".format(minus_one, idx + 1)
                    )

                site.add_internal_source(ram32, 'SPO', lut + "O6")
                site.add_internal_source(ram32, 'DPO', minus_one + "O6")

                ram32.parameters['INIT'] = get_lut_init(
                    s, aparts[0], aparts[1], lut
                )
                other_init = get_lut_init(s, aparts[0], aparts[1], minus_one)

                site.add_bel(ram32)

                del lut_modes[lut]
                del lut_modes[minus_one]

        for priority, lut in zip([6, 5, 4, 3], 'ABCD'):
            if lut not in lut_modes:
                continue

            if lut_modes[lut] == 'LUT':
                luts[lut] = create_lut(site, lut)
                luts[lut].parameters['INIT'] = get_lut_init(
                    s, aparts[0], aparts[1], lut
                )
                site.add_bel(luts[lut])
            elif lut_modes[lut] == 'RAM64X1S':
                ram64 = Bel(
                    'RAM64X1S', name='RAM64X1S_' + lut, priority=priority
                )

                site.add_sink(ram64, 'WE', WE)
                site.add_sink(ram64, 'WCLK', "CLK")
                site.add_sink(ram64, 'D', lut + "I")

                for idx in range(6):
                    site.add_sink(
                        ram64, 'A{}'.format(idx), "{}{}".format(lut, idx + 1)
                    )

                site.add_internal_source(ram64, 'O', lut + "O6")

                ram64.parameters['INIT'] = get_lut_init(
                    s, aparts[0], aparts[1], lut
                )

                site.add_bel(ram64)
            elif lut_modes[lut] == 'RAM32X2S':
                ram32 = Bel(
                    'RAM32X1S', name='RAM32X1S_' + lut, priority=priority
                )

                site.add_sink(ram32, 'WE', WE)
                site.add_sink(ram32, 'WCLK', "CLK")
                site.add_sink(ram32, 'D', lut + "I")

                for idx in range(5):
                    site.add_sink(
                        ram32, 'A{}'.format(idx), "{}{}".format(lut, idx + 1)
                    )

                site.add_internal_source(ram32, 'O', lut + "O6")

                ram32.parameters['INIT'] = get_lut_init(
                    s, aparts[0], aparts[1], lut
                )

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

            f7amux = Bel(bel_type, 'MUXF7A', priority=7)
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

            f7bmux = Bel(bel_type, 'MUXF7B', priority=7)
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

            f8mux = Bel(bel_type, priority=7)

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

    if len(srls) != 0:
        can_have_carry4 = False

    if can_have_carry4:
        bel = Bel('CARRY4', priority=1)

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
            bel.connections['CI'] = 0

        elif site.has_feature('PRECYINIT.C0'):
            bel.connections['CYINIT'] = 0
            bel.connections['CI'] = 0

        elif site.has_feature('PRECYINIT.C1'):
            bel.connections['CYINIT'] = 1
            bel.connections['CI'] = 0

        elif site.has_feature('PRECYINIT.CIN'):
            bel.connections['CYINIT'] = 0
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
