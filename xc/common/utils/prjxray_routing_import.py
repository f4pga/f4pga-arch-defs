#!/usr/bin/env python3
""" Imports 7-series routing fabric to the rr graph.

For ROI configurations, this also connects the synthetic IO tiles to the routing
node specified.

Rough structure:

Add rr_nodes for CHANX and CHANY from the database.  IPIN and OPIN rr_nodes
should already be present from the input rr_graph.

Create a mapping between database graph_nodes and IPIN, OPIN, CHANX and CHANY
rr_node ids in the rr_graph.

Add rr_edge for each row in the graph_edge table.

Import channel XML node from connection database and serialize output to
rr_graph XML.

"""

import argparse
import os.path
from hilbertcurve.hilbertcurve import HilbertCurve
import math
import prjxray.db
from prjxray.roi import Roi
import prjxray.grid as grid
from lib.rr_graph import graph2
from lib.rr_graph import tracks
from lib.connection_database import get_wire_pkey, get_track_model
import lib.rr_graph_capnp.graph2 as capnp_graph2
from prjxray_constant_site_pins import feature_when_routed
from prjxray_tile_import import remove_vpr_tile_prefix
import simplejson as json
from lib import progressbar_utils
import datetime
import re
import functools
import pickle

import sqlite3

now = datetime.datetime.now

HCLK_CK_BUFHCLK_REGEX = re.compile('HCLK_CK_BUFHCLK[0-9]+')
CLK_HROW_CK_MUX_REGEX = re.compile('CLK_HROW_CK_MUX_OUT_([LR])([0-9]+)')
CASCOUT_REGEX = re.compile('BRAM_CASCOUT_ADDR((?:BWR)|(?:ARD))ADDRU([0-9]+)')
CONNECTION_BOX_FILTER = re.compile('([^0-9]+)[0-9]*')
BUFG_CLK_IN_REGEX = re.compile('CLK_HROW_CK_IN_[LR][0-9]+')
BUFG_CLK_OUT_REGEX = re.compile('CLK_HROW_R_CK_GCLK[0-9]+')
CCIO_ACTIVE_REGEX = re.compile('HCLK_CMT_CCIO[0-9]+')
HCLK_OUT = re.compile('CLK_HROW_CK_HCLK_OUT_([LR])([0-9]+)')
IOI_OCLK = re.compile('IOI_OCLK_([01])')

# Regex for [LR]IOI_SING tiles
IOI_SITE_PIPS = ['OLOGIC', 'ILOGIC', 'IDELAY', 'OCLK_', 'OCLKM_']
IOI_SING_REGEX = re.compile(
    r'([RL]IOI3_SING_X[0-9]+Y)([0-9]+)(\.IOI_)({})([01])(.*)'.format(
        "|".join(IOI_SITE_PIPS)
    )
)


def reduce_connection_box(box):
    """ Reduce the number of connection boxes by merging some.

    Examples:

    >>> reduce_connection_box('IMUX0')
    'IMUX'
    >>> reduce_connection_box('IMUX1')
    'IMUX'
    >>> reduce_connection_box('IMUX10')
    'IMUX'
    >>> reduce_connection_box('BRAM_ADDR')
    'IMUX'
    >>> reduce_connection_box('A_L10')
    'A'
    >>> reduce_connection_box('B')
    'B'
    >>> reduce_connection_box('B_L')
    'B'

    """

    box = CONNECTION_BOX_FILTER.match(box).group(1)

    if 'BRAM_ADDR' in box:
        box = 'IMUX'

    if box.endswith('_L'):
        box = box.replace('_L', '')

    return box


REBUF_NODES = {}
REBUF_SOURCES = {}


def get_clk_hrow_and_rebuf_tiles_sorted(cur):
    """
    Finds all CLK_HROW_TOP_R, CLK_HROW_BOT_T and REBUF tiles.
    returns them in a list sorted according to their Y coordinates.
    """

    cur.execute(
        """
SELECT name
FROM phy_tile
WHERE
  name LIKE "CLK_HROW_BOT_R_%"
OR
  name LIKE "CLK_HROW_TOP_R_%"
OR
  name LIKE "CLK_BUFG_REBUF_%"
ORDER BY grid_y DESC;
    """
    )

    return [t[0] for t in cur.fetchall()]


