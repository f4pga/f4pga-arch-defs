#!/usr/bin/env python3
""" Classify 7-series nodes and generate channels for required nodes. """

import argparse
import prjxray.db
import progressbar
from lib.rr_graph import points
from lib.rr_graph import tracks
from lib.rr_graph import graph2
import sqlite3
import datetime
import os
import os.path
from lib.connection_database import NodeClassification

def create_tables(conn):
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

def import_site_type(db, c, site_types, site_type_name):
    assert site_type_name not in site_types
    site_type = db.get_site_type(site_type_name)

    c.execute("INSERT INTO site_type(name) VALUES (?)", (site_type_name,))
    site_types[site_type_name] = c.lastrowid

    for site_pin in site_type.get_site_pins():
        pin_info = site_type.get_site_pin(site_pin)

        c.execute("""INSERT INTO site_pin(name, site_type_pkey, direction)
             VALUES (?, ?, ?)""",
             (pin_info.name, site_types[site_type_name], pin_info.direction.value))

def import_tile_type(db, c, tile_types, site_types, tile_type_name):
    assert tile_type_name not in tile_types
    tile_type = db.get_tile_type(tile_type_name)

    c.execute("INSERT INTO tile_type(name) VALUES (?)", (tile_type_name,))
    tile_types[tile_type_name] = c.lastrowid

    wires = {}
    for wire in tile_type.get_wires():
        c.execute("""INSERT INTO wire_in_tile(name, tile_type_pkey)
            VALUES (?, ?)""",
            (wire, tile_types[tile_type_name]))
        wires[wire] = c.lastrowid

    for pip in tile_type.get_pips():
        # Psuedo pips are not part of the routing fabric, so don't add them.
        if pip.is_pseudo:
            continue

        if not pip.is_directional:
            continue

        c.execute("""INSERT INTO pip_in_tile(name, tile_type_pkey, src_wire_in_tile_pkey, dest_wire_in_tile_pkey)
            VALUES (?, ?, ?, ?)""",
            (pip.name, tile_types[tile_type_name], wires[pip.net_from], wires[pip.net_to]))

    for site in tile_type.get_sites():
        if site.type not in site_types:
            import_site_type(db, c, site_types, site.type)

def add_wire_to_site_relation(db, c, tile_types, site_types, tile_type_name):
    tile_type = db.get_tile_type(tile_type_name)
    for site in tile_type.get_sites():
        c.execute("""INSERT INTO site(name, x_coord, y_coord, site_type_pkey)
            VALUES (?, ?, ?, ?)""", (site.name, site.x, site.y, site_types[site.type]))

        site_pkey = c.lastrowid

        for site_pin in site.site_pins:
            c.execute("""SELECT pkey FROM site_pin WHERE name = ? AND
                    site_type_pkey = ?""", (site_pin.name, site_types[site.type]))

            result = c.fetchone()
            site_pin_pkey = result[0]
            c.execute("""UPDATE wire_in_tile
            SET site_pkey = ?,
                site_pin_pkey = ?
            WHERE name = ? and tile_type_pkey = ?;""", (
                site_pkey, site_pin_pkey, site_pin.wire,
                tile_types[tile_type_name]))

def build_tile_type_indicies(c):
    c.execute("CREATE INDEX site_pin_index ON site_pin(name, site_type_pkey);")
    c.execute("CREATE INDEX wire_name_index ON wire_in_tile(name, tile_type_pkey);")
    c.execute("CREATE INDEX wire_site_pin_index ON wire_in_tile(site_pin_pkey);")
    c.execute("CREATE INDEX tile_type_index ON tile(tile_type_pkey);")
    c.execute("CREATE INDEX pip_tile_type_index ON pip_in_tile(tile_type_pkey);")
    c.execute("CREATE INDEX src_pip_index ON pip_in_tile(src_wire_in_tile_pkey);")
    c.execute("CREATE INDEX dest_pip_index ON pip_in_tile(dest_wire_in_tile_pkey);")

