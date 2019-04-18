#!/usr/bin/env python3
""" Classify 7-series nodes and generate channels for required nodes.

Rough structure:

Create initial database import by importing tile types, tile wires, tile pips,
site types and site pins.  After importing tile types, imports the grid of
tiles.  This uses tilegrid.json, tile_type_*.json and site_type_*.json.

Once all tiles are imported, all wires in the grid are added and nodes are
formed from the sea of wires based on the tile connections description
(tileconn.json).

In order to determine what each node is used for, site pins and pips are counted
on each node (count_sites_and_pips_on_nodes).  Depending on the site pin and
pip count, the nodes are classified into one of 4 buckets:

    NULL - An unconnected node
    CHANNEL - A routing node
    EDGE_WITH_MUX - An edge between an IPIN and OPIN.
    EDGES_TO_CHANNEL - An edge between an IPIN/OPIN and a CHANNEL.

Then all CHANNEL are grouped into tracks (form_tracks) and graph nodes are
created for the CHANNELs.  Graph edges are added to connect graph nodes that are
part of the same track.

Note that IPIN and OPIN graph nodes are not added yet, as pins have not been
assigned sides of the VPR tiles yet.  This occurs in
prjxray_assign_tile_pin_direction.


"""

import argparse
import itertools
import prjxray.db
import progressbar
from lib.rr_graph import points
from lib.rr_graph import tracks
from lib.rr_graph import graph2
import datetime
import os
import os.path
from lib.connection_database import NodeClassification, create_tables
import lib.grid_mapping as grid_mapping

from prjxray_db_cache import DatabaseCache

from splitter.grid_splitter import GridSplitter
from splitter.tile_splitter import TileSplitter


def import_site_type(db, c, site_types, site_type_name):
    assert site_type_name not in site_types
    site_type = db.get_site_type(site_type_name)

    if site_type_name in site_types:
        return

    c.execute("INSERT INTO site_type(name) VALUES (?)", (site_type_name, ))
    site_types[site_type_name] = c.lastrowid

    for site_pin in site_type.get_site_pins():
        pin_info = site_type.get_site_pin(site_pin)

        c.execute(
            """
INSERT INTO site_pin(name, site_type_pkey, direction)
VALUES
  (?, ?, ?)""", (
                pin_info.name, site_types[site_type_name],
                pin_info.direction.value
            )
        )


def import_tile_type(db, c, tile_types, site_types, tile_type_name):
    assert tile_type_name not in tile_types
    tile_type = db.get_tile_type(tile_type_name)

    c.execute("INSERT INTO tile_type(name) VALUES (?)", (tile_type_name, ))
    tile_types[tile_type_name] = c.lastrowid

    wires = {}
    for wire in tile_type.get_wires():
        c.execute(
            """
INSERT INTO wire_in_tile(name, tile_type_pkey)
VALUES
  (?, ?)""", (wire, tile_types[tile_type_name])
        )
        wires[wire] = c.lastrowid

    for pip in tile_type.get_pips():

        c.execute(
            """
INSERT INTO pip_in_tile(
  name, tile_type_pkey, src_wire_in_tile_pkey,
  dest_wire_in_tile_pkey, can_invert, is_directional, is_pseudo
)
VALUES
  (?, ?, ?, ?, ?, ?, ?)""", (
                pip.name, tile_types[tile_type_name], wires[pip.net_from],
                wires[pip.net_to
                      ], pip.can_invert, pip.is_directional, pip.is_pseudo
            )
        )

    for site in tile_type.get_sites():
        if site.type not in site_types:
            import_site_type(db, c, site_types, site.type)


def add_wire_to_site_relation(db, c, tile_types, site_types, tile_type_name):
    tile_type = db.get_tile_type(tile_type_name)
    for site in tile_type.get_sites():
        c.execute(
            """
INSERT INTO site(name, x_coord, y_coord, site_type_pkey)
VALUES
  (?, ?, ?, ?)""", (site.name, site.x, site.y, site_types[site.type])
        )

        site_pkey = c.lastrowid

        for site_pin in site.site_pins:
            c.execute(
                """
SELECT
  pkey
FROM
  site_pin
WHERE
  name = ?
  AND site_type_pkey = ?""", (site_pin.name, site_types[site.type])
            )

            result = c.fetchone()
            site_pin_pkey = result[0]
            c.execute(
                """
UPDATE
  wire_in_tile
SET
  site_pkey = ?,
  site_pin_pkey = ?
WHERE
  name = ?
  and tile_type_pkey = ?;""", (
                    site_pkey, site_pin_pkey, site_pin.wire,
                    tile_types[tile_type_name]
                )
            )


