""" Print override delta delay placement model in human readable format. """

import argparse
import capnp
import os.path

# Remove magic import hook.
capnp.remove_import_hook()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        '--schema_path',
        help='Path to override delta delay placement model schema',
        required=True
    )
    parser.add_argument('--place_delay_matrix', required=True)

    args = parser.parse_args()

    place_delay_model = capnp.load(
        os.path.join(args.schema_path, 'place_delay_model.capnp')
    )

    with open(args.place_delay_matrix, 'rb') as f:
        delay_model = place_delay_model.VprOverrideDelayModel.read(f)

    x_dim = delay_model.delays.dims[0]
    y_dim = delay_model.delays.dims[1]
    itr = iter(delay_model.delays.data)
    for x in range(x_dim):
        row = []
        for y in range(y_dim):
            value = next(itr)
            row.append(str(value.value.value))

        print(','.join(row))


if __name__ == "__main__":
    main()
