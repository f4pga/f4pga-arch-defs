"""Provide utilites for converting between FASM and icebox representations.

FASM represents enabling features from a default "empty" configuration.
IceBox documents what each bit does even if should be set by default (unused).

Therefore any differences between ice40 parts are hidden from the FASM
portion. For example IE, REN, and Ram PowerUp are inverted for 1k parts comparted to
all other families.

FASM features attempt to maintain the IceStrom nomenclature.
Exceptions:
 - '/' are replaced with '_' as '/' is not valid for FASM feature name
 - RAM CBITS are combined into READ_MODE and WRITE_MODE FASM features
 - IO configuration bits are combined into SimpleInput and SimpleOut FASM features
"""

from io import StringIO
import re
import unittest
import numpy as np

import icebox
import fasm
from ice40_feature import Feature, IceDbEntry, FasmEntry

# hardcoded permutation
# * https://github.com/YosysHQ/nextpnr/blob/343569105ddf7c97316922774dc4d70d1d4f7c9f/ice40/bitstream.cc#L460-L468
# * https://github.com/cliffordwolf/icestorm/blob/master/icebox/icebox_hlc2asc.py#L925-L936
# * https://github.com/YosysHQ/arachne-pnr/blob/840bdfdeb38809f9f6af4d89dd7b22959b176fdd/src/place.cc#L1573-L1627
LUT_BITS = [4, 14, 15, 5, 6, 16, 17, 7, 3, 13, 12, 2, 1, 11, 10, 0]
LUT_CTRL = {"CarryEnable": 8, "DffEnable": 9, "Set_NoReset": 18, "AsyncSetReset": 19}


def _nibbles_to_bits(line):
    """
    Convert from icebox hex string for ramdata in asc files to an array of Bool
    """
    res = []
    for ch in line:
        res += [xx == "1" for xx in "{:4b}".format(int(ch, 16))]
    res.reverse()
    return res


def _bits_to_nibbles(arr):
    """
    Convert from array of Bool to icebox hex string used for ramdata in asc files
    """
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

    Modifies tile in place to simplify updating of iceconfig
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
    res = 20 * [lut[0]]
    for ii, bit in enumerate(LUT_BITS):
        res[bit] = lut[ii]
    for k, v in ctrl.items():
        res[LUT_CTRL[k]] = v
    return res


def _lc_to_lut(lc):
    """
    convert from lc bits to unpermuted lut table and control dict
    """
    lut = [lc[val] for val in LUT_BITS]
    ctrl = {k: lc[v] for k, v in LUT_CTRL.items()}
    return lut, ctrl


def _get_feature_bits(tile, cond):
    """
    get bitmask and values for the tile from an icebox db entry
    """
    bm = np.zeros(tile.shape, dtype=bool)
    bp = np.zeros(tile.shape, dtype=bool)
    for ii in cond:
        neg, x, y = ii
        bm[x][y] = True
        bp[x][y] = neg != "!"
    return bm, bp


def _set_feature_bits(ic, loc, bits):
    """
    Set bits for a specifc location in an iceconfig
    """
    tile = ic.tile(*loc)
    tile_bits = _tile_to_array(tile)
    bm, bv = _get_feature_bits(tile_bits, bits)
    tile_bits[bm] = bv[bm]
    _array_to_tile(tile_bits, tile)


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
        self[feature.to_fasm_entry().feature] = feature

    def append_ice_entry(self, tile_type, tile_loc, bits, names, idx, negate=False):

        if negate:
            feature = Feature.from_icedb_entry(
                IceDbEntry(tile_type, tile_loc, bits, names, idx)
            )
            feature.bit_tuples = [_inv_bit_tuple(bt) for bt in feature.bit_tuples]
        else:
            feature = Feature.from_icedb_entry(
                IceDbEntry(tile_type, tile_loc, bits, names, idx)
            )

        self.append_feature(feature)
        return feature

    def as_fasm_db(self, outf=StringIO()):
        for key in sorted(self.keys()):
            entry = self[key].to_fasm_entry()
            print("{} {}".format(entry.feature, " ".join(entry.bits)), file=outf)
        return outf

    def as_fasm(self, outf=StringIO()):
        for key in sorted(self.keys()):
            print(key, file=outf)
        return outf