def populate_bufg_rebuf_map(conn):
    global REBUF_NODES
    REBUF_NODES = {}

    global REBUF_SOURCES
    REBUF_SOURCES = {}

    rebuf_wire_regexp = re.compile(
        'CLK_BUFG_REBUF_R_CK_GCLK([0-9]+)_(BOT|TOP)'
    )

    cur = conn.cursor()

    # Find CLK_HROW_TOP_R, CLK_HROW_TOP_R and REBUF tiles.
    rebuf_and_hrow_tiles = get_clk_hrow_and_rebuf_tiles_sorted(cur)
    # Append None on both ends of the list to simplify the code below.
    rebuf_and_hrow_tiles = [None] + rebuf_and_hrow_tiles + [None]

    def maybe_get_clk_hrow(i):
        """
        Returns a name of CLK_HROW tile only if its there on the list.
        """
        tile = rebuf_and_hrow_tiles[i]
        if tile is not None and tile.startswith("CLK_HROW"):
            return tile
        return None

    # Assign each REBUF tile its above and below CLK_HROW tile. Note that in
    # VPR coords terms. "above" and "below" mean the opposite...
    rebuf_to_hrow_map = {}
    for i, tile_name in enumerate(rebuf_and_hrow_tiles):
        if tile_name is not None and tile_name.startswith("CLK_BUFG_REBUF"):

            rebuf_to_hrow_map[tile_name] = {
                "above": maybe_get_clk_hrow(i - 1),
                "below": maybe_get_clk_hrow(i + 1),
            }

    # Find nodes touching rebuf wires.
    cur.execute(
        """
WITH
  rebuf_wires(wire_in_tile_pkey) AS (
    SELECT pkey
      FROM wire_in_tile
      WHERE
        name LIKE "CLK_BUFG_REBUF_R_CK_GCLK%_BOT"
      OR
        name LIKE "CLK_BUFG_REBUF_R_CK_GCLK%_TOP"
),
  rebuf_nodes(node_pkey) AS (
    SELECT DISTINCT node_pkey
    FROM wire
    WHERE wire_in_tile_pkey IN (SELECT wire_in_tile_pkey FROM rebuf_wires)
)
SELECT rebuf_nodes.node_pkey, phy_tile.name, wire_in_tile.name
FROM rebuf_nodes
INNER JOIN wire ON wire.node_pkey = rebuf_nodes.node_pkey
INNER JOIN wire_in_tile ON wire_in_tile.pkey = wire.wire_in_tile_pkey
INNER JOIN phy_tile ON phy_tile.pkey = wire.phy_tile_pkey
WHERE wire.wire_in_tile_pkey IN (SELECT wire_in_tile_pkey FROM rebuf_wires)
ORDER BY rebuf_nodes.node_pkey;"""
    )

    for node_pkey, rebuf_tile, rebuf_wire_name in cur:
        if node_pkey not in REBUF_NODES:
            REBUF_NODES[node_pkey] = []

        m = rebuf_wire_regexp.fullmatch(rebuf_wire_name)

        if m.group(2) == 'TOP':
            REBUF_NODES[node_pkey].append(
                '{}.GCLK{}_ENABLE_BELOW'.format(rebuf_tile, m.group(1))
            )

            hrow_tile = rebuf_to_hrow_map[rebuf_tile]["below"]
            if hrow_tile is not None:
                REBUF_NODES[node_pkey].append(
                    "{}.CLK_HROW_R_CK_GCLK{}_ACTIVE".format(
                        hrow_tile, m.group(1)
                    )
                )

        elif m.group(2) == 'BOT':
            REBUF_NODES[node_pkey].append(
                '{}.GCLK{}_ENABLE_ABOVE'.format(rebuf_tile, m.group(1))
            )

            hrow_tile = rebuf_to_hrow_map[rebuf_tile]["above"]
            if hrow_tile is not None:
                REBUF_NODES[node_pkey].append(
                    "{}.CLK_HROW_R_CK_GCLK{}_ACTIVE".format(
                        hrow_tile, m.group(1)
                    )
                )

        else:
            assert False, (rebuf_tile, rebuf_wire_name)

    for node_pkey in REBUF_NODES:
        cur.execute(
            """
SELECT phy_tile.name, wire_in_tile.name
FROM wire
INNER JOIN phy_tile ON phy_tile.pkey = wire.phy_tile_pkey
INNER JOIN wire_in_tile ON wire_in_tile.pkey = wire.wire_in_tile_pkey
WHERE wire.node_pkey = ?;""", (node_pkey, )
        )

        for tile, wire_name in cur:
            REBUF_SOURCES[(tile, wire_name)] = node_pkey


HCLK_CMT_TILES = {}


def populate_hclk_cmt_tiles(db):
    global HCLK_CMT_TILES
    HCLK_CMT_TILES = {}

    grid = db.grid()
    _, x_max, _, _ = grid.dims()

    for tile in grid.tiles():
        gridinfo = grid.gridinfo_at_tilename(tile)

        if gridinfo.tile_type not in ['CLK_HROW_BOT_R', 'CLK_HROW_TOP_R']:
            continue

        hclk_x, hclk_y = grid.loc_of_tilename(tile)

        hclk_cmt_x = hclk_x
        hclk_cmt_y = hclk_y

        while hclk_cmt_x > 0:
            hclk_cmt_x -= 1
            gridinfo = grid.gridinfo_at_loc((hclk_cmt_x, hclk_cmt_y))

            if gridinfo.tile_type == 'HCLK_CMT':
                HCLK_CMT_TILES[tile, 'L'] = grid.tilename_at_loc(
                    (hclk_cmt_x, hclk_cmt_y)
                )
                break

        hclk_cmt_x = hclk_x

        while hclk_cmt_x < x_max:
            hclk_cmt_x += 1

            gridinfo = grid.gridinfo_at_loc((hclk_cmt_x, hclk_cmt_y))

            if gridinfo.tile_type == 'HCLK_CMT_L':
                HCLK_CMT_TILES[tile, 'R'] = grid.tilename_at_loc(
                    (hclk_cmt_x, hclk_cmt_y)
                )
                break


def find_hclk_cmt_hclk_feature(hclk_tile, lr, hclk_number):
    if (hclk_tile, lr) not in HCLK_CMT_TILES:
        return []

    hclk_cmt_tile = HCLK_CMT_TILES[(hclk_tile, lr)]

    return ['{}.HCLK_CMT_CK_BUFHCLK{}_USED'.format(hclk_cmt_tile, hclk_number)]


