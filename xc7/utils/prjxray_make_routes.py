import functools
from prjxray.tile_segbits import PsuedoPipType

ZERO_NET = -1
ONE_NET = -2

DEBUG = False

def get_node_pkey(conn, wire_pkey):
    c = conn.cursor()

    c.execute("SELECT node_pkey FROM wire WHERE pkey = ?", (wire_pkey,))

    return c.fetchone()[0]


def get_wires_in_node(conn, node_pkey):
    c = conn.cursor()

    c.execute("SELECT pkey FROM wire WHERE node_pkey = ?", (node_pkey,))

    for row in c.fetchall():
        yield row[0]

def create_check_downstream_default(conn, db):
    c = conn.cursor()

    @functools.lru_cache(maxsize=None)
    def check_for_default(wire_in_tile_pkey):
        c.execute("SELECT name, tile_type_pkey FROM wire_in_tile WHERE pkey = ?", (wire_in_tile_pkey,))
        name, tile_type_pkey = c.fetchone()

        c.execute("SELECT name FROM tile_type WHERE pkey = ?", (tile_type_pkey,))
        tile_type = c.fetchone()[0]

        tile = db.get_tile_segbits(tile_type)

        for k in tile.ppips:
            parts = k.split('.')
            assert len(parts) == 3
            assert parts[0] == tile_type

            if parts[2] == name and tile.ppips[k] == PsuedoPipType.ALWAYS:
                downstream_wire = parts[1]
                c.execute("SELECT pkey FROM wire_in_tile WHERE name = ? AND tile_type_pkey = ?;", (
                    downstream_wire, tile_type_pkey))
                downstream_wire_in_tile_pkey = c.fetchone()[0]

                return downstream_wire_in_tile_pkey

        return None

    return check_for_default


def find_downstream_node(conn, check_downstream_default, source_node_pkey):
    c = conn.cursor()

    for wire_pkey in get_wires_in_node(conn, source_node_pkey):
        c.execute("SELECT tile_pkey, wire_in_tile_pkey FROM wire WHERE pkey = ?", (wire_pkey,))
        tile_pkey, wire_in_tile_pkey = c.fetchone()

        downstream_wire_in_tile_pkey = check_downstream_default(wire_in_tile_pkey)
        if downstream_wire_in_tile_pkey is not None:
            c.execute("SELECT node_pkey FROM wire WHERE tile_pkey = ? AND wire_in_tile_pkey = ?",
                    (tile_pkey, downstream_wire_in_tile_pkey,))
            downstream_node_pkey = c.fetchone()[0]
            return downstream_node_pkey

    return None

class Net(object):
    def __init__(self, source_wire_pkey):
        self.source_wire_pkey = source_wire_pkey
        self.sink_wire_pkeys = []

        self.unexpanded_sources = set()
        self.unexpanded_sources.add(self.source_wire_pkey)

        self.route_wire_pkeys = set()

    def add_node(self, conn, net_map, node_pkey):
        if DEBUG:
            print('// sink node {} connected to source {}'.format(node_pkey, self.source_wire_pkey))

        for wire_pkey in get_wires_in_node(conn, node_pkey):
            net_map[wire_pkey] = self.source_wire_pkey
            self.route_wire_pkeys.add(wire_pkey)

    def expand_source(self, conn, check_downstream_default, net_map):
        """ Propigate net downstream through trival PPIP connections. """
        source_node_pkey = get_node_pkey(conn, self.source_wire_pkey)

        while True:
            source_node_pkey = find_downstream_node(conn, check_downstream_default, source_node_pkey)

            if source_node_pkey is not None:
                self.add_node(conn, net_map, source_node_pkey)
            else:
                break


def create_check_for_default(db, conn):
    c = conn.cursor()

    @functools.lru_cache(maxsize=None)
    def check_for_default(wire_in_tile_pkey):
        c.execute("SELECT name, tile_type_pkey FROM wire_in_tile WHERE pkey = ?", (wire_in_tile_pkey,))
        name, tile_type_pkey = c.fetchone()

        c.execute("SELECT name FROM tile_type WHERE pkey = ?", (tile_type_pkey,))
        tile_type = c.fetchone()[0]

        tile = db.get_tile_segbits(tile_type)

        for k in tile.ppips:
            parts = k.split('.')
            assert len(parts) == 3
            if k.startswith('{}.{}.'.format(tile_type, name)):
                assert tile.ppips[k] in [PsuedoPipType.ALWAYS, PsuedoPipType.DEFAULT], (k, tile.ppips[k])

                upstream_wire = parts[2]

                c.execute("SELECT pkey FROM wire_in_tile WHERE name = ? AND tile_type_pkey = ?;", (
                    upstream_wire, tile_type_pkey))

                upstream_wire_in_tile_pkey = c.fetchone()[0]

                return upstream_wire_in_tile_pkey

        return None

    return check_for_default

