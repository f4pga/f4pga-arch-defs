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
import math
import os
import sys

def str2bool(v):
    if v.lower() in ('yes', 'true', 't', 'y', '1'):
        return True
    elif v.lower() in ('no', 'false', 'f', 'n', '0'):
        return False
    else:
        raise argparse.ArgumentTypeError('Boolean value expected.')

parser = argparse.ArgumentParser(
    description='Generate a MUX wrapper.',
    fromfile_prefix_chars='@',
    prefix_chars='-~'
)

parser.add_argument(
    '--width', type=int, default=8,
    help="Width of the MUX.")

parser.add_argument(
    '--type', choices=['logic', 'routing'],
    default='logic',
    help="Type of MUX.")

parser.add_argument(
    '--split-inputs', type=str2bool, nargs='?', const=True, default=False,
    help="Split the inputs into separate signals")

parser.add_argument(
    '--split-selects', type=str2bool, nargs='?', const=True, default=False,
    help="Split the selects into separate signals")

parser.add_argument(
    '--name-mux', type=str, default='MUX',
    help="Name of the mux.")

parser.add_argument(
    '--name-input', type=str, default='I',
    help="Name of the input values for the mux.")

parser.add_argument(
    '--name-inputs', type=str, default=None,
    help="Comma deliminator list for the name of each input to the mux (implies --split-inputs).")

parser.add_argument(
    '--name-output', type=str, default='O',
    help="Name of the output value for the mux.")

parser.add_argument(
    '--name-select', type=str, default='S',
    help="Name of the select parameter for the mux.")

parser.add_argument(
    '--name-selects', type=str, default=None,
    help="Comma deliminator list for the name of each select to the mux (implies --split-selects).")

parser.add_argument(
    '--order', choices=[''.join(x) for x in itertools.permutations('ios')]+[''.join(x) for x in itertools.permutations('io')],
    default='iso',
    help="""Order of the arguments for the MUX. (i - Inputs, o - Output, s - Select)""")

parser.add_argument(
    '--outdir', default=None,
    help="""Directory to output generated content too.""")

parser.add_argument(
    '--comment', default=None,
    help="""Add some type of comment to the mux.""")

parser.add_argument(
    '--num_pb', default=1,
    help="""Set the num_pb for the mux.""")

parser.add_argument(
    '--subckt', default=None,
    help="""Override the subcircuit name.""")


def output_block(name, s):
    print()
    print(name, '-'*(75-(len(name)+1)))
    print(s, end="")
    if s[-1] != '\n':
        print()
    print('-'*75)


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

import doctest
doctest.testmod()

call_args = list(sys.argv)

args = parser.parse_args()
args.width_bits = clog2(args.width)
if not args.subckt:
    args.subckt = args.name_mux

mypath = __file__
mydir = os.path.dirname(mypath)

print(mypath)
print(args)

if not args.outdir:
    outdir = os.path.join(".", args.name_mux.lower())
else:
    outdir = args.outdir

mux_dir = os.path.relpath(os.path.abspath(os.path.join(mydir, '..', 'vpr', 'muxes')), outdir)

repo_args = []
skip_next = False
for i, arg in enumerate(sys.argv):
    if skip_next:
        skip_next = False
        continue

    if i == 0:
        repo_args.append(os.path.relpath(mypath, outdir))
        repo_args.append("--outdir")
        repo_args.append(".")
        continue

    # Outdir is special, ignore it.
    if arg.startswith("--outdir"):
        if "=" not in arg:
            skip_next = True
            continue

    repo_args.append(repr(arg))
    assert "--" not in arg[2:], "Can't have -- in argument value or name %r" % arg

os.makedirs(outdir, exist_ok=True)

# Generated headers
generated_with = """
Generated with mux_gen.py, run the following to regenerate in this directory;
%s
""" % " ".join(repo_args)
if args.comment:
    generated_with += args.comment

# XML Files can't have "--" in them, so instead we use ~~
xml_comment = """
Generated with %s
""" % mypath
if args.comment:
    xml_comment += "\n"
    xml_comment += args.comment.replace("--", "~~")
    xml_comment += "\n"

