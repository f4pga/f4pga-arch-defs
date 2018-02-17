#!/usr/bin/env python3

"""\
Convert a Verilog simulation model to a VPR `pb_type.xml`

The following are allowed on a top level module:
    
    - (* TYPE="bel|blackbox" *) : specify the type of the module
    (either a Basic ELement or a blackbox named after the pb_type
    
    - (* CLASS="lut|routing|flipflop|mem" *) : specify the class of an given
    instance. Must be specified for BELs

    - (* PB_NAME="name" *) : override the name of the pb_type
    (default: name of module)

The following are allowed on nets within modules (TODO: use proper Verilog timing):
    All are NYI at the moment!
    - (* SETUP="clk 10e-12" *) : specify setup time for a given clock
    
    - (* HOLD="clk 10e-12" *) : specify hold time for a given clock
    
    - (* CLK_TO_Q="clk 10e-12" *) : specify clock-to-output time for a given clock
    
    - (* PB_MUX=1 *) : if the signal is driven by a $mux cell, generate a pb_type <mux> element for it
"""

import yosys.run
import lxml.etree as ET
import argparse, re
import os, tempfile
from yosys.json import YosysJson


parser = argparse.ArgumentParser(description=__doc__.strip(), formatter_class=argparse.RawTextHelpFormatter)
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

vjson = yosys.run.vlog_to_json(args.infiles, False, False)
yj = YosysJson(vjson)

ET.register_namespace("xi", "http://www.w3.org/2001/XInclude")

if args.top is not None:
    top = args.top
else:
    top = yj.get_top()
tmod = yj.get_module(top)

def make_pb_type(mod, xml_parent = None):
    cname_to_pb_name = dict()

    def get_full_pin_name(pin):
        cname, cellpin = pin
        if cname != mod.get_name():
            cname = cname_to_pb_name[cname]
        return ("%s.%s" % (cname, cellpin))
    
    attrs = mod.get_module_attrs()
    pb_xml_attrs = dict()
    
    pb_xml_attrs["name"] = mod.get_attr("PB_NAME", mod.get_name())
    
    # Process type and class of module
    mod_type = mod.get_attr("TYPE", "blackbox") #TODO: is blackbox a good default?
    mod_cls = mod.get_attr("CLASS")
    if mod_type == "bel":
        assert mod_cls is not None
        if mod_cls == "lut":
            pb_xml_attrs["blif_model"] = ".names"
            pb_xml_attrs["class"] = "lut"
        elif mod_cls == "routing":
            # TODO: pb_xml_attrs["class"] = "routing"
            pass
        elif mod_cls == "flipflop":
            pb_xml_attrs["blif_model"] = ".latch"
            pb_xml_attrs["class"] = "flipflop"
        else:
            assert False
    elif mod_type == "blackbox":
        pb_xml_attrs["blif_model"] = ".subckt " + mod.get_name()
        if mod_cls is not None:
            if mod_cls == "mem":
                pb_xml_attrs["class"] = "memory"
            else:
                assert False
    else:
        assert False
    
    #TODO: might not always be the case? should be use Verilog `generate`s to detect this?
    pb_xml_attrs["num_pb"] = "1"
    
    if xml_parent is None:
        pb_type_xml = ET.Element("pb_type", pb_xml_attrs)
    else:
        pb_type_xml = ET.SubElement(xml_parent, "pb_type", pb_xml_attrs)
    
    # List of entries in format ((from_cell, from_pin), (to) 
    interconn = []
    
    # Process IOs
    clocks = yosys.run.list_clocks(args.infiles, mod.get_name())
    for name, width, iodir in mod.get_ports():
        ioattrs = {"name": name, "num_pins": str(width), "equivalent": "false"}
        if name in clocks:
            ET.SubElement(pb_type_xml, "clock", ioattrs)
        elif iodir == "input":
            ET.SubElement(pb_type_xml, "input", ioattrs)
        elif iodir == "output":
            ET.SubElement(pb_type_xml, "output", ioattrs)
        else:
            assert False
    # Process cells
    for cname, i_of in mod.get_cells(False):
        pb_name = mod.get_cell_attr(cname, "PB_NAME", i_of)
        pb_type_path = "./%s/pb_type.xml" % pb_name # TODO: might want to override path for complex hierarchies?
        ET.SubElement(pb_type_xml, "{http://www.w3.org/2001/XInclude}include", {'href': pb_type_path})
        cname_to_pb_name[cname] = pb_name
        # In order to avoid overspecifying interconnect, there are two directions we currently
        # consider. All interconnect going INTO a cell, and interconnect going out of a cell
        # into a top level output
        inp_cons = mod.get_cell_conns(cname, "input")
        for pin, net in inp_cons:
            drvs = mod.get_net_drivers(net)
            if len(drvs) == 0:
                print("WARNING: pin %s.%s has no driver, interconnect will be missing" % (pb_name, pin))
            elif len(drvs) > 1:
                print("WARNING: pin %s.%s has multiple drivers, interconnect will be overspecified" % (pb_name, pin))
            for drv_cell, drv_pin in drvs:
                interconn.append(((drv_cell, drv_pin), (cname, pin)))
        
        out_cons = mod.get_cell_conns(cname, "output")
        for pin, net in out_cons:
            sinks = mod.get_net_sinks(net)
            for sink_cell, sink_pin in sinks:
                if sink_cell == mod.get_name():
                    interconn.append(((cname, pin), (sink_cell, sink_pin)))
    
    ic_xml = ET.SubElement(pb_type_xml, "interconnect")
    # Process interconnect
    for source, dest in interconn:
        source_pin = get_full_pin_name(source)
        dest_pin = get_full_pin_name(dest)
        # TODO: should we use this, or determine a net name from the Verilog?
        ic_name = source_pin.replace(".","_") + "_to_" + dest_pin.replace(".","_")
        dir_xml = ET.SubElement(ic_xml, 'direct', {
            'name': ic_name,
            'input': source_pin,
            'output': dest_pin
        })
        
    # TODO: timing
    # TODO: muxes
    return pb_type_xml

pb_type_xml = make_pb_type(tmod, None)

outfile = "pb_type.xml"
if "o" in args and args.o is not None:
    outfile = args.o
    
f = open(outfile, 'w')
f.write(ET.tostring(pb_type_xml, pretty_print=True).decode('utf-8'))
f.close()