def check_feature(feature):
    """ Check if enabling this feature requires other features to be enabled.

    Some pips imply other features.  Example:

    .HCLK_LEAF_CLK_B_BOTL0.HCLK_CK_BUFHCLK10
    implies:
    .ENABLE_BUFFER.HCLK_CK_BUFHCLK10
    """

    # IOI_SING tiles have bits in common with the IOI tiles.
    #
    # The difference is that the TOP IOI_SING tile shares bits with
    # the bottom half of a normal IOI tile, while the BOTTOM IOI_SING
    # shares bits with the top half of a normal IOI TILE.
    #
    # The following, is to change the edge feature to accomodate this
    # need, as the IOI_SING tiles have the same wire, and pip names
    # despite they are found on the TOP or BOTTOM of an IOI column
    m = IOI_SING_REGEX.fullmatch(feature)
    if m:
        # Each clock region spans a total of 50 IOBs.
        # The IOI_SING are found on top or bottom of the whole
        # IOI/IOB column. The Y coordinate identified with the
        # second capture group is dived by 50 to get the relative
        # position of the IOI_SING within the clock region column
        is_bottom_sing = int(m.group(2)) % 50 == 0

        # This is the value to attach to the source pip name that
        # changes based on which IOI_SING is selected (top or bottom)
        #
        # Example: IOI_OLOGIC0_D1.IOI_IMUX34_0 -> IOI_OLOGIC0_D1.IOI_IMUX34_1
        src_value = '1' if is_bottom_sing else '0'

        # This is the value to attach to the IOI_SITE_PIPS names
        # in the destination wire of the pip
        #
        # Example: IOI_OLOGIC0 -> IOI_OLOGIC1
        dst_value = '0' if is_bottom_sing else '1'

        unchanged_feature = "{}{}{}{}".format(
            m.group(1), m.group(2), m.group(3), m.group(4)
        )

        src_wire = m.group(6).replace('_SING', '')

        for pip in ['IMUX', 'LOGIC_OUTS', 'CTRL', 'FAN', 'BYP']:
            if pip in src_wire:
                src_wire = src_wire.replace('_0', '_{}'.format(src_value))

        if 'IOI_OCLK' in src_wire:
            src_wire = src_wire.replace('_0', '_{}'.format(dst_value))

        changed_feature = "{}{}".format(dst_value, src_wire)
        feature = "{}{}".format(unchanged_feature, changed_feature)

    feature_path = feature.split('.')

    # IOB_DIFFO_OUT0->IOB_DIFFO_IN1
    #
    # When this PIP is active the IOB operates in the differential output mode.
    # There is no feature assosciated with that PIP in the prjxray db but there
    # is a tile-wide feature named "DIFF_OUT".
    #
    # The "DIFF_OUT" cannot be set in the architecture as it is defined one
    # level up in the hierarchy (its tile-wide, not site-wide). So here we
    # map the PIP's feature to "DIFF_OUT"
    if feature_path[2] == "IOB_DIFFO_OUT0" and \
       feature_path[1] == "IOB_DIFFO_IN1":
        return '{}.OUT_DIFF'.format(feature_path[0])

    # IOB_PADOUT0->IOB_DIFFI_IN1
    # IOB_PADOUT1->IOB_DIFFI_IN0
    #
    # These connections are hard wires that connect IOB33M and IOB33S sites.
    # They are used in differential input mode.
    #
    # Vivado does not report this connection as a PIP but in the prjxray db it
    # is a pip. Instead of making it a pseudo-pip we simply reject fasm
    # features here.
    if feature_path[2] == "IOB_PADOUT0" and feature_path[1] == "IOB_DIFFI_IN1":
        return ''
    if feature_path[2] == "IOB_PADOUT1" and feature_path[1] == "IOB_DIFFI_IN0":
        return ''

    # REBUF stuff
    rebuf_key = (feature_path[0], feature_path[1])
    if rebuf_key in REBUF_SOURCES:
        return ' '.join([feature] + REBUF_NODES[REBUF_SOURCES[rebuf_key]])

    m = IOI_OCLK.fullmatch(feature_path[1])
    if m:
        enable_oclkm_feature = '{}.IOI_OCLKM_{}.{}'.format(
            feature_path[0], m.group(1), feature_path[-1]
        )

        return ' '.join((feature, enable_oclkm_feature))

    if HCLK_CK_BUFHCLK_REGEX.fullmatch(feature_path[-1]):
        enable_buffer_feature = '{}.ENABLE_BUFFER.{}'.format(
            feature_path[0], feature_path[-1]
        )

        return ' '.join((feature, enable_buffer_feature))

    # BUFHCE sites are now routed through, without the need of placing them, therefore,
    # when the relative pip is traversed, the correct fasm feature needs to be added.
    # The relevant features are:
    #    - IN_USE: to enable the BUFHCE site
    #    - ZINV_CE: to disable the inverter on CE input which is connected to VCC.
    #               This sets the CE signal to constant 1
    m = CLK_HROW_CK_MUX_REGEX.fullmatch(feature_path[-1])
    if m:
        x_loc_str = m.group(1)
        if 'L' in x_loc_str:
            x_loc = 0
        elif 'R' in x_loc_str:
            x_loc = 1
        else:
            assert False, "Impossible to determine X location of BUFHCE"

        y_loc = m.group(2)
        bufhce_loc = 'BUFHCE_X{}Y{}'.format(x_loc, y_loc)

        enable_bufhce_in_use = '{}.BUFHCE.{}.IN_USE'.format(
            feature_path[0], bufhce_loc
        )
        enable_bufhce_zinv_ce = '{}.BUFHCE.{}.ZINV_CE=1\'b1'.format(
            feature_path[0], bufhce_loc
        )

        return ' '.join((feature, enable_bufhce_in_use, enable_bufhce_zinv_ce))

    if BUFG_CLK_IN_REGEX.fullmatch(feature_path[-1]):
        enable_feature = '{}.{}_ACTIVE'.format(
            feature_path[0], feature_path[-1]
        )

        return ' '.join((feature, enable_feature))

    if BUFG_CLK_OUT_REGEX.fullmatch(feature_path[-1]):
        enable_feature = '{}.{}_ACTIVE'.format(
            feature_path[0], feature_path[-1]
        )

        return ' '.join((feature, enable_feature))

    if CCIO_ACTIVE_REGEX.fullmatch(feature_path[-1]):
        features = [feature]
        features.append(
            '{}.{}_ACTIVE'.format(feature_path[0], feature_path[-1])
        )
        features.append('{}.{}_USED'.format(feature_path[0], feature_path[-1]))

        return ' '.join(features)

    m = HCLK_OUT.fullmatch(feature_path[-1])
    if m:
        return ' '.join(
            [feature] + find_hclk_cmt_hclk_feature(
                feature_path[0], m.group(1), m.group(2)
            )
        )

    m = CASCOUT_REGEX.fullmatch(feature_path[-2])
    if m:
        enable_cascout = '{}.CASCOUT_{}_ACTIVE'.format(
            feature_path[0], m.group(1)
        )

        return ' '.join((feature, enable_cascout))

    parts = feature.split('.')

    wire_feature = feature_when_routed(parts[1])
    if wire_feature is not None:
        return '{} {}.{}'.format(feature, parts[0], wire_feature)

    return feature


