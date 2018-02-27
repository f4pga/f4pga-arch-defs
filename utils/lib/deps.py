"""
This file needs to be kept in sync with ../../common/make/deps.mk
"""

import os
import os.path


DEPEXT=".d"


def makefile_dir(filepath):
    """
    >>> makefile_dir("blah1")
    ''
    >>> makefile_dir("a/blah2")
    'a/'
    >>> makefile_dir("../b/blah3")
    '../b/'
    >>> makefile_dir("./blah1")
    ''
    """
    dirname=os.path.dirname(filepath)
    if not dirname:
        return ''
    return dirname+'/'


def makefile_notdir(filepath):
    """
    >>> makefile_notdir("blah1")
    'blah1'
    >>> makefile_notdir("a/blah2")
    'blah2'
    >>> makefile_notdir("../b/blah3")
    'blah3'
    """
    return os.path.basename(filepath)


def deps_only(filepath):
    """
    Python version of `$(call ONLY,{})`
    """
    return filepath


def deps_file(filepath):
    """
    Python version of `$(call DEPS,{})`

    >>> deps_file("./a/blah")
    'a/blah.d'
    >>> deps_file("blah")
    'blah.d
    """
    return "{dir}{notdir}{depext}".format(
        dir=makefile_dir(filepath),
        notdir=makefile_notdir(filepath),
        depext=DEPEXT,
    )


def deps_all(filepath):
    """
    Python version of `$call ALL,{})`

    >>> deps_all("./a/blah")
    'a/blah a/blah.d'
    >>> deps_all("blah")
    'blah blah.d'

    """
    return "{only} {deps}".format(
        only=deps_only(filepath),
        deps=deps_file(filepath),
    )


def write_deps(inputfile_name, data):
    deps_filename = deps_file(inputfile_name)
    with open(deps_filename, "w") as f:
        f.write(data.getvalue())
    print("Generated dependency info", deps_filename)


if __name__ == "__main__":
    import doctest
    doctest.testmod()
