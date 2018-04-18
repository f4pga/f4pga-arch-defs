#!/usr/bin/env python3
import lxml.etree as ET
from enum import Enum


def clog2(x):
    """Ceiling log 2 of x.

    >>> clog2(0), clog2(1), clog2(2), clog2(3), clog2(4)
    (0, 0, 1, 2, 2)
    >>> clog2(5), clog2(6), clog2(7), clog2(8), clog2(9)
    (3, 3, 3, 3, 4)
    >>> clog2(1 << 31)
    31
    >>> clog2(1 << 63)
    63
    >>> clog2(1 << 11)
    11
    """
    x -= 1
    i = 0
    while True:
        if x <= 0:
            break
        x = x >> 1
        i += 1
    return i


class MuxType(Enum):
    LOGIC   = 'BEL_MX'
    ROUTING = 'BEL_RX'


class MuxPinType(Enum):
    INPUT = 'i'
    SELECT = 's'
    OUTPUT = 'o'

    def verilog(self):
        if self in (self.INPUT, self.SELECT):
            return "input wire"
        elif self == self.OUTPUT:
            return "output wire"
        else:
            raise TypeError("Can't convert {} into verilog definition.".format(self))

    def direction(self):
        if self in (self.INPUT, self.SELECT):
            return "input"
        elif self == self.OUTPUT:
            return "output"
        else:
            raise TypeError("Can't convert {} into verilog definition.".format(self))

    def __str__(self):
        return self.value


def pb_type_xml(mux_type, mux_name, pins, subckt=None, num_pb=1, comment=""):
    """Generate <pb_type> XML for a mux.

    Parameters
    ----------
    mux_type: MuxType
        Type of mux to create.

    mux_name: str
        Name of the mux.

    pins: [(MuxPinType, str, int, int),]
        List of tuples which contain (pin type, pin name, port width, index)

    subckt: str
        Name of the blif_model for the mux. Only valid when mux_type ==
        MuxType.LOGIC.

    num_pb: int
        Value for the num_pb value. Defaults to 1.

    comment: str
        Optional comment for the mux.

    Returns
    -------
    xml.etree.ElementTree
        pb_type.xml for requested mux
    """
    assert isinstance(comment, str), "{} {}".format(type(comment), repr(comment))

    if mux_type == MuxType.LOGIC:
        if '-' not in mux_name:
            mux_name = 'BEL_MX-'+mux_name
        else:
            assert mux_name.startswith('BEL_MX-'), "Provided mux name has type {} but not BEL_MX!".format(mux_name)
    elif mux_type == MuxType.ROUTING:
        if '-' not in mux_name:
            mux_name = 'BEL_RX-'+mux_name
        else:
            assert mux_name.startswith('BEL_RX-'), "Provided mux name has type {} but not BEL_MX!".format(mux_name)
    else:
        assert False, "Unknown type {}".format(mux_type)

    pb_type_xml = ET.Element(
        'pb_type', {
            'name': mux_name,
            'num_pb': str(num_pb),
        })

    if mux_type == MuxType.LOGIC:
        pb_type_xml.attrib['blif_model'] = '.subckt %s' % subckt
    else:
        assert not subckt, "Provided subckt={} for non-logic mux!".format(subckt)

    if comment is not None:
        pb_type_xml.append(ET.Comment(comment))

    for pin_type, pin_name, pin_width, pin_index in pins:
        #assert pin_index < pin_width, (
        #    "Pin index {} >= width {} for pin {} {}".format(pin_index, pin_width, pin_name, pin_type))
        if mux_type == MuxType.ROUTING and pin_type == MuxPinType.SELECT:
            continue
        ET.SubElement(
            pb_type_xml,
            pin_type.direction(),
            {'name': pin_name, 'num_pins': str(pin_width)},
        )

    if mux_type == MuxType.LOGIC:
        for ipin_type, ipin_name, ipin_width, ipin_index in pins:
            if ipin_type not in (MuxPinType.INPUT, MuxPinType.SELECT):
                continue

            for opin_type, opin_name, opin_width, opin_index in pins:
                if opin_type not in (MuxPinType.OUTPUT,):
                    continue

                ET.SubElement(
                    pb_type_xml,
                    'delay_constant', {
                        'max': "10e-12",
                        'in_port': "%s.%s" % (mux_name, ipin_name),
                        'out_port': "%s.%s" % (mux_name, opin_name),
                    },
                )
    elif mux_type == MuxType.ROUTING:
        interconnect = ET.SubElement(pb_type_xml, 'interconnect')

        inputs  = ["{}.{}".format(mux_name, n) for t, n, _, _ in pins if t in (MuxPinType.INPUT,)]
        outputs = ["{}.{}".format(mux_name, n) for t, n, _, _ in pins if t in (MuxPinType.OUTPUT,)]
        assert len(outputs) == 1

        ET.SubElement(
            interconnect,
            'mux', {
                'name': '%s' % (mux_name,),
                'input': " ".join(inputs),
                'output': outputs[0],
            },
        )

    return pb_type_xml


if __name__ == "__main__":
    import doctest
    doctest.testmod()
