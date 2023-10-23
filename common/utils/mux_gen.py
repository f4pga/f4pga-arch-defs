#!/usr/bin/env python3
"""
Generate MUX.

MUXes come in two types,
 1) Configurable via logic signals,
 2) Statically configured by PnR (called "routing") muxes.
"""

import argparse
import itertools
import lxml.etree as ET
import os
import sys

from lib import mux as mux_lib
from lib.argparse_extra import ActionStoreBool
from lib.asserts import assert_eq

parser = argparse.ArgumentParser(
    description='Generate a MUX wrapper.',
    fromfile_prefix_chars='@',
    prefix_chars='-~'
)

parser.add_argument(
    '--verbose',
    '--no-verbose',
    action=ActionStoreBool,
    default=os.environ.get('V', '') == '1',
    help="Print lots of information about the generation."
)

parser.add_argument('--width', type=int, default=8, help="Width of the MUX.")

parser.add_argument(
    '--data-width', type=int, default=1, help="data width of the MUX."
)

parser.add_argument(
    '--type',
    choices=['logic', 'routing'],
    default='logic',
    help="Type of MUX."
)

parser.add_argument(
    '--split-inputs',
    action=ActionStoreBool,
    default=False,
    help="Split the inputs into separate signals"
)

parser.add_argument(
    '--split-selects',
    action=ActionStoreBool,
    default=False,
    help="Split the selects into separate signals"
)

parser.add_argument(
    '--name-mux', type=str, default='MUX', help="Name of the mux."
)

parser.add_argument(
    '--name-input',
    type=str,
    default='I',
    help="Name of the input values for the mux."
)

parser.name_inputs = parser.add_argument(
    '--name-inputs',
    type=str,
    default=None,
    help=  # noqa: E251
    "Comma deliminator list for the name of each input to the mux (implies --split-inputs)."
)

parser.add_argument(
    '--name-output',
    type=str,
    default='O',
    help="Name of the output value for the mux."
)

parser.add_argument(
    '--name-select',
    type=str,
    default='S',
    help="Name of the select parameter for the mux."
)

parser.name_selects = parser.add_argument(
    '--name-selects',
    type=str,
    default=None,
    help=  # noqa: E251
    "Comma deliminator list for the name of each select to the mux (implies --split-selects)."
)

parser.add_argument(
    '--order',
    choices=[''.join(x) for x in itertools.permutations('ios')] +
    [''.join(x) for x in itertools.permutations('io')],
    default='iso',
    help=  # noqa: E251
    """Order of the arguments for the MUX. (i - Inputs, o - Output, s - Select)"""
)

parser.add_argument(
    '--outdir',
    default=None,
    help="""Directory to output generated content too."""
)

parser.add_argument(
    '--outfilename',
    default=None,
    help="""Filename to output generated content too."""
)

parser.add_argument(
    '--comment', default=None, help="""Add some type of comment to the mux."""
)

parser.add_argument(
    '--num_pb', default=1, help="""Set the num_pb for the mux."""
)

parser.add_argument(
    '--subckt', default=None, help="""Override the subcircuit name."""
)