# CLBLL_L.CLBLL_LL_A1[0] -> (CLBLL_L, CLBLL_LL_A1)
PIN_NAME_TO_PARTS = re.compile(r'^([^\.]+)\.([^\]]+)\[0\]$')


def set_connection_box(
        graph, node_idx, grid_x, grid_y, box_id, site_pin_delay
):
    """ Assign a connection box to an IPIN node. """
    node_dict = graph.nodes[node_idx]._asdict()
    node_dict['connection_box'] = graph2.ConnectionBox(
        x=grid_x,
        y=grid_y,
        id=box_id,
        site_pin_delay=site_pin_delay,
    )
    graph.nodes[node_idx] = graph2.Node(**node_dict)


def update_connection_box(
        conn, graph, graph_node_pkey, node_idx, connection_box_map
):
    """ Update connection box of IPIN node if needed. """
    cur = conn.cursor()

    cur.execute(
        """
SELECT connection_box_wire_pkey
FROM graph_node WHERE pkey = ?""", (graph_node_pkey, )
    )

    connection_box_wire_pkey = cur.fetchone()[0]
    if connection_box_wire_pkey is not None:
        cur.execute(
            """
SELECT grid_x, grid_y FROM phy_tile WHERE pkey = (
    SELECT phy_tile_pkey FROM wire WHERE pkey = ?
    )""", (connection_box_wire_pkey, )
        )
        grid_x, grid_y = cur.fetchone()

        cur.execute(
            "SELECT wire_in_tile_pkey FROM wire WHERE pkey = ?",
            (connection_box_wire_pkey, )
        )
        wire_in_tile_pkey = cur.fetchone()[0]
        box_id = connection_box_map[wire_in_tile_pkey]

        cur.execute(
            """
SELECT switch.intrinsic_delay
FROM switch
WHERE pkey = (
    SELECT site_pin_switch_pkey
    FROM wire_in_tile
    WHERE pkey = (
        SELECT wire_in_tile_pkey
        FROM wire
        WHERE pkey = (
            SELECT site_wire_pkey
            FROM node
            WHERE pkey = (
                SELECT node_pkey
                FROM graph_node
                WHERE pkey = ?
            )
        )
    )
)""", (graph_node_pkey, )
        )
        site_pin_delay = cur.fetchone()[0]

        set_connection_box(
            graph, node_idx, grid_x, grid_y, box_id, site_pin_delay
        )


def create_get_tile_and_site_as_tile_pkey(cur):
    tiles = {}

    for tile_pkey, site_as_tile_pkey, grid_x, grid_y in cur.execute("""
SELECT pkey, site_as_tile_pkey, grid_x, grid_y FROM tile;"""):
        tiles[(grid_x, grid_y)] = (tile_pkey, site_as_tile_pkey)

    def get_tile_and_site_as_tile_pkey(x, y):
        return tiles[(x, y)]

    return get_tile_and_site_as_tile_pkey


def create_get_site_as_tile_wire(cur):
    @functools.lru_cache(maxsize=0)
    def get_site_from_site_as_tile(site_as_tile_pkey):
        cur.execute(
            """
        SELECT site.site_type_pkey, site_as_tile.site_pkey
        FROM site_as_tile
        INNER JOIN site ON site.pkey = site_as_tile.site_pkey
        WHERE site_as_tile.pkey = ?""", (site_as_tile_pkey, )
        )

        results = cur.fetchall()
        assert len(results) == 1, site_as_tile_pkey
        return results[0]

    @functools.lru_cache(maxsize=0)
    def get_site_as_tile_wire(site_as_tile_pkey, pin):
        site_type_pkey, site_pkey = get_site_from_site_as_tile(
            site_as_tile_pkey
        )
        cur.execute(
            """
SELECT
  pkey
FROM
  wire_in_tile
WHERE
  site_pin_pkey = (
    SELECT
      pkey
    FROM
      site_pin
    WHERE
      site_type_pkey = ?
      AND name = ?
  )
AND
  site_pkey = ?
  ;""", (site_type_pkey, pin, site_pkey)
        )
        results = cur.fetchall()
        assert len(results) == 1
        wire_in_tile_pkey = results[0][0]

        return wire_in_tile_pkey

    return get_site_as_tile_wire


