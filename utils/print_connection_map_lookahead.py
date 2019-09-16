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

    for idx, (m, offset) in enumerate(zip(cost_map.costMap, cost_map.offset)):

        x_off = offset.x
        y_off = offset.y

        assert len(m.dims) == 2
        x_dim = m.dims[0]
        y_dim = m.dims[1]

        print(
            'Cost map for segment {} (size {}, {}, offset {}, {})'.format(
                idx, x_dim, y_dim, x_off, y_off
            )
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
