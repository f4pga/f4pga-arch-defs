#!/usr/bin/env python3

from lxml import etree
from lib.rr_graph import graph, inaccessible


def test_simple():
    '''
    Test a simple graph without complete connectivity.
    '''
    expected_inaccessible = {7: {6}}
    rr_graph_string = '''
<rr_graph>
    <!--
              7
              |
              V
    0 -> 1 -> 2 -> 3
         |
         V
         4 -> 5 -> 6
    -->
  <rr_nodes>
    <node id="0" type="SOURCE"/>
    <node id="1" type="WHATEVER"/>
    <node id="2" type="WHATEVER"/>
    <node id="3" type="SINK"/>
    <node id="4" type="WHATEVER"/>
    <node id="5" type="WHATEVER"/>
    <node id="6" type="SINK"/>
    <node id="7" type="SOURCE"/>
  </rr_nodes>
  <rr_edges>
    <edge src_node="0" sink_node="1"/>
    <edge src_node="1" sink_node="2"/>
    <edge src_node="2" sink_node="3"/>
    <edge src_node="1" sink_node="4"/>
    <edge src_node="4" sink_node="5"/>
    <edge src_node="5" sink_node="6"/>
    <edge src_node="7" sink_node="2"/>
  </rr_edges>
</rr_graph>
    '''
    xml_graph = etree.XML(rr_graph_string)
    routing_graph = graph.RoutingGraph(xml_graph, verbose=True, clear_fabric=False)
    inaccessible_nodes = inaccessible.inaccessible_sink_node_ids_by_source_node_id(routing_graph)
    assert inaccessible_nodes == expected_inaccessible


def test_loop():
    '''
    Test a graph with a loop.
    '''
    expected_inaccessible = {0: {9},
                             7: {9},
                             8: {3, 6}}
    rr_graph_string = '''
<rr_graph>
    <!--
              7
              |
              V
    0 -> 1 <- 2 -> 3
         |    ^
         V    |
         4 -> 5 -> 6

    8 -> 9
    -->
  <rr_nodes>
    <node id="0" type="SOURCE"/>
    <node id="1" type="WHATEVER"/>
    <node id="2" type="WHATEVER"/>
    <node id="3" type="SINK"/>
    <node id="4" type="WHATEVER"/>
    <node id="5" type="WHATEVER"/>
    <node id="6" type="SINK"/>
    <node id="7" type="SOURCE"/>
    <node id="8" type="SOURCE"/>
    <node id="9" type="SINK"/>
  </rr_nodes>
  <rr_edges>
    <edge src_node="0" sink_node="1"/>
    <edge src_node="2" sink_node="1"/>
    <edge src_node="2" sink_node="3"/>
    <edge src_node="1" sink_node="4"/>
    <edge src_node="4" sink_node="5"/>
    <edge src_node="5" sink_node="6"/>
    <edge src_node="5" sink_node="2"/>
    <edge src_node="7" sink_node="2"/>
    <edge src_node="8" sink_node="9"/>
  </rr_edges>
</rr_graph>
    '''
    xml_graph = etree.XML(rr_graph_string)
    routing_graph = graph.RoutingGraph(xml_graph, verbose=True, clear_fabric=False)
    inaccessible_nodes = inaccessible.inaccessible_sink_node_ids_by_source_node_id(routing_graph)
    assert inaccessible_nodes == expected_inaccessible


def test_complex():
    '''
    Test a graph with loops.
    '''
    expected_inaccessible = {0: {14},
                             7: {14},
                             15: {3, 6}}
    rr_graph_string = '''
<rr_graph>
    <!--
              7
              |
              V
    0 -> 1 <- 2 -> 3
         |    ^
         V    |
         4 -> 5 -> 6
              ^
              |
         8 -> 9  -> 10 -> 16
              ^     |     |
              |     V     V
              11 <- 12 -> 13 -> 14
                          ^
                          |
                          15
    -->
  <rr_nodes>
    <node id="0" type="SOURCE"/>
    <node id="1" type="WHATEVER"/>
    <node id="2" type="WHATEVER"/>
    <node id="3" type="SINK"/>
    <node id="4" type="WHATEVER"/>
    <node id="5" type="WHATEVER"/>
    <node id="6" type="SINK"/>
    <node id="7" type="SOURCE"/>
    <node id="8" type="SOURCE"/>
    <node id="9" type="WHATEVER"/>
    <node id="10" type="WHATEVER"/>
    <node id="11" type="WHATEVER"/>
    <node id="12" type="WHATEVER"/>
    <node id="13" type="WHATEVER"/>
    <node id="14" type="SINK"/>
    <node id="15" type="SOURCE"/>
    <node id="16" type="WHATEVER"/>
  </rr_nodes>
  <rr_edges>
    <edge src_node="0" sink_node="1"/>
    <edge src_node="2" sink_node="1"/>
    <edge src_node="2" sink_node="3"/>
    <edge src_node="1" sink_node="4"/>
    <edge src_node="4" sink_node="5"/>
    <edge src_node="5" sink_node="6"/>
    <edge src_node="5" sink_node="2"/>
    <edge src_node="7" sink_node="2"/>
    <edge src_node="8" sink_node="9"/>
    <edge src_node="9" sink_node="5"/>
    <edge src_node="9" sink_node="10"/>
    <edge src_node="10" sink_node="16"/>
    <edge src_node="10" sink_node="12"/>
    <edge src_node="16" sink_node="13"/>
    <edge src_node="11" sink_node="9"/>
    <edge src_node="12" sink_node="11"/>
    <edge src_node="12" sink_node="13"/>
    <edge src_node="13" sink_node="14"/>
    <edge src_node="15" sink_node="13"/>
  </rr_edges>
</rr_graph>
    '''
    xml_graph = etree.XML(rr_graph_string)
    routing_graph = graph.RoutingGraph(xml_graph, verbose=True, clear_fabric=False)
    inaccessible_nodes = inaccessible.inaccessible_sink_node_ids_by_source_node_id(routing_graph)
    assert inaccessible_nodes == expected_inaccessible


def run_tests():
    test_simple()
    test_loop()
    test_complex()


if __name__ == '__main__':
    run_tests()
