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

    - `(* FASM_xxxx *)` : All attributes with names starting from "FASM_" will
        be converted do metadata entries with corresponding lowercase names.

    - `(* FASM_xxxx_mmmm *)` : If there are modes and an attribute name begins
       with "FASM" and ends with an upper case mode name, then it is applied
       only for the matching mode. The base attribute name with mode name
       removed is converted to lowercase "fasm_xxxx"

The Verilog define "PB_TYPE" is set during generation.
"""

import os, sys
import argparse, re

import lxml.etree as ET

import yosys.run
from yosys.json import YosysJSON

sys.path.insert(0, "..")
from lib import xmlinc

INVALID_INSTANCE = -1


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


def update_attributes(attrs, new_attrs, ignore_list=()):
    """
    Updates one dictionary with elements from another. Prints message
    when a conflict occurs.
    """

    for key, value in new_attrs.items():

        if key in ignore_list:
            continue

        if key not in attrs:
            attrs[key] = value
        elif attrs[key] != value:
            print("Attribute conflict (!): '{}'='{}' vs '{}".format(
                  key, attrs[key], value))

    return attrs


def make_metadata(xml_parent, module_attrs, mode=None, all_modes=None):
    """
    Generates the XML <metadata> tag and fills it in according to the module
    attributes given.
    """

    metadata = {}

    # Find attributes beginning with "FASM_"
    for attr, value in module_attrs.items():
        if attr.startswith("FASM_"):

            # We have modes
            if mode is not None:
                is_mode_attr = False

                # Check if the attribute is relevant to a mode (any mode)
                for m in all_modes:
                    if attr.endswith("_" + m.upper()):
                        is_mode_attr = True

                        # Append it if relevant for current mode, skip otherwise
                        if m == mode:
                            name = attr.rsplit("_", 1)[0]
                            metadata[name.lower()] = value
                            break

                # This attribute is not mode relevant so add it as it is common
                if not is_mode_attr:
                    metadata[attr.lower()] = value

            # We do not have modes
            else:
                metadata[attr.lower()] = value

    # Store the metadata in XML (if any)
    if len(metadata):
        xml_metadata = ET.SubElement(xml_parent, 'metadata')
        for key, value in metadata.items():
            xml_meta = ET.SubElement(xml_metadata, "meta", {"name": key})
            xml_meta.text = value


def make_pb_content(yj, mod, outfile, xml_parent, mod_pname, submode=None, all_submodes=None):
    """Build the pb_type content - child pb_types, timing and direct interconnect,
    but not IO. This may be put directly inside <pb_type>, or inside <mode>."""

    def get_module_name(pin, instance=INVALID_INSTANCE):
        """Returns the name of the module relative to the pin and a boolean that indicates whether
        the module is a cell (True) or the top one (False)"""
        if instance <= INVALID_INSTANCE:
            instance = ""
        else:
            instance = "[" + str(instance) + "]"
        cname, cellpin = pin
        if cname.startswith("$"):
            return mod.cell_type(cname) + instance, True
        elif cname != mod.name:
            cname = mod.cell_type(cname)
            modname = mod_pb_name(yj.module(cname)) + instance
            return modname, True
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

    def make_direct_conn(
            ic_xml,
            src,
            dst,
            source_instance=INVALID_INSTANCE,
            dest_instance=INVALID_INSTANCE
    ):
        s_cellpin = get_cellpin(src)
        d_cellpin = get_cellpin(dst)
        s_cname, s_is_cell = get_module_name(src, source_instance)
        d_cname, d_is_cell = get_module_name(dst, dest_instance)

        s_port = create_port(s_cellpin, s_cname, s_is_cell, "input")
        d_port = create_port(d_cellpin, d_cname, d_is_cell, "output")

        dir_xml = ET.SubElement(ic_xml, 'direct')

        s_port_xml = ET.SubElement(dir_xml, 'port', s_port)
        d_port_xml = ET.SubElement(dir_xml, 'port', d_port)

        return dir_xml

    # Find out whether or not the module we are generating content for is a blackbox
    is_blackbox = (mod.attr("blackbox", 0) == 1) or not mod.cells

    # List of entries in format ((from_cell, from_pin), (to_cell, to_pin))
    interconn = []

    # Determine multiple instances of the same cell:
    cells = dict()
    for cname, i_of in mod.cells:
        if i_of in cells:
            cells[i_of]['count'] += 1
            cells[i_of]['is_multi_instance'] = True
            # assign unique instance number
            cells[i_of][cname] = cells[i_of]['count']
        else:
            cells[i_of] = dict()
            cells[i_of]['is_multi_instance'] = False
            cells[i_of]['count'] = 0
            cells[i_of][cname] = 0

    # Blackbox modules don't have inner cells or interconnect (but do still have timing)
    if (not is_blackbox) or submode is not None:
        # Process cells. First build the list of cnames.
        processed_cells = list()
        for cname, i_of in mod.cells:
            pb_name = strip_name(i_of)
            pbtype_already_included = False
            if i_of in processed_cells:
                # do not emit xml include for every instance of multi instace cell
                pbtype_already_included = True
            else:
                processed_cells.append(i_of)
            instance = INVALID_INSTANCE

            # If currently considered cell is a multi instance one, pass it's unique
            # instance number to connection creator. If not, pass INVALID_INSTANCE
            # constant
            if cells[i_of]['is_multi_instance']:
                instance = cells[i_of][cname]
            module_file = yj.get_module_file(i_of)
            module_path = os.path.dirname(module_file)
            module_basename = os.path.basename(module_file)

            # Heuristic for autogenerated files from w.py
            if not pbtype_already_included:
                wm = re.match(r"([A-Za-z0-9_]+)\.sim\.v", module_basename)
                if wm:
                    pb_type_path = "{}/{}.pb_type.xml".format(
                        module_path,
                        wm.group(1).lower()
                    )
                else:
                    pb_type_path = "{}/pb_type.xml".format(module_path)

                # inlude contents of the included pb_type, but update it's
                # num_pb value
                with open(pb_type_path, 'r') as inc_xml:
                    xml_inc = ET.fromstring(inc_xml.read().encode('utf-8'))
                    inc_attrib = xml_inc.attrib
                    inc_attrib['num_pb'] = str(cells[i_of]['count'] + 1)

                inc_pb_type = ET.SubElement(xml_parent, 'pb_type', inc_attrib)
                xmlinc.include_xml(
                    parent=inc_pb_type,
                    href=pb_type_path,
                    outfile=outfile,
                    xptr="xpointer(pb_type/child::node())"
                )

                # Append metadata
                make_metadata(
                    inc_pb_type,
                    mod.data["cells"][cname]["attributes"],
                    submode,
                    all_submodes
                )

            # In order to avoid overspecifying interconnect, there are two directions we currently
            # consider. All interconnect going INTO a cell, and interconnect going out of a cell
            # into a top level output - or all outputs if "mode" is used.
            inp_cons = mod.cell_conns(cname, "input")
            for pin, net in inp_cons:

                net_attrs = {}
                for net_name in mod.net_names_by_id(net):
                    update_attributes(net_attrs, mod.net_attrs(net_name), ("src"))

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
                    print(pin, net, drv_cell, drv_pin)
                    # check if we're driven by multi instance cell
                    drive_instance = INVALID_INSTANCE
                    drv_cell_type = [
                        c[1] for c in mod.cells if c[0] == drv_cell
                    ]
                    if len(drv_cell_type) != 0:
                        drv_cell_type = drv_cell_type[0]
                        if cells[drv_cell_type]['is_multi_instance']:
                            # get drv_cell unique instance number
                            drive_instance = cells[drv_cell_type][drv_cell]
                    interconn.append(
                        (
                            "direct",
                            net_attrs,
                            (drv_cell, drv_pin), (cname, pin), drive_instance,
                            instance
                        )
                    )

            out_cons = mod.cell_conns(cname, "output")
            for pin, net in out_cons:

                net_attrs = {}
                for net_name in mod.net_names_by_id(net):
                    update_attributes(net_attrs, mod.net_attrs(net_name), ("src"))

                sinks = mod.net_sinks(net)
                for sink_cell, sink_pin in sinks:
                    if sink_cell == mod.name:
                        #Only consider outputs from cell to top level IO. Inputs to other cells will be dealt with
                        #in those cells.
                        interconn.append(
                            (
                                "direct",
                                net_attrs,
                                (cname, pin), (sink_cell, sink_pin), instance,
                                INVALID_INSTANCE
                            )
                        )

        # Direct pin->pin connections
        for net in mod.nets:

            net_attrs = {}
            for net_name in mod.net_names_by_id(net):
                update_attributes(net_attrs, mod.net_attrs(net_name), ("src"))

            drv = mod.conn_io(net, "input")
            if not drv:
                continue
            assert len(drv) == 1, (
                "ERROR: net {} has multiple drivers {}, interconnect will be over specified"
                .format(net, drv)
            )
            for snk in mod.conn_io(net, "output"):
                conn = ("direct", net_attrs, (mod.name, drv[0]), (mod.name, snk), INVALID_INSTANCE, INVALID_INSTANCE)
                interconn.append(conn)

        ic_xml = ET.SubElement(xml_parent, "interconnect")

        # Process interconnect
        for type, attrs, source, dest, src_instance, dst_instance in interconn:

            # Write connection
            if type == "direct":
                conn_xml = make_direct_conn(ic_xml, source, dest, src_instance, dst_instance)
            elif type == "mux":
                print("MUX not supported yet!")  # TODO:
                continue
            else:
                print("Unknown connection type '{}'".format(type))
                continue

            # Write metadata
            make_metadata(conn_xml, attrs, submode, all_submodes)

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

    # Append metadata
    make_metadata(xml_parent, mod.module_attrs, submode, all_submodes)

def make_pb_type(yj, mod, outfile):
    """Build the pb_type for a given module. mod is the YosysModule object to
    generate."""

    modes = mod.attr("MODES", None)
    if modes is not None:
        modes = modes.split(";")
        modes = [mode.strip() for mode in modes]
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

    # set num_pb to 1, it will be updated if this pb_type
    # will be included by another one
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
            mode_xml = ET.SubElement(pb_type_xml, "mode", {"name": mode})
            # Rerun Yosys with mode parameter
            mode_yj = YosysJSON(
                yosys.run.vlog_to_json(
                    args.infiles,
                    flatten=False,
                    aig=False,
                    mode=mode,
                    module_with_mode=mod.name
                )
            )

            if args.dump_json:
                import json
                print("Mode '{}'".format(mode))
                print(json.dumps(mode_yj.data, sort_keys=True, indent=1))

            mode_mod = mode_yj.module(mod.name)
            make_pb_content(yj, mode_mod, outfile, mode_xml, mod_pname, mode, modes)
    else:
        make_pb_content(yj, mod, outfile, pb_type_xml, mod_pname)

    return pb_type_xml


def main(args):
    iname = os.path.basename(args.infiles[0])

    yosys.run.add_define("PB_TYPE")

    if args.includes:
        for include in args.includes.split(','):
            yosys.run.add_include(include)

    vjson = yosys.run.vlog_to_json(args.infiles, flatten=False, aig=False)
    yj = YosysJSON(vjson)

    if args.dump_json:
        import json
        print(json.dumps(yj.data, sort_keys=True, indent=1))

    if args.top is not None:
        top = args.top
    else:
        wm = re.match(r"([A-Za-z0-9_]+)\.sim\.v", iname)
        if wm:
            top = wm.group(1)
        else:
            print(
                "ERROR file name not of format %.sim.v ({}), cannot detect top level. Manually specify the top level module using --top"
                .format(iname)
            )
            sys.exit(1)

    tmod = yj.module(top)

    outfile = "pb_type.xml"
    if args.outfile is not None:
        outfile = args.outfile

    pb_type_xml = make_pb_type(yj, tmod, outfile)

    with open(outfile, "w") as fp:
        fp.write(
            ET.tostring(
                pb_type_xml,
                pretty_print=True,
                encoding="utf-8",
                xml_declaration=True
            ).decode('utf-8')
        )

        print("Generated {} from {}".format(outfile, iname))


if __name__ == "__main__":

    parser = argparse.ArgumentParser(
        description=__doc__.strip(),
        formatter_class=argparse.RawTextHelpFormatter
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
        '--includes',
        help="""\
    Command seperate list of include directories.
    """,
        default=""
    )

    parser.add_argument(
        '--top',
        help="""\
    Top level module, will usually be automatically determined from the file
    name %.sim.v
    """
    )

    parser.add_argument(
        '--outfile',
        '-o',
        type=str,
        default=None,
        help="""\
    Output filename
    """
    )

    parser.add_argument('--dump-json', action="store_true",
                        help="Prints Yosys JSON"
                        )

    args = parser.parse_args()
    sys.exit(main(args))
