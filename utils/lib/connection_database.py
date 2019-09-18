import enum
import os
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
        os.path.dirname(__file__), "connection_database.sql"
    )
    with open(connection_database_sql_file, 'r') as f:
        c = conn.cursor()
        c.executescript(f.read())
        conn.commit()

    c = conn.cursor()
    c.execute(
        """
INSERT INTO
    switch(name, internal_capacitance, drive_resistance, intrinsic_delay, switch_type)
VALUES
    ("__vpr_delayless_switch__", 0.0, 0.0, 0.0, "mux"),
    ("short", 0.0, 0.0, 0.0, "short")
"""
    )
    conn.commit()


def get_wire_pkey(conn, tile_name, wire):
    c = conn.cursor()
    c.execute(
        """
WITH selected_tile(phy_tile_pkey, tile_type_pkey) AS (
  SELECT
    pkey,
    tile_type_pkey
  FROM
    phy_tile
  WHERE
    name = ?
)
SELECT
  wire.pkey
FROM
  wire
WHERE
  wire.phy_tile_pkey = (
    SELECT
      selected_tile.phy_tile_pkey
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
""", (tile_name, wire)
    )

    results = c.fetchone()
    assert results is not None, (tile_name, wire)
    return results[0]


def get_track_model(conn, track_pkey):
    assert track_pkey is not None

    track_list = []
    track_nodes = []
    c2 = conn.cursor()
    graph_node_pkey = {}
    for idx, (pkey, graph_node_type, x_low, x_high, y_low,
              y_high) in enumerate(c2.execute("""
    SELECT pkey, graph_node_type, x_low, x_high, y_low, y_high
      FROM graph_node WHERE track_pkey = ?""", (track_pkey, ))):
        node_type = graph2.NodeType(graph_node_type)
        if node_type == graph2.NodeType.CHANX:
            direction = 'X'
        elif node_type == graph2.NodeType.CHANY:
            direction = 'Y'

        graph_node_pkey[pkey] = idx
        track_nodes.append(pkey)
        track_list.append(
            tracks.Track(
                direction=direction,
                x_low=x_low,
                x_high=x_high,
                y_low=y_low,
                y_high=y_high
            )
        )

    track_connections = set()
    for src_graph_node_pkey, dest_graph_node_pkey in c2.execute("""
    SELECT src_graph_node_pkey, dest_graph_node_pkey
        FROM graph_edge WHERE track_pkey = ?""", (track_pkey, )):

        src_idx = graph_node_pkey[src_graph_node_pkey]
        dest_idx = graph_node_pkey[dest_graph_node_pkey]

        track_connections.add(tuple(sorted((src_idx, dest_idx))))

    tracks_model = tracks.Tracks(track_list, list(track_connections))

    return tracks_model, track_nodes


def yield_wire_info_from_node(conn, node_pkey):
    """ Yield tile types and wires attached to specified node.

    Parameters
    ----------
    conn : sqlite3.Connection
        Connection database object.
    node_pkey : int
        Primary key into node table

    Yields
    -------
    tile_type : str
        Name of tile type for wire being yielded.
    wire : str
        Name of wire for wire being yielded.

    Note: This function yields the prjxray tile_type and wire name.  This
    function does NOT tile_type's and wire names coorsponding to the VPR tiles.

    """
    c2 = conn.cursor()
    for tile_type, wire in c2.execute("""
WITH wires_in_node(phy_tile_pkey, wire_in_tile_pkey) AS (
  SELECT
    phy_tile_pkey,
    wire_in_tile_pkey
  FROM
    wire
  WHERE
    node_pkey = ?
),
tile_for_wire(
  wire_in_tile_pkey, tile_type_pkey
) AS (
  SELECT
    wires_in_node.wire_in_tile_pkey,
    phy_tile.tile_type_pkey
  FROM
    phy_tile
    INNER JOIN wires_in_node ON phy_tile.pkey = wires_in_node.phy_tile_pkey
),
tile_type_for_wire(
  wire_in_tile_pkey, tile_type_name
) AS (
  SELECT
    tile_for_wire.wire_in_tile_pkey,
    tile_type.name
  FROM
    tile_type
    INNER JOIN tile_for_wire ON tile_type.pkey = tile_for_wire.tile_type_pkey
)
SELECT
  tile_type_for_wire.tile_type_name,
  wire_in_tile.name
FROM
  wire_in_tile
  INNER JOIN tile_type_for_wire ON tile_type_for_wire.wire_in_tile_pkey = wire_in_tile.pkey;
    """, (node_pkey, )):
        yield tile_type, wire