def build_tile_type_indicies(c):
    c.execute("CREATE INDEX site_pin_index ON site_pin(name, site_type_pkey);")
    c.execute(
        "CREATE INDEX wire_name_index ON wire_in_tile(name, tile_type_pkey);"
    )
    c.execute(
        "CREATE INDEX wire_site_pin_index ON wire_in_tile(site_pin_pkey);"
    )
    c.execute(
        "CREATE INDEX pip_tile_type_index ON pip_in_tile(tile_type_pkey);"
    )
    c.execute(
        "CREATE INDEX src_pip_index ON pip_in_tile(src_wire_in_tile_pkey);"
    )
    c.execute(
        "CREATE INDEX dest_pip_index ON pip_in_tile(dest_wire_in_tile_pkey);"
    )


def build_phy_tile_grid_indicies(c):
    c.execute("CREATE INDEX phy_tile_name_index ON phy_tile(name);")
    c.execute("CREATE INDEX phy_tile_loc_index ON phy_tile(grid_x, grid_y);")


def import_grid(db, grid, conn):
    c = conn.cursor()

    tile_types = {}
    site_types = {}
    for tile in grid.tiles():
        gridinfo = grid.gridinfo_at_tilename(tile)

        if gridinfo.tile_type not in tile_types:
            if gridinfo.tile_type in tile_types:
                continue

            import_tile_type(db, c, tile_types, site_types, gridinfo.tile_type)

    c.connection.commit()

    build_tile_type_indicies(c)
    c.connection.commit()

    for tile_type in tile_types:
        add_wire_to_site_relation(db, c, tile_types, site_types, tile_type)

    for tile in grid.tiles():
        gridinfo = grid.gridinfo_at_tilename(tile)
        loc = grid.loc_of_tilename(tile)
        # tile: pkey name tile_type_pkey grid_x grid_y
        c.execute(
            """
INSERT INTO phy_tile(name, tile_type_pkey, grid_x, grid_y)
VALUES
  (?, ?, ?, ?)""",
            (tile, tile_types[gridinfo.tile_type], loc.grid_x, loc.grid_y)
        )

    c.connection.commit()

    build_phy_tile_grid_indicies(c)


