import unittest

from ..graph2 import *
from ..tracks import Direction


class Graph2Tests(unittest.TestCase):
    def setUp(self):
        switch_timing = SwitchTiming(r=0, c_in=1, c_out=2, t_del=0)
        switch_sizing = SwitchSizing(mux_trans_size=0, buf_size=1)
        self.switches = [
            Switch(
                id=0,
                name='mux',
                type=SwitchType.MUX,
                timing=switch_timing,
                sizing=switch_sizing
            ),
            Switch(
                id=1,
                name='__vpr_delayless_switch__',
                type=SwitchType.SHORT,
                timing=switch_timing,
                sizing=switch_sizing
            ),
        ]

        seg_timing = SegmentTiming(r_per_meter=1, c_per_meter=1)
        self.segments = [Segment(id=0, name='s0', timing=seg_timing)]

        pin_classes = [
            PinClass(type=PinType.INPUT, pin=[Pin(ptc=0, name='p1')]),
            PinClass(type=PinType.OUTPUT, pin=[Pin(ptc=1, name='p2')]),
        ]
        self.block_types = [
            BlockType(
                id=0, name='b0', width=1, height=1, pin_class=pin_classes
            )
        ]

        self.grid = [
            GridLoc(
                x=0, y=0, block_type_id=0, width_offset=0, height_offset=0
            ),
        ]

        node_timing = NodeTiming(r=0, c=0)
        self.nodes = [
            Node(
                id=0,
                type=NodeType.IPIN,
                direction=NodeDirection.NO_DIR,
                capacity=1,
                loc=NodeLoc(
                    x_low=0,
                    x_high=0,
                    y_low=0,
                    y_high=0,
                    side=Direction.LEFT,
                    ptc=0
                ),
                timing=node_timing,
                metadata=None,
                segment=NodeSegment(segment_id=0)
            ),
            Node(
                id=1,
                type=NodeType.SINK,
                direction=NodeDirection.NO_DIR,
                capacity=1,
                loc=NodeLoc(
                    x_low=0,
                    x_high=0,
                    y_low=0,
                    y_high=0,
                    side=Direction.NO_SIDE,
                    ptc=0
                ),
                timing=node_timing,
                metadata=None,
                segment=NodeSegment(segment_id=0)
            ),
            Node(
                id=2,
                type=NodeType.OPIN,
                direction=NodeDirection.NO_DIR,
                capacity=1,
                loc=NodeLoc(
                    x_low=0,
                    x_high=0,
                    y_low=0,
                    y_high=0,
                    side=Direction.LEFT,
                    ptc=1
                ),
                timing=node_timing,
                metadata=None,
                segment=NodeSegment(segment_id=0)
            ),
            Node(
                id=3,
                type=NodeType.SOURCE,
                direction=NodeDirection.NO_DIR,
                capacity=1,
                loc=NodeLoc(
                    x_low=0,
                    x_high=0,
                    y_low=0,
                    y_high=0,
                    side=Direction.NO_SIDE,
                    ptc=1
                ),
                timing=node_timing,
                metadata=None,
                segment=NodeSegment(segment_id=0)
            ),
        ]

    def test_init(self):
        self.graph = Graph(
            self.switches, self.segments, self.block_types, self.grid,
            self.nodes
        )

    def test_add_track(self):
        pass

    def test_get_nodes_for_pin(self):
        pass

    def test_create_edge(self):
        pass

    def test_add_edge(self):
        pass

    def test_add_switch(self):
        pass

    def test_check_ptc(self):
        pass

    def test_set_track_ptc(self):
        pass

    def test_creat_channels(self):
        pass

    def test_block_type_at_loc(self):
        pass

    def test_get_switch_id(self):
        pass
