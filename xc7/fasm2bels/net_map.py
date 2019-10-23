""" Utilities for match VPR route names with xc7 site pin sources. """
from collections import namedtuple
from lib.parse_route import find_net_sources
import re


class Net(namedtuple('Net', 'name wire_pkey tile site_pin')):
    """
    Args:
        name (str): VPR net name
        wire_pkey (int): Wire table primary key.  This is unique in the part.
        tile (str): Name of tile this wire belongs too.  This is redundant
            information wire_pkey uniquely indentifies the tile.
        site_pin (str): Name of site pin this wire belongs. This is redundant
            information wire_pkey uniquely indentifies the site pin.
    """
    pass


# CLBLL_L.CLBLL_LL_A1[0] -> (CLBLL_L, CLBLL_LL_A1)
PIN_NAME_TO_PARTS = re.compile(r'^([^\.]+)\.([^\]]+)\[0\]$')


def create_net_list(conn, graph, route_file):
    """ From connection database, rrgraph and VPR route file, yields net_map.Net.
    """
    c = conn.cursor()

    for net, node in find_net_sources(route_file):
        graph_node = graph.nodes[node.inode]
        assert graph_node.id == node.inode
        assert graph_node.loc.x_low == node.x_low
        assert graph_node.loc.x_high == node.x_high
        assert graph_node.loc.y_low == node.y_low
        assert graph_node.loc.y_high == node.y_high

        gridloc = graph.loc_map[(node.x_low, node.y_low)]
        pin_name = graph.pin_ptc_to_name_map[(gridloc.block_type_id, node.ptc)]

        # Do not add synthetic nets to map.
        if pin_name.startswith('SYN-'):
            continue

        m = PIN_NAME_TO_PARTS.match(pin_name)
        assert m is not None, pin_name

        pin = m.group(2)

        c.execute(
            """
        SELECT site_as_tile_pkey, phy_tile_pkey FROM tile WHERE grid_x = ? AND grid_y = ?
        """, (node.x_low, node.y_low)
        )
        site_as_tile_pkey, phy_tile_pkey = c.fetchone()

        if site_as_tile_pkey is None:
            c.execute(
                """
WITH tiles(phy_tile_pkey, tile_name, tile_type_pkey) AS (
    SELECT DISTINCT pkey, name, tile_type_pkey FROM phy_tile
    WHERE pkey IN (
        SELECT phy_tile_pkey FROM tile_map WHERE tile_pkey = (
            SELECT pkey FROM tile WHERE grid_x = ? AND grid_y = ?
        )
    )
)
SELECT wire_in_tile.pkey, tiles.phy_tile_pkey, tiles.tile_name
FROM wire_in_tile
INNER JOIN tiles
ON tiles.tile_type_pkey = wire_in_tile.phy_tile_type_pkey
WHERE
    name = ?;""", (node.x_low, node.y_low, pin)
            )
            results = c.fetchall()
            assert len(results) == 1, (node, pin)
            wire_in_tile_pkey, phy_tile_pkey, tile_name = results[0]
        else:
            c.execute(
                "SELECT tile_type_pkey, name FROM phy_tile WHERE pkey = ?",
                (phy_tile_pkey, )
            )
            phy_tile_type_pkey, tile_name = c.fetchone()

            c.execute(
                "SELECT site_pkey FROM site_as_tile WHERE pkey = ?",
                (site_as_tile_pkey, )
            )
            site_pkey = c.fetchone()[0]

            c.execute(
                """
              SELECT pkey FROM site_pin WHERE name = ? AND site_type_pkey = (
                SELECT site_type_pkey FROM site WHERE pkey = ?
              );""", (
                    pin,
                    site_pkey,
                )
            )
            site_pin_pkey = c.fetchone()[0]

            c.execute(
                """
            SELECT pkey
            FROM wire_in_tile
            WHERE
                site_pkey = ?
            AND
                site_pin_pkey = ?
            AND
                phy_tile_type_pkey = ?""", (
                    site_pkey,
                    site_pin_pkey,
                    phy_tile_type_pkey,
                )
            )
            wire_in_tile_pkey = c.fetchone()[0]

        c.execute(
            "SELECT pkey FROM wire WHERE wire_in_tile_pkey = ? AND phy_tile_pkey = ?",
            (wire_in_tile_pkey, phy_tile_pkey)
        )
        wire_pkey = c.fetchone()[0]

        yield Net(name=net, wire_pkey=wire_pkey, tile=tile_name, site_pin=pin)
