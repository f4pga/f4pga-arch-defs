#!/usr/bin/env python3
"""
This script allows to read the tile grid from various sources and render it to
either SVG or PDF file. It can also draw connections between tiles when
provided with the 'tileconn.json' file used in the prjxray database.

Use ONE of following argument sets for data source specification:
1. --tilgrid <tilegrid.json> [--tileconn <tileconn.json>]
2. --arch-xml <arch.xml>
3. --graph-xml <rr_graph.xml>
4. --conn-db <channels.db> [--tb-table <tile table name>]
"""

import sys
import argparse
import os
import re
from collections import namedtuple

import progressbar

import json
import sqlite3

import lxml.etree as ET
import lxml.objectify as objectify

import svgwrite

# =============================================================================


class GridVisualizer(object):

    BLOCK_RECT = 100
    BLOCK_GAP = 10
    BLOCK_SIZE = BLOCK_RECT + BLOCK_GAP

    Loc = namedtuple("Loc", "x y")
    Conn = namedtuple("Conn", "loc0 loc1")
    GridExtent = namedtuple("GridExtent", "xmin ymin xmax ymax")

    def __init__(self):

        self.tilegrid = None
        self.tileconn = None

        self.grid_roi = None
        self.conn_roi = None

        self.tile_colormap = None
        self.connections = {}

    def load_tilegrid_from_json(self, json_file):

        # Load JSON files
        with open(json_file, "r") as fp:
            self.tilegrid = json.load(fp)

        self._determine_grid_extent()
        self._build_loc_map()

    def load_tileconn_from_json(self, json_file):

        # Load JSON files
        with open(json_file, "r") as fp:
            self.tileconn = json.load(fp)

        self._form_connections()

    def load_tilegrid_from_arch_xml(self, xml_file):

        # Load and parse the XML
        parser = ET.XMLParser(remove_comments=True)
        xml_tree = objectify.parse(xml_file, parser=parser)
        xml_root = xml_tree.getroot()

        # Get the layout section
        layout = xml_root.find("layout")
        assert (layout is not None)

        # Get the fixed_layout section
        fixed_layout = layout.find("fixed_layout")
        assert (fixed_layout is not None)

        # Extract the grid extent
        dx = int(fixed_layout.get("width"))
        dy = int(fixed_layout.get("height"))
        self.grid_extent = self.GridExtent(0, 0, dx, dy)

        # Convert
        self.tilegrid = {}

        for tile in list(fixed_layout):
            assert (tile.tag == "single")

            # Basic tile parameters
            grid_x = int(tile.get("x"))
            grid_y = int(tile.get("y"))
            tile_type = tile.get("type")

            # Tile name (if present)
            tile_name = None
            metadata = tile.find("metadata")
            if metadata is not None:
                for meta in metadata.findall("meta"):
                    if meta.get("name") == "fasm_prefix":
                        tile_name = meta.text

            # Fake tile name
            if tile_name is None:
                tile_name = "UNKNOWN_X%dY%d" % (grid_x, grid_y)

            # Already exists
            if tile_name in self.tilegrid:
                tile_name += "(2)"

            self.tilegrid[tile_name] = {
                "grid_x": grid_x,
                "grid_y": grid_y,
                "type": tile_type
            }

        self._build_loc_map()

    def load_tilegrid_from_graph_xml(self, xml_file):

        # Load and parse the XML
        parser = ET.XMLParser(remove_comments=True)
        xml_tree = objectify.parse(xml_file, parser=parser)
        xml_root = xml_tree.getroot()

        # Load block types
        xml_block_types = xml_root.find("block_types")
        assert (xml_block_types is not None)

        block_types = {}
        for xml_block_type in xml_block_types:
            block_type_id = int(xml_block_type.get("id"))
            block_name = xml_block_type.get("name")

            block_types[block_type_id] = block_name

        # Load grid
        self.tilegrid = {}

        all_x = set()
        all_y = set()

        xml_grid = xml_root.find("grid")
        assert (xml_grid is not None)

        for xml_grid_loc in xml_grid:
            grid_x = int(xml_grid_loc.get("x"))
            grid_y = int(xml_grid_loc.get("y"))
            block_type_id = int(xml_grid_loc.get("block_type_id"))

            all_x.add(grid_x)
            all_y.add(grid_y)

            # Fake tile name
            tile_name = "BLOCK_X%dY%d" % (grid_x, grid_y)

            self.tilegrid[tile_name] = {
                "grid_x": grid_x,
                "grid_y": grid_y,
                "type": block_types[block_type_id]
            }

        # Determine grid extent
        self.grid_extent = self.GridExtent(
            min(all_x), min(all_y), max(all_x), max(all_y)
        )

        self._build_loc_map()

    def load_tilegrid_from_conn_db(self, db_file, db_table):

        # Connect to the database and load data
        with sqlite3.Connection("file:%s?mode=ro" % db_file, uri=True) as conn:
            c = conn.cursor()

            # Load the grid
            db_tiles = c.execute(
            "SELECT pkey, name, tile_type_pkey, grid_x, grid_y FROM %s" % \
            (db_table)).fetchall() # They say that it is insecure..

            # Load tile types
            db_tile_types = c.execute("SELECT pkey, name FROM tile_type"
                                      ).fetchall()

        # Maps pkey to type string
        tile_type_map = {}
        for item in db_tile_types:
            tile_type_map[item[0]] = item[1]

        # Translate information
        self.tilegrid = {}

        all_x = set()
        all_y = set()

        for tile in db_tiles:

            tile_type_pkey = tile[2]

            if tile_type_pkey not in tile_type_map.keys():
                print("Unknown tile type pkey %d !" % tile_type_pkey)
                continue

            tile_name = tile[1]
            tile_type = tile_type_map[tile_type_pkey]
            tile_grid_x = tile[3]
            tile_grid_y = tile[4]

            if tile_name in self.tilegrid:
                print("Duplicate tile name '%s' !" % tile_name)
                continue

            all_x.add(tile_grid_x)
            all_y.add(tile_grid_y)

            self.tilegrid[tile_name] = {
                "grid_x": tile_grid_x,
                "grid_y": tile_grid_y,
                "type": tile_type
            }

        # Determine grid extent
        self.grid_extent = self.GridExtent(
            min(all_x), min(all_y), max(all_x), max(all_y)
        )

        self._build_loc_map()

    def load_tile_colormap(self, colormap):

        # If it fails just skip it
        try:
            with open(colormap, "r") as fp:
                self.tile_colormap = json.load(fp)

        except FileNotFoundError:
            pass

    def set_grid_roi(self, roi):
        self.grid_roi = roi

    def set_conn_roi(self, roi):
        self.conn_roi = roi

    def _determine_grid_extent(self):

        # Determine the grid extent
        xs = set()
        ys = set()

        for tile in self.tilegrid.values():
            xs.add(tile["grid_x"])
            ys.add(tile["grid_y"])

        self.grid_extent = self.GridExtent(min(xs), min(ys), max(xs), max(ys))

        if self.grid_roi is not None:
            self.grid_extent = self.GridExtent(
                max(self.grid_extent.xmin, self.grid_roi[0]),
                max(self.grid_extent.ymin, self.grid_roi[1]),
                min(self.grid_extent.xmax, self.grid_roi[2]),
                min(self.grid_extent.ymax, self.grid_roi[3])
            )

    def _build_loc_map(self):

        self.loc_map = {}

        for tile_name, tile in self.tilegrid.items():
            loc = self.Loc(tile["grid_x"], tile["grid_y"])

            if loc in self.loc_map.keys():
                print("Duplicate tile at [%d, %d] !" % (loc.x, loc.y))

            self.loc_map[loc] = tile_name

    def _form_connections(self):

        # Loop over tiles of interest
        print("Forming connections...")
        for tile_name, tile in progressbar.progressbar(self.tilegrid.items()):

            this_loc = self.Loc(tile["grid_x"], tile["grid_y"])
            this_type = tile["type"]

            # Find matching connection rules
            for rule in self.tileconn:
                grid_deltas = rule["grid_deltas"]
                tile_types = rule["tile_types"]
                wire_count = len(rule["wire_pairs"])

                for k in [+1]:

                    # Get a couterpart tile according to the rule grid delta
                    other_loc = self.Loc(
                        this_loc.x + k * grid_deltas[0],
                        this_loc.y + k * grid_deltas[1]
                    )

                    try:
                        other_name = self.loc_map[other_loc]
                        other_type = self.tilegrid[other_name]["type"]
                    except KeyError:
                        continue

                    # Check match
                    if this_type == tile_types[0] and \
                       other_type == tile_types[1]:

                        # Add the connection
                        conn = self.Conn(this_loc, other_loc)

                        if conn not in self.connections.keys():
                            self.connections[conn] = wire_count
                        else:
                            self.connections[conn] += wire_count

    def _draw_connection(self, x0, y0, x1, y1, curve=False):

        if curve:
            dx = x1 - x0
            dy = y1 - y0

            cx = (x1 + x0) * 0.5 + dy * 0.33
            cy = (y1 + y0) * 0.5 - dx * 0.33

            path = "M %.3f %.3f " % (x0, y0)
            path += "C %.3f %.3f %.3f %.3f %.3f %.3f" % \
                (cx, cy, cx, cy, x1, y1)

            self.svg.add(self.svg.path(d=path, fill="none", stroke="#000000"))

        else:
            self.svg.add(self.svg.line((x0, y0), (x1, y1), stroke="#000000"))

    def _grid_to_drawing(self, x, y):

        xc = (x - self.grid_extent.xmin + 1) * self.BLOCK_SIZE
        yc = (y - self.grid_extent.ymin + 1) * self.BLOCK_SIZE

        return xc, yc

    def _create_drawing(self):

        # Drawing size
        self.svg_dx = (self.grid_extent.xmax - self.grid_extent.xmin + 2) \
            * self.BLOCK_SIZE
        self.svg_dy = (self.grid_extent.ymax - self.grid_extent.ymin + 2) \
            * self.BLOCK_SIZE

        # Create the drawing
        self.svg = svgwrite.Drawing(
            size=(self.svg_dx, self.svg_dy), profile="full", debug=False
        )

    def _get_tile_color(self, tile_name, tile):
        tile_type = tile["type"]

        # Match
        if self.tile_colormap is not None:
            for rule in self.tile_colormap:

                # Match by tile name
                if "name" in rule and re.match(rule["name"], tile_name):
                    return rule["color"]
                # Match by tile type
                if "type" in rule and re.match(rule["type"], tile_type):
                    return rule["color"]

        # A default color
        return "#C0C0C0"

    def _draw_grid(self):

        svg_tiles = []
        svg_text = []

        # Draw tiles
        print("Drawing grid...")
        for tile_name, tile in progressbar.progressbar(self.tilegrid.items()):

            grid_x = tile["grid_x"]
            grid_y = tile["grid_y"]
            tile_type = tile["type"]

            if self.grid_roi:
                if grid_x < self.grid_roi[0] or grid_x > self.grid_roi[2]:
                    continue
                if grid_y < self.grid_roi[1] or grid_y > self.grid_roi[3]:
                    continue

            xc, yc = self._grid_to_drawing(grid_x, grid_y)

            color = self._get_tile_color(tile_name, tile)
            if color is None:
                continue

            font_size = self.BLOCK_RECT / 10

            # Rectangle
            svg_tiles.append(
                self.svg.rect(
                    (
                        xc - self.BLOCK_RECT / 2,
                        (self.svg_dy - 1 - yc) - self.BLOCK_RECT / 2
                    ), (self.BLOCK_RECT, self.BLOCK_RECT),
                    stroke="#C0C0C0",
                    fill=color
                )
            )

            if grid_x & 1:
                text_ofs = -font_size
            else:
                text_ofs = font_size

            # Tile name
            svg_text.append(
                self.svg.text(
                    tile_name, (
                        xc - self.BLOCK_RECT / 2 + 2,
                        (self.svg_dy - 1 - yc) - font_size / 2 + text_ofs
                    ),
                    font_size=font_size
                )
            )
            # Tile type
            svg_text.append(
                self.svg.text(
                    tile_type, (
                        xc - self.BLOCK_RECT / 2 + 2,
                        (self.svg_dy - 1 - yc) + font_size / 2 + text_ofs
                    ),
                    font_size=font_size
                )
            )

            # Index
            svg_text.append(
                self.svg.text(
                    "X%dY%d" % (grid_x, grid_y), (
                        xc - self.BLOCK_RECT / 2 + 2,
                        (self.svg_dy - 1 - yc) + self.BLOCK_RECT / 2 - 2
                    ),
                    font_size=font_size
                )
            )

        # Add tiles to SVG
        for item in svg_tiles:
            self.svg.add(item)

        # Add text to SVG
        for item in svg_text:
            self.svg.add(item)

    def _draw_connections(self):

        # Draw connections
        print("Drawing connections...")
        for conn, count in progressbar.progressbar(self.connections.items()):

            if self.conn_roi:

                if conn.loc0.x < self.grid_roi[0] or \
                   conn.loc0.x > self.grid_roi[2]:
                    if conn.loc1.x < self.grid_roi[0] or \
                       conn.loc1.x > self.grid_roi[2]:
                        continue

                if conn.loc0.y < self.grid_roi[1] or \
                   conn.loc0.y > self.grid_roi[3]:
                    if conn.loc1.y < self.grid_roi[1] or \
                       conn.loc1.y > self.grid_roi[3]:
                        continue

            dx = conn.loc1.x - conn.loc0.x
            dy = conn.loc1.y - conn.loc0.y

            xc0, yc0 = self._grid_to_drawing(conn.loc0.x, conn.loc0.y)
            xc1, yc1 = self._grid_to_drawing(conn.loc1.x, conn.loc1.y)

            max_count = int(self.BLOCK_RECT * 0.75 * 0.5)
            line_count = min(count, max_count)

            # Mostly horizontal
            if abs(dx) > abs(dy):

                for i in range(line_count):
                    k = 0.5 if line_count == 1 else i / (line_count - 1)
                    k = (k - 0.5) * 0.75

                    if dx > 0:
                        x0 = xc0 + self.BLOCK_RECT / 2
                        x1 = xc1 - self.BLOCK_RECT / 2
                    else:
                        x0 = xc0 - self.BLOCK_RECT / 2
                        x1 = xc1 + self.BLOCK_RECT / 2

                    y0 = yc0 + k * self.BLOCK_RECT
                    y1 = yc1 + k * self.BLOCK_RECT

                    self._draw_connection(
                        x0, (self.svg_dy - 1 - y0), x1, (self.svg_dy - 1 - y1),
                        True
                    )

            # Mostly vertical
            elif abs(dy) > abs(dx):

                for i in range(line_count):
                    k = 0.5 if line_count == 1 else i / (line_count - 1)
                    k = (k - 0.5) * 0.75

                    if dy > 0:
                        y0 = yc0 + self.BLOCK_RECT / 2
                        y1 = yc1 - self.BLOCK_RECT / 2
                    else:
                        y0 = yc0 - self.BLOCK_RECT / 2
                        y1 = yc1 + self.BLOCK_RECT / 2

                    x0 = xc0 + k * self.BLOCK_RECT
                    x1 = xc1 + k * self.BLOCK_RECT

                    self._draw_connection(
                        x0, (self.svg_dy - 1 - y0), x1, (self.svg_dy - 1 - y1),
                        True
                    )

            # Diagonal
            else:
                # FIXME: Do it in a more elegant way...

                max_count = int(max_count * 0.40)
                line_count = min(count, max_count)

                for i in range(line_count):
                    k = 0.5 if line_count == 1 else i / (line_count - 1)
                    k = (k - 0.5) * 0.25

                    if (dx > 0) ^ (dy > 0):
                        x0 = xc0 + k * self.BLOCK_RECT
                        x1 = xc1 + k * self.BLOCK_RECT
                        y0 = yc0 + k * self.BLOCK_RECT
                        y1 = yc1 + k * self.BLOCK_RECT
                    else:
                        x0 = xc0 - k * self.BLOCK_RECT
                        x1 = xc1 - k * self.BLOCK_RECT
                        y0 = yc0 + k * self.BLOCK_RECT
                        y1 = yc1 + k * self.BLOCK_RECT

                    x0 += dx * self.BLOCK_RECT / 4
                    y0 += dy * self.BLOCK_RECT / 4
                    x1 -= dx * self.BLOCK_RECT / 4
                    y1 -= dy * self.BLOCK_RECT / 4

                    self._draw_connection(
                        x0, (self.svg_dy - 1 - y0), x1, (self.svg_dy - 1 - y1),
                        False
                    )

    def run(self):

        if self.grid_roi is not None:

            if self.conn_roi is None:
                self.conn_roi = self.grid_roi
            else:
                self.conn_roi[0] = max(self.conn_roi[0], self.grid_roi[0])
                self.conn_roi[1] = max(self.conn_roi[1], self.grid_roi[1])
                self.conn_roi[2] = min(self.conn_roi[2], self.grid_roi[2])
                self.conn_roi[3] = min(self.conn_roi[3], self.grid_roi[3])

        self._create_drawing()
        self._draw_grid()
        self._draw_connections()

    def save(self, file_name):
        self.svg.saveas(file_name)