# ------------------------------------------------------------------------
# Create a makefile to regenerate files.
# ------------------------------------------------------------------------
makefile_file = os.path.join(outdir, "Makefile.mux")
output_files = ['model.xml', 'pb_type.xml', '.gitignore', 'Makefile.mux', 'sim.v']
commit_files = ['.gitignore', 'Makefile.mux']
remove_files = [f for f in output_files if f not in commit_files]
with open(makefile_file, "w") as f:
    f.write("""\
%s

all: %s

clean:
\trm -f .mux_gen.stamp %s

.mux_gen.stamp: %s Makefile.mux
\t%s
\ttouch --reference $< $@

.PHONY: all clean

""" % ("\n# ".join(generated_with.split("\n")),
       " ".join(output_files),
       " ".join(remove_files),
       repo_args[0],
       " ".join(repo_args),
    ))

    for name in output_files:
        f.write("%s: .mux_gen.stamp\n\n" % name)


output_block("Makefile.mux", open(makefile_file).read())

# ------------------------------------------------------------------------
# Create .gitignore file for the generated files.
# ------------------------------------------------------------------------
gitignore_file = os.path.join(outdir, ".gitignore")
with open(gitignore_file, "w") as f:
    f.write(".mux_gen.stamp\n")
    for name in remove_files:
        f.write(name+'\n')

output_block(".gitignore", open(gitignore_file).read())

# ------------------------------------------------------------------------
# Work out the port and their names
# ------------------------------------------------------------------------
if args.name_inputs:
    assert args.name_input == 'I'
    args.name_input = None
    args.split_inputs = True

    names = args.name_inputs.split(',')
    assert len(names) == args.width, "%s input names, but %s needed." % (names, args.width)
    args.name_inputs = names
elif args.split_inputs:
    args.name_inputs = [args.name_input+str(i) for i in range(args.width)]

if args.name_selects:
    assert args.name_input == 'I'
    args.name_input = None
    args.split_selects = True

    names = args.name_selects.split(',')
    assert len(names) == args.width, "%s select names, but %s needed." % (names, args.width_bits)
    args.name_selects = names
elif args.split_selects:
    args.name_selects = [args.name_select+str(i) for i in range(args.width_bits)]

port_names = []
for i in args.order:
    if i == 'i':
        if args.split_inputs:
            port_names.extend(('i', args.name_inputs[j], 1, '[%i]' % j) for j in range(args.width))
        else:
            port_names.append(('i', args.name_input, args.width, '[%i:0]' % args.width))
    elif i == 's':
        if args.split_selects and args.width_bits > 1:
            port_names.extend(('s', args.name_selects[j], 1, '[%i]' % j) for j in range(args.width_bits))
        else:
            port_names.append(('s', args.name_select, args.width_bits, '[%i:0]' % args.width_bits))
    elif i == 'o':
        port_names.append(('o', args.name_output, 1, ''))

# ------------------------------------------------------------------------
# Generate the sim.v Verilog module
# ------------------------------------------------------------------------

defs = {'i': 'input wire', 's': 'input wire', 'o': 'output wire'}

