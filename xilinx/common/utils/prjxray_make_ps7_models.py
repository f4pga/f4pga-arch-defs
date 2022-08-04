#!/usr/bin/env python3
"""
This script reads PS7 port definitions and generates the following:

- An XML file with the PS7 cell model for VPR
- An XML file with the PS7 cell pb_type definition for VPR
- A verilog file with simulation model (blackbox) of the PS7
- A techmap file for Yosys that ties all unconnected ports of the PS7 cell
  to GND in the same way as the vendor tools do.
"""
import argparse
import json
import os

# =============================================================================


def make_model_xml(file_name, ports, blif_model="VPR_PS7"):
    """
    Generates an XML file with model of the PS7 primitive given its ports
    definitions.
    """

    model_xml = """<models>
  <model name="{}">
""".format(blif_model)

    # Inputs
    model_xml += """    <input_ports>
"""
    for name in sorted(ports.keys()):
        port = ports[name]

        # Skip not relevant pins
        if port["class"] not in ["normal"]:
            continue

        if port["direction"] != "input":
            continue

        model_xml += "      <port name=\"{}\"/>\n".format(name)

    # Outputs
    model_xml += """    </input_ports>
    <output_ports>
"""
    for name in sorted(ports.keys()):
        port = ports[name]

        # Skip not relevant pins
        if port["class"] not in ["normal"]:
            continue

        if port["direction"] != "output":
            continue

        model_xml += "      <port name=\"{}\"/>\n".format(name)

    model_xml += """    </output_ports>
"""

    model_xml += """  </model>
</models>"""

    with open(file_name, "w") as fp:
        fp.write(model_xml)


def make_pbtype_xml(file_name, ports, pb_name="PS7", blif_model="VPR_PS7"):
    """
    Generates a leaf pb_type XML for the PS7 cell given its input ports
    definitions.
    """

    pb_xml = """<pb_type name="{}" blif_model=".subckt {}" num_pb="1">
""".format(pb_name, blif_model)

    for name in sorted(ports.keys()):
        port = ports[name]

        # Skip not relevant pins
        if port["class"] not in ["normal"]:
            continue

        pb_xml += "  <{} name=\"{}\" num_pins=\"{}\"/>\n".format(
            port["direction"].ljust(6), name, port["width"]
        )

    pb_xml += """</pb_type>
"""

    with open(file_name, "w") as fp:
        fp.write(pb_xml)


# =============================================================================


def make_verilog_blackbox(file_name, ports, blif_model="PS7_VPR"):
    """
    Generates a verilog blackbox instance for the PS7.
    """

    port_defs = []
    for name in sorted(ports.keys()):
        port = ports[name]

        # Skip not relevant pins (eg. MIO and DDR)
        if port["class"] not in ["normal"]:
            continue

        # Generate port definition
        if port["width"] > 1:
            port_str = "  {} [{:>2d}:{:>2d}] {}".format(
                port["direction"].ljust(6), port["max"], port["min"], name
            )
        else:
            port_str = "  {}         {}".format(
                port["direction"].ljust(6), name
            )

        port_defs.append(port_str)

    verilog = """(* blackbox *)
module {} (
{}
);

endmodule
""".format(blif_model, ",\n".join(port_defs))

    with open(file_name, "w") as fp:
        fp.write(verilog)


def make_verilog_techmap(file_name, ports, blif_model="PS7_VPR"):
    """
    Generates a techmap which transforms the PS7 cell instance to a new one
    with all unconnected inputs tied to GND.
    """
    port_defs = []
    port_conns = []
    param_defs = []
    wire_defs = []
    for name in sorted(ports.keys()):
        port = ports[name]

        # Skip not relevant pins
        if port["class"] not in ["normal", "mio"]:
            continue

        # Generate port definition
        if port["width"] > 1:
            port_str = "  {} [{:>2d}:{:>2d}] {}".format(
                port["direction"].ljust(6), port["max"], port["min"], name
            )
        else:
            port_str = "  {}         {}".format(
                port["direction"].ljust(6), name
            )

        port_defs.append(port_str)

        # MIO and DDR pins are not mapped as they are dummy
        if port["class"] == "mio":
            continue

        # This is an input port, needs to be tied to GND if unconnected
        if port["direction"] == "input":

            # Techmap parameter definition
            param_defs.append(
                "  parameter _TECHMAP_CONSTMSK_{}_ = 0;".format(name.upper())
            )
            param_defs.append(
                "  parameter _TECHMAP_CONSTVAL_{}_ = 0;".format(name.upper())
            )

            # Wire definition using generate statement. Necessary for detection
            # of unconnected ports.
            wire_defs.append(
                """
  generate if((_TECHMAP_CONSTMSK_{name_up}_ == {N}'d0) && (_TECHMAP_CONSTVAL_{name_up}_ == {N}'d0))
    wire [{M}:0] {name_lw} = {N}'d0;
  else
    wire [{M}:0] {name_lw} = {name};
  endgenerate""".format(
                    name=name,
                    name_up=name.upper(),
                    name_lw=name.lower(),
                    N=port["width"],
                    M=port["width"] - 1
                )
            )

            # Connection to the "generated" wire.
            port_conns.append(
                "  .{name:<25}({name_lwr})".format(
                    name=name, name_lwr=name.lower()
                )
            )

        # An output port
        else:

            # Direct connection
            port_conns.append("  .{name:<25}({name})".format(name=name))

    # Format the final verilog.
    verilog = """module PS7 (
{port_defs}
);

  // Techmap specific parameters.
{param_defs}

  // Detect all unconnected inputs and tie them to 0.
{wire_defs}

  // Replacement cell.
  {blif_model} _TECHMAP_REPLACE_ (
{port_conns}
  );

endmodule
""".format(
        port_defs=",\n".join(port_defs),
        param_defs="\n".join(param_defs),
        wire_defs="\n".join(wire_defs),
        port_conns=",\n".join(port_conns),
        blif_model=blif_model
    )

    with open(file_name, "w") as fp:
        fp.write(verilog)


# =============================================================================


def main():

    # Parse arguments
    parser = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter
    )

    parser.add_argument(
        "json",
        type=str,
        help="Input JSON file with PS7 pins grouped into ports"
    )
    parser.add_argument(
        "--path", type=str, default=".", help="Output folder. (def. '.')"
    )

    args = parser.parse_args()

    # Load ports
    with open(args.json, "r") as fp:
        ports = json.load(fp)

    model_name = "PS7_VPR"

    # Generte XML model
    make_model_xml(os.path.join(args.path, "ps7.model.xml"), ports, model_name)

    # Generate XML pb_type
    make_pbtype_xml(
        os.path.join(args.path, "ps7.pb_type.xml"), ports, "PS7", model_name
    )

    # Generate verilog blackbox definition
    make_verilog_blackbox(
        os.path.join(args.path, "ps7_sim.v"), ports, model_name
    )

    # Generate the techmap for Yosys
    make_verilog_techmap(
        os.path.join(args.path, "ps7_map.v"), ports, model_name
    )


# =============================================================================

if __name__ == "__main__":
    main()
