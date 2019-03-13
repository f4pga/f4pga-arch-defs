"""Convert the icestorm database to a prjxray type DB

The goal is that the icestorm db doesn't encode information about BRAM init or
inversion of some bits such as RamConfig PowerUp (differs between 8k and 1k?)

This is handled pretty wonkley in explain and hlc code

These are not handled as features in icebox
 - break out INIT for ram
 - break out bits for LC_[0-7] INIT


Another name variant

HLC introduce a globally unique name for each wire named on the right endpoint.
FASM will have a slight variation for some features due to not supporting / character

"""
from io import StringIO
import re
import unittest
import numpy as np

import icebox
import fasm
from ice40_feature import Feature, IceDbEntry, FasmEntry


def _nibbles_to_bits(line):
    res = []
    for ch in line:
        res += [xx == "1" for xx in "{:4b}".format(int(ch, 16))]
    res.reverse()
    return res


def _bits_to_nibbles(arr):
    res = []
    for ii in range(0, len(arr), 4):
        nibble_val = sum((1 << ii) for ii, xx in enumerate(arr[ii : ii + 4]) if xx)
        res += "{:x}".format(nibble_val)
    res.reverse()
    return "".join(res)


def _tile_to_array(tile, is_hex=False):
    """
    convert text icedb tile to a numpy array
    """
    if is_hex:
        array = np.array([_nibbles_to_bits(line) for line in tile], dtype=bool)
    else:
        array = np.array([[int(xx) for xx in line] for line in tile], dtype=bool)
    return array


def _array_to_tile(tile_bits, tile, is_hex=False):
    """
    convert a numpy array to text icedb tile
    """
    if is_hex:
        for ii, xx in enumerate(tile_bits):
            tile[ii] = _bits_to_nibbles(xx)
    else:
        for ii, xx in enumerate(tile_bits):
            tile[ii] = tile_bits.shape[1] * "%d" % tuple(xx)


def _lut_to_lc(lut, ctrl):
    """
    convert lut and ctrl dict to permuted lc bits
    """
    # hardcoded permutation
    # * https://github.com/YosysHQ/nextpnr/blob/343569105ddf7c97316922774dc4d70d1d4f7c9f/ice40/bitstream.cc#L460-L468
    # * https://github.com/cliffordwolf/icestorm/blob/master/icebox/icebox_hlc2asc.py#L925-L936
    # * https://github.com/YosysHQ/arachne-pnr/blob/840bdfdeb38809f9f6af4d89dd7b22959b176fdd/src/place.cc#L1573-L1627
    lut_bits = [4, 14, 15, 5, 6, 16, 17, 7, 3, 13, 12, 2, 1, 11, 10, 0]
    lut_ctrl = {
        "CarryEnable": 8,
        "DffEnable": 9,
        "Set_NoReset": 18,
        "AsyncSetReset": 19,
    }
    res = 20 * [lut[0]]
    for ii, bit in enumerate(lut_bits):
        res[bit] = lut[ii]
    for k, v in ctrl.items():
        res[lut_ctrl[k]] = v
    return res


def _lc_to_lut(lc):
    # hardcoded permutation
    # * https://github.com/YosysHQ/nextpnr/blob/343569105ddf7c97316922774dc4d70d1d4f7c9f/ice40/bitstream.cc#L460-L468
    # * https://github.com/cliffordwolf/icestorm/blob/master/icebox/icebox_hlc2asc.py#L925-L936
    # * https://github.com/YosysHQ/arachne-pnr/blob/840bdfdeb38809f9f6af4d89dd7b22959b176fdd/src/place.cc#L1573-L1627
    lut_bits = [4, 14, 15, 5, 6, 16, 17, 7, 3, 13, 12, 2, 1, 11, 10, 0]
    lut_ctrl = {
        "CarryEnable": 8,
        "DffEnable": 9,
        "Set_NoReset": 18,
        "AsyncSetReset": 19,
    }

    lut = [lc[val] for val in lut_bits]
    ctrl = {k: lc[v] for k, v in lut_ctrl.items()}

    return lut, ctrl