def import_nodes(db, conn, tile_types_to_split, tile_wire_name_map):
    # Some nodes are just 1 wire, so start by enumerating all wires.

    c = conn.cursor()
    c1 = conn.cursor()
    c2 = conn.cursor()
    c2.execute("""BEGIN EXCLUSIVE TRANSACTION;""")

    tile_wire_map = {}
    wires = {}

    for tile_name, tile_pkey, tile_type_pkey, phy_loc_x, phy_loc_y in progressbar.progressbar(
            c1.execute("SELECT name, pkey, tile_type_pkey, grid_x, grid_y FROM phy_tile")):

        # Map the pkey of the physical tile to pkey of the VPR tile(s).
        vpr_tile_data = c.execute("""SELECT pkey, grid_x, grid_y FROM tile WHERE pkey IN (SELECT vpr_tile_pkey FROM grid_loc_map WHERE phy_tile_pkey = (?))""", (tile_pkey, )).fetchall()

        # NOTE:
        # In this function I need to know which wires from wire_in_tile belong
        # to which site. As one phy CLB correspond to two VPR SLICEs some wires
        # must have tile_pkey for SLICE_X0 and others for SLICE_X1. It is
        # important later when tracks are formed. Location of the tile in VPR
        # grid is required for track formation.

        tile_type = c.execute(
            "SELECT name FROM tile_type WHERE pkey = ?", (tile_type_pkey,)
        ).fetchone()[0]

        for wire in db.get_tile_type(tile_type).get_wires():
            # pkey node_pkey tile_pkey wire_in_tile_pkey
            c.execute(
                """
SELECT pkey FROM wire_in_tile WHERE name = ? and tile_type_pkey = ?;""",
                (wire, tile_type_pkey)
            )
            (wire_in_tile_pkey, ) = c.fetchone()

            # Loop over all VPR tiles that correspond to the physical tile.
            for vpr_tile_pkey, vpr_loc_x, vpr_loc_y in vpr_tile_data:

                # If the tile is being split check if a wite belongs
                # to this tile
                if tile_type in tile_types_to_split:
                    site_ofs  = (vpr_loc_x - phy_loc_x, vpr_loc_y - phy_loc_y)
                    site_name = "X%dY%d" % (site_ofs[0], site_ofs[1])

                    # This wire is not relevant for the "part" of split tile
                    if wire not in tile_wire_name_map[site_name]:
                        print("Reject %s for %s %s" % (wire, tile_type, site_name))
                        continue

                c2.execute(
                    """INSERT INTO wire(tile_pkey, wire_in_tile_pkey) VALUES (?, ?);""", (vpr_tile_pkey, wire_in_tile_pkey)
                )

                wire_pkey = c2.lastrowid
                wires[wire_pkey] = None

                #assert (tile_name, wire) not in tile_wire_map
                key = (tile_name, wire)
                if key not in tile_wire_map:
                    tile_wire_map[key] = [wire_pkey]
                else:
                    tile_wire_map[key].append(wire_pkey)

    c2.execute("""COMMIT TRANSACTION;""")

    connections = db.connections()

    for connection in progressbar.progressbar(connections.get_connections()):
        a_pkeys = tile_wire_map[
            (connection.wire_a.tile, connection.wire_a.wire)]
        b_pkeys = tile_wire_map[
            (connection.wire_b.tile, connection.wire_b.wire)]

        for a_pkey, b_pkey in itertools.product(a_pkeys, b_pkeys):

            a_node = wires[a_pkey]
            b_node = wires[b_pkey]

            if a_node is None:
                a_node = set((a_pkey, ))

            if b_node is None:
                b_node = set((b_pkey, ))

            if a_node is not b_node:
                a_node |= b_node

                for wire in a_node:
                    wires[wire] = a_node

    nodes = {}
    for wire_pkey, node in wires.items():
        if node is None:
            node = set((wire_pkey, ))

        assert wire_pkey in node

        nodes[id(node)] = node

    wires_assigned = set()
    for node in progressbar.progressbar(nodes.values()):
        c.execute("""INSERT INTO node(number_pips) VALUES (0);""")
        node_pkey = c.lastrowid

        for wire_pkey in node:
            wires_assigned.add(wire_pkey)
            c.execute(
                """
            UPDATE wire
                SET node_pkey = ?
                WHERE pkey = ?
            ;""", (node_pkey, wire_pkey)
            )

    assert len(set(wires.keys()) ^ wires_assigned) == 0

    del tile_wire_map
    del nodes
    del wires

    c.execute("CREATE INDEX wire_in_tile_index ON wire(wire_in_tile_pkey);")
    c.execute("CREATE INDEX wire_index ON wire(tile_pkey, wire_in_tile_pkey);")
    c.execute("CREATE INDEX wire_node_index ON wire(node_pkey);")

    c.connection.commit()


def count_sites_and_pips_on_nodes(conn):
    c = conn.cursor()

    print("{}: Counting sites on nodes".format(datetime.datetime.now()))
    c.execute(
        """
WITH node_sites(node_pkey, number_site_pins) AS (
  SELECT
    wire.node_pkey,
    count(wire_in_tile.site_pin_pkey)
  FROM
    wire_in_tile
    INNER JOIN wire ON wire.wire_in_tile_pkey = wire_in_tile.pkey
  WHERE
    wire_in_tile.site_pin_pkey IS NOT NULL
  GROUP BY
    wire.node_pkey
)
SELECT
  max(node_sites.number_site_pins)
FROM
  node_sites;
"""
    )

    # Nodes are only expected to have 1 site
    assert c.fetchone()[0] == 1

    print("{}: Assigning site wires for nodes".format(datetime.datetime.now()))
    c.execute(
        """
WITH site_wires(wire_pkey, node_pkey) AS (
  SELECT
    wire.pkey,
    wire.node_pkey
  FROM
    wire_in_tile
    INNER JOIN wire ON wire.wire_in_tile_pkey = wire_in_tile.pkey
  WHERE
    wire_in_tile.site_pin_pkey IS NOT NULL
)
UPDATE
  node
SET
  site_wire_pkey = (
    SELECT
      site_wires.wire_pkey
    FROM
      site_wires
    WHERE
      site_wires.node_pkey = node.pkey
  );
      """
    )

    print("{}: Counting pips on nodes".format(datetime.datetime.now()))
    c.execute(
        """
    CREATE TABLE node_pip_count(
      node_pkey INT,
      number_pips INT,
      FOREIGN KEY(node_pkey) REFERENCES node(pkey)
    );"""
    )
    c.execute(
        """
INSERT INTO node_pip_count(node_pkey, number_pips)
SELECT
  wire.node_pkey,
  count(pip_in_tile.pkey)
FROM
  pip_in_tile
  INNER JOIN wire
WHERE
  pip_in_tile.is_directional = 1 AND pip_in_tile.is_pseudo = 0 AND (
  pip_in_tile.src_wire_in_tile_pkey = wire.wire_in_tile_pkey
  OR pip_in_tile.dest_wire_in_tile_pkey = wire.wire_in_tile_pkey)
GROUP BY
  wire.node_pkey;"""
    )
    c.execute("CREATE INDEX pip_count_index ON node_pip_count(node_pkey);")

    print("{}: Inserting pip counts".format(datetime.datetime.now()))
    c.execute(
        """
UPDATE
  node
SET
  number_pips = (
    SELECT
      node_pip_count.number_pips
    FROM
      node_pip_count
    WHERE
      node_pip_count.node_pkey = node.pkey
  )
WHERE
  pkey IN (
    SELECT
      node_pkey
    FROM
      node_pip_count
  );"""
    )

    c.execute("""DROP TABLE node_pip_count;""")

    c.connection.commit()


