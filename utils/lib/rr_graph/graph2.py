""" rr graph library that is not tied to the underlying serialization format
and provides simple fast lookup required to build real FPGA rr graph fabrics.
"""

from __future__ import print_function
from collections import namedtuple
from enum import Enum
from .tracks import Track
from lib.rr_graph import channel2
from lib import progressbar_utils


class SwitchType(Enum):
    """Enumeration of allowed VPR switch type
    See: https://vtr-verilog-to-routing.readthedocs.io/en/latest/vpr/file_formats.html#tag-switches-switch
    """  # noqa: E501
    INVALID_SWITCH_TYPE = 0
    MUX = 1
    TRISTATE = 2
    PASS_GATE = 3
    SHORT = 4
    BUFFER = 5


class NodeType(Enum):
    """VPR Node type. This is a superset of Type in channel.py
    See: https://vtr-verilog-to-routing.readthedocs.io/en/latest/vpr/file_formats.html#tag-nodes-node
    """  # noqa: E501
    INVALID_NODE_TYPE = 0
    CHANX = 1
    CHANY = 2
    SOURCE = 3
    SINK = 4
    OPIN = 5
    IPIN = 6


class NodeDirection(Enum):
    """VPR Node Direction. This is a superset of Direction in channel.py
    See: https://vtr-verilog-to-routing.readthedocs.io/en/latest/vpr/file_formats.html#tag-nodes-node
    """  # noqa: E501
    NO_DIR = 0
    INC_DIR = 1
    DEC_DIR = 2
    BI_DIR = 3


class PinType(Enum):
    """Enum for PinClass type
    See: https://vtr-verilog-to-routing.readthedocs.io/en/latest/vpr/file_formats.html#tag-blocks-pin_class
    """  # noqa: E501
    NONE = 0
    OPEN = 1
    OUTPUT = 2
    INPUT = 3


class ChannelList(namedtuple('ChannelList', 'index info')):
    """VPR `x_list` and `y_list` tags in the channels
    """


class Channels(namedtuple(
        'Channels', 'chan_width_max x_min y_min x_max y_max x_list y_list')):
    """Encapsulation for VPR channels tag
    See: https://vtr-verilog-to-routing.readthedocs.io/en/latest/vpr/file_formats.html#tag-channel-channel
    """  # noqa: E501


class SwitchTiming(namedtuple('SwitchTiming',
                              'r c_in c_out c_internal t_del p_cost')):
    """Encapsulation for timing attributes of a VPR switch
    see: https://vtr-verilog-to-routing.readthedocs.io/en/latest/arch/reference.html#switches
    """


class SwitchSizing(namedtuple('SwitchSizing', 'mux_trans_size buf_size')):
    """Encapsulation for sizing attributes of a VPR switch
    see: https://vtr-verilog-to-routing.readthedocs.io/en/latest/arch/reference.html#switches
    """


class Switch(namedtuple('Switch', 'id name type timing sizing')):
    """Encapsulate VPR switch tag. Contains SwitchTiming and SwitchSizing tuples.
    see: https://vtr-verilog-to-routing.readthedocs.io/en/latest/arch/reference.html#switches
    """


class SegmentTiming(namedtuple('SegmentTiming', 'r_per_meter c_per_meter')):
    """Encapsulation for timing attributes of a VPR segment.
    see: https://vtr-verilog-to-routing.readthedocs.io/en/latest/arch/reference.html#wire-segments
    """


class Segment(namedtuple('Segment', 'id name timing')):
    """Encapsulate VPR segment tag. Contains SegmentTiming to encapsulate the timing attributes
    see: https://vtr-verilog-to-routing.readthedocs.io/en/latest/arch/reference.html#wire-segments
    """


class Pin(namedtuple('Pin', 'ptc name')):
    """Encapsulation for VPR Pin tag
    See: https://vtr-verilog-to-routing.readthedocs.io/en/latest/vpr/file_formats.html#tag-blocks-pin
    """  # noqa: E501


class PinClass(namedtuple('PinClass', 'type pin')):
    """Encapsulation for VPR PinClass tag
    See: https://vtr-verilog-to-routing.readthedocs.io/en/latest/vpr/file_formats.html#tag-blocks-pin_class
    """  # noqa: E501


class BlockType(namedtuple('BlockType', 'id name width height pin_class')):
    """Encapsulation for VPR BlockType tag
    See: https://vtr-verilog-to-routing.readthedocs.io/en/latest/vpr/file_formats.html#tag-blocks-block_type
    """  # noqa: E501