def import_graph_nodes(conn, graph, node_mapping, connection_box_map):
    cur = conn.cursor()

    get_tile_and_site_as_tile_pkey = create_get_tile_and_site_as_tile_pkey(cur)
    get_site_as_tile_wire = create_get_site_as_tile_wire(cur)

    for node_idx, node in enumerate(graph.nodes):
        if node.type not in (graph2.NodeType.IPIN, graph2.NodeType.OPIN):
            continue

        gridloc = graph.loc_map[(node.loc.x_low, node.loc.y_low)]
        pin_name = graph.pin_ptc_to_name_map[
            (gridloc.block_type_id, node.loc.ptc)]

        # Synthetic blocks are handled below.
        if pin_name.startswith('SYN-'):
            set_connection_box(
                graph,
                node_idx,
                node.loc.x_low,
                node.loc.y_low,
                box_id=graph.maybe_add_connection_box('IMUX'),
                site_pin_delay=0.,
            )
            continue

        m = PIN_NAME_TO_PARTS.match(pin_name)
        assert m is not None, pin_name

        tile_type = m.group(1)
        tile_type = remove_vpr_tile_prefix(tile_type)

        pin = m.group(2)

        tile_pkey, site_as_tile_pkey = get_tile_and_site_as_tile_pkey(
            node.loc.x_low, node.loc.y_low
        )

        if site_as_tile_pkey is not None:
            wire_in_tile_pkey = get_site_as_tile_wire(site_as_tile_pkey, pin)
        else:
            cur.execute(
                """
SELECT
  pkey
FROM
  wire_in_tile
WHERE
  name = ?
AND
  phy_tile_type_pkey IN (
    SELECT tile_type_pkey FROM phy_tile WHERE pkey IN (
        SELECT phy_tile_pkey FROM tile_map WHERE tile_pkey = ?
        )
    );""", (pin, tile_pkey)
            )
            results = cur.fetchall()
            assert len(results) == 1
            wire_in_tile_pkey = results[0][0]

        tile_pkey, _ = get_tile_and_site_as_tile_pkey(gridloc[0], gridloc[1])

        cur.execute(
            """
        SELECT
            top_graph_node_pkey, bottom_graph_node_pkey,
            left_graph_node_pkey, right_graph_node_pkey FROM wire
            WHERE
              wire_in_tile_pkey = ? AND tile_pkey = ?;""",
            (wire_in_tile_pkey, tile_pkey)
        )

        result = cur.fetchone()
        assert result is not None, (wire_in_tile_pkey, tile_pkey)
        (
            top_graph_node_pkey, bottom_graph_node_pkey, left_graph_node_pkey,
            right_graph_node_pkey
        ) = result

        side = node.loc.side
        if side == tracks.Direction.LEFT:
            assert left_graph_node_pkey is not None, (tile_type, pin_name)
            node_mapping[left_graph_node_pkey] = node.id

            update_connection_box(
                conn, graph, left_graph_node_pkey, node_idx, connection_box_map
            )
        elif side == tracks.Direction.RIGHT:
            assert right_graph_node_pkey is not None, (tile_type, pin_name)
            node_mapping[right_graph_node_pkey] = node.id

            update_connection_box(
                conn, graph, right_graph_node_pkey, node_idx,
                connection_box_map
            )
        elif side == tracks.Direction.TOP:
            assert top_graph_node_pkey is not None, (tile_type, pin_name)
            node_mapping[top_graph_node_pkey] = node.id

            update_connection_box(
                conn, graph, top_graph_node_pkey, node_idx, connection_box_map
            )
        elif side == tracks.Direction.BOTTOM:
            assert bottom_graph_node_pkey is not None, (tile_type, pin_name)
            node_mapping[bottom_graph_node_pkey] = node.id

            update_connection_box(
                conn, graph, bottom_graph_node_pkey, node_idx,
                connection_box_map
            )
        else:
            assert False, side


def import_tracks(conn, alive_tracks, node_mapping, graph, default_segment_id):
    cur = conn.cursor()
    cur2 = conn.cursor()
    for (graph_node_pkey, track_pkey, graph_node_type, x_low, x_high, y_low,
         y_high, ptc, capacitance,
         resistance) in progressbar_utils.progressbar(cur.execute("""
SELECT
    pkey,
    track_pkey,
    graph_node_type,
    x_low,
    x_high,
    y_low,
    y_high,
    ptc,
    capacitance,
    resistance
FROM
    graph_node WHERE track_pkey IS NOT NULL;""")):
        if track_pkey not in alive_tracks:
            continue

        cur2.execute(
            """
SELECT name FROM segment WHERE pkey = (
    SELECT segment_pkey FROM track WHERE pkey = ?
)""", (track_pkey, )
        )
        result = cur2.fetchone()
        if result is not None:
            segment_name = result[0]
            segment_id = graph.get_segment_id_from_name(segment_name)
        else:
            segment_id = default_segment_id

        node_type = graph2.NodeType(graph_node_type)

        if node_type == graph2.NodeType.CHANX:
            direction = 'X'
            x_low = max(x_low, 1)
        elif node_type == graph2.NodeType.CHANY:
            direction = 'Y'
            y_low = max(y_low, 1)
        else:
            assert False, node_type

        canonical_loc = None
        cur2.execute(
            """
SELECT grid_x, grid_y FROM phy_tile WHERE pkey = (
    SELECT canon_phy_tile_pkey FROM track WHERE pkey = ?
    )""", (track_pkey, )
        )
        result = cur2.fetchone()
        if result:
            canonical_loc = graph2.CanonicalLoc(x=result[0], y=result[1])

        track = tracks.Track(
            direction=direction,
            x_low=x_low,
            x_high=x_high,
            y_low=y_low,
            y_high=y_high,
        )
        assert graph_node_pkey not in node_mapping
        node_mapping[graph_node_pkey] = graph.add_track(
            track=track,
            segment_id=segment_id,
            ptc=ptc,
            timing=graph2.NodeTiming(
                r=resistance,
                c=capacitance,
            ),
            canonical_loc=canonical_loc
        )


def create_track_rr_graph(
        conn, graph, node_mapping, use_roi, roi, synth_tiles, segment_id
):
    cur = conn.cursor()
    cur.execute("""SELECT count(*) FROM track;""")
    (num_channels, ) = cur.fetchone()

    print('{} Import alive tracks'.format(now()))
    alive_tracks = set()
    for (track_pkey,
         ) in cur.execute("SELECT pkey FROM track WHERE alive = 1;"):
        alive_tracks.add(track_pkey)

    print('{} Importing alive tracks'.format(now()))
    import_tracks(conn, alive_tracks, node_mapping, graph, segment_id)

    print('original {} final {}'.format(num_channels, len(alive_tracks)))