def classify_nodes(conn):
    c = conn.cursor()

    # Nodes are NULL if they they only have either a site pin or 1 pip, but
    # nothing else.
    c.execute(
        """
UPDATE node SET classification = ?
    WHERE (node.site_wire_pkey IS NULL AND node.number_pips <= 1) OR
          (node.site_wire_pkey IS NOT NULL AND node.number_pips == 0)
    ;""", (NodeClassification.NULL.value, )
    )
    c.execute(
        """
UPDATE node SET classification = ?
    WHERE node.number_pips > 1 and node.site_wire_pkey IS NULL;""",
        (NodeClassification.CHANNEL.value, )
    )
    c.execute(
        """
UPDATE node SET classification = ?
    WHERE node.number_pips > 1 and node.site_wire_pkey IS NOT NULL;""",
        (NodeClassification.EDGES_TO_CHANNEL.value, )
    )

    null_nodes = []
    edges_to_channel = []
    edge_with_mux = []

    c2 = conn.cursor()
    c2.execute(
        """
SELECT
  count(pkey)
FROM
  node
WHERE
  number_pips == 1
  AND site_wire_pkey IS NOT NULL;"""
    )
    num_nodes = c2.fetchone()[0]
    with progressbar.ProgressBar(max_value=num_nodes) as bar:
        bar.update(0)
        for idx, (node, site_wire_pkey) in enumerate(c2.execute("""
SELECT
  pkey,
  site_wire_pkey
FROM
  node
WHERE
  number_pips == 1
  AND site_wire_pkey IS NOT NULL;""")):
            bar.update(idx)

            c.execute(
                """
WITH wire_in_node(
  wire_pkey, tile_pkey, wire_in_tile_pkey
) AS (
  SELECT
    wire.pkey,
    wire.tile_pkey,
    wire.wire_in_tile_pkey
  FROM
    wire
  WHERE
    wire.node_pkey = ?
)
SELECT
  pip_in_tile.pkey,
  pip_in_tile.src_wire_in_tile_pkey,
  pip_in_tile.dest_wire_in_tile_pkey,
  wire_in_node.wire_pkey,
  wire_in_node.wire_in_tile_pkey,
  wire_in_node.tile_pkey
FROM
  wire_in_node
  INNER JOIN pip_in_tile
WHERE
  pip_in_tile.is_directional = 1 AND pip_in_tile.is_pseudo = 0 AND (
  pip_in_tile.src_wire_in_tile_pkey = wire_in_node.wire_in_tile_pkey
  OR pip_in_tile.dest_wire_in_tile_pkey = wire_in_node.wire_in_tile_pkey)
LIMIT
  1;
""", (node, )
            )

            (
                pip_pkey, src_wire_in_tile_pkey, dest_wire_in_tile_pkey,
                wire_in_node_pkey, wire_in_tile_pkey, tile_pkey
            ) = c.fetchone()
            assert c.fetchone() is None, node

            assert (
                wire_in_tile_pkey == src_wire_in_tile_pkey
                or wire_in_tile_pkey == dest_wire_in_tile_pkey
            ), (wire_in_tile_pkey, pip_pkey)

            if src_wire_in_tile_pkey == wire_in_tile_pkey:
                other_wire = dest_wire_in_tile_pkey
            else:
                other_wire = src_wire_in_tile_pkey

            c.execute(
                """
            SELECT node_pkey FROM wire WHERE
                wire_in_tile_pkey = ? AND
                tile_pkey = ?;
                """, (other_wire, tile_pkey)
            )

            (other_node_pkey, ) = c.fetchone()
            assert c.fetchone() is None
            assert other_node_pkey is not None, (other_wire, tile_pkey)

            c.execute(
                """
            SELECT site_wire_pkey, number_pips
                FROM node WHERE pkey = ?;
                """, (other_node_pkey, )
            )

            result = c.fetchone()
            assert result is not None, other_node_pkey
            other_site_wire_pkey, other_number_pips = result
            assert c.fetchone() is None

            if other_site_wire_pkey is not None and other_number_pips == 1:
                if src_wire_in_tile_pkey == wire_in_tile_pkey:
                    src_wire_pkey = site_wire_pkey
                    dest_wire_pkey = other_site_wire_pkey
                else:
                    src_wire_pkey = other_site_wire_pkey
                    dest_wire_pkey = site_wire_pkey

                edge_with_mux.append(
                    (
                        (node, other_node_pkey), src_wire_pkey, dest_wire_pkey,
                        pip_pkey
                    )
                )
            elif other_site_wire_pkey is None and other_number_pips == 1:
                null_nodes.append(node)
                null_nodes.append(other_node_pkey)
                pass
            else:
                edges_to_channel.append(node)

    for nodes, src_wire_pkey, dest_wire_pkey, pip_pkey in \
            progressbar.progressbar(edge_with_mux):
        assert len(nodes) == 2
        c.execute(
            """
        UPDATE node SET classification = ?
            WHERE pkey IN (?, ?);""",
            (NodeClassification.EDGE_WITH_MUX.value, nodes[0], nodes[1])
        )

        c.execute(
            """
INSERT INTO edge_with_mux(src_wire_pkey, dest_wire_pkey, pip_in_tile_pkey)
VALUES
  (?, ?, ?);""", (src_wire_pkey, dest_wire_pkey, pip_pkey)
        )

    for node in progressbar.progressbar(edges_to_channel):
        c.execute(
            """
        UPDATE node SET classification = ?
            WHERE pkey = ?;""", (
                NodeClassification.EDGES_TO_CHANNEL.value,
                node,
            )
        )

    for null_node in progressbar.progressbar(null_nodes):
        c.execute(
            """
        UPDATE node SET classification = ?
            WHERE pkey = ?;""", (
                NodeClassification.NULL.value,
                null_node,
            )
        )

    c.execute("CREATE INDEX node_type_index ON node(classification);")
    c.connection.commit()


