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
    c = conn.cursor()

    c.execute("""CREATE TABLE tile_type(
      pkey INTEGER PRIMARY KEY,
      name TEXT
    );""")
    c.execute("""CREATE TABLE site_type(
      pkey INTEGER PRIMARY KEY,
      name TEXT
    );""")
    c.execute("""CREATE TABLE tile(
      pkey INTEGER PRIMARY KEY,
      name TEXT,
      tile_type_pkey INT,
      grid_x INT,
      grid_y INT,
      FOREIGN KEY(tile_type_pkey) REFERENCES tile_type(pkey)
    );""")
    c.execute("""CREATE TABLE site_pin(
      pkey INTEGER PRIMARY KEY,
      name TEXT,
      site_type_pkey INT,
      direction TEXT,
      FOREIGN KEY(site_type_pkey) REFERENCES site_type(pkey)
    );""")
    c.execute("""CREATE TABLE site(
      pkey INTEGER PRIMARY KEY,
      name TEXT,
      x_coord INT,
      y_coord INT,
      site_type_pkey INT,
      FOREIGN KEY(site_type_pkey) REFERENCES site_type(pkey)
    );""")
    c.execute("""CREATE TABLE wire_in_tile(
      pkey INTEGER PRIMARY KEY,
      name TEXT,
      tile_type_pkey INT,
      site_pkey INT,
      site_pin_pkey INT,
      FOREIGN KEY(tile_type_pkey) REFERENCES tile_type(pkey),
      FOREIGN KEY(site_pkey) REFERENCES site(pkey),
      FOREIGN KEY(site_pin_pkey) REFERENCES site_pin(pkey)
    );""")
    c.execute("""CREATE TABLE pip_in_tile(
      pkey INTEGER PRIMARY KEY,
      name TEXT,
      tile_type_pkey INT,
      src_wire_in_tile_pkey INT,
      dest_wire_in_tile_pkey INT,
      FOREIGN KEY(tile_type_pkey) REFERENCES tile_type(pkey),
      FOREIGN KEY(src_wire_in_tile_pkey) REFERENCES wire_in_tile(pkey),
      FOREIGN KEY(dest_wire_in_tile_pkey) REFERENCES wire_in_tile(pkey)
    );""")
    c.execute("""CREATE TABLE track(
      pkey INTEGER PRIMARY KEY,
      alive BOOL
    );""")
    c.execute("""CREATE TABLE node(
      pkey INTEGER PRIMARY KEY,
      number_pips INT,
      track_pkey INT,
      site_wire_pkey INT,
      classification INT,
      FOREIGN KEY(track_pkey) REFERENCES track_pkey(pkey),
      FOREIGN KEY(site_wire_pkey) REFERENCES wire(pkey)
    );""")
    c.execute("""CREATE TABLE edge_with_mux(
      pkey INTEGER PRIMARY KEY,
      src_wire_pkey INT,
      dest_wire_pkey INT,
      pip_in_tile_pkey INT,
      FOREIGN KEY(src_wire_pkey) REFERENCES wire(pkey),
      FOREIGN KEY(dest_wire_pkey) REFERENCES wire(pkey),
      FOREIGN KEY(pip_in_tile_pkey) REFERENCES pip_in_tile(pkey)
    );""")
    c.execute("""CREATE TABLE graph_node(
      pkey INTEGER PRIMARY KEY,
      graph_node_type INT,
      track_pkey INT,
      node_pkey INT,
      x_low INT,
      x_high INT,
      y_low INT,
      y_high INT,
      ptc INT,
      capacity INT,
      FOREIGN KEY(track_pkey) REFERENCES track(pkey),
      FOREIGN KEY(node_pkey) REFERENCES node(pkey)
    );""")
    c.execute("""CREATE TABLE wire(
      pkey INTEGER PRIMARY KEY,
      node_pkey INT,
      tile_pkey INT,
      wire_in_tile_pkey INT,
      graph_node_pkey INT,
      top_graph_node_pkey INT,
      bottom_graph_node_pkey INT,
      left_graph_node_pkey INT,
      right_graph_node_pkey INT,
      FOREIGN KEY(node_pkey) REFERENCES node(pkey),
      FOREIGN KEY(tile_pkey) REFERENCES tile(pkey),
      FOREIGN KEY(wire_in_tile_pkey) REFERENCES wire_in_grid(pkey)
      FOREIGN KEY(graph_node_pkey) REFERENCES graph_node(pkey)
      FOREIGN KEY(top_graph_node_pkey) REFERENCES graph_node(pkey)
      FOREIGN KEY(bottom_graph_node_pkey) REFERENCES graph_node(pkey)
      FOREIGN KEY(left_graph_node_pkey) REFERENCES graph_node(pkey)
      FOREIGN KEY(right_graph_node_pkey) REFERENCES graph_node(pkey)
    );""")
    c.execute("""CREATE TABLE switch(
      pkey INTEGER PRIMARY KEY,
      name TEXT
    );""")
    c.execute("""CREATE TABLE graph_edge(
      src_graph_node_pkey INT,
      dest_graph_node_pkey INT,
      switch_pkey INT,
      track_pkey INT,
      tile_pkey INT,
      pip_in_tile_pkey INT,
      FOREIGN KEY(src_graph_node_pkey) REFERENCES graph_node(pkey),
      FOREIGN KEY(dest_graph_node_pkey) REFERENCES graph_node(pkey)
      FOREIGN KEY(track_pkey) REFERENCES track(pkey)
      FOREIGN KEY(tile_pkey) REFERENCES tile(pkey)
      FOREIGN KEY(pip_in_tile_pkey) REFERENCES pip(pkey)
    );""")
    c.execute("""CREATE TABLE channel(
      chan_width_max INT,
      x_min INT,
      y_min INT,
      x_max INT,
      y_max INT
    );""")
    c.execute("""CREATE TABLE x_list(
        idx INT,
        info INT
    );""")
    c.execute("""CREATE TABLE y_list(
        idx INT,
        info INT
    );""")

    conn.commit()

    c.execute("""INSERT INTO switch(name) VALUES
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