def _get_feature_bits(tile, cond):
    """
  get bitmask and values for the tile from an icebox db entry
  """
    bm = np.zeros(tile.shape, dtype=bool)
    bp = np.zeros(tile.shape, dtype=bool)
    for ii in cond:
        neg, x, y = ii
        bm[x][y] = 1
        bp[x][y] = neg != "!"
    return bm, bp


def _get_iceconfig_bits(tile, cond):
    """
  get bitmask and values for the tile from an icebox db entry
  """
    bm = np.zeros(tile.shape, dtype=bool)
    bp = np.zeros(tile.shape, dtype=bool)
    for ii in cond:
        mm = re.match(r"([\!]?)B([0-9]+)\[([0-9]*)\]", ii)
        neg = mm.group(1)
        inds = [int(mm.group(ii)) for ii in range(2, 4)]
        bm[inds[0]][inds[1]] = 1
        bp[inds[0]][inds[1]] = neg != "!"
    return bm, bp


def _check_iceconfig_entry(tile, entry):
    """
  check an entry is set for a tile
  """
    bm, bp = _get_iceconfig_bits(tile, entry[0])
    return np.all(bp[bm] == tile[bm])

def _inv_bit_tuple(bit_tuple):
    if bit_tuple[0] == "":
        neg = "!"
    else:
        neg = ""
    return tuple(neg) + bit_tuple[1:]


class FeatureAccumulator(dict):
    """
    Class to help accumulate iCE40 features for output as FASM file or a FASM DB
    """

    def append_feature(self, feature):
        self[feature.toFasmEntry().feature] = feature

    def append_ice_entry(self, tile_type, tile_loc, bits, names, idx, negate=False):

        if negate:
            feature = Feature.fromIceDbEntry(
                IceDbEntry(tile_type, tile_loc, bits, names, idx)
            )
            feature.bit_tuples = [_inv_bit_tuple(bt) for bt in feature.bit_tuples]
        else:
            feature = Feature.fromIceDbEntry(
                IceDbEntry(tile_type, tile_loc, bits, names, idx)
            )

        self.append_feature(feature)
        return feature

    def as_fasm_db(self, outf=StringIO()):
        for key in sorted(self.keys()):
            entry = self[key].toFasmEntry()
            print("{} {}".format(entry.feature, " ".join(entry.bits)), file=outf)
        return outf

    def as_fasm(self, outf=StringIO()):
        for key in sorted(self.keys()):
            print(key, file=outf)
        return outf