def insert_tracks(conn, tracks_to_insert):
    c = conn.cursor()
    c.execute('SELECT pkey FROM switch WHERE name = "short";')
    short_pkey = c.fetchone()[0]

    track_graph_nodes = {}
    track_pkeys = []
    for node, tracks_list, track_connections, tracks_model in \
            progressbar.progressbar(tracks_to_insert):
        c.execute("""INSERT INTO track DEFAULT VALUES""")
        track_pkey = c.lastrowid
        track_pkeys.append(track_pkey)

        c.execute(
            """UPDATE node SET track_pkey = ? WHERE pkey = ?""",
            (track_pkey, node)
        )

        track_graph_node_pkey = []
        for track in tracks_list:
            if track.direction == 'X':
                node_type = graph2.NodeType.CHANX
            elif track.direction == 'Y':
                node_type = graph2.NodeType.CHANY
            else:
                assert False, track.direction

            c.execute(
                """
INSERT INTO graph_node(
  graph_node_type, track_pkey, node_pkey,
  x_low, x_high, y_low, y_high, capacity
)
VALUES
  (?, ?, ?, ?, ?, ?, ?, 1)""", (
                    node_type.value, track_pkey, node, track.x_low,
                    track.x_high, track.y_low, track.y_high
                )
            )
            track_graph_node_pkey.append(c.lastrowid)

        track_graph_nodes[node] = track_graph_node_pkey

        for connection in track_connections:
            c.execute(
                """
INSERT INTO graph_edge(
  src_graph_node_pkey, dest_graph_node_pkey,
  switch_pkey, track_pkey
)
VALUES
  (?, ?, ?, ?),
  (?, ?, ?, ?)""", (
                    track_graph_node_pkey[connection[0]],
                    track_graph_node_pkey[connection[1]],
                    short_pkey,
                    track_pkey,
                    track_graph_node_pkey[connection[1]],
                    track_graph_node_pkey[connection[0]],
                    short_pkey,
                    track_pkey,
                )
            )

    conn.commit()

    wire_to_graph = {}
    for node, tracks_list, track_connections, tracks_model in \
            progressbar.progressbar(tracks_to_insert):
        track_graph_node_pkey = track_graph_nodes[node]

        c.execute(
            """
WITH wires_from_node(wire_pkey, tile_pkey) AS (
  SELECT
    pkey,
    tile_pkey
  FROM
    wire
  WHERE
    node_pkey = ?
)
SELECT
  wires_from_node.wire_pkey,
  tile.grid_x,
  tile.grid_y
FROM
  tile
  INNER JOIN wires_from_node ON tile.pkey = wires_from_node.tile_pkey;
  """, (node, )
        )

        wires = c.fetchall()

        for wire_pkey, grid_x, grid_y in wires:
            connections = list(
                tracks_model.get_tracks_for_wire_at_coord((grid_x, grid_y))
            )
            assert len(connections) > 0, (
                wire_pkey, track_pkey, grid_x, grid_y
            )
            graph_node_pkey = track_graph_node_pkey[connections[0][0]]

            wire_to_graph[wire_pkey] = graph_node_pkey

    for wire_pkey, graph_node_pkey in progressbar.progressbar(
            wire_to_graph.items()):
        c.execute(
            """
        UPDATE wire SET graph_node_pkey = ?
            WHERE pkey = ?""", (graph_node_pkey, wire_pkey)
        )

    conn.commit()

    c.execute("""CREATE INDEX graph_node_nodes ON graph_node(node_pkey);""")
    c.execute("""CREATE INDEX graph_node_tracks ON graph_node(track_pkey);""")
    c.execute("""CREATE INDEX graph_edge_tracks ON graph_edge(track_pkey);""")

    conn.commit()
    return track_pkeys


