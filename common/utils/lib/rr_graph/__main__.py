#!/usr/bin/env python3
from .. import rr_graph

if __name__ == "__main__":
    import doctest
    failure_count, test_count = doctest.testmod(rr_graph)
    assert test_count > 0
    assert failure_count == 0, "Doctests failed!"
