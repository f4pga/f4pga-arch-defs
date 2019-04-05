#!/usr/bin/env python3

import os
import os.path

def write_deps(inputfile_name, data):
    deps_filename = deps_makefile(inputfile_name)
    with open(deps_filename, "w") as f:
        f.write(data.getvalue())
    print("Generated dependency info", deps_filename)


if __name__ == "__main__":
    import doctest
    doctest.testmod()
