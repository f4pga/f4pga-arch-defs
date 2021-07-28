import subprocess
import argparse
import os
import shutil
import sys
import re

# Returns decoded dependency name along with a bool telling whether the
# dependency is required.
# Examples: "required_dep" -> ("required_dep", True)
#           "maybe_dep?" -> ("maybe_dep", False)
def decompose_depname(name: str):
    required = True
    if name[len(name) - 1] == '?':
        required = False
        name = name[:len(name) - 1]
    return name, required

# Represents argument list for VPR (Versatile Place and Route)
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
        self.eblif = os.path.realpath(eblif)
        self.optional = vpr_options
        if sdc_file:
            self.optional += ['--sdc_file', sdc_file]

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

# Converts a dictionary of named options for CLI program to a list.
# Example: { "option_name": "value" } -> [ "--option_name", "value" ]
def options_dict_to_list(opt_dict: dict):
    opts = []
    for key, val in opt_dict.items():
        opts.append('--' + key)
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

# Save VPR logc (moves the default output file into a desired path)
def save_vpr_log(filename, build_dir=''):
    shutil.move(os.path.join(build_dir, 'vpr_stdout.log'), filename)

# Print a message informing about an error that has occured and terminate program
# with a given return code.
def fatal(code, message):
    print(f'[FATAL ERROR]: {message}')
    exit(code)

# TODO: Move this to symbiflow_module
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

# ResolutionEnv is used to hold onto mappings for variables used in flow and
# perform text substitutions using those variables.
# Variables can be referred in any "resolvable" string using the following
# syntax: 'Some static text ${variable_name}'. The '${variable_name}' part
# will be replaced by the value associated with name 'variable_name', is such
# mapping exists.
class ResolutionEnv:
    values: dict

    def __init__(self, values={}):
        self.values = values
    
    def __copy__(self):
        return ResolutionEnv(self.values.copy())

    # Perform resolution on `s`.
    # `s` can be a `str`, a `dict` with arbitrary keys and resolvable values,
    # or a `list` of resolvable values.
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

    # Add mappings from `values`
    def add_values(self, values: dict):
        for k, v in values.items():
            self.values[k] = self.resolve(v)
