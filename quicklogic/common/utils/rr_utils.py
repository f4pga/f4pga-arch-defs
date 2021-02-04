import re

from data_structs import *

from lib.rr_graph import tracks
import lib.rr_graph.graph2 as rr

# =============================================================================

# A regular expression for VPR pin name parsing
# VPR names pins according to the scheme:
#
#  <block_type>[<sub_idx>].<pin_name>[<bit_idx>]
#
#  block_type - type of the block (tile).
#  sub_idx    - index of a sub tile. May be omitted if there are none.
#  pin_name   - actual pin name
#  bit_idx    - pin bit index (always present)
#
PIN_NAME_REGEX = re.compile(
    r"^(?P<tile>[A-Za-z0-9_\-]+)(?P<idx>\[[0-9]+\])?.((?P<sub_tile>([A-Za-z0-9_\-])+)-)?(?P<pin>[A-Za-z0-9_\-]+)(?P<bit>\[[0-9]+\])$"
)

def parse_block_pin_name(pin_name):
    """
    Decomposes a VPR pin name into meaningful fields. Returns them as a tuple:
    (tile_name, sub_tile_index, pin_name, bit_index)
    """

    match = PIN_NAME_REGEX.match(pin_name)
    assert match is not None, pin_name

    def get_index(s):
        """
        For an empty string returns "". For a string with a number in brackets
        (like "[10]") removes the brackets.
        """
        if not s:
            return 0
        return int(s[1:-1])

    return (match.group("tile"),
            get_index(match.group("idx")),
            match.group("sub_tile"),
            match.group("pin"),
            get_index(match.group("bit")))

# =============================================================================


def index_sub_tiles(block):
    """
    Analyzes a rr graph block and returns a list of sub-tiles and their indices
    sorted by Z coordinates.

    The block has to be a BlockType object.
    The function returns a list of tuples (sub_tile_type, index)
    """

    ptc_range = {}

    for pin_class in block.pin_class:
        for pin in pin_class.pin:

            # Decode the pin name
            tile, idx, sub_tile, name, bit = parse_block_pin_name(pin.name)

            if not sub_tile:
                sub_tile = tile

            # Update PTC range
            key = (sub_tile, idx)
            if key not in ptc_range:
                ptc_range[key] = [pin.ptc, pin.ptc]

            else:
                ptc_range[key] = [
                    min(ptc_range[key][0], pin.ptc),
                    max(ptc_range[key][1], pin.ptc),
                ]

    # Sort sub-tiles by their PTC ranges
    sub_tiles = list(ptc_range.keys())
    return sorted(sub_tiles, key=lambda st: ptc_range[st][0])

# =============================================================================


def add_track(graph, loc_beg, loc_end, segment_id, node_timing=None):
    """
    Adds a track to the graph. Returns the node object representing the track
    node.
    """

    # Cannot do diagonal
    assert loc_beg.x == loc_end.x or loc_beg.y == loc_end.y, (loc_beg, loc_end)

    # CHANX
    if loc_beg.x != loc_end.x:
        chan = "X"
        if loc_beg.x <= loc_end.x:
            direction = rr.NodeDirection.INC_DIR
        else:
            direction = rr.NodeDirection.DEC_DIR

    # CHANY
    elif loc_beg.y != loc_end.y:
        chan = "Y"
        if loc_beg.y <= loc_end.y:
            direction = rr.NodeDirection.INC_DIR
        else:
            direction = rr.NodeDirection.DEC_DIR

    # Shouldn't happen
    else:
        assert False, (loc_beg, loc_end)

    # Make delayless if no timing data is provided
    if node_timing is None:
        node_timing = rr.NodeTiming(r=0.0, c=0.0)

    # Create the Track object
    track = tracks.Track(
        direction=chan,
        x_low=min(loc_beg.x, loc_end.x),
        y_low=min(loc_beg.y, loc_end.y),
        x_high=max(loc_beg.x, loc_end.x),
        y_high=max(loc_beg.y, loc_end.y)
    )

    # Add it to the graph
    node_id = graph.add_track(
        track,
        segment_id,
        direction=direction,
        timing=node_timing
    )

    node = graph.nodes[-1]
    assert node.id == node_id

    return node


