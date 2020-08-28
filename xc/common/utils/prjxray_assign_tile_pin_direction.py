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
import prjxray.db

from prjxray_db_cache import DatabaseCache

from assign_tile_pin_direction import assign_tile_pin_direction

now = datetime.datetime.now

# =============================================================================


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        '--db_root',
        help='Project X-Ray Database',
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

    db = prjxray.db.Database(args.db_root, args.part)

    with DatabaseCache(args.connection_database, read_only=True) as conn:

        pin_directions, direct_connections = assign_tile_pin_direction(db, conn)

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
