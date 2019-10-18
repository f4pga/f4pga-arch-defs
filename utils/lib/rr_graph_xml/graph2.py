""" Graph object that handles serialization and deserialization from XML. """
from lib.rr_graph import graph2
from lib.rr_graph.graph2 import NodeDirection
from lib.rr_graph import tracks
import lxml.etree as ET
import contextlib

# Set to True once
# https://github.com/verilog-to-routing/vtr-verilog-to-routing/compare/c_internal
# is merged and included in VTR conda.
VPR_HAS_C_INTERNAL_SUPPORT = True


def serialize_nodes(xf, nodes):
    """ Serialize list of Node objects to XML.

    Note that this method is extremely hot, len(nodes) is order 1-10 million.
    Almost any modification of this function has a significant effect on
    performance, so any modification to this function should be tested for
    performance and correctness before commiting.

    """
    element = xf.element
    write = xf.write
    Element = ET.Element
    with element('rr_nodes'):
        for node in nodes:
            attrib = {
                'id': str(node.id),
                'type': node.type.name,
                'capacity': str(node.capacity),
            }

            if node.direction != NodeDirection.NO_DIR:
                attrib['direction'] = node.direction.name

            with element('node', attrib):
                loc = {
                    'xlow': str(node.loc.x_low),
                    'ylow': str(node.loc.y_low),
                    'xhigh': str(node.loc.x_high),
                    'yhigh': str(node.loc.y_high),
                    'ptc': str(node.loc.ptc),
                }

                if node.loc.side is not None:
                    loc['side'] = node.loc.side.name

                write(Element('loc', loc))

                if node.timing is not None:
                    write(
                        Element(
                            'timing', {
                                'R': str(node.timing.r),
                                'C': str(node.timing.c),
                            }
                        )
                    )

                if node.metadata is not None and len(node.metadata) > 0:
                    with element('metadata'):
                        for m in node.metadata:
                            with element('meta', name=m.name):
                                write(m.value)

                if node.segment is not None:
                    write(
                        Element(
                            'segment', {
                                'segment_id': str(node.segment.segment_id),
                            }
                        )
                    )

                if node.connection_box is not None:
                    write(
                        Element(
                            'connection_box', {
                                'x': str(node.connection_box.x),
                                'y': str(node.connection_box.y),
                                'id': str(node.connection_box.id),
                            }
                        )
                    )

                if node.canonical_loc is not None:
                    write(
                        Element(
                            'canonical_loc', {
                                'x': str(node.canonical_loc.x),
                                'y': str(node.canonical_loc.y),
                            }
                        )
                    )


def serialize_edges(xf, edges):
    """ Serialize list of edge tuples objects to XML.

    edge tuples are (src_node(int), sink_node(int), switch_id(int), metadata(NodeMetadata)).

    metadata may be None.

    Note that this method is extremely hot, len(edges) is order 5-50 million.
    Almost any modification of this function has a significant effect on
    performance, so any modification to this function should be tested for
    performance and correctness before commiting.

    """
    element = xf.element
    write = xf.write

    with element('rr_edges'):
        for src_node, sink_node, switch_id, metadata in edges:
            with element('edge', {
                    'src_node': str(src_node),
                    'sink_node': str(sink_node),
                    'switch_id': str(switch_id),
            }):
                if metadata is not None and len(metadata) > 0:
                    with element('metadata'):
                        for name, value in metadata:
                            with element('meta', name=name):
                                write(value)


def enum_from_string(enum_type, s):
    return enum_type[s.upper()]


def iterate_xml(xml_file):
    """
    A generator function that allows to incrementally walk over an XML tree
    while reading it from a file thus allowing to greatly reduce memory
    usage.
    """
    doc = ET.iterparse(xml_file, events=('start', 'end'))
    _, root = next(doc)
    path = root.tag
    for event, element in doc:
        if event == 'start':
            path += "/" + element.tag
        if event == 'end':
            path = path.rsplit('/', maxsplit=1)[0]
            yield path, element
            element.clear()
    root.clear()