class GridLoc(namedtuple('GridLoc',
                         'x y block_type_id width_offset height_offset')):
    """
    """


class NodeTiming(namedtuple('NodeTiming', 'r c')):
    """https://vtr-verilog-to-routing.readthedocs.io/en/latest/vpr/file_formats.html#tag-nodes-timing
    """


class NodeLoc(namedtuple('NodeLoc', 'x_low y_low x_high y_high side ptc')):
    """https://vtr-verilog-to-routing.readthedocs.io/en/latest/vpr/file_formats.html#tag-nodes-loc
    """


class NodeMetadata(namedtuple('NodeMetadata',
                              'name x_offset y_offset z_offset value')):
    """https://vtr-verilog-to-routing.readthedocs.io/en/latest/arch/reference.html#architecture-metadata
    """


class NodeSegment(namedtuple('NodeSegment', 'segment_id')):
    """https://vtr-verilog-to-routing.readthedocs.io/en/latest/vpr/file_formats.html#tag-nodes-segment
    """


class CanonicalLoc(namedtuple('CanonicalLoc', 'x y')):
    """ Canonical location of channel node.

    The canonical location of the node is an unambigous location for the given
    node in the "canonical grid".  For example, on an L-shaped wire, the
    canonical location is the location of the input edge.

    """
    pass


class ConnectionBox(namedtuple('ConnectionBox', 'x y id site_pin_delay')):
    """ Connection box location and definition.

    The connection box location is the place in the "canonical grid" where
    a IPIN is connected too. This allows lookahead from a routing channel
    to the IPIN connection box, which uses the regular interconnect fabric.

    Attributes
    ----------
    x, y : int
        Canonical location of connection box for IPIN.
    id : int
        0-based index into ConnectionBoxes.boxes vector of connection box names.
    site_pin_delay : float

    """
    pass


class ConnectionBoxes(namedtuple('ConnectionBoxes', 'x_dim y_dim boxes')):
    """ Definition of the canonical routing grid.

    Attributes
    ----------
    x_dim, y_dim : int
        Dimensions of the canonical grid.  All ConnectionBox and CanonicalLoc
        coordinates should be [0, x_dim), [0, y_dim).
    boxes : list of str
        List of names for connection boxes.
    """
    pass


class Node(namedtuple(
        'Node',
        'id type direction capacity loc timing metadata segment canonical_loc connection_box'
)):
    """https://vtr-verilog-to-routing.readthedocs.io/en/latest/vpr/file_formats.html#tag-nodes-node
    """


class Edge(namedtuple('Edge', 'src_node sink_node switch_id metadata')):
    """https://vtr-verilog-to-routing.readthedocs.io/en/latest/vpr/file_formats.html#tag-edges-edge
    """


class GraphInput(namedtuple('GraphInput',
                            'switches segments block_types grid')):
    """Top level encapsulation of input Graph
    """


def process_track(track):
    channel_model = channel2.Channel(track)
    channel_model.pack_tracks()

    return channel_model