def expand_sink(conn, check_for_default, nets, net_map,
        source_to_sink_pip_map, sink_wire_pkey,
        allow_orphan_sinks):
    if sink_wire_pkey in net_map:
        return

    c = conn.cursor()

    c.execute("SELECT wire_in_tile_pkey, tile_pkey FROM wire WHERE pkey = ?",
            (sink_wire_pkey,))
    wire_in_tile_pkey, tile_pkey = c.fetchone()

    c.execute("SELECT name FROM tile WHERE pkey = ?", (tile_pkey,))
    (tile_name,) = c.fetchone()

    c.execute("SELECT name FROM wire_in_tile WHERE pkey = ?", (wire_in_tile_pkey,))
    (wire_name,) = c.fetchone()

    if DEBUG:
        print('//', tile_name, wire_name, sink_wire_pkey)

    sink_node_pkey = get_node_pkey(conn, sink_wire_pkey)

    c.execute("SELECT site_wire_pkey FROM node WHERE pkey = ?", (sink_node_pkey,))
    site_wire_pkey = c.fetchone()[0]
    if site_wire_pkey is not None:
        c.execute("""
SELECT site_pin_pkey FROM wire_in_tile WHERE pkey = (
        SELECT wire_in_tile_pkey FROM wire WHERE pkey = ?);""", (site_wire_pkey,))
        site_pin_pkey = c.fetchone()[0]

        assert site_pin_pkey is not None

        c.execute("SELECT name, direction FROM site_pin WHERE pkey = ?;""", (site_pin_pkey,))
        site_pin, direction = c.fetchone()

        if direction == 'OUT':
            if site_pin == 'HARD1':
                nets[ONE_NET].add_node(conn, net_map, sink_node_pkey)
            elif site_pin == 'HARD0':
                nets[ZERO_NET].add_node(conn, net_map, sink_node_pkey)
            else:
                c.execute("SELECT name FROM tile WHERE pkey = (SELECT tile_pkey FROM wire WHERE pkey = ?)", (site_wire_pkey,))
                tile = c.fetchone()[0]
                assert site_pin in ['HARD1', 'HARD0'], (sink_node_pkey, tile, site_pin)

            return

    for node_wire_pkey in get_wires_in_node(conn, sink_node_pkey):
        assert node_wire_pkey not in net_map

        if node_wire_pkey in source_to_sink_pip_map:
            upstream_sink_wire_pkey = source_to_sink_pip_map[node_wire_pkey]

            if upstream_sink_wire_pkey not in net_map:
                expand_sink(
                        conn=conn,
                        check_for_default=check_for_default,
                        nets=nets,
                        net_map=net_map,
                        source_to_sink_pip_map=source_to_sink_pip_map,
                        sink_wire_pkey=upstream_sink_wire_pkey,
                        allow_orphan_sinks=allow_orphan_sinks)

            if upstream_sink_wire_pkey in net_map:
                if DEBUG:
                    print('// {}/{} is connected to net via wire_pkey {}'.format(
                        tile_name, wire_name, upstream_sink_wire_pkey))

                nets[net_map[upstream_sink_wire_pkey]].add_node(conn, net_map, sink_node_pkey)
            return

    # No active pips to move upstream, find a ppip upstream
    for node_wire_pkey in get_wires_in_node(conn, sink_node_pkey):
        c.execute("SELECT tile_pkey, wire_in_tile_pkey FROM wire WHERE pkey = ?;", (node_wire_pkey,))
        tile_pkey, wire_in_tile_pkey = c.fetchone()

        upstream_sink_wire_in_tile_pkey = check_for_default(wire_in_tile_pkey)

        if upstream_sink_wire_in_tile_pkey is not None:
            c.execute("SELECT pkey FROM wire WHERE wire_in_tile_pkey = ? AND tile_pkey = ?;",
                    (upstream_sink_wire_in_tile_pkey, tile_pkey,))
            upstream_sink_wire_pkey = c.fetchone()[0]

            if upstream_sink_wire_pkey not in net_map:
                expand_sink(
                        conn=conn,
                        check_for_default=check_for_default,
                        nets=nets,
                        net_map=net_map,
                        source_to_sink_pip_map=source_to_sink_pip_map,
                        sink_wire_pkey=upstream_sink_wire_pkey,
                        allow_orphan_sinks=allow_orphan_sinks)

            if upstream_sink_wire_pkey in net_map:
                if DEBUG:
                    print('// {}/{} is connected to net via wire_pkey {}'.format(
                        tile_name, wire_name, upstream_sink_wire_pkey))

                nets[net_map[upstream_sink_wire_pkey]].add_node(conn, net_map, sink_node_pkey)
            return

    if allow_orphan_sinks:
        print('// ERROR, failed to find source for node = {}'.format(sink_node_pkey))
    else:
        assert False, (sink_node_pkey, tile_name, wire_name, sink_wire_pkey)


