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
    }

    for tile in ['INT_L', 'INT_R']:
        add_segment_wires(db, tile, wires, segments)

    reduce_wires_to_segments(wires, segments)

    return segments


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

    def get_segment_for_wire(self, wire):
        if wire in self.wire_to_segment:
            return self.default_segment
        else:
            return self.wire_to_segment[wire]

    def get_segment_for_wires(self, wires):
        segments = set()

        for wire in wires:
            if wire in self.wire_to_segment:
                segments.add(self.wire_to_segment[wire])

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
