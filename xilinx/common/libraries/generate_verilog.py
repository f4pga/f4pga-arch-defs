"""Transforms the XML module definitions parsed from the PDF into a verilog representation"""
from lxml import etree
from datetime import datetime


def format_port(name, width, type, **kwargs):
    wstr = '' if int(width) == 1 else '[%s:0]\t' % width
    return '\t%s\t%s%s;\n' % (type, wstr, name)


def format_attrib(name, type, default, **kwargs):
    if type == 'STRING':
        default = '"%s"' % default  # need to ensure strings are quoted
    return '\tparameter %s = %s;\n' % (name, default)


def process(infile, outfile):
    tree = etree.parse(infile)
    root = tree.getroot()
    with open(outfile, "w") as output:
        output.write(
            '// Automatically generated from %s on %s\n\n' %
            (infile, datetime.now().isoformat())
        )
        for module in root.getchildren():
            ports = module.xpath('port')
            attrs = module.xpath('attribute')
            output.write(
                'module %s (%s);\n' % (
                    module.attrib['name'],
                    ', '.join([port.attrib['name'] for port in ports])
                )
            )
            for port in ports:
                output.write(format_port(**dict(port.attrib)))
            if len(attrs):
                output.write('\n')
            for attr in attrs:
                output.write(format_attrib(**dict(attr.attrib)))
            output.write('endmodule\n\n')


if __name__ == '__main__':
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument('--input', '-i', nargs='?', default='cells_xtra.xml')
    parser.add_argument('--output', '-o', nargs='?', default='cells_xtra.v')
    args = parser.parse_args()
    process(args.input, args.output)
