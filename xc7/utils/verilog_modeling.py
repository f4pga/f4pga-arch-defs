import functools
from prjxray_make_routes import make_routes, ONE_NET, ZERO_NET
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
        self.nets = None

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

    def get_cell(self):
        return self._prefix_things(self.name)

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

        yield '{indent}) {name} ('.format(indent=indent, name=self.get_cell())

        if connections:
            yield ',\n'.join(connections[port] for port in sorted(connections))

        yield '{indent});'.format(indent=indent)


class Site(object):
    def __init__(self, features, site, tile=None):
        self.bels = []
        self.sinks = {}
        self.sources = {}
        self.outputs = {}
        self.internal_sources = {}
        self.illegal_nets = {}

        self.set_features = set()

        aparts = features[0].feature.split('.')

        for f in features:
            if f.value == 0:
                continue

            parts = f.feature.split('.')
            assert parts[0] == aparts[0]
            assert parts[1] == aparts[1]
            self.set_features.add('.'.join(parts[2:]))

        if tile is None:
            self.tile = aparts[0]
        else:
            self.tile = tile

        self.site = site

    def has_feature(self, feature):
        return feature in self.set_features

    def add_sink(self, bel, bel_pin, sink):
        """ Adds a sink.

        Attaches sink to bel.
        """

        assert bel_pin not in bel.connections

        if sink not in self.sinks:
            self.sinks[sink] = []

        bel.connections[bel_pin] = sink
        self.sinks[sink].append((bel, bel_pin))

    def add_source(self, bel, bel_pin, source):
        """ Adds a source.

        Attaches source to bel.
        """
        assert source not in self.sources
        assert bel_pin not in bel.connections

        bel.connections[bel_pin] = source
        self.sources[source] = (bel, bel_pin)

    def add_output_from_internal(self, source, internal_source):
        """ Adds a source from a site internal source. """
        assert source not in self.sources
        assert internal_source in self.internal_sources

        self.outputs[source] = internal_source
        self.sources[source] = self.internal_sources[internal_source]

    def add_output_from_output(self, source, other_source):
        assert source not in self.sources
        assert other_source in self.sources
        self.outputs[source] = other_source

    def add_internal_source(self, bel, bel_pin, wire_name):
        """ Adds a site internal source. """
        bel.connections[bel_pin] = wire_name
        self.internal_sources[bel.connections[bel_pin]] = (bel, bel_pin)

    def connect_internal(self, bel, bel_pin, source):
        assert source in self.internal_sources, source
        assert bel_pin not in bel.connections
        bel.connections[bel_pin] = source

    def add_illegal_connection(self, sink, source):
        self.illegal_nets[sink] = source

    def integrate_site(self, conn, module):
        self.check_site()

        prefix = '{}_{}'.format(self.tile, self.site.name)

        site_pin_map = make_site_pin_map(frozenset(self.site.site_pins))

        # Sanity check BEL connections
        for bel in self.bels:
            bel.set_prefix(prefix)
            bel.set_site(self.site.name)

            for wire in bel.connections.values():
                if wire == 0 or wire == 1:
                    continue

                assert wire in self.sinks or \
                       wire in self.sources or \
                       wire in self.internal_sources or \
                       module.is_top_level(wire), wire

        wires = set()
        unrouted_sinks = set()
        unrouted_sources = set()
        wire_pkey_to_wire = {}
        source_bels = {}
        wire_assigns = {}

        for wire in self.internal_sources:
            prefix_wire = prefix + '_' + wire
            wires.add(prefix_wire)

        for wire in self.sinks:
            if wire is module.is_top_level(wire):
                continue

            prefix_wire = prefix + '_' + wire
            wires.add(prefix_wire)
            wire_pkey = get_wire_pkey(conn, self.tile, site_pin_map[wire])
            wire_pkey_to_wire[wire_pkey] = prefix_wire
            unrouted_sinks.add(wire_pkey)

        for wire in self.sources:
            if wire is module.is_top_level(wire):
                continue

            prefix_wire = prefix + '_' + wire
            wires.add(prefix_wire)
            wire_pkey = get_wire_pkey(conn, self.tile, site_pin_map[wire])
            wire_pkey_to_wire[wire_pkey] = prefix_wire
            unrouted_sources.add(wire_pkey)

            source_bel = self.sources[wire]

            if source_bel is not None:
                source_bels[wire_pkey] = source_bel

        for source_wire, sink_wire in self.outputs.items():
            wires.add(prefix + '_' + source_wire)
            wire_assigns[prefix + '_' + source_wire] = prefix + '_' + sink_wire

        return dict(
                wires=wires,
                unrouted_sinks=unrouted_sinks,
                unrouted_sources=unrouted_sources,
                wire_pkey_to_wire=wire_pkey_to_wire,
                source_bels=source_bels,
                wire_assigns=wire_assigns,
                )

    def check_site(self):
        internal_sources = set(self.internal_sources.keys())
        sinks = set(self.sinks.keys())
        sources = set(self.sources.keys())

        assert len(internal_sources & sinks) == 0, (internal_sources & sinks)
        assert len(internal_sources & sources) == 0, (internal_sources & sources)

        for sink, source in self.illegal_nets.items():
            assert sink in self.sinks
            assert source in self.sources

        bel_ids = set()
        for bel in self.bels:
            bel_ids.add(id(bel))

        for bel_pair in self.sources.values():
            if bel_pair is not None:
                bel, _ = bel_pair
                assert id(bel) in bel_ids

        for sinks in self.sinks.values():
            for bel, _ in sinks:
                assert id(bel) in bel_ids

        for bel_pair in self.internal_sources.values():
            if bel_pair is not None:
                bel, _ = bel_pair
                assert id(bel) in bel_ids


    def add_bel(self, bel):
        self.bels.append(bel)

