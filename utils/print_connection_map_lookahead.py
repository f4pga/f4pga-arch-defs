""" Print connection map lookahead in human readable format. """

import argparse
import capnp
import os.path

# Remove magic import hook.
capnp.remove_import_hook()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        '--schema_path', help='Path to connection map schema', required=True
    )
    parser.add_argument('--lookahead_map', required=True)

    args = parser.parse_args()

    connection_map = capnp.load(
        os.path.join(args.schema_path, 'connection_map.capnp')
    )

    with open(args.lookahead_map, 'rb') as f:
        cost_map = connection_map.VprCostMap.read(f)

    assert cost_map.costMap.dims[0] == cost_map.offset.dims[0]
    assert cost_map.costMap.dims[1] == cost_map.offset.dims[1]
    nsegment = cost_map.costMap.dims[0]
    nconnection_box = cost_map.costMap.dims[1]

    m_itr = iter(cost_map.costMap.data)
    offset_itr = iter(cost_map.offset.data)
    for segment in range(nsegment):
        for connection_box in range(nconnection_box):
            m = next(m_itr).value
            offset = next(offset_itr).value

            x_off = offset.x
            y_off = offset.y

            assert len(m.dims) == 2
            x_dim = m.dims[0]
            y_dim = m.dims[1]

            print(
                'Cost map for segment {} connection box {} (size {}, {}, offset {}, {})'
                .format(segment, connection_box, x_dim, y_dim, x_off, y_off)
            )

            itr = iter(m.data)

            for x in range(x_dim):
                for y in range(y_dim):
                    value = next(itr)
                    print(
                        '({}, {}) = {{ delay = {}, congestion = {} }}'.format(
                            x + x_off,
                            y + y_off,
                            value.value.delay,
                            value.value.congestion,
                        )
                    )


if __name__ == "__main__":
    main()