def build_other_indicies(c):
    c.execute("CREATE INDEX tile_name_index ON tile(name);")
    c.execute("CREATE INDEX tile_location_index ON tile(grid_x, grid_y);")

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
        c.execute("""INSERT INTO tile(name, tile_type_pkey, grid_x, grid_y)
            VALUES (?, ?, ?, ?)""",
            (tile, tile_types[gridinfo.tile_type], loc.grid_x, loc.grid_y))

    build_other_indicies(c)
    c.connection.commit()

def import_nodes(db, grid, conn):
    # Some nodes are just 1 wire, so start by enumerating all wires.

    c = conn.cursor()
    c2 = conn.cursor()
    c2.execute("""BEGIN EXCLUSIVE TRANSACTION;""")

    tiles = {}
    tile_wire_map = {}
    wires = {}
    for tile in progressbar.progressbar(grid.tiles()):
        gridinfo = grid.gridinfo_at_tilename(tile)
        tile_type = db.get_tile_type(gridinfo.tile_type)

        c.execute("""SELECT pkey, tile_type_pkey FROM tile WHERE name = ?;""",
                (tile,))
        tile_pkey, tile_type_pkey = c.fetchone()
        tiles[tile] = (tile_pkey, tile_type_pkey)

        for wire in tile_type.get_wires():
            # pkey node_pkey tile_pkey wire_in_tile_pkey
            c.execute("""SELECT pkey FROM wire_in_tile WHERE name = ? and tile_type_pkey = ?;""",
                    (wire, tile_type_pkey))
            (wire_in_tile_pkey,) = c.fetchone()

            c2.execute("""
            INSERT INTO wire(tile_pkey, wire_in_tile_pkey) VALUES
            (?, ?);""", (tile_pkey, wire_in_tile_pkey))

            assert (tile, wire) not in tile_wire_map
            wire_pkey = c2.lastrowid
            tile_wire_map[(tile, wire)] = wire_pkey
            wires[wire_pkey] = None

    c2.execute("""COMMIT TRANSACTION;""")

    connections = db.connections()

    for connection in progressbar.progressbar(connections.get_connections()):
        a_pkey = tile_wire_map[(connection.wire_a.tile, connection.wire_a.wire)]
        b_pkey = tile_wire_map[(connection.wire_b.tile, connection.wire_b.wire)]

        a_node = wires[a_pkey]
        b_node = wires[b_pkey]

        if a_node is None:
            a_node = set((a_pkey,))

        if b_node is None:
            b_node = set((b_pkey,))

        if a_node is not b_node:
            a_node |= b_node

            for wire in a_node:
                wires[wire] = a_node

    nodes = {}
    for wire_pkey, node in wires.items():
        if node is None:
            node = set((wire_pkey,))

        assert wire_pkey in node

        nodes[id(node)] = node

    wires_assigned = set()
    for node in progressbar.progressbar(nodes.values()):
        c.execute("""INSERT INTO node(number_pips) VALUES (0);""")
        node_pkey = c.lastrowid

        for wire_pkey in node:
            wires_assigned.add(wire_pkey)
            c.execute("""
            UPDATE wire
                SET node_pkey = ?
                WHERE pkey = ?
            ;""", (node_pkey, wire_pkey))

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
    c.execute("""
WITH
  node_sites(node_pkey, number_site_pins) AS (
   SELECT wire.node_pkey, count(wire_in_tile.site_pin_pkey) FROM wire_in_tile
   INNER JOIN wire ON
     wire.wire_in_tile_pkey = wire_in_tile.pkey
     WHERE wire_in_tile.site_pin_pkey IS NOT NULL
  GROUP BY wire.node_pkey)
SELECT max(node_sites.number_site_pins) FROM node_sites;
""")

    # Nodes are only expected to have 1 site
    assert c.fetchone()[0] == 1

    print("{}: Assigning site wires for nodes".format(datetime.datetime.now()))
    c.execute("""
WITH
  site_wires(wire_pkey, node_pkey) AS (
    SELECT wire.pkey, wire.node_pkey FROM wire_in_tile
    INNER JOIN wire ON
      wire.wire_in_tile_pkey = wire_in_tile.pkey
      WHERE wire_in_tile.site_pin_pkey IS NOT NULL)
UPDATE node SET site_wire_pkey = (
  SELECT site_wires.wire_pkey FROM site_wires WHERE site_wires.node_pkey = node.pkey
  );
      """)

    print("{}: Counting pips on nodes".format(datetime.datetime.now()))
    c.execute("""
    CREATE TABLE node_pip_count(
      node_pkey INT,
      number_pips INT,
      FOREIGN KEY(node_pkey) REFERENCES node(pkey)
    );""")
    c.execute("""
    INSERT INTO node_pip_count(node_pkey, number_pips)
    SELECT wire.node_pkey, count(pip_in_tile.pkey) FROM pip_in_tile
    INNER JOIN wire WHERE
        pip_in_tile.src_wire_in_tile_pkey = wire.wire_in_tile_pkey OR
        pip_in_tile.dest_wire_in_tile_pkey = wire.wire_in_tile_pkey
    GROUP BY wire.node_pkey;""");
    c.execute("CREATE INDEX pip_count_index ON node_pip_count(node_pkey);")

    print("{}: Inserting pip counts".format(datetime.datetime.now()))
    c.execute("""
    UPDATE node SET number_pips = (
        SELECT node_pip_count.number_pips FROM node_pip_count
        WHERE node_pip_count.node_pkey = node.pkey
    ) WHERE pkey IN (SELECT node_pkey FROM node_pip_count);""")

    c.execute("""DROP TABLE node_pip_count;""")

    c.connection.commit()

