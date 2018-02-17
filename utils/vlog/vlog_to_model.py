#!/usr/bin/python3
import yosys_exec
import lxml.etree as ET
import argparse, re
import os, tempfile
from yosys_json import YosysJson

"""
Convert a Verilog simulation model to a VPR `model.xml`
"""

parser = argparse.ArgumentParser(description='Convert a Verilog simulation model into a VPR model.xml file')
parser.add_argument('infiles', metavar='input.v', type=str, nargs='+',
                    help='one or more Verilog input files')
parser.add_argument('--top', help='top level module, not needed if only one module across all files')
parser.add_argument('-o', help='output filename, default model.xml')

args = parser.parse_args()

aig_json = yosys_exec.vlog_to_json(args.infiles, True, True)

# TODO: All of these functions involve a fairly large number of calls to Yosys
# Although performance here is unlikely to be a major priority any time soon,
# it might be worth investigating better options?

def do_select(infiles, module, expr):
    outfile = tempfile.mktemp()
    sel_cmd = "prep -top %s -flatten; cd %s; select -write %s %s" % (module, module, outfile, expr)
    yosys_exec.run_yosys_commands(sel_cmd, infiles)
    pins = []
    with open(outfile, 'r') as f:
        for net in f:
            snet = net.strip()
            if(len(snet) > 0):
                m = re.match(r"([^/]+)/([^/]+)", snet)
                if m and m.group(1) == module:
                    pins.append(m.group(2))
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
models = ET.Element("models")
model = ET.SubElement(models, "model", dict(name=top))
ports = yj.get_ports()

inports = ET.SubElement(model, "input_ports")
outports = ET.SubElement(model, "output_ports")

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
        ET.SubElement(inports, "port", attrs)
    elif iodir == "output":
        ET.SubElement(outports, "port", attrs)
    else:
        assert(False) #how does VPR specify inout (only applicable for PACKAGEPIN of an IO primitive)

outfile = "model.xml"
if "o" in args and args.o is not None:
    outfile = args.o
    
f = open(outfile, 'w')
f.write(ET.tostring(models, pretty_print=True).decode('utf-8'))
f.close()