def yield_logical_wire_info_from_node(conn, node_pkey):
    """ Yield tile types and wires attached to specified node.

    Parameters
    ----------
    conn : sqlite3.Connection
        Connection database object.
    node_pkey : int
        Primary key into node table

    Yields
    -------
    tile_type : str
        Name of tile type for wire being yielded.
    wire : str
        Name of wire for wire being yielded.

    Note: This function yields the prjxray tile_type and wire name.  This
    function does NOT tile_type's and wire names coorsponding to the VPR tiles.

    """
    c2 = conn.cursor()
    for tile_type, wire in c2.execute("""
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
  wire_in_tile_pkey, tile_type_pkey
) AS (
  SELECT
    wires_in_node.wire_in_tile_pkey,
    tile.tile_type_pkey
  FROM
    tile
    INNER JOIN wires_in_node ON tile.pkey = wires_in_node.tile_pkey
),
tile_type_for_wire(
  wire_in_tile_pkey, tile_type_name
) AS (
  SELECT
    tile_for_wire.wire_in_tile_pkey,
    tile_type.name
  FROM
    tile_type
    INNER JOIN tile_for_wire ON tile_type.pkey = tile_for_wire.tile_type_pkey
)
SELECT
  tile_type_for_wire.tile_type_name,
  wire_in_tile.name
FROM
  wire_in_tile
  INNER JOIN tile_type_for_wire ON tile_type_for_wire.wire_in_tile_pkey = wire_in_tile.pkey;
    """, (node_pkey, )):
        yield tile_type, wire


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
            FIND_WIRE_WITH_SITE_PIN, (node_pkey, )):
        yield wire_pkey, tile_pkey, wire_in_tile_pkey


def get_pin_name_of_wire(conn, wire_pkey):
    """ Returns pin name of wire.

    For unsplit tiles, this is the name of the wire.
    For split tiles with only 1 site, this is the name of the site pin
    connected to this wire.
    For wires that are not a pin, returns None.

    Parameters
    ----------
    conn : sqlite3.Connection
        Connection database object.
    wire_pkey : int
        Primary key into wire table

    Returns
    -------
    pin : str
        VPR pin name for given wire_pkey.
        Returns none if this wire is not a pin.

    """
    c = conn.cursor()
    c.execute(
        """
SELECT wire_in_tile_pkey, tile_pkey FROM wire WHERE pkey = ?
        """, (wire_pkey, )
    )
    wire_in_tile_pkey, tile_pkey = c.fetchone()

    c.execute(
        """
SELECT site_as_tile_pkey FROM tile WHERE pkey = ?
        """, (tile_pkey, )
    )
    site_as_tile_pkey = c.fetchone()[0]

    c.execute(
        """
SELECT name, site_pin_pkey FROM wire_in_tile WHERE pkey = ?;
    """, (wire_in_tile_pkey, )
    )
    wire_name, site_pin_pkey = c.fetchone()

    if site_pin_pkey is None:
        return None

    if site_as_tile_pkey is not None:
        c.execute(
            "SELECT name FROM site_pin WHERE pkey = ?", (site_pin_pkey, )
        )
        return c.fetchone()[0]
    else:
        return wire_name


def get_wire_in_tile_from_pin_name(conn, tile_type_str, wire_str):
    """ Returns wire_in_tile rows match specified tile type and pin name.

    Because a split tile type can appear in multiple tiles (e.g. SLICEL in
    CLBLL_L, CLBLL_R, etc), multiple wire_in_tile rows may be returned. The
    site table primary key disambiguates which row to use.

    Parameters
    ----------
    conn : sqlite3.Connection
        Connection database object.
    tile_type_str : str
        Name of tile_type this pin belongs to.
    wire_str : str
        Name of pin to get wire_in_tile rows for.

    Returns
    -------
    wire_in_tile_pkeys : dict of int to int
        Map of site table primary keys to wire_in_tile primary keys.  Unsplit
        tiles will always have only one dictionary entry.  Split tiles may have
        more than one.
    site_pin_pkey : int
        Row into site_pin table for this pin.

    """
    # Find the generic wire_in_tile_pkey for the specified tile_type name and
    # wire name.
    c = conn.cursor()

    # Find if this tile_type is a split tile.
    c.execute(
        """
SELECT
  site_pkey
FROM
  site_as_tile
WHERE
  parent_tile_type_pkey = (
    SELECT
      pkey
    FROM
      tile_type
    WHERE
      name = ?
  );
        """, (tile_type_str, )
    )
    result = c.fetchone()
    wire_is_pin = result is not None

    if wire_is_pin:
        # This tile is a split tile, lookup for the wire_in_tile_pkey is based
        # on the site pin name, rather than the wire name.
        site_pkey = result[0]
        c.execute(
            """
SELECT
  pkey,
  site_pin_pkey,
  site_pkey
FROM
  wire_in_tile
WHERE
  site_pin_pkey = (
    SELECT
      pkey
    FROM
      site_pin
    WHERE
      site_type_pkey = (
        SELECT
          site_type_pkey
        FROM
          site
        WHERE
          pkey = ?
      )
      AND name = ?
  );""", (site_pkey, wire_str)
        )
    else:
        c.execute(
            """
SELECT
  pkey,
  site_pin_pkey,
  site_pkey
FROM
  wire_in_tile
WHERE
  name = ?
  and tile_type_pkey = (
    SELECT
      pkey
    FROM
      tile_type
    WHERE
      name = ?
  );
""", (wire_str, tile_type_str)
        )

    wire_in_tile_pkeys = {}
    the_site_pin_pkey = None
    for wire_in_tile_pkey, site_pin_pkey, site_pkey in c:
        wire_in_tile_pkeys[site_pkey] = wire_in_tile_pkey

        if the_site_pin_pkey is not None:
            assert the_site_pin_pkey == site_pin_pkey, (
                tile_type_str, wire_str
            )
        else:
            the_site_pin_pkey = site_pin_pkey

    #assert the_site_pin_pkey is not None, (tile_type_str, wire_str)

    return wire_in_tile_pkeys, the_site_pin_pkey
