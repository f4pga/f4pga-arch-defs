"""
This file needs to be kept in sync with ../../common/make/deps.mk
"""

import os
import os.path

DEPDIR=".d"


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
    filepath = os.path.relpath(filepath, os.curdir)
    dirname=os.path.dirname(filepath)
    if not dirname:
        return ''
    return dirname+'/'

def makefile_defname(filepath):
    return filepath.replace("/", "_").replace("-","_").replace(".","_")


def makefile_notdir(filepath):
    """
    >>> makefile_notdir("blah1")
    'blah1'
    >>> makefile_notdir("a/blah2")
    'blah2'
    >>> makefile_notdir("../b/blah3")
    'blah3'
    """
    filepath = os.path.relpath(filepath, os.curdir)
    return os.path.basename(filepath)


def deps_only(filepath):
    """
    Python version of `$(call ONLY,{})`
    """
    filepath = os.path.relpath(filepath, os.curdir)
    return filepath


def deps_file(filepath):
    """
    Python version of `$(call DEPS,{})`

    >>> deps_file("./a/blah")
    'a/.d/blah.deps'
    >>> deps_file("blah")
    '.d/blah.deps'
    """
    return "{dir}{depdir}/{notdir}.deps".format(
        dir=makefile_dir(filepath),
        depdir=DEPDIR,
        notdir=makefile_notdir(filepath),
    )


def deps_mk(filepath):
    """
    Python version of `$(call DEPMK,{})`

    >>> deps_mk("./a/blah")
    'a/.d/blah.mk'
    >>> deps_mk("blah")
    '.d/blah.mk'
    """
    return "{dir}{depdir}/{notdir}.mk".format(
        dir=makefile_dir(filepath),
        depdir=DEPDIR,
        notdir=makefile_notdir(filepath),
    )


def deps_all(filepath):
    """
    Python version of `$call ALL,{})`

    >>> deps_all("./a/blah")
    'a/blah a/.d/blah.deps'
    >>> deps_all("blah")
    'blah .d/blah.deps'

    """
    return "{only} {deps}".format(
        only=deps_only(filepath),
        deps=deps_file(filepath),
    )


def gen_make(filepath):
    return """\
ifeq (,$({defname}))

{defname}=1

{filepath}:
\tmake -C {filedir} {filename}

{filepath_deps}:
\tmake -C {filedir} {filename_deps}

endif
""".format(
        defname=makefile_defname(filepath),
        filepath=deps_only(filepath),
        filedir=makefile_dir(filepath),
        filename=makefile_notdir(filepath),
        filepath_deps=deps_file(filepath),
        filename_deps=deps_file(makefile_notdir(filepath)),
    )


def write_deps(inputfile_name, data):
    deps_filename = deps_mk(inputfile_name)
    with open(deps_filename, "w") as f:
        f.write(data.getvalue())
    print("Created:", os.path.abspath(deps_filename))


if __name__ == "__main__":
    import doctest
    doctest.testmod()
