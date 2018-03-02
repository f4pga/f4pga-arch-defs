"""
This file needs to be kept in sync with ../../make/deps.mk
"""

import os
import os.path


DEPS_EXT=".d"
DEPMK_EXT=".dmk"


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


def depend_on_only(filepath):
    """
    Python version of `$(call depend_on_only,{})`
    """
    return filepath


def depend_on_deps(filepath):
    """
    Python version of `$(call depend_on_deps,{})`

    >>> deps_file("./a/blah")
    'a/blah.d'
    >>> deps_file("blah")
    'blah.d'
    """
    return "{dir}{notdir}{ext}".format(
        dir=makefile_dir(filepath),
        notdir=makefile_notdir(filepath),
        ext=DEPS_EXT,
    )


def deps_makefile(filepath):
    """
    Python version of `$(call deps_makefile,{})`

    >>> deps_file("./a/blah")
    'a/blah.dmk'
    >>> deps_file("blah")
    'blah.dmk'
    """
    return "{dir}{notdir}{ext}".format(
        dir=makefile_dir(filepath),
        notdir=makefile_notdir(filepath),
        ext=DEPMK_EXT,
    )


def depend_on_all(filepath):
    """
    Python version of `$call depend_on_all,{})`

    >>> deps_all("./a/blah")
    'a/blah a/blah.d'
    >>> deps_all("blah")
    'blah blah.d'

    """
    return "{only} {deps}".format(
        only=deps_only(filepath),
        deps=deps_file(filepath),
    )


def add_dependency(f, from_file, on_file):
    """Record a dependency from file on file."""
    f.write("""
$(call add_dependency,{from_file},{on_file})
""".format(
    from_file=from_file,
    on_file=on_file,
))


def write_deps(inputfile_name, data):
    deps_filename = deps_makefile(inputfile_name)
    with open(deps_filename, "w") as f:
        f.write(data.getvalue())
    print("Generated dependency info", deps_filename)


if __name__ == "__main__":
    import doctest
    doctest.testmod()
