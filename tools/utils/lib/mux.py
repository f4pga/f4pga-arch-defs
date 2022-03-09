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


def add_metadata(tag, mtype, msubtype):
    meta_root = ET.SubElement(tag, 'metadata')
    meta_type = ET.SubElement(meta_root, 'meta', {'name': 'type'})
    meta_type.text = mtype
    meta_subtype = ET.SubElement(meta_root, 'meta', {'name': 'subtype'})
    meta_subtype.text = msubtype
    return meta_root


class MuxType(Enum):
    LOGIC = 'BEL_MX'
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
            raise TypeError(
                "Can't convert {} into verilog definition.".format(self)
            )

    def direction(self):
        if self in (self.INPUT, self.SELECT):
            return "input"
        elif self == self.OUTPUT:
            return "output"
        else:
            raise TypeError(
                "Can't convert {} into verilog definition.".format(self)
            )

    def __str__(self):
        return self.value


class ModulePort(object):
    def __init__(self, pin_type, name, width, index, data_width=1):
        self.name = name
        self.pin_type = pin_type
        self.width = width
        self.index = index
        self.data_width = data_width

    def getDefinition(self):
        if self.width == 1:
            if self.data_width is not None and self.data_width > 1:
                return '\t%s [%d:0] %s;\n' % (
                    self.pin_type.verilog(), self.data_width - 1, self.name
                )
            else:
                return '\t%s %s;\n' % (self.pin_type.verilog(), self.name)
        else:
            return '\t%s %s %s;\n' % (
                self.pin_type.verilog(), self.index, self.name
            )


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
    assert isinstance(comment,
                      str), "{} {}".format(type(comment), repr(comment))

    if mux_type not in (MuxType.LOGIC, MuxType.ROUTING):
        assert False, "Unknown type {}".format(mux_type)

    pb_type_xml = ET.Element(
        'pb_type', {
            'name': mux_name,
            'num_pb': str(num_pb),
        }
    )

    if mux_type == MuxType.LOGIC:
        add_metadata(pb_type_xml, 'bel', 'mux')
    else:
        add_metadata(pb_type_xml, 'bel', 'routing')

    if mux_type == MuxType.LOGIC:
        model = ET.SubElement(pb_type_xml, "blif_model")
        model.text = '.subckt {}'.format(subckt)
    else:
        assert not subckt, "Provided subckt={} for non-logic mux!".format(
            subckt
        )

    if comment is not None:
        pb_type_xml.append(ET.Comment(comment))

    for port in pins:
        # assert port.index < port.width, (
        #     "Pin index {} >= width {} for pin {} {}".format(
        #         port.index, port.width, port.name, port.pin_type
        #     )
        # )
        if mux_type == MuxType.ROUTING and port.pin_type == MuxPinType.SELECT:
            continue

        assert port.width == 1 or port.data_width == 1, (
            'Only one of width(%d) or data_width(%d) may > 1 for pin %s' %
            (port.width, port.data_width, port.name)
        )

        if port.width == 1 and port.data_width > 1:
            num_pins = port.data_width
        else:
            num_pins = port.width

        mux = ET.SubElement(
            pb_type_xml,
            port.pin_type.direction(),
            {
                'name': port.name,
                'num_pins': str(num_pins)
            },
        )

    if mux_type == MuxType.LOGIC:
        for inport in pins:
            if inport.pin_type not in (MuxPinType.INPUT, MuxPinType.SELECT):
                continue

            for outport in pins:
                if outport.pin_type not in (MuxPinType.OUTPUT, ):
                    continue
                if inport.name.startswith('I'):
                    delay_inport = inport.name[1]
                else:
                    # if it is not IX it must be S
                    delay_inport = "S0"
                # XXX: temporary workaroud
                if mux_name == "F6MUX":
                    maxdel = "10e-12"
                else:
                    maxdel = "{{iopath_{}_OUT}}".format(delay_inport)

                ET.SubElement(
                    pb_type_xml,
                    'delay_constant',
                    {
                        'max': maxdel,
                        'in_port': "%s" % inport.name,
                        'out_port': "%s" % outport.name,
                    },
                )
    elif mux_type == MuxType.ROUTING:
        interconnect = ET.SubElement(pb_type_xml, 'interconnect')

        inputs = [
            "{}.{}".format(mux_name, port.name)
            for port in pins
            if port.pin_type in (MuxPinType.INPUT, )
        ]
        outputs = [
            "{}.{}".format(mux_name, port.name)
            for port in pins
            if port.pin_type in (MuxPinType.OUTPUT, )
        ]
        assert len(outputs) == 1

        mux = ET.SubElement(
            interconnect,
            'mux',
            {
                'name': '%s' % mux_name,
                'input': " ".join(inputs),
                'output': outputs[0],
            },
        )
        meta_root = add_metadata(mux, 'bel', 'routing')

        meta_fasm_mux = ET.SubElement(meta_root, 'meta', {'key': 'fasm_mux'})
        meta_fasm_mux.text = "\n".join(
            [""] + ["{0} = {0}".format(i) for i in inputs] + [""]
        )

    return pb_type_xml


if __name__ == "__main__":
    import doctest
    failure_count, test_count = doctest.testmod()
    assert test_count > 0
    assert failure_count == 0, "Doctests failed!"
