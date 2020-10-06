#!/usr/bin/env python3
""" Assign pin directions to all tile pins.

Tile pins are defined by one of two methods:
 - Pins that are part of a direct connection (e.g. edge_with_mux) are assigned
   based on the direction relationship between the two tiles, e.g. facing each
   other.
 - Pins that connect to a routing track face a routing track.

Tile pins may end up with multiple edges if the routing tracks are formed
differently throughout the grid.

No connection database modifications are made in
prjxray_assign_tile_pin_direction.

"""
import argparse
import datetime
import simplejson as json
import prjuray.db

from lib.connection_database import yield_tiles_and_wires_for_node
from lib.connection_database import NodeClassification
from lib.connection_database import get_track_model
from lib import progressbar_utils

from prjxray_db_cache import DatabaseCache

from assign_tile_pin_direction import handle_direction_connections
from assign_tile_pin_direction import handle_edges_to_channels
from assign_tile_pin_direction import process_edge_assignments

now = datetime.datetime.now

# =============================================================================


def yield_tiles_and_wires_of_tile_type(conn, tile_type_pkey):

    c = conn.cursor()
    for (tile_name, wire_name,) in c.execute("""
WITH
  tile_instance(tile_pkey, tile_type_pkey, name)
AS (
  SELECT
    tile.pkey,
    phy_tile.tile_type_pkey,
    phy_tile.name
  FROM
    tile
  INNER JOIN
    phy_tile
  ON
    tile.phy_tile_pkey == phy_tile.pkey
),
  wire_instance(tile_pkey, name)
AS (
  SELECT
    wire.tile_pkey,
    wire_in_tile.name
  FROM
    wire
  INNER JOIN
    wire_in_tile
  WHERE
    wire.wire_in_tile_pkey == wire_in_tile.pkey
)
SELECT
  tile_instance.name,
  wire_instance.name
FROM
  wire_instance
INNER JOIN
  tile_instance
ON
  wire_instance.tile_pkey == tile_instance.tile_pkey
WHERE
  tile_instance.tile_type_pkey == ?
        """, (tile_type_pkey,)):
        yield (tile_name, wire_name,)


def initialize_edge_assignments(db, conn):
    """ Create initial edge_assignments map. """
    c = conn.cursor()
    c2 = conn.cursor()

    c.execute(
        """
SELECT name, pkey FROM tile_type WHERE pkey IN (
    SELECT DISTINCT tile_type_pkey FROM tile
    );"""
    )
    tiles = dict(c)

    edge_assignments = {}
    wires_in_tiles = set()

    # First find out which tile types were split during VPR grid formation.
    # These tile types should not get edge assignments directly, instead
    # their sites will get edge assignements.
    sites_as_tiles = set()
    split_tile_types = set()
    for site_pkey, tile_type_pkey in c.execute("""
        SELECT site_pkey, tile_type_pkey FROM site_as_tile;
        """):
        c2.execute(
            "SELECT name FROM tile_type WHERE pkey = ?", (tile_type_pkey, )
        )
        split_tile_types.add(c2.fetchone()[0])

        c2.execute(
            """
SELECT name FROM site_type WHERE pkey = (
    SELECT site_type_pkey FROM site WHERE pkey = ?
    );""", (site_pkey, )
        )
        site_type_name = c2.fetchone()[0]
        sites_as_tiles.add(site_type_name)

    # Initialize edge assignments for split tiles
    for site_type in sites_as_tiles:
        del tiles[site_type]

        site_obj = db.get_site_type(site_type)
        for site_pin in site_obj.get_site_pins():
            key = (site_type, site_pin)
            assert key not in edge_assignments, key

            edge_assignments[key] = []

    for tile_type in db.get_tile_types():
        if tile_type not in tiles:
            continue

        del tiles[tile_type]

        # Skip tile types that are split tiles
        if tile_type in split_tile_types:
            continue

        print("", tile_type)

        (tile_type_pkey, ) = c.execute(
            """
    SELECT pkey
    FROM tile_type
    WHERE name = ?
        """, (tile_type, )
        ).fetchone()

        for tile, wire in yield_tiles_and_wires_of_tile_type(conn, tile_type_pkey):
            wires_in_tiles.add((tile, wire,))

        type_obj = db.get_tile_type(tile_type)
        for site in type_obj.get_sites():
            for site_pin in site.site_pins:
                if site_pin.wire is None:
                    continue

                # Skip if this wire is not in the database
                c.execute(
                    """
    SELECT pkey
    FROM wire_in_tile
    WHERE name = ?
""", (site_pin.wire, )
                )
                if not c.fetchone():
                    continue

                key = (tile_type, site_pin.wire)
                assert key not in edge_assignments, key
                edge_assignments[key] = []

    for tile_type, tile_pkey in tiles.items():
        assert tile_type not in split_tile_types

        print("", tile_type)

        for tile, wire in yield_tiles_and_wires_of_tile_type(conn, tile_type_pkey):
            wires_in_tiles.add((tile, wire,))

        for (wire, ) in c.execute("""
SELECT DISTINCT name
FROM wire_in_tile
WHERE pkey in (
    SELECT DISTINCT wire_in_tile_pkey
    FROM wire
    WHERE tile_pkey IN (
        SELECT pkey
        FROM tile
        WHERE tile_type_pkey = ?)
    )
    AND
        site_pin_pkey IS NOT NULL""", (tile_pkey, )):
            key = (tile_type, wire)
            assert key not in edge_assignments, key
            edge_assignments[key] = []

    return edge_assignments, wires_in_tiles