def read_ice_db(ic):
    # TODO: undo Hack to invert some specific signals
    device_1k = ic.device == "1k"

    accum = FeatureAccumulator()
    locs = [(x, y) for x in range(ic.max_x + 1) for y in range(ic.max_y + 1)]

    for tile_loc in locs:
        if ic.tile(*tile_loc) is None:
            continue
        tile_type = ic.tile_type(*tile_loc)

        for entry in ic.tile_db(*tile_loc):
            if entry[1].startswith("LC_"):

                lut, ctrl = _lc_to_lut(entry[0])
                for ii, bit in enumerate(lut):
                    names = entry[1:] + ["INIT"]
                    accum.append_ice_entry(tile_type, tile_loc, [bit], names, ii)

                for name, bit in ctrl.items():
                    names = entry[1:] + [name]
                    accum.append_ice_entry(tile_type, tile_loc, [bit], names, None)

            # entries to generate the negated case
            elif tile_type == "IO" and device_1k and entry[-1].startswith("IE_"):
                accum.append_ice_entry(
                    tile_type, tile_loc, entry[0], entry[1:], None, negate=True
                )
            elif tile_type == "IO" and entry[-1].startswith("PINTYPE"):
                # TODO: push this up into sythesis and pass parameters
                # SimpleInput and SimpleOutput for IOB_0 and IOB_1
                if entry[-1] == "PINTYPE_0":
                    ic.tile_db(*tile_loc)
                    sinput = []
                    soutput = []
                    IOB = entry[-2][-1]
                    tmap = [xx[3:] for xx in ic.ieren_db() if xx[:3] == (tile_loc + (int(IOB),))]
                    assert (len(tmap) < 2), "expected 1 IEREN_DB entry found {}".format(len(tmap))

                    if len(tmap) == 0:
                        print("no ieren found for {}".format( (tile_loc + (int(IOB),)) ))
                        continue
                    ieren_map = tmap[0]
                    assert (ieren_map[:2] == tile_loc), "IEREN_DB entry is in a different tile. This is not currently supported."

                    for ii in ic.tile_db(*tile_loc):
                        if ii[-1] in ["IE_{}".format(ieren_map[2]), "REN_{}".format(ieren_map[2])] or (ii[-2] == "IOB_{}".format(IOB) and ii[-1] in ["PINTYPE_0"]):
                            sinput += ii[0]
                        if ii[-1] in ["REN_{}".format(ieren_map[2])] or (ii[-2] == "IOB_{}".format(ieren_map[2]) and ii[-1] in ["PINTYPE_0", "PINTYPE_3", "PINTYPE_4"]):
                            soutput += ii[0]

                    accum.append_ice_entry(tile_type, tile_loc, sinput, entry[1:-1] + ["SimpleInput"], None)
                    accum.append_ice_entry(tile_type, tile_loc, soutput, entry[1:-1] + ["SimpleOutput"], None)
            elif device_1k and tile_type == "RAMB" and entry[-1] == "PowerUp":
                accum.append_ice_entry(
                    tile_type, tile_loc, entry[0], entry[1:], None, negate=True
                )
            elif tile_type == "RAMT" and entry[-1].startswith("CBIT"):
                matches = re.match(r"CBIT_([0-9]+)", entry[-1])
                assert matches is not None, "Expected 'CBIT_n' received {}".format(
                    entry[-1]
                )

                cbit_offset = matches.group(1)
                cbit_translation = {
                    "0": ("WRITE_MODE", 0),
                    "1": ("WRITE_MODE", 1),
                    "2": ("READ_MODE", 0),
                    "3": ("READ_MODE", 1),
                }
                val = cbit_translation.get(cbit_offset)
                if val is not None:
                    ramb_tile_loc = (tile_loc[0], tile_loc[1] - 1)
                    accum.append_ice_entry(
                        "RAMB", ramb_tile_loc, entry[0], [val[0]], val[1]
                    )
                else:
                    accum.append_ice_entry(
                        tile_type, tile_loc, entry[0], entry[1:], None
                    )
            else:
                accum.append_ice_entry(tile_type, tile_loc, entry[0], entry[1:], None)

    # add RAM data entries features
    tile_type = "RAMB"
    for ram_loc in ic.ramb_tiles:
        for i in range(16):
            feature_name = "INIT{:X}".format(i)
            for j in range(256):
                bit = "B{}[{}]".format(i, j)
                accum.append_ice_entry(tile_type, ram_loc, [bit], [feature_name], j)

    # TODO: extra bits?

    return accum


def _iceboxdb_to_fasmdb(ic, outf=StringIO()):
    """
    read in an icebox config and output the exhaustive list of bits with fasm compatible names

    expand RAM and LUT INIT bits
    """
    fasmdb = read_ice_db(ic)
    return fasmdb.as_fasm_db(outf)


def generate_fasm_db(outf, device):
    ic = icebox.iceconfig()
    init_method_name = "setup_empty_{}".format(device.lower()[2:])
    assert hasattr(ic, init_method_name), "no icebox method to init empty device"
    getattr(ic, init_method_name)()

    return _iceboxdb_to_fasmdb(ic, outf)


def asc_to_fasm(filename, outf=StringIO()):
    """
    generate a fasm output from an asc
    """
    ic = icebox.iceconfig()
    ic.read_file(filename)

    return iceconfig_to_fasm(ic, outf)


