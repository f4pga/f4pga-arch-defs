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
