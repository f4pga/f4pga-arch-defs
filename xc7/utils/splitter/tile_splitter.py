import sqlite3

from lib.grid_mapping import GenericMap

# =============================================================================


class TileSplitter(object):

    def __init__(self, prjxray_db, sql_db):
        self.prjxray_db = prjxray_db
        self.sql_db = sql_db

        self.tile_types_to_split = []
        self.tile_site_pkeys = {}

    def set_tile_types_to_split(self, tile_types):
        """
        Set tile types to split
        """
        self.tile_types_to_split = tile_types

    @staticmethod
    def append_to_map(map_dict, map_key, map_item):
        """
        Appends something to a dict of lists. If the key is not present in
        the dict then a single element is added to it.

        Args:
            map_dict:
            map_key:
            map_item:
        """

        if map_key not in map_dict:
            map_dict[map_key] = [map_item]
        else:
            map_dict[map_key].append(map_item)

    @staticmethod
    def append_to_unique_map(map_dict, map_key, map_item):
        """
        Basically adds a item to a dictionary but also checks whether there
        isn't anything different already there.

        Args:
            map_dict:
            map_key:
            map_item:
        """

        if map_key not in map_dict:
            map_dict[map_key] = map_item

        elif map_dict[map_key] != map_item:
            raise RuntimeError("A map entry for '{}' already exists".format(str(map_key)))

    def get_tile_type_sites(self, tile_type_pkey):
        """
        Returns all site types and their offsets for a given tile type
        """

        c = self.sql_db.cursor()

        # Get tile type sites
        sites = c.execute("SELECT site_type.name, site.name, site.x_coord, site.y_coord, site.pkey FROM site INNER JOIN site_type ON site.site_type_pkey = site_type.pkey WHERE site.pkey IN (SELECT site_pkey FROM wire_in_tile WHERE tile_type_pkey = (?) AND site_pkey IS NOT NULL)", (tile_type_pkey,)).fetchall()

        # Sort sites by X coordinate
        sites = sorted(sites, key=lambda s: s[2])
        sites = [(s[0], s[1], (s[2], s[3]), s[4]) for s in sites]

        return sites

    def build_pip_wire_map(self, tile_type_pkey):
        """
        Generates two dictionaries. The first is indexed with src wire pkeys
        while holding dst wire pkeys, the other vice versa.
        Also generates third dictionary indexed by wire pkeys which holds
        pip pkeys.

        Args:
            tile_type_pkey:

        Returns: pip_src_to_dst, pip_dst_to_src, wire_pip_map
        """

        c = self.sql_db.cursor()

        # Build pip wire map
        pip_src_to_dst = {}
        pip_dst_to_src = {}
        wire_pip_map = {}

        for pip_pkey, src_wire_in_tile_pkey, dst_wire_in_tile_pkey in c.execute("SELECT pkey, src_wire_in_tile_pkey, dest_wire_in_tile_pkey FROM pip_in_tile WHERE tile_type_pkey = (?)", (tile_type_pkey,)):

            pip_src_to_dst[src_wire_in_tile_pkey] = dst_wire_in_tile_pkey
            pip_dst_to_src[dst_wire_in_tile_pkey] = src_wire_in_tile_pkey

            if pip_pkey is not None:
                self.append_to_map(wire_pip_map, src_wire_in_tile_pkey, pip_pkey)
                self.append_to_map(wire_pip_map, dst_wire_in_tile_pkey, pip_pkey)

        # Remove repetitions from the map
        for key in wire_pip_map.keys():
            val = list(set(wire_pip_map[key]))
            wire_pip_map[key] = val

        return pip_src_to_dst, pip_dst_to_src, wire_pip_map

    def build_site_wire_and_pip_map(self, tile_type_pkey):
        """
        Generates wire to site and pip to site maps

        Args:
            tile_type_pkey:

        Returns: site_wire_map, site_pip_map
        """

        c = self.sql_db.cursor()

        # Get sites and their pkeys
        sites = self.get_tile_type_sites(tile_type_pkey)
        site_pkeys = [s[3] for s in sites]

        site_wire_map = {}
        site_pip_map = {}

        # Build pip wire maps
        pip_src_to_dst, pip_dst_to_src, wire_pip_map = self.build_pip_wire_map(tile_type_pkey)

        # Iterate over all tile wires
        for wire_pkey, wire_site_pkey in c.execute("SELECT pkey, site_pkey FROM wire_in_tile WHERE tile_type_pkey = (?)", (tile_type_pkey, )):
            is_free = True

            # The wire goes directly to a site
            if wire_site_pkey in site_pkeys:
                is_free = False
                self.append_to_unique_map(site_wire_map, wire_pkey, wire_site_pkey)

            # The wire does go to a pip(s)
            if wire_pkey in wire_pip_map.keys():
                is_free = False
                for pip_pkey in wire_pip_map[wire_pkey]:

                    # Get wire which is on the other side of that pip
                    other_wire_pkey = None
                    if wire_pkey in pip_src_to_dst.keys():
                        other_wire_pkey = pip_src_to_dst[wire_pkey]
                    if wire_pkey in pip_dst_to_src.keys():
                        other_wire_pkey = pip_dst_to_src[wire_pkey]

                    assert other_wire_pkey is not None

                    # Check if the other wire goes to a site
                    c2 = self.sql_db.cursor()
                    other_wire_site_pkey = c2.execute("SELECT site_pkey FROM wire_in_tile WHERE pkey = (?)", (other_wire_pkey,)).fetchone()

                    assert other_wire_site_pkey is not None
                    other_wire_site_pkey = other_wire_site_pkey[0]

                    if other_wire_site_pkey is not None:

                        # Append to maps
                        self.append_to_unique_map(site_wire_map, wire_pkey, other_wire_site_pkey)
                        self.append_to_unique_map(site_pip_map,  pip_pkey,  other_wire_site_pkey)

            # This is a "free" wire which does not go to neither to a site
            # not to a pip.
            if is_free:
                self.append_to_unique_map(site_wire_map, wire_pkey, None)

        # Return maps
        return site_wire_map, site_pip_map

    # .........................................................................

    def split_tiles(self):
        """
        Splits the tiles by generating new tile types and inserting them into
        the database.

        Returns:
        """

        c = self.sql_db.cursor()

        fwd_map = {}
        bwd_map = {}

        # For each tile to split
        for tile_type in self.tile_types_to_split:

            # Get tile type pkey
            tile_type_pkey = c.execute("SELECT pkey FROM tile_type WHERE name = (?)", (tile_type,)).fetchone()[0]

            # Get sites
            sites = self.get_tile_type_sites(tile_type_pkey)

            # Generate new tile types
            for site_type, site_name, site_loc, site_pkey in sites:
                new_tile_type = "{}_{}_{}".format(tile_type, site_type, site_name)

                # Insert new tile type
                c.execute("INSERT INTO tile_type(name) VALUES (?)", (new_tile_type, ))
                new_tile_type_pkey = c.lastrowid

                # Insert new tile type as it should appear in the VPR
                c.execute("INSERT INTO vpr_tile_type(name, tile_type_pkey) VALUES (?, ?)", (site_type, new_tile_type_pkey))
                vpr_tile_pkey = c.lastrowid

                print("{} -> {} -> {}".format(tile_type, new_tile_type, site_type))

                # Tile type map
                self.append_to_map(fwd_map, tile_type, new_tile_type)
                self.append_to_map(bwd_map, new_tile_type, tile_type)

                # Internal map with tile to site type and site loc.
                self.append_to_map(self.tile_site_pkeys, tile_type, (new_tile_type_pkey, vpr_tile_pkey, site_pkey))

        return GenericMap(fwd_map, bwd_map)

    def remap_tile_wires_and_pips(self):
        """
        Remaps tile wires from CLBs to corresponding SLICEs

        Returns:
        """

        c  = self.sql_db.cursor()
        c2 = self.sql_db.cursor()

        # Initialize pkey maps for wires and pips
        wire_pkey_map = {}
        pip_pkey_map  = {}

        # For each tile to split
        for tile_type in self.tile_types_to_split:

            # Get tile type pkey
            tile_type_pkey = c.execute("SELECT pkey FROM tile_type WHERE name = (?)", (tile_type,)).fetchone()[0]

            # Build site wire and pip map
            site_wire_map, site_pip_map = self.build_site_wire_and_pip_map(tile_type_pkey)
            # DEBUG
            #self._debug_dump_wire_and_pip_map(tile_type_pkey, site_wire_map, site_pip_map)

            # Copy tile wires to new tile types
            for new_tile_type_pkey, vpr_tile_pkey, site_pkey in self.tile_site_pkeys[tile_type]:

                # Remap all tile wires relevant to the new_tile_type_pkey, when doing this create a map for pkeys.
                itr = c.execute("SELECT pkey, name, site_pin_pkey FROM wire_in_tile WHERE tile_type_pkey = (?)", (tile_type_pkey,))
                for pkey, name, site_pin_pkey in itr:

                    # The wire is relevant to a site
                    if site_wire_map[pkey] == site_pkey:
                        #print("{}->{} wire {}:{} -> site {}".format(tile_type_pkey, new_tile_type_pkey, pkey, name, site_pkey))

                        c2.execute("INSERT INTO wire_in_tile(name, tile_type_pkey, site_pkey, site_pin_pkey) VALUES (?, ?, ?, ?)",
                                   (name, new_tile_type_pkey, site_pkey, site_pin_pkey))

                        self.append_to_map(wire_pkey_map, pkey, c2.lastrowid)

                    # This is a free wire
                    elif site_wire_map[pkey] is None:
                        #print("{}->{} wire {}:{} -> site {}".format(tile_type_pkey, new_tile_type_pkey, pkey, name, site_pkey))

                        c2.execute("INSERT INTO wire_in_tile(name, tile_type_pkey, site_pkey, site_pin_pkey) VALUES (?, ?, ?, ?)",
                                   (name, new_tile_type_pkey, None, None))

                        self.append_to_map(wire_pkey_map, pkey, c2.lastrowid)

                # Remap all tile pips
                itr = c.execute("SELECT pkey, name, src_wire_in_tile_pkey, dest_wire_in_tile_pkey, can_invert, is_directional, is_pseudo FROM pip_in_tile WHERE tile_type_pkey = (?)", (tile_type_pkey,))
                for pkey, name, src_wire_in_tile_pkey, dest_wire_in_tile_pkey, can_invert, is_directional, is_pseudo in itr:

                    # We haven't remapped this pip
                    if pkey not in site_pip_map.keys():
                        raise RuntimeError("The pip '{}' (pkey={}) has not been remapped".format(name, pkey))

                    # The pip is relevant to a site
                    if site_pip_map[pkey] == site_pkey:

                        # There may not be multiple wire correspondencies for
                        # wires that go to a pip. Multiple correspondencies are
                        # only allowed for "free" wires.
                        src_wire = wire_pkey_map[src_wire_in_tile_pkey]
                        dst_wire = wire_pkey_map[dest_wire_in_tile_pkey]

                        assert len(src_wire) == 1
                        assert len(dst_wire) == 1

                        c2.execute("INSERT INTO pip_in_tile(name, tile_type_pkey, src_wire_in_tile_pkey, dest_wire_in_tile_pkey, can_invert, is_directional, is_pseudo) VALUES(?, ?, ?, ?, ?, ?, ?)",
                                   (name, new_tile_type_pkey, src_wire[0], dst_wire[0], can_invert, is_directional, is_pseudo))

                        self.append_to_unique_map(pip_pkey_map, pkey, c2.lastrowid)

    # .........................................................................

    def split(self):
        """
        Performs the tile split
        """

        # Split the tiles
        tile_type_map = self.split_tiles()

        # Remap tile wires and pips
        self.remap_tile_wires_and_pips()

        return tile_type_map

    # .........................................................................

    def _debug_dump_wire_and_pip_map(self, tile_type_pkey, site_wire_map, site_pip_map):

        c = self.sql_db.cursor()

        # Get tile type string
        tile_type = c.execute("SELECT name FROM tile_type WHERE pkey = (?)", (tile_type_pkey,)).fetchone()[0]

        print("== wire and pip map for '{}' ==".format(tile_type))

        # Site wires
        print("Wires:")
        for wire_pkey, site_pkey in site_wire_map.items():
            wire = c.execute("SELECT name FROM wire_in_tile WHERE pkey = (?)", (wire_pkey,)).fetchone()[0]

            # Site relevant wire
            if site_pkey is not None:
                site = c.execute("SELECT name FROM site WHERE pkey = (?)", (site_pkey,)).fetchone()[0]
                print(" {} {}.{}".format(site, tile_type, wire))

            # Free wire
            else:
                print(" ALL {}.{}".format(tile_type, wire))

        # Site pips
        print("Pips:")
        for pip_pkey, site_pkey in site_pip_map.items():

            # Query texts
            pip  = c.execute("SELECT name FROM pip_in_tile WHERE pkey = (?)", (pip_pkey,)).fetchone()[0]
            site = c.execute("SELECT name FROM site WHERE pkey = (?)", (site_pkey,)).fetchone()[0]

            print(" {} {}".format(site, pip))
