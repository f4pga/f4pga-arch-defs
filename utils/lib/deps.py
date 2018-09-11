#!/usr/bin/env python3
"""
This file needs to be kept in sync with ../../make/deps.mk
"""

import os
import os.path

MY_DIR = os.path.dirname(os.path.abspath(__file__))
TOP_DIR = os.path.abspath(os.path.join(MY_DIR, "..", ".."))

DEPS_DIR = ".deps"
DEPS_EXT = ".d"
DEPMK_EXT = ".dmk"


def makefile_dir(filepath):
    """Get the directory part of a path in the same way make does.

    Python version of the makefile `$(dir xxx)` function.

    >>> makefile_dir("blah1")
    ''
    >>> makefile_dir("a/blah2")
    'a/'
    >>> makefile_dir("../b/blah3")
    '../b/'
    >>> makefile_dir("./blah4")
    ''
    >>> makefile_dir("/abc/blah6")
    '/abc/'
    >>> makefile_dir("/blah5")
    '/'
    """
    dirname = os.path.dirname(os.path.normpath(filepath))
    if not dirname or dirname == '.':
        return ''
    if dirname[-1] != '/':
        dirname += '/'
    return dirname


def makefile_notdir(filepath):
    """Get the non-directory part of a path in the same way make does.

    Python version of the makefile `$(nodir xxxx)` function.

    >>> makefile_notdir("blah1")
    'blah1'
    >>> makefile_notdir("a/blah2")
    'blah2'
    >>> makefile_notdir("../b/blah3")
    'blah3'
    >>> makefile_notdir("blah4/")
    ''
    >>> makefile_notdir("/blah5")
    'blah5'
    >>> makefile_notdir("/abc/blah6")
    'blah6'
    """
    return os.path.basename(filepath)


def deps_dir(filepath, *, top_dir=TOP_DIR):
    """Get the directory to put dependencies files into.

    >>> td = os.path.abspath(os.curdir)
    >>> deps_dir("./a/blah", top_dir=td)
    '.deps/a/blah'
    >>> deps_dir("blah", top_dir=td)
    '.deps/blah'
    >>> deps_dir("blah.abc", top_dir=td)
    '.deps/blah.abc'
    >>> deps_dir("/abc3/blah", top_dir='/abc3')
    '.deps/blah'
    >>> deps_dir("/abc3/blah", top_dir='/abc4')
    Traceback (most recent call last):
        ...
    OSError: /abc3/blah is not inside top /abc4
    """
    filepath = os.path.normpath(filepath)
    if filepath[0] != '/':
        filepath = os.path.abspath(filepath)
    filepath_notop = filepath.replace(top_dir + '/', '')
    if filepath_notop == filepath:
        raise IOError("{} is not inside top {}".format(filepath, top_dir))
    return "{deps_dir}/{dir}{notdir}".format(
        deps_dir=DEPS_DIR,
        dir=makefile_dir(filepath_notop),
        notdir=makefile_notdir(filepath_notop),
    )


def deps_makefile(filepath, *, top_dir=TOP_DIR):
    """Get deps makefile name.

    Python version of `$(call deps_makefile,{})` in make/deps.mk

    >>> td = os.path.abspath(os.curdir)
    >>> deps_makefile("./a/blah", top_dir=td)
    '.deps/a/blah.dmk'
    >>> deps_makefile("blah", top_dir=td)
    '.deps/blah.dmk'
    """
    return deps_dir(
        "{dir}{notdir}{ext}".format(
            dir=makefile_dir(filepath),
            notdir=makefile_notdir(filepath),
            ext=DEPMK_EXT,
        ),
        top_dir=top_dir)


def add_dependency(f, from_file, on_file, fmt=None):
    """Record a dependency from file on file."""
    if fmt is None:
        fmt = "$(call add_dependency,{from_file},{on_file})\n"
    f.write(fmt.format(
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
