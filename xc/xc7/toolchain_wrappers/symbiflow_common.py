import subprocess
import argparse
import os
import shutil
import sys
import json
import re

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

    def __init__(self, share, device, eblif, vpr_options=[], sdc_file=None):
        self.arch_dir = os.path.join(share, 'arch')
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


def setup_vpr_arg_parser():
    parser = argparse.ArgumentParser(description="Parse flags")
    parser.add_argument('-d', '--device', nargs=1, metavar='<device>',
                        type=str, help='Device type (e.g. artix7)')
    parser.add_argument('-e', '--eblif', nargs=1, metavar='<eblif file>',
                        type=str, help='EBLIF filename')
    parser.add_argument('-p', '--pcf', nargs=1, metavar='<pcf file>',
                        type=str, help='PCF filename')
    parser.add_argument('-P', '--part', nargs=1, metavar='<name>',
                        type=str, help='Part name')
    parser.add_argument('-s', '--sdc', nargs=1, metavar='<sdc file>',
                        type=str, help='SDC file')
    parser.add_argument('-a', '--additional_vpr_options', metavar='<opts>',
                        type=str, help='Additional VPR options')
    parser.add_argument('additional_vpr_args', nargs='*', metavar='<args>',
                        type=str, help='Additional arguments for vpr command')
    return parser

# Execute subroutine
def sub(*args, env=None, cwd=None):
    # print(args)
    out = subprocess.run(args, capture_output=True, env=env, cwd=cwd)
    if out.returncode != 0:
        print(f'[ERROR]: {args[0]} non-zero return code.\n'
              f'stderr:\n{out.stderr.decode()}\n\n'
              )
        exit(out.returncode)
    return out.stdout

# Execute `vpr`
def vpr(mode: str, vprargs: VprArgs, cwd=None):
    modeargs = []
    if mode == 'pack':
        modeargs = ['--pack']
    elif mode == 'place':
        modeargs = ['--place']
    elif mode == 'route':
        modeargs = ['--route']

    return sub(*(['vpr',
                  vprargs.arch_def,
                  vprargs.eblif,
                  '--device', vprargs.device_name,
                  '--read_rr_graph', vprargs.rr_graph,
                  '--read_router_lookahead', vprargs.lookahead,
                  '--read_placement_delay_lookup', vprargs.place_delay] +
                  modeargs + vprargs.optional),
               cwd=cwd)

def options_dict_to_list(opt_dict: dict):
    opts = []
    for key, val in opt_dict.items():
        opts.append(key)
        if not(type(val) is list and val == []):
            opts.append(str(val))
    return opts

# Emit some noisy warnings
def noisy_warnings(device):
    os.environ['OUR_NOISY_WARNINGS'] = 'noisy_warnings-' + device + '_pack.log'

# Get current PWD
def my_path():
    mypath = os.path.realpath(sys.argv[0])
    return os.path.dirname(mypath)

# Save VPR log
def save_vpr_log(filename, build_dir=''):
    shutil.move(os.path.join(build_dir, 'vpr_stdout.log'), filename)

def fatal(code, message):
    print(f'[FATAL ERROR]: {message}')
    exit(code)

def setup_stage_arg_parser():
    parser = argparse.ArgumentParser(description="Parse flags")
    parser.add_argument('-s', '--share', nargs=1, metavar='<share>',
                        type=str, help='Symbiflow\'s "share" directory path')
    parser.add_argument('-m', '--map', action='store_true',
                        help='Perform `output name` <-> `file path` mapping '
                             'instead of executing the stage.')
    parser.add_argument('-i', '--io', action='store_true',
                        help='Return a JSON containing module input/output '
                             'declarations and metadata')
    return parser

class ResolutionEnv:
    values: dict

    def __init__(self, values={}):
        self.values = values
    
    def __copy__(self):
        return ResolutionEnv(self.values.copy())

    def resolve(self, s):
        if type(s) is str:
            match_list = list(re.finditer('\$\{([^${}]*)\}', s))
            # Assupmtion: re.finditer finds matches in a left-to-right order
            match_list.reverse()
            for match in match_list:
                v = self.values.get(match.group(1))
                if not v:
                    continue
                span = match.span()
                s = s[:span[0]] + v + s[span[1]:]
        elif type(s) is list:
            s = list(map(self.resolve, s))
        elif type(s) is dict:
            s = dict([(k, self.resolve(v)) for k, v in s.items()])
        return s


    def add_values(self, values: dict):
        for k, v in values.items():
            self.values[k] = self.resolve(v)

class Module:
    no_of_phases: int
    stage_name: str
    takes: 'list[str]'
    produces: 'list[str]'
    prod_meta: 'dict[str, str]'

    def execute(self, share: str, config: dict, outputs: dict,
                r_env: ResolutionEnv):
        return None

    def map_io(self, config: dict, r_env: ResolutionEnv):
        return {}
    
    def __init__(self):
        self.no_of_phases = 0
        self.current_phase = 0
        self.stage_name = '<BASE STAGE>'
        self.prod_meta = {}

def get_mod_metadata(module: Module):
    meta = {}
    has_meta = hasattr(module, 'prod_meta')
    for prod in module.produces:
        prod = prod.replace('?', '')
        if not has_meta:
            meta[prod] = '<no descritption>'
            continue
        prod_meta = module.prod_meta.get(prod)
        meta[prod] = prod_meta if prod_meta else '<no description>'
    return meta

def do_module(module: Module):
    parser = setup_stage_arg_parser()
    args = parser.parse_args()

    if args.io:
        io = {
            'name': module.stage_name,
            'takes': module.takes,
            'produces': module.produces,
            'meta': get_mod_metadata(module)
        }
        io_json = json.dumps(io)
        print(io_json)
        exit(0)

    if not args.share:
        fatal(-1, 'Symbiflow stage module requires "share" directory to be specified '
            'using `-s` option.')
    
    share = os.path.realpath(args.share[0])

    config_json = sys.stdin.read()
    config = json.loads(config_json)

    r_env = ResolutionEnv({
        'shareDir': share
    })
    r_env.add_values(config['values'])

    io_map = module.map_io(config, r_env)

    if (args.map):
        json_map = json.dumps(io_map)
        print(json_map)
        return
    
    print(f'Executing module `{module.stage_name}`:')
    current_phase = 1
    for phase_msg in module.execute(share, config, io_map, r_env):
        print(f'    [{current_phase}/{module.no_of_phases}]: {phase_msg}')
        current_phase += 1
    print(f'Module `{module.stage_name}` has finished its work!')
