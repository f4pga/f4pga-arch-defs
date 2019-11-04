import functools

from prjxray.tile_segbits import PsuedoPipType

from .connection_db_utils import get_node_pkey, get_wires_in_node, get_wire

ZERO_NET = -1
ONE_NET = -2

DEBUG = False


def create_check_downstream_default(conn, db):
    """ Returns check_for_default function. """
    c = conn.cursor()

    @functools.lru_cache(maxsize=None)
    def check_for_default(wire_in_tile_pkey):
        """ Returns downstream wire_in_tile_pkey from given wire_in_tile_pkey.

        This function traverses "always" ppips downstream.
        Returns None if no ppips are found for the given wire_in_tile_pkey.

        """
        c.execute(
            "SELECT name, phy_tile_type_pkey FROM wire_in_tile WHERE pkey = ?",
            (wire_in_tile_pkey, )
        )
        name, phy_tile_type_pkey = c.fetchone()

        c.execute(
            "SELECT name FROM tile_type WHERE pkey = ?",
            (phy_tile_type_pkey, )
        )
        tile_type = c.fetchone()[0]

        tile = db.get_tile_segbits(tile_type)

        for k in tile.ppips:
            parts = k.split('.')
            assert len(parts) == 3
            assert parts[0] == tile_type

            if parts[2] == name and tile.ppips[k] == PsuedoPipType.ALWAYS:
                downstream_wire = parts[1]
                c.execute(
                    "SELECT pkey FROM wire_in_tile WHERE name = ? AND phy_tile_type_pkey = ?;",
                    (downstream_wire, phy_tile_type_pkey)
                )
                downstream_wire_in_tile_pkey = c.fetchone()[0]

                return downstream_wire_in_tile_pkey

        return None

    return check_for_default


def find_downstream_node(conn, check_downstream_default, source_node_pkey):
    """ Finds a downstream node starting from source_node_pkey.

    This function only traverses "always" ppips downstream, not active pips.

    Returns None if no nodes downstream are connected via "always" ppips.

    """
    c = conn.cursor()

    for wire_pkey in get_wires_in_node(conn, source_node_pkey):
        c.execute(
            "SELECT phy_tile_pkey, wire_in_tile_pkey FROM wire WHERE pkey = ?",
            (wire_pkey, )
        )
        phy_tile_pkey, wire_in_tile_pkey = c.fetchone()

        downstream_wire_in_tile_pkey = check_downstream_default(
            wire_in_tile_pkey
        )
        if downstream_wire_in_tile_pkey is not None:
            c.execute(
                "SELECT node_pkey FROM wire WHERE phy_tile_pkey = ? AND wire_in_tile_pkey = ?",
                (
                    phy_tile_pkey,
                    downstream_wire_in_tile_pkey,
                )
            )
            downstream_node_pkey = c.fetchone()[0]
            return downstream_node_pkey

    return None


def output_builder(fixed_route):
    yield '[list'

    for i in fixed_route:
        if type(i) is list:
            for i2 in output_builder(i):
                yield i2
        else:
            yield i

    # TCL cannot express 1-length list, so add an additional element to
    # prevent TCL from collapsing the 1-length list.
    yield ' {} ]'