def process_non_channel_nodes(conn, wires_in_tiles):
    """
    Identifies and returns a set of wires that are not channels.
    """

    wires_not_in_channels = {}

    c = conn.cursor()
    for node_pkey, classification in progressbar_utils.progressbar(
            c.execute("""
SELECT pkey, classification FROM node WHERE classification != ?;
""", (NodeClassification.CHANNEL.value, ))):
        reason = NodeClassification(classification)

        for (tile_type, tile_name, wire) in \
            yield_tiles_and_wires_for_node(conn, node_pkey):

            key = (tile_name, wire)

            assert key not in wires_not_in_channels, key
            wires_not_in_channels[key] = reason

            if key in wires_in_tiles:
                wires_in_tiles.remove(key)

    return wires_not_in_channels


def create_models_from_tracks(conn, wires_in_tiles, wires_not_in_channels):

    # List of nodes that are channels.
    channel_nodes = []

    # Map of (tile, wire) to track.  This will be used to find channels for pips
    # that come from EDGES_TO_CHANNEL.
    channel_wires_to_tracks = {}

    c = conn.cursor()
    for node_pkey, track_pkey in progressbar_utils.progressbar(c.execute(
            """
SELECT pkey, track_pkey FROM node WHERE classification = ?;
""", (NodeClassification.CHANNEL.value, ))):
        assert track_pkey is not None

        tracks_model, _ = get_track_model(conn, track_pkey)
        channel_nodes.append(tracks_model)
        channel_wires_to_tracks[track_pkey] = tracks_model

        for (tile_type, tile_name, wire) in \
            yield_tiles_and_wires_for_node(conn, node_pkey):

            key = (tile_name, wire)

            # Make sure all wires in channels always are in channels
            assert key not in wires_not_in_channels

            if key in wires_in_tiles:
                wires_in_tiles.remove(key)

    # Make sure all wires appear to have been assigned.
    if len(wires_in_tiles) > 0:
        for tile_name, wire in sorted(wires_in_tile_types):
            print(tile_name, wire)

    assert len(wires_in_tiles) == 0

    # Verify that all tracks are sane.
    for node in channel_nodes:
        node.verify_tracks()

    return channel_nodes, channel_wires_to_tracks

# =============================================================================


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        '--db_root',
        help='Project U-Ray Database',
        required=True
    )
    parser.add_argument(
        '--part',
        help='FPGA part',
        required=True)
    parser.add_argument(
        '--connection_database',
        help='Database of fabric connectivity',
        required=True
    )
    parser.add_argument(
        '--pin_assignments',
        help="""
Output JSON assigning pins to tile types and direction connections""",
        required=True
    )

    args = parser.parse_args()

    db = prjuray.db.Database(args.db_root, args.part)

    with DatabaseCache(args.connection_database, read_only=True) as conn:

        edge_assignments = {}

        print('{} Initializing edge assignments.'.format(now()))
        edge_assignments, wires_in_tiles = initialize_edge_assignments(
            db, conn
        )

        direct_connections = set()
        print('{} Processing direct connections.'.format(now()))
        handle_direction_connections(
            conn, direct_connections, edge_assignments
        )

        print('{} Processing non-channel nodes.'.format(now()))
        wires_not_in_channels = process_non_channel_nodes(conn, wires_in_tiles)

        # Generate track models and verify that wires are either in a channel
        # or not in a channel.
        print('{} Creating models from tracks.'.format(now()))
        channel_nodes, channel_wires_to_tracks = create_models_from_tracks(
            conn, wires_in_tiles, wires_not_in_channels
        )

        # Verify that all nodes that are classified as edges to channels have at
        # least one site, and at least one live connection to a channel.
        #
        # If no live connections from the node are present, this node should've
        # been marked as NULL during channel formation.
        null_tile_wires = set()
        print('{} Handling edges to channels.'.format(now()))
        handle_edges_to_channels(
            conn, null_tile_wires, edge_assignments, channel_wires_to_tracks
        )

        print('{} Processing edge assignments.'.format(now()))
        pin_directions = process_edge_assignments(edge_assignments, null_tile_wires)

        # Save
        with open(args.pin_assignments, 'w') as f:
            json.dump(
                {
                    'pin_directions':
                        pin_directions,
                    'direct_connections':
                        [d._asdict() for d in direct_connections],
                },
                f,
                indent=2
            )

        print(
            '{} Flushing database back to file "{}"'.format(
                now(), args.connection_database
            )
        )


if __name__ == '__main__':
    main()