@functools.lru_cache(maxsize=None)
def make_site_pin_map(site_pins):
    site_pin_map = {}

    for site_pin in site_pins:
        site_pin_map[site_pin.name] = site_pin.wire

    return site_pin_map

def merge_exclusive_sets(set_a, set_b):
    assert len(set_a & set_b) == 0, (set_a & set_b)

    set_a |= set_b

def merge_exclusive_dicts(dict_a, dict_b):
    assert len(set(dict_a.keys()) & set(dict_b.keys())) == 0

    dict_a.update(dict_b)

class Module(object):
    def __init__(self, db, grid, conn):
        self.iostandard = None
        self.db = db
        self.grid = grid
        self.conn = conn
        self.sites = []
        self.source_bels = {}

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

    def add_site(self, site):
        integrated_site = site.integrate_site(self.conn, self)

        merge_exclusive_sets(self.wires, integrated_site['wires'])
        merge_exclusive_sets(self.unrouted_sinks, integrated_site['unrouted_sinks'])
        merge_exclusive_sets(self.unrouted_sources, integrated_site['unrouted_sources'])

        merge_exclusive_dicts(self.wire_pkey_to_wire, integrated_site['wire_pkey_to_wire'])
        merge_exclusive_dicts(self.source_bels, integrated_site['source_bels'])
        merge_exclusive_dicts(self.wire_assigns, integrated_site['wire_assigns'])

        self.sites.append(site)

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

        for site in self.sites:
            for bel in site.bels:
                yield ''
                for l in bel.output_verilog(self, indent='  '):
                    yield l

        for lhs, rhs in self.wire_assigns.items():
            yield '  assign {} = {};'.format(lhs, rhs)

        yield 'endmodule'


    def make_routes(self, allow_orphan_sinks):
        self.nets = {}
        for sink_wire, src_wire in make_routes(
                db=self.db,
                conn=self.conn,
                wire_pkey_to_wire=self.wire_pkey_to_wire,
                unrouted_sinks=self.unrouted_sinks,
                unrouted_sources=self.unrouted_sources,
                active_pips=self.active_pips,
                allow_orphan_sinks=allow_orphan_sinks,
                nets=self.nets):
            self.wire_assigns[sink_wire] = src_wire

    def output_nets(self):
        for net_wire_pkey, net in self.nets.items():
            if net_wire_pkey in [ZERO_NET, ONE_NET]:
                continue

            if net_wire_pkey not in self.source_bels:
                continue

            if not net.is_net_alive():
                continue

            bel, pin = self.source_bels[net_wire_pkey]

            yield """
set pin [get_pins {cell}/{pin}]
if {{ $pin == {{}} }} {{
    error "Failed to find pin!"
}}
set net [get_nets -of_object $pin]
if {{ $net == {{}} }} {{
    error "Failed to find net!"
}}
set_property FIXED_ROUTE {fixed_route} $net
""".format(
        cell=bel.get_cell(),
        pin=pin,
        fixed_route=' '.join(
            net.make_fixed_route(self.conn, self.wire_pkey_to_wire)))

    def get_bels(self):
        for site in self.sites:
            for bel in site.bels:
                yield bel

