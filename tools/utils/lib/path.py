#!/usr/bin/env python3
import os
import os.path


def normpath(p, to=None):
    p = os.path.realpath(os.path.abspath(p))
    if to is None:
        return p
    return os.path.relpath(p, normpath(to))


def curpath(p):
    return normpath(p, os.curdir)


def modfile(p, pattern):
    assert "{}" not in p
    filename = os.path.basename(p)
    pathname = os.path.dirname(p)
    newfilename = pattern.format(filename)
    while newfilename.startswith(".."):
        newfilename = newfilename[1:]
    newpath = os.path.join(pathname, newfilename)
    return newpath
