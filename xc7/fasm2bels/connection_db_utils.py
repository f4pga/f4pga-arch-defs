import functools

def create_maybe_get_wire(conn):
    c = conn.cursor()

    @functools.lru_cache(maxsize=None)
    def get_tile_type_pkey(tile):
        c.execute('SELECT pkey, tile_type_pkey FROM tile WHERE name = ?',
                (tile,))
        return c.fetchone()

    @functools.lru_cache(maxsize=None)
    def maybe_get_wire(tile, wire):
        tile_pkey, tile_type_pkey = get_tile_type_pkey(tile)

        c.execute('SELECT pkey FROM wire_in_tile WHERE tile_type_pkey = ? and name = ?',
                (tile_type_pkey, wire))

        result = c.fetchone()

        if result is None:
            return None

        wire_in_tile_pkey = result[0]

        c.execute('SELECT pkey FROM wire WHERE tile_pkey = ? AND wire_in_tile_pkey = ?',
                (tile_pkey, wire_in_tile_pkey))

        return c.fetchone()[0]

    return maybe_get_wire


def maybe_add_pip(top, maybe_get_wire, feature):
    if feature.value != 1:
        return

    parts = feature.feature.split('.')
    assert len(parts) == 3

    sink_wire = maybe_get_wire(parts[0], parts[2])
    if sink_wire is None:
        return

    src_wire = maybe_get_wire(parts[0], parts[1])
    if src_wire is None:
        return

    top.active_pips.add((sink_wire, src_wire))


def get_node_pkey(conn, wire_pkey):
    c = conn.cursor()

    c.execute("SELECT node_pkey FROM wire WHERE pkey = ?", (wire_pkey,))

    return c.fetchone()[0]


def get_wires_in_node(conn, node_pkey):
    c = conn.cursor()

    c.execute("SELECT pkey FROM wire WHERE node_pkey = ?", (node_pkey,))

    for row in c.fetchall():
        yield row[0]


def get_wire(conn, tile_pkey, wire_in_tile_pkey):
    c = conn.cursor()
    c.execute("SELECT pkey FROM wire WHERE wire_in_tile_pkey = ? AND tile_pkey = ?;",
            (wire_in_tile_pkey, tile_pkey,))
    return c.fetchone()[0]


def get_tile_type(conn, tile_name):
    c = conn.cursor()

    c.execute("""
SELECT name FROM tile_type WHERE pkey = (
    SELECT tile_type_pkey FROM tile WHERE name = ?);""", (tile_name,))

    return c.fetchone()[0]
