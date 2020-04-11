import re

# =============================================================================

# A regex used for fixing pin names
RE_PIN_NAME = re.compile(r"^([A-Za-z0-9_]+)(?:\[([0-9]+)\])?$")

# =============================================================================


def get_pin_name(name):
    """
    Returns the pin name and its index in bus. If a pin is not a member of
    a bus then the index is None

    >>> get_pin_name("WIRE")
    ('WIRE', None)
    >>> get_pin_name("DATA[12]")
    ('DATA', 12)
    """

    match = re.match(r"(?P<name>.*)\[(?P<idx>[0-9]+)\]$", name)
    if match:
        return match.group("name"), int(match.group("idx"))
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


# =============================================================================


def yield_muxes(switchbox):
    """
    Yields all muxes of a switchbox. Returns tuples with:
    (stage, switch, mux)
    """

    for stage in switchbox.stages.values():
        for switch in stage.switches.values():
            for mux in switch.muxes.values():
                yield stage, switch, mux


# =============================================================================


def add_named_item(item_dict, item, item_name):
    """
    Adds a named item to the given dict if not already there. If it is there
    then returns the one from the dict.
    """

    if item_name not in item_dict:
        item_dict[item_name] = item

    return item_dict[item_name]
