""" rr graph library that is not tied to the underlying serialization format
and provides simple fast lookup required to build real FPGA rr graph fabrics. """
from __future__ import print_function
from collections import namedtuple
from enum import Enum
from .tracks import Track, Direction
from lib.rr_graph import channel2
import progressbar

class SwitchType(Enum):
    INVALID_SWITCH_TYPE = 0
    MUX = 1
    TRISTATE = 2
    PASS_GATE = 3
    SHORT = 4
    BUFFER = 5

class NodeType(Enum):
    INVALID_NODE_TYPE = 0
    CHANX = 1
    CHANY = 2
    SOURCE = 3
    SINK = 4
    OPIN = 5
    IPIN = 6

class NodeDirection(Enum):
    NO_DIR = 0
    INC_DIR = 1
    DEC_DIR = 2
    BI_DIR = 3

class PinType(Enum):
    NONE = 0
    OPEN = 1
    OUTPUT = 2
    INPUT = 3

ChannelList = namedtuple('ChannelList', 'index info')
Channels = namedtuple('Channels', 'chan_width_max x_min y_min x_max y_max x_list y_list')

SwitchTiming = namedtuple('SwitchTiming', 'r c_in c_out t_del')
SwitchSizing = namedtuple('SwitchSizing', 'mux_trans_size buf_size')
Switch = namedtuple('Switch', 'id name type timing sizing')

SegmentTiming = namedtuple('SegmentTiming', 'r_per_meter c_per_meter')
Segment = namedtuple('Segment', 'id name timing')

Pin = namedtuple('Pin', 'ptc name')
PinClass = namedtuple('PinClass', 'type pin')
BlockType = namedtuple('BlockType', 'id name width height pin_class')

GridLoc = namedtuple('GridLoc', 'x y block_type_id width_offset height_offset')
NodeTiming = namedtuple('NodeTiming', 'r c')
NodeLoc = namedtuple('NodeLoc', 'x_low y_low x_high y_high side ptc')
NodeMetadata = namedtuple('NodeMetadata', 'name x_offset y_offset z_offset value')
NodeSegment = namedtuple('NodeSegment', 'segment_id')
Node = namedtuple('Node', 'id type direction capacity loc timing metadata segment')
Edge = namedtuple('Edge', 'src_node sink_node switch_id metadata')

GraphInput = namedtuple('GraphInput', 'switches segments block_types grid')

def process_track(track):
    channel_model = channel2.Channel(track)
    channel_model.pack_tracks()

    return channel_model

