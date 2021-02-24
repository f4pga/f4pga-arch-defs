"""Tool for generating pb_type/model/cells_[sim|map] prototypes from cells_data JSONs.

utils/build_primitive_prototypes.py is a helper script to accelerate development
of adding support for new primitves. It uses cells_data JSONs (attributes and ports)
to generate XMLs: pb_type and model and verilog prototypes for cells_sim and cells_map.

The output files of the script should be treated as prototypes - they may need
some manual adjustments.

"""
import argparse
import os
import json
import re
import lxml.etree as ET

BIN = "BIN"
BOOL = "BOOL"
INT = "INT"
STR = "STR"


def build_pb_type_prototype(ports, attrs, name):
    pb_type_xml = ET.Element(
        "pb_type", {
            "name": name.upper(),
            "num_pb": "1",
            "blif_model": ".subckt {}_VPR".format(name.upper())
        }
    )

    endswith_int = re.compile("[0-9]*$")
    for port_name, config in ports.items():
        int_present = re.search(endswith_int, port_name).group(0)
        trimmed_port_name = port_name.strip(int_present)
        input_type = config["direction"]
        width = config["width"]
        if trimmed_port_name.endswith("CLK"):
            input_type = "clock"

        ET.SubElement(
            pb_type_xml, input_type, {
                "name": port_name,
                "num_pins": str(width),
            }
        )

    xml_fasm_params = "\n"
    for attr_name, config in attrs.items():
        attr_type = config["type"]
        values = config["values"]
        digits = config["digits"]
        if attr_type == BIN or attr_type == INT:
            fasm_param = "      {}[{}:0] = {}\n".format(
                attr_name, digits - 1, attr_name
            )
        elif attr_type == BOOL:
            fasm_param = "      {} = {}\n".format(attr_name, attr_name)
        else:
            assert attr_type == STR
            for val in values:
                fasm_param = "      {}.{} = {}_{}\n".format(
                    attr_name, val, attr_name, val
                )
        xml_fasm_params += fasm_param

    metadata = ET.SubElement(pb_type_xml, "metadata")
    meta = ET.SubElement(metadata, "meta", {"name": "fasm_params"})
    meta.text = xml_fasm_params

    with open("{}.pb_type.xml".format(name), "w") as f:
        xml_str = ET.tostring(pb_type_xml, pretty_print=True).decode("utf-8")
        f.write(xml_str)


def build_model_prototype(ports, name):
    model_xml = ET.Element("models")
    model = ET.SubElement(
        model_xml, "model", {"name": "{}_VPR".format(name.upper())}
    )
    input_ports = ET.SubElement(model, "input_ports")
    output_ports = ET.SubElement(model, "output_ports")

    endswith_int = re.compile("[0-9]*$")
    for port_name, config in ports.items():
        input_type = config["direction"]
        int_present = re.search(endswith_int, port_name).group(0)
        trimmed_port_name = port_name.strip(int_present)
        if trimmed_port_name.endswith("CLK"):
            ET.SubElement(
                input_ports, "port", {
                    "name": port_name,
                    "is_clock": "1"
                }
            )
        elif input_type == "input":
            ET.SubElement(input_ports, "port", {
                "name": port_name,
            })
        else:
            ET.SubElement(output_ports, "port", {
                "name": port_name,
            })

    with open("{}.model.xml".format(name), "w") as f:
        xml_str = ET.tostring(model_xml, pretty_print=True).decode("utf-8")
        f.write(xml_str)