def create_track(node, unique_pos):
    xs, ys = points.decompose_points_into_tracks(unique_pos)
    tracks_list, track_connections = tracks.make_tracks(xs, ys, unique_pos)
    tracks_model = tracks.Tracks(tracks_list, track_connections)

    return [node, tracks_list, track_connections, tracks_model]


def form_tracks(conn):
    c = conn.cursor()

    c.execute(
        'SELECT count(pkey) FROM node WHERE classification == ?;',
        (NodeClassification.CHANNEL.value, )
    )
    num_nodes = c.fetchone()[0]

    tracks_to_insert = []
    with progressbar.ProgressBar(max_value=num_nodes) as bar:
        bar.update(0)
        c2 = conn.cursor()
        for idx, (node, ) in enumerate(c.execute("""
SELECT pkey FROM node WHERE classification == ?;
""", (NodeClassification.CHANNEL.value, ))):
            bar.update(idx)

            unique_pos = set()
            for wire_pkey, grid_x, grid_y in c2.execute("""
WITH wires_from_node(wire_pkey, tile_pkey) AS (
  SELECT
    pkey,
    tile_pkey
  FROM
    wire
  WHERE
    node_pkey = ?
)
SELECT
  wires_from_node.wire_pkey,
  tile.grid_x,
  tile.grid_y
FROM
  tile
  INNER JOIN wires_from_node ON tile.pkey = wires_from_node.tile_pkey;
  """, (node, )):
                unique_pos.add((grid_x, grid_y))

            tracks_to_insert.append(create_track(node, unique_pos))

    # Create constant tracks
    vcc_track_to_insert, gnd_track_to_insert = create_constant_tracks(conn)
    vcc_idx = len(tracks_to_insert)
    tracks_to_insert.append(vcc_track_to_insert)
    gnd_idx = len(tracks_to_insert)
    tracks_to_insert.append(gnd_track_to_insert)

    track_pkeys = insert_tracks(conn, tracks_to_insert)
    vcc_track_pkey = track_pkeys[vcc_idx]
    gnd_track_pkey = track_pkeys[gnd_idx]

    c.execute(
        """
INSERT INTO constant_sources(vcc_track_pkey, gnd_track_pkey) VALUES (?, ?)
        """, (
            vcc_track_pkey,
            gnd_track_pkey,
        )
    )

    conn.commit()

    connect_hardpins_to_constant_network(conn, vcc_track_pkey, gnd_track_pkey)


