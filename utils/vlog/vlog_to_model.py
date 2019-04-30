#!/usr/bin/env python3
"""
Convert a Verilog simulation model to a VPR `model.xml`

The following Verilog attributes are considered on ports:
    - `(* CLOCK *)` : force a given port to be a clock

    - `(* ASSOC_CLOCK="RDCLK" *)` : force a port's associated clock to a given value

The following Verilog attributes are considered on modules:
    - `(* MODEL_NAME="model" *)` : override the name used for <model> and for
    ".subckt name" in the BLIF model. Mostly intended for use with w.py, when several
    different pb_types implement the same model.

    - `(* CLASS="lut|routing|mux|flipflop|mem" *)` : specify the class of an given
    instance. A model will not be generated for the `lut`, `routing` or `flipflop`
    class.
"""
import argparse, re, json
import os, sys

import lxml.etree as ET

import yosys.run
from yosys.json import YosysJSON
import xmlinc


def is_registered(tmod, bits, iodir, clk):
    """Checks if a specific i/o port is registered

    Returns a boolean value
    -------
    is_reg: bool
    """
    is_reg = False
    for cell, ctype in tmod.all_cells:
        if ctype != "$dff":
            continue

        # The clock is not related to the given port
        if tmod.cell_clk_conn(cell) != tmod.port_conns(clk):
            continue

        if iodir == "input" and (
            (set(bits) & set(tmod.cell_conn_list(cell, "D"))) == set(bits)):
            return True
        elif iodir == "output" and (
            (set(bits) & set(tmod.cell_conn_list(cell, "Q"))) == set(bits)):
            return True
        else:
            continue

    return is_reg


def is_registered_path(tmod, pin, pout):
    """Checks if a i/o path is sequential. If that is the case
    no combinational_sink_port is needed

    Returns a boolean value
    """

    for cell, ctype in tmod.all_cells:
        if ctype != "$dff":
            continue

        if tmod.port_conns(pin) == tmod.cell_conn_list(
                cell, "D") and tmod.port_conns(pout) == tmod.cell_conn_list(
                    cell, "Q"):
            return True

    return False


parser = argparse.ArgumentParser(description=__doc__.strip())
parser.add_argument(
    'infiles',
    metavar='input.v',
    type=str,
    nargs='+',
    help="""\
One or more Verilog input files, that will be passed to Yosys internally.
They should be enough to generate a flattened representation of the model,
so that paths through the model can be determined.
"""
)
parser.add_argument(
    '--top',
    help="""\
Top level module, will usually be automatically determined from the file name
%.sim.v
"""
)
parser.add_argument(
    '--includes',
    help="""\
Command seperate list of include directories.
""",
    default=""
)
parser.add_argument('-o', help="""\
Output filename, default 'model.xml'
""")

args = parser.parse_args()
iname = os.path.basename(args.infiles[0])

outfile = "model.xml"
if "o" in args and args.o is not None:
    outfile = args.o

if args.includes:
    for include in args.includes.split(','):
        yosys.run.add_include(include)

aig_json = yosys.run.vlog_to_json(args.infiles, flatten=True, aig=True)

if args.top is not None:
    yj = YosysJSON(aig_json, args.top)
    top = yj.top
else:
    wm = re.match(r"([A-Za-z0-9_]+)\.sim\.v", iname)
    if wm:
        top = wm.group(1).upper()
    else:
        print(
            "ERROR file name not of format %.sim.v ({}), cannot detect top level. Manually specify the top level module using --top"
        ).format(iname)
        sys.exit(1)
    yj = YosysJSON(aig_json, top)

if top is None:
    print(
        "ERROR: more than one module in design, cannot detect top level. Manually specify the top level module using --top"
    )
    sys.exit(1)

tmod = yj.top_module
models_xml = ET.Element("models", nsmap={'xi': xmlinc.xi_url})

inc_re = re.compile(r'^\s*`include\s+"([^"]+)"')

deps_files = set()
# XML dependencies need to correspond 1:1 with Verilog includes, so we have
# to do this manually rather than using Yosys
with open(args.infiles[0], 'r') as f:
    for line in f:
        im = inc_re.match(line)
        if not im:
            continue
        deps_files.add(im.group(1))

if True:
    # Has dependencies, not a leaf model
    for df in sorted(deps_files):
        abs_base = os.path.dirname(os.path.abspath(args.infiles[0]))
        abs_dep = os.path.normpath(os.path.join(abs_base, df))
        module_path = os.path.dirname(abs_dep)
        module_basename = os.path.basename(abs_dep)
        wm = re.match(r"([A-Za-z0-9_]+)\.sim\.v", module_basename)
        if wm:
            model_path = "{}/{}.model.xml".format(
                module_path,
                wm.group(1).lower()
            )
        else:
            assert False, "included Verilog file name {} does not follow pattern %%.sim.v".format(
                module_basename
            )
        xmlinc.include_xml(
            parent=models_xml,
            href=model_path,
            outfile=outfile,
            xptr="xpointer(models/child::node())"
        )
if True:
    # Is a leaf model
    topname = tmod.attr("MODEL_NAME", top)
    modclass = tmod.attr("CLASS", "")

    if modclass not in ("lut", "routing", "flipflop"):
        model_xml = ET.SubElement(models_xml, "model", {'name': topname})
        ports = tmod.ports

        inports_xml = ET.SubElement(model_xml, "input_ports")
        outports_xml = ET.SubElement(model_xml, "output_ports")

        clocks = yosys.run.list_clocks(args.infiles, top)

        for name, width, bits, iodir in ports:
            attrs = dict(name=name)
            sinks = yosys.run.get_combinational_sinks(args.infiles, top, name)

            # Removes comb sinks if path from in to out goes through a dff
            for sink in sinks:
                if is_registered_path(tmod, name, sink):
                    sinks.remove(sink)

            # FIXME: Check if ignoring clock for "combination_sink_ports" is a
            # valid thing to do.
            if name in clocks:
                attrs["is_clock"] = "1"
            else:
                if len(sinks) > 0 and iodir == "input":
                    attrs["combinational_sink_ports"] = " ".join(sinks)
                for clk in clocks:
                    if is_registered(tmod, bits, iodir, clk):
                        attrs["clock"] = clk
                assoc_clk = tmod.net_attr(name, "ASSOC_CLOCK")
                if assoc_clk is not None:
                    attrs["clock"] = assoc_clk
            if iodir == "input":
                ET.SubElement(inports_xml, "port", attrs)
            elif iodir == "output":
                ET.SubElement(outports_xml, "port", attrs)
            else:
                assert False, "bidirectional ports not permitted in VPR models"

if len(models_xml) == 0:
    models_xml.insert(0, ET.Comment("this file is intentionally left blank"))

f = open(outfile, 'w')
f.write(ET.tostring(models_xml, pretty_print=True).decode('utf-8'))
f.close()
print("Generated {} from {}".format(outfile, iname))
