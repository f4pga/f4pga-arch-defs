import os.path
import re
from lib.rr_graph import graph2
from lib.rr_graph import tracks
import gc

import capnp
import capnp.lib.capnp
capnp.remove_import_hook()

CAMEL_CASE_CAPITALS = re.compile('([A-Z]+)')

ENUM_CACHE = {}


def enum_from_string(enum_type, s):
    if s == 'uxsdInvalid':
        return None

    s = str(s)
    key = (id(enum_type), s)
    if key not in ENUM_CACHE:
        ENUM_CACHE[key] = enum_type[CAMEL_CASE_CAPITALS.sub(r'_\1', s).upper()]
    return ENUM_CACHE[key]


CAPNP_ENUM_CACHE = {}


def to_capnp_enum(enum_type, e):
    key = (id(enum_type), e)

    if key not in CAPNP_ENUM_CACHE:
        # Convert from snake_case to camelCase.
        parts = []
        for idx, part in enumerate(e.name.split('_')):
            if idx == 0:
                parts.append(part.lower())
            else:
                parts.append(part.capitalize())
        camel_case_e = "".join(parts)

        CAPNP_ENUM_CACHE[key] = enum_type.__dict__[camel_case_e]

    return CAPNP_ENUM_CACHE[key]


def cleanup_capnp_leak(f):
    """ Cleanup capnp leak resulting from _parent pointers. """
    popped = set()
    strays = {}

    # Some strays hold a reference to the input file
    strays.update(
        (id(obj), obj)
        for obj in gc.get_referrers(f)
        if 'capnp' in str(type(obj))
    )

    # Some strays are "floating"
    for obj in gc.get_objects():
        type_str = str(type(obj))
        if 'capnp.lib.capnp._DynamicStructReader' in type_str:
            strays[id(obj)] = obj

    if len(strays) > 0:
        # First expand all strays and find other capnp objects that still hold
        # a reference to them (via the _parent pointer).
        for obj_id in set(strays.keys()) - popped:
            popped.add(obj_id)
            strays.update(
                (id(obj), obj)
                for obj in gc.get_referrers(strays[obj_id])
                if 'capnp' in str(type(obj))
            )

        # Clear their _parent pointer
        for obj in strays.values():
            obj._parent = None

        # Make sure none of the strays are still referred to by anything
        for obj in strays.values():
            capnp_refs = [
                None for obj in gc.get_referrers(strays[obj_id])
                if 'capnp' in str(type(obj))
            ]
            assert len(capnp_refs) == 0

        # Make sure the file is not referenced by any files.
        capnp_refs = [
            None for obj in gc.get_referrers(f) if 'capnp' in str(type(obj))
        ]
        assert len(capnp_refs) == 0


def read_switch(sw):
    timing = sw.timing
    sizing = sw.sizing

    return graph2.Switch(
        id=sw.id,
        name=str(sw.name),
        type=enum_from_string(graph2.SwitchType, sw.type),
        timing=graph2.SwitchTiming(
            r=timing.r,
            c_in=timing.cin,
            c_out=timing.cout,
            c_internal=timing.cinternal,
            t_del=timing.tdel,
        ),
        sizing=graph2.SwitchSizing(
            buf_size=sizing.bufSize,
            mux_trans_size=sizing.muxTransSize,
        ),
    )


def read_segment(seg):
    timing = seg.timing
    return graph2.Segment(
        id=seg.id,
        name=str(seg.name),
        timing=graph2.SegmentTiming(
            r_per_meter=timing.rPerMeter,
            c_per_meter=timing.cPerMeter,
        )
    )


def read_pin(pin):
    return graph2.Pin(
        ptc=pin.ptc,
        name=str(pin.value),
    )


def read_pin_class(pin_class):
    return graph2.PinClass(
        type=enum_from_string(graph2.PinType, pin_class.type),
        pin=[read_pin(pin) for pin in pin_class.pins]
    )


def read_block_type(block_type):
    return graph2.BlockType(
        id=block_type.id,
        name=str(block_type.name),
        width=block_type.width,
        height=block_type.height,
        pin_class=[
            read_pin_class(pin_class) for pin_class in block_type.pinClasses
        ]
    )