class Net(object):
    """ Object to present a net (e.g. a source and it sinks). """

    def __init__(self, source_wire_pkey):
        """ Create a net.

        source_wire_pkey (int): A pkey from the wire table that is the source
            of this net.  This wire must be the wire connected to a site pin.

        """

        self.source_wire_pkey = source_wire_pkey
        self.route_wire_pkeys = set()
        self.parent_nodes = {}
        self.incoming_wire_map = {}

    def add_node(
            self,
            conn,
            net_map,
            node_pkey,
            parent_node_pkey,
            incoming_wire_pkey=None
    ):
        """ Add a node to a net.

        node_pkey (int): A pkey from the node table that is part of this net.
        parent_node_pkey (int): A pkey from the node table that is the source
            for node_pkey.
        incoming_wire_pkey (int): incoming_wire_pkey is the wire_pkey that is
            the connecting wire in this node.  For example, if this node is
            connected to the net via a pip, then incoming_wire_pkey should be
            the source wire_pkey from the pip.  This is important when dealing
            with bidirection pips.

        """
        if DEBUG:
            print(
                '// sink node {} connected to source {}'.format(
                    node_pkey, self.source_wire_pkey
                )
            )

        if incoming_wire_pkey is not None:
            assert node_pkey not in self.incoming_wire_map, node_pkey
            self.incoming_wire_map[node_pkey] = incoming_wire_pkey

        self.parent_nodes[node_pkey] = parent_node_pkey

        for wire_pkey in get_wires_in_node(conn, node_pkey):
            if wire_pkey not in net_map:
                net_map[wire_pkey] = set()

            net_map[wire_pkey].add(self.source_wire_pkey)
            self.route_wire_pkeys.add(wire_pkey)

    def expand_source(self, conn, check_downstream_default, net_map):
        """ Propigate net downstream through trival PPIP connections. """
        source_node_pkey = get_node_pkey(conn, self.source_wire_pkey)

        while True:
            parent_node_pkey = source_node_pkey
            source_node_pkey = find_downstream_node(
                conn, check_downstream_default, source_node_pkey
            )

            if source_node_pkey is not None:
                self.add_node(
                    conn, net_map, source_node_pkey, parent_node_pkey
                )
            else:
                break

    def prune_antennas(self, sink_node_pkeys):
        """ Remove entries from parent_nodes that belong to antenna wires.

        The expand_source may add entires in parent_nodes that are
        disconnected. hese nodes should be removed prior to outputting fixed
        routes.
        """

        alive_nodes = set()

        for node in self.parent_nodes.keys():
            if node in sink_node_pkeys:
                while node in self.parent_nodes:
                    alive_nodes.add(node)
                    node = self.parent_nodes[node]

        dead_nodes = set(self.parent_nodes.keys()) - alive_nodes

        for dead_node in dead_nodes:
            del self.parent_nodes[dead_node]

    def is_net_alive(self):
        """ True if this net is connected to sinks.

        Call this method after invoked prune_antennas to avoid false positives.

        """
        return len(self.parent_nodes) > 0

    def make_fixed_route(self, conn, wire_pkey_to_wire):
        """ Yields a TCL statement that is the value for the FIXED_ROUTE param.

        Should invoke this method after calling prune_antennas.
        """

        source_to_sink_node_map = {}

        for sink, src in self.parent_nodes.items():
            if src not in source_to_sink_node_map:
                source_to_sink_node_map[src] = []

            source_to_sink_node_map[src].append(sink)

        c = conn.cursor()

        def get_a_wire(node_pkey):
            c.execute(
                "SELECT phy_tile_pkey, wire_in_tile_pkey FROM wire WHERE node_pkey = ? LIMIT 1",
                (node_pkey, )
            )
            (
                phy_tile_pkey,
                wire_in_tile_pkey,
            ) = c.fetchone()
            c.execute(
                "SELECT name FROM phy_tile WHERE pkey = ?", (phy_tile_pkey, )
            )
            tile_name = c.fetchone()[0]
            c.execute(
                "SELECT name FROM wire_in_tile WHERE pkey = ?",
                (wire_in_tile_pkey, )
            )
            wire_name = c.fetchone()[0]

            return tile_name + '/' + wire_name

        def descend_fixed_route(source_node_pkey, fixed_route):
            if source_node_pkey in self.incoming_wire_map:
                c.execute(
                    "SELECT wire_in_tile_pkey, phy_tile_pkey FROM wire WHERE pkey = ?",
                    (self.incoming_wire_map[source_node_pkey], )
                )
                wire_in_tile_pkey, phy_tile_pkey = c.fetchone()

                c.execute(
                    "SELECT name FROM phy_tile WHERE pkey = ?",
                    (phy_tile_pkey, )
                )
                (tile_name, ) = c.fetchone()

                c.execute(
                    "SELECT name FROM wire_in_tile WHERE pkey = ?",
                    (wire_in_tile_pkey, )
                )
                (wire_name, ) = c.fetchone()

                wire_name = tile_name + '/' + wire_name
            else:
                # We don't have a specific upstream wire, use any from the node
                wire_name = get_a_wire(source_node_pkey)
                wire_name = '[get_nodes -of_object [get_wires {}]]'.format(
                    wire_name
                )

            fixed_route.append(wire_name)

            if source_node_pkey not in source_to_sink_node_map:
                return

            descend_routes = []

            for _ in range(len(source_to_sink_node_map[source_node_pkey]) - 1):
                fixed_route.append([])
                descend_routes.append(fixed_route[-1])

            descend_routes.append(fixed_route)

            for idx, next_node_pkey in enumerate(
                    source_to_sink_node_map[source_node_pkey]):
                descend_fixed_route(next_node_pkey, descend_routes[idx])

        if self.source_wire_pkey not in [ZERO_NET, ONE_NET]:
            fixed_route = []
            descend_fixed_route(
                get_node_pkey(conn, self.source_wire_pkey), fixed_route
            )

            for i in output_builder(fixed_route):
                yield i
        else:
            source_nodes = []
            for node, parent_node in self.parent_nodes.items():
                if parent_node == self.source_wire_pkey:
                    source_nodes.append(node)

            yield '[list '

            for source_node in source_nodes:
                yield '('
                fixed_route = []
                descend_fixed_route(source_node, fixed_route)
                for i in output_builder(fixed_route):
                    yield i

                yield ')'

            # TCL cannot express 1-length list, so add an additional element
            # to prevent TCL from collapsing the 1-length list.
            yield '{} ]'