class Graph(object):
    """ Simple object for working with VPR RR graph.

    This class does not handle serialization.  A format specific class handles
    serdes takes.
    """

    def __init__(
            self,
            switches,
            segments,
            block_types,
            grid,
            nodes,
            edges=None,
            build_pin_edges=True
    ):
        self.switches = switches
        self.next_switch_id = max(switch.id for switch in self.switches) + 1

        self.switch_name_map = {}
        self.delayless_switch = None

        for idx, switch in enumerate(self.switches):
            assert idx == switch.id
            assert switch.name not in self.switch_name_map
            self.switch_name_map[switch.name] = switch.id

        assert '__vpr_delayless_switch__' in self.switch_name_map, self.switch_name_map.keys(
        )
        self.delayless_switch = self.switch_name_map['__vpr_delayless_switch__'
                                                     ]

        self.segments = segments
        self.segment_name_map = {}

        for idx, segment in enumerate(self.segments):
            assert idx == segment.id
            assert segment.name not in self.segment_name_map
            self.segment_name_map[segment.name] = segment.id

        self.block_types = block_types
        self.grid = grid

        self.tracks = []
        self.nodes = nodes
        self.nodes.sort(key=lambda node: node.id)
        self.edges = edges if edges is not None else []

        self.connection_boxes = []
        self.connection_box_map = {}

        # Map of (x, y) to GridLoc definitions.
        self.loc_map = {}

        # Maps grid location and pin class index to node index
        # (x, y, pin class idx) -> node_idx
        self.loc_pin_class_map = {}

        # Maps grid location and pin index to node index
        # (x, y, pin idx) -> [(node_idx, side)]
        self.loc_pin_map = {}

        # Maps pin name to block type id and pin idx.
        # pin name -> block type id, pin class idx, pin idx
        self.pin_name_map = {}

        self.pin_ptc_to_name_map = {}

        # Create pin_name_map and sanity check block_types.
        for idx, block_type in enumerate(self.block_types):
            assert idx == block_type.id
            for pin_class_idx, pin_class in enumerate(block_type.pin_class):
                for pin in pin_class.pin:
                    assert pin.name not in self.pin_name_map
                    self.pin_name_map[
                        pin.name] = (block_type.id, pin_class_idx, pin.ptc)
                    self.pin_ptc_to_name_map[(block_type.id,
                                              pin.ptc)] = pin.name

        # Create mapping from grid locations and pins to nodes.
        for idx, node in enumerate(self.nodes):
            assert node.id == idx, (idx, node)

            if node.type in (
                    NodeType.IPIN,
                    NodeType.OPIN,
            ):
                key = (node.loc.x_low, node.loc.y_low, node.loc.ptc)
                if key not in self.loc_pin_map:
                    self.loc_pin_map[key] = []
                self.loc_pin_map[key].append((node.id, node.loc.side))

            if node.type in (
                    NodeType.SOURCE,
                    NodeType.SINK,
            ):
                key = (node.loc.x_low, node.loc.y_low, node.loc.ptc)
                assert key not in self.loc_pin_class_map, (
                    node, self.loc_pin_class_map[key]
                )
                self.loc_pin_class_map[key] = node.id

        # Rebuild initial edges of IPIN -> SINK and SOURCE -> OPIN.
        for loc in grid:
            assert loc.block_type_id >= 0 and loc.block_type_id <= len(
                self.block_types
            ), loc.block_type_id
            block_type = self.block_types[loc.block_type_id]

            key = (loc.x, loc.y)
            assert key not in self.loc_map
            self.loc_map[key] = loc

            for pin_class_idx, pin_class in enumerate(block_type.pin_class):
                pin_class_node = self.loc_pin_class_map[
                    (loc.x, loc.y, pin_class_idx)]

                # Skip building IPIN -> SINK and OPIN -> SOURCE graph if edges
                # are not required.
                if not build_pin_edges:
                    continue

                for pin in pin_class.pin:
                    for pin_node, _ in self.loc_pin_map[(loc.x, loc.y,
                                                         pin.ptc)]:
                        if pin_class.type == PinType.OUTPUT:
                            self.add_edge(
                                src_node=pin_class_node,
                                sink_node=pin_node,
                                switch_id=self.delayless_switch
                            )
                        elif pin_class.type == PinType.INPUT:
                            self.add_edge(
                                src_node=pin_node,
                                sink_node=pin_class_node,
                                switch_id=self.delayless_switch,
                            )
                        else:
                            assert False, (loc, pin_class)

    def maybe_add_connection_box(self, box):
        """ Get id for connection box name.

        If connection box was not declared previously, assign an id for it.

        Arugments
        ---------
        box : str
            Name of connection box.
        """
        if box not in self.connection_box_map:
            idx = len(self.connection_boxes)
            self.connection_boxes.append(box)
            self.connection_box_map[box] = idx
            return idx
        else:
            return self.connection_box_map[box]

    def create_connection_box_object(self, x_dim, y_dim):
        """ Create ConnectionBoxes object defining canonical grid. """
        return ConnectionBoxes(
            x_dim=x_dim,
            y_dim=y_dim,
            boxes=tuple(self.connection_boxes),
        )

    def _create_node(
            self,
            type,
            direction,
            loc,
            segment,
            timing,
            capacity=1,
            metadata=None,
            canonical_loc=None,
            connection_box=None,
    ):

        if timing is None:
            if type in (NodeType.CHANX, NodeType.CHANY):
                timing = NodeTiming(r=1, c=1)
            else:
                timing = NodeTiming(r=0, c=0)

        self.nodes.append(
            Node(
                id=len(self.nodes),
                type=type,
                direction=direction,
                capacity=capacity,
                loc=loc,
                timing=timing,
                metadata=metadata,
                segment=segment,
                canonical_loc=canonical_loc,
                connection_box=connection_box,
            )
        )

        return self.nodes[-1].id

    def get_segment_id_from_name(self, segment_name):
        return self.segment_name_map[segment_name]

    def get_delayless_switch_id(self):
        return self.delayless_switch

    def add_track(
            self,
            track,
            segment_id,
            capacity=1,
            timing=None,
            name=None,
            ptc=None,
            direction=NodeDirection.BI_DIR,
            canonical_loc=None,
            connection_box=None,
    ):
        """Take a Track and add node to the graph with supplimental data"""

        if track.direction == 'X':
            node_type = NodeType.CHANX
        elif track.direction == 'Y':
            node_type = NodeType.CHANY
        else:
            assert False, track

        if name is not None:
            metadata = [
                NodeMetadata(
                    name=name,
                    x_offset=0,
                    y_offset=0,
                    z_offset=0,
                    value='',
                )
            ]
        else:
            metadata = None

        self.tracks.append(
            self._create_node(
                type=node_type,
                direction=direction,
                capacity=capacity,
                loc=NodeLoc(
                    x_low=track.x_low,
                    y_low=track.y_low,
                    x_high=track.x_high,
                    y_high=track.y_high,
                    side=None,
                    ptc=ptc,
                ),
                timing=timing,
                segment=NodeSegment(segment_id=segment_id),
                metadata=metadata,
                canonical_loc=canonical_loc,
                connection_box=connection_box,
            )
        )

        return self.tracks[-1]

    def create_pin_name_from_tile_type_and_pin(
            self, tile_type, port_name, pin_idx=0
    ):
        return '{}.{}[{}]'.format(tile_type, port_name, pin_idx)

    def create_pin_name_from_tile_type_sub_tile_num_and_pin(
            self, tile_type, sub_tile_num, port_name, pin_idx=0
    ):
        return '{}[{}].{}[{}]'.format(
            tile_type, sub_tile_num, port_name, pin_idx
        )

    def get_nodes_for_pin(self, loc, pin_name):
        block_type_id, pin_class_idx, pin_idx = self.pin_name_map[pin_name]
        grid_loc = self.loc_map[loc]
        assert grid_loc.block_type_id == block_type_id

        return self.loc_pin_map[(loc[0], loc[1], pin_idx)]

    def _create_edge(
            self, src_node, sink_node, switch_id, name=None, value=''
    ):
        assert src_node >= 0 and src_node < len(self.nodes), src_node
        assert sink_node >= 0 and sink_node < len(self.nodes), sink_node
        assert switch_id >= 0 and switch_id < len(self.switches), switch_id

        if name is not None:
            metadata = [
                NodeMetadata(
                    name=name, x_offset=0, y_offset=0, z_offset=0, value=value
                )
            ]
        else:
            metadata = None

        return Edge(
            src_node=src_node,
            sink_node=sink_node,
            switch_id=switch_id,
            metadata=metadata
        )

    def add_edge(self, src_node, sink_node, switch_id, name=None, value=''):
        """Add Edge to the graph

        Appends a new edge to the graph and retruns the index in the edges list
        """
        self.edges.append(
            self._create_edge(
                src_node=src_node,
                sink_node=sink_node,
                switch_id=switch_id,
                name=name,
                value=value
            )
        )

        return len(self.edges) - 1

    def add_switch(self, switch):
        """ Inner add_switch method.  Do not invoke directly.

        This method adds a switch into the graph model.  This method should
        not be invoked directly, instead invoke add_switch on the serialization
        graph object (e.g. rr_graph_xml.graph2.add_switch, etc).

        """

        switch_dict = switch._asdict()
        switch_dict['id'] = self.next_switch_id
        self.next_switch_id += 1

        switch = Switch(**switch_dict)

        assert switch.name not in self.switch_name_map
        self.switch_name_map[switch.name] = switch.id
        self.switches.append(switch)

        return switch.id

    def check_ptc(self):
        for node in self.nodes:
            assert node.loc.ptc is not None, node

    def set_track_ptc(self, track, ptc):
        node_d = self.nodes[track]._asdict()
        loc_d = self.nodes[track].loc._asdict()
        assert loc_d['ptc'] is None
        loc_d['ptc'] = ptc
        node_d['loc'] = NodeLoc(**loc_d)

        self.nodes[track] = Node(**node_d)

    def create_channels(self, pad_segment, pool=None):
        """ Pack tracks into channels and return Channels definition for tracks."""
        assert len(self.tracks) > 0

        xs = []
        ys = []

        for track in self.tracks:
            track_node = self.nodes[track]

            xs.append(track_node.loc.x_low)
            xs.append(track_node.loc.x_high)
            ys.append(track_node.loc.y_low)
            ys.append(track_node.loc.y_high)

        x_tracks = {}
        y_tracks = {}

        for track in self.tracks:
            track_node = self.nodes[track]

            if track_node.type == NodeType.CHANX:
                assert track_node.loc.y_low == track_node.loc.y_high

                x1, x2 = sorted((track_node.loc.x_low, track_node.loc.x_high))

                if track_node.loc.y_low not in x_tracks:
                    x_tracks[track_node.loc.y_low] = []

                x_tracks[track_node.loc.y_low].append((x1, x2, track))
            elif track_node.type == NodeType.CHANY:
                assert track_node.loc.x_low == track_node.loc.x_high

                y1, y2 = sorted((track_node.loc.y_low, track_node.loc.y_high))

                if track_node.loc.x_low not in y_tracks:
                    y_tracks[track_node.loc.x_low] = []

                y_tracks[track_node.loc.x_low].append((y1, y2, track))
            else:
                assert False, track_node

        x_list = []
        y_list = []

        x_channel_models = {}
        y_channel_models = {}

        if pool is not None:
            for y in x_tracks:
                x_channel_models[y] = pool.apply_async(
                    process_track, (x_tracks[y], )
                )

            for x in y_tracks:
                y_channel_models[x] = pool.apply_async(
                    process_track, (y_tracks[x], )
                )

        for y in progressbar_utils.progressbar(range(max(x_tracks) + 1)):
            if y in x_tracks:
                if pool is None:
                    x_channel_models[y] = process_track(x_tracks[y])
                else:
                    x_channel_models[y] = x_channel_models[y].get()

                x_list.append(len(x_channel_models[y].trees))
                for idx, tree in enumerate(x_channel_models[y].trees):
                    for i in tree:
                        self.set_track_ptc(track=i[2], ptc=idx)
            else:
                x_list.append(0)

        for x in progressbar_utils.progressbar(range(max(y_tracks) + 1)):
            if x in y_tracks:
                if pool is None:
                    y_channel_models[x] = process_track(y_tracks[x])
                else:
                    y_channel_models[x] = y_channel_models[x].get()

                y_list.append(len(y_channel_models[x].trees))
                for idx, tree in enumerate(y_channel_models[x].trees):
                    for i in tree:
                        self.set_track_ptc(track=i[2], ptc=idx)
            else:
                y_list.append(0)

        x_min = min(xs)
        y_min = min(ys)
        x_max = max(xs)
        y_max = max(ys)

        num_padding = 0
        for chan, channel_model in x_channel_models.items():
            for ptc, start, end in channel_model.fill_empty(max(x_min, 1),
                                                            x_max):
                num_padding += 1
                self.add_track(
                    track=Track(
                        direction='X',
                        x_low=start,
                        y_low=chan,
                        x_high=end,
                        y_high=chan,
                    ),
                    segment_id=pad_segment,
                    capacity=0,
                    timing=None,
                    ptc=ptc
                )

        for chan, channel_model in y_channel_models.items():
            for ptc, start, end in channel_model.fill_empty(max(y_min, 1),
                                                            y_max):
                num_padding += 1
                self.add_track(
                    track=Track(
                        direction='Y',
                        x_low=chan,
                        y_low=start,
                        x_high=chan,
                        y_high=end,
                    ),
                    segment_id=pad_segment,
                    capacity=0,
                    timing=None,
                    ptc=ptc
                )

        print('Number padding nodes {}'.format(num_padding))

        return Channels(
            chan_width_max=max(max(x_list), max(y_list)),
            x_min=x_min,
            y_min=y_min,
            x_max=x_max,
            y_max=y_max,
            x_list=[ChannelList(idx, info) for idx, info in enumerate(x_list)],
            y_list=[ChannelList(idx, info) for idx, info in enumerate(y_list)],
        )

    def block_type_at_loc(self, loc):
        return self.block_types[self.loc_map[loc].block_type_id].name

    def get_switch_id(self, switch_name):
        return self.switch_name_map[switch_name]

    def sort_nodes(self):
        self.nodes.sort(key=lambda node: node.id)