def read_grid_loc(grid_loc):
    return graph2.GridLoc(
        x=grid_loc.x,
        y=grid_loc.y,
        block_type_id=grid_loc.blockTypeId,
        width_offset=grid_loc.widthOffset,
        height_offset=grid_loc.heightOffset,
    )


def read_metadata(metadata):
    if len(metadata.metas) == 0:
        return None
    else:
        return [(str(m.name), str(m.value)) for m in metadata.metas]


def read_node(node, new_node_id=None):
    node_loc = node.loc
    node_timing = node.timing

    return graph2.Node(
        id=new_node_id if new_node_id is not None else node.id,
        type=enum_from_string(graph2.NodeType, node.type),
        direction=enum_from_string(graph2.NodeDirection, node.direction),
        capacity=node.capacity,
        loc=graph2.NodeLoc(
            x_low=node_loc.xlow,
            y_low=node_loc.ylow,
            x_high=node_loc.xhigh,
            y_high=node_loc.yhigh,
            ptc=node_loc.ptc,
            side=enum_from_string(tracks.Direction, node_loc.side),
        ),
        timing=graph2.NodeTiming(r=node_timing.r, c=node_timing.c),
        metadata=None,
        segment=graph2.NodeSegment(segment_id=node.segment.segmentId),
        canonical_loc=None,
        connection_box=None
    )


def read_edge(edge):
    return graph2.Edge(
        src_node=edge.srcNode,
        sink_node=edge.sinkNode,
        switch_id=edge.switchId,
        metadata=read_metadata(edge.metadata),
    )


