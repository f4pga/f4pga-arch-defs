import functools
from prjxray_make_routes import make_routes
from lib.connection_database import get_wire_pkey


class Bel(object):
    def __init__(self, module, name=None, keep=True):
        self.module = module
        if name is None:
            self.name = module
        else:
            self.name = name
        self.connections = {}
        self.unused_connections = set()
        self.parameters = {}
        self.prefix = None
        self.site = None
        self.keep = keep
        self.bel = None

    def set_prefix(self, prefix):
        self.prefix = prefix

    def set_site(self, site):
        self.site = site

    def set_bel(self, bel):
        self.bel = bel

    def _prefix_things(self, s):
        if self.prefix is not None:
            return '{}_{}'.format(self.prefix, s)
        else:
            return s

    def output_verilog(self, top, indent='  '):
        connections = {}
        buses = {}

        for wire, connection in self.connections.items():
            if top.is_top_level(connection):
                connection_wire = connection
            elif connection in [0, 1]:
                connection_wire = connection
            else:
                connection_wire = self._prefix_things(connection)

            if '[' in wire:
                bus_name, address = wire.split('[')
                assert address[-1] == ']', address

                if bus_name not in buses:
                    buses[bus_name] = {}

                buses[bus_name][int(address[:-1])] = connection_wire
            else:
                connections[wire] = '{indent}{indent}.{wire}({connection})'.format(indent=indent, wire=wire, connection=connection_wire)

        for bus_name, bus in buses.items():
            bus_wires = [0 for _ in range(max(bus.keys())+1)]

            for idx, _ in enumerate(bus_wires):
                assert idx in bus
                bus_wires[idx] = bus[idx]

            connections[bus_name] = '{indent}{indent}.{bus_name}({connection})'.format(
                indent=indent,
                bus_name=bus_name,
                connection='{{{}}}'.format(', '.join(bus_wires[::-1])))

        for unused_connection in self.unused_connections:
            connections[unused_connection] = '{indent}{indent}.{connection}()'.format(
                    indent=indent,
                    connection=unused_connection)

        yield ''

        if self.site is not None:
            comment = []
            if self.keep:
                comment.append('KEEP')
                comment.append('DONT_TOUCH')

            comment.append('LOC = "{site}"'.format(site=self.site))

            if self.bel:
                comment.append('BEL = "{bel}"'.format(bel=self.bel))

            yield '{indent}(* {comment} *)'.format(
                    indent=indent,
                    comment=', '.join(comment))

        yield '{indent}{site} #('.format(indent=indent, site=self.module)

        parameters = []
        for param, value in sorted(self.parameters.items(), key=lambda x: x[0]):
            parameters.append('{indent}{indent}.{param}({value})'.format(indent=indent, param=param, value=value))

        if parameters:
            yield ',\n'.join(parameters)

        yield '{indent}) {name} ('.format(indent=indent, name=self._prefix_things(self.name))

        if connections:
            yield ',\n'.join(connections[port] for port in sorted(connections))

        yield '{indent});'.format(indent=indent)


@functools.lru_cache(maxsize=None)
def make_site_pin_map(site_pins):
    site_pin_map = {}

    for site_pin in site_pins:
        site_pin_map[site_pin.name] = site_pin.wire

    return site_pin_map


