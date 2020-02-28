""" Graph object that handles serialization and deserialization from XML. """
from lib.rr_graph import graph2
from lib.rr_graph.graph2 import NodeDirection
from lib.rr_graph import tracks
import lxml.etree as ET

# Set to True once
# https://github.com/verilog-to-routing/vtr-verilog-to-routing/compare/c_internal
# is merged and included in VTR conda.
VPR_HAS_C_INTERNAL_SUPPORT = True

# For debugging purposes:
# 0 - debugging off,
# 1 - indent output XML,
# 2 - write only one element of each kind.
DEBUG = 0


def enum_from_string(enum_type, s):
    return enum_type[s.upper()]


def iterate_xml(xml_file, load_edges):
    """
    A generator function that allows to incrementally walk over an XML tree
    while reading it from a file thus allowing to greatly reduce memory
    usage.
    """
    doc = ET.iterparse(xml_file, events=('start', 'end'))
    _, root = next(doc)
    yield "", root
    path = root.tag
    in_edge = False
    for event, element in doc:
        if event == 'start':
            if in_edge:
                continue

            if not load_edges and element.tag == 'edge':
                in_edge = True
                continue
            path += "/" + element.tag
        if event == 'end':
            if in_edge:
                if element.tag == 'edge':
                    in_edge = False
                element.clear()
                continue

            path = path.rsplit('/', maxsplit=1)[0]
            yield path, element
            element.clear()

    root.clear()