def graph_from_xml(input_file_name, progressbar=None):
    """
    Loads relevant information about the routing resource graph from an XML
    file.
    """

    if progressbar is None:
        progressbar = lambda x: x  # noqa: E731

    switches = []
    segments = []
    block_types = []
    grid = []
    nodes = []

    # Itertate over XML elements
    switch_timing = None
    switch_sizing = None
    segment_timing = None
    pins = []
    pin_classes = []
    node_loc = None
    node_timing = None

    for path, element in progressbar(iterate_xml(input_file_name)):

        # Switch timing
        if path == "rr_graph/switches/switch" and element.tag == "timing":
            switch_timing = graph2.SwitchTiming(
                r=float(element.attrib['R']),
                c_in=float(element.attrib['Cin']),
                c_out=float(element.attrib['Cout']),
                c_internal=float(element.attrib.get('Cinternal', 0)),
                t_del=float(element.attrib['Tdel']),
            )

        # Switch sizing
        if path == "rr_graph/switches/switch" and element.tag == "sizing":
            switch_sizing = graph2.SwitchSizing(
                mux_trans_size=float(element.attrib['mux_trans_size']),
                buf_size=float(element.attrib['buf_size']),
            )

        # Switch
        if path == "rr_graph/switches" and element.tag == "switch":
            switches.append(
                graph2.Switch(
                    id=int(element.attrib['id']),
                    type=enum_from_string(
                        graph2.SwitchType, element.attrib['type']
                    ),
                    name=element.attrib['name'],
                    timing=switch_timing,
                    sizing=switch_sizing,
                )
            )

            switch_timing = None
            switch_sizing = None

        # Segment timing
        if path == "rr_graph/segments/segment" and element.tag == "timing":
            segment_timing = graph2.SegmentTiming(
                r_per_meter=float(element.attrib['R_per_meter']),
                c_per_meter=float(element.attrib['C_per_meter']),
            )

        # Segment
        if path == "rr_graph/segments" and element.tag == "segment":
            segments.append(
                graph2.Segment(
                    id=int(element.attrib['id']),
                    name=element.attrib['name'],
                    timing=segment_timing,
                )
            )

            segment_timing = None

        # Block type - pin
        if path == "rr_graph/block_types/block_type/pin_class" and element.tag == "pin":
            pins.append(
                graph2.Pin(
                    ptc=int(element.attrib['ptc']),
                    name=element.text,
                )
            )

        # Block type - pin_class
        if path == "rr_graph/block_types/block_type" and element.tag == "pin_class":
            pin_classes.append(
                graph2.PinClass(
                    type=enum_from_string(
                        graph2.PinType, element.attrib['type']
                    ),
                    pin=pins,
                )
            )

            pins = []
           
        # Block type
        if path == "rr_graph/block_types" and element.tag == "block_type":
            block_types.append(
                graph2.BlockType(
                    id=int(element.attrib['id']),
                    name=element.attrib['name'],
                    width=int(element.attrib['width']),
                    height=int(element.attrib['height']),
                    pin_class=pin_classes,
                )
            )

            pin_classes = []

        # Grid
        if path == "rr_graph/grid" and element.tag == "grid_loc":
            grid.append(graph2.GridLoc(
                    x=int(element.attrib['x']),
                    y=int(element.attrib['y']),
                    block_type_id=int(element.attrib['block_type_id']),
                    width_offset=int(element.attrib['width_offset']),
                    height_offset=int(element.attrib['height_offset']),
                )
            )

        # Node - loc
        if path == "rr_graph/rr_nodes/node" and element.tag == "loc":
            if 'side' in element.attrib:
                side = enum_from_string(
                    tracks.Direction, element.attrib['side']
                )
            else:
                side = None

            node_loc = graph2.NodeLoc(
                x_low=int(element.attrib['xlow']),
                y_low=int(element.attrib['ylow']),
                x_high=int(element.attrib['xhigh']),
                y_high=int(element.attrib['yhigh']),
                ptc=int(element.attrib['ptc']),
                side=side
            )

        # Node - timing
        if path == "rr_graph/rr_nodes/node" and element.tag == "timing":
            node_timing = graph2.NodeTiming(
                r=float(element.attrib['R']),
                c=float(element.attrib['C']),
            )

        # Node
        if path == "rr_graph/rr_nodes" and element.tag == "node":
            node_type = enum_from_string(graph2.NodeType, element.attrib['type'])

            if node_type in [graph2.NodeType.SOURCE, graph2.NodeType.SINK,
                             graph2.NodeType.OPIN, graph2.NodeType.IPIN]:

                # Not expecting any metadata on the input.
                assert element.find('metadata') is None
                metadata = None

                nodes.append(
                    graph2.Node(
                        id=int(element.attrib['id']),
                        type=node_type,
                        direction=graph2.NodeDirection.NO_DIR,
                        capacity=int(element.attrib['capacity']),
                        loc=node_loc,
                        timing=node_timing,
                        metadata=metadata,
                        segment=None,
                        canonical_loc=None,
                        connection_box=None,
                    )
                )

            node_loc = None
            node_timing = None

    return dict(
        switches=switches,
        segments=segments,
        block_types=block_types,
        grid=grid,
        nodes=nodes
    )


