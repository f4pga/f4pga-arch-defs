"""
This file contains a "proxy" class which implements an "overlay" for the
prjxray database.
"""

import os
import json

from prjxray import db
from prjxray import tile

# =============================================================================


class DatabaseWithOverlay(db.Database):
    """
    Prjxray database overlay
    """

    def __init__(self, db_root, overlay_root=None):
        """
        Constructor.

        :param db_root: Prjxray database root
        :param db_overlay: Prjxray database overlay root
        """

        # Initialize base class
        db.Database.__init__(self, db_root)

        # Get overlay root
        if overlay_root is None:
            overlay_root = os.path.dirname(__file__)
        self.overlay_root = overlay_root

        # Load additional tile types
        for f in os.listdir(self.overlay_root):
            if f.endswith('.json') and f.startswith('tile_type_'):
                tile_type = f[len('tile_type_'):-len('.json')].lower()

                print("Overlay tile type: '%s'" % tile_type)

                tile_type_file = os.path.join(
                    self.overlay_root, 'tile_type_{}.json'.format(
                        tile_type.upper()))
                if not os.path.isfile(tile_type_file):
                    tile_type_file = None

                self.tile_types[tile_type.upper()] = tile.TileDbs(
                    segbits=None,
                    block_ram_segbits=None,
                    ppips=None,
                    mask=None,
                    tile_type=tile_type_file,
                )

        # Delete splitted tile types
        # FIXME: Make it derived from somewhere somehow....
        del self.tile_types["CLBLL_L"]
        del self.tile_types["CLBLL_R"]
        del self.tile_types["CLBLM_L"]
        del self.tile_types["CLBLM_R"]

#        print("Tile types:")
#        for tile_type in self.tile_types:
#            print(" ", tile_type)

    def _read_tilegrid(self):
        """ Read tilegrid database if not already read. """
        if not self.tilegrid:
            with open(os.path.join(self.overlay_root, 'tilegrid.json')) as f:
                self.tilegrid = json.load(f)

    def _read_tileconn(self):
        """ Read tileconn database if not already read. """
        if not self.tileconn:
            with open(os.path.join(self.overlay_root, 'tileconn.json')) as f:
                self.tileconn = json.load(f)
