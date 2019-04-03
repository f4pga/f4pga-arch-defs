-- Grid location map
-- This table maps locations from the input (physical) grid to the VPR grid
-- locations and vice versa. If there are multiple entries for the same physical
-- location (grid_phy_x, grid_phy_y) then it means that a single physical tile 
-- should end up being splitted.
CREATE TABLE IF NOT EXISTS grid_loc_map(
    grid_phy_x INT,
    grid_phy_y INT,
    grid_vpr_x INT,
    grid_vpr_y INT
);