def add_synthetic_edges(conn, graph, node_mapping, grid, synth_tiles):
    cur = conn.cursor()
    delayless_switch = graph.get_switch_id('__vpr_delayless_switch__')

    for tile_name, synth_tile in synth_tiles['tiles'].items():
        input_num = 0
        output_num = 0
        for pin in synth_tile['pins']:
            if pin['port_type'] in ['input', 'output']:
                wire_pkey = get_wire_pkey(conn, tile_name, pin['wire'])
                cur.execute(
                    """
SELECT
  track_pkey
FROM
  node
WHERE
  pkey = (
    SELECT
      node_pkey
    FROM
      wire
    WHERE
      pkey = ?
  );""", (wire_pkey, )
                )
                (track_pkey, ) = cur.fetchone()
                assert track_pkey is not None, (
                    tile_name, pin['wire'], wire_pkey
                )
            elif pin['port_type'] == 'VCC':
                cur.execute('SELECT vcc_track_pkey FROM constant_sources')
                (track_pkey, ) = cur.fetchone()
            elif pin['port_type'] == 'GND':
                cur.execute('SELECT gnd_track_pkey FROM constant_sources')
                (track_pkey, ) = cur.fetchone()
            else:
                assert False, pin['port_type']
            tracks_model, track_nodes = get_track_model(conn, track_pkey)

            option = list(
                tracks_model.get_tracks_for_wire_at_coord(
                    tuple(synth_tile['loc'])
                ).values()
            )
            assert len(option) > 0, (pin, len(option))

            if pin['port_type'] == 'input':
                tile_type = 'SYN-IOPAD'
                sub_tile_num = input_num
                wire = 'outpad'
            elif pin['port_type'] == 'output':
                tile_type = 'SYN-IOPAD'
                sub_tile_num = output_num
                wire = 'inpad'
            elif pin['port_type'] == 'VCC':
                tile_type = 'SYN-VCC'
                wire = 'VCC'
            elif pin['port_type'] == 'GND':
                tile_type = 'SYN-GND'
                wire = 'GND'
            else:
                assert False, pin

            track_node = track_nodes[option[0]]
            assert track_node in node_mapping, (track_node, track_pkey)
            if pin['port_type'] in ['input', 'output']:
                if len(synth_tile['pins']) != 1:
                    pin_name = graph.create_pin_name_from_tile_type_sub_tile_num_and_pin(
                        tile_type, sub_tile_num, wire
                    )
                else:
                    pin_name = graph.create_pin_name_from_tile_type_and_pin(
                        tile_type, wire
                    )
            else:
                pin_name = graph.create_pin_name_from_tile_type_and_pin(
                    tile_type, wire
                )

            pin_node = graph.get_nodes_for_pin(
                tuple(synth_tile['loc']), pin_name
            )

            if pin['port_type'] == 'input':
                graph.add_edge(
                    src_node=node_mapping[track_node],
                    sink_node=pin_node[0][0],
                    switch_id=delayless_switch,
                    name='synth_{}_{}'.format(tile_name, pin['wire']),
                )
            elif pin['port_type'] in ['VCC', 'GND', 'output']:
                graph.add_edge(
                    src_node=pin_node[0][0],
                    sink_node=node_mapping[track_node],
                    switch_id=delayless_switch,
                    name='synth_{}_{}'.format(tile_name, pin['wire']),
                )
            else:
                assert False, pin


def get_switch_name(conn, graph, switch_name_map, switch_pkey):
    assert switch_pkey is not None
    if switch_pkey not in switch_name_map:
        cur = conn.cursor()
        cur.execute(
            """SELECT name FROM switch WHERE pkey = ?;""", (switch_pkey, )
        )
        (switch_name, ) = cur.fetchone()
        switch_id = graph.get_switch_id(switch_name)
        switch_name_map[switch_pkey] = switch_id
    else:
        switch_id = switch_name_map[switch_pkey]

    return switch_id


def create_get_tile_name(conn):
    cur = conn.cursor()

    @functools.lru_cache(maxsize=None)
    def get_tile_name(tile_pkey):
        cur.execute(
            """
        SELECT name FROM phy_tile WHERE pkey = ?;
        """, (tile_pkey, )
        )
        return cur.fetchone()[0]

    return get_tile_name


def create_get_pip_wire_names(conn):
    cur = conn.cursor()

    @functools.lru_cache(maxsize=None)
    def get_pip_wire_names(pip_pkey):
        cur.execute(
            """SELECT src_wire_in_tile_pkey, dest_wire_in_tile_pkey
            FROM pip_in_tile WHERE pkey = ?;""", (pip_pkey, )
        )
        src_wire_in_tile_pkey, dest_wire_in_tile_pkey = cur.fetchone()

        cur.execute(
            """SELECT name FROM wire_in_tile WHERE pkey = ?;""",
            (src_wire_in_tile_pkey, )
        )
        (src_net, ) = cur.fetchone()

        cur.execute(
            """SELECT name FROM wire_in_tile WHERE pkey = ?;""",
            (dest_wire_in_tile_pkey, )
        )
        (dest_net, ) = cur.fetchone()

        return (src_net, dest_net)

    return get_pip_wire_names


def get_number_graph_edges(conn, graph, node_mapping):
    num_edges = len(graph.edges)

    print('{} Counting edges.'.format(now()))
    cur = conn.cursor()
    cur.execute("SELECT count() FROM graph_edge;" "")

    for src_graph_node, dest_graph_node in cur.execute("""
SELECT
  src_graph_node_pkey,
  dest_graph_node_pkey
FROM
  graph_edge;
                """):
        if src_graph_node not in node_mapping:
            continue

        if dest_graph_node not in node_mapping:
            continue

        num_edges += 1

    return num_edges