def build_cells_prototypes(ports, attrs, name):
    verilog_sim_module = "module {}_VPR (\n".format(name.upper())

    ports_str = list()
    for port_name, config in ports.items():
        direction = config["direction"]
        width = config["width"]
        port_str = "  input" if direction == "input" else "  output"
        if width > 1:
            port_str += " [{}:0]".format(width - 1)
        port_str += " {},".format(port_name)
        ports_str.append(port_str)

    ports_str[-1] = ports_str[-1][:-1] + "\n"
    verilog_sim_module += "\n".join(port for port in ports_str)
    verilog_sim_module += ");\n"

    fasm_params_str = list()
    for attr_name, config in attrs.items():
        attr_type = config["type"]
        values = config["values"]
        digits = config["digits"]
        if attr_type == BIN:
            # Default single value
            if type(values) is int:
                fasm_param_str = "  parameter [{}:0] {} = {}'d{};" \
                                 .format(digits - 1, attr_name, digits, values)
            # Choice, pick the 1st one as default
            elif type(values) is list and len(values) > 1:
                fasm_param_str = "  parameter [{}:0] {} = {}'d{};" \
                                 .format(digits - 1, attr_name, digits, values[0])
            else:
                fasm_param_str = "  parameter [{}:0] {} = {}'d0;" \
                                 .format(digits - 1, attr_name, digits)
        elif attr_type == BOOL or attr_type == STR:
            fasm_param_str = "  parameter {} = \"{}\";" \
                             .format(attr_name, values[0])
        else:
            assert attr_type == INT
            fasm_param_str = "  parameter integer {} = {};" \
                             .format(attr_name, values[0])

        fasm_params_str.append(fasm_param_str)

    verilog_sim_module += "\n".join(param for param in fasm_params_str)
    verilog_map_module = verilog_sim_module.replace(
        "{}_VPR".format(name.upper()), name.upper()
    )
    verilog_sim_module += "\nendmodule"

    verilog_map_module += "\n\n  {}_VPR #(\n".format(name.upper())

    init_fasm_params_str = list()
    for attr_name, config in attrs.items():
        attr_type = config["type"]
        if attr_type == BOOL:
            init_fasm_param_str = "    .{}({} == \"TRUE\"),".format(
                attr_name, attr_name
            )
        else:
            init_fasm_param_str = "    .{}({}),".format(attr_name, attr_name)
        init_fasm_params_str.append(init_fasm_param_str)

    init_fasm_params_str[-1] = init_fasm_params_str[-1][:-1] + "\n"
    verilog_map_module += "\n".join(param for param in init_fasm_params_str)
    verilog_map_module += "  ) _TECHMAP_REPLACE_ (\n"

    init_ports_str = list()
    for port in ports.keys():
        init_port_str = "    .{}({}),".format(port, port)
        init_ports_str.append(init_port_str)

    init_ports_str[-1] = init_ports_str[-1][:-1] + "\n"
    verilog_map_module += "\n".join(port for port in init_ports_str)
    verilog_map_module += "  );\nendmodule"

    with open("{}_cells_sim.v".format(name), "w") as f:
        f.write(verilog_sim_module)

    with open("{}_cells_map.v".format(name), "w") as f:
        f.write(verilog_map_module)


def main():
    parser = argparse.ArgumentParser(
        description=
        "Create prototypes for model, pb_type and cells_sim/map modules "\
        "from attributes and ports files"
    )
    parser.add_argument(
        "--arch", help="Architectures available: artix7, kintex7, zynq7"
    )
    parser.add_argument(
        "--name",
        help=
        "Name of the site used to import JSONs: e.g. gtpe2_channel, pcie_2_1"
    )
    parser.add_argument("--prjxray-db", help="Path to prjxray-db directory")

    args = parser.parse_args()

    assert args.arch in ["artix7", "kintex7", "zynq7"]

    attrs_file = os.path.join(
        args.prjxray_db, args.arch, "{}_attrs.json".format(args.name)
    )
    ports_file = os.path.join(
        args.prjxray_db, args.arch, "{}_ports.json".format(args.name)
    )

    assert os.path.exists(attrs_file) and os.path.exists(ports_file)

    with open(attrs_file, "r") as f:
        attrs = json.load(f)

    with open(ports_file) as f:
        ports = json.load(f)

    build_model_prototype(ports, args.name)
    build_pb_type_prototype(ports, attrs, args.name)
    build_cells_prototypes(ports, attrs, args.name)


if __name__ == "__main__":
    main()
