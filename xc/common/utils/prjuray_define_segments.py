""" Create segment definitions for prjuray interconnect.

"""
import re
from collections import OrderedDict

# =============================================================================


def add_segment_wires(db, tile, wires, segments):
    """ Adds to the set segment wires. """
    tile = db.get_tile_type(tile)

    for pip in tile.get_pips():

        wires.add(pip.net_to)
        if not pip.is_directional:
            wires.add(pip.net_from)


def reduce_wires_to_segments(wires, segments):
    """ Reduce wire names to segment definitions.

    For purposes of creating the routing heuristic, it is assumed that if two
    source wires share a prefix, they can be considered segments for the
    purposes of the routing heuristic.

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

    segments = OrderedDict()

    # TODO: Segment names, interconnect tile names.

    #    for segment in [
    #            'INPINFEED',
    #            'CLKFEED',
    #            'OUTPINFEED',
    #            'BRAM_CASCADE',
    #            'BUFG_CASCADE',
    #            'GCLK',
    #            'GCLK_OUTPINFEED',
    #            'GCLK_INPINFEED',
    #            'HCLK_CK_IN',
    #            'BRAM_IMUX',
    #            'HCLK_COLUMNS',
    #            'HCLK_ROWS',
    #            'HCLK_ROW_TO_COLUMN',
    #            'CCIO_OUTPINFEED',
    #            'CCIO_CLK_IN',
    #            'PLL_OUTPINFEED',
    #            'PLL_INPINFEED',
    #    ]:
    #        segments[segment] = set()
    #
    #    for tile in ['INT_L', 'INT_R']:
    #        add_segment_wires(db, tile, wires, segments)

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

    def get_segment_for_wires(self, wires):
        wires = list(wires)
        segments = set()

        # TODO: Fill it in with correct segment definitions

        assert len(segments) <= 1, (wires, segments)
        if len(segments) == 1:
            return list(segments)[0]
        else:
            return self.default_segment

    def get_segments(self):
        return self.segments.keys()