def import_graph_edges(conn, graph, node_mapping):
    # First yield existing edges
    print('{} Importing existing edges.'.format(now()))
    for edge in graph.edges:
        yield (edge.src_node, edge.sink_node, edge.switch_id, None)

    # Then yield edges from database.
    cur = conn.cursor()

    cur.execute("SELECT count() FROM graph_edge;" "")
    (num_edges, ) = cur.fetchone()

    get_tile_name = create_get_tile_name(conn)
    get_pip_wire_names = create_get_pip_wire_names(conn)

    switch_name_map = {}

    print('{} Importing edges from database.'.format(now()))
    with progressbar_utils.ProgressBar(max_value=num_edges) as bar:
        for idx, (src_graph_node, dest_graph_node, switch_pkey, phy_tile_pkey,
                  pip_pkey, backward) in enumerate(cur.execute("""
SELECT
  src_graph_node_pkey,
  dest_graph_node_pkey,
  switch_pkey,
  phy_tile_pkey,
  pip_in_tile_pkey,
  backward
FROM
  graph_edge;
                """)):
            if src_graph_node not in node_mapping:
                continue

            if dest_graph_node not in node_mapping:
                continue

            if pip_pkey is not None:
                tile_name = get_tile_name(phy_tile_pkey)
                src_net, dest_net = get_pip_wire_names(pip_pkey)

                if not backward:
                    pip_name = '{}.{}.{}'.format(tile_name, dest_net, src_net)
                else:
                    pip_name = '{}.{}.{}'.format(tile_name, src_net, dest_net)
            else:
                pip_name = None

            switch_id = get_switch_name(
                conn, graph, switch_name_map, switch_pkey
            )

            src_node = node_mapping[src_graph_node]
            sink_node = node_mapping[dest_graph_node]

            if pip_name is not None:
                feature = check_feature(pip_name)
                if feature:
                    yield (
                        src_node, sink_node, switch_id,
                        (('fasm_features', feature), )
                    )
                else:
                    yield (src_node, sink_node, switch_id, ())
            else:
                yield (src_node, sink_node, switch_id, ())

            if idx % 1024 == 0:
                bar.update(idx)


def create_channels(conn):
    cur = conn.cursor()

    cur.execute(
        """
    SELECT chan_width_max, x_min, x_max, y_min, y_max FROM channel;"""
    )
    chan_width_max, x_min, x_max, y_min, y_max = cur.fetchone()

    cur.execute('SELECT idx, info FROM x_list;')
    x_list = []
    for idx, info in cur:
        x_list.append(graph2.ChannelList(idx, info))

    cur.execute('SELECT idx, info FROM y_list;')
    y_list = []
    for idx, info in cur:
        y_list.append(graph2.ChannelList(idx, info))

    return graph2.Channels(
        chan_width_max=chan_width_max,
        x_min=x_min,
        y_min=y_min,
        x_max=x_max,
        y_max=y_max,
        x_list=x_list,
        y_list=y_list,
    )


def create_connection_boxes(conn, graph):
    """ Assign connection box ids for all connection box types. """
    cur = conn.cursor()
    cur.execute(
        """
SELECT pkey, tile_type_pkey, name FROM wire_in_tile WHERE pkey IN (
    SELECT DISTINCT wire_in_tile_pkey FROM wire WHERE pkey IN (
        SELECT connection_box_wire_pkey FROM graph_node
        WHERE connection_box_wire_pkey IS NOT NULL
    )
);"""
    )

    connection_box_map = {}
    for wire_in_tile_pkey, tile_type_pkey, wire_name in cur:
        connection_box_map[wire_in_tile_pkey] = graph.maybe_add_connection_box(
            reduce_connection_box(wire_name)
        )

    return connection_box_map


def yield_nodes(nodes):
    with progressbar_utils.ProgressBar(max_value=len(nodes)) as bar:
        for idx, node in enumerate(nodes):
            yield node

            if idx % 1024 == 0:
                bar.update(idx)


def phy_grid_dims(conn):
    """ Returns physical grid dimensions. """
    cur = conn.cursor()
    cur.execute("SELECT grid_x FROM phy_tile ORDER BY grid_x DESC LIMIT 1;")
    x_max = cur.fetchone()[0]
    cur.execute("SELECT grid_y FROM phy_tile ORDER BY grid_y DESC LIMIT 1;")
    y_max = cur.fetchone()[0]

    return x_max + 1, y_max + 1


def find_constant_network(graph):
    """ Find VCC and GND tiles and create synth_tiles input.

    All arches should have these synthetic tiles, search the input rr graph
    for the SYN-GND and SYN-VCC tiles.

    """
    block_types = {}

    for block_type in graph.block_types:
        block_types[block_type.name] = block_type.id

    assert 'SYN-GND' in block_types
    assert 'SYN-VCC' in block_types

    gnd_block_id = block_types['SYN-GND']
    vcc_block_id = block_types['SYN-VCC']

    gnd_loc = None
    vcc_loc = None

    for grid_loc in graph.grid:
        if gnd_block_id == grid_loc.block_type_id:
            assert gnd_loc is None
            gnd_loc = (grid_loc.x, grid_loc.y)

        if vcc_block_id == grid_loc.block_type_id:
            assert vcc_loc is None
            vcc_loc = (grid_loc.x, grid_loc.y)

    assert gnd_loc is not None
    assert vcc_loc is not None

    synth_tiles = {
        'tiles':
            {
                "VCC":
                    {
                        'loc':
                            vcc_loc,
                        'pins':
                            [
                                {
                                    'wire': 'VCC',
                                    'pad': 'VCC',
                                    'port_type': 'VCC',
                                    'is_clock': False,
                                },
                            ],
                    },
                "GND":
                    {
                        'loc':
                            gnd_loc,
                        'pins':
                            [
                                {
                                    'wire': 'GND',
                                    'pad': 'GND',
                                    'port_type': 'GND',
                                    'is_clock': False,
                                },
                            ],
                    },
            }
    }

    return synth_tiles