class Module(object):
    def __init__(self, db, grid, conn):
        self.iostandard = None
        self.db = db
        self.grid = grid
        self.conn = conn
        self.bels = []

        # Map of wire_pkey to Verilog wire.
        self.wire_pkey_to_wire = {}

        # wire_pkey of sinks that are not connected to their routing.
        self.unrouted_sinks = set()

        # wire_pkey of sources that are not connected to their routing.
        self.unrouted_sources = set()

        # Known active pips, tuples of sink and source wire_pkey's.
        # The sink wire_pkey is a net with the source wire_pkey.
        self.active_pips = set()

        self.root_in = set()
        self.root_out = set()
        self.root_inout = set()

        self.wires = set()
        self.wire_assigns = {}

    def set_iostandard(self, iostandards):
        possible_iostandards = set(iostandards[0])

        for l in iostandards:
            possible_iostandards &= set(l)

        if len(possible_iostandards) != 1:
            raise RuntimeError('Ambigous IOSTANDARD, must specify possibilities: {}'.format(possible_iostandards))

        self.iostandard = possible_iostandards.pop()

    def add_top_in_port(self, tile, site, name):
        port = '{}_{}_{}'.format(tile, site, name)
        self.root_in.add(port)
        return port

    def add_top_out_port(self, tile, site, name):
        port = '{}_{}_{}'.format(tile, site, name)
        self.root_out.add(port)
        return port

    def add_top_inout_port(self, tile, site, name):
        port = '{}_{}_{}'.format(tile, site, name)
        self.root_inout.add(port)
        return port

    def is_top_level(self, wire):
        return wire in self.root_in or wire in self.root_out or wire in self.root_inout

    def add_site(self, tile, site, bels, outputs, sinks, sources, internal_sources):
        prefix = '{}_{}'.format(tile, site.name)

        site_pin_map = make_site_pin_map(frozenset(site.site_pins))

        # Sanity check BEL connections
        for bel in bels:
            bel.set_prefix(prefix)
            bel.set_site(site.name)

            for wire in bel.connections.values():
                if wire == 0 or wire == 1:
                    continue

                assert wire in sinks or \
                       wire in sources or \
                       wire in internal_sources or \
                       self.is_top_level(wire), wire

        for wire in internal_sources:
            prefix_wire = prefix + '_' + wire
            self.wires.add(prefix_wire)

        for wire in sinks:
            if wire is self.is_top_level(wire):
                continue

            prefix_wire = prefix + '_' + wire
            self.wires.add(prefix_wire)
            wire_pkey = get_wire_pkey(self.conn, tile, site_pin_map[wire])
            self.wire_pkey_to_wire[wire_pkey] = prefix_wire
            self.unrouted_sinks.add(wire_pkey)

        for wire in sources:
            if wire is self.is_top_level(wire):
                continue

            prefix_wire = prefix + '_' + wire
            self.wires.add(prefix_wire)
            wire_pkey = get_wire_pkey(self.conn, tile, site_pin_map[wire])
            self.wire_pkey_to_wire[wire_pkey] = prefix_wire
            self.unrouted_sources.add(wire_pkey)

        self.bels.extend(bels)

        for source_wire, sink_wire in outputs.items():
            self.wires.add(prefix + '_' + source_wire)
            self.wire_assigns[prefix + '_' + source_wire] = prefix + '_' + sink_wire

        assert len(internal_sources & sinks) == 0, (internal_sources & sinks)
        assert len(internal_sources & sources) == 0, (internal_sources & sources)


    def output_verilog(self):
        root_module_args = []
        for in_wire in sorted(self.root_in):
            root_module_args.append('  input ' + in_wire)
        for out_wire in sorted(self.root_out):
            root_module_args.append('  output ' + out_wire)
        for inout_wire in sorted(self.root_inout):
            root_module_args.append('  inout ' + inout_wire)

        yield 'module top('

        yield ',\n'.join(root_module_args)

        yield '  );'

        for wire in sorted(self.wires):
            yield '  wire {};'.format(wire)

        for bel in self.bels:
            yield ''
            for l in bel.output_verilog(self, indent='  '):
                yield l

        for lhs, rhs in self.wire_assigns.items():
            yield '  assign {} = {};'.format(lhs, rhs)

        yield 'endmodule'


    def make_routes(self, allow_orphan_sinks):
        for sink_wire, src_wire in make_routes(
                db=self.db,
                conn=self.conn,
                wire_pkey_to_wire=self.wire_pkey_to_wire,
                unrouted_sinks=self.unrouted_sinks,
                unrouted_sources=self.unrouted_sources,
                active_pips=self.active_pips,
                allow_orphan_sinks=allow_orphan_sinks):
            self.wire_assigns[sink_wire] = src_wire