def graph_from_xml(
        input_file_name, progressbar=None, filter_nodes=True, load_edges=False
):
    """
    Loads relevant information about the routing resource graph from an XML
    file.
    """

    if progressbar is None:
        progressbar = lambda x: x  # noqa: E731

    root_attrib = {}
    switches = []
    segments = []
    block_types = []
    grid = []
    nodes = []
    edges = []

    # Itertate over XML elements
    switch_timing = None
    switch_sizing = None
    segment_timing = None
    pins = []
    pin_classes = []
    node_loc = None
    node_timing = None
    node_segment = None

    for path, element in progressbar(iterate_xml(input_file_name,
                                                 load_edges=load_edges)):

        # Root tag
        if path == "" and element.tag == "rr_graph":
            root_attrib = dict(element.attrib)

        # Switch timing
        if path == "rr_graph/switches/switch" and element.tag == "timing":
            switch_timing = graph2.SwitchTiming(
                r=float(element.attrib.get('R', 0)),
                c_in=float(element.attrib.get('Cin', 0)),
                c_out=float(element.attrib.get('Cout', 0)),
                c_internal=float(element.attrib.get('Cinternal', 0)),
                t_del=float(element.attrib.get('Tdel', 0)),
                p_cost=float(element.attrib.get('penalty_cost', 0)),
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
                r_per_meter=float(element.attrib.get('R_per_meter', 0)),
                c_per_meter=float(element.attrib.get('C_per_meter', 0)),
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
            grid.append(
                graph2.GridLoc(
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

        # Node - segment
        if path == "rr_graph/rr_nodes/node" and element.tag == "segment":
            node_segment = int(element.attrib['segment_id'])

        # Node
        if path == "rr_graph/rr_nodes" and element.tag == "node":
            node_type = enum_from_string(
                graph2.NodeType, element.attrib['type']
            )

            if filter_nodes and node_type not in [
                    graph2.NodeType.SOURCE, graph2.NodeType.SINK,
                    graph2.NodeType.OPIN, graph2.NodeType.IPIN
            ]:
                continue

            # Dropping metadata for now
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
                    segment=node_segment,
                    canonical_loc=None,
                    connection_box=None,
                )
            )

            node_loc = None
            node_timing = None
            node_segment = None

        # Edge
        if path == "rr_graph/rr_edges" and element.tag == "edge":
            if load_edges:
                edges.append(
                    graph2.Edge(
                        src_node=int(element.attrib['src_node']),
                        sink_node=int(element.attrib['sink_node']),
                        switch_id=int(element.attrib['switch_id']),
                        metadata=None  # FIXME: Add reading edge metadata
                    )
                )

    return dict(
        root_attrib=root_attrib,
        switches=switches,
        segments=segments,
        block_types=block_types,
        grid=grid,
        nodes=nodes,
        edges=edges
    )


class Graph(object):
    def __init__(
            self,
            input_file_name,
            output_file_name=None,
            progressbar=None,
            build_pin_edges=True,
            rebase_nodes=True,
            filter_nodes=True,
    ):
        if progressbar is None:
            progressbar = lambda x: x  # noqa: E731

        self.input_file_name = input_file_name
        self.progressbar = progressbar
        self.output_file_name = output_file_name

        graph_input = graph_from_xml(
            input_file_name, progressbar, filter_nodes=filter_nodes
        )
        graph_input['build_pin_edges'] = build_pin_edges

        self.root_attrib = graph_input["root_attrib"]
        del graph_input["root_attrib"]

        if rebase_nodes:
            rebase_nodes = []
            for node in graph_input['nodes']:
                node_d = node._asdict()
                node_d['id'] = len(rebase_nodes)
                rebase_nodes.append(graph2.Node(**node_d))

            graph_input['nodes'] = rebase_nodes

        self.graph = graph2.Graph(**graph_input)

        self.xf = None
        self.xf_tag = []

        if DEBUG > 0:
            self._write_xml = self._write_xml_debug
        else:
            self._write_xml = self._write_xml_no_debug

    def _write_xml_debug(self, text):
        """
        Writes to the XML file
        """
        self.xf.write(" " * len(self.xf_tag) + text + "\n")

    def _write_xml_no_debug(self, text):
        self.xf.write(text)

    def _begin_xml_tag(self, tag, attrib={}, value=None, term=False):
        """
        Writes beginning of an XML tag. If term=True then terminates it
        immediately.
        """
        s = "<{}".format(tag)
        s += "".join([' {}="{}"'.format(k, str(v)) for k, v in attrib.items()])
        if value and term:
            s += ">{}</{}>".format(value, tag)
        else:
            s += "/>" if term is True else ">"
        self._write_xml(s)

        if not term:
            self.xf_tag.append(tag)

    def _end_xml_tag(self):
        """
        Finishes the current XML tag.
        """
        assert len(self.xf_tag)

        tag = self.xf_tag[-1]
        self.xf_tag = self.xf_tag[:-1]
        self._write_xml("</{}>".format(tag))

    def _write_xml_tag(self, tag, attrib={}, value=None):
        """
        A wrapper func. to write a tag and immediately close it
        """
        self._begin_xml_tag(tag, attrib, value, True)

    def _write_xml_header(self):
        """
        Writes the RR graph XML header.
        """
        self._begin_xml_tag("rr_graph", self.root_attrib)

    def _write_channels(self, channels):
        """
        Writes the RR graph channels.
        """
        self._begin_xml_tag("channels")

        attrib = {
            "chan_width_max": channels.chan_width_max,
            "x_min": channels.x_min,
            "y_min": channels.y_min,
            "x_max": channels.x_max,
            "y_max": channels.y_max,
        }
        self._write_xml_tag("channel", attrib)

        for l in channels.x_list:
            self._write_xml_tag("x_list", {"index": l.index, "info": l.info})
            if DEBUG >= 2:
                break
        for l in channels.y_list:
            self._write_xml_tag("y_list", {"index": l.index, "info": l.info})
            if DEBUG >= 2:
                break

        self._end_xml_tag()

    def _write_connection_box(self, connection_box):
        """
        Writes the RR graph connection box.
        """
        attrib = {
            "x_dim": connection_box.x_dim,
            "y_dim": connection_box.y_dim,
            "num_boxes": len(connection_box.boxes)
        }

        self._begin_xml_tag("connection_boxes", attrib)

        for idx, box in enumerate(connection_box.boxes):
            self._write_xml_tag("connection_box", {"id": idx, "name": box})
            if DEBUG >= 2:
                break

        self._end_xml_tag()

    def _write_nodes(self, nodes, node_remap):
        """ Serialize list of Node objects to XML.

        Note that this method is extremely hot, len(nodes) is order 1-10 million.
        Almost any modification of this function has a significant effect on
        performance, so any modification to this function should be tested for
        performance and correctness before commiting.

        """

        self._begin_xml_tag("rr_nodes")

        for node in nodes:
            attrib = {
                "id": node_remap(node.id),
                "type": node.type.name,
                "capacity": node.capacity
            }

            if node.direction != NodeDirection.NO_DIR:
                attrib["direction"] = node.direction.name

            self._begin_xml_tag("node", attrib)

            attrib = {
                "xlow": node.loc.x_low,
                "xhigh": node.loc.x_high,
                "ylow": node.loc.y_low,
                "yhigh": node.loc.y_high,
                "ptc": node.loc.ptc,
            }

            if node.loc.side is not None:
                attrib["side"] = node.loc.side.name

            self._write_xml_tag("loc", attrib)

            if node.timing is not None:
                attrib = {
                    "R": node.timing.r,
                    "C": node.timing.c,
                }
                self._write_xml_tag("timing", attrib)

            if node.metadata is not None and len(node.metadata) > 0:
                self._begin_xml_tag("metadata")
                for m in node.metadata:
                    self._write_xml_tag("meta", {"name": m.name}, m.value)

                self._end_xml_tag()

            if node.segment is not None:
                attrib = {"segment_id": node.segment.segment_id}
                self._write_xml_tag("segment", attrib)

            if node.connection_box is not None:
                attrib = {
                    "x": node.connection_box.x,
                    "y": node.connection_box.y,
                    "id": node.connection_box.id,
                    "site_pin_delay": node.connection_box.site_pin_delay,
                }
                self._write_xml_tag("connection_box", attrib)

            if node.canonical_loc is not None:
                attrib = {
                    "x": node.canonical_loc.x,
                    "y": node.canonical_loc.y,
                }
                self._write_xml_tag("canonical_loc", attrib)

            self._end_xml_tag()
            if DEBUG >= 2:
                break

        self._end_xml_tag()

    def _write_edges(self, edges, node_remap):
        """ Serialize list of edge tuples objects to XML.

        edge tuples are (src_node(int), sink_node(int), switch_id(int), metadata(NodeMetadata)).

        metadata may be None.

        Note that this method is extremely hot, len(edges) is order 5-50 million.
        Almost any modification of this function has a significant effect on
        performance, so any modification to this function should be tested for
        performance and correctness before commiting.

        """
        self._begin_xml_tag("rr_edges")

        for src_node, sink_node, switch_id, metadata in edges:
            attrib = {
                "src_node": node_remap(src_node),
                "sink_node": node_remap(sink_node),
                "switch_id": switch_id,
            }

            if metadata is not None and len(metadata) > 0:
                self._begin_xml_tag("edge", attrib)
                self._begin_xml_tag("metadata")
                for name, value in metadata:
                    self._write_xml_tag("meta", {"name": name}, value)
                self._end_xml_tag()
                self._end_xml_tag()

            else:
                self._write_xml_tag("edge", attrib)

        self._end_xml_tag()

    def _write_switches(self):
        """
        Writes the RR graph switches.
        """
        self._begin_xml_tag("switches")

        for switch in self.graph.switches:
            attrib = {
                "id": switch.id,
                "type": switch.type.name.lower(),
                "name": switch.name,
            }
            self._begin_xml_tag("switch", attrib)

            if switch.timing:
                attrib = {
                    "R": switch.timing.r,
                    "Cin": switch.timing.c_in,
                    "Cout": switch.timing.c_out,
                    "Tdel": switch.timing.t_del,
                    "penalty_cost": switch.timing.p_cost,
                }

                if VPR_HAS_C_INTERNAL_SUPPORT:
                    attrib["Cinternal"] = switch.timing.c_internal

                self._write_xml_tag("timing", attrib)

            if switch.sizing:
                attrib = {
                    "mux_trans_size": switch.sizing.mux_trans_size,
                    "buf_size": switch.sizing.buf_size
                }
                self._write_xml_tag("sizing", attrib)

            self._end_xml_tag()
            if DEBUG >= 2:
                break

        self._end_xml_tag()

    def _write_segments(self):
        """
        Writes the RR graph segments.
        """
        self._begin_xml_tag("segments")

        for segment in self.graph.segments:
            attrib = {
                "id": segment.id,
                "name": segment.name,
            }
            self._begin_xml_tag("segment", attrib)

            if segment.timing:
                attrib = {
                    "R_per_meter": segment.timing.r_per_meter,
                    "C_per_meter": segment.timing.c_per_meter,
                }
                self._write_xml_tag("timing", attrib)

            self._end_xml_tag()
            if DEBUG >= 2:
                break

        self._end_xml_tag()

    def _write_block_types(self):
        """
        Writes the RR graph block types.
        """
        self._begin_xml_tag("block_types")

        for blk in self.graph.block_types:
            attrib = {
                "id": blk.id,
                "name": blk.name,
                "width": blk.width,
                "height": blk.height,
            }
            self._begin_xml_tag("block_type", attrib)

            for pin_class in blk.pin_class:
                self._begin_xml_tag(
                    "pin_class", {"type": pin_class.type.name.upper()}
                )

                for pin in pin_class.pin:
                    self._write_xml_tag("pin", {"ptc": pin.ptc}, pin.name)
                    if DEBUG >= 2:
                        break

                self._end_xml_tag()
                if DEBUG >= 2:
                    break

            self._end_xml_tag()
            if DEBUG >= 2:
                break

        self._end_xml_tag()

    def _write_grid(self):
        """
        Writes the RR graph grid.
        """
        self._begin_xml_tag("grid")

        for loc in self.graph.grid:
            attrib = {
                "x": loc.x,
                "y": loc.y,
                "block_type_id": loc.block_type_id,
                "width_offset": loc.width_offset,
                "height_offset": loc.height_offset,
            }
            self._write_xml_tag("grid_loc", attrib)
            if DEBUG >= 2:
                break

        self._end_xml_tag()

    def serialize_to_xml(
            self,
            channels_obj,
            connection_box_obj,
            nodes_obj,
            edges_obj,
            node_remap=lambda x: x
    ):
        """
        Writes the routing graph to the XML file.
        """

        self.graph.check_ptc()

        # Open the file
        with open(self.output_file_name, "w") as xf:
            self.xf = xf
            self.xf_tag = []

            # Write header
            self._write_xml_header()

            self._write_channels(channels_obj)

            if connection_box_obj is not None:
                self._write_connection_box(connection_box_obj)

            self._write_switches()
            self._write_segments()
            self._write_block_types()
            self._write_grid()

            self._write_nodes(nodes_obj, node_remap)
            self._write_edges(edges_obj, node_remap)

            # Write footer
            self._end_xml_tag()

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

        return switch_id