def read_ice_db(ic):
    """
    read icebox database from iceconfig and construct a dictionary of features
    """

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
            elif (
                tile_type == "IO"
                and device_1k
                and (entry[-1].startswith("IE_") or entry[-1].startswith("REN_"))
            ):
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
    """
    Generate FASM style DB for a ice40 device
    """
    ic = icebox.iceconfig()
    init_method_name = "setup_empty_{}".format(device.lower()[2:])
    assert hasattr(ic, init_method_name), "no icebox method to init empty device"
    getattr(ic, init_method_name)()

    return _iceboxdb_to_fasmdb(ic, outf)


def asc_to_fasm(filename, outf=StringIO()):
    """
    Generate a fasm output from an asc
    """
    ic = icebox.iceconfig()
    ic.read_file(filename)

    return iceconfig_to_fasm(ic, outf)


def iceconfig_to_fasm(ic, outf=StringIO()):
    """
    read iceconfig and generate FASM features.

    Useful for generating FASM from ASC file.
    """
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

            elif (
                tile_type == "IO"
                and device_1k
                and (entry[-1].startswith("IE_") or entry[-1].startswith("REN_"))
            ):
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
            feature = Feature.from_icedb_entry(
                IceDbEntry(tile_type, tile_loc, entry[0], entry[1:], y)
            )
            print(feature.to_fasm_entry().feature, file=outf)

    # TODO: extra_bits

    return accum.as_fasm(outf)


def fasm_to_asc(in_fasm, outf, device):
    """
    Convert an FASM input to an ASC file

    Set input enable defaults, RAM powerup, and enables all ColBufCtrl (until modeled in VPR see: #464)
    """
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
                and (
                    (tile_type == "IO" and entry[-1] in ["IE_0", "IE_1"])
                    or (tile_type == "RAMB" and entry[-1] == "PowerUp")
                )
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

        feature = Feature.from_fasm_entry(FasmEntry(line.set_feature.feature, []))

        def find_ieren(ic, loc, iob):
            tmap = [xx[3:] for xx in ic.ieren_db() if xx[:3] == (tuple(loc) + (iob,))]
            assert len(tmap) < 2, "expected 1 IEREN_DB entry found {}".format(len(tmap))

            if len(tmap) == 0:
                print("no ieren found for {}".format((tile_loc + (iob,))))
                return
            return tmap[0]

        # fix up for IO
        if feature.parts[-1] == "SimpleInput":
            iob = int(feature.parts[-2][-1])
            new_ieren = find_ieren(ic, feature.loc, iob)

            feature.parts[-1] = "PINTYPE_0"
            db_entry = fasmdb[feature.to_fasm_entry().feature]
            _set_feature_bits(ic, db_entry.loc, db_entry.bit_tuples)

            feature.loc = new_ieren[:2]
            feature.parts[-2] = "IoCtrl"
            feature.parts[-1] = "IE_{}".format(new_ieren[2])
            db_entry = fasmdb[feature.to_fasm_entry().feature]
            _set_feature_bits(ic, db_entry.loc, db_entry.bit_tuples)
            feature.parts[-1] = "REN_{}".format(new_ieren[2])
            db_entry = fasmdb[feature.to_fasm_entry().feature]
            _set_feature_bits(ic, db_entry.loc, db_entry.bit_tuples)
            continue

        if feature.parts[-1] == "SimpleOutput":
            iob = int(feature.parts[-2][-1])
            new_ieren = find_ieren(ic, feature.loc, iob)

            feature.parts[-1] = "PINTYPE_3"
            db_entry = fasmdb[feature.to_fasm_entry().feature]
            _set_feature_bits(ic, db_entry.loc, db_entry.bit_tuples)
            feature.parts[-1] = "PINTYPE_4"
            db_entry = fasmdb[feature.to_fasm_entry().feature]
            _set_feature_bits(ic, db_entry.loc, db_entry.bit_tuples)

            feature.loc = new_ieren[:2]
            feature.parts[-2] = "IoCtrl"
            feature.parts[-1] = "REN_{}".format(new_ieren[2])
            db_entry = fasmdb[feature.to_fasm_entry().feature]
            _set_feature_bits(ic, db_entry.loc, db_entry.bit_tuples)
            continue

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


if __name__ == "__main__":
    import argparse
    import sys

    parser = argparse.ArgumentParser(description="Dump FASM DB from icebox")
    parser.add_argument("device", help="Device type (eg lp1k, hx8k)")
    parser.add_argument(
        "--output", help="Output file", type=argparse.FileType("w"), default=sys.stdout
    )
    args = parser.parse_args()

    generate_fasm_db(args.output, args.device)
