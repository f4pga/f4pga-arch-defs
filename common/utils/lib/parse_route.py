""" Library for parsing route output from VPR route files. """
from collections import namedtuple

Node = namedtuple('Node', 'inode x_low y_low x_high y_high ptc')


def format_name(s):
    """ Converts VPR parenthesized name to just name. """
    assert s[0] == '('
    assert s[-1] == ')'
    return s[1:-1]


def format_coordinates(coord):
    """ Parses coordinates from VPR route file in format of (x,y). """
    coord = format_name(coord)
    x, y = coord.split(',')
    return int(x), int(y)


def find_net_sources(f):
    """ Yields tuple of (net string, Node namedtuple) from file object.

    File object should be formatted as VPR route output file.

    """
    net = None
    for e in f:
        tokens = e.strip().split()
        if not tokens:
            continue
        elif tokens[0][0] == '#':
            continue
        elif tokens[0] == 'Net':
            net = format_name(tokens[2])
        elif e == "\n\nUsed in local cluster only, reserved one CLB pin\n\n":
            continue
        else:
            if net is not None:
                inode = int(tokens[1])
                assert tokens[2] == 'SOURCE'

                x, y = format_coordinates(tokens[3])

                if tokens[4] == 'to':
                    x2, y2 = format_coordinates(tokens[5])
                    offset = 2
                else:
                    x2, y2 = x, y
                    offset = 0

                ptc = int(tokens[5 + offset])

                yield net, Node(inode, x, y, x2, y2, ptc)
                net = None