def add_node(graph, loc, chan, segment_id, node_timing=None):
    """
    Adds a track of length 1 to the graph. Returns the node object
    """

    # Make delayless if no timing data is provided
    if node_timing is None:
        node_timing = rr.NodeTiming(r=0.0, c=0.0)

    # Create the Track object
    track = tracks.Track(
        direction=chan,
        x_low=loc.x,
        y_low=loc.y,
        x_high=loc.x,
        y_high=loc.y,
    )

    # Add it to the graph
    node_id = graph.add_track(
        track,
        segment_id,
        direction=rr.NodeDirection.INC_DIR,
        timing=node_timing
    )

    node = graph.nodes[-1]
    assert node.id == node_id

    return node



def add_edge(
        graph, src_node_id, dst_node_id, switch_id, meta_name=None,
        meta_value=""
):
    """
    Adds an edge to the routing graph. If the given switch corresponds to a
    "pass" type switch then adds two edges going both ways.
    """

    # Sanity check
    assert src_node_id != dst_node_id, \
        (src_node_id, dst_node_id, switch_id, meta_name, meta_value)

    # Connect src to dst
    graph.add_edge(src_node_id, dst_node_id, switch_id, meta_name, meta_value)

    # Check if the switch is of the "pass" type. If so then add an edge going
    # in the opposite way.
    switch = graph.switch_map[switch_id]
    if switch.type in [rr.SwitchType.SHORT, rr.SwitchType.PASS_GATE]:

        graph.add_edge(
            dst_node_id, src_node_id, switch_id, meta_name, meta_value
        )


# =============================================================================


def node_joint_location(node_a, node_b):
    """
    Given two VPR nodes returns a location of the point where they touch each
    other.
    """

    loc_a1 = Loc(node_a.loc.x_low, node_a.loc.y_low, 0)
    loc_a2 = Loc(node_a.loc.x_high, node_a.loc.y_high, 0)

    loc_b1 = Loc(node_b.loc.x_low, node_b.loc.y_low, 0)
    loc_b2 = Loc(node_b.loc.x_high, node_b.loc.y_high, 0)

    if loc_a1 == loc_b1:
        return loc_a1
    if loc_a1 == loc_b2:
        return loc_a1
    if loc_a2 == loc_b1:
        return loc_a2
    if loc_a2 == loc_b2:
        return loc_a2

    assert False, (node_a, node_b)


