#!/usr/bin/env python3
""" Print connection map lookahead in human readable format. """

import argparse
import capnp
from lib.connection_box_tools import load_connection_box, iterate_connection_box

# Remove magic import hook.
capnp.remove_import_hook()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        '--schema_path', help='Path to connection map schema', required=True
    )
    parser.add_argument('--lookahead_map', required=True)

    args = parser.parse_args()

    with open(args.lookahead_map, 'rb') as f:
        cost_map = load_connection_box(args.schema_path, f)

    for segment, connection_box, (
            x_off, y_off), m in iterate_connection_box(cost_map):
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
