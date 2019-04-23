-- This is the database schema for relating a tile grid to a VPR routing
-- graph.
--
-- Terms:
--  grid - A 2D matrix of tiles
--
--  tile - A location within the grid.  A tile is always of a partial
--         tile type.  The tile type specifies what wires, pips and
--         sites a tile contains.
--
--  wires - A partial net within a tile.  It may start or end at a site pins
--          or a pip, or can connect to wires in other tiles.
--
--  pip - Programable interconnect point, connecting two wires within a
--        tile.
--
--  node - A complete net made of one or more wires.
--
--  site - A location within a tile that contains site pins and BELs.
--         BELs are not described in this database.
--
--  site - Site pins are the connections to/from the site to a wire in a
--         tile.  A site pin may be associated with one wire in the tile.
--
--  graph_node - A VPR type representing either a pb_type IPIN or OPIN or
--               a routing wire CHANX or CHANY.
--
--               IPIN/OPIN are similiar to site pin.
--               CHANX/CHANY are how VPR express routing nodes.
--
--  track - A collection of graph_node's that represents one routing node.
--
--  graph_edge - A VPR type representing a connection between an IPIN, OPIN,
--               CHANX, or CHANY.  All graph_edge's require a switch.
--
--  switch - See VPR documentation :http://docs.verilogtorouting.org/en/latest/arch/reference/--tag-fpga-device-information-switch_block
--
--  This database provides a relational description between the terms above.

-- Tile type table, used to track tile_type using a pkey, and provide
-- the tile_type_pkey <-> name mapping.
CREATE TABLE tile_type(
  pkey INTEGER PRIMARY KEY,
  name TEXT
);

-- Site type table, used to track site_type using a pkey, and provide
-- the site_type_pkey <-> name mapping.
CREATE TABLE site_type(
  pkey INTEGER PRIMARY KEY,
  name TEXT
);

-- Tile table, contains type and name of tile and location in the physical grid.
CREATE TABLE phy_tile(
  pkey INTEGER PRIMARY KEY,
  name TEXT,
  tile_type_pkey INT,
  grid_x INT,
  grid_y INT,
  FOREIGN KEY(tile_type_pkey) REFERENCES tile_type(pkey)
);

-- Tile table, contains type and name of tile and location in the VPR grid.
CREATE TABLE tile(
  pkey INTEGER PRIMARY KEY,
  name TEXT,
  tile_type_pkey INT,
  site_remap_pkey INT,
  grid_x INT,
  grid_y INT,
  FOREIGN KEY(tile_type_pkey) REFERENCES tile_type(pkey)
  FOREIGN KEY(site_remap_pkey) REFERENCES site(pkey)
);

-- Site pin table, contains names of pins and their direction, along
-- with parent site type information.
CREATE TABLE site_pin(
  pkey INTEGER PRIMARY KEY,
  name TEXT,
  site_type_pkey INT,
  direction TEXT,
  FOREIGN KEY(site_type_pkey) REFERENCES site_type(pkey)
);

-- Concreate site instance within tiles.  Used to relate connect
-- wire_in_tile instead to site_type's, along with providing metadata
-- about the site.
CREATE TABLE site(
  pkey INTEGER PRIMARY KEY,
  name TEXT,
  x_coord INT,
  y_coord INT,
  site_type_pkey INT,
  FOREIGN KEY(site_type_pkey) REFERENCES site_type(pkey)
);

-- Table of tile type wires. This table is the of uninstanced tile type
-- wires. Site pins wires will reference their site and site pin rows in
-- the site and site_pin tables.
--
-- All concrete wire instances will related to a row in this table.
CREATE TABLE wire_in_tile(
  pkey INTEGER PRIMARY KEY,
  name TEXT,
  tile_type_pkey INT,
  site_pkey INT,
  site_pin_pkey INT,
  FOREIGN KEY(tile_type_pkey) REFERENCES tile_type(pkey),
  FOREIGN KEY(site_pkey) REFERENCES site(pkey),
  FOREIGN KEY(site_pin_pkey) REFERENCES site_pin(pkey)
);

-- Table of tile type pips.  This table is the table of uninstanced pips.
-- No concreate table of pips is created, instead this table is used to
-- add rows in the graph_edge table.
CREATE TABLE pip_in_tile(
  pkey INTEGER PRIMARY KEY,
  name TEXT,
  tile_type_pkey INT,
  src_wire_in_tile_pkey INT,
  dest_wire_in_tile_pkey INT,
  can_invert BOOLEAN,
  is_directional BOOLEAN,
  is_pseudo BOOLEAN,
  FOREIGN KEY(tile_type_pkey) REFERENCES tile_type(pkey),
  FOREIGN KEY(src_wire_in_tile_pkey) REFERENCES wire_in_tile(pkey),
  FOREIGN KEY(dest_wire_in_tile_pkey) REFERENCES wire_in_tile(pkey)
);