def main(argv):
    args = parser.parse_args()

    def output_block(name, s):
        if args.verbose:
            print()
            print(name, '-' * (75 - (len(name) + 1)))
            print(s, end="")
            if s[-1] != '\n':
                print()
            print('-' * 75)

    args.width_bits = mux_lib.clog2(args.width)

    def normpath(p, to=None):
        p = os.path.realpath(os.path.abspath(p))
        if to is None:
            return p
        return os.path.relpath(p, normpath(to))

    mypath = normpath(__file__)

    if not args.outdir:
        outdir = os.path.join(".", args.name_mux.lower())
    else:
        outdir = args.outdir

    outdir = normpath(outdir)

    mydir = normpath(os.path.dirname(mypath), to=outdir)
    mux_dir = normpath(os.path.join(mydir, '..', 'vpr', 'muxes'), to=outdir)

    if args.data_width > 1 and not args.split_inputs:
        assert False, "data_width(%d) > 1 requires using split_inputs" % (
            args.data_width
        )

    if args.name_inputs:
        assert_eq(args.name_input, parser.get_default("name_input"))
        args.name_input = None
        args.split_inputs = True

        names = args.name_inputs.split(',')
        assert len(names) == args.width, "%s input names, but %s needed." % (
            names, args.width
        )
        args.name_inputs = names
    elif args.split_inputs:
        args.name_inputs = [
            args.name_input + str(i) for i in range(args.width)
        ]
        parser.name_inputs.default = args.name_inputs
        assert_eq(parser.get_default("name_inputs"), args.name_inputs)

    if args.name_selects:
        assert_eq(args.name_select, parser.get_default("name_select"))
        args.name_select = None
        args.split_selects = True

        names = args.name_selects.split(',')
        assert len(names) == args.width_bits, (
            "%s select names, but %s needed." % (names, args.width_bits)
        )
        args.name_selects = names
    elif args.split_selects:
        args.name_selects = [
            args.name_select + str(i) for i in range(args.width_bits)
        ]
        parser.name_selects.default = args.name_selects
        assert_eq(parser.get_default("name_selects"), args.name_selects)

    os.makedirs(outdir, exist_ok=True)

    # Generated headers
    generated_with = """
Generated with %s
""" % mypath

    # XML Files can't have "--" in them, so instead we use ~~
    xml_comment = """
Generated with %s
""" % "\n".join(argv).replace('--', '~~')

    if not args.outfilename:
        args.outfilename = args.name_mux.lower()

    model_xml_filename = '%s.model.xml' % args.outfilename
    pbtype_xml_filename = '%s.pb_type.xml' % args.outfilename
    sim_filename = '%s.sim.v' % args.outfilename

    # ------------------------------------------------------------------------
    # Work out the port and their names
    # ------------------------------------------------------------------------

    port_names = []
    for i in args.order:
        if i == 'i':
            if args.split_inputs:
                port_names.extend(
                    mux_lib.ModulePort(
                        mux_lib.MuxPinType.INPUT, args.name_inputs[j], 1,
                        '[%i]' % j, args.data_width
                    ) for j in range(args.width)
                )
            else:
                # verilog range bounds are inclusive and convention is
                # [<width-1>:0]
                port_names.append(
                    mux_lib.ModulePort(
                        mux_lib.MuxPinType.INPUT, args.name_input, args.width,
                        '[%i:0]' % (args.width - 1)
                    )
                )
        elif i == 's':
            if args.split_selects:
                port_names.extend(
                    mux_lib.ModulePort(
                        mux_lib.MuxPinType.SELECT, args.name_selects[j], 1,
                        '[%i]' % j
                    ) for j in range(args.width_bits)
                )
            else:
                # verilog range bounds are inclusive and convention is
                # [<width-1>:0]
                assert args.name_select is not None
                port_names.append(
                    mux_lib.ModulePort(
                        mux_lib.MuxPinType.SELECT, args.name_select,
                        args.width_bits, '[%i:0]' % (args.width_bits - 1)
                    )
                )
        elif i == 'o':
            port_names.append(
                mux_lib.ModulePort(
                    mux_lib.MuxPinType.OUTPUT, args.name_output, 1, '',
                    args.data_width
                )
            )

    # ------------------------------------------------------------------------
    # Generate the techmap Verilog module
    # ------------------------------------------------------------------------
    techmap_filename = '%s.techmap.v' % args.outfilename
    techmap_pathname = os.path.join(outdir, techmap_filename)
    if args.type == 'routing':
        with open(techmap_pathname, "w") as f:
            module_args = []
            for port in port_names:
                if args.type == 'routing' and port.pin_type == mux_lib.MuxPinType.SELECT:
                    continue
                module_args.append(port.name)

            f.write("/* ")
            f.write("\n * ".join(generated_with.splitlines()))
            f.write("\n */\n\n")

            f.write(
                "module %s(%s);\n" %
                (args.name_mux.upper(), ", ".join(module_args))
            )
            f.write('\tparameter MODE = "";\n')

            modes = [
                port.name
                for port in port_names
                if port.pin_type in (mux_lib.MuxPinType.INPUT, )
            ]

            outputs = [
                port.name
                for port in port_names
                if port.pin_type in (mux_lib.MuxPinType.OUTPUT, )
            ]
            for port in port_names:
                if port.pin_type != mux_lib.MuxPinType.SELECT:
                    f.write(port.getDefinition())

            f.write('\tgenerate\n')
            for i, mode in enumerate(modes):
                f.write(
                    '\t\t%s ( MODE == "%s" )\n' %
                    (('if', 'else if')[i > 0], mode)
                )
                f.write('\t\tbegin\n')
                f.write('\t\t\tassign %s = %s;\n' % (outputs[0], mode))
                f.write('\t\tend\n')
            f.write('\t\telse\n')
            f.write('\t\tbegin\n')
            f.write('\t\t\twire _TECHMAP_FAIL_ = 1;\n')
            f.write('\t\tend\n')
            f.write("\tendgenerate\n")
            f.write("endmodule")

    # ------------------------------------------------------------------------
    # Generate the sim.v Verilog module
    # ------------------------------------------------------------------------
    sim_pathname = os.path.join(outdir, sim_filename)
    with open(sim_pathname, "w") as f:
        module_args = []
        for port in port_names:
            if args.type == 'routing' and port.pin_type == mux_lib.MuxPinType.SELECT:
                continue
            module_args.append(port.name)

        mux_class = {'logic': 'mux', 'routing': 'routing'}[args.type]

        f.write("/* ")
        f.write("\n * ".join(generated_with.splitlines()))
        f.write("\n */\n\n")
        f.write("`default_nettype none\n")
        f.write("\n")

        if args.type != 'routing':
            f.write(
                '`include "%s/%s/%smux%i/%smux%i.sim.v"\n' % (
                    mux_dir,
                    'logic',
                    '',
                    args.width,
                    '',
                    args.width,
                )
            )
        f.write("\n")
        f.write('(* CLASS="%s" *)\n' % mux_class)

        if args.type == 'routing':
            modes = [
                port.name
                for port in port_names
                if port.pin_type in (mux_lib.MuxPinType.INPUT, )
            ]
            outputs = [
                port.name
                for port in port_names
                if port.pin_type in (mux_lib.MuxPinType.OUTPUT, )
            ]
            assert len(
                outputs
            ) == 1, "FIXME: routing muxes should only have 1 output."
            f.write('(* MODES="%s" *)\n' % "; ".join(modes))

        f.write('(* whitebox *)\n')
        f.write(
            "module %s(%s);\n" %
            (args.name_mux.upper(), ", ".join(module_args))
        )
        previous_type = None
        for port in port_names:
            if previous_type != port.pin_type:
                f.write("\n")
                previous_type = port.pin_type
            if args.type == 'routing' and port.pin_type == mux_lib.MuxPinType.SELECT:
                f.write('\tparameter MODE = "";\n')
            else:
                f.write(port.getDefinition())

        f.write("\n")
        if args.data_width > 1:
            f.write('\tgenvar\tii;\n')
            f.write(
                '\tfor(ii=0; ii<%d; ii++) begin: bitmux\n' % (args.data_width)
            )

        if args.type == 'logic':
            f.write('\tMUX%s mux (\n' % args.width)
            for i in range(0, args.width):
                j = 0
                for port in port_names:
                    if port.pin_type != mux_lib.MuxPinType.INPUT:
                        continue
                    if j + port.width <= i:
                        j += port.width
                        continue
                    break

                if port.width == 1:
                    if args.data_width > 1:
                        f.write('\t\t.I%i(%s[ii]),\n' % (i, port.name))
                    else:
                        f.write('\t\t.I%i(%s),\n' % (i, port.name))
                else:
                    f.write('\t\t.I%i(%s[%i]),\n' % (i, port.name, i - j))

            for i in range(0, args.width_bits):
                j = 0
                for port in port_names:
                    if port.pin_type != mux_lib.MuxPinType.SELECT:
                        continue
                    if j + port.width < i:
                        j += port.width
                        continue
                    break

                if port.width == 1:
                    f.write('\t\t.S%i(%s),\n' % (i, port.name))
                else:
                    f.write('\t\t.S%i(%s[%i]),\n' % (i, port.name, i - j))

            for port in port_names:
                if port.pin_type != mux_lib.MuxPinType.OUTPUT:
                    continue
                break
            assert_eq(port.width, 1)
            if args.data_width > 1:
                f.write('\t\t.O(%s[ii])\n\t);\n' % port.name)
            else:
                f.write('\t\t.O(%s)\n\t);\n' % port.name)

        elif args.type == 'routing':
            f.write('\tgenerate\n')
            for i, mode in enumerate(modes):
                f.write(
                    '\t\t%s ( MODE == "%s" )\n' %
                    (('if', 'else if')[i > 0], mode)
                )
                f.write('\t\tbegin:SELECT_%s\n' % mode)
                f.write('\t\t\tassign %s = %s;\n' % (outputs[0], mode))
                f.write('\t\tend\n')
            f.write('\t\telse\n')
            f.write('\t\tbegin\n')
            f.write(
                '\t\t\t//$error("%s: Invalid routing value %%s (options are: %s)", MODE);\n'
                % (args.name_mux, ", ".join(modes))
            )
            f.write('\t\tend\n')
            f.write('\tendgenerate\n')

        if args.data_width > 1:
            f.write('end\n')

        f.write('endmodule\n')

    output_block(sim_filename, open(sim_pathname).read())

    if args.type == 'logic':
        subckt = args.subckt or args.name_mux
        assert subckt
    elif args.type == 'routing':
        assert args.subckt is None
        subckt = None

    # ------------------------------------------------------------------------
    # Generate the Model XML form.
    # ------------------------------------------------------------------------
    def xml_comment_indent(n, s):
        return ("\n" + " " * n).join(s.splitlines() + [""])

    if args.type == 'logic':
        models_xml = ET.Element('models')
        models_xml.append(ET.Comment(xml_comment_indent(4, xml_comment)))

        model_xml = ET.SubElement(models_xml, 'model', {'name': subckt})

        input_ports = ET.SubElement(model_xml, 'input_ports')
        output_ports = ET.SubElement(model_xml, 'output_ports')
        for port in port_names:
            if port.pin_type in (mux_lib.MuxPinType.INPUT,
                                 mux_lib.MuxPinType.SELECT):
                ET.SubElement(
                    input_ports, 'port', {
                        'name':
                            port.name,
                        'combinational_sink_ports':
                            ' '.join(
                                port.name for port in port_names if
                                port.pin_type in (mux_lib.MuxPinType.OUTPUT, )
                            ),
                    }
                )
            elif port.pin_type in (mux_lib.MuxPinType.OUTPUT, ):
                ET.SubElement(output_ports, 'port', {'name': port.name})

        models_str = ET.tostring(models_xml, pretty_print=True).decode('utf-8')
    else:
        models_str = "<models><!-- No models for routing elements.--></models>"

    output_block(model_xml_filename, models_str)
    with open(os.path.join(outdir, model_xml_filename), "w") as f:
        f.write(models_str)

    # ------------------------------------------------------------------------
    # Generate the pb_type XML form.
    # ------------------------------------------------------------------------

    pb_type_xml = mux_lib.pb_type_xml(
        mux_lib.MuxType[args.type.upper()],
        args.name_mux,
        port_names,
        subckt=subckt,
        num_pb=args.num_pb,
        comment=xml_comment_indent(4, xml_comment),
    )

    pb_type_str = ET.tostring(pb_type_xml, pretty_print=True).decode('utf-8')
    output_block(pbtype_xml_filename, pb_type_str)
    with open(os.path.join(outdir, pbtype_xml_filename), "w") as f:
        f.write(pb_type_str)

    print("Generated mux {} in {}".format(args.name_mux, outdir))


if __name__ == "__main__":
    sys.exit(main(sys.argv))