def iceconfig_to_fasm(ic, outf=StringIO()):
    # TODO: undo Hack to invert some specific signals
    device_1k = ic.device == "1k"

    accum = FeatureAccumulator()

    locs = [(x, y) for x in range(ic.max_x + 1) for y in range(ic.max_y + 1)]
    for tile_loc in locs:
        bits = ic.tile(*tile_loc)
        if bits is None:
            continue
        tile_bits = _tile_to_array(bits)
        tile_type = ic.tile_type(*tile_loc)

        for entry in ic.tile_db(*tile_loc):
            # LC_ entries are treated differently as it's not a match, but a pattern
            if entry[1].startswith("LC_"):
                bm, _ = _get_iceconfig_bits(tile_bits, entry[0])
                bits = tile_bits[bm]
                if np.any(bits):
                    lut, ctrl = _lc_to_lut(bits)
                    for ii, bit in enumerate(lut):
                        if bit:
                            names = entry[1:] + ["INIT"]
                            accum.append_ice_entry(tile_type, tile_loc, [], names, ii)

                    for name, bit in ctrl.items():
                        if bit:
                            names = entry[1:] + [name]
                            accum.append_ice_entry(tile_type, tile_loc, [], names, None)

            elif tile_type == "IO" and device_1k and entry[-1].startswith("IE_"):
                accum.append_ice_entry(
                    tile_type, tile_loc, entry[0], entry[1:], None, negate=True
                )
            elif device_1k and tile_type == "RAMB" and entry[-1] == "PowerUp":
                accum.append_ice_entry(
                    tile_type, tile_loc, entry[0], entry[1:], None, negate=True
                )
            elif tile_type == "RAMT" and entry[-1].startswith("CBIT"):
                matches = re.match(r"CBIT_([0-9]+)", entry[-1])
                assert matches is not None, "Expected 'CBIT_n' received {}".format(
                    entry[-1]
                )

                cbit_offset = matches.group(1)
                cbit_translation = {
                    "0": ("WRITE_MODE", 0),
                    "1": ("WRITE_MODE", 1),
                    "2": ("READ_MODE", 0),
                    "3": ("READ_MODE", 1),
                }
                val = cbit_translation.get(cbit_offset)
                if val is not None:
                    ramb_tile_loc = (tile_loc[0], tile_loc[1] - 1)
                    accum.append_ice_entry(
                        "RAMB", ramb_tile_loc, entry[0], [val[0]], val[1]
                    )
                else:
                    accum.append_ice_entry(
                        tile_type, tile_loc, entry[0], entry[1:], None
                    )

            else:
                if _check_iceconfig_entry(tile_bits, entry):
                    accum.append_ice_entry(
                        tile_type, tile_loc, entry[0], entry[1:], None
                    )

    # ram data
    for tile_loc, hexd in ic.ram_data.items():
        tile_bits = _tile_to_array(hexd, is_hex=True)
        tile_type = "RAMB"

        for x, y in zip(*np.where(tile_bits)):
            feature_name = "INIT{:X}".format(x)
            bit = "B{}[{}]".format(x, y)
            entry = [[bit], feature_name]
            feature = Feature.fromIceDbEntry(
                IceDbEntry(tile_type, tile_loc, entry[0], entry[1:], y)
            )
            print(feature.toFasmEntry().feature, file=outf)

    # TODO: extra_bits

    return accum.as_fasm(outf)