def make_routes(db, conn, wire_pkey_to_wire, unrouted_sinks, unrouted_sources, active_pips, allow_orphan_sinks):
    """ Form nets (and their routes) based:

    unrouted_sinks - Set of wire_pkeys of sinks to BELs in the graph
    unrouted_sources - Set of wire_pkeys of sources from BELs in the graph
    active_pips - Known active pips, (sink wire_pkey, source wire_pkey).

    Once nets are formed, wire_pkey_to_wire maps wire_pkeys back to wire names.

    """
    for wire_pkey in unrouted_sinks:
        assert wire_pkey in wire_pkey_to_wire

    for wire_pkey in unrouted_sources:
        assert wire_pkey in wire_pkey_to_wire

    source_to_sink_pip_map = {}

    for sink_wire_pkey, source_wire_pkey in active_pips:
        assert source_wire_pkey not in source_to_sink_pip_map
        source_to_sink_pip_map[source_wire_pkey] = sink_wire_pkey

    # Every sink should belong to exactly 1 net
    # Every net should have exactly 1 source
    check_downstream_default = create_check_downstream_default(conn, db)

    nets = {}
    net_map = {}

    def report_sources():
        print('// Source wire pkeys:')
        c = conn.cursor()
        for wire_pkey in unrouted_sources:
            c.execute("SELECT tile_pkey, wire_in_tile_pkey FROM wire WHERE pkey = ?", (wire_pkey,))
            tile_pkey, wire_in_tile_pkey = c.fetchone()

            c.execute("SELECT name, tile_type_pkey FROM wire_in_tile WHERE pkey = ?", (
                wire_in_tile_pkey,))
            name, tile_type_pkey = c.fetchone()

            c.execute("SELECT name FROM tile WHERE pkey = ?", (tile_pkey,))
            tile = c.fetchone()[0]

            print('//', wire_pkey, tile, name)

    if DEBUG:
        report_sources()

    for wire_pkey in unrouted_sources:
        nets[wire_pkey] = Net(wire_pkey)
        nets[wire_pkey].add_node(conn, net_map, get_node_pkey(conn, wire_pkey))
        nets[wire_pkey].expand_source(conn, check_downstream_default, net_map)
    del check_downstream_default

    nets[ZERO_NET] = Net(ZERO_NET)
    nets[ONE_NET] = Net(ONE_NET)

    check_for_default = create_check_for_default(db, conn)

    for wire_pkey in unrouted_sinks:
        expand_sink(
                conn=conn,
                check_for_default=check_for_default,
                nets=nets,
                net_map=net_map,
                source_to_sink_pip_map=source_to_sink_pip_map,
                sink_wire_pkey=wire_pkey,
                allow_orphan_sinks=allow_orphan_sinks)

        if wire_pkey in net_map:
            source_wire_pkey = net_map[wire_pkey]

            if source_wire_pkey == ZERO_NET:
                yield wire_pkey_to_wire[wire_pkey], 0
            elif source_wire_pkey == ONE_NET:
                yield wire_pkey_to_wire[wire_pkey], 1
            else:
                yield wire_pkey_to_wire[wire_pkey], wire_pkey_to_wire[source_wire_pkey]
        else:
            if allow_orphan_sinks:
                print('// ERROR, source for sink wire {} not found'.format(wire_pkey_to_wire[wire_pkey]))