class Graph(object):
    """ Simple object for working with VPR RR graph. This class does not handle
    """
    def __init__(self, switches, segments, block_types, grid, nodes):
        self.switches = switches
        self.next_switch_id = max(switch.id for switch in self.switches)+1

        self.switch_name_map = {}
        self.delayless_switch = None

        for idx, switch in enumerate(self.switches):
            assert idx == switch.id
            assert switch.name not in self.switch_name_map
            self.switch_name_map[switch.name] = switch.id

        assert '__vpr_delayless_switch__' in self.switch_name_map, self.switch_name_map.keys()
        self.delayless_switch = self.switch_name_map['__vpr_delayless_switch__']

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
        self.edges = []

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
                    self.pin_name_map[pin.name] = (block_type.id, pin_class_idx, pin.ptc)
                    self.pin_ptc_to_name_map[(block_type.id, pin.ptc)] = pin.name

        # Create mapping from grid locations and pins to nodes.
        for idx, node in enumerate(self.nodes):
            assert node.id == idx, (idx, node)
            assert node.type in (
                    NodeType.IPIN,
                    NodeType.OPIN,
                    NodeType.SOURCE,
                    NodeType.SINK,
            ), node

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
                assert key not in self.loc_pin_class_map, (node, self.loc_pin_class_map[key])
                self.loc_pin_class_map[key] = node.id

        # Rebuild initial edges of IPIN -> SINK and SOURCE -> OPIN.
        for loc in grid:
            assert loc.block_type_id >= 0 and loc.block_type_id <= len(self.block_types), loc.block_type_id
            block_type = self.block_types[loc.block_type_id]

            key = (loc.x, loc.y)
            assert key not in self.loc_map
            self.loc_map[key] = loc

            for pin_class_idx, pin_class in enumerate(block_type.pin_class):
                pin_class_node = self.loc_pin_class_map[(loc.x, loc.y, pin_class_idx)]
                for pin in pin_class.pin:
                    for pin_node, _ in self.loc_pin_map[(loc.x, loc.y, pin.ptc)]:
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

    def _create_node(self, type, direction, loc, segment, timing, capacity=1,
                      metadata=None):

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
                        segment=segment)
        )

        return self.nodes[-1].id

    def get_segment_id_from_name(self, segment_name):
        return self.segment_name_map[segment_name]

    def get_delayless_switch_id(self):
        return self.delayless_switch

    def add_track(self, track, segment_id, capacity=1, timing=None, name=None, ptc=None):
        if track.direction == 'X':
            node_type = NodeType.CHANX
        elif track.direction == 'Y':
            node_type = NodeType.CHANY
        else:
            assert False, track

        if name is not None:
            metadata = [NodeMetadata(
                    name=name,
                    x_offset=0,
                    y_offset=0,
                    z_offset=0,
                    value='',
            )]
        else:
            metadata = None

        self.tracks.append(self._create_node(
            type=node_type,
            direction=NodeDirection.BI_DIR,
            capacity=capacity,
            loc=NodeLoc(
                    x_low=track.x_low,
                    y_low=track.y_low,
                    x_high=track.x_high,
                    y_high=track.y_high,
                    side=Direction.NO_SIDE,
                    ptc=ptc,
            ),
            timing=timing,
            segment=NodeSegment(segment_id=segment_id),
            metadata=metadata,
        ))

        return self.tracks[-1]

    def create_pin_name_from_tile_type_and_pin(self, tile_type, port_name, pin_idx=0):
        return '{}.{}[{}]'.format(tile_type, port_name, pin_idx)

    def get_nodes_for_pin(self, loc, pin_name):
        block_type_id, pin_class_idx, pin_idx = self.pin_name_map[pin_name]
        grid_loc = self.loc_map[loc]
        assert grid_loc.block_type_id == block_type_id

        return self.loc_pin_map[(loc[0], loc[1], pin_idx)]

    def create_edge(self, src_node, sink_node, switch_id, name=None, value=''):
        assert src_node >= 0 and src_node < len(self.nodes), src_node
        assert sink_node >= 0 and sink_node < len(self.nodes), sink_node
        assert switch_id >= 0 and switch_id < len(self.switches), switch_id

        if name is not None:
            metadata = [NodeMetadata(
                    name=name,
                    x_offset=0,
                    y_offset=0,
                    z_offset=0,
                    value=value
            )]
        else:
            metadata = None

        return Edge(
                src_node=src_node,
                sink_node=sink_node,
                switch_id=switch_id,
                metadata=metadata
        )

    def add_edge(self, src_node, sink_node, switch_id, name=None, value=''):
        self.edges.append(self.create_edge(
            src_node=src_node,
            sink_node=sink_node,
            switch_id=switch_id,
            name=name,
            value=value))

        return len(self.edges)-1

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

                if track_node.loc.y_low not in x_tracks:
                    x_tracks[track_node.loc.y_low] = []

                x_tracks[track_node.loc.y_low].append((
                        track_node.loc.x_low,
                        track_node.loc.x_high,
                        track))
            elif track_node.type == NodeType.CHANY:
                assert track_node.loc.x_low == track_node.loc.x_high

                if track_node.loc.x_low not in y_tracks:
                    y_tracks[track_node.loc.x_low] = []

                y_tracks[track_node.loc.x_low].append((
                        track_node.loc.y_low,
                        track_node.loc.y_high,
                        track))
            else:
                assert False, track_node

        x_list = []
        y_list = []

        x_channel_models = {}
        y_channel_models = {}

        if pool is not None:
            for y in x_tracks:
                x_channel_models[y] = pool.apply_async(process_track, (x_tracks[y],))

            for x in y_tracks:
                y_channel_models[x] = pool.apply_async(process_track, (y_tracks[x],))

        for y in progressbar.progressbar(range(max(x_tracks)+1)):
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

        for x in progressbar.progressbar(range(max(y_tracks)+1)):
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

        x_min=min(xs)
        y_min=min(ys)
        x_max=max(xs)
        y_max=max(ys)

        num_padding = 0
        for chan, channel_model in x_channel_models.items():
            for ptc, start, end in channel_model.fill_empty(x_min, x_max):
                num_padding += 1
                track_idx = self.add_track(
                        track=Track(
                                direction='X',
                                x_low=start,
                                y_low=chan,
                                x_high=end,
                                y_high=chan,
                        ),
                        segment_id=pad_segment,
                        capacity=0,
                        timing=None)

                self.set_track_ptc(track_idx, ptc)

        for chan, channel_model in y_channel_models.items():
            for ptc, start, end in channel_model.fill_empty(y_min, y_max):
                num_padding += 1
                track_idx = self.add_track(
                        track=Track(
                                direction='Y',
                                x_low=chan,
                                y_low=start,
                                x_high=chan,
                                y_high=end,
                        ),
                        segment_id=pad_segment,
                        capacity=0,
                        timing=None)

                self.set_track_ptc(track_idx, ptc)

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
