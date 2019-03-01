#!/usr/bin/env python3
# Run `python3 -m unittest utils.lib.rr_graph.tests.test_graph`
import unittest

from .. import graph, P, Size
from ..graph import (Pin, PinClass, PinClassDirection, Block, BlockGrid, BlockType, Segment,
    Switch, SwitchType, RoutingGraph, RoutingGraphPrinter, RoutingNodeType)

import lxml.etree as ET

class TestGraph(unittest.TestCase):

    def test_parse_net(self):
        # Fully specified
        self.assertEqual(
            ('a', 'b', [0]),
            graph.parse_net('a.b[0]')
        )
        self.assertEqual(
            ('c', 'd', [1]),
            graph.parse_net('c.d[1]')
        )
        self.assertEqual(
            ('c', 'd', [40]),
            graph.parse_net('c.d[40]')
        )
        self.assertEqual(
            ('BLK_BB-VPR_PAD', 'outpad', [0]),
            graph.parse_net('BLK_BB-VPR_PAD.outpad[0]')
        )
        # Complex block names
        self.assertEqual(
            ('a.b', 'c', [0]),
            graph.parse_net('a.b.c[0]')
        )
        self.assertEqual(
            ('c-d', 'e', [11]),
            graph.parse_net('c-d.e[11]')
        )
        # Block names w/ square brackets
        self.assertEqual(
            ('a.b[2]', 'c', [0]),
            graph.parse_net('a.b[2].c[0]')
        )
        self.assertEqual(
            ('c-d[3]', 'e', [11]),
            graph.parse_net('c-d[3].e[11]')
        )
        # Fully specified range of pins
        self.assertEqual(
            ('a', 'b', [8, 9, 10, 11]),
            graph.parse_net('a.b[11:8]')
        )
        self.assertEqual(
            ('c', 'd', [8, 9, 10, 11]),
            graph.parse_net('c.d[8:11]')
        )
        # Net with no block
        self.assertEqual(
            (None, 'outpad', [10]),
            graph.parse_net('outpad[10]')
        )
        self.assertEqual(
            (None, 'outpad', [10, 11, 12]),
            graph.parse_net('outpad[10:12]')
        )
        self.assertEqual(
            (None, 'outpad', [10, 11, 12]),
            graph.parse_net('outpad[12:10]')
        )
        # No block or pin index
        self.assertEqual(
            (None, 'outpad', None),
            graph.parse_net('outpad')
        )
        self.assertEqual(
            (None, 'outpad0', None),
            graph.parse_net('outpad0')
        )
        self.assertEqual(
            (None, '0outpad', None),
            graph.parse_net('0outpad')
        )
        self.assertEqual(
            (None, None, [0]),
            graph.parse_net('0')
        )


    def test_pin_from_text(self):
        self.assertEqual(
            'None(0)->None[None]',
            str(Pin.from_text(None, '0'))
        )
        self.assertEqual(
            'None(10)->None[None]',
            str(Pin.from_text(None, '10'))
        )
        self.assertEqual(
            'bt(None)->outpad[2]',
            str(Pin.from_text(None, 'bt.outpad[2]'))
        )
        self.assertEqual(
            'bt[3](None)->outpad[2]',
            str(Pin.from_text(None, 'bt[3].outpad[2]'))
        )


    def test_pin_from_xml(self):
        pc = PinClass(BlockType(name="bt"), direction=PinClassDirection.INPUT)
        xml_string = '<pin ptc="1">bt.outpad[2]</pin>'
        pin = Pin.from_xml(pc, ET.fromstring(xml_string))
        self.assertEqual(
            'bt(1)->outpad[2]',
            str(pin)
        )
        self.assertEqual(
            1,
            pin.ptc
        )


    def test_pinclass_port_name(self):
        bg = BlockGrid()
        bt = BlockType(g=bg, id=0, name="B")
        c1 = PinClass(block_type=bt, direction=PinClassDirection.OUTPUT)
        c2 = PinClass(block_type=bt, direction=PinClassDirection.OUTPUT)
        c3 = PinClass(block_type=bt, direction=PinClassDirection.OUTPUT)
        p0 = Pin(pin_class=c1, port_name="P1", port_index=0)
        p1 = Pin(pin_class=c2, port_name="P1", port_index=1)
        p2 = Pin(pin_class=c2, port_name="P1", port_index=2)
        p3 = Pin(pin_class=c2, port_name="P1", port_index=3)
        p4 = Pin(pin_class=c3, port_name="P2", port_index=0)
        self.assertEqual(
            'P1[0]',
            c1.port_name
        )
        self.assertEqual(
            'P1[3:1]',
            c2.port_name
        )
        self.assertEqual(
            'P2[0]',
            c3.port_name
        )


    def test_pinclass_from_xml(self):
        bt = BlockType(name="bt")
        xml_string1 = '''
        <pin_class type="INPUT">
            <pin ptc="2">bt.outpad[3]</pin>
            <pin ptc="3">bt.outpad[4]</pin>
        </pin_class>
        '''
        pc = PinClass.from_xml(bt, ET.fromstring(xml_string1))
        self.assertEqual(
            2,
            len(pc.pins)
        )
        self.assertEqual(
            'outpad[4:3]',
            pc.port_name
        )

        bt = BlockType(name="a")
        xml_string2 = '''
        <pin_class type="INPUT">
            <pin ptc="0">a.b[1]</pin>
        </pin_class>
        '''
        pc = PinClass.from_xml(bt, ET.fromstring(xml_string2))
        self.assertEqual(
            1,
            len(pc.pins)
        )

        xml_string3 = '''
        <pin_class type="OUTPUT">
            <pin ptc="2">a.b[5]</pin>
            <pin ptc="3">a.b[6]</pin>
            <pin ptc="4">a.b[7]</pin>
        </pin_class>
        '''
        pc = PinClass.from_xml(bt, ET.fromstring(xml_string3))
        self.assertEqual(
            3,
            len(pc.pins)
        )


    def test_blocktype_from_xml(self):
        xml_string = '''
        <block_type id="1" name="BLK_BB-VPR_PAD" width="2" height="3">
            <pin_class type="OUTPUT">
                <pin ptc="0">BLK_BB-VPR_PAD.outpad[0]</pin>
            </pin_class>
            <pin_class type="OUTPUT">
                <pin ptc="1">BLK_BB-VPR_PAD.outpad[1]</pin>
            </pin_class>
            <pin_class type="INPUT">
                <pin ptc="2">BLK_BB-VPR_PAD.inpad[0]</pin>
            </pin_class>
        </block_type>
        '''
        bt = BlockType.from_xml(None, ET.fromstring(xml_string))
        self.assertEqual(
            3,
            len(bt.pin_classes)
        )
        self.assertEqual(
            'PCD.OUTPUT',
            str(bt.pin_classes[0].direction)
        )
        self.assertEqual(
            'PCD.INPUT',
            str(bt.pin_classes[2].direction)
        )

        # Multiple pins in a single pinclass
        xml_string = '''
        <block_type id="1" name="BLK_BB-VPR_PAD" width="2" height="3">
            <pin_class type="OUTPUT">
                <pin ptc="0">BLK_BB-VPR_PAD.outpad[0]</pin>
                <pin ptc="1">BLK_BB-VPR_PAD.outpad[1]</pin>
            </pin_class>
            <pin_class type="INPUT">
                <pin ptc="2">BLK_BB-VPR_PAD.inpad[0]</pin>
            </pin_class>
        </block_type>
        '''
        bt = BlockType.from_xml(None, ET.fromstring(xml_string))
        self.assertEqual(
            3,
            len(bt.pins_index)
        )
        self.assertEqual(
            2,
            len(bt.pin_classes)
        )
        self.assertEqual(
            2,
            len(bt.pin_classes[0].pins)
        )

        # Multiple subblocks within a block_type
        xml_string = '''
        <block_type id="1" name="BLK_BB-VPR_PAD" width="2" height="3">
            <pin_class type="OUTPUT">
                <pin ptc="0">BLK_BB-VPR_PAD[0].outpad[0]</pin>
            </pin_class>
            <pin_class type="INPUT">
                <pin ptc="1">BLK_BB-VPR_PAD[0].inpad[0]</pin>
            </pin_class>
            <pin_class type="OUTPUT">
                <pin ptc="2">BLK_BB-VPR_PAD[1].outpad[0]</pin>
            </pin_class>
            <pin_class type="INPUT">
                <pin ptc="3">BLK_BB-VPR_PAD[1].inpad[0]</pin>
            </pin_class>
        </block_type>
        '''
        bt = BlockType.from_xml(None, ET.fromstring(xml_string))
        self.assertEqual(
            4,
            len(bt.pins_index)
        )
        self.assertEqual(
            4,
            len(bt.pin_classes)
        )
        # Each pin class should only have one pin
        self.assertEqual(
            1,
            len(bt.pin_classes[0].pins)
        )


    def test_blocktype_add_pin(self):
        pc = PinClass(direction=PinClassDirection.INPUT)
        self.assertEqual(
            0,
            len(pc.pins)
        )
        pc._add_pin(Pin())
        self.assertEqual(
            1,
            len(pc.pins)
        )
        bt = BlockType()
        self.assertEqual(
            0,
            len(bt.pins_index)
        )
        bt._add_pin_class(pc)
        self.assertEqual(
            1,
            len(bt.pins_index)
        )


    def test_block_from_xml(self):
        g = BlockGrid()
        g.add_block_type(BlockType(id=0, name="bt"))
        xml_string = '''
        <grid_loc x="2" y="5" block_type_id="0" width_offset="1" height_offset="2"/>
        '''
        bl1 = Block.from_xml(g, ET.fromstring(xml_string))
        self.assertEqual(
            2,
            bl1.position.x
        )
        self.assertEqual(
            5,
            bl1.position.y
        )
        self.assertEqual(
            1,
            bl1.offset.w
        )
        self.assertEqual(
            2,
            bl1.offset.h
        )


    def test_segment_from_xml(self):
        xml_string = '''
        <segment id="0" name="span">
            <timing R_per_meter="101" C_per_meter="2.25000005e-14"/>
        </segment>
        '''
        segment = Segment.from_xml(ET.fromstring(xml_string))
        self.assertEqual(
            101,
            segment.timing.R_per_meter
        )
        self.assertEqual(
            2.25000005e-14,
            segment.timing.C_per_meter
        )


    def test_switch_from_xml(self):
        xml_string = '''
        <switch id="0" type="mux" name="buffer">
            <timing R="551" Cin="7.70000012e-16" Cout="4.00000001e-15" Tdel="5.80000006e-11"/>
            <sizing mux_trans_size="2.63073993" buf_size="27.6459007"/>
        </switch>
        '''
        sw = Switch.from_xml(ET.fromstring(xml_string))
        self.assertEqual(
            'buffer',
            sw.name
        )
        self.assertEqual(
            551,
            sw.timing.R
        )
        self.assertEqual(
            7.70000012e-16,
            sw.timing.Cin
        )
        self.assertEqual(
            4.00000001e-15,
            sw.timing.Cout
        )
        self.assertEqual(
            4.00000001e-15,
            sw.timing.Tdel
        )
        self.assertEqual(
            2.63073993,
            sw.sizing.mux_trans_size
        )
        self.assertEqual(
            27.6459007,
            sw.sizing.buf_size
        )


    def test_routinggraphprinter_node(self):
        self.assertEqual(
            '0 X000Y003[00].SINK-<',
            RoutingGraphPrinter.node(ET.fromstring('''
        <node id="0" type="SINK" capacity="1">
            <loc xlow="0" ylow="3" xhigh="0" yhigh="3" ptc="0"/>
            <timing R="0" C="0"/>
        </node>
        '''))
        )
        self.assertEqual(
            '1 X001Y002[01].SRC-->',
            RoutingGraphPrinter.node(ET.fromstring('''
            <node id="1" type="SOURCE" capacity="1">
                <loc xlow="1" ylow="2" xhigh="1" yhigh="2" ptc="1"/>
                <timing R="0" C="0"/>
            </node>
            '''))
        )
        self.assertEqual(
            '2 X002Y001[00].T-PIN<',
            RoutingGraphPrinter.node(ET.fromstring('''
            <node id="2" type="IPIN" capacity="1">
                <loc xlow="2" ylow="1" xhigh="2" yhigh="1" side="TOP" ptc="0"/>
                <timing R="0" C="0"/>
            </node>
            '''))
        )
        self.assertEqual(
            '6 X003Y000[01].R-PIN>',
            RoutingGraphPrinter.node(ET.fromstring('''
            <node id="6" type="OPIN" capacity="1">
                <loc xlow="3" ylow="0" xhigh="3" yhigh="0" side="RIGHT" ptc="1"/>
                <timing R="0" C="0"/>
            </node>
            '''))
        )
        # With a block graph, the name will include the block type
        bg = graph.simple_test_block_grid()
        self.assertEqual(
            '0 X000Y003_INBLOCK[00].C[3:0]-SINK-<',
            RoutingGraphPrinter.node(ET.fromstring('''
            <node id="0" type="SINK" capacity="1">
                <loc xlow="0" ylow="3" xhigh="0" yhigh="3" ptc="0"/>
                <timing R="0" C="0"/>
            </node>
            '''), bg)
        )
        self.assertEqual(
            '1 X001Y002_DUALBLK[01].B[0]-SRC-->',
            RoutingGraphPrinter.node(ET.fromstring('''
            <node id="1" type="SOURCE" capacity="1">
                <loc xlow="1" ylow="2" xhigh="1" yhigh="2" ptc="1"/>
                <timing R="0" C="0"/>
            </node>
            '''), bg)
        )
        self.assertEqual(
            '2 X002Y001_DUALBLK[00].A[0]-T-PIN<',
            RoutingGraphPrinter.node(ET.fromstring('''
            <node id="2" type="IPIN" capacity="1">
                <loc xlow="2" ylow="1" xhigh="2" yhigh="1" side="TOP" ptc="0"/>
                <timing R="0" C="0"/>
            </node>
            '''), bg)
        )
        self.assertEqual(
            '6 X003Y000_OUTBLOK[01].D[1]-R-PIN>',
            RoutingGraphPrinter.node(ET.fromstring('''
            <node id="6" type="OPIN" capacity="1">
                <loc xlow="3" ylow="0" xhigh="3" yhigh="0" side="RIGHT" ptc="1"/>
                <timing R="0" C="0"/>
            </node>
            '''), bg)
        )
        # Edges don't require a block graph, as they have the full information on the node.
        self.assertEqual(
            '372 X003Y000--04->X003Y000',
            RoutingGraphPrinter.node(ET.fromstring('''
            <node capacity="1" direction="INC_DIR" id="372" type="CHANX">
                <loc ptc="4" xhigh="3" xlow="3" yhigh="0" ylow="0"/>
                <timing C="2.72700004e-14" R="101"/>
                <segment segment_id="1"/>
            </node>
            '''))
        )
        self.assertEqual(
            '373 X003Y000<|05||X003Y000',
            RoutingGraphPrinter.node(ET.fromstring('''
            <node capacity="1" direction="DEC_DIR" id="373" type="CHANY">
                <loc ptc="5" xhigh="3" xlow="3" yhigh="0" ylow="0"/>
                <timing C="2.72700004e-14" R="101"/>
                <segment segment_id="1"/>
            </node>
            '''))
        )
        self.assertEqual(
            '374 X003Y000<-05->X003Y000',
            RoutingGraphPrinter.node(ET.fromstring('''
            <node capacity="1" direction="BI_DIR" id="374" type="CHANX">
                <loc ptc="5" xhigh="3" xlow="3" yhigh="0" ylow="0"/>
                <timing C="2.72700004e-14" R="101"/>
                <segment segment_id="1"/>
            </node>
            '''))
        )


    def test_routinggraphprinter_edge(self):
        bg = graph.simple_test_block_grid()
        xml_string1 = '''
        <rr_graph>
            <rr_nodes>
                <node id="0" type="SOURCE" capacity="1">
                    <loc xlow="0" ylow="3" xhigh="0" yhigh="3" ptc="0"/>
                    <timing R="0" C="0"/>
                </node>
                <node capacity="1" direction="INC_DIR" id="1" type="CHANY">
                    <loc ptc="5" xhigh="3" xlow="0" yhigh="0" ylow="3"/>
                    <timing C="2.72700004e-14" R="101"/>
                    <segment segment_id="1"/>
                </node>
            </rr_nodes>
        <rr_edges />
        <switches />
        </rr_graph>
        '''
        rg = RoutingGraph(xml_graph=ET.fromstring(xml_string1))
        self.assertEqual(
            '0 X000Y003[00].SRC--> ->>- 1 X000Y003||05|>X003Y000',
            RoutingGraphPrinter.edge(rg, ET.fromstring('''
            <edge sink_node="1" src_node="0" switch_id="1"/>
            '''))
        )
        self.assertEqual(
            '0 X000Y003_INBLOCK[00].C[3:0]-SRC--> ->>- 1 X000Y003||05|>X003Y000',
            RoutingGraphPrinter.edge(rg, ET.fromstring('''
            <edge sink_node="1" src_node="0" switch_id="1"/>
            '''), bg)
        )


    def test_routinggraph_set_metadata(self):
        r = graph.simple_test_routing()
        sw = Switch(id=0, type=SwitchType.MUX, name="sw")
        r.create_edge_with_ids(0, 1, sw)
        e1 = r.get_edge_by_id(4)
        self.assertEqual(
            ':-(',
            e1.get_metadata("test", default=":-(")
        )
        e1.set_metadata("test", "123")
        self.assertEqual(
            '123',
            e1.get_metadata("test", default=":-(")
        )
        # Or via the routing object
        r.set_metadata(e1, "test", "234")
        self.assertEqual(
            '234',
            r.get_metadata(e1, "test", "234")
        )
        # Exception if no default provided
        try:
            r.get_metadata(e1, "not_found")
            assert False # Should've failed
        except ValueError:
            # Exception caught
            pass
        r.set_metadata(e1, "test", 1)
        # Works with nodes
        n1 = r.get_node_by_id(0)
        # Call directly on the node
        self.assertEqual(
            ':-(',
            n1.get_metadata("test", default=":-(")
        )
        n1.set_metadata("test", "123")
        self.assertEqual(
            '123',
            n1.get_metadata("test", default=":-(")
        )
        # Or via the routing object
        r.set_metadata(n1, "test", "234")
        self.assertEqual(
            '234',
            r.get_metadata(n1, "test")
        )


    def test_routinggraph_get_node_by_id(self):
        r = graph.simple_test_routing()
        self.assertEqual(
            '0 X000Y000[00].SRC-->',
            RoutingGraphPrinter.node(r.get_node_by_id(0))
        )
        self.assertEqual(
            '1 X000Y000[00].R-PIN>',
            RoutingGraphPrinter.node(r.get_node_by_id(1))
        )
        self.assertEqual(
            '2 X000Y000<-00->X000Y010',
            RoutingGraphPrinter.node(r.get_node_by_id(2))
        )
        self.assertEqual(
            '3 X000Y010[00].L-PIN<',
            RoutingGraphPrinter.node(r.get_node_by_id(3))
        )
        self.assertEqual(
            '4 X000Y010[00].SINK-<',
            RoutingGraphPrinter.node(r.get_node_by_id(4))
        )
        try:
            RoutingGraphPrinter.node(r.get_node_by_id(5))
            assert False # Should fail
        except KeyError:
            # Exception caught
            pass


    def test_routinggraph_get_edge_by_id(self):
        r = graph.simple_test_routing()
        self.assertEqual(
            '0 X000Y000[00].SRC--> ->>- 1 X000Y000[00].R-PIN>',
            RoutingGraphPrinter.edge(r, r.get_edge_by_id(0))
        )
        self.assertEqual(
            '1 X000Y000[00].R-PIN> ->>- 2 X000Y000<-00->X000Y010',
            RoutingGraphPrinter.edge(r, r.get_edge_by_id(1))
        )
        self.assertEqual(
            '2 X000Y000<-00->X000Y010 ->>- 3 X000Y010[00].L-PIN<',
            RoutingGraphPrinter.edge(r, r.get_edge_by_id(2))
        )
        self.assertEqual(
            '3 X000Y010[00].L-PIN< ->>- 4 X000Y010[00].SINK-<',
            RoutingGraphPrinter.edge(r, r.get_edge_by_id(3))
        )
        try:
            r.get_edge_by_id(4)
            assert False # Should fail
        except KeyError:
            # Exception caught
            pass


    def test_routinggraph_node_ids_for_edge(self):
        e = ET.fromstring('<edge src_node="0" sink_node="1" switch_id="1"/>')
        self.assertEqual(
            (0, 1),
            RoutingGraph.node_ids_for_edge(e)
        )


    def test_routinggraph_nodes_for_edge(self):
        r = graph.simple_test_routing()
        e1 = r.get_edge_by_id(0)
        self.assertEqual(
            '0 X000Y000[00].SRC--> ->>- 1 X000Y000[00].R-PIN>',
            RoutingGraphPrinter.edge(r, e1)
        )
        self.assertEqual(
            ['0 X000Y000[00].SRC-->', '1 X000Y000[00].R-PIN>'],
            [RoutingGraphPrinter.node(n) for n in r.nodes_for_edge(e1)]
        )
        e2 = r.get_edge_by_id(1)
        self.assertEqual(
            '1 X000Y000[00].R-PIN> ->>- 2 X000Y000<-00->X000Y010',
            RoutingGraphPrinter.edge(r, e2)
        )
        self.assertEqual(
            ['1 X000Y000[00].R-PIN>', '2 X000Y000<-00->X000Y010'],
            [RoutingGraphPrinter.node(n) for n in r.nodes_for_edge(e2)]
        )


    def test_routinggraph_edges_for_node(self):
        r = graph.simple_test_routing()
        self.assertEqual(
            ['0 X000Y000[00].SRC--> ->>- 1 X000Y000[00].R-PIN>', '1 X000Y000[00].R-PIN> ->>- 2 X000Y000<-00->X000Y010'],
            [RoutingGraphPrinter.edge(r, e) for e in r.edges_for_node(r.get_node_by_id(1))]
        )
        self.assertEqual(
            ['1 X000Y000[00].R-PIN> ->>- 2 X000Y000<-00->X000Y010', '2 X000Y000<-00->X000Y010 ->>- 3 X000Y010[00].L-PIN<'],
            [RoutingGraphPrinter.edge(r, e) for e in r.edges_for_node(r.get_node_by_id(2))]
        )


    def test_routinggraph_create_edge_with_ids(self):
        r = graph.simple_test_routing()
        sw = Switch(id=0, type=SwitchType.MUX, name="sw")
        r.create_edge_with_ids(0, 1, sw)
        e1 = r.get_edge_by_id(4)
        self.assertEqual(
            '0 X000Y000[00].SRC--> ->>- 1 X000Y000[00].R-PIN>',
            RoutingGraphPrinter.edge(r, e1)
        )
        # The code protects against invalid edge creation
        try:
            r.create_edge_with_ids(0, 2, sw)
            assert False # Should fail
        except TypeError:
            # Exception caught
            pass
        try:
            r.create_edge_with_ids(1, 4, sw)
            assert False # Should fail
        except TypeError:
            # Exception caught
            pass


    def test_graph_constructor(self):
        # Look at the segments via name or ID number
        g = graph.simple_test_graph()
        self.assertEqual(
            'local',
            g.segments[0].name
        )
        self.assertEqual(
            0,
            g.segments['local'].id
        )
        # Look at the switches via name or ID number
        g = graph.simple_test_graph()
        self.assertEqual(
            'mux',
            g.switches[0].name
        )
        self.assertEqual(
            0,
            g.switches['mux'].id
        )
        self.assertEqual(
            '__vpr_delayless_switch__',
            g.switches[1].name
        )
        self.assertEqual(
            1,
            g.switches['__vpr_delayless_switch__'].id
        )
        # Look at the block grid
        g = graph.simple_test_graph()
        self.assertEqual(
            Size(w=4, h=3),
            g.block_grid.size
        )
        self.assertEqual(
            P(x=0, y=0),
            g.block_grid[P(0, 0)].position
        )
        self.assertEqual(
            P(x=2, y=1),
            g.block_grid[P(2, 1)].position
        )
        try:
            g.block_grid[P(4, 4)]
            assert False # Should fail
        except KeyError:
            # Exception caught
            pass
        self.assertEqual(
        1,
        g.block_grid.block_types["BLK_IG-IBUF"].id
        )
        self.assertEqual(
            'BLK_IG-OBUF',
            g.block_grid.block_types[2].name
        )


if __name__ == "__main__":
    unittest.main()