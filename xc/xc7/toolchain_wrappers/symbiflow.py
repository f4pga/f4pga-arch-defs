#!/usr/bin/python3

import os
import json
import argparse
import shutil
import subprocess

mypath = os.path.realpath(os.sys.argv[0])
mypath = os.path.dirname(mypath)

share_dir_path = os.path.realpath(os.path.join(mypath, '../share/symbiflow'))
techmap_path = os.path.join(share_dir_path, 'techmaps/xc7_vpr/techmap')
utils_path = os.path.join(share_dir_path, 'scripts')
synth_tcl_path = os.path.join(utils_path, 'xc7/synth.tcl')
conv_tcl_path = os.path.join(utils_path, 'xc7/conv.tcl')
split_inouts = os.path.join(utils_path, 'split_inouts.py')

def fatal(code, message):
    print(f'[FATAL ERROR]: {message}')
    exit(code)

def setup_argparser():
    parser = argparse.ArgumentParser(description="Execute SymbiFlow flow")
    parser.add_argument('flow', nargs=1, metavar='<flow path>', type=str,
                        help='Path to flow definition file')
    return parser

# Execute subroutine
def sub(*args, env={}):
    out = subprocess.run(args, capture_output=True, env=env)
    if out.returncode != 0:
        exit(out.returncode)
    return out.stdout

def yosys_synth(top, device, part, verilog_files=[], out_json=None, out_sdc=None,
                synth_json=None, out_synth_v=None, out_eblif=None,
                out_fasm_extra=None, database_dir=None, use_roi=False, log=None):
    # Setup environmental variables for the YOSYS TCL script
    if not out_json:
        out_json = top + '.json'
    if not out_sdc:
        out_sdc = top + '.sdc'
    if not synth_json:
        synth_json = top + '_io.json'
    if not out_synth_v:
        out_synth_v = top + '_synth.v'
    if not out_eblif:
        out_eblif = top + '.eblif'
    if not out_fasm_extra:
        out_fasm_extra = top + '_fasm_extra.fasm'
    if not database_dir:
        database_dir = sub('prjxray-config')
    part_json_path = os.path.join(database_dir, device, part, 'part.json')
    optional = []
    if log:
        optional += ['-l', log]
    env = {
        'USE_ROI': 'FALSE',
        'TOP': top,
        'OUT_JSON': out_json,
        'OUT_SDC': out_sdc,
        'PART_JSON': os.path.realpath(part_json_path),
        'OUT_FASM_EXTRA': out_fasm_extra,
        'PYTHON3': shutil.which('python3')
    }
    if use_roi:
        env['USE_ROI'] = 'TRUE'
    return sub('yosys', '-p', 'tcl ' + synth_tcl_path, *optional, *verilog_files,
               env=env)

parser = setup_argparser()
args = parser.parse_args()

flow_path = args.flow[0]

flow_def = None
try:
    with open(flow_path, 'r') as flow_def_file:
        flow_def = flow_def_file.read()
except FileNotFoundError as _:
    fatal(-1, 'The provided flow definition file does not exist')

flow = json.loads(flow_def)

if not flow['platform_name']:
    fatal(-1, 'Flow is missing platform name')
if not (type(flow['platform_name']) is str):
    fatal(-1, '`platform_name` field in flow definitionis is not a string.')
platform_path = flow['platform_name'] + '.json'
platform_def = None
try:
    with open(platform_path) as platform_file:
        platform_def = platform_file.read()
except FileNotFoundError as _:
    fatal(-1, f'The platform flow definition file {platform_path} for the platform '
          f'{flow["platform_name"]} referenced in flow definition file {flow_path} '
          'cannot be found.')

platform_flow = json.loads(platform_def)

if not flow['synthesize']:
    fatal(-1, '`synthsize` section in flow definitionis is missing.')
if not (type(flow['synthesize']) is dict):
    fatal(-1, '`synthesize` section in flow definitionis not an object.')

if not flow['synthesize']['top']:
    fatal(-1, '`synthsize.top` field in flow definitionis is missing.')
if not (type(flow['synthesize']['top']) is str):
    fatal(-1, '`synthesize.top` field in flow definitionis is not a string.')

if not flow['synthesize']['sources']:
    fatal(-1, '`synthsize.sources` field in flow definitionis is missing.')
if not (type(flow['synthesize']['sources']) is list):
    fatal(-1, '`synthesize.sources` field in flow definitionis is not a list. ')

top = flow['synthesize']['top']
sources = flow['synthesize']['sources']

print(flow)

yosys_synth(flow['synthesize']['top'],
            platform_flow['device'], platform_flow['part_name'],
            verilog_files=sources,
            log=flow['synthesize']['log']
)