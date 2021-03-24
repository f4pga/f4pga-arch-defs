#!/usr/bin/env python3
"""
Block hierarchy path utilities.
"""
import re

# =============================================================================

# A regular expression for parsing path nodes
PATH_NODE_RE = re.compile(
    r"^(?P<name>[^\s\[\]\.]+)(\[(?P<index>[0-9]+)\])?" \
    r"(\[(?P<mode>[^\s\[\]\.]+)\])?$"
)

# =============================================================================


class PathNode:
    """
    A class for representing a single path node.

    A string representation of a path node can have the following formats:
    - "<name>[<index>][<mode>]"
    - "<name>[<index>]"
    - "<name>[<mode>]"
    - "<name>"

    Differentiation between index and mode is based on the assumption that an
    index may only contain numbers while a mode any other character as well.

    FIXME: This may lead to ambiguity if a mode is named using digits only.
    """

    def __init__(self, name, index=None, mode=None):
        """
        Generic constructor
        """

        assert isinstance(name, str) or name is None, name
        assert isinstance(index, int) or index is None, index
        assert isinstance(mode, str) or mode is None, mode

        self.name = name
        self.index = index
        self.mode = mode

    @staticmethod
    def from_string(string):
        """
        Converts a string representation to a PathNode object
        """

        # Match the regex
        match = PATH_NODE_RE.fullmatch(string)
        assert match is not None, string

        name  = match.group("name")
        index = match.group("index")
        mode  = match.group("mode")

        if index is not None:
            index = int(index)

        return PathNode(name, index, mode)

    def to_string(self):
        """
        Converts the node into a string
        """
        string = self.name

        if self.index is not None:
            string += "[{}]".format(self.index)

        if self.mode is not None:
            string += "[{}]".format(self.mode)

        return string

    def __str__(self):
        return self.to_string()

    def __repr__(self):
        return self.to_string()
