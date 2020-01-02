import re
import functools

# A map of wires that require "SING" in their name for [LR]IOI3_SING tiles.
IOI_SING_WIRES = {
    "IOI_IOCLK0": "IOI_SING_IOCLK0",
    "IOI_IOCLK1": "IOI_SING_IOCLK1",
    "IOI_IOCLK2": "IOI_SING_IOCLK2",
    "IOI_IOCLK3": "IOI_SING_IOCLK3",
    "IOI_LEAF_GCLK0": "IOI_SING_LEAF_GCLK0",
    "IOI_LEAF_GCLK1": "IOI_SING_LEAF_GCLK1",
    "IOI_LEAF_GCLK2": "IOI_SING_LEAF_GCLK2",
    "IOI_LEAF_GCLK3": "IOI_SING_LEAF_GCLK3",
    "IOI_LEAF_GCLK4": "IOI_SING_LEAF_GCLK4",
    "IOI_LEAF_GCLK5": "IOI_SING_LEAF_GCLK5",
    "IOI_RCLK_FORIO0": "IOI_SING_RCLK_FORIO0",
    "IOI_RCLK_FORIO1": "IOI_SING_RCLK_FORIO1",
    "IOI_RCLK_FORIO2": "IOI_SING_RCLK_FORIO2",
    "IOI_RCLK_FORIO3": "IOI_SING_RCLK_FORIO3",
    "IOI_TBYTEIN": "IOI_SING_TBYTEIN",
}


def create_maybe_get_wire(conn):
    c = conn.cursor()

    @functools.lru_cache(maxsize=None)
    def get_tile_type_pkey(tile):
        c.execute(
            'SELECT pkey, tile_type_pkey FROM phy_tile WHERE name = ?',
            (tile, )
        )
        return c.fetchone()

    @functools.lru_cache(maxsize=None)
    def maybe_get_wire(tile, wire):

        # Some wires in [LR]IOI3_SING tiles have different names than in regular
        # IOI3 tiles. Rename them.
        if "IOI3_SING" in tile:

            # The connection database contains only wires with suffix "0" for
            # SING tiles. Change the wire name accordingly.
            wire = wire.replace("_1", "_0")
            wire = wire.replace("ILOGIC1", "ILOGIC0")
            wire = wire.replace("IDELAY1", "IDELAY0")
            wire = wire.replace("OLOGIC1", "OLOGIC0")

            # Add the "SING" part to wire name if applicable.
            if wire in IOI_SING_WIRES:
                wire = IOI_SING_WIRES[wire]

        phy_tile_pkey, tile_type_pkey = get_tile_type_pkey(tile)

        c.execute(
            'SELECT pkey FROM wire_in_tile WHERE phy_tile_type_pkey = ? and name = ?',
            (tile_type_pkey, wire)
        )

        result = c.fetchone()

        if result is None:
            return None

        wire_in_tile_pkey = result[0]

        c.execute(
            'SELECT pkey FROM wire WHERE phy_tile_pkey = ? AND wire_in_tile_pkey = ?',
            (phy_tile_pkey, wire_in_tile_pkey)
        )

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

    c.execute("SELECT node_pkey FROM wire WHERE pkey = ?", (wire_pkey, ))

    return c.fetchone()[0]


def get_wires_in_node(conn, node_pkey):
    c = conn.cursor()

    c.execute("SELECT pkey FROM wire WHERE node_pkey = ?", (node_pkey, ))

    for row in c.fetchall():
        yield row[0]


def get_wire(conn, phy_tile_pkey, wire_in_tile_pkey):
    c = conn.cursor()
    c.execute(
        "SELECT pkey FROM wire WHERE wire_in_tile_pkey = ? AND phy_tile_pkey = ?;",
        (
            wire_in_tile_pkey,
            phy_tile_pkey,
        )
    )
    return c.fetchone()[0]


def get_tile_type(conn, tile_name):
    c = conn.cursor()

    c.execute(
        """
SELECT name FROM tile_type WHERE pkey = (
    SELECT tile_type_pkey FROM phy_tile WHERE name = ?);""", (tile_name, )
    )

    return c.fetchone()[0]


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
      AND wire_in_tile.phy_tile_type_pkey = (
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
