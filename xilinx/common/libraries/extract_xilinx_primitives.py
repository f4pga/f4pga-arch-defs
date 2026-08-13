#!/usr/bin/env python3
"""
Tool to extract Spartan-6 (and other Xilinx) primitive definitions from Yosys cells_sim.v.
This addresses f4pga-arch-defs Issue #1246 without needing to parse the PDF.

Usage:
  python3 extract_xilinx_primitives.py <path_to_yosys> <output_json>
"""

import os
import sys
import json
import xml.etree.ElementTree as ET
from xml.dom import minidom
import subprocess
import tempfile

def extract_primitives(yosys_bin, output_path):
    # Find cells_sim.v relative to yosys binary path or common installation paths
    yosys_dir = os.path.dirname(os.path.dirname(os.path.abspath(yosys_bin)))
    cells_sim_path = os.path.join(yosys_dir, "techlibs", "xilinx", "cells_sim.v")
    
    if not os.path.exists(cells_sim_path):
        cells_sim_path = os.path.join(yosys_dir, "share", "yosys", "xilinx", "cells_sim.v")
        
    if not os.path.exists(cells_sim_path):
        # Fallback to current directory struct
        cells_sim_path = "deps/yosys/techlibs/xilinx/cells_sim.v"

    if not os.path.exists(cells_sim_path):
        print(f"Error: Could not find cells_sim.v. Please ensure Yosys techlibs are available.")
        sys.exit(1)

    print(f"Using cells_sim.v from: {cells_sim_path}")

    # Create a temporary file for the Yosys JSON output
    with tempfile.NamedTemporaryFile(suffix='.json', delete=False) as tmp_file:
        tmp_json = tmp_file.name

    try:
        # Run Yosys to parse the Verilog and dump JSON AST
        cmd = [
            yosys_bin,
            "-p",
            f"read_verilog {cells_sim_path}; proc; write_json {tmp_json}"
        ]
        print("Running Yosys to parse primitives...")
        subprocess.run(cmd, check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

        # Load the Yosys JSON
        with open(tmp_json, 'r') as f:
            yosys_data = json.load(f)

        modules = yosys_data.get('modules', {})
        
        primitives = {}
        for mod_name, mod_data in modules.items():
            # Clean up module names (remove yosys internal prefixes if any)
            clean_name = mod_name.replace('\\', '').strip()
            
            ports = []
            for port_name, port_info in mod_data.get('ports', {}).items():
                ports.append({
                    "name": port_name,
                    "direction": port_info.get("direction", "unknown"),
                    "width": len(port_info.get("bits", []))
                })
            
            # Sort ports alphabetically for consistency
            ports.sort(key=lambda x: x['name'])
            
            attributes = []
            for param_name, param_val in mod_data.get('parameter_default_values', {}).items():
                # Yosys returns raw strings or binary literals
                # We'll clean them up for XML
                val_str = str(param_val).strip()
                attributes.append({
                    "name": param_name,
                    "type": "STRING", # Yosys doesn't easily expose the raw type here
                    "default": val_str,
                    "values": ""
                })
                
            attributes.sort(key=lambda x: x['name'])
            
            primitives[clean_name] = {
                "name": clean_name,
                "ports": ports,
                "attributes": attributes
            }

        print(f"Extracted {len(primitives)} primitives.")

        # Write the clean JSON output
        with open(output_path, 'w') as f:
            json.dump(primitives, f, indent=4)
        
        # Write F4PGA intermediate XML output (matching parse_pdf_modules.py)
        xml_path = output_path.replace('.json', '.xml')
        xml_elem = ET.Element("xml", source="yosys_cells_sim.v")
        
        for prim_name in sorted(primitives.keys()):
            prim = primitives[prim_name]
            module_elem = ET.SubElement(xml_elem, "module", name=prim["name"])
            
            for port in prim["ports"]:
                ET.SubElement(
                    module_elem, 
                    "port", 
                    name=port["name"], 
                    type=port["direction"], 
                    width=str(port["width"])
                )
                
            for attr in prim.get("attributes", []):
                ET.SubElement(
                    module_elem,
                    "attribute",
                    name=attr["name"],
                    type=attr["type"],
                    default=attr["default"],
                    values=attr["values"]
                )
                
        xmlstr = minidom.parseString(ET.tostring(xml_elem)).toprettyxml(indent="  ")
        with open(xml_path, 'w') as f:
            f.write(xmlstr)
            
        print(f"Successfully wrote primitive JSON definitions to {output_path}")
        print(f"Successfully wrote F4PGA intermediate XML models to {xml_path}")

    finally:
        # Cleanup temporary file
        if os.path.exists(tmp_json):
            os.remove(tmp_json)

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python3 extract_xilinx_primitives.py <path_to_yosys_bin> <output_json>")
        sys.exit(1)
        
    extract_primitives(sys.argv[1], sys.argv[2])
