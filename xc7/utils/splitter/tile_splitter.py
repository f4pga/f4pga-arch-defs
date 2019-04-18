import sqlite3

from lib.grid_mapping import GenericMap

# =============================================================================


class TileSplitter(object):

    def __init__(self, prjxray_db, sql_db):
        self.prjxray_db = prjxray_db
        self.sql_db = sql_db

        self.tile_types_to_split = []

    def set_tile_types_to_split(self, tile_types):
        """
        Set tile types to split
        """
        self.tile_types_to_split = tile_types

    def get_tile_type_sites(self, tile_type):
        """
        Returns all site types and their offsets for a given tile type
        """

        c = self.sql_db.cursor()

        # Get the tile type pkey
        tile_type_pkey = c.execute("SELECT pkey FROM tile_type WHERE name = (?)", (tile_type,)).fetchone()[0]

        # Get sites
        sites = c.execute("SELECT site_type.name, site. x_coord, y_coord FROM site INNER JOIN site_type ON site.site_type_pkey = site_type.pkey WHERE site.pkey IN (SELECT site_pkey FROM wire_in_tile WHERE tile_type_pkey = (?) AND site_pkey IS NOT NULL)", (tile_type_pkey, )).fetchall()

        # Return a list of tuples (site_type, site_ofs)
        return [(s[0], (s[1], s[2])) for s in sites]

    def get_unique_site_types(self):
        """
        Returns unique site types among all considered tile types
        """

        unique_site_types = set()

        for tile_type in self.tile_types_to_split:
            sites = self.get_tile_type_sites(tile_type)
            for site_type, site_ofs in sites:
                unique_site_types.add(site_type)

        return unique_site_types

    def insert_new_tile_types(self):
        """
        Creates new tile types and insets them to the database
        """

        c = self.sql_db.cursor()

        # Identify all unique site types for tiles being split and insert them
        # as new tile types.
        unique_site_types = self.get_unique_site_types()
        for site_type in unique_site_types:
            c.execute("INSERT INTO tile_type(name) VALUES(?)", (site_type, ))
            #print(c.lastrowid, site_type)


    # def insert_wires_and_pips(self):
    #     """
    #     Inserts wires and pips for new tile types
    #     """
    #
    #     c = self.sql_db.cursor()
    #
    #     for tile_type in self.tile_types_to_split:
    #
    #         # Get the physical tile type pkey
    #         tile_type_pkey = c.execute("SELECT pkey FROM tile_type WHERE name = (?)", (tile_type,)).fetchone()[0]
    #
    #         # Insert wires
    #         wires = {}
    #         for wire in tile_type.get_wires():
    #
    #             # Get target tile type for that wire
    #             vpr_tile_type = self.tile_wire_name_map.fwd_map
    #
    #             c.execute("""INSERT INTO wire_in_tile(name, tile_type_pkey) VALUES (?, ?)""", (wire, tile_types[tile_type_name]))
    #             wires[wire] = c.lastrowid

    def insert_new_tile_wires(self):
        """
        Insert wires relevant to split tiles to the wire_in_tile table.
        """

        c = self.sql_db.cursor()

        for phy_tile_type_pkey, vpr_tile_data in self.tile_type_pkey_map.fwd_map.items():
            vpr_tile_type_pkey = vpr_tile_data[0]
            site_ofs = vpr_tile_data[1]



        # # For every wire in tile being split
        # for phy_tile_type, fwd_map in self.tile_wire_name_map.items():
        #
        #     # Get the physical tile type pkey
        #     phy_tile_type_pkey = c.execute("SELECT pkey FROM tile_type WHERE name = (?)", (phy_tile_type,)).fetchone()[0]
        #
        #     for wire, wire_site_name in fwd_map.items():
        #
        #         # Match wire_site_name with tile_site_name
        #         for xxx in self.tile_type_pkey_map




    @staticmethod
    def append_to_map(map_dict, map_key, map_item):
        """
        Appends something to a dict of lists. If the key is not present in
        the dict then a single element is added to it.

        Args:
            map_dict:
            map_key:
            map_item:

        Returns:

        """

        if map_key not in map_dict:
            map_dict[map_key] = [map_item]
        else:
            map_dict[map_key].append(map_item)

    def build_tile_type_pkey_map(self):
        """
        Builds a forward and backward correspondence map of tile types
        as pkeys.
        """

        c = self.sql_db.cursor()

        # Built tile type map
        fwd_map = {}
        bwd_map = {}

        for tile_type in self.tile_types_to_split:

            # Get the physical tile type pkey
            tile_type_pkey = c.execute("SELECT pkey FROM tile_type WHERE name = (?)", (tile_type,)).fetchone()[0]

            # Insert corresponding VPR tile type pkeys
            fwd_map[tile_type_pkey] = []
            for site_type, site_ofs in self.get_tile_type_sites(tile_type):

                # Get new tile type pkey from site name
                new_tile_type_pkey = c.execute("SELECT pkey FROM tile_type WHERE name = (?)", (site_type,)).fetchone()[0]

                # Get the site instance pkey from site name and offset
                #site_pkey = c.execute("SELECT pkey FROM site WHERE x_coord = (?) AND y_coord = (?) AND site_type_pkey = (SELECT pkey FROM site_type WHERE name = (?))", (site_ofs[0], site_ofs[1], site_type, )).fetchone()[0]

                fwd_map[tile_type_pkey].append((new_tile_type_pkey, site_ofs))
                bwd_map[new_tile_type_pkey] = [tile_type_pkey]

        # Return forward and backward mapping.
        return fwd_map, bwd_map

    def build_tile_wire_names_map(self, tile_type):
        """
        Builds a map which holds information about which wires are relevant
        for particular site (new tile type). Wires which do not have any
        sites/pips are included for all sites.

        Args:
            tile_type: Tile type string

        Returns:

        """

        #print(tile_type)

        fwd_map = {}

        # Get the tile type object and its site objects
        tile_type_obj = self.prjxray_db.get_tile_type(tile_type)
        site_objs = tile_type_obj.get_sites()

        # Get list of all site wires
        site_wires = {}
        for site_obj in site_objs:
            site_wires[site_obj.name] = [pin.wire for pin in site_obj.site_pins]

        # Loop through all tile wires
        for wire in tile_type_obj.get_wires():
            wire_info = tile_type_obj.get_wire_info(wire, allow_pseudo=False)
            #print(wire, wire_info.pips, wire_info.sites)

            # The wire has no pips and sites. It is a passthrough one which
            # should appear in all new tile types after CLB split.
            if len(wire_info.pips) == 0 and len(wire_info.sites) == 0:
                for site_obj in site_objs:
                    self.append_to_map(fwd_map, wire, site_obj.name)

            # The wire is relevant to a particular site(s) and pip(s).
            else:

                # The wire goes directly to site(s)
                for site_name, site_pin in wire_info.sites:
                    self.append_to_map(fwd_map, wire, site_name)

                # The wire goes to a pip(s)
                for pip_name in wire_info.pips:
                    pip_obj = tile_type_obj.get_pip_by_name(pip_name)

                    # If the pip is connected to a site then the wire
                    # is also relevant for that site
                    for site_name, wires in site_wires.items():

                        # FIXME: It is assumed here that there can be only one
                        # pip between a tile wire and a site. This is true
                        # for 7-series CLBs.

                        if pip_obj.net_to in wires or \
                           pip_obj.net_from in wires:
                            self.append_to_map(fwd_map, wire, site_name)

            # Remove duplicates
            fwd_map[wire] = list(set(fwd_map[wire]))

        # Return maps
        return fwd_map, None

    def split(self):
        """
        Performs the tile split
        """

        # TODO: I plan to use this class here for generating pb_type XMLs for
        # the arch.xml

        # Insert new tile types
        self.insert_new_tile_types()

        # Build tile type pkey map
        fwd_map, bwd_map = self.build_tile_type_pkey_map()
        self.tile_type_pkey_map = GenericMap(fwd_map, bwd_map)

        # Build tile wire map
        self.tile_wire_name_map = {}
        for tile_type in self.tile_types_to_split:
            fwd_map, _ = self.build_tile_wire_names_map(tile_type)
            self.tile_wire_name_map[tile_type] = GenericMap(fwd_map, None)

            #for k, v in fwd_map.items():
            #    print(tile_type, k, v)

        # Insert wires and pips for new tile types
        self.insert_new_tile_wires()

        # Return the map
        return self.tile_type_pkey_map, self.tile_wire_name_map

# =============================================================================


if __name__ == "__main__":

    db = "/home/mkurc/Repos/google-symbiflow-arch-defs/build/xc7/archs/artix7/devices/xc7a50t-basys3-roi-virt/channels.db"
    db_conn = sqlite3.Connection(db)

    ts = TileSplitter(db_conn)
    ts.set_tile_types_to_split(["CLBLL_L", "CLBLL_R", "CLBLM_L", "CLBLM_R"])

    ts.split()

    #for x in ts.get_unique_site_types():
    #    print(x)