def connect(
        graph,
        src_node,
        dst_node,
        switch_id=None,
        segment_id=None,
        meta_name=None,
        meta_value=""
):
    """
    Connect two VPR nodes in a way that certain rules are obeyed.

    The rules are:
    - a CHANX cannot connect directly to a CHANY and vice versa,
    - a CHANX cannot connect to an IPIN facing left or right,
    - a CHANY cannot connect to an IPIN facting top or bottom,
    - an OPIN facing left or right cannot connect to a CHANX,
    - an OPIN facing top or bottom cannot connect to a CHANY

    Whenever a rule is not met then the connection is made through a padding
    node:

      src -> [delayless] -> pad -> [desired switch] -> dst

    Otherwise the connection is made directly

      src -> [desired switch] -> dst

    The function returns the padding node object if one is inserted.

    The influence of whether the rules are obeyed or not on the actual VPR
    behavior is unclear.
    """

    # Use the default delayless switch if none is given
    if switch_id is None:
        switch_id = graph.get_delayless_switch_id()

    # Determine which segment to use if none given
    if segment_id is None:
        # If the source is IPIN/OPIN then use the same segment as used by
        # the destination.
        # If the destination is IPIN/OPIN then do the opposite.
        # Finally if both are CHANX/CHANY then use the source's segment.

        if src_node.type in [rr.NodeType.IPIN, rr.NodeType.OPIN]:
            segment_id = dst_node.segment.segment_id
        elif dst_node.type in [rr.NodeType.IPIN, rr.NodeType.OPIN]:
            segment_id = src_node.segment.segment_id
        else:
            segment_id = src_node.segment.segment_id

    # CHANX to CHANY or vice-versa
    if src_node.type == rr.NodeType.CHANX and dst_node.type == rr.NodeType.CHANY or \
       src_node.type == rr.NodeType.CHANY and dst_node.type == rr.NodeType.CHANX:

        # Check loc
        node_joint_location(src_node, dst_node)

        # Connect directly
        add_edge(
            graph, src_node.id, dst_node.id, switch_id, meta_name, meta_value
        )

        return None

    # CHANX to CHANX or CHANY to CHANY
    elif src_node.type == rr.NodeType.CHANX and dst_node.type == rr.NodeType.CHANX or \
         src_node.type == rr.NodeType.CHANY and dst_node.type == rr.NodeType.CHANY:

        loc = node_joint_location(src_node, dst_node)
        direction = "X" if src_node.type == rr.NodeType.CHANY else "Y"

        # Padding node
        pad_node = add_node(graph, loc, direction, segment_id)

        # Connect through the padding node
        add_edge(
            graph, src_node.id, pad_node.id, graph.get_delayless_switch_id()
        )

        add_edge(
            graph, pad_node.id, dst_node.id, switch_id, meta_name, meta_value
        )

        return pad_node

    # OPIN to CHANX/CHANY
    elif src_node.type == rr.NodeType.OPIN and dst_node.type in \
        [rr.NodeType.CHANX, rr.NodeType.CHANY]:

        # Allow only right or top
        assert src_node.loc.side in \
            [tracks.Direction.RIGHT, tracks.Direction.TOP], src_node

        # The pin goes right
        if src_node.loc.side == tracks.Direction.RIGHT:

            # Connected to CHANX
            if dst_node.type == rr.NodeType.CHANX:

                loc = node_joint_location(src_node, dst_node)

                # Padding node
                pad_node = add_node(graph, loc, "Y", segment_id)

                # Connect through the padding node
                add_edge(
                    graph, src_node.id, pad_node.id,
                    graph.get_delayless_switch_id()
                )

                add_edge(
                    graph, pad_node.id, dst_node.id, switch_id, meta_name,
                    meta_value
                )

                return pad_node

            # Connected to CHANY
            elif dst_node.type == rr.NodeType.CHANY:

                # Directly
                add_edge(
                    graph, src_node.id, dst_node.id, switch_id, meta_name,
                    meta_value
                )

                return None

            # Should not happen
            else:
                assert False, dst_node

        # The pin gors top
        elif src_node.loc.side == tracks.Direction.TOP:

            # Connected to CHANX
            if dst_node.type == rr.NodeType.CHANX:

                # Directly
                add_edge(
                    graph, src_node.id, dst_node.id, switch_id, meta_name,
                    meta_value
                )

                return None

            # Connected to CHANY
            elif dst_node.type == rr.NodeType.CHANY:

                loc = node_joint_location(src_node, dst_node)

                # Padding node
                pad_node = add_node(graph, loc, "X", segment_id)

                # Connect through the padding node
                add_edge(
                    graph, src_node.id, pad_node.id,
                    graph.get_delayless_switch_id()
                )

                add_edge(
                    graph, pad_node.id, dst_node.id, switch_id, meta_name,
                    meta_value
                )

                return pad_node

            # Should not happen
            else:
                assert False, dst_node

        # Shouldn't happen
        else:
            assert False, src_node

    # CHANX/CHANY to IPIN
    elif dst_node.type == rr.NodeType.IPIN and src_node.type in \
        [rr.NodeType.CHANX, rr.NodeType.CHANY]:

        # All IPINs go top (toward +Y)
        assert dst_node.loc.side == tracks.Direction.TOP, dst_node

        # Connected to CHANY
        if src_node.type == rr.NodeType.CHANY:

            loc = node_joint_location(src_node, dst_node)

            # Padding node
            pad_node = add_node(graph, loc, "X", segment_id)

            # Connect through the padding node
            add_edge(
                graph, src_node.id, pad_node.id,
                graph.get_delayless_switch_id()
            )

            add_edge(
                graph, pad_node.id, dst_node.id, switch_id, meta_name,
                meta_value
            )

            return pad_node

        # Connected to CHANX
        elif src_node.type == rr.NodeType.CHANX:

            # Directly
            add_edge(
                graph, src_node.id, dst_node.id, switch_id, meta_name,
                meta_value
            )

            return None

        # Should not happen
        else:
            assert False, dst_node

    # An unhandled case
    else:
        assert False, (src_node, dst_node)
