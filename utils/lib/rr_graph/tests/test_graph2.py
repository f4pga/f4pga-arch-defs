import unittest

from copy import deepcopy

from ..graph2 import SwitchTiming, SwitchSizing, Switch, SwitchType, \
    Graph, SegmentTiming, Segment, PinClass, Pin, PinType, \
    BlockType, GridLoc, NodeTiming, NodeSegment, Node, NodeType, \
    NodeDirection, NodeLoc
from ..tracks import Track, Direction


class Graph2Tests(unittest.TestCase):
    def setUp(self):
        switch_timing = SwitchTiming(
            r=0, c_in=1, c_out=2, t_del=0, c_internal=0
        )
        switch_sizing = SwitchSizing(mux_trans_size=0, buf_size=1)
        delayless = Switch(
            id=0,
            name='__vpr_delayless_switch__',
            type=SwitchType.SHORT,
            timing=switch_timing,
            sizing=switch_sizing
        )

        self.graph = Graph([delayless], [], [], [], [])

    def test_init(self):
        switch_timing = SwitchTiming(
            r=0, c_in=1, c_out=2, t_del=0, c_internal=0
        )
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
                segment=NodeSegment(segment_id=0),
                canonical_loc=None,
                connection_box=None,
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
                segment=NodeSegment(segment_id=0),
                canonical_loc=None,
                connection_box=None,
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
                segment=NodeSegment(segment_id=0),
                canonical_loc=None,
                connection_box=None,
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
                segment=NodeSegment(segment_id=0),
                canonical_loc=None,
                connection_box=None,
            ),
        ]

        self.graph = Graph(
            self.switches, self.segments, self.block_types, self.grid,
            deepcopy(self.nodes)
        )

    def test_add_track(self):
        trk = Track(direction='Y', x_low=2, x_high=2, y_low=1, y_high=3)
        segment_id = -1
        node_id = self.graph.add_track(trk, segment_id)
        self.assertEqual(len(self.graph.tracks), 1)
        self.assertEqual(len(self.graph.nodes), 1)

        node = self.graph.nodes[node_id]
        self.assertEqual(node.id, len(self.graph.nodes) - 1)
        self.assertEqual(node.type, NodeType.CHANY)
        self.assertEqual(node.direction, NodeDirection.BI_DIR)
        self.assertEqual(node.capacity, 1)

    def test_add_edge(self):
        trk = Track(direction='Y', x_low=2, x_high=2, y_low=1, y_high=3)
        segment_id = -1
        self.graph.add_track(trk, segment_id)

        trk = Track(direction='X', x_low=1, x_high=3, y_low=1, y_high=1)
        segment_id = -1
        self.graph.add_track(trk, segment_id)

        trk = Track(direction='X', x_low=1, x_high=3, y_low=3, y_high=3)
        segment_id = -1
        self.graph.add_track(trk, segment_id)

        idx = self.graph.add_edge(1, 2, 0)
        self.assertEqual(self.graph.edges[idx].src_node, 1)
        self.assertEqual(self.graph.edges[idx].sink_node, 2)
        self.assertEqual(self.graph.edges[idx].switch_id, 0)
        self.assertEqual(self.graph.edges[idx].metadata, None)

    def test_add_switch(self):
        idx = self.graph.add_switch(
            Switch(
                id=None,
                name='mux',
                type=SwitchType.MUX,
                timing=None,
                sizing=SwitchSizing(mux_trans_size=1, buf_size=0)
            )
        )

        self.assertEqual(idx, len(self.graph.switches) - 1)
        self.assertTrue('mux' in self.graph.switch_name_map.keys())

    def test_check_ptc(self):
        self.graph.check_ptc()

        trk = Track(direction='Y', x_low=2, x_high=2, y_low=1, y_high=3)
        segment_id = -1
        self.graph.add_track(trk, segment_id)

        with self.assertRaises(AssertionError):
            self.graph.check_ptc()

    def test_set_track_ptc(self):
        trk = Track(direction='Y', x_low=2, x_high=2, y_low=1, y_high=3)
        segment_id = -1
        node_id = self.graph.add_track(trk, segment_id)

        with self.assertRaises(AssertionError):
            self.graph.check_ptc()

        self.graph.set_track_ptc(node_id, 0)
        self.graph.check_ptc()

    def test_block_type_at_loc_asserts(self):
        loc = (0, 0)
        with self.assertRaises(KeyError):
            self.graph.block_type_at_loc(loc)

    def test_get_switch_id(self):
        with self.assertRaises(KeyError):
            self.graph.get_switch_id('mux')

        idx = self.graph.add_switch(
            Switch(
                id=None,
                name='mux',
                type=SwitchType.MUX,
                timing=None,
                sizing=SwitchSizing(mux_trans_size=1, buf_size=0)
            )
        )

        lu_idx = self.graph.get_switch_id('mux')
        self.assertEqual(idx, lu_idx)


class Graph2MediumTests(unittest.TestCase):
    def setUp(self):
        switch_timing = SwitchTiming(
            r=0, c_in=1, c_out=2, t_del=0, c_internal=0
        )
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

        pin_classes0 = [
            PinClass(type=PinType.INPUT, pin=[Pin(ptc=0, name='p1')]),
            PinClass(type=PinType.OUTPUT, pin=[Pin(ptc=1, name='p2')]),
        ]
        pin_classes1 = [
            PinClass(type=PinType.OUTPUT, pin=[Pin(ptc=1, name='p3')]),
        ]
        self.block_types = [
            BlockType(
                id=0, name='b0', width=1, height=1, pin_class=pin_classes0
            ),
            BlockType(
                id=1, name='b1', width=1, height=1, pin_class=pin_classes1
            ),
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
                segment=NodeSegment(segment_id=0),
                canonical_loc=None,
                connection_box=None,
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
                segment=NodeSegment(segment_id=0),
                canonical_loc=None,
                connection_box=None,
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
                segment=NodeSegment(segment_id=0),
                canonical_loc=None,
                connection_box=None,
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
                segment=NodeSegment(segment_id=0),
                canonical_loc=None,
                connection_box=None,
            ),
        ]

        self.graph = Graph(
            self.switches, self.segments, self.block_types, self.grid,
            deepcopy(self.nodes)
        )

    def test_block_type_at_loc(self):
        loc = (0, 0)
        name = self.graph.block_type_at_loc(loc)
        self.assertEqual(name, 'b0')

    def test_get_nodes_for_pin(self):
        nodes = self.graph.get_nodes_for_pin((0, 0), 'p1')
        self.assertEqual(nodes, [
            (0, Direction.LEFT),
        ])

        with self.assertRaises(KeyError):
            self.graph.get_nodes_for_pin((0, 0), 'd1')

        with self.assertRaises(AssertionError):
            self.graph.get_nodes_for_pin((0, 0), 'p3')

    def test_create_channels(self):
        pass
