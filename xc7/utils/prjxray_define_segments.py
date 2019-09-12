""" Create segment definitions for prjxray interconnect.

"""
import argparse
from prjxray.db import Database
import re


def add_segment_wires(db, tile, wires, segments):
    """ Adds to the set segment wires. """
    tile = db.get_tile_type(tile)

    for pip in tile.get_pips():
        # Ignore wires that sink to a site
        if 'GCLK' in pip.net_to:
            segments['CLKFEED'].add(pip.net_to)
            segments['HCLK_COLUMNS'].add(pip.net_from)
            continue

        elif 'IMUX' in pip.net_to or \
             'CTRL' in pip.net_to or \
             'CLK' in pip.net_to or \
             re.match('BYP[0-7]', pip.net_to) or \
             re.match('FAN[0-7]', pip.net_to):
            segments['INPINFEED'].add(pip.net_to)
            continue

        wires.add(pip.net_to)
        if not pip.is_directional:
            wires.add(pip.net_from)


def reduce_wires_to_segments(wires, segments):
    """ Reduce wire names to segment definitions.

    For purposes of creating the routing heuristic, it is assumed that if two
    source wires share a prefix, they can be considered segments for the
    purposes of the routing heuristic.

    This is definitely true for wires like SR1BEG1 or LV18.
    This may apply to the local fanout wires like GFAN0 or FAN_BOUNCE0.

    """
    WIRE_PARTS = re.compile('^(.*?)([0-9]+)$')

    for wire in wires:
        m = WIRE_PARTS.match(wire)
        assert m is not None

        segment = m.group(1)
        if segment not in segments:
            segments[segment] = set()

        segments[segment].add(wire)


def get_segments(db):
    """ Return segment approximation for device.

    Returns
    -------
    segments : dict of str to list of str
        Each key is a segment, with the elements of the values as the wires
        that belong to that segment type.

    """
    wires = set()

    segments = {
        'INPINFEED': set(),
        'CLKFEED': set(),
        'OUTPINFEED': set(),
        'BRAM_CASCADE': set(),
        'BRAM_IMUX': set(),
        'HCLK_COLUMNS': set(),
        'HCLK_ROWS': set(),
        'HCLK_ROW_TO_COLUMN': set(),
    }

    for tile in ['INT_L', 'INT_R']:
        add_segment_wires(db, tile, wires, segments)

    reduce_wires_to_segments(wires, segments)

    return segments


GCLK_MATCH = re.compile('GCLK_(L_)?B[0-9]+')
LOGIC_OUT_MATCH = re.compile('LOGIC_OUTS')
BRAM_CASCADE = re.compile('BRAM_CASC(OUT|IN|INBOT)_')
HCLK_R2C_MATCH = re.compile('HCLK_CK_(OUTIN|INOUT)')


class SegmentWireMap(object):
    """ SegmentWireMap provides a way to map node wires to segments.

    The default segment should be used for non-routing wires, e.g. the wires
    that go from the interconnect switch box to sites.  This default segment
    will generally be low delay extremely short wires.

    Routing segments (e.g. LH = 12-length horizontal wire) will have
    specialized lookahead entries, and should be given their own segment.

    """

    def __init__(self, default_segment, db):
        self.default_segment = default_segment
        self.segments = get_segments(db)

        self.wire_to_segment = {}
        for segment, wires in self.segments.items():
            for wire in wires:
                assert wire not in self.wire_to_segment
                self.wire_to_segment[wire] = segment

    def get_segment_for_wires(self, wires):
        wires = list(wires)
        segments = set()

        # BRAM_IMUX cannot use INPINFEED because it doesn't obey typically
        # connection box definitions.
        is_bram_imux = False
        for wire in wires:
            if 'BRAM_IMUX' in wire:
                is_bram_imux = True
                break

        for wire in wires:
            if wire in self.wire_to_segment and not is_bram_imux:
                segments.add(self.wire_to_segment[wire])

            m = LOGIC_OUT_MATCH.match(wire)
            if m is not None:
                segments.add('OUTPINFEED')

            m = BRAM_CASCADE.search(wire)
            if m is not None:
                segments.add('BRAM_CASCADE')

            if 'CK_BUFHCLK' in wire:
                segments.add('HCLK_ROWS')

            if HCLK_R2C_MATCH.match(wire):
                segments.add('HCLK_ROW_TO_COLUMN')

            if wire.startswith('BRAM_IMUX'):
                segments.add('BRAM_IMUX')

        assert len(segments) <= 1, (wires, segments)
        if len(segments) == 1:
            return list(segments)[0]
        else:
            return self.default_segment

    def get_segments(self):
        return self.segments.keys()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--db_root', required=True)

    args = parser.parse_args()

    db = Database(args.db_root)

    segments = get_segments(db)

    for segment in sorted(segments):
        print('Segment = {}'.format(segment))
        print('Wires:')

        for wire in sorted(segments[segment]):
            print('  {}'.format(wire))


if __name__ == '__main__':
    main()
