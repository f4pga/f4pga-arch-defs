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
    '--name-output', type=str, default='O',
    help="Name of the output value for the mux.")

parser.add_argument(
    '--name-select', type=str, default='S',
    help="Name of the select parameter for the mux.")

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


def clog2(x):
    """Ceiling log 2 of x.

    >>> clog2(0), clog2(1), clog2(2), clog2(3), clog2(4)
    (1, 1, 2, 2, 3)
    >>> clog2(5), clog2(6), clog2(7), clog2(8), clog2(9)
    (3, 3, 3, 4, 4)
    >>> clog2(1 << 31)
    32
    >>> clog2(1 << 63)
    64
    >>> clog2(1 << 11)
    12
    """
    i = 0
    while True:
        x = x >> 1
        i += 1
        if x <= 0:
            break
    return i

import doctest
doctest.testmod()


# Method for implementing the internals of the MUX.
method = {
    'impl': """\
	assign O = I[S];
""",

    'wrap': {
        # FIXME: Wrap the LOGIC_MUX_N
        'logic': """\
    LOGIC_MUX_N ...
""",
        # FIXME: Wrap the ROUTING_MUX_N
        'routing': """\
""",
    },

    'blackbox': "",
}


logic_template = """\
module {:name}({:args});

    output wire {:name_output};
    input wire [{:width}:0] {:name_;
    input wire [{:select}:0] {:name_select};

{:method}
endmodule
"""

routing_template = """\
module {:name}({:args});
    parameter {:name_select} = 0;

    output wire {:name_output};
    input wire [{:width}:0] {:name_input};

{:method}
    assign {:name_output} = {:name_input}[{:name_select}];
endmodule
"""

call_args = list(sys.argv)

args = parser.parse_args()
args.width_bits = clog2(args.width)
if not args.subckt:
    args.subckt = args.name_mux

mypath = __file__

print(mypath)
print(args)

if not args.outdir:
    outdir = os.path.join(".", args.name_mux.lower())
else:
    outdir = args.outdir

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

# Create a makefile to regenerate files.
makefile_file = os.path.join(outdir, "Makefile.mux")
output_files = ['model.xml', 'pb_type.xml', '.gitignore', 'Makefile.mux']
commit_files = ['.gitignore', 'Makefile.mux']
remove_files = [f for f in output_files if f not in commit_files]
with open(makefile_file, "w") as f:
    f.write("""\
%s

all: %s

clean:
\trm -f .mux_gen.stamp %s

.mux_gen.stamp: %s
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


print("Makefile.mux", "-"*75)
print(open(makefile_file).read())
print("-"*75)

# .gitignore file for the generated file.
gitignore_file = os.path.join(outdir, ".gitignore")
with open(gitignore_file, "w") as f:
    f.write(".mux_gen.stamp\n")
    for name in remove_files:
        f.write(name+'\n')

print(".gitignore", "-"*75)
print(open(gitignore_file).read())
print("-"*75)

# Work out the port names
port_names = []
for i in args.order:
    if i == 'i':
        if args.split_inputs:
            port_names.extend(('i', args.name_input+str(i), 1, '[%i]' % i) for i in range(args.width))
        else:
            port_names.append(('i', args.name_input, args.width, '[%i:0]' % args.width))
    elif i == 's' and args.type == 'logic':
        if args.split_selects:
            port_names.extend(('s', args.name_select+str(i), 1, '[%i]' % i) for i in range(args.width_bits))
        else:
            port_names.append(('s', args.name_select, args.width_bits, '[%i:0]' % args.width_bits))
    elif i == 'o':
        port_names.append(('o', args.name_output, 1, ''))

# Generate the Model XML form.
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
print("models.xml", "-"*75)
print(models_str)
print("-"*75)
with open(os.path.join(outdir, "model.xml"), "w") as f:
    f.write(models_str)

# Generate the pb_type XML form.
pb_type_xml = ET.Element(
    'pb_type', {
        'name': args.name_mux,
        'num_pb': str(args.num_pb),
        'blif_model': '.subckt %s' % args.subckt,
    })
pb_type_xml.append(ET.Comment(xml_comment))

for type, name, width, index in port_names:
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
                    'in_port': iname,
                    'out_port': oname,
                },
            )

if False:
    interconnect = ET.SubElement(pb_type_xml, 'interconnect')
    if args.type == 'routing':
        ET.SubElement(
            interconnect,
            'mux', {
                'name': 'OUT',
                'input': ' '.join(n for t, n, w, i in port_names if t in ('i',)),
                'output': args.name_output,
            },
        )
    else:
        for type, name, width, index in port_names:
            if type in ('i', 's'):
                ET.SubElement(
                    interconnect,
                    'direct', {
                        'name': name,
                        'input': name,
                        'output': "MUX.%s%s" % (type.upper(), index),
                    },
                )
            elif type in ('o',):
                ET.SubElement(
                    interconnect,
                    'direct', {
                        'name': name,
                        'output': name,
                        'input': "MUX.%s%s" % (type.upper(), index),
                    },
                )

pb_type_str = ET.tostring(pb_type_xml, pretty_print=True).decode('utf-8')
print("pb_type.xml", "-"*75)
print(pb_type_str)
print("-"*75)
with open(os.path.join(outdir, "pb_type.xml"), "w") as f:
    f.write(pb_type_str)


import sys; sys.exit(0)

mux_args = []
for i in args.order:
    if i == 'i':
        if args.split_inputs:
            for i in range(args.width):
                mux_args.append(args.name_input+str(i))
        else:
            mux_args.append(args.name_input)
    elif i == 'o':
        mux_args.append(args.name_output)
    elif i == 's':
        mux_args.append(args.name_select)
    else:
        assert False, "Unknown input argument."

