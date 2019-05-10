#!/usr/bin/env python3

from typing import List, Tuple, Union

from .pb_type import Port

SinglePinPortPinName = str  # "PortName" -- Will not have square brackets
MultiPinPortPinName = str  # "PortName[PinIndex]"


def flatten(ports: List[Port]) -> Tuple[Union[SinglePinPortPinName, MultiPinPortPinName], SinglePinPortPinName]:
    """Mapping from pins a list of ports to individual width ports pins.

    Parameters
    ----------
    ports
        List of ports to flatten, accepts both single pin ports as strings or
        multi-pin ports as a tuple of port name and port width.

    Yields
    -------
    (str, str)
        Mapping between original port pin names to single pin port names.

    >>> print(list(flatten(['A', ('B', 1), ('C', 2)])))
    [('A', 'A'), ('B', 'B'), ('C[0]', 'C0'), ('C[1]', 'C1')]
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
                src = "{}[{}]".format(n, i)
                dst = "{}{}".format(n, i)
                yield (src, dst)