def connect_hardpins_to_constant_network(conn, vcc_track_pkey, gnd_track_pkey):
    """ Connect TIEOFF HARD1 and HARD0 pins.

    Update nodes connected to to HARD1 or HARD0 pins to point to the new
    VCC or GND track.  This should connect the pips to the constant
    network instead of the TIEOFF site.
    """

    c = conn.cursor()
    c.execute("""
SELECT pkey FROM site_type WHERE name = ?
""", ("TIEOFF", ))
    results = c.fetchall()
    assert len(results) == 1, results
    tieoff_site_type_pkey = results[0][0]

    c.execute(
        """
SELECT pkey FROM site_pin WHERE site_type_pkey = ? and name = ?
""", (tieoff_site_type_pkey, "HARD1")
    )
    vcc_site_pin_pkey = c.fetchone()[0]
    c.execute(
        """
SELECT pkey FROM wire_in_tile WHERE site_pin_pkey = ?
""", (vcc_site_pin_pkey, )
    )

    c2 = conn.cursor()
    c2.execute("""BEGIN EXCLUSIVE TRANSACTION;""")

    for (wire_in_tile_pkey, ) in c:
        c2.execute(
            """
UPDATE node SET track_pkey = ? WHERE pkey IN (
    SELECT node_pkey FROM wire WHERE wire_in_tile_pkey = ?
)
            """, (
                vcc_track_pkey,
                wire_in_tile_pkey,
            )
        )

    c.execute(
        """
SELECT pkey FROM site_pin WHERE site_type_pkey = ? and name = ?
""", (tieoff_site_type_pkey, "HARD0")
    )
    gnd_site_pin_pkey = c.fetchone()[0]
    c.execute(
        """
SELECT pkey FROM wire_in_tile WHERE site_pin_pkey = ?
""", (gnd_site_pin_pkey, )
    )

    c.execute(
        """
SELECT pkey FROM wire_in_tile WHERE site_pin_pkey = ?
""", (gnd_site_pin_pkey, )
    )
    for (wire_in_tile_pkey, ) in c:
        c2.execute(
            """
UPDATE node SET track_pkey = ? WHERE pkey IN (
    SELECT node_pkey FROM wire WHERE wire_in_tile_pkey = ?
)
            """, (
                gnd_track_pkey,
                wire_in_tile_pkey,
            )
        )

    c2.execute("""COMMIT TRANSACTION""")


def create_constant_tracks(conn):
    """ Create two tracks that go to all TIEOFF sites to route constants.

    Returns (vcc_track_to_insert, gnd_track_to_insert), suitable for insert
    via insert_tracks function.

    """

    # Make constant track available to all tiles.
    c = conn.cursor()
    unique_pos = set()
    c.execute('SELECT grid_x, grid_y FROM tile')
    for grid_x, grid_y in c:
        if grid_x == 0 or grid_y == 0:
            continue
        unique_pos.add((grid_x, grid_y))

    c.execute(
        """
INSERT INTO node(classification) VALUES (?)
""", (NodeClassification.CHANNEL.value, )
    )
    vcc_node = c.lastrowid

    c.execute(
        """
INSERT INTO node(classification) VALUES (?)
""", (NodeClassification.CHANNEL.value, )
    )
    gnd_node = c.lastrowid

    conn.commit()

    return create_track(vcc_node, unique_pos), \
           create_track(gnd_node, unique_pos)


def insert_vpr_tile(conn, vpr_tile_name, vpr_tile_loc, vpr_tile_type_pkey, phy_tile_pkey):
    """
    Inserts a tile into the VPR tile grid. Adds also location correspondence
    (through pkeys) to its counterpart in physical tile grid

    Args:
        conn: Database connection
        vpr_tile_name: Tile name for VPR
        vpr_tile_loc: Tile location in VPR grid (tuple)
        vpr_tile_type_pkey: Tile type pkey
        phy_tile_pkey: Corresponding tile pkey in the physical grid

    Returns:
        None
    """

    c = conn.cursor()

    # Insert the tile into the tile grid
    c.execute(
        "INSERT INTO tile(pkey, name, tile_type_pkey, grid_x, grid_y)"
        "VALUES (?, ?, ?, ?)",
        (vpr_tile_name, vpr_tile_type_pkey, vpr_tile_loc[0], vpr_tile_loc[1])
    )

    # Insert location correspondence
    new_pkey = c.lastrowid
    c.execute(
        "INSERT INTO grid_loc_map(phy_tile_pkey, vpr_tile_pkey)"
        "VALUES (?, ?)", (phy_tile_pkey, new_pkey)
    )


