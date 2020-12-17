""" Used to parse XDC files for pin constraints """

from collections import namedtuple
import re

XdcIoConstraint = namedtuple("XdcIoConstraint",
                             "net pad line_str line_num params")


def to_int_float_or_string(s):
    """ Convert string to int or float if possible

    If s is an integer, return int(s)
    >>> to_int_float_or_string("3")
    3
    >>> to_int_float_or_string("-7")
    -7

    If s is a float, return float(2)
    >>> to_int_float_or_string("3.52")
    3.52
    >>> to_int_float_or_string("-10.0")
    -10.0
    >>> to_int_float_or_string("1.4e7")
    14000000.0

    Otherwise, just return the string s
    >>> to_int_float_or_string("A3")
    'A3'

    """

    try:
        s_int = int(s)

        # int(s) will truncate.  If user specified a '.', return a float instead
        if "." not in s:
            return s_int
    except (TypeError, ValueError):
        pass

    try:
        return float(s)
    except (TypeError, ValueError):
        return s


def parse_simple_xdc(fp):
    """ Parse a simple XDC file object and return list of XdcIoConstraint objects. """

    # For each port, maintain a dictionary of PROPERTIES
    port_to_params = {}

    # For each port, maintain XdcIoConstraint object to return
    port_to_results = {}

    for line_number, line in enumerate(fp):
        m = re.match(r"^\s*set_property\s+(.*)\[\s*get_ports\s+(.*)\]", line,
                     re.I)
        if not m:
            continue
        properties = m.group(1).strip()
        port = m.group(2).strip()

        # Check if port is surrounded by {} braces
        m = re.match(r"{\s*(\S+)\s*}", port)
        if m:
            port = m.group(1).strip()

        if port not in port_to_params:
            # Default DRIVE value is 12.
            port_to_params[port] = {'DRIVE': 12}

        # Check for pin property as part of a dictionary, ie:
        # -dict { PACKAGE_PIN N15   IOSTANDARD LVCMOS33 }
        m = re.match(r"-dict\s+{(.*)}", properties)
        if m:
            # Convert tcl dict to python dict
            dict_list = m.group(1).strip().split()
            properties = dict(zip(dict_list[::2], dict_list[1::2]))

            if "PACKAGE_PIN" in properties:
                port_to_results[port] = XdcIoConstraint(
                    net=port,
                    pad=properties["PACKAGE_PIN"],
                    line_str=line.strip(),
                    line_num=line_number,
                    params=port_to_params[port],
                )

            port_to_params[port].update(properties)
        else:
            # Otherwise, must be a direct set_property, ie:
            # PACKAGE_PIN N15
            property_pair = properties.split()
            assert len(property_pair) == 2, property_pair

            port_to_params[port][property_pair[0]] = property_pair[1]

            if property_pair[0] == "PACKAGE_PIN" or property_pair[0] == "LOC":
                port_to_results[port] = XdcIoConstraint(
                    net=port,
                    pad=property_pair[1],
                    line_str=line.strip(),
                    line_num=line_number,
                    params=port_to_params[port],
                )

    # Convert all property values to int/float when possible
    for port in port_to_results:
        for k, v in port_to_results[port].params.items():
            port_to_results[port].params[k] = to_int_float_or_string(v)

    # Return list of XdcIoConstraint objects
    return [port_to_results[port] for port in port_to_results]
