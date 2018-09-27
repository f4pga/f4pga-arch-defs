""" Graph object that handles serialization and deserialization from XML. """
from lib.rr_graph import graph2
from lib.rr_graph import tracks
import copy
import lxml.etree as ET

def enum_from_string(enum_type, s):
    for e in enum_type:
        if e.name == s.upper():
            return e

    assert False, (enum_type, s)

def graph_from_xml(input_xml, progressbar=None):
    if progressbar is None:
        progressbar = lambda x: x

    switches = []
    for switch in input_xml.find('switches').iter('switch'):
        timing_xml = switch.find('timing')

        if timing_xml is not None:
            timing = graph2.SwitchTiming(
                    r=float(timing_xml.attrib['R']),
                    c_in=float(timing_xml.attrib['Cin']),
                    c_out=float(timing_xml.attrib['Cout']),
                    t_del=float(timing_xml.attrib['Tdel']),
            )
        else:
            timing = None

        sizing_xml = switch.find('sizing')

        if sizing_xml is not None:
            sizing = graph2.SwitchSizing(
                    mux_trans_size=float(sizing_xml.attrib['mux_trans_size']),
                    buf_size=float(sizing_xml.attrib['buf_size']),
            )
        else:
            sizing = None

        switches.append(graph2.Switch(
                id=int(switch.attrib['id']),
                type=enum_from_string(graph2.SwitchType, switch.attrib['type']),
                name=switch.attrib['name'],
                timing=timing,
                sizing=sizing,
        ))

    segments = []
    for segment in input_xml.find('segments').iter('segment'):
        timing_xml = segment.find('timing')

        if timing_xml is not None:
            timing = graph2.SegmentTiming(
                    r_per_meter=float(timing_xml.attrib['R_per_meter']),
                    c_per_meter=float(timing_xml.attrib['C_per_meter']),
            )
        else:
            timing = None

        segments.append(graph2.Segment(
                id=int(segment.attrib['id']),
                name=segment.attrib['name'],
                timing=timing,
        ))

    block_types = []
    for block_type in input_xml.find('block_types').iter('block_type'):
        pin_classes = []

        for pin_class in block_type.iter('pin_class'):
            pins = []
            for pin in pin_class.iter('pin'):
                pins.append(graph2.Pin(
                        ptc=int(pin.attrib['ptc']),
                        name=pin.text,
                ))

            pin_classes.append(graph2.PinClass(
                    type=enum_from_string(graph2.PinType, pin_class.attrib['type']),
                    pin=pins,
            ))

        block_types.append(graph2.BlockType(
                id=int(block_type.attrib['id']),
                name=block_type.attrib['name'],
                width=int(block_type.attrib['width']),
                height=int(block_type.attrib['height']),
                pin_class=pin_classes,
        ))

    grid = []
    for grid_loc in input_xml.find('grid').iter('grid_loc'):
        grid.append(graph2.GridLoc(
                x=int(grid_loc.attrib['x']),
                y=int(grid_loc.attrib['y']),
                block_type_id=int(grid_loc.attrib['block_type_id']),
                width_offset=int(grid_loc.attrib['width_offset']),
                height_offset=int(grid_loc.attrib['height_offset']),
        ))

    nodes = []
    for node in progressbar(input_xml.find('rr_nodes').iter('node')):
        node_type = enum_from_string(graph2.NodeType, node.attrib['type'])
        if node_type in [graph2.NodeType.SOURCE, graph2.NodeType.SINK,
                            graph2.NodeType.OPIN, graph2.NodeType.IPIN]:

            loc_xml = node.find('loc')
            if loc_xml is not None:
                if 'side' in loc_xml.attrib:
                    side = enum_from_string(tracks.Direction, loc_xml.attrib['side'])
                else:
                    side = None

                loc = graph2.NodeLoc(
                        x_low=int(loc_xml.attrib['xlow']),
                        y_low=int(loc_xml.attrib['ylow']),
                        x_high=int(loc_xml.attrib['xhigh']),
                        y_high=int(loc_xml.attrib['yhigh']),
                        ptc=int(loc_xml.attrib['ptc']),
                        side=side
                )
            else:
                loc = None

            timing_xml = node.find('timing')
            if timing_xml is not None:
                timing = graph2.NodeTiming(
                        r=float(timing_xml.attrib['R']),
                        c=float(timing_xml.attrib['C']),
                )
            else:
                timing = None

            # Not expecting any metadata on the input.
            assert node.find('metadata') is None
            metadata = None
            nodes.append(graph2.Node(
                    id=int(node.attrib['id']),
                    type=node_type,
                    direction=graph2.NodeDirection.NO_DIR,
                    capacity=int(node.attrib['capacity']),
                    loc=loc,
                    timing=timing,
                    metadata=metadata,
                    segment=None,
            ))

    return dict(
            switches=switches,
            segments=segments,
            block_types=block_types,
            grid=grid,
            nodes=nodes
    )

