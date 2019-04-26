#!/usr/bin/env python3
"""\
Convert a Verilog simulation model to a VPR `pb_type.xml`

The following are allowed on a top level module:

    - `(* blackbox *)` : specify that the module has no interconnect or child
    pb_types (but if modes are used then its modes are allowed to have these).
    This will also set the BLIF model to be `.subckt <name>` unless CLASS is
    also specified.

    - `(* CLASS="lut|routing|mux|flipflop|mem" *)` : specify the class of an given
    instance.

    - `(* MODES="mode1; mode2; ..." *)` : specify that the module has more than one functional
    mode, each with a given name. The module will be evaluated n times, each time setting
    the MODE parameter to the nth value in the list of mode names. Each evaluation will be
    put in a pb_type `<mode>` section named accordingly.

    - `(* MODEL_NAME="model" *)` : override the name used for <model> and for
    ".subckt name" in the BLIF model. Mostly intended for use with w.py, when several
    different pb_types implement the same model.

The following are allowed on nets within modules (TODO: use proper Verilog timing):
    - `(* SETUP="clk 10e-12" *)` : specify setup time for a given clock

    - `(* HOLD="clk 10e-12" *)` : specify hold time for a given clock

    - `(* CLK_TO_Q="clk 10e-12" *)` : specify clock-to-output time for a given clock

    - `(* DELAY_CONST_{input}="30e-12" *)` : specify a constant max delay from an input (applied to the output)

    - `(* DELAY_MATRIX_{input}="30e-12 35e-12; 20e-12 25e-12; ..." *)` : specify a VPR
        delay matrix (semicolons indicate rows). In this format columns specify
        inputs bits and rows specify output bits. This should be applied to the output.

The following are allowed on ports:
    - `(* CLOCK *)` : force a given port to be a clock

    - `(* ASSOC_CLOCK="RDCLK" *)` : force a port's associated clock to a given value

    - `(* PORT_CLASS="clock" *)` : specify the VPR "port_class"

The Verilog define "PB_TYPE" is set during generation.
"""

import os, sys
import argparse, re

import lxml.etree as ET

import yosys.run
from yosys.json import YosysJSON
import xmlinc

parser = argparse.ArgumentParser(
    description=__doc__.strip(), formatter_class=argparse.RawTextHelpFormatter
)
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

outfile = "pb_type.xml"
if "o" in args and args.o is not None:
    outfile = args.o

yosys.run.add_define("PB_TYPE")
if args.includes:
    for include in args.includes.split(','):
        yosys.run.add_include(include)

vjson = yosys.run.vlog_to_json(args.infiles, flatten=False, aig=False)
yj = YosysJSON(vjson)

if args.top is not None:
    top = args.top
else:
    wm = re.match(r"([A-Za-z0-9_]+)\.sim\.v", iname)
    if wm:
        top = wm.group(1).upper()
    else:
        print(
            "ERROR file name not of format %.sim.v ({}), cannot detect top level. Manually specify the top level module using --top"
            .format(iname)
        )
        sys.exit(1)

tmod = yj.module(top)


def mod_pb_name(mod):
    """Convert a Verilog module to a pb_type name in the format documented here:
    https://github.com/SymbiFlow/symbiflow-arch-defs/#names"""
    is_blackbox = (mod.attr("blackbox", 0) == 1)
    modes = mod.attr("MODES", None)
    has_modes = modes is not None
    # Process type and class of module
    mod_cls = mod.CLASS
    if mod_cls == "routing":
        return mod.name
    elif mod_cls == "mux":
        return mod.name
    elif mod_cls == "flipflop":
        return mod.name
    elif mod_cls == "lut":
        return mod.name
    elif is_blackbox and not has_modes:
        return mod.name
    else:
        #TODO: other types
        return mod.name


def strip_name(name):
    if '\\' in name:
        ts = name.find('\\')
        tf = name.rfind('\\')
        return name[ts + 1:tf]
    return name


