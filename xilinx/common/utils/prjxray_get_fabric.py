""" Prints the fabric of a part. """
import argparse
import prjxray.db


def main():
    parser = argparse.ArgumentParser(description=__doc__)

    parser.add_argument('--db_root', required=True)
    parser.add_argument('--part', required=True)
    parser.add_argument('-cmake', action='store_true')

    args = parser.parse_args()

    db = prjxray.db.Database(args.db_root, args.part)
    if args.cmake:
        print(db.fabric)
    else:
        print("Fabric: {}".format(db.fabric))


if __name__ == "__main__":
    main()
