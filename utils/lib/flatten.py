#!/usr/bin/env python3


def flatten(ports, reverse=False):
    """Convert port + width into individual pins.

    >>> print(list(flatten(['A', ('B', 1), ('C', 2)])))
    [('A', 'A'), ('B', 'B'), ('C0', 'C[0]'), ('C1', 'C[1]')]
    """
    for x in ports:
        if isinstance(x, tuple):
            n, bits = x
        else:
            n = x
            bits = 1

        if bits == 1:
            yield (n, n)
        else:
            for i in range(0, bits):
                src = "{}{}".format(n, i)
                dst = "{}[{}]".format(n, i)
                if reverse:
                    yield (dst, src)
                else:
                    yield (src, dst)