def AddNodeMetadata(root, metadata):
    metadata_xml = ET.SubElement(root, 'metadata')
    for m in metadata:
        ET.SubElement(metadata_xml, 'meta', {
                'name': m.name,
                'x_offset': str(m.x_offset),
                'y_offset': str(m.y_offset),
                'z_offset': str(m.z_offset),
        }).text = m.value

class Graph(object):
    def __init__(self, input_xml, progressbar=None):
        if progressbar is None:
            self.progressbar = lambda x: x

        self.input_xml = input_xml
        self.progressbar = progressbar

        graph_input = graph_from_xml(input_xml, progressbar)

        rebase_nodes = []
        for node in progressbar(graph_input['nodes']):
            node_d = node._asdict()
            node_d['id'] = len(rebase_nodes)
            rebase_nodes.append(graph2.Node(**node_d))

        graph_input['nodes'] = rebase_nodes

        self.graph = graph2.Graph(**graph_input)

    def serialize_to_xml(self, tool_version, tool_comment, pad_segment, pool=None):
        output_xml = ET.Element('rr_graph', {
                'tool_name': 'vpr',
                'tool_version': tool_version,
                'tool_comment': tool_comment,
        })

        channels_obj = self.graph.create_channels(
                pad_segment=pad_segment,
                pool=pool,
        )
        self.graph.check_ptc()

        channels_xml = ET.SubElement(output_xml, 'channels')

        ET.SubElement(channels_xml, 'channel', {
                'chan_width_max': str(channels_obj.chan_width_max),
                'x_min': str(channels_obj.x_min),
                'y_min': str(channels_obj.y_min),
                'x_max': str(channels_obj.x_max),
                'y_max': str(channels_obj.y_max),
        })

        for x_list in channels_obj.x_list:
            ET.SubElement(channels_xml, 'x_list', {
                'index': str(x_list.index),
                'info': str(x_list.info),
            })

        for y_list in channels_obj.y_list:
            ET.SubElement(channels_xml, 'y_list', {
                'index': str(y_list.index),
                'info': str(y_list.info),
            })

        output_xml.append(copy.deepcopy(self.input_xml.find('switches')))
        output_xml.append(copy.deepcopy(self.input_xml.find('segments')))
        output_xml.append(copy.deepcopy(self.input_xml.find('block_types')))
        output_xml.append(copy.deepcopy(self.input_xml.find('grid')))

        rr_nodes_xml = ET.SubElement(output_xml, 'rr_nodes')
        for node in self.progressbar(self.graph.nodes):
            node_xml = ET.SubElement(rr_nodes_xml, 'node', {
                    'id': str(node.id),
                    'type': node.type.name,
                    'capacity': str(node.capacity),
            })

            if node.direction != graph2.NodeDirection.NO_DIR:
                node_xml.attrib['direction'] = node.direction.name

            if node.loc is not None:
                loc = {
                        'xlow': str(node.loc.x_low),
                        'ylow': str(node.loc.y_low),
                        'xhigh': str(node.loc.x_high),
                        'yhigh': str(node.loc.y_high),
                        'ptc': str(node.loc.ptc),
                }

                if node.loc.side is not None:
                    loc['side'] = node.loc.side.name

                ET.SubElement(node_xml, 'loc', loc)

            if node.timing is not None:
                ET.SubElement(node_xml, 'timing', {
                        'R': str(node.timing.r),
                        'C': str(node.timing.c),
                })

            if node.metadata is not None:
                AddNodeMetadata(node_xml, node.metadata)

            if node.segment is not None:
                ET.SubElement(node_xml, 'segment', {
                        'segment_id': str(node.segment.segment_id),
                })

        rr_edges_xml = ET.SubElement(output_xml, 'rr_edges')
        for edge in self.progressbar(self.graph.edges):
            edge_xml = ET.SubElement(rr_edges_xml, 'edge', {
                    'src_node': str(edge.src_node),
                    'sink_node': str(edge.sink_node),
                    'switch_id': str(edge.switch_id),
            })

            if edge.metadata is not None:
                AddNodeMetadata(edge_xml, edge.metadata)

        return ET.tostring(ET.ElementTree(output_xml), pretty_print=True)