-- Table of tracks. alive is a flag used during routing import to indicate
-- whether this a particular track is connected and should be imported.
CREATE TABLE track(
  pkey INTEGER PRIMARY KEY,
  alive BOOL
);

-- Table of nodes.  Provides the concrete relation for connected wire
-- instances. Generally speaking nodes are either routing nodes or a site
-- pin node.
--
-- Routing nodes will have track_pkey set.
-- Site pin nodes will have a site_wire_pkey to the wire that is the wire
-- connected to a site pin.
CREATE TABLE node(
  pkey INTEGER PRIMARY KEY,
  number_pips INT,
  track_pkey INT,
  site_wire_pkey INT,
  classification INT,
  FOREIGN KEY(track_pkey) REFERENCES track_pkey(pkey),
  FOREIGN KEY(site_wire_pkey) REFERENCES wire(pkey)
);

-- Table of edge with mux.  An edge_with_mux needs special handling in VPR,
-- in the form of architecture level direct connections.
--
-- This table is the list of these direct connections.
CREATE TABLE edge_with_mux(
  pkey INTEGER PRIMARY KEY,
  src_wire_pkey INT,
  dest_wire_pkey INT,
  pip_in_tile_pkey INT,
  FOREIGN KEY(src_wire_pkey) REFERENCES wire(pkey),
  FOREIGN KEY(dest_wire_pkey) REFERENCES wire(pkey),
  FOREIGN KEY(pip_in_tile_pkey) REFERENCES pip_in_tile(pkey)
);

-- Table of graph nodes.  This is a direction mapping of an VPR rr_node
-- instance.
CREATE TABLE graph_node(
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
);

-- Table of wires.  This table is the complete list of all wires in the
-- grid. All wires will belong to exactly one node.
--
-- Rows will relate back to their parent tile, and generic wire instance.
--
-- If the wire is connected to both a site pin and a pip, then
-- top_graph_node_pkey, bottom_graph_node_pkey, left_graph_node_pkey, and
-- right_graph_node_pkey will be set to the IPIN or OPIN instances, based
-- on the pin directions for the tile.
--
-- If the wire is a member of a routing node, then graph_node_pkey will be
-- set to the graph_node this wire is a member of.
CREATE TABLE wire(
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
);

-- Table of switches.
CREATE TABLE switch(
  pkey INTEGER PRIMARY KEY,
  name TEXT
);

-- Table of graph edges.
CREATE TABLE graph_edge(
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
);

-- channel, x_list and y_list are direct mappings of the channel object
-- present in the rr_graph.
CREATE TABLE channel(
  chan_width_max INT,
  x_min INT,
  y_min INT,
  x_max INT,
  y_max INT
);
CREATE TABLE x_list(
    idx INT,
    info INT
);
CREATE TABLE y_list(
    idx INT,
    info INT
);

-- Table that represents the (optional) VCC and GND global sources.
-- VPR cannot natively take advantage of local VCC and GND sources, so
-- a global source is generated, and local sources will connect to the global
-- sources.
CREATE TABLE constant_sources(
    vcc_track_pkey INT,
    gnd_track_pkey INT,
    FOREIGN KEY(vcc_track_pkey) REFERENCES track(pkey),
    FOREIGN KEY(gnd_track_pkey) REFERENCES track(pkey)
);

-- Grid location map.
CREATE TABLE grid_loc_map(
    phy_tile_pkey INT,
    vpr_tile_pkey INT,
    FOREIGN KEY(phy_tile_pkey) REFERENCES phy_tile(pkey),
    FOREIGN KEY(vpr_tile_pkey) REFERENCES tile(pkey)
);

-- Tile type map.
-- Maps physical tiles to VPR tiles. Used for CLB splitting
CREATE TABLE tile_type_map(
    phy_tile_type_pkey INT,
    vpr_tile_type_pkey INT,
    FOREIGN KEY(phy_tile_type_pkey) REFERENCES tile_type(pkey),
    FOREIGN KEY(vpr_tile_type_pkey) REFERENCES tile_type(pkey)
);

-- Pip in tile instance
-- Relates a pip_in_tile with a concrete tile instance in the VPR grid.
-- This is necessary as in the VPR we have generic SLICE tiles but pips
-- inside them are not generic.
CREATE TABLE pip(
    vpr_tile_pkey INT,
    pip_in_tile_pkey INT,
    FOREIGN KEY(vpr_tile_pkey) REFERENCES tile(pkey),
    FOREIGN KEY(pip_in_tile_pkey) REFERENCES pip_in_tile(pkey)
);
