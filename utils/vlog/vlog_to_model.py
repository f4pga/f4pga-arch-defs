#!/usr/bin/env python3
"""
Convert a Verilog simulation model to a VPR `model.xml`
"""
import yosys.run
import lxml.etree as ET
import argparse, re
import os, tempfile
from yosys.json import YosysJson


parser = argparse.ArgumentParser(description=__doc__.strip())
parser.add_argument(
    'infiles',
    metavar='input.v', type=str, nargs='+',
    help="""\
One or more Verilog input files, that will be passed to Yosys internally.
They should be enough to generate a flattened representation of the model,
so that paths through the model can be determined.
""")
parser.add_argument(
    '--top',
    help="""\
Top level module, not needed if only one module exists across all input Verilog
files, in which case that module will be used as the top level.
""")
parser.add_argument(
    '-o',
    help="""\
Output filename, default 'model.xml'
""")

args = parser.parse_args()

aig_json = yosys.run.vlog_to_json(args.infiles, True, True)

"""
Extract the pin from a line of the result of a Yosys select command
"""
def extract_pin(module, pstr, _regex=re.compile(r"([^/]+)/([^/]+)")):
    m = re.match(r"([^/]+)/([^/]+)", pstr)
    if m and m.group(1) == module:
        return m.group(2)
    else:
        return None
"""
Run a Yosys select command (given the expression and input files) on a module
and return the result as a list of pins

TODO: All of these functions involve a fairly large number of calls to Yosys
Although performance here is unlikely to be a major priority any time soon,
it might be worth investigating better options?

"""
def do_select(infiles, module, expr):
    outfile = tempfile.mktemp()
    sel_cmd = "prep -top %s -flatten; cd %s; select -write %s %s" % (module, module, outfile, expr)
    yosys.run.yosys_commands(sel_cmd, infiles)
    pins = []
    with open(outfile, 'r') as f:
        for net in f:
            snet = net.strip()
            if(len(snet) > 0):
                pin = extract_pin(module, snet)
                if pin is not None:
                    pins.append(pin)
    os.remove(outfile)
    return pins
    
def get_combinational_sinks(infiles, module, innet):
    return do_select(infiles, module, "%s %%coe* o:* %%i %s %%d" % (innet, innet))

def list_clocks(infiles, module):
    return do_select(infiles, module, "c:* %x:+[CLK] c:* %d")

def get_clock_assoc_signals(infiles, module, clk):
    return do_select(infiles, module, "select -list %s %%x* i:* o:* %%u %%i %s %%d" % (clk, clk))

if "top" in args:
    yj = YosysJson(aig_json, args.top)
else:
    yj = YosysJson(aig_json)    

top = yj.get_top()
models_xml = ET.Element("models")
model_xml = ET.SubElement(models_xml, "model", {'name': top})
ports = yj.get_ports()

inports_xml = ET.SubElement(model_xml, "input_ports")
outports_xml = ET.SubElement(model_xml, "output_ports")

clocks = list_clocks(args.infiles, top)
clk_sigs = dict()
for clk in clocks:
    clk_sigs[clk] = get_clock_assoc_signals(args.infiles, top, clk)

for name, width, iodir in ports:
    attrs = dict(name=name)
    sinks = get_combinational_sinks(args.infiles, top, name)
    if len(sinks) > 0:
        attrs["combinational_sink_ports"] = " ".join(sinks)
    if name in clocks:
        attrs["is_clock"] = "1"
    for clk in clocks:
        if name in clk_sigs[clk]:
            attrs["clock"] = clk
    if iodir == "input":
        ET.SubElement(inports_xml, "port", attrs)
    elif iodir == "output":
        ET.SubElement(outports_xml, "port", attrs)
    else:
        assert(False) #how does VPR specify inout (only applicable for PACKAGEPIN of an IO primitive)

outfile = "model.xml"
if "o" in args and args.o is not None:
    outfile = args.o
    
f = open(outfile, 'w')
f.write(ET.tostring(models_xml, pretty_print=True).decode('utf-8'))
f.close()