def classify_nodes(conn):
    c = conn.cursor()

    # Nodes are NULL if they they only have either a site pin or 1 pip, but
    # nothing else.
    c.execute("""
UPDATE node SET classification = ?
    WHERE (node.site_wire_pkey IS NULL AND node.number_pips <= 1) OR
          (node.site_wire_pkey IS NOT NULL AND node.number_pips == 0)
    ;""",
    (NodeClassification.NULL.value,))
    c.execute("""
UPDATE node SET classification = ?
    WHERE node.number_pips > 1 and node.site_wire_pkey IS NULL;""",
    (NodeClassification.CHANNEL.value,))
    c.execute("""
UPDATE node SET classification = ?
    WHERE node.number_pips > 1 and node.site_wire_pkey IS NOT NULL;""",
    (NodeClassification.EDGES_TO_CHANNEL.value,))

    null_nodes = []
    edges_to_channel = []
    edge_with_mux = []

    c2 = conn.cursor()
    c2.execute("SELECT count(pkey) FROM node WHERE number_pips == 1 AND site_wire_pkey IS NOT NULL;")
    num_nodes = c2.fetchone()[0]
    with progressbar.ProgressBar(max_value=num_nodes) as bar:
        bar.update(0)
        for idx, (node, site_wire_pkey) in enumerate(c2.execute("""
SELECT pkey, site_wire_pkey FROM node WHERE number_pips == 1 AND site_wire_pkey IS NOT NULL;""")):
            bar.update(idx)

            c.execute("""
WITH wire_in_node(wire_pkey, tile_pkey, wire_in_tile_pkey) AS (
    SELECT wire.pkey, wire.tile_pkey, wire.wire_in_tile_pkey FROM wire
    WHERE wire.node_pkey = ?)
SELECT pip_in_tile.pkey,
       pip_in_tile.src_wire_in_tile_pkey,
       pip_in_tile.dest_wire_in_tile_pkey,
       wire_in_node.wire_pkey,
       wire_in_node.wire_in_tile_pkey,
       wire_in_node.tile_pkey
  FROM wire_in_node
  INNER JOIN pip_in_tile
  WHERE pip_in_tile.src_wire_in_tile_pkey = wire_in_node.wire_in_tile_pkey OR
        pip_in_tile.dest_wire_in_tile_pkey = wire_in_node.wire_in_tile_pkey LIMIT 1;
""", (node,))

            (
                    pip_pkey,
                    src_wire_in_tile_pkey,
                    dest_wire_in_tile_pkey,
                    wire_in_node_pkey,
                    wire_in_tile_pkey,
                    tile_pkey) = c.fetchone()
            assert c.fetchone() is None, node

            assert (
                    wire_in_tile_pkey == src_wire_in_tile_pkey or
                    wire_in_tile_pkey == dest_wire_in_tile_pkey
                    ), (wire_in_tile_pkey, pip_pkey)

            if src_wire_in_tile_pkey == wire_in_tile_pkey:
                other_wire = dest_wire_in_tile_pkey
            else:
                other_wire = src_wire_in_tile_pkey

            c.execute("""
            SELECT node_pkey FROM wire WHERE
                wire_in_tile_pkey = ? AND
                tile_pkey = ?;
                """, (other_wire, tile_pkey))

            (other_node_pkey,) = c.fetchone()
            assert c.fetchone() is None
            assert other_node_pkey is not None, (other_wire, tile_pkey)

            c.execute("""
            SELECT site_wire_pkey, number_pips
                FROM node WHERE pkey = ?;
                """, (other_node_pkey,))

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

                edge_with_mux.append(((node, other_node_pkey),
                    src_wire_pkey, dest_wire_pkey, pip_pkey))
            elif other_site_wire_pkey is None and other_number_pips == 1:
                null_nodes.append(node)
                null_nodes.append(other_node_pkey)
                pass
            else:
                edges_to_channel.append(node)

    for nodes, src_wire_pkey, dest_wire_pkey, pip_pkey in progressbar.progressbar(edge_with_mux):
        assert len(nodes) == 2
        c.execute("""
        UPDATE node SET classification = ?
            WHERE pkey IN (?, ?);""",
            (NodeClassification.EDGE_WITH_MUX.value, nodes[0], nodes[1]))

        c.execute("""
        INSERT INTO edge_with_mux(src_wire_pkey, dest_wire_pkey, pip_in_tile_pkey)
            VALUES (?, ?, ?);""", (src_wire_pkey, dest_wire_pkey, pip_pkey))

    for node in progressbar.progressbar(edges_to_channel):
        c.execute("""
        UPDATE node SET classification = ?
            WHERE pkey = ?;""", (NodeClassification.EDGES_TO_CHANNEL.value, node,))

    for null_node in progressbar.progressbar(null_nodes):
        c.execute("""
        UPDATE node SET classification = ?
            WHERE pkey = ?;""", (NodeClassification.NULL.value, null_node,))

    c.execute("CREATE INDEX node_type_index ON node(classification);")
    c.connection.commit()