def create_check_for_default(db, conn):
    """ Returns check_for_default function. """
    c = conn.cursor()

    @functools.lru_cache(maxsize=None)
    def check_for_default(wire_in_tile_pkey):
        """ Returns upstream wire_in_tile_pkey from given wire_in_tile_pkey.

        This function traverses "always" or "default" ppips upstream. Because
        this function will traverse "default" ppips, it should only be invoked
        on wire_in_tile_pkey that have no active upstream pips, otherwise an
        invalid connection could be made.

        Returns None if no ppips are found for the given wire_in_tile_pkey.

        """
        c.execute(
            "SELECT name, phy_tile_type_pkey FROM wire_in_tile WHERE pkey = ?",
            (wire_in_tile_pkey, )
        )
        name, phy_tile_type_pkey = c.fetchone()

        c.execute(
            "SELECT name FROM tile_type WHERE pkey = ?",
            (phy_tile_type_pkey, )
        )
        tile_type = c.fetchone()[0]

        tile = db.get_tile_segbits(tile_type)

        # The xMUX wires have multiple "hint" connections.  Deal with them
        # specially.
        if name in [
                'CLBLM_L_AMUX',
                'CLBLM_L_BMUX',
                'CLBLM_L_CMUX',
                'CLBLM_L_DMUX',
                'CLBLM_M_AMUX',
                'CLBLM_M_BMUX',
                'CLBLM_M_CMUX',
                'CLBLM_M_DMUX',
                'CLBLL_L_AMUX',
                'CLBLL_L_BMUX',
                'CLBLL_L_CMUX',
                'CLBLL_L_DMUX',
                'CLBLL_LL_AMUX',
                'CLBLL_LL_BMUX',
                'CLBLL_LL_CMUX',
                'CLBLL_LL_DMUX',
        ]:
            upstream_wire = name.replace('MUX', '')
            c.execute(
                "SELECT pkey FROM wire_in_tile WHERE name = ? AND phy_tile_type_pkey = ?;",
                (upstream_wire, phy_tile_type_pkey)
            )

            upstream_wire_in_tile_pkey = c.fetchone()[0]

            return upstream_wire_in_tile_pkey

        for k in tile.ppips:
            parts = k.split('.')
            assert len(parts) == 3
            if k.startswith('{}.{}.'.format(tile_type, name)):
                assert tile.ppips[k] in [
                    PsuedoPipType.ALWAYS, PsuedoPipType.DEFAULT
                ], (k, tile.ppips[k])

                upstream_wire = parts[2]

                c.execute(
                    "SELECT pkey FROM wire_in_tile WHERE name = ? AND phy_tile_type_pkey = ?;",
                    (upstream_wire, phy_tile_type_pkey)
                )

                upstream_wire_in_tile_pkey = c.fetchone()[0]

                return upstream_wire_in_tile_pkey

        return None

    return check_for_default


