-- Grid location map
CREATE TABLE IF NOT EXISTS grid_loc_map(
    phy_tile_pkey INT,
    vpr_tile_pkey INT,
    FOREIGN KEY(phy_tile_pkey) REFERENCES phy_tile(pkey),
    FOREIGN KEY(vpr_tile_pkey) REFERENCES tile(pkey)
);

