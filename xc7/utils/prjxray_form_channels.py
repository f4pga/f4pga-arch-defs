#!/usr/bin/env python3
""" Classify 7-series nodes and generate channels for required nodes. """

import argparse
import prjxray.db
from collections import namedtuple
import progressbar
import simplejson as json
from lib.rr_graph import points
from lib.rr_graph import tracks

EdgeWithMux = namedtuple('EdgeWithMux', 'source_node pip destination_node')
NodeClassification = namedtuple('NodeClassification', 'type edge_with_mux')

def full_wire_name(wire_in_grid):
    return (wire_in_grid.tile, wire_in_grid.wire)


def make_connection(wires, connection):
    wire_a = full_wire_name(connection.wire_a)
    wire_b = full_wire_name(connection.wire_b)

    wire_a_set = wires[wire_a]
    wire_b_set = wires[wire_b]

    if wire_a_set is wire_b_set:
        return

    wire_a_set |= wire_b_set

    for wire in wire_a_set:
        wires[wire] = wire_a_set


def make_connections(db):
    # Some nodes are just 1 wire, so start by enumerating all wires.
    wires = {}
    grid = db.grid()
    for tile in progressbar.progressbar(grid.tiles()):
        gridinfo = grid.gridinfo_at_tilename(tile)
        tile_type = db.get_tile_type(gridinfo.tile_type)

        for wire in tile_type.get_wires():
            key = (tile, wire)
            wires[key] = set((key,))

    c = db.connections()

    for connection in progressbar.progressbar(c.get_connections()):
        make_connection(wires, connection)

    nodes = {}

    for wire_node in wires.values():
        nodes[id(wire_node)] = wire_node

    return nodes.values()

