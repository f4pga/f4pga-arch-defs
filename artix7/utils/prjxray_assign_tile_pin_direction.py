""" Assign pin directions to all tile pins such that they point to the connecting channel or direct connection. """
import argparse
from collections import namedtuple
import prjxray.db
import prjxray.tile
import simplejson as json
from lib.rr_graph import tracks
import progressbar
import datetime

DirectConnection = namedtuple('DirectConnection', 'from_pin to_pin switch_name x_offset y_offset')

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument(
            '--db_root', help='Project X-Ray Database', required=True)
    parser.add_argument(
            '--channels', help='Input JSON defining channel assignments', required=True)
    parser.add_argument(
            '--pin_assignments', help='Output JSON assigning pins to tile types and direction connections', required=True)

    args = parser.parse_args()

    db = prjxray.db.Database(args.db_root)
    grid = db.grid()

    edge_assignments = {}

    wires_in_tile_types = set()

    for tile_type in db.get_tile_types():
        type_obj = db.get_tile_type(tile_type)

        for wire in type_obj.get_wires():
            wires_in_tile_types.add((tile_type, wire))

        for site in type_obj.get_sites():
            for site_pin in site.site_pins:
                if site_pin.wire is None:
                    continue

                key = (tile_type, site_pin.wire)
                assert key not in edge_assignments, key
                edge_assignments[key] = []

    print('{} Reading channel data'.format(datetime.datetime.now()))
    with open(args.channels) as f:
        channels = json.load(f)
    print('{} Done reading channel data'.format(datetime.datetime.now()))

    direct_connections = set()

    # Edges with mux should have one source tile and one destination_tile.
    # The pin from the source_tile should face the destination_tile.
    #
    # It is expected that all edges_with_mux will lies in a line (e.g. X only or
    # Y only).
    for edge_with_mux in progressbar.progressbar(channels['edges_with_mux']):
        source_tile = None
        source_tile_type = None
        source_wire = None
        destination_tile = None
        destination_tile_type = None
        destination_wire = None

        for tile, wire in edge_with_mux['source_node']:
            tileinfo = grid.gridinfo_at_tilename(tile)
            tile_type = db.get_tile_type(tileinfo.tile_type)
            wire_info = tile_type.get_wire_info(wire)

            if len(wire_info.sites) == 1:
                assert source_tile is None, (tile, wire, source_tile)
                source_tile = tile
                source_tile_type = tileinfo.tile_type
                source_wire = wire

        for tile, wire in edge_with_mux['destination_node']:
            tileinfo = grid.gridinfo_at_tilename(tile)
            tile_type = db.get_tile_type(tileinfo.tile_type)
            wire_info = tile_type.get_wire_info(wire)

            if len(wire_info.sites) == 1:
                assert destination_tile is None, (tile, wire, destination_tile, wire_info)
                destination_tile = tile
                destination_tile_type = tileinfo.tile_type
                destination_wire = wire

        assert source_tile is not None
        assert destination_tile is not None

        source_loc = grid.loc_of_tilename(source_tile)
        destination_loc = grid.loc_of_tilename(destination_tile)

        assert source_loc.grid_x == destination_loc.grid_x or source_loc.grid_y == destination_loc.grid_y, (source_tile, destination_tile, edge_with_mux['pip'])

        direct_connections.add(
                DirectConnection(
                        from_pin='{}.{}'.format(source_tile_type, source_wire),
                        to_pin='{}.{}'.format(destination_tile_type, destination_wire),
                        switch_name='routing',
                        x_offset=destination_loc.grid_x-source_loc.grid_x,
                        y_offset=destination_loc.grid_y-source_loc.grid_y,
                )
        )

        if destination_loc.grid_x == source_loc.grid_x:
            if destination_loc.grid_y > source_loc.grid_y:
                source_dir = tracks.Direction.TOP
                destination_dir = tracks.Direction.BOTTOM
            else:
                source_dir = tracks.Direction.BOTTOM
                destination_dir = tracks.Direction.TOP
        else:
            if destination_loc.grid_x > source_loc.grid_x:
                source_dir = tracks.Direction.RIGHT
                destination_dir = tracks.Direction.LEFT
            else:
                source_dir = tracks.Direction.LEFT
                destination_dir = tracks.Direction.RIGHT

        edge_assignments[(source_tile_type, source_wire)].append((source_dir,))
        edge_assignments[(destination_tile_type, destination_wire)].append((destination_dir,))

    wires_not_in_channels = {}
    for node in progressbar.progressbar(channels['node_not_in_channels']):
        reason = node['classification']

        for tile, wire in node['wires']:
            tileinfo = grid.gridinfo_at_tilename(tile)
            key = (tileinfo.tile_type, wire)

            # Sometimes nodes in particular tile instances are disconnected,
            # disregard classification changes if this is the case.
            if reason != 'NULL':
                if key not in wires_not_in_channels:
                    wires_not_in_channels[key] = reason
                else:
                    other_reason = wires_not_in_channels[key]
                    assert reason == other_reason, (tile, wire, reason, other_reason)

            if key in wires_in_tile_types:
                wires_in_tile_types.remove(key)

    # List of nodes that are channels.
    channel_nodes = []

    # Map of (tile, wire) to track.  This will be used to find channels for pips
    # that come from EDGES_TO_CHANNEL.
    channel_wires_to_tracks = {}

    # Generate track models and verify that wires are either in a channel
    # or not in a channel.
    for channel in progressbar.progressbar(channels['channels']):
        track_list = []
        for track in channel['tracks']:
            track_list.append(tracks.Track(**track))

        tracks_model = tracks.Tracks(track_list, channel['track_connections'])
        channel_nodes.append(tracks_model)

        for tile, wire in channel['wires']:
            tileinfo = grid.gridinfo_at_tilename(tile)
            key = (tileinfo.tile_type, wire)
            # Make sure all wires in channels always are in channels
            assert key not in wires_not_in_channels

            if key in wires_in_tile_types:
                wires_in_tile_types.remove(key)

            channel_wires_to_tracks[(tile, wire)] = tracks_model

    # Make sure all wires appear to have been assigned.
    assert len(wires_in_tile_types) == 0

    # Verify that all tracks are sane.
    for node in channel_nodes:
        node.verify_tracks()

    null_tile_wires = set()

    # Verify that all nodes that are classified as edges to channels have at
    # least one site, and at least one live connection to a channel.
    #
    # If no live connections from the node are present, this node should've
    # been marked as NULL during channel formation.
    for node in progressbar.progressbar(channels['node_not_in_channels']):
        reason = node['classification']

        assert reason != 'EDGE_WITH_SHORT'

        if reason == 'NULL':
            for tile, wire in node['wires']:
                tileinfo = grid.gridinfo_at_tilename(tile)
                tile_type = db.get_tile_type(tileinfo.tile_type)
                null_tile_wires.add((tileinfo.tile_type, wire))

        if reason == 'EDGES_TO_CHANNEL':

            num_sites = 0

            for tile, wire in node['wires']:
                tileinfo = grid.gridinfo_at_tilename(tile)
                loc = grid.loc_of_tilename(tile)
                tile_type = db.get_tile_type(tileinfo.tile_type)

                wire_info = tile_type.get_wire_info(wire)
                num_sites += len(wire_info.sites)
                for pip in wire_info.pips:
                    other_wire = prjxray.tile.get_other_wire_from_pip(tile_type.get_pip_by_name(pip), wire)

                    key = (tile, other_wire)
                    if key in channel_wires_to_tracks:
                        tracks_model = channel_wires_to_tracks[key]

                        if len(wire_info.sites) > 0:
                            available_pins = set(pin_dir for _, pin_dir in tracks_model.get_tracks_for_wire_at_coord((loc.grid_x, loc.grid_y)))
                            edge_assignments[(tileinfo.tile_type, wire)].append(available_pins)

    final_edge_assignments = {}
    for (tile_type, wire), available_pins in progressbar.progressbar(edge_assignments.items()):
        if len(available_pins) == 0:
            if (tile_type, wire) not in null_tile_wires:
                # TODO: Figure out what is going on with these wires.  Appear to
                # tile internal connections sometimes?
                print((tile_type, wire))

            final_edge_assignments[(tile_type, wire)] = [tracks.Direction.RIGHT]
            continue

        pins = set(available_pins[0])
        for p in available_pins[1:]:
            pins &= set(p)

        if len(pins) > 0:
            final_edge_assignments[(tile_type, wire)] = [list(pins)[0]]
        else:
            # More than 2 pins are required, final the minimal number of pins
            pins = set()
            for p in available_pins:
                pins |= set(p)

            while len(pins) > 2:
                pins = list(pins)

                prev_len = len(pins)

                for idx in range(len(pins)):
                    pins_subset = list(pins)
                    del pins_subset[idx]

                    pins_subset = set(pins_subset)

                    bad_subset = False
                    for p in available_pins:
                        if len(pins_subset & set(p)) == 0:
                            bad_subset = True
                            break

                    if not bad_subset:
                        pins = list(pins_subset)
                        break

                # Failed to remove any pins, stop.
                if len(pins) == prev_len:
                    break

            final_edge_assignments[(tile_type, wire)] = pins

    for (tile_type, wire), available_pins in edge_assignments.items():
        pins = set(final_edge_assignments[(tile_type, wire)])

        for required_pins in available_pins:
            assert len(pins & set(required_pins)) > 0, (
                    tile_type, wire, pins, required_pins)

    pin_directions = {}
    for (tile_type, wire), pins in final_edge_assignments.items():
        if tile_type not in pin_directions:
            pin_directions[tile_type] = {}

        pin_directions[tile_type][wire] = [pin._name_ for pin in pins]

    with open(args.pin_assignments, 'w') as f:
        json.dump({
            'pin_directions': pin_directions,
            'direct_connections': [d._asdict() for d in direct_connections],
        }, f, indent=2)

if __name__ == '__main__':
    main()
