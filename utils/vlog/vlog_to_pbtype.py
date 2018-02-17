#!/usr/bin/python3
import yosys_exec
import lxml.etree as ET
import argparse, re
import os, tempfile
from yosys_json import YosysJson

"""
Convert a Verilog simulation model to a VPR `pb_type.xml`

The following Verilog attributes are allowed on instances:
    - (* PB_PATH="../path/to/pb_type.xml" *) : import the pb_type for a given instance
        from an external XML file instead of including it inline.
    
    - (* GENERATE_PB *) : generate (and overwrite if applicable) the above file, as well as including it
        
The following are allowed on both instances (except where PB_PATH is set but GENERATE_PB isn't), and
the top level module.
    
    - (* BLIF_MODEL=".latch" *) : specify the corresponding blif_model for a given instance
    
    - (* CLASS="flipflop" *) : specify the corresponding class for a given instance

    - (* PB_NAME="name" *) : override the name of the pb_type (default: cell type)

The following are allowed on nets within modules:

    - (* SETUP="clk 10e-12" *) : specify setup time for a given clock
    
    - (* HOLD="clk 10e-12" *) : specify hold time for a given clock
    
    - (* CLK_TO_Q="clk 10e-12" *) : specify clock-to-output time for a given clock
    
    - (* PB_MUX=1 *) : if the signal is driven by a $mux cell, generate a pb_type <mux> element for it
"""

parser = argparse.ArgumentParser(description='Convert a Verilog simulation model into a VPR pb_type.xml file')
parser.add_argument('infiles', metavar='input.v', type=str, nargs='+',
                    help='one or more Verilog input files')
parser.add_argument('--top', help='top level module, not needed if only one module across all files')
parser.add_argument('-o', help='output filename, default model.xml')

args = parser.parse_args()

vjson = yosys_exec.vlog_to_json(args.infiles, False, False)
yj = YosysJson(vjson)