# =============================================================================


def main():

    # Parse arguments
    parser = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter
    )

    parser.add_argument(
        "--tilegrid",
        type=str,
        default=None,
        help="Project X-Ray 'tilegrid.json' file"
    )
    parser.add_argument(
        "--tileconn",
        type=str,
        default=None,
        help="Project X-Ray 'tileconn.json' file"
    )
    parser.add_argument(
        "--arch-xml",
        type=str,
        default=None,
        help="Architecture definition XML file"
    )
    parser.add_argument(
        "--graph-xml", type=str, default=None, help="Routing graph XML file"
    )
    parser.add_argument(
        '--conn-db',
        type=str,
        default=None,
        help='Connection SQL database (eg. "channels.db")'
    )
    parser.add_argument(
        '--db-table',
        type=str,
        default="tile",
        help='Table name in the SQL database to read (def. "tile")'
    )
    parser.add_argument(
        "--colormap",
        type=str,
        default=None,
        help="JSON file with tile coloring rules"
    )
    parser.add_argument(
        "--grid-roi",
        type=int,
        nargs=4,
        default=None,
        help="Grid ROI to draw (x0 y0 x1 y1)"
    )
    parser.add_argument(
        "--conn-roi",
        type=int,
        nargs=4,
        default=None,
        help="Connection ROI to draw (x0 y0 x1 y1)"
    )
    parser.add_argument(
        "-o", type=str, default="layout.svg", help="Output SVG file name"
    )

    if len(sys.argv) <= 1:
        parser.print_help()
        exit(1)

    args = parser.parse_args()

    script_path = os.path.dirname(os.path.realpath(__file__))
    if args.colormap is None:
        args.colormap = os.path.join(script_path, "tile_colormap.json")

    # Create the visualizer
    visualizer = GridVisualizer()

    # Set ROI
    visualizer.set_grid_roi(args.grid_roi)
    visualizer.set_conn_roi(args.conn_roi)

    # Load arch XML file
    if args.arch_xml is not None:
        visualizer.load_tilegrid_from_arch_xml(args.arch_xml)
    # Load routing graph XML
    elif args.graph_xml is not None:
        visualizer.load_tilegrid_from_graph_xml(args.graph_xml)
    # Load JSON files
    elif args.tilegrid is not None:

        visualizer.load_tilegrid_from_json(args.tilegrid)

        if args.tileconn is not None:
            visualizer.load_tileconn_from_json(args.tileconn)
    # Load SQL database
    elif args.conn_db is not None:
        visualizer.load_tilegrid_from_conn_db(args.conn_db, args.db_table)

    # No data input
    else:
        raise RuntimeError("No input data specified")

    # Load tile colormap
    if args.colormap:
        visualizer.load_tile_colormap(args.colormap)

    # Do the visualization
    visualizer.run()

    # Save drawing
    if args.o.endswith(".svg"):
        print("Saving SVG...")
        visualizer.save(args.o)

    elif args.o.endswith(".pdf"):
        print("Saving PDF...")

        from cairosvg import svg2pdf
        svg2pdf(visualizer.svg.tostring(), write_to=args.o)

    else:
        print("Unknown output file type '{}'".format(args.o))
        exit(-1)

    print("Done.")


# =============================================================================

if __name__ == "__main__":
    main()