def insert_tracks(conn, tracks_to_insert):
    c = conn.cursor()
    # TODO: Use short
    #c.execute('SELECT pkey FROM switch WHERE name = "short";')
    #short_pkey = c.fetchone()[0]
    c.execute('SELECT pkey FROM switch WHERE name = "__vpr_delayless_switch__";')
    short_pkey = c.fetchone()[0]

    track_graph_nodes = {}
    for node, tracks_list, track_connections, tracks_model in progressbar.progressbar(tracks_to_insert):
        c.execute("""INSERT INTO track DEFAULT VALUES""")
        track_pkey = c.lastrowid

        c.execute("""UPDATE node SET track_pkey = ? WHERE pkey = ?""",
                (track_pkey, node))

        track_graph_node_pkey = []
        for track in tracks_list:
            if track.direction == 'X':
                node_type = graph2.NodeType.CHANX
            elif track.direction == 'Y':
                node_type = graph2.NodeType.CHANY
            else:
                assert False, track.direction

            c.execute("""
            INSERT INTO graph_node(
                graph_node_type, track_pkey, node_pkey, x_low, x_high, y_low, y_high, capacity)
                VALUES (?, ?, ?, ?, ?, ?, ?, 1)""", (
                node_type.value, track_pkey, node,
                track.x_low, track.x_high, track.y_low, track.y_high
                ))
            track_graph_node_pkey.append(c.lastrowid)

        track_graph_nodes[node] = track_graph_node_pkey

        for connection in track_connections:
            c.execute("""
            INSERT INTO graph_edge(src_graph_node_pkey, dest_graph_node_pkey, switch_pkey, track_pkey)
                VALUES (?, ?, ?, ?), (?, ?, ?, ?)""", (
                track_graph_node_pkey[connection[0]],
                track_graph_node_pkey[connection[1]],
                short_pkey,
                track_pkey,
                track_graph_node_pkey[connection[1]],
                track_graph_node_pkey[connection[0]],
                short_pkey,
                track_pkey,
                ))

    conn.commit()

    wire_to_graph = {}
    for node, tracks_list, track_connections, tracks_model in progressbar.progressbar(tracks_to_insert):
        track_graph_node_pkey = track_graph_nodes[node]

        c.execute("""
WITH
    wires_from_node(wire_pkey, tile_pkey) AS (
      SELECT pkey, tile_pkey FROM wire WHERE node_pkey = ?)
SELECT wires_from_node.wire_pkey, tile.grid_x, tile.grid_y
  FROM tile
  INNER JOIN wires_from_node
  ON tile.pkey = wires_from_node.tile_pkey;
  """, (node,))

        wires = c.fetchall()

        for wire_pkey, grid_x, grid_y in wires:
            connections = list(tracks_model.get_tracks_for_wire_at_coord((grid_x, grid_y)))
            assert len(connections) > 0
            graph_node_pkey = track_graph_node_pkey[connections[0][0]]

            wire_to_graph[wire_pkey] = graph_node_pkey

    for wire_pkey, graph_node_pkey in progressbar.progressbar(wire_to_graph.items()):
        c.execute("""
        UPDATE wire SET graph_node_pkey = ?
                WHERE pkey = ?""", (graph_node_pkey, wire_pkey))

    conn.commit()

    c.execute("""CREATE INDEX graph_node_nodes ON graph_node(node_pkey);""")
    c.execute("""CREATE INDEX graph_node_tracks ON graph_node(track_pkey);""")
    c.execute("""CREATE INDEX graph_edge_tracks ON graph_edge(track_pkey);""")

    conn.commit()


