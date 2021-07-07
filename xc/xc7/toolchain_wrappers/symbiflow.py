#!/usr/bin/python3

import os
import json
import argparse
from posixpath import realpath
import shutil
import subprocess

mypath = os.path.realpath(os.sys.argv[0])
mypath = os.path.dirname(mypath)

share_dir_path = os.path.realpath(os.path.join(mypath, '../share/symbiflow'))
# techmap_path = os.path.join(share_dir_path, 'techmaps/xc7_vpr/techmap')
utils_path = os.path.join(share_dir_path, 'scripts')
# synth_tcl_path = os.path.join(utils_path, 'xc7/synth.tcl')
# conv_tcl_path = os.path.join(utils_path, 'xc7/conv.tcl')
split_inouts = os.path.join(utils_path, 'split_inouts.py')

def fatal(code, message):
    print(f'[FATAL ERROR]: {message}')
    exit(code)

def setup_argparser():
    parser = argparse.ArgumentParser(description="Execute SymbiFlow flow")
    parser.add_argument('flow', nargs=1, metavar='<flow path>', type=str,
                        help='Path to flow definition file')
    parser.add_argument('-s', '--synth', action='store_true',
                        help="Perform synthesis stage")
    return parser

# Execute subroutine
def sub(*args, env=None):
    # print(args)
    out = subprocess.run(args, capture_output=True, env=env)
    if out.returncode != 0:
        print(f'[ERROR]: args[0] non-zero return code.\nstderr:\n{str(out.stderr)}')
        exit(out.returncode)
    return out.stdout

# Setup environmental variables for YOSYS TCL scripts
def yosys_setup_tcl_env(build_dir, top, bitstream_device, part, techmap_path,
                        out_json=None, out_sdc=None, synth_json=None,
                        out_synth_v=None, out_eblif=None, out_fasm_extra=None,
                        database_dir=None, use_roi=False, xdc_files=None):
    if not out_json:
        out_json = os.path.join(build_dir, top + '.json')
    if not out_sdc:
        out_sdc = os.path.join(build_dir, top + '.sdc')
    if not synth_json:
        synth_json = os.path.join(build_dir, top + '_io.json')
    if not out_synth_v:
        out_synth_v = os.path.join(build_dir, top + '_synth.v')
    if not out_eblif:
        out_eblif = os.path.join(build_dir, top + '.eblif')
    if not out_fasm_extra:
        out_fasm_extra = os.path.join(build_dir, top + '_fasm_extra.fasm')
    if not database_dir:
        database_dir = sub('prjxray-config').decode().replace('\n', '')
    part_json_path = \
        os.path.join(database_dir, bitstream_device, part, 'part.json')
    env = {
        'USE_ROI': 'FALSE',
        'TOP': top,
        'OUT_JSON': out_json,
        'OUT_SDC': out_sdc,
        'PART_JSON': os.path.realpath(part_json_path),
        'OUT_FASM_EXTRA': out_fasm_extra,
        'TECHMAP_PATH': techmap_path,
        'OUT_SYNTH_V': out_synth_v,
        'OUT_EBLIF': out_eblif,
        'PYTHON3': shutil.which('python3'),
        'UTILS_PATH': utils_path
    }
    if use_roi:
        env['USE_ROI'] = 'TRUE'
    if xdc_files:
        env['INPUT_XDC_FILES'] = ' '.join(xdc_files)
    return env
        


def yosys_synth(tcl, tcl_env, verilog_files=[], log=None):
    # Set up environment for TCL weirdness
    optional = []
    if log:
        optional += ['-l', log]
    env = os.environ.copy()
    env.update(tcl_env)
    
    # Execute YOSYS command
    return sub(*(['yosys', '-p', 'tcl ' + tcl] + optional + verilog_files),
               env=env)

def yosys_conv(tcl, tcl_env, synth_json):
    # Set up environment for TCL weirdness
    env = os.environ.copy()
    env.update(tcl_env)

    # Execute YOSYS command
    return sub('yosys', '-p', 'read_json ' + synth_json + '; tcl ' + tcl,
               env=env)

""" def verify_flow(flow):
    if not flow['platform_name']:
        fatal(-1, 'Flow is missing platform name')
    if not (type(flow['platform_name']) is str):
        fatal(-1, '`platform_name` field in flow definitionis is not a string.')
        
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
        fatal(-1, '`synthesize.sources` field in flow definitionis is not a list. ') """


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
# verify_flow(flow)

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

top = flow['synthesize']['top']
build_dir = os.path.realpath(flow['build_dir'])
out_json = os.path.join(build_dir, top + '.json')
synth_json = os.path.join(build_dir, top + '_io.json')
sources = \
    list(map(lambda src: os.path.realpath(src), flow['synthesize']['sources']))


if not os.path.isdir(build_dir):
    os.makedirs(build_dir)

# -------------------------------------------------------------------------------

def stage_synth():
    yosys_tcl_env = \
        yosys_setup_tcl_env(build_dir=build_dir,
                            top=flow['synthesize']['top'],
                            bitstream_device=platform_flow['bitstream_device'],
                            part=platform_flow['part_name'],
                            techmap_path=platform_flow['synthesize']['techmap'],
                            out_json=out_json,
                            synth_json=synth_json,
                            xdc_files = flow['xdc'])
    
    print('Synthesis stage:')

    print(f'    [1/3] Sythesizing sources: {sources}')
    yosys_synth(platform_flow['synthesize']['synth_tcl'], yosys_tcl_env,
                verilog_files=sources, log=(top + '_synth.log'))
    print('    [2/3] Splitting in/outs...')
    sub('python3', split_inouts, '-i', out_json, '-o', synth_json)
    print('    [3/3] Converting...')
    yosys_conv(platform_flow['synthesize']['conv_tcl'], yosys_tcl_env,
               synth_json)

# -------------------------------------------------------------------------------

if args.synth:
    stage_synth()