import capnp
import os.path
import numpy as np

# Remove magic import hook.
capnp.remove_import_hook()


def load_connection_box(schema_path, f_lookahead_map):
    """ Read connection box delay map from provided file.close(

    Arguments
    ---------
    schema_path : str/Path-like
        Path to schema directory containing connection_map.capnp
    f_lookahead_map : file-like
        Binary file-like that contains connection box delay map data.
    """

    connection_map = capnp.load(
        os.path.join(schema_path, 'connection_map.capnp')
    )

    return connection_map.VprCostMap.read(
        f_lookahead_map, traversal_limit_in_words=1024 * 1024 * 1024
    )


def iterate_connection_box(cost_map):
    """ Iterate over connection boxes present in cost_map.

    Yields
    ------
    segment : int
        Segment ID.
    connection_box : int
        Connection box ID.
    offset : (int, int)
        dx/dy value for first element of cost matrix.
    m : Matrix capnp object
        Cost matrix in capnp.

    """
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

            yield segment_idx, connection_box_idx, (x_off, y_off), m


def connection_box_to_numpy(offset, m):
    """ Convert connection box offset and matrix into numpy arrays.

    Returns
    -------
    x : numpy.array of int
        X coordinate suitable for mesh/surface plotting of delay data
    y : numpy.array of int
        Y coordinate suitable for mesh/surface plotting of delay data
    delay : numpy.array of float
        Delay matrix in seconds
    congestion : numpy.array of float
        Congestion matrix.

    NOTE: First dimension is the y dimension, per numpy plotting convention.

    """
    x_off, y_off = offset

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
            delay[y_idx][x_idx] = value.value.delay
            congestion[y_idx][x_idx] = value.value.congestion
            assert x[y_idx][x_idx] == x_val
            assert y[y_idx][x_idx] == y_val

    return x, y, delay, congestion