def make_pb_content(yj, mod, xml_parent, mod_pname, is_submode=False):
    """Build the pb_type content - child pb_types, timing and direct interconnect,
    but not IO. This may be put directly inside <pb_type>, or inside <mode>."""

    def get_module_name(pin):
        """Returns the name of the module relative to the pin and a boolean that indicates whether
        the module is a cell (True) or the top one (False)"""
        cname, cellpin = pin
        if cname != mod.name:
            cname = mod.cell_type(cname)
            return mod_pb_name(yj.module(cname)), True
        else:
            return mod_pname, False

    def get_cellpin(pin):
        cname, cellpin = pin
        return cellpin

    def create_port(pin_name, mod_name, is_cell, direction):
        """Returns a dictionary containing the port definition. If the module is a cell, the port
        contains the 'from' attribute."""
        port = dict()
        port['name'] = pin_name
        port['type'] = direction

        if is_cell:
            port['from'] = mod_name

        return port

    def make_direct_conn(ic_xml, src, dst):
        s_cellpin = get_cellpin(src)
        d_cellpin = get_cellpin(dst)
        s_cname, s_is_cell = get_module_name(src)
        d_cname, d_is_cell = get_module_name(dst)

        s_port = create_port(s_cellpin, s_cname, s_is_cell, "input")
        d_port = create_port(d_cellpin, d_cname, d_is_cell, "output")

        dir_xml = ET.SubElement(ic_xml, 'direct')

        s_port_xml = ET.SubElement(dir_xml, 'port', s_port)
        d_port_xml = ET.SubElement(dir_xml, 'port', d_port)

    # Find out whether or not the module we are generating content for is a blackbox
    is_blackbox = (mod.attr("blackbox", 0) == 1) or not mod.cells

    # List of entries in format ((from_cell, from_pin), (to_cell, to_pin))
    interconn = []

    # Blackbox modules don't have inner cells or interconnect (but do still have timing)
    if (not is_blackbox) or is_submode:
        # Process cells. First build the list of cnames.
        for cname, i_of in mod.cells:
            pb_name = strip_name(i_of)
            module_file = yj.get_module_file(i_of)
            module_path = os.path.dirname(module_file)
            module_basename = os.path.basename(module_file)
            # Heuristic for autogenerated files from w.py
            wm = re.match(r"([A-Za-z0-9_]+)\.sim\.v", module_basename)
            if wm:
                pb_type_path = "{}/{}.pb_type.xml".format(
                    module_path,
                    wm.group(1).lower()
                )
            else:
                pb_type_path = "{}/pb_type.xml".format(module_path)
            xmlinc.include_xml(
                parent=xml_parent, href=pb_type_path, outfile=outfile
            )
            # In order to avoid overspecifying interconnect, there are two directions we currently
            # consider. All interconnect going INTO a cell, and interconnect going out of a cell
            # into a top level output - or all outputs if "mode" is used.
            inp_cons = mod.cell_conns(cname, "input")
            for pin, net in inp_cons:
                drvs = mod.net_drivers(net)
                assert len(drvs) > 0, (
                    "ERROR: pin {}.{} has no driver, interconnect will be missing\n{}"
                    .format(pb_name, pin, mod)
                )
                assert len(drvs) < 2, (
                    "ERROR: pin {}.{} has multiple drivers, interconnect will be overspecified"
                    .format(pb_name, pin)
                )
                for drv_cell, drv_pin in drvs:
                    interconn.append(((drv_cell, drv_pin), (cname, pin)))

            out_cons = mod.cell_conns(cname, "output")
            for pin, net in out_cons:
                sinks = mod.net_sinks(net)
                for sink_cell, sink_pin in sinks:
                    if sink_cell == mod.name:
                        #Only consider outputs from cell to top level IO. Inputs to other cells will be dealt with
                        #in those cells.
                        interconn.append(((cname, pin), (sink_cell, sink_pin)))

        # Direct pin->pin connections
        for net in mod.nets:
            drv = mod.conn_io(net, "input")
            if not drv:
                continue
            assert len(drv) == 1, (
                "ERROR: net {} has multiple drivers {}, interconnect will be over specified"
                .format(net, drv)
            )
            for snk in mod.conn_io(net, "output"):
                conn = ((mod.name, drv[0]), (mod.name, snk))
                interconn.append(conn)

        ic_xml = ET.SubElement(xml_parent, "interconnect")
        # Process interconnect
        for source, dest in interconn:
            make_direct_conn(ic_xml, source, dest)

    def process_clocked_tmg(tmgspec, port, xmltype, xml_parent):
        """Add a suitable timing spec if necessary to the pb_type"""
        if tmgspec is not None:
            splitspec = tmgspec.split(" ")
            assert len(
                splitspec
            ) == 2, 'bad timing specification "{}", must be of format "clock value"'.format(
                tmgspec
            )
            attrs = {"port": port, "clock": splitspec[0]}
            if xmltype == "T_clock_to_Q":
                attrs["max"] = splitspec[1]
            else:
                attrs["value"] = splitspec[1]
            ET.SubElement(xml_parent, xmltype, attrs)

    # Process timing
    for name, width, bits, iodir in mod.ports:
        port = "{}.{}".format(mod_pname, name)
        # Clocked timing
        Tsetup = mod.net_attr(name, "SETUP")
        Thold = mod.net_attr(name, "HOLD")
        Tctoq = mod.net_attr(name, "CLK_TO_Q")
        process_clocked_tmg(Tsetup, port, "T_setup", xml_parent)
        process_clocked_tmg(Thold, port, "T_hold", xml_parent)
        process_clocked_tmg(Tctoq, port, "T_clock_to_Q", xml_parent)

        # Combinational delays
        dly_prefix = "DELAY_CONST_"
        dly_mat_prefix = "DELAY_MATRIX_"
        for attr, atvalue in sorted(mod.net_attrs(name).items()):
            if attr.startswith(dly_prefix):
                # Single, constant delays
                inp = attr[len(dly_prefix):]
                inport = "{}.{}".format(mod_pname, inp)
                ET.SubElement(
                    xml_parent, "delay_constant", {
                        "in_port": inport,
                        "out_port": port,
                        "max": str(atvalue)
                    }
                )
            elif attr.startswith(dly_mat_prefix):
                # Constant delay matrices
                inp = attr[len(dly_mat_prefix):]
                inport = "{}.{}".format(mod_pname, inp)
                mat = "\n" + atvalue.replace(";", "\n") + "\n"
                xml_mat = ET.SubElement(
                    xml_parent, "delay_matrix", {
                        "in_port": inport,
                        "out_port": port,
                        "type": "max"
                    }
                )
                xml_mat.text = mat


