import argparse
import capnp
import os.path

import matplotlib.pyplot as plt
from matplotlib.colors import BoundaryNorm
from matplotlib.ticker import MaxNLocator
import numpy as np


def get_connection_box(cost_map, segment, connection_box):
    assert cost_map.costMap.dims[0] == cost_map.offset.dims[0]
    assert cost_map.costMap.dims[1] == cost_map.offset.dims[1]
    nsegment = cost_map.costMap.dims[0]
    nconnection_box = cost_map.costMap.dims[1]

    m_itr = iter(cost_map.costMap.data)
    offset_itr = iter(cost_map.offset.data)
    for segment_idx in range(nsegment):
        for connection_box_idx in range(nconnection_box):
            m = next(m_itr).value
            offset = next(offset_itr).value

            x_off = offset.x
            y_off = offset.y

            if segment == segment_idx and connection_box_idx == connection_box:
                return m, (x_off, y_off)


def plot_connection_box(cost_map, segment, connection_box):
    m, (x_off, y_off) = get_connection_box(cost_map, segment, connection_box)

    assert len(m.dims) == 2
    x_dim = m.dims[0]
    y_dim = m.dims[1]

    # generate 2 2d grids for the x & y bounds
    y, x = np.mgrid[slice(y_off, y_off + y_dim), slice(x_off, x_off + x_dim)]

    delay = np.zeros((y_dim, x_dim))
    congestion = np.zeros((y_dim, x_dim))

    itr = iter(m.data)

    for x_idx in range(x_dim):
        for y_idx in range(y_dim):
            value = next(itr)

            x_val = x_idx + x_off
            y_val = y_idx + y_off
            delay[(x == x_val) & (y == y_val)] = value.value.delay
            congestion[(x == x_val) & (y == y_val)] = value.value.congestion

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

    connection_map = capnp.load(
        os.path.join(args.schema_path, 'connection_map.capnp')
    )

    with open(args.lookahead_map, 'rb') as f:
        cost_map = connection_map.VprCostMap.read(
            f, traversal_limit_in_words=1024 * 1024 * 1024
        )

    plot_connection_box(cost_map, args.segment, args.connection_box)


if __name__ == "__main__":
    main()