def expand_sink(
        conn, check_for_default, nets, net_map, source_to_sink_pip_map,
        sink_wire_pkey, allow_orphan_sinks
):
    """ Attempt to expand a sink to its source. """
    if sink_wire_pkey in net_map:
        return

    c = conn.cursor()

    c.execute(
        "SELECT wire_in_tile_pkey, phy_tile_pkey FROM wire WHERE pkey = ?",
        (sink_wire_pkey, )
    )
    wire_in_tile_pkey, phy_tile_pkey = c.fetchone()

    c.execute("SELECT name FROM phy_tile WHERE pkey = ?", (phy_tile_pkey, ))
    (tile_name, ) = c.fetchone()

    c.execute(
        "SELECT name FROM wire_in_tile WHERE pkey = ?", (wire_in_tile_pkey, )
    )
    (wire_name, ) = c.fetchone()

    if DEBUG:
        print('//', tile_name, wire_name, sink_wire_pkey)

    sink_node_pkey = get_node_pkey(conn, sink_wire_pkey)

    # Check if there is an upstream active pip on this node.
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
                    allow_orphan_sinks=allow_orphan_sinks
                )

            if upstream_sink_wire_pkey in net_map:
                if DEBUG:
                    print(
                        '// {}/{} is connected to net via wire_pkey {}'.format(
                            tile_name, wire_name, upstream_sink_wire_pkey
                        )
                    )

                for net in net_map[upstream_sink_wire_pkey]:
                    nets[net].add_node(
                        conn=conn,
                        net_map=net_map,
                        node_pkey=sink_node_pkey,
                        parent_node_pkey=get_node_pkey(
                            conn, upstream_sink_wire_pkey
                        ),
                        incoming_wire_pkey=node_wire_pkey
                    )
                return

    # There are no active pips upstream from this node, check if this is a
    # site pin connected to a HARD0 or HARD1 pin.  These are connected to the
    # global ZERO_NET or ONE_NET.
    c.execute(
        "SELECT site_wire_pkey FROM node WHERE pkey = ?", (sink_node_pkey, )
    )
    site_wire_pkey = c.fetchone()[0]
    if site_wire_pkey is not None:
        upstream_sink_wire_in_tile_pkey = check_for_default(wire_in_tile_pkey)
        if upstream_sink_wire_in_tile_pkey is not None:
            upstream_sink_wire_pkey = get_wire(
                conn, phy_tile_pkey, upstream_sink_wire_in_tile_pkey
            )

            if upstream_sink_wire_pkey in net_map:
                if DEBUG:
                    print(
                        '// {}/{} is connected to net via wire_pkey {}'.format(
                            tile_name, wire_name, upstream_sink_wire_pkey
                        )
                    )

                for net in net_map[upstream_sink_wire_pkey]:
                    nets[net].add_node(
                        conn=conn,
                        net_map=net_map,
                        node_pkey=sink_node_pkey,
                        parent_node_pkey=get_node_pkey(
                            conn, upstream_sink_wire_pkey
                        ),
                        incoming_wire_pkey=sink_wire_pkey,
                    )
                return

        c.execute(
            """
SELECT name, site_pin_pkey FROM wire_in_tile WHERE pkey = (
        SELECT wire_in_tile_pkey FROM wire WHERE pkey = ?);""",
            (site_wire_pkey, )
        )
        wire_name, site_pin_pkey = c.fetchone()

        assert site_pin_pkey is not None

        c.execute(
            "SELECT name, direction FROM site_pin WHERE pkey = ?;"
            "", (site_pin_pkey, )
        )
        site_pin, direction = c.fetchone()

        if direction == 'OUT':
            if DEBUG:
                print(
                    '// {}/{} is connected to const'.format(
                        tile_name, wire_name
                    )
                )

            if site_pin == 'HARD1':
                nets[ONE_NET].add_node(
                    conn, net_map, sink_node_pkey, parent_node_pkey=ONE_NET
                )
            elif site_pin == 'HARD0':
                nets[ZERO_NET].add_node(
                    conn, net_map, sink_node_pkey, parent_node_pkey=ZERO_NET
                )
            else:
                c.execute(
                    "SELECT name FROM phy_tile WHERE pkey = (SELECT phy_tile_pkey FROM wire WHERE pkey = ?)",
                    (site_wire_pkey, )
                )
                tile = c.fetchone()[0]
                assert site_pin in [
                    'HARD1', 'HARD0'
                ], (sink_node_pkey, tile, wire_name, site_pin)

            return

    # No active pips to move upstream, find a ppip upstream
    for node_wire_pkey in get_wires_in_node(conn, sink_node_pkey):
        c.execute(
            "SELECT phy_tile_pkey, wire_in_tile_pkey FROM wire WHERE pkey = ?;",
            (node_wire_pkey, )
        )
        phy_tile_pkey, wire_in_tile_pkey = c.fetchone()

        upstream_sink_wire_in_tile_pkey = check_for_default(wire_in_tile_pkey)

        if upstream_sink_wire_in_tile_pkey is not None:
            c.execute(
                "SELECT pkey FROM wire WHERE wire_in_tile_pkey = ? AND phy_tile_pkey = ?;",
                (
                    upstream_sink_wire_in_tile_pkey,
                    phy_tile_pkey,
                )
            )
            upstream_sink_wire_pkey = c.fetchone()[0]

            if upstream_sink_wire_pkey not in net_map:
                expand_sink(
                    conn=conn,
                    check_for_default=check_for_default,
                    nets=nets,
                    net_map=net_map,
                    source_to_sink_pip_map=source_to_sink_pip_map,
                    sink_wire_pkey=upstream_sink_wire_pkey,
                    allow_orphan_sinks=allow_orphan_sinks
                )

            if upstream_sink_wire_pkey in net_map:
                if DEBUG:
                    print(
                        '// {}/{} is connected to net via wire_pkey {}'.format(
                            tile_name, wire_name, upstream_sink_wire_pkey
                        )
                    )

                for net in net_map[upstream_sink_wire_pkey]:
                    nets[net].add_node(
                        conn=conn,
                        net_map=net_map,
                        node_pkey=sink_node_pkey,
                        parent_node_pkey=get_node_pkey(
                            conn, upstream_sink_wire_pkey
                        ),
                        incoming_wire_pkey=node_wire_pkey
                    )
                return

    # There does not appear to be an upstream connection, handle it.
    if allow_orphan_sinks:
        print(
            '// ERROR, failed to find source for node = {} ({}/{})'.format(
                sink_node_pkey, tile_name, wire_name
            )
        )
    else:
        assert False, (sink_node_pkey, tile_name, wire_name, sink_wire_pkey)


