import re

# =============================================================================

# A regex used for fixing pin names
RE_PIN_NAME = re.compile(r"^([A-Za-z0-9_]+)(?:\[([0-9]+)\])?$")

# =============================================================================


def get_pin_name(name):
    """
    Returns the pin name and its index in bus. If a pin is not a member of
    a bus then the index is None
    """

    match = re.match(r"(.*)\[([0-9]+)\]$", name)
    if match:
        return match.group(1), int(match.group(2))
    else:
        return name, None


def fixup_pin_name(name):
    """
    Renames a pin to make its name suitable for VPR.

    >>> fixup_pin_name("A_WIRE")
    'A_WIRE'
    >>> fixup_pin_name("ADDRESS[17]")
    'ADDRESS_17'
    >>> fixup_pin_name("DATA[11]_X")
    Traceback (most recent call last):
        ...
    AssertionError: DATA[11]_X
    """

    match = RE_PIN_NAME.match(name)
    assert match is not None, name

    groups = match.groups()
    if groups[1] is None:
        return groups[0]
    else:
        return "{}_{}".format(*groups)
