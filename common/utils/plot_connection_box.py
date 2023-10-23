#!/usr/bin/env python3
""" Plot a connection box delay matrix using matplotlib. """
import argparse
from lib.connection_box_tools import load_connection_box, \
    iterate_connection_box, connection_box_to_numpy

import matplotlib.pyplot as plt
from matplotlib.colors import BoundaryNorm
from matplotlib.ticker import MaxNLocator


def get_connection_box(cost_map, segment, connection_box):
    for segment_idx, connection_box_idx, offset, m in iterate_connection_box(
            cost_map):
        if segment == segment_idx and connection_box_idx == connection_box:
            return offset, m


def plot_connection_box(cost_map, segment, connection_box):
    offset, m = get_connection_box(cost_map, segment, connection_box)

    x, y, delay, congestion = connection_box_to_numpy(offset, m)

    print(delay)

    # x and y are bounds, so z should be the value *inside* those bounds.
    # Therefore, remove the last value from the z array.
    delay_levels = MaxNLocator(nbins=50).tick_values(delay.min(), delay.max())

    # pick the desired colormap, sensible levels, and define a normalization
    # instance which takes data values and translates those into levels.
    cmap = plt.get_cmap('PiYG')
    norm = BoundaryNorm(delay_levels, ncolors=cmap.N, clip=True)

    fig, (ax0, ax1) = plt.subplots(nrows=2)

    im = ax0.pcolormesh(x, y, delay, cmap=cmap, norm=norm)
    ax0.autoscale(False)  # To avoid that the scatter changes limits
    inf_idx = delay == float('inf')
    ax0.scatter(x[inf_idx], y[inf_idx])
    fig.colorbar(im, ax=ax0)
    ax0.set_title('pcolormesh with levels')

    # contours are *point* based plots, so convert our bound into point
    # centers
    cf = ax1.contourf(
        x + 1. / 2., y + 1. / 2., delay, levels=delay_levels, cmap=cmap
    )
    fig.colorbar(cf, ax=ax1)
    ax1.set_title('contourf with levels')

    # adjust spacing between subplots so `ax1` title and `ax0` tick labels
    # don't overlap
    fig.tight_layout()

    plt.show()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        '--schema_path', help='Path to connection map schema', required=True
    )
    parser.add_argument('--lookahead_map', required=True)
    parser.add_argument('--segment', required=True, type=int)
    parser.add_argument('--connection_box', required=True, type=int)

    args = parser.parse_args()

    with open(args.lookahead_map, 'rb') as f:
        cost_map = load_connection_box(args.schema_path, f)

    plot_connection_box(cost_map, args.segment, args.connection_box)


if __name__ == "__main__":
    main()