def make_pb_type(yj, mod):
    """Build the pb_type for a given module. mod is the YosysModule object to
    generate."""

    modes = mod.attr("MODES", None)
    if modes is not None:
        modes = modes.split(";")
    mod_pname = mod_pb_name(mod)

    pb_xml_attrs = dict()
    pb_xml_attrs["name"] = mod_pname
    # If we are a blackbox with no modes, then generate a blif_model
    is_blackbox = mod.attr("blackbox", 0) == 1 or not mod.cells
    has_modes = modes is not None

    print("is_blackbox", is_blackbox, "has_modes?", has_modes)

    # Process type and class of module
    mod_cls = mod.CLASS
    if mod_cls is not None:
        if mod_cls == "lut":
            pb_xml_attrs["blif_model"] = ".names"
            pb_xml_attrs["class"] = "lut"
        elif mod_cls == "routing":
            # TODO: pb_xml_attrs["class"] = "routing"
            pass
        elif mod_cls == "mux":
            # TODO: ?
            pass
        elif mod_cls == "flipflop":
            pb_xml_attrs["blif_model"] = ".latch"
            pb_xml_attrs["class"] = "flipflop"
        else:
            assert False, "unknown class {}".format(mod_cls)
    elif is_blackbox and not has_modes:
        pb_xml_attrs["blif_model"
                     ] = ".subckt " + mod.attr("MODEL_NAME", mod.name)

    #TODO: might not always be the case? should be use Verilog `generate`s to detect this?
    pb_xml_attrs["num_pb"] = "1"
    pb_type_xml = ET.Element(
        "pb_type", pb_xml_attrs, nsmap={'xi': xmlinc.xi_url}
    )

    # Process IOs
    clocks = yosys.run.list_clocks(args.infiles, mod.name)
    for name, width, bits, iodir in mod.ports:
        ioattrs = {"name": name, "num_pins": str(width)}
        pclass = mod.net_attr(name, "PORT_CLASS")
        if pclass is not None:
            ioattrs["port_class"] = pclass
        if name in clocks:
            ET.SubElement(pb_type_xml, "clock", ioattrs)
        elif iodir == "input":
            ET.SubElement(pb_type_xml, "input", ioattrs)
        elif iodir == "output":
            ET.SubElement(pb_type_xml, "output", ioattrs)
        else:
            assert False, "bidirectional ports not supported in VPR pb_types"

    if has_modes:
        for mode in modes:
            smode = mode.strip()
            mode_xml = ET.SubElement(pb_type_xml, "mode", {"name": smode})
            # Rerun Yosys with mode parameter
            mode_yj = YosysJSON(
                yosys.run.vlog_to_json(
                    args.infiles,
                    flatten=False,
                    aig=False,
                    mode=smode,
                    module_with_mode=mod.name
                )
            )
            mode_mod = mode_yj.module(mod.name)
            make_pb_content(yj, mode_mod, mode_xml, mod_pname, True)
    else:
        make_pb_content(yj, mod, pb_type_xml, mod_pname)

    return pb_type_xml


parser = argparse.ArgumentParser(
    description=__doc__.strip(), formatter_class=argparse.RawTextHelpFormatter
)
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
    '--outfile',
    '-o',
    type=argparse.FileType('w'),
    default="pb_type.xml",
    help="""\
Output filename, default 'model.xml'
"""
)


def main(args):
    iname = os.path.basename(args.infiles[0])

    yosys.run.add_define("PB_TYPE")
    vjson = yosys.run.vlog_to_json(args.infiles, flatten=False, aig=False)
    yj = YosysJSON(vjson)

    if args.top is not None:
        top = args.top
    else:
        wm = re.match(r"([A-Za-z0-9_]+)\.sim\.v", iname)
        if wm:
            top = wm.group(1).upper()
        else:
            print(
                "ERROR file name not of format %.sim.v ({}), cannot detect top level. Manually specify the top level module using --top"
                .format(iname)
            )
            sys.exit(1)

    tmod = yj.module(top)

    pb_type_xml = make_pb_type(yj, tmod)

    args.outfile.write(
        ET.tostring(
            pb_type_xml,
            pretty_print=True,
            encoding="utf-8",
            xml_declaration=True
        ).decode('utf-8')
    )
    print("Generated {} from {}".format(args.outfile.name, iname))
    args.outfile.close()


if __name__ == "__main__":
    args = parser.parse_args()
    sys.exit(main(args))