class Node(object):
    def __init__(self, node):
        self.node = node
        self.tracks = []
        self.track_connections = []
        self.wire_connections = {}

        self.sites = []
        self.pips = []
        self.classification = None

    def add_sites_and_pips_to_node(self, db, grid):
        for tile, wire in self.node:
            tileinfo = grid.gridinfo_at_tilename(tile)

            tile_type = db.get_tile_type(tileinfo.tile_type)

            wire_info = tile_type.get_wire_info(wire)

            for pip in wire_info.pips:
                self.pips.append((tile, pip, wire))

            for site in wire_info.sites:
                self.sites.append((tile,)+site)

    def classify_node(self, db, grid, wire_to_nodes):
        if len(self.pips) + len(self.sites) <= 1:
            # Some nodes don't go anywhere.
            return NodeClassification(type='NULL', edge_with_mux=None)

        if len(self.pips) == 1 and len(self.sites) == 0:
            # Some nodes don't go anywhere.
            return NodeClassification(type='NULL', edge_with_mux=None)

        if len(self.pips) > 1:
            if len(self.sites) == 0:
                return NodeClassification(type='CHANNEL', edge_with_mux=None)
            else:
                if len(self.sites) == 1:
                    return NodeClassification(type='EDGES_TO_CHANNEL', edge_with_mux=None)
                else:
                    assert False, (self.pips, self.sites, self.node)


        if len(self.sites) == 2 and len(self.pips) == 0:
            return NodeClassification(type='EDGE_WITH_SHORT', edge_with_mux=None)

        if len(self.sites) == 1 and len(self.pips) == 1:
            # This could be a site pin -> pip -> site pin, check.
            tile, pip, wire = self.pips[0]

            tileinfo = grid.gridinfo_at_tilename(tile)
            tile_type = db.get_tile_type(tileinfo.tile_type)

            for tile_pip in tile_type.get_pips():
                if tile_pip.name == pip:
                    if tile_pip.net_to == wire:
                        other_wire = tile_pip.net_from
                        other_node = wire_to_nodes[(tile, other_wire)]

                        source_node = other_node.node
                        destination_node = self.node
                    elif tile_pip.net_from == wire:
                        other_wire = tile_pip.net_to
                        other_node = wire_to_nodes[(tile, other_wire)]

                        source_node = self.node
                        destination_node = other_node.node
                    else:
                        assert False, (tile, pip, wire, tile_pip)

                    if len(other_node.sites) == 1 and len(other_node.pips) == 1:
                        edge_with_mux = EdgeWithMux(
                            source_node = tuple(sorted(source_node)),
                            pip = pip,
                            destination_node = tuple(sorted(destination_node)),
                        )
                        return NodeClassification(type='EDGE_WITH_MUX', edge_with_mux=edge_with_mux)
                    elif len(other_node.sites) == 0 and len(other_node.pips) == 1:
                        # Sometimes (e.g. top of carry chain) will end up with
                        # site pin -> pip -> nothing.
                        return NodeClassification(type='NULL', edge_with_mux=None)
                    else:
                        break

            # This node is an edge to/from a channel, but not a
            # channel itself.
            return NodeClassification(type='EDGES_TO_CHANNEL', edge_with_mux=None)

        assert False, (self.pips, self.sites, self.node)

    def form_tracks(self, grid):
        connected_tiles = set()
        for tile, wire in self.node:
            connected_tiles.add(grid.loc_of_tilename(tile))

        unique_pos = set()
        for tile, wire in self.node:
            loc = grid.loc_of_tilename(tile)
            unique_pos.add((loc.grid_x, loc.grid_y))

        xs, ys = points.decompose_points_into_tracks(unique_pos)

        self.tracks, self.track_connections = tracks.make_tracks(xs, ys, unique_pos)
        self.wire_connections = {}
        self.tracks_model = tracks.Tracks(self.tracks, self.track_connections)
        for tile, wire in self.node:
            loc = grid.loc_of_tilename(tile)
            connections = list(self.tracks_model.get_tracks_for_wire_at_coord((loc.grid_x, loc.grid_y)))
            assert len(connections) > 0
            self.wire_connections[(tile, wire)] = connections[0][0]

    def _get_track_idx(self, tilewire):
        if self.wire_connections:
            assert tilewire in self.wire_connections
            assert self.wire_connections[tilewire] < len(self.tracks)
            return self.wire_connections[tilewire]
        else:
            assert len(self.tracks) == 1
            return 0

    def verify_tracks(self, grid):
        self.tracks_model.verify_tracks()

        # Check that all wires can be connected to the track specified by
        # _get_track.
        for tile, wire in self.node:
            track_idx = self._get_track_idx((tile, wire))
            loc = grid.loc_of_tilename(tile)
            assert self.tracks_model.is_wire_adjacent_to_track(track_idx, (loc.grid_x, loc.grid_y)) != tracks.Direction.NO_SIDE, (loc, track_idx, self.tracks[track_idx])

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument(
            '--db_root', help='Project X-Ray Database', required=True)
    parser.add_argument(
            '--channels', help='Project X-Ray Database', required=True)

    args = parser.parse_args()

    db = prjxray.db.Database(args.db_root)
    nodes = [Node(node) for node in make_connections(db)]
    grid = db.grid()
    wire_to_nodes = {}
    for node in progressbar.progressbar(nodes):
        node.add_sites_and_pips_to_node(db, grid)
        for wire in node.node:
            wire_to_nodes[wire] = node

    edges_with_mux = set()
    node_not_in_channels = []
    channels = []
    num_tracks = 0
    for node in progressbar.progressbar(nodes):
        node.classification = node.classify_node(db, grid, wire_to_nodes)

        if node.classification.type != 'CHANNEL':
            node_not_in_channels.append({
                    'classification': node.classification.type,
                    'wires': list(node.node),
            })
        else:
            node.form_tracks(grid)
            node.verify_tracks(grid)
            num_tracks += len(node.tracks)

            channels.append({
                    'wires': list(node.node),
                    'tracks': [track._asdict() for track in node.tracks],
                    'track_connections': node.track_connections,
            })

        if node.classification.type == 'EDGE_WITH_MUX':
            edges_with_mux.add(node.classification.edge_with_mux)

    print(num_tracks)

    with open(args.channels, 'w') as f:
        json.dump({
                'node_not_in_channels': node_not_in_channels,
                'edges_with_mux': [edge._asdict() for edge in list(edges_with_mux)],
                'channels': channels,
        }, f, indent=2)

if __name__ == '__main__':
    main()