def fasm_to_asc(in_fasm, outf, device):
    ic = icebox.iceconfig()

    init_method_name = "setup_empty_{}".format(device.lower()[2:])
    assert hasattr(ic, init_method_name), "no icebox method to init empty device"
    getattr(ic, init_method_name)()

    device_1k = ic.device == "1k"

    fasmdb = read_ice_db(ic)
    # TODO: upstream init "default" bitstream
    locs = [(x, y) for x in range(ic.max_x + 1) for y in range(ic.max_y + 1)]
    for tile_loc in locs:
        tile = ic.tile(*tile_loc)
        if tile is None:
            continue
        db = ic.tile_db(*tile_loc)
        tile_type = ic.tile_type(*tile_loc)
        for entry in db:
            if (
                device_1k
                and (tile_type == "IO" and entry[-1] in ["IE_0", "IE_1"])
                or (tile_type == "RAMB" and entry[-1] == "PowerUp")
                or (entry[-2] == "ColBufCtrl")
            ):
                tile_bits = _tile_to_array(tile)
                tile_type = ic.tile_type(*tile_loc)
                bm, bv = _get_iceconfig_bits(tile_bits, entry[0])
                tile_bits[bm] = bv[bm]
                _array_to_tile(tile_bits, tile)

    missing_features = []
    for line in fasm.parse_fasm_string(in_fasm.read()):
        if not line.set_feature:
            continue

        line_strs = tuple(fasm.fasm_line_to_string(line))
        assert len(line_strs) == 1

        feature = Feature.fromFasmEntry(FasmEntry(line.set_feature.feature, []))
        ## special case for RAM INIT values
        tile_type, loc = feature.tile_type, feature.loc
        if tile_type == "RAMB" and feature.parts[-1].startswith("INIT"):
            tloc = tuple(loc)
            if tloc not in ic.ram_data:
                ic.ram_data[tloc] = [64 * "0" for _ in range(16)]
            tile = ic.ram_data[tloc]
            tile_bits = _tile_to_array(tile, is_hex=True)
        elif tile_type == "RAMB" and feature.parts[-1].endswith("_MODE"):
            # hack to force modes to the RAMT
            tile = ic.tile(loc[0], loc[1] + 1)
            tile_bits = _tile_to_array(tile)
        else:
            tile = ic.tile(*loc)
            tile_bits = _tile_to_array(tile)

        # lookup feature and convert
        for canonical_feature in fasm.canonical_features(line.set_feature):
            key = fasm.set_feature_to_str(canonical_feature)
            feature = fasmdb[key]
            bm, bv = _get_feature_bits(tile_bits, feature.bit_tuples)

            tile_bits[bm] = bv[bm]

        if tile_type == "RAMB" and feature.parts[-1].startswith("INIT"):
            _array_to_tile(tile_bits, tile, is_hex=True)
        else:
            _array_to_tile(tile_bits, tile)

    # TODO: would be nice to upstream a way to write to non-files
    ic.write_file(outf.name)



class TestConversion(unittest.TestCase):
    def helper(self, icedb, fasm_repr):
        fi = Feature.fromIceDbEntry(icedb)
        ff = Feature.fromFasmEntry(fasm_repr)
        self.assertEqual(fasm_repr, fi.toFasmEntry())
        self.assertEqual(icedb, ff.toIceDbEntry())

    def test_lc_x_lut(self):
        test_vec = [xx for xx in range(20)]
        lut, ctrl = _lc_to_lut(test_vec)
        lc = _lut_to_lc(lut, ctrl)
        self.assertEqual(lc, test_vec)

    def test_nibble_x_bits(self):
        test_vec = "0123456789abcd"
        bits = _nibbles_to_bits(test_vec)
        nibbles = _bits_to_nibbles(bits)
        self.assertEqual(nibbles, test_vec)

    def test_ram(self):

        self.helper(
            IceDbEntry("RAMB", [3, 15], ["B10[49]"], ["INITA"], 49),
            FasmEntry("RAMB_X3_Y15.INITA[49]", ["10_49"]),
        )

        self.helper(
            IceDbEntry("RAMB", [3, 15], ["!B10[49]"], ["INITA"], 49),
            FasmEntry("RAMB_X3_Y15.INITA[49]", ["!10_49"]),
        )

    def test_logic(self):
        self.helper(
            IceDbEntry(
                "LOGIC",
                [7, 3],
                ["!B0[31]", "B0[32]", "!B0[33]", "!B0[34]", "!B1[31]"],
                ["buffer", "carry_in_mux", "lutff_0/in_3"],
                None,
            ),
            FasmEntry(
                "LOGIC_X7_Y3.buffer.carry_in_mux.lutff_0_in_3",
                "!0_31 0_32 !0_33 !0_34 !1_31".split(),
            ),
        )

    def test_io(self):
        self.helper(
            IceDbEntry(
                "IO",
                [10, 17],
                ["B1[17]"],
                ["buffer", "io_0/D_IN_0", "span12_horz_0"],
                None,
            ),
            FasmEntry("IO_X10_Y17.buffer.io_0_D_IN_0.span12_horz_0", ["1_17"]),
        )

    """
    def test_asc_to_fasm(self):
        with open('tt','w') as f:
            res = asc_to_fasm('test_data/test1.asc', f)
        with open('t2', 'w') as f:
            fasm_to_asc('tt', f)
    """

if __name__ == "__main__":
    device = "hx8k"
    with open("ice40_{}.db".format(device), "w") as f:
        generate_fasm_db(f, device)