def remap_tile_grid(conn, grid_map, tile_map):
    """
    Remaps tiles present in the "phy_tile" table to the "tile" table.
    :param conn:
    :param grid_map:
    :return:
    """

    c = conn.cursor()

    # Get NULL tile pkey
    null_pkey = c.execute("SELECT pkey FROM tile_type WHERE name = \"NULL\""
                          ).fetchone()[0]

    assert null_pkey is not None

    # Fetch all physical tiles from the database
    tile_data = c.execute(
        "SELECT pkey, name, tile_type_pkey, grid_x, grid_y FROM phy_tile"
    ).fetchall()

    # Convert them to the new grid one-by-one
    for tile in tile_data:
        tile_type_pkey = tile[2]
        phy_loc_x = tile[3]
        phy_loc_y = tile[4]

        # Map location. Possibly one to many
        vpr_locs = grid_map.get_vpr_loc((phy_loc_x, phy_loc_y))

        # The tile is being split
        if tile_type_pkey in tile_map.fwd_map:

            # Get base VPR location
            base_vpr_loc = (
                min([loc[0] for loc in vpr_locs]),
                min([loc[1] for loc in vpr_locs])
            )

            # Get data from tile type map
            vpr_tile_data = tile_map.fwd_map[tile_type_pkey]

            # Insert tiles into the VPR grid
            for vpr_tile_type_pkey, loc_ofs in vpr_tile_data:

                # Compute location in the VPR grid
                vpr_loc = (
                    base_vpr_loc[0] + loc_ofs[0],
                    base_vpr_loc[1] + loc_ofs[1],
                )

                # Get tile type as string
                vpr_tile_type = c.execute("SELECT name FROM tile_type WHERE pkey = (?)", (vpr_tile_type_pkey, )).fetchone()[0]

                # Generate new tile name
                # FIXME: This will be the SLICE name. However it will not match
                # the Vivado slice name, coordinates will differ.
                vpr_tile_name = "%s_X%dY%d" % (vpr_tile_type, vpr_loc[0], vpr_loc[1])

                # Insert the tile into grid
                insert_vpr_tile(conn, vpr_tile_name, vpr_loc, vpr_tile_type_pkey, tile[0])

        # The tile is not being split
        else:

            # Insert the tile into grid
            insert_vpr_tile(conn, tile[1], vpr_locs[0], tile_type_pkey, tile[0])

            # If one physical location corresponds to more than one VPR location
            # then fill the space with artificial EMPTY tiles.
            for i in range(1, len(vpr_locs)):
                tile_name = "EMPTY_X%dY%d" % (vpr_locs[i][0], vpr_locs[i][1])

                # Insert the tile into grid
                insert_vpr_tile(conn, tile_name, vpr_locs[i], null_pkey, tile[0])

    # Build indices
    c.execute("CREATE INDEX tile_type_index ON tile(tile_type_pkey);")
    c.execute("CREATE INDEX tile_name_index ON tile(name);")
    c.execute("CREATE INDEX tile_location_index ON tile(grid_x, grid_y);")

    c.connection.commit()


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        '--db_root', help='Project X-Ray Database', required=True
    )
    parser.add_argument(
        '--connection_database', help='Connection database', required=True
    )

    args = parser.parse_args()
    if os.path.exists(args.connection_database):
        os.remove(args.connection_database)

    with DatabaseCache(args.connection_database) as conn:

        create_tables(conn)

        print("{}: About to load database".format(datetime.datetime.now()))
        db = prjxray.db.Database(args.db_root)
        grid = db.grid()
        import_grid(db, grid, conn)
        print("{}: Initial database formed".format(datetime.datetime.now()))

        # List of tile types to split
        tile_types_to_split = ["CLBLL_L", "CLBLL_R", "CLBLM_L", "CLBLM_R"]

        gs = GridSplitter(conn)
        gs.set_tile_types_to_split(tile_types_to_split)

        ts = TileSplitter(db, conn)
        ts.set_tile_types_to_split(tile_types_to_split)

        grid_map = gs.split()
        tile_type_pkey_map, tile_wire_name_map = ts.split()

        print("{}: Grid map initialized".format(datetime.datetime.now()))
        remap_tile_grid(conn, grid_map, tile_type_pkey_map)
        print("{}: Tile grid remapped".format(datetime.datetime.now()))
        #import_nodes(db, conn, tile_types_to_split, tile_wire_name_map)
        #print("{}: Connections made".format(datetime.datetime.now()))
        #count_sites_and_pips_on_nodes(conn)
        #print("{}: Counted sites and pips".format(datetime.datetime.now()))
        # classify_nodes(conn)
        # print("{}: Nodes classified".format(datetime.datetime.now()))
        # form_tracks(conn)
        # print("{}: Tracks formed".format(datetime.datetime.now()))
        #
        # print(
        #     '{} Flushing database back to file "{}"'.format(
        #         datetime.datetime.now(), args.connection_database
        #     )
        # )

        print("/\\/\\/\\/\\ FINISHED /\\/\\/\\/\\")


if __name__ == '__main__':
    main()
