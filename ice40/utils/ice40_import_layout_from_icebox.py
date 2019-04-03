#!/usr/bin/env python3

import sys
import os
import lxml.etree as ET

import icebox

from ice40_list_layout_in_icebox import versions


def vpr_pos(x, y):
    return x + 2, y + 2


def get_corner_tiles(ic):
    corner_tiles = set()
    for x in (0, ic.max_x):
        for y in (0, ic.max_y):
            corner_tiles.add((x, y))
    return corner_tiles


def add_metadata(parent_xml, key, value):
    metadata_xml = parent_xml.find("./metadata")
    if metadata_xml is None:
        metadata_xml = ET.SubElement(parent_xml, "metadata")

    m = ET.SubElement(metadata_xml, "meta", {"name": str(key)})
    m.text = str(value)


def add_tile(layout_xml, type_name, pos):
    return ET.SubElement(
        layout_xml, "single", {
            'type': type_name,
            'x': str(pos[0]),
            'y': str(pos[1]),
            'priority': '1'
        }
    )


SKIP = []

for name, pins in icebox.pinloc_db.items():
    part, package = name.split('-')
    if ':' in package:
        continue
    #if part != "1k":
    #    continue
    pin_locs = {}
    for name, x, y, z in pins:
        if (x, y) not in pin_locs:
            pin_locs[(x, y)] = {}
        pin_locs[(x, y)][z] = name

    ic = icebox.iceconfig()
    getattr(ic, "setup_empty_{}".format(part))()

    def edge_blocks(x, y):
        p = [[0, 0], [0, 0], [0, 0]]
        if x == 0:
            p[0][0] -= 1
            p[1][0] -= 1
        if x == ic.max_x:
            p[0][0] += 1
            p[1][0] += 1
        if y == 0:
            p[1][1] -= 1
            p[2][1] -= 1
        if y == ic.max_y:
            p[1][1] += 1
            p[2][1] += 1
        p = set(tuple(x) for x in p)
        try:
            p.remove((0, 0))
        except KeyError:
            pass
        return tuple(p)

    def find_fabric_glb_netwk(x, y):
        fabric_glb_network = ""
        for gx, gy, gn in ic.gbufin_db():
            if (gx, gy) == (x, y):
                fabric_glb_network = "glb_netwk_{}".format(gn)
        return fabric_glb_network

    def tile_type(x, y):
        tt = ic.tile_type(x, y)

        if tt == "IO":
            fasm_prefix = ""
            for z in range(2):
                fasm_prefix += "{}_X{:d}_Y{:d}.IOB_{:d} ".format(tt, x, y, z)
        else:
            fasm_prefix = "{}_X{:d}_Y{:d}".format(tt, x, y)

        metadata = {
            'hlc_coord': "{:d} {:d}".format(x, y),
            "fasm_prefix": fasm_prefix
        }
        if (x, y) in get_corner_tiles(ic):
            return None, {}
        if tt == "RAMB":
            return "BLK_TL-RAM", metadata
        if tt == "RAMT":
            return SKIP, {}
        if tt.startswith("DSP"):
            if tt.endswith("0"):
                return "BLK_TL-DSP", metadata
            return SKIP, {}
        if tt == "IO":
            padin = ic.padin_pio_db()

            details = []
            for z in (0, 1):
                try:
                    metadata["hlc_global_io:{}".format(z)
                             ] = "glb_netwk_{}".format(padin.index((x, y, z)))
                    metadata["hlc_global_fabric:{}".format(z)
                             ] = find_fabric_glb_netwk(x, y)
                    tt = "GPIO{}".format(z)
                except ValueError:
                    pass

                name = ""
                if (x, y) in pin_locs:
                    tile = pin_locs[(x, y)]
                    if z in tile:
                        name = tile[z]

                if (x, y) in ic.iolatch_db():
                    metadata["hlc_latch_io"] = z

                print(
                    "(%2d,%2d)-%d i:%12s f:%12s l:%2s n:%s" % (
                        x, y, z,
                        metadata.get("hlc_global_io:{}".format(z), ""),
                        metadata.get("hlc_global_fabric:{}".format(z), ""),
                        metadata.get("hlc_latch_io", ""), name
                    )
                )
            return "BLK_TL-PIO", metadata
        if tt == "LOGIC":
            return "BLK_TL-PLB", metadata
        return None, {}
        assert False, tt

    for version in versions(part):
        layout_xml = ET.Element(
            "fixed_layout", {
                'name': '{}-{}'.format(version, package),
                'width': str(ic.max_x + 4 + 1),
                'height': str(ic.max_y + 4 + 1),
            }
        )

        pin_map = {}
        for x in range(0, ic.max_x + 1):
            for y in range(0, ic.max_y + 1):
                ipos = (x, y)
                vpos = vpr_pos(*ipos)

                tt, metadata = tile_type(*ipos)
                if tt is not None:
                    if tt is not SKIP:
                        tile_xml = add_tile(layout_xml, tt, vpos)
                else:
                    tile_xml = add_tile(layout_xml, "EMPTY", vpos)

                for k, v in metadata.items():
                    add_metadata(tile_xml, k, str(v))

                eposes = edge_blocks(x, y)
                #print(vpos, eposes)
                for e in eposes:
                    pad_xml = add_tile(
                        layout_xml, "EMPTY",
                        (vpos[0] + e[0] * 2, vpos[1] + e[1] * 2)
                    )

                    pin_pos = vpos[0] + e[0] * 1, vpos[1] + e[1] * 1
                    if ipos in pin_locs:
                        pin_xml = add_tile(layout_xml, "EMPTY", pin_pos)
                        for z, name in pin_locs[ipos].items():
                            add_metadata(pin_xml, "hlc_pin:{}".format(z), name)
                            pin_map[(*vpos, z)] = name
                    else:
                        pin_xml = add_tile(layout_xml, "EMPTY", pin_pos)

                    add_metadata(
                        pin_xml, "hlc_coord",
                        "{} {}".format(x + e[0], y + e[1])
                    )

        with open("{}.{}.fixed_layout.xml".format(version, package),
                  "wb+") as f:
            f.write(ET.tostring(layout_xml, pretty_print=True))

        def i(x):
            try:
                return int(x)
            except ValueError:
                return x

        lines = [(i(v), *k) for k, v in pin_map.items()]
        with open("{}.{}.pinmap.csv".format(version, package), "wb+") as f:
            f.write("name,x,y,z\n".format(*k, v).encode("utf-8"))
            for i in sorted(lines):
                f.write("{},{},{},{}\n".format(*i).encode("utf-8"))
