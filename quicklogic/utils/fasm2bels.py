#!/usr/bin/env python3
import argparse
import pickle
import re
from collections import defaultdict

import fasm

import sys
sys.path.append("../")
from data_structs import *

# =============================================================================

def decode_switchbox(switchbox, features):

    # Sort switchbox connecions by destinations
    conn_by_dst = defaultdict(lambda: set())
    for c in switchbox.connections:
        conn_by_dst[c.dst].add(c)

    # Prepare data structure
    mux_sel = {}
    for stage_id, stage in switchbox.stages.items():
        mux_sel[stage_id] = {}
        for switch_id, switch in stage.switches.items():
            mux_sel[stage_id][switch_id] = {}
            for mux_id, mux in switch.muxes.items():
                mux_sel[stage_id][switch_id][mux_id] = None

    # Decode mux settings
    for feature in features:

        # Skip unset features
        if feature.value == 0:
            continue

        # Decode HIGHWAY muxes
        match = re.match(r"^.*I_highway\.IM([0-9]+)\.I_pg([0-9]+)$", feature.feature)
        if match:
            stage_id    = 3  # FIXME: Get HIGHWAY stage id from the switchbox def!
            switch_id   = int(match.group(1))
            mux_id      = 0
            sel_id      = int(match.group(2))
        
#            print("HIGHWAY", stage_id, switch_id, mux_id, sel_id)

            assert mux_sel[stage_id][switch_id][mux_id] is None, ("HIGHWAY", stage_id, switch_id, mux_id, sel_id)
            mux_sel[stage_id][switch_id][mux_id] = sel_id

        # Decode STREET muxes
        match = re.match(r"^.*I_street\.Isb([0-9])([0-9])\.I_M([0-9]+)\.I_pg([0-9]+)$", feature.feature)
        if match:
            stage_id    = int(match.group(1)) - 1
            switch_id   = int(match.group(2)) - 1
            mux_id      = int(match.group(3))
            sel_id      = int(match.group(4))

#            print("STREET", stage_id, switch_id, mux_id, sel_id)

            assert mux_sel[stage_id][switch_id][mux_id] is None, ("STREET", stage_id, switch_id, mux_id, sel_id)
            mux_sel[stage_id][switch_id][mux_id] = sel_id

    def expand_mux(out_loc):
        """
        Expands a multiplexer output until a switchbox input is reached.
        Returns name of the input or None if not found.
        """

        # Get mux selection, If it is set to None then the mux is
        # not active
        sel = mux_sel[out_loc.stage_id][out_loc.switch_id][out_loc.mux_id]
        if sel is None:
            return None

        # Check if we have hit a top-level input
        stage  = switchbox.stages[out_loc.stage_id]
        switch = stage.switches[out_loc.switch_id]
        mux    = switch.muxes[out_loc.mux_id]
        pin    = mux.inputs[sel]

        if pin.name is not None:
            return pin.name

        # Make location of the mux input pin
        inp_loc = SwitchboxPinLoc(
            stage_id    = out_loc.stage_id,
            switch_id   = out_loc.switch_id,
            mux_id      = out_loc.mux_id,
            pin_id      = sel,
            pin_direction = PinDirection.INPUT
        )        

        # Expand all "upstream" muxes that connect to the selected
        # input pin
        assert inp_loc in conn_by_dst, inp_loc
        for c in conn_by_dst[inp_loc]:
            inp_name = expand_mux(c.src)
            if inp_name is not None:
                return inp_name

        # Nothing found
        return None

    # For each output pin of a switchbox determine tw which input is it
    # connected to.
    routes = {}
    for out_pin in switchbox.outputs.values():
        out_loc = out_pin.locs[0]
        routes[out_pin.name] = expand_mux(out_loc)

    return routes


def process_switchbox(loc, switchbox, features, connections_by_loc):

    # Decode switchbox routes
    routes = decode_switchbox(switchbox, features)

    # Find local connections
    

    # DEBUG
    for k,v in routes.items():
        if v is not None:
            print("X{}Y{} {:<10} <= {:<5}".format(loc.x, loc.y, k, v))

    # F2A_io_t_1  => IE
    # F2A_io_t_2  => INEN
    # F2A_io_t_4  => OQI
    # A2F_hop_t_1 <= IZ
    # A2F_hop_t_3 <= IZ

# =============================================================================

def main():
    
    # Parse arguments
    parser = argparse.ArgumentParser(description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter)

    parser.add_argument(
        "fasm_file",
        type=str,
        help="Input fasm file"
    )

    parser.add_argument(
        "--vpr-db",
        type=str,
        required=True,
        help="VPR database file"
    )

    args = parser.parse_args()

    # Load data from the database
    print("Loading database...")
    with open(args.vpr_db, "rb") as fp:
        db = pickle.load(fp)

#        cells_library  = db["cells_library"]
        loc_map        = db["loc_map"]
#        vpr_tile_types = db["vpr_tile_types"]
#        vpr_tile_grid  = db["vpr_tile_grid"]
        vpr_switchbox_types = db["vpr_switchbox_types"]
        vpr_switchbox_grid  = db["vpr_switchbox_grid"]
        connections    = db["connections"]

    # Load fasm features
    features_by_loc = defaultdict(lambda: set())
    for fasm_line in fasm.parse_fasm_filename(args.fasm_file):

        if not fasm_line.set_feature:
            continue

        # Decode loc
        parts = fasm_line.set_feature.feature.split(".", maxsplit=1)
        match = re.match(r"^X([0-9]+)Y([0-9]+)$", parts[0])
        assert match is not None, parts

        phy_loc = Loc(
            x=int(match.group(1)),
            y=int(match.group(2)),
        )

        # Store the feature
        features_by_loc[phy_loc].add(fasm_line.set_feature)

    # Sort connections by locations they mention
    connections_by_loc = defaultdict(lambda: [])
    for connection in connections:
        connections_by_loc[connection.dst].append(connections)
        connections_by_loc[connection.src].append(connections)

    # Process features
    keys = sorted(features_by_loc.keys(), key=lambda loc: (loc.x, loc.y))
    for phy_loc in keys:
        features = features_by_loc[phy_loc]

        # Map location to VPR coordinates
        if phy_loc not in loc_map.fwd:
            continue
        loc = loc_map.fwd[phy_loc]

        # Process the switchbox
        if loc in vpr_switchbox_grid:
            type      = vpr_switchbox_grid[loc]
            switchbox = vpr_switchbox_types[type]
            process_switchbox(loc, switchbox, features, connections_by_loc)
 

# =============================================================================

if __name__ == "__main__":
    main()
