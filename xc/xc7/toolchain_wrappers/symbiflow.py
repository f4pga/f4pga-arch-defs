#!/usr/bin/python3

import os
import json
import argparse
import shutil
import subprocess

mypath = os.path.realpath(os.sys.argv[0])
mypath = os.path.dirname(mypath)

share_dir_path = os.path.realpath(os.path.join(mypath, '../share/symbiflow'))
arch_dir_path = os.path.join(share_dir_path, 'arch')
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
                        help='Perform synthesis stage')
    parser.add_argument('-p', '--pack', action='store_true',
                        help='Perform packing stage')
    return parser

# Execute subroutine
def sub(*args, env=None):
    # print(args)
    out = subprocess.run(args, capture_output=True, env=env)
    if out.returncode != 0:
        print(f'[ERROR]: {args[0]} non-zero return code.\n'
              f'stderr:\n{out.stderr.decode()}\n\n'
              f'stdout:\n{out.stdout.decode()}\n')
        exit(out.returncode)
    return out.stdout

def noisy_warnings(device):
    return 'noisy_warnings-' + device + '_pack.log'

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

class VprArgs:
    arch_dir: str
    arch_def: str
    lookahead: str
    rr_graph: str
    rr_graph_xml: str
    place_delay: str
    device_name: str
    eblif: str
    optional: list

    def __init__(self, device, eblif, vpr_options=[], sdc_file=None):
        self.arch_dir = arch_dir_path
        self.arch_def = os.path.join(self.arch_dir, device, 'arch.timing.xml')
        self.lookahead = \
            os.path.join(self.arch_dir, device,
                         'rr_graph_' + device + '.lookahead.bin')
        self.rr_graph = \
            os.path.join(self.arch_dir, device,
                         'rr_graph_' + device + '.rr_graph.real.bin')
        self.rr_graph_xml = \
            os.path.join(self.arch_dir, device,
                         'rr_graph_' + device + '.rr_graph.real.xml')
        self.place_delay = \
            os.path.join(self.arch_dir, device,
                         'rr_graph_' + device + '.place_delay.bin')
        self.device_name = device.replace('_', '-')
        self.eblif = eblif
        self.optional = vpr_options
        if sdc_file:
            self.optional += ['--sdc_file', sdc_file]
    
    def env(self):
        return {
            'ARCH_DIR': self.arch_dir,
            'ARCH_DEF': self.arch_def,
            'LOOKAHEAD': self.lookahead,
            'RR_GRAPH': self.rr_graph,
            'RR_GRAPH_XML': self.rr_graph_xml,
            'PLACE_DELAY': self.place_delay,
            'DEVICE_NAME': self.device_name
        }

# Execute `vpr`
def vpr(mode: str, vprargs: VprArgs):
    modeargs = []
    if mode == "pack":
        modeargs = ['--pack']

    return sub(*(['vpr',
                  vprargs.arch_def,
                  vprargs.eblif,
                  '--device', vprargs.device_name,
                  '--read_rr_graph', vprargs.rr_graph,
                  '--read_router_lookahead', vprargs.lookahead,
                  '--read_placement_delay_lookup', vprargs.place_delay] +
                  modeargs + vprargs.optional))


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
device = platform_flow['device']

def subst_env(s: str):
    s = s.replace('${shareDir}', share_dir_path)
    s = s.replace('${noisyWarnings}', noisy_warnings(device))
    return s

def resolve_path(path: str):
    path = subst_env(path)
    path = path.replace('//', '/')
    path = path.replace('\\\\', '\\')
    path = os.path.realpath(path)
    return path

top = flow['synthesize']['top']
build_dir = resolve_path(flow['build_dir'])
out_json = os.path.join(build_dir, top + '.json')
synth_json = os.path.join(build_dir, top + '_io.json')
sources = \
    list(map(resolve_path, flow['synthesize']['sources']))
tcl_scripts = resolve_path(platform_flow['synthesize']['tcl_scripts'])
synth_tcl = os.path.join(tcl_scripts, 'synth.tcl')
conv_tcl = os.path.join(tcl_scripts, 'conv.tcl')
techmap_path = resolve_path(platform_flow['synthesize']['techmap'])
sdc = None
if flow.get('sdc'):
    sdc = resolve_path(flow['sdc'])
out_eblif = os.path.join(build_dir, top + '.eblif')
vpr_options = list(map(subst_env, platform_flow['pack']['vpr_options']))


if not os.path.isdir(build_dir):
    os.makedirs(build_dir)

# -------------------------------------------------------------------------------

def stage_synth():
    yosys_tcl_env = \
        yosys_setup_tcl_env(build_dir=build_dir,
                            top=flow['synthesize']['top'],
                            bitstream_device=platform_flow['bitstream_device'],
                            part=platform_flow['part_name'],
                            techmap_path=techmap_path,
                            out_json=out_json,
                            synth_json=synth_json,
                            out_eblif=out_eblif,
                            xdc_files=flow.get('xdc'))
    
    print('Synthesis stage:')

    print(f'    [1/3] Sythesizing sources: {sources}')
    yosys_synth(synth_tcl, yosys_tcl_env,
                verilog_files=sources, log=(top + '_synth.log'))
    print('    [2/3] Splitting in/outs...')
    sub('python3', split_inouts, '-i', out_json, '-o', synth_json)
    print('    [3/3] Converting...')
    yosys_conv(conv_tcl, yosys_tcl_env, synth_json)

def stage_pack():
    noisy_warnings(device)

    if not os.path.isfile(out_eblif):
        fatal(-1, f'The prerequisite file `{out_eblif}` does not  exist')

    vpr_args = VprArgs(device, out_eblif, sdc_file=sdc, vpr_options=vpr_options)

    print('Packing stage:')
    print('    [1/2]: Packing with VPR...')
    r = vpr('pack', vpr_args)
    # print(r.decode())
    print('    [2/2]: Moving log file...')
    shutil.move('vpr_stdout.log', 'pack.log')


# -------------------------------------------------------------------------------

if args.synth:
    stage_synth()

if args.pack:
    stage_pack()