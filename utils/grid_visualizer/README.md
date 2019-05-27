# Grid visualizer

This is a python utility which can visualize tile grid. It can load the grid definition from various sources (prjxray database files, arch.xml, rr_graph.xml, SQL database) and render it to a SVG/PDF file.

## 1. Usage

```
usage: grid_visualizer.py [-h] [--tilegrid TILEGRID] [--tileconn TILECONN]
                          [--arch-xml ARCH_XML] [--graph-xml GRAPH_XML]
                          [--conn-db CONN_DB] [--db-table DB_TABLE]
                          [--colormap COLORMAP]
                          [--grid-roi GRID_ROI GRID_ROI GRID_ROI GRID_ROI]
                          [--conn-roi CONN_ROI CONN_ROI CONN_ROI CONN_ROI]
                          [-o O]

This script allows to read the tile grid from various sources and render it to
either SVG or PDF file. It can also draw connections between tiles when
provided with the 'tileconn.json' file used in the prjxray database.

Use ONE of following argument sets for data source specification:
1. --tilgrid <tilegrid.json> [--tileconn <tileconn.json>]
2. --arch-xml <arch.xml>
3. --graph-xml <rr_graph.xml>
4. --conn-db <channels.db> [--tb-table <tile table name>]

optional arguments:
  -h, --help            show this help message and exit
  --tilegrid TILEGRID   Project X-Ray 'tilegrid.json' file
  --tileconn TILECONN   Project X-Ray 'tileconn.json' file
  --arch-xml ARCH_XML   Architecture definition XML file
  --graph-xml GRAPH_XML
                        Routing graph XML file
  --conn-db CONN_DB     Connection SQL database (eg. "channels.db")
  --db-table DB_TABLE   Table name in the SQL database to read (def. "tile")
  --colormap COLORMAP   JSON file with tile coloring rules
  --grid-roi GRID_ROI GRID_ROI GRID_ROI GRID_ROI
                        Grid ROI to draw (x0 y0 x1 y1)
  --conn-roi CONN_ROI CONN_ROI CONN_ROI CONN_ROI
                        Connection ROI to draw (x0 y0 x1 y1)
  -o O                  Output SVG file name

```

### 1.1 Usage examples

 * Render the whole tile grid to an SVG file using the architecture XML as the source:

    ```
    ./grid_visualizer.py --arch-xml arch.unique_pack.xml -o grid.svg
    ```

 * Render the whole tile grid to an SVG file using the routng graph XML as the source

    ```
    ./grid_visualizer.py --grap-xml rr_graph_hx1k_tq144.rr_graph.real.xml -o grid.svg
    ```

 * Render only a section of the tile grid along with tile connections using JSON files from the database directly:

    ```
    ./grid_visualizer.py --tilegrid tilegrid.json --tileconn tileconn.json --grid-roi 10 20 30 40 -o grid.svg
    ```