def make_routes(
        db, conn, wire_pkey_to_wire, unrouted_sinks, unrouted_sources,
        active_pips, allow_orphan_sinks, shorted_nets, nets, net_map
):
    """ Form nets (and their routes) based:

    unrouted_sinks - Set of wire_pkeys of sinks to BELs in the graph
    unrouted_sources - Set of wire_pkeys of sources from BELs in the graph
    active_pips - Known active pips, (sink wire_pkey, source wire_pkey).
    shorted_nets - Map of source_wire_pkey to sink_wire_pkey that represent
       shorted_nets

    Once nets are formed, yields wire names to their sources (which may be 0
    or 1 when connected to a constant net).

    """
    for wire_pkey in unrouted_sinks:
        assert wire_pkey in wire_pkey_to_wire

    for wire_pkey in unrouted_sources:
        assert wire_pkey in wire_pkey_to_wire

    source_to_sink_pip_map = {}

    for sink_wire_pkey, source_wire_pkey in active_pips:
        assert source_wire_pkey not in source_to_sink_pip_map
        source_to_sink_pip_map[source_wire_pkey] = sink_wire_pkey

    # Shorted nets can be treated like an active pip.
    for source_wire_pkey, sink_wire_pkey in shorted_nets.items():
        assert source_wire_pkey not in source_to_sink_pip_map
        source_to_sink_pip_map[source_wire_pkey] = sink_wire_pkey

    # Every sink should belong to exactly 1 net
    # Every net should have exactly 1 source
    check_downstream_default = create_check_downstream_default(conn, db)

    def report_sources():
        print('// Source wire pkeys:')
        c = conn.cursor()
        for wire_pkey in unrouted_sources:
            c.execute(
                "SELECT phy_tile_pkey, wire_in_tile_pkey FROM wire WHERE pkey = ?",
                (wire_pkey, )
            )
            phy_tile_pkey, wire_in_tile_pkey = c.fetchone()

            c.execute(
                "SELECT name FROM wire_in_tile WHERE pkey = ?",
                (wire_in_tile_pkey, )
            )
            (name, ) = c.fetchone()

            c.execute(
                "SELECT name FROM phy_tile WHERE pkey = ?", (phy_tile_pkey, )
            )
            tile = c.fetchone()[0]

            print('//', wire_pkey, tile, name)

    if DEBUG:
        report_sources()

    for wire_pkey in unrouted_sources:
        nets[wire_pkey] = Net(wire_pkey)
        nets[wire_pkey].add_node(
            conn,
            net_map,
            get_node_pkey(conn, wire_pkey),
            parent_node_pkey=None
        )
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
            allow_orphan_sinks=allow_orphan_sinks
        )

        if wire_pkey in net_map:
            for source_wire_pkey in net_map[wire_pkey]:
                if source_wire_pkey == ZERO_NET:
                    yield wire_pkey_to_wire[wire_pkey], 0
                elif source_wire_pkey == ONE_NET:
                    yield wire_pkey_to_wire[wire_pkey], 1
                else:
                    yield wire_pkey_to_wire[wire_pkey], wire_pkey_to_wire[
                        source_wire_pkey]
        else:
            if allow_orphan_sinks:
                print(
                    '// ERROR, source for sink wire {} not found'.format(
                        wire_pkey_to_wire[wire_pkey]
                    )
                )


def prune_antennas(conn, nets, unrouted_sinks):
    """ Prunes antenna routes from nets based on active sinks. """
    active_sink_nodes = set()
    for wire_pkey in unrouted_sinks:
        active_sink_nodes.add(get_node_pkey(conn, wire_pkey))

    for net in nets.values():
        net.prune_antennas(active_sink_nodes)
