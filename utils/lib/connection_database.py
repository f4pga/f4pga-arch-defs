import enum
from lib.rr_graph import graph2
from lib.rr_graph import tracks

class NodeClassification(enum.Enum):
    NULL = 1
    CHANNEL = 2
    EDGES_TO_CHANNEL = 3
    EDGE_WITH_MUX = 4


def create_tables(conn):
    """ Create connection database scheme. """
    connection_database_sql_file = os.path.join(
        os.path.dirname(__file__), "connection_database.sql")
    with open(connection_database_sql_file, 'r'):
        c = conn.cursor()
        c.execute(f.read())
        conn.commit()

    c = conn.cursor()
    c.execute("""
INSERT INTO
    switch(name)
VALUES
    ("__vpr_delayless_switch__"),
    ("routing"),
    ("short");
""")
    conn.commit()


def get_wire_pkey(conn, tile_name, wire):
    c = conn.cursor()
    c.execute("""
WITH selected_tile(tile_pkey, tile_type_pkey) AS (
  SELECT
    pkey,
    tile_type_pkey
  FROM
    tile
  WHERE
    name = ?
)
SELECT
  wire.pkey
FROM
  wire
WHERE
  wire.tile_pkey = (
    SELECT
      selected_tile.tile_pkey
    FROM
      selected_tile
  )
  AND wire.wire_in_tile_pkey = (
    SELECT
      wire_in_tile.pkey
    FROM
      wire_in_tile
    WHERE
      wire_in_tile.name = ?
      AND wire_in_tile.tile_type_pkey = (
        SELECT
          tile_type_pkey
        FROM
          selected_tile
      )
  );
""", (tile_name, wire))

    (wire_pkey,) = c.fetchone()
    return wire_pkey

def get_track_model(conn, track_pkey):
    assert track_pkey is not None

    track_list = []
    track_nodes = []
    c2 = conn.cursor()
    graph_node_pkey = {}
    for idx, (pkey, graph_node_type, x_low, x_high, y_low, y_high) in enumerate(c2.execute("""
    SELECT pkey, graph_node_type, x_low, x_high, y_low, y_high
        FROM graph_node WHERE track_pkey = ?""", (track_pkey,))):
        node_type = graph2.NodeType(graph_node_type)
        if node_type == graph2.NodeType.CHANX:
            direction = 'X'
        elif node_type == graph2.NodeType.CHANY:
            direction = 'Y'

        graph_node_pkey[pkey] = idx
        track_nodes.append(pkey)
        track_list.append(tracks.Track(
            direction=direction,
            x_low=x_low,
            x_high=x_high,
            y_low=y_low,
            y_high=y_high))

    track_connections = set()
    for src_graph_node_pkey, dest_graph_node_pkey in c2.execute("""
    SELECT src_graph_node_pkey, dest_graph_node_pkey
        FROM graph_edge WHERE track_pkey = ?""", (track_pkey,)):

        src_idx = graph_node_pkey[src_graph_node_pkey]
        dest_idx = graph_node_pkey[dest_graph_node_pkey]

        track_connections.add(tuple(sorted((src_idx, dest_idx))))

    tracks_model = tracks.Tracks(track_list, list(track_connections))

    return tracks_model, track_nodes

def yield_wire_info_from_node(conn, node_pkey):
    c2 = conn.cursor()
    for tile, tile_type, wire in c2.execute("""
WITH wires_in_node(tile_pkey, wire_in_tile_pkey) AS (
  SELECT
    tile_pkey,
    wire_in_tile_pkey
  FROM
    wire
  WHERE
    node_pkey = ?
),
tile_for_wire(
  wire_in_tile_pkey, tile_name, tile_type_pkey
) AS (
  SELECT
    wires_in_node.wire_in_tile_pkey,
    tile.name,
    tile.tile_type_pkey
  FROM
    tile
    INNER JOIN wires_in_node ON tile.pkey = wires_in_node.tile_pkey
),
tile_type_for_wire(
  wire_in_tile_pkey, tile_name, tile_type_name
) AS (
  SELECT
    tile_for_wire.wire_in_tile_pkey,
    tile_for_wire.tile_name,
    tile_type.name
  FROM
    tile_type
    INNER JOIN tile_for_wire ON tile_type.pkey = tile_for_wire.tile_type_pkey
)
SELECT
  tile_type_for_wire.tile_name,
  tile_type_for_wire.tile_type_name,
  wire_in_tile.name
FROM
  wire_in_tile
  INNER JOIN tile_type_for_wire ON tile_type_for_wire.wire_in_tile_pkey = wire_in_tile.pkey;
    """,
    (node_pkey,)):
            yield tile, tile_type, wire

def node_to_site_pins(conn, node_pkey):
    FIND_WIRE_WITH_SITE_PIN = """
WITH wires_in_node(
  pkey, tile_pkey, wire_in_tile_pkey
) AS (
  SELECT
    pkey,
    tile_pkey,
    wire_in_tile_pkey
  FROM
    wire
  WHERE
    node_pkey = ?
)
SELECT
  wires_in_node.pkey,
  wires_in_node.tile_pkey,
  wire_in_tile.pkey
FROM
  wires_in_node
  INNER JOIN wire_in_tile ON wires_in_node.wire_in_tile_pkey = wire_in_tile.pkey
WHERE
  wire_in_tile.site_pin_pkey IS NOT NULL;
"""

    c = conn.cursor()
    for wire_pkey, tile_pkey, wire_in_tile_pkey in c.execute(
            FIND_WIRE_WITH_SITE_PIN, (node_pkey,)):
        yield wire_pkey, tile_pkey, wire_in_tile_pkey
