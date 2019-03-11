"""
This file contains a "proxy" class which implements an "overlay" for the
prjxray ROI.
"""

import os
import json

from prjxray import roi

# =============================================================================


class RoiWithOverlay(roi.Roi):
    """
    ROI overlay. Provides ROI coordinate translation according to the grid split.
    """

    def __init__(self, db, x1, x2, y1, y2):

        # Initialize the base class
        roi.Roi.__init__(self, db, x1, x2, y1, y2)

        # Load grid X location map
        loc_map_file = os.path.join(db.overlay_root, "map_grid_loc.json")
        with open(loc_map_file, "r") as fp:
            loc_map = json.load(fp)

        # Remap ROI boundaries
        fwd_loc_map = loc_map["forward"]

        new_x1 = min(fwd_loc_map[str(self.x1)])
        new_x2 = max(fwd_loc_map[str(self.x2)])

        # Debug
        print("Mapping X1 %d -> %d" % (self.x1, new_x1))
        print("Mapping X2 %d -> %d" % (self.x2, new_x2))

        self.x1 = new_x1
        self.x2 = new_x2