def form_tracks(conn):
    c = conn.cursor()

    c.execute('SELECT count(pkey) FROM node WHERE classification == ?;',
            (NodeClassification.CHANNEL.value,))
    num_nodes = c.fetchone()[0]

    tracks_to_insert = []
    with progressbar.ProgressBar(max_value=num_nodes) as bar:
        bar.update(0)
        c2 = conn.cursor()
        for idx, (node,) in enumerate(c.execute("""
SELECT pkey FROM node WHERE classification == ?;
""", (NodeClassification.CHANNEL.value,))):
            bar.update(idx)

            unique_pos = set()
            for wire_pkey, grid_x, grid_y in c2.execute("""
WITH
    wires_from_node(wire_pkey, tile_pkey) AS (
      SELECT pkey, tile_pkey FROM wire WHERE node_pkey = ?)
SELECT wires_from_node.wire_pkey, tile.grid_x, tile.grid_y
  FROM tile
  INNER JOIN wires_from_node
  ON tile.pkey = wires_from_node.tile_pkey;
  """, (node,)):
                unique_pos.add((grid_x, grid_y))

            xs, ys = points.decompose_points_into_tracks(unique_pos)
            tracks_list, track_connections = tracks.make_tracks(xs, ys, unique_pos)
            tracks_model = tracks.Tracks(tracks_list, track_connections)

            tracks_to_insert.append([node, tracks_list, track_connections, tracks_model])

    insert_tracks(conn, tracks_to_insert)

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument(
            '--db_root', help='Project X-Ray Database', required=True)
    parser.add_argument(
            '--connection_database', help='Connection database', required=True)

    args = parser.parse_args()
    if os.path.exists(args.connection_database):
        os.remove(args.connection_database)

    conn = sqlite3.connect(args.connection_database)
    create_tables(conn)

    print("{}: About to load database".format(datetime.datetime.now()))
    db = prjxray.db.Database(args.db_root)
    grid = db.grid()
    import_grid(db, grid, conn)
    print("{}: Initial database formed".format(datetime.datetime.now()))
    import_nodes(db, grid, conn)
    print("{}: Connections made".format(datetime.datetime.now()))
    count_sites_and_pips_on_nodes(conn)
    print("{}: Counted sites and pips".format(datetime.datetime.now()))
    classify_nodes(conn)
    print("{}: Nodes classified".format(datetime.datetime.now()))
    form_tracks(conn)
    print("{}: Tracks formed".format(datetime.datetime.now()))

if __name__ == '__main__':
    main()
