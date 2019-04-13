import argparse
from lib.parse_route import find_net_sources


def main():
    parser = argparse.ArgumentParser(description="")

    parser.add_argument('route_file')

    args = parser.parse_args()

    with open(args.route_file) as f:
        for net, node in find_net_sources(f):
            print(net, node)


if __name__ == "__main__":
    main()