def graph_from_capnp(
        rr_graph_schema,
        input_file_name,
        progressbar=None,
        filter_nodes=True,
        load_edges=False,
        rebase_nodes=False,
):
    """
    Loads relevant information about the routing resource graph from an capnp
    file.
    """
    if rebase_nodes:
        assert not load_edges

    if progressbar is None:
        progressbar = lambda x: x  # noqa: E731

    with open(input_file_name, 'rb') as f:
        graph = rr_graph_schema.RrGraph.read(
            f, traversal_limit_in_words=2**63 - 1
        )

        root_attrib = {
            'tool_comment': str(graph.toolComment),
            'tool_name': str(graph.toolName),
            'tool_version': str(graph.toolVersion),
        }

        switches = [read_switch(sw) for sw in graph.switches.switches]
        segments = [read_segment(seg) for seg in graph.segments.segments]
        block_types = [
            read_block_type(block_type)
            for block_type in graph.blockTypes.blockTypes
        ]
        grid = [read_grid_loc(g) for g in graph.grid.gridLocs]

        nodes = []
        for n in progressbar(graph.rrNodes.nodes):
            if filter_nodes and n.type not in ['source', 'sink', 'opin', 'ipin'
                                               ]:
                continue

            if rebase_nodes:
                node = read_node(n, new_node_id=len(nodes))
            else:
                node = read_node(n)

            nodes.append(node)

        edges = []
        if load_edges:
            edges = [read_edge(e) for e in graph.rrEdges.edges]

        # File back capnp objects cannot outlive their input file,
        # so verify that no dangling references exist.
        del graph
        gc.collect()

        # Cleanup leaked capnp objects due to _parent in Cython.
        cleanup_capnp_leak(f)

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
            rr_graph_schema_fname,
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

        self.rr_graph_schema = capnp.load(
            rr_graph_schema_fname,
            imports=[os.path.dirname(os.path.dirname(capnp.__file__))]
        )

        graph_input = graph_from_capnp(
            rr_graph_schema=self.rr_graph_schema,
            input_file_name=input_file_name,
            progressbar=progressbar,
            filter_nodes=filter_nodes,
            rebase_nodes=rebase_nodes,
        )
        graph_input['build_pin_edges'] = build_pin_edges

        self.root_attrib = graph_input["root_attrib"]
        del graph_input["root_attrib"]

        self.graph = graph2.Graph(**graph_input)

    def _write_channels(self, rr_graph, channels):
        """
        Writes the RR graph channels.
        """

        rr_graph.channels.channel.chanWidthMax = channels.chan_width_max
        rr_graph.channels.channel.xMax = channels.x_max
        rr_graph.channels.channel.xMin = channels.x_min
        rr_graph.channels.channel.yMax = channels.y_max
        rr_graph.channels.channel.yMin = channels.y_min

        xLists = rr_graph.channels.init('xLists', len(channels.x_list))
        for out_x_list, x_list in zip(xLists, channels.x_list):
            out_x_list.index = x_list.index
            out_x_list.info = x_list.info

        yLists = rr_graph.channels.init('yLists', len(channels.y_list))
        for out_y_list, y_list in zip(yLists, channels.y_list):
            out_y_list.index = y_list.index
            out_y_list.info = y_list.info

    def _write_connection_box(self, rr_graph, connection_box):
        """
        Writes the RR graph connection box.
        """

        rr_graph.connectionBoxes.xDim = connection_box.x_dim
        rr_graph.connectionBoxes.yDim = connection_box.y_dim
        rr_graph.connectionBoxes.numBoxes = len(connection_box.boxes)

        connection_boxes = rr_graph.connectionBoxes.init(
            'connectionBoxes', len(connection_box.boxes)
        )

        for idx, (out_box, box) in enumerate(zip(connection_boxes,
                                                 connection_box.boxes)):
            out_box.id = idx
            out_box.name = box

    def _write_nodes(self, rr_graph, num_nodes, nodes, node_remap):
        """ Serialize list of Node objects to capnp.

        Note that this method is extremely hot, len(nodes) is order 1-10 million.
        Almost any modification of this function has a significant effect on
        performance, so any modification to this function should be tested for
        performance and correctness before commiting.

        """

        rr_nodes = rr_graph.rrNodes.init('nodes', num_nodes)

        nodes_written = 0

        node_iter = iter(nodes)

        for out_node, node in zip(rr_nodes, node_iter):
            nodes_written += 1

            out_node.id = node_remap(node.id)
            out_node.type = to_capnp_enum(
                self.rr_graph_schema.NodeType, node.type
            )
            out_node.capacity = node.capacity

            if node.direction is not None:
                out_node.direction = to_capnp_enum(
                    self.rr_graph_schema.NodeDirection, node.direction
                )

            node_loc = out_node.loc
            node_loc.ptc = node.loc.ptc
            if node.loc.side is not None:
                node_loc.side = to_capnp_enum(
                    self.rr_graph_schema.LocSide, node.loc.side
                )
            node_loc.xhigh = node.loc.x_high
            node_loc.xlow = node.loc.x_low
            node_loc.yhigh = node.loc.y_high
            node_loc.ylow = node.loc.y_low

            if node.timing is not None:
                timing = out_node.timing
                timing.c = node.timing.c
                timing.r = node.timing.r

            if node.segment is not None:
                segment = out_node.segment
                segment.segmentId = node.segment.segment_id

            if node.metadata is not None and len(node.metadata) > 0:
                metas = out_node.metadata.init('metas', len(node.metadata))
                for out_meta, meta in zip(metas, node.metadata):
                    out_meta.name = meta.name
                    out_meta.value = meta.value

            if node.canonical_loc is not None:
                canonical_loc = out_node.canonicalLoc
                canonical_loc.x = node.canonical_loc.x
                canonical_loc.y = node.canonical_loc.y

            if node.connection_box is not None:
                connection_box = out_node.connectionBox
                connection_box.id = node.connection_box.id
                connection_box.x = node.connection_box.x
                connection_box.y = node.connection_box.y
                connection_box.sitePinDelay = node.connection_box.site_pin_delay

        assert nodes_written == num_nodes, 'Unwritten nodes!'

        try:
            _ = next(node_iter)
            assert False, 'Unwritten nodes!'
        except StopIteration:
            pass

    def _write_edges(self, rr_graph, num_edges, edges, node_remap):
        """ Serialize list of edge tuples objects to capnp.

        edge tuples are (src_node(int), sink_node(int), switch_id(int), metadata(NodeMetadata)).

        metadata may be None.

        Note that this method is extremely hot, len(edges) is order 5-50 million.
        Almost any modification of this function has a significant effect on
        performance, so any modification to this function should be tested for
        performance and correctness before commiting.

        """

        out_edges = rr_graph.rrEdges.init('edges', num_edges)

        edges_written = 0
        edges_iter = iter(edges)
        for out_edge, (src_node, sink_node, switch_id,
                       metadata) in zip(out_edges, edges_iter):
            edges_written += 1
            out_edge.srcNode = node_remap(src_node)
            out_edge.sinkNode = node_remap(sink_node)
            out_edge.switchId = switch_id

            if metadata is not None and len(metadata) > 0:
                metas = out_edge.metadata.init('metas', len(metadata))
                for out_meta, (name, value) in zip(metas, metadata):
                    out_meta.name = name
                    out_meta.value = value

        assert edges_written == num_edges, 'Unwritten edges!'

        try:
            _ = next(edges_iter)
            assert False, 'Unwritten edges!'
        except StopIteration:
            pass

    def _write_switches(self, rr_graph):
        """
        Writes the RR graph switches.
        """
        switches = rr_graph.switches.init('switches', len(self.graph.switches))
        for out_switch, switch in zip(switches, self.graph.switches):
            out_switch.id = switch.id
            out_switch.name = switch.name
            out_switch.type = to_capnp_enum(
                self.rr_graph_schema.SwitchType, switch.type
            )

            if switch.timing:
                timing = out_switch.timing
                timing.cin = switch.timing.c_in
                timing.cinternal = switch.timing.c_internal
                timing.cout = switch.timing.c_out
                timing.r = switch.timing.r
                timing.tdel = switch.timing.t_del

            if switch.sizing:
                sizing = out_switch.sizing
                sizing.bufSize = switch.sizing.buf_size
                sizing.muxTransSize = switch.sizing.mux_trans_size

    def _write_segments(self, rr_graph):
        """
        Writes the RR graph segments.
        """

        segments = rr_graph.segments.init('segments', len(self.graph.segments))

        for out_segment, segment in zip(segments, self.graph.segments):
            out_segment.id = segment.id
            out_segment.name = segment.name

            if segment.timing:
                timing = out_segment.timing
                timing.cPerMeter = segment.timing.c_per_meter
                timing.rPerMeter = segment.timing.r_per_meter

    def _write_block_types(self, rr_graph):
        """
        Writes the RR graph block types.
        """

        block_types = rr_graph.blockTypes.init(
            'blockTypes', len(self.graph.block_types)
        )

        for out_blk, blk in zip(block_types, self.graph.block_types):
            out_blk.id = blk.id
            out_blk.name = blk.name
            out_blk.width = blk.width
            out_blk.height = blk.height

            pin_classes = out_blk.init('pinClasses', len(blk.pin_class))

            for out_pin_class, pin_class in zip(pin_classes, blk.pin_class):
                out_pin_class.type = to_capnp_enum(
                    self.rr_graph_schema.PinType, pin_class.type
                )

                pins = out_pin_class.init('pins', len(pin_class.pin))

                for out_pin, pin in zip(pins, pin_class.pin):
                    out_pin.ptc = pin.ptc
                    out_pin.value = pin.name

    def _write_grid(self, rr_graph):
        """
        Writes the RR graph grid.
        """

        grid_locs = rr_graph.grid.init('gridLocs', len(self.graph.grid))
        for out_grid_loc, grid_loc in zip(grid_locs, self.graph.grid):
            out_grid_loc.x = grid_loc.x
            out_grid_loc.y = grid_loc.y
            out_grid_loc.blockTypeId = grid_loc.block_type_id
            out_grid_loc.widthOffset = grid_loc.width_offset
            out_grid_loc.heightOffset = grid_loc.height_offset

    def serialize_to_capnp(
            self,
            channels_obj,
            connection_box_obj,
            num_nodes,
            nodes_obj,
            num_edges,
            edges_obj,
            node_remap=lambda x: x
    ):
        """
        Writes the routing graph to the capnp file.
        """

        self.graph.check_ptc()

        rr_graph = self.rr_graph_schema.RrGraph.new_message()
        rr_graph.toolComment = self.root_attrib['tool_comment']
        rr_graph.toolName = self.root_attrib['tool_name']
        rr_graph.toolVersion = self.root_attrib['tool_version']

        self._write_channels(rr_graph, channels_obj)
        self._write_switches(rr_graph)
        self._write_segments(rr_graph)
        self._write_block_types(rr_graph)
        self._write_grid(rr_graph)
        self._write_connection_box(rr_graph, connection_box_obj)
        self._write_nodes(rr_graph, num_nodes, nodes_obj, node_remap)
        self._write_edges(rr_graph, num_edges, edges_obj, node_remap)

        # Open the file
        with open(self.output_file_name, "wb") as f:
            rr_graph.write(f)

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
