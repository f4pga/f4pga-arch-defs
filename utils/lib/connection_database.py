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

    # This is the database schema for relating a tile grid to a VPR routing
    # graph.
    #
    # Terms:
    #  grid - A 2D matrix of tiles
    #
    #  tile - A location within the grid.  A tile is always of a partial
    #         tile type.  The tile type specifies what wires, pips and
    #         sites a tile contains.
    #
    #  wires - A partial net within a tile.  It may start or end at a site pins
    #          or a pip, or can connect to wires in other tiles.
    #
    #  pip - Programable interconnect point, connecting two wires within a
    #        tile.
    #
    #  node - A complete net made of one or more wires.
    #
    #  site - A location within a tile that contains site pins and BELs.
    #         BELs are not described in this database.
    #
    #  site - Site pins are the connections to/from the site to a wire in a
    #         tile.  A site pin may be associated with one wire in the tile.
    #
    #  graph_node - A VPR type representing either a pb_type IPIN or OPIN or
    #               a routing wire CHANX or CHANY.
    #
    #               IPIN/OPIN are similiar to site pin.
    #               CHANX/CHANY are how VPR express routing nodes.
    #
    #  track - A collection of graph_node's that represents one routing node.
    #
    #  graph_edge - A VPR type representing a connection between an IPIN, OPIN,
    #               CHANX, or CHANY.  All graph_edge's require a switch.
    #
    #  switch - See VPR documentation :http://docs.verilogtorouting.org/en/latest/arch/reference/#tag-fpga-device-information-switch_block
    #
    #  This database provides a relational description between the terms above.

    # Tile type table, used to track tile_type using a pkey, and provide
    # the tile_type_pkey <-> name mapping.
    c.execute("""CREATE TABLE tile_type(
      pkey INTEGER PRIMARY KEY,
      name TEXT
    );""")

    # Site type table, used to track site_type using a pkey, and provide
    # the site_type_pkey <-> name mapping.
    c.execute("""CREATE TABLE site_type(
      pkey INTEGER PRIMARY KEY,
      name TEXT
    );""")

    # Tile table, contains type and name of tile and location in grid.
    c.execute("""CREATE TABLE tile(
      pkey INTEGER PRIMARY KEY,
      name TEXT,
      tile_type_pkey INT,
      grid_x INT,
      grid_y INT,
      FOREIGN KEY(tile_type_pkey) REFERENCES tile_type(pkey)
    );""")

    # Site pin table, contains names of pins and their direction, along
    # with parent site type information.
    c.execute("""CREATE TABLE site_pin(
      pkey INTEGER PRIMARY KEY,
      name TEXT,
      site_type_pkey INT,
      direction TEXT,
      FOREIGN KEY(site_type_pkey) REFERENCES site_type(pkey)
    );""")

    # Concreate site instance within tiles.  Used to relate connect
    # wire_in_tile instead to site_type's, along with providing metadata
    # about the site.
    c.execute("""CREATE TABLE site(
      pkey INTEGER PRIMARY KEY,
      name TEXT,
      x_coord INT,
      y_coord INT,
      site_type_pkey INT,
      FOREIGN KEY(site_type_pkey) REFERENCES site_type(pkey)
    );""")

    # Table of tile type wires. This table is the of uninstanced tile type
    # wires. Site pins wires will reference their site and site pin rows in
    # the site and site_pin tables.
    #
    # All concrete wire instances will related to a row in this table.
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

    # Table of tile type pips.  This table is the table of uninstanced pips.
    # No concreate table of pips is created, instead this table is used to
    # add rows in the graph_edge table.
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

    # Table of tracks. alive is a flag used during routing import to indicate
    # whether this a particular track is connected and should be imported.
    c.execute("""CREATE TABLE track(
      pkey INTEGER PRIMARY KEY,
      alive BOOL
    );""")

    # Table of nodes.  Provides the concrete relation for connected wire
    # instances. Generally speaking nodes are either routing nodes or a site
    # pin node.
    #
    # Routing nodes will have track_pkey set.
    # Site pin nodes will have a site_wire_pkey to the wire that is the wire
    # connected to a site pin.
    c.execute("""CREATE TABLE node(
      pkey INTEGER PRIMARY KEY,
      number_pips INT,
      track_pkey INT,
      site_wire_pkey INT,
      classification INT,
      FOREIGN KEY(track_pkey) REFERENCES track_pkey(pkey),
      FOREIGN KEY(site_wire_pkey) REFERENCES wire(pkey)
    );""")

    # Table of edge with mux.  An edge_with_mux needs special handling in VPR,
    # in the form of architecture level direct connections.
    #
    # This table is the list of these direct connections.
    c.execute("""CREATE TABLE edge_with_mux(
      pkey INTEGER PRIMARY KEY,
      src_wire_pkey INT,
      dest_wire_pkey INT,
      pip_in_tile_pkey INT,
      FOREIGN KEY(src_wire_pkey) REFERENCES wire(pkey),
      FOREIGN KEY(dest_wire_pkey) REFERENCES wire(pkey),
      FOREIGN KEY(pip_in_tile_pkey) REFERENCES pip_in_tile(pkey)
    );""")

    # Table of graph nodes.  This is a direction mapping of an VPR rr_node
    # instance.
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

    # Table of wires.  This table is the complete list of all wires in the
    # grid. All wires will belong to exactly one node.
    #
    # Rows will relate back to their parent tile, and generic wire instance.
    #
    # If the wire is connected to both a site pin and a pip, then
    # top_graph_node_pkey, bottom_graph_node_pkey, left_graph_node_pkey, and
    # right_graph_node_pkey will be set to the IPIN or OPIN instances, based
    # on the pin directions for the tile.
    #
    # If the wire is a member of a routing node, then graph_node_pkey will be
    # set to the graph_node this wire is a member of.
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

    # Table of switches.
    c.execute("""CREATE TABLE switch(
      pkey INTEGER PRIMARY KEY,
      name TEXT
    );""")

    # Table of graph edges.
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

    # channel, x_list and y_list are direct mappings of the channel object
    # present in the rr_graph.
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