class Graph(object):
    def __init__(
            self,
            input_file_name,
            output_file_name=None,
            progressbar=None,
            build_pin_edges=True
    ):
        if progressbar is None:
            progressbar = lambda x: x  # noqa: E731

        self.input_file_name = input_file_name
        self.progressbar = progressbar
        self.output_file_name = output_file_name

        graph_input = graph_from_xml(input_file_name, progressbar)
        graph_input['build_pin_edges'] = build_pin_edges

        rebase_nodes = []
        for node in graph_input['nodes']:
            node_d = node._asdict()
            node_d['id'] = len(rebase_nodes)
            rebase_nodes.append(graph2.Node(**node_d))

        graph_input['nodes'] = rebase_nodes

        self.graph = graph2.Graph(**graph_input)

        self.exit_stack = None
        self.xf = None

    def __enter__(self):
        assert self.output_file_name is not None
        assert self.exit_stack is None
        self.exit_stack = contextlib.ExitStack().__enter__()

        f = self.exit_stack.enter_context(open(self.output_file_name, 'wb'))
        self.xf = self.exit_stack.enter_context(ET.xmlfile(f))

        return self

    def __exit__(self, exc_type, exc_value, traceback):
        ret = self.exit_stack.__exit__(exc_type, exc_value, traceback)
        self.exit_stack = None
        self.xf = None
        return ret

    def start_serialize_to_xml(
            self,
            tool_version,
            tool_comment,
            channels_obj,
            connection_box_obj=None
    ):
        assert self.exit_stack is not None
        assert self.xf is not None

        self.exit_stack.enter_context(
            self.xf.element(
                'rr_graph', {
                    'tool_name': 'vpr',
                    'tool_version': tool_version,
                    'tool_comment': tool_comment,
                }
            )
        )

        self.graph.check_ptc()

        with self.xf.element('channels'):
            el = ET.Element(
                'channel', {
                    'chan_width_max': str(channels_obj.chan_width_max),
                    'x_min': str(channels_obj.x_min),
                    'y_min': str(channels_obj.y_min),
                    'x_max': str(channels_obj.x_max),
                    'y_max': str(channels_obj.y_max),
                }
            )
            self.xf.write(el)

            for x_list in channels_obj.x_list:
                el = ET.Element(
                    'x_list', {
                        'index': str(x_list.index),
                        'info': str(x_list.info),
                    }
                )
                self.xf.write(el)

            for y_list in channels_obj.y_list:
                el = ET.Element(
                    'y_list', {
                        'index': str(y_list.index),
                        'info': str(y_list.info),
                    }
                )
                self.xf.write(el)

        if connection_box_obj is not None:
            with self.xf.element('connection_boxes', {
                    'x_dim': str(connection_box_obj.x_dim),
                    'y_dim': str(connection_box_obj.y_dim),
                    'num_boxes': str(len(connection_box_obj.boxes)),
            }):
                for idx, box in enumerate(connection_box_obj.boxes):
                    el = ET.Element(
                        'connection_box', {
                            'id': str(idx),
                            'name': box,
                        }
                    )
                    self.xf.write(el)

        self.xf.write(self.input_xml.find('switches'))
        self.xf.write(self.input_xml.find('segments'))
        self.xf.write(self.input_xml.find('block_types'))
        self.xf.write(self.input_xml.find('grid'))

    def add_switch(self, switch):
        """ Add switch into graph model.

        Typically switches are imported from the architecture definition,
        however VPR will not save unused switches from the arch.  In this
        case, the switches must be added back during routing import.

        Important note: any switch present in the rr graph must also be present
        in the architecture definition.

        """

        # Add to Graph2 data structure
        switch_id = self.graph.add_switch(switch)

        # Add to XML
        switch_xml = ET.SubElement(
            self.input_xml.find('switches'), 'switch', {
                'id': str(switch_id),
                'type': switch.type.name.lower(),
                'name': switch.name,
            }
        )

        if switch.timing:
            attrib = {
                'R': str(switch.timing.r),
                'Cin': str(switch.timing.c_in),
                'Cout': str(switch.timing.c_out),
                'Tdel': str(switch.timing.t_del),
            }

            if VPR_HAS_C_INTERNAL_SUPPORT:
                attrib['Cinternal'] = str(switch.timing.c_internal)

            ET.SubElement(switch_xml, 'timing', attrib)

        ET.SubElement(
            switch_xml, 'sizing', {
                'mux_trans_size': str(switch.sizing.mux_trans_size),
                'buf_size': str(switch.sizing.buf_size),
            }
        )

        return switch_id

    def serialize_nodes(self, nodes):
        serialize_nodes(self.xf, nodes)

    def serialize_edges(self, edges):
        serialize_edges(self.xf, edges)

    def serialize_to_xml(
            self,
            tool_version,
            tool_comment,
            pad_segment,
            channels_obj=None,
            pool=None
    ):
        if channels_obj is None:
            channels_obj = self.graph.create_channels(
                pad_segment=pad_segment,
                pool=pool,
            )

        with self:
            self.start_serialize_to_xml(
                tool_version=tool_version,
                tool_comment=tool_comment,
                channels_obj=channels_obj,
            )
            self.serialize_nodes(self.progressbar(self.graph.nodes))
            self.serialize_edges(self.progressbar(self.graph.edges))