def create_node_remap(nodes, channels_obj):
    N = 2
    p = math.ceil(math.log2(max(channels_obj.x_max, channels_obj.y_max)))

    point_map = {}

    for node in nodes:
        x = node.loc.x_low
        y = node.loc.y_low

        if (x, y) not in point_map:
            point_map[(x, y)] = []

        point_map[(x, y)].append(node.id)

    hilbert_curve = HilbertCurve(p, N)

    idx = 0
    id_map = {}
    for h in range(hilbert_curve.max_h + 1):
        coord = tuple(hilbert_curve.coordinates_from_distance(h))

        if coord not in point_map:
            continue

        for old_id in point_map[coord]:
            id_map[old_id] = idx
            idx += 1

        del point_map[coord]

    return lambda x: id_map[x]


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        '--db_root', required=True, help='Project X-Ray Database'
    )
    parser.add_argument('--part', required=True, help='FPGA part')
    parser.add_argument(
        '--read_rr_graph', required=True, help='Input rr_graph file'
    )
    parser.add_argument(
        '--write_rr_graph', required=True, help='Output rr_graph file'
    )
    parser.add_argument(
        '--write_rr_node_map',
        required=True,
        help='Output map of graph_node_pkey to rr inode file'
    )
    parser.add_argument(
        '--connection_database',
        help='Database of fabric connectivity',
        required=True
    )
    parser.add_argument(
        '--synth_tiles',
        help='If using an ROI, synthetic tile defintion from prjxray-arch-import'
    )
    parser.add_argument(
        '--graph_limit',
        help='Limit grid to specified dimensions in x_min,y_min,x_max,y_max',
    )
    parser.add_argument(
        '--vpr_capnp_schema_dir',
        help='Directory container VPR schema files',
    )

    print('{} Starting routing import'.format(now()))
    args = parser.parse_args()

    db = prjxray.db.Database(args.db_root, args.part)
    populate_hclk_cmt_tiles(db)

    synth_tiles = None
    if args.synth_tiles:
        use_roi = True
        with open(args.synth_tiles) as f:
            synth_tiles = json.load(f)

        roi = Roi(
            db=db,
            x1=synth_tiles['info']['GRID_X_MIN'],
            y1=synth_tiles['info']['GRID_Y_MIN'],
            x2=synth_tiles['info']['GRID_X_MAX'],
            y2=synth_tiles['info']['GRID_Y_MAX'],
        )

        print('{} generating routing graph for ROI.'.format(now()))
    elif args.graph_limit:
        use_roi = True
        x_min, y_min, x_max, y_max = map(int, args.graph_limit.split(','))
        roi = Roi(
            db=db,
            x1=x_min,
            y1=y_min,
            x2=x_max,
            y2=y_max,
        )
    else:
        use_roi = False
        roi = None
        synth_tiles = None

    capnp_graph = capnp_graph2.Graph(
        rr_graph_schema_fname=os.path.join(
            args.vpr_capnp_schema_dir, 'rr_graph_uxsdcxx.capnp'
        ),
        input_file_name=args.read_rr_graph,
        progressbar=progressbar_utils.progressbar,
        output_file_name=args.write_rr_graph,
    )

    graph = capnp_graph.graph

    if synth_tiles is None:
        synth_tiles = find_constant_network(graph)

    with sqlite3.connect("file:{}?mode=ro".format(args.connection_database),
                         uri=True) as conn:

        populate_bufg_rebuf_map(conn)

        cur = conn.cursor()
        for name, internal_capacitance, drive_resistance, intrinsic_delay, penalty_cost, \
                switch_type in cur.execute("""
SELECT
    name,
    internal_capacitance,
    drive_resistance,
    intrinsic_delay,
    penalty_cost,
    switch_type
FROM
    switch;"""):
            # Add back missing switchs, which were unused in arch xml, and so
            # were not  emitted in rrgraph XML.
            #
            # TODO: This can be removed once
            # https://github.com/verilog-to-routing/vtr-verilog-to-routing/issues/354
            # is fixed.

            try:
                graph.get_switch_id(name)
                continue
            except KeyError:
                capnp_graph.add_switch(
                    graph2.Switch(
                        id=None,
                        name=name,
                        type=graph2.SwitchType[switch_type.upper()],
                        timing=graph2.SwitchTiming(
                            r=drive_resistance,
                            c_in=0.0,
                            c_out=0.0,
                            c_internal=internal_capacitance,
                            t_del=intrinsic_delay,
                            p_cost=penalty_cost,
                        ),
                        sizing=graph2.SwitchSizing(
                            mux_trans_size=0,
                            buf_size=0,
                        ),
                    )
                )

        # Mapping of graph_node.pkey to rr node id.
        node_mapping = {}

        print('{} Creating connection box list'.format(now()))
        connection_box_map = create_connection_boxes(conn, graph)

        # Match site pins rr nodes with graph_node's in the connection_database.
        print('{} Importing graph nodes'.format(now()))
        import_graph_nodes(conn, graph, node_mapping, connection_box_map)

        # Walk all track graph nodes and add them.
        print('{} Creating tracks'.format(now()))
        segment_id = graph.get_segment_id_from_name('dummy')
        create_track_rr_graph(
            conn, graph, node_mapping, use_roi, roi, synth_tiles, segment_id
        )

        # Set of (src, sink, switch_id) tuples that pip edges have been sent to
        # VPR.  VPR cannot handle duplicate paths with the same switch id.
        print('{} Adding synthetic edges'.format(now()))
        add_synthetic_edges(conn, graph, node_mapping, grid, synth_tiles)

        print('{} Creating channels.'.format(now()))
        channels_obj = create_channels(conn)

        node_remap = create_node_remap(capnp_graph.graph.nodes, channels_obj)

        x_dim, y_dim = phy_grid_dims(conn)
        connection_box_obj = graph.create_connection_box_object(
            x_dim=x_dim, y_dim=y_dim
        )

        num_edges = get_number_graph_edges(conn, graph, node_mapping)
        print('{} Serializing to disk.'.format(now()))

        capnp_graph.serialize_to_capnp(
            channels_obj=channels_obj,
            connection_box_obj=connection_box_obj,
            num_nodes=len(capnp_graph.graph.nodes),
            nodes_obj=yield_nodes(capnp_graph.graph.nodes),
            num_edges=num_edges,
            edges_obj=import_graph_edges(conn, graph, node_mapping),
            node_remap=node_remap,
        )

        for k in node_mapping:
            node_mapping[k] = node_remap(node_mapping[k])

        print('{} Writing node map.'.format(now()))
        with open(args.write_rr_node_map, 'wb') as f:
            pickle.dump(node_mapping, f)
        print('{} Done writing node map.'.format(now()))


if __name__ == '__main__':
    main()