sim_file = os.path.join(outdir, "sim.v")
with open(sim_file, "w") as f:
    module_args = []
    for type, name, _, _ in port_names:
        if args.type == 'routing' and type == 's':
            continue
        module_args.append(name)

    mux_prefix = {'logic': '', 'routing': 'r'}[args.type]

    f.write("/* ")
    f.write("\n * ".join(generated_with.splitlines()))
    f.write("\n */\n\n")
    f.write('`include "%s/%s/%smux%i/sim.v"\n' % (mux_dir, 'logic', '', args.width))
    f.write("\n")
    f.write("module %s(%s);\n" % (args.name_mux, ", ".join(module_args)))
    previous_type = None
    for type, name, width, index in port_names:
        if previous_type != type:
            f.write("\n")
            previous_type = type
        if args.type == 'routing' and type == 's':
            if width == 1:
                f.write('\tparameter [0:0] %s = 0;\n' % (name))
            else:
                f.write('\tparameter %s %s = 0;\n' % (index, name))
            continue

        if width == 1:
            f.write('\t%s %s;\n' % (defs[type], name))
        else:
            f.write('\t%s %s %s;\n' % (defs[type], index, name))

    f.write("\n")
    f.write('\tMUX%s mux (\n' % args.width)
    for i in range(0, args.width):
        j = 0
        for type, name, width, index in port_names:
            if type != 'i':
                continue
            if j+width <= i:
                j += width
                continue
            break

        print(i, j, name)

        if width == 1:
            f.write('\t\t.I%i(%s),\n' % (i, name))
        else:
            f.write('\t\t.I%i(%s[%i]),\n' % (i, name, i-j))

    for i in range(0, args.width_bits):
        j = 0
        for type, name, width, index in port_names:
            if type != 's':
                continue
            if j+width < i:
                j += width
                continue
            break

        if width == 1:
            f.write('\t\t.S%i(%s),\n' % (i, name))
        else:
            f.write('\t\t.S%i(%s[%i]),\n' % (i, name, i-j))

    for type, name, width, index in port_names:
        if type != 'o':
            continue
        break
    assert width == 1
    f.write('\t\t.O(%s)\n\t);\n' % name)

    f.write('endmodule\n')

output_block("sim.v", open(sim_file).read())

# ------------------------------------------------------------------------
# Generate the Model XML form.
# ------------------------------------------------------------------------
if args.type == 'logic':
    models_xml = ET.Element('models')
    models_xml.append(ET.Comment(xml_comment))

    model_xml = ET.SubElement(models_xml, 'model', {'name': args.subckt})

    input_ports = ET.SubElement(model_xml, 'input_ports')
    output_ports = ET.SubElement(model_xml, 'output_ports')
    for type, name, width, index in port_names:
        if type in ('i', 's'):
            ET.SubElement(
                input_ports, 'port', {
                    'name': name,
                    'combinational_sink_ports': ','.join(n for t, n, w, i in port_names if t in ('o',)),
                })
        elif type in ('o',):
            ET.SubElement(output_ports, 'port', {'name': args.name_output})

    models_str = ET.tostring(models_xml, pretty_print=True).decode('utf-8')
    output_block("model.xml", models_str)
    with open(os.path.join(outdir, "model.xml"), "w") as f:
        f.write(models_str)
else:
    output_block("model.xml", "No model.xml for routing elements.")

# ------------------------------------------------------------------------
# Generate the pb_type XML form.
# ------------------------------------------------------------------------

mn = args.name_mux
pb_type_xml = ET.Element(
    'pb_type', {
        'name': mn,
        'num_pb': str(args.num_pb),
    })
if args.type == 'logic':
    pb_type_xml.attrib['blif_model'] = '.subckt %s' % args.subckt

pb_type_xml.append(ET.Comment(xml_comment))

for type, name, width, index in port_names:
    if args.type == 'routing' and type == 's':
        continue
    ET.SubElement(
        pb_type_xml,
        {'i': 'input',
         's': 'input',
         'o': 'output'}[type],
        {'name': name, 'num_pins': str(width)},
    )

if args.type == 'logic':
    for itype, iname, iwidth, iindex in port_names:
        if itype not in ('i', 's'):
            continue

        for otype, oname, owidth, oindex in port_names:
            if otype not in ('o',):
                continue

            ET.SubElement(
                pb_type_xml,
                'delay_constant', {
                    'max': "10e-12",
                    'in_port': "%s.%s" % (args.name_mux, iname),
                    'out_port': "%s.%s" % (args.name_mux, oname),
                },
            )
else:
    interconnect = ET.SubElement(pb_type_xml, 'interconnect')
    ET.SubElement(
        interconnect,
        'mux', {
            'name': '_'+args.name_mux,
            'input': ' '.join("%s.%s" % (mn,n) for t, n, _, _ in port_names if t in ('i',)),
            'output': "%s.%s" % (mn,args.name_output),
        },
    )

pb_type_str = ET.tostring(pb_type_xml, pretty_print=True).decode('utf-8')
output_block("pb_type.xml", pb_type_str)
with open(os.path.join(outdir, "pb_type.xml"), "w") as f:
    f.write(pb_type_str)
