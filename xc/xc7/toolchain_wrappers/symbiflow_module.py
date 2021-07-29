# Here are the things necessary to write a symbiflow Module

import os
import sys
import json
from types import SimpleNamespace
from symbiflow_common import *
from colorama import Fore, Style

# A `Module` is a wrapper for whatever tool is used in a flow.
# Modules can request dependencies, values and are guranteed to have all the
# required ones present when entering `exec` mode.
# They also have to specify what dependencies they produce and create the files
# for these dependencies.
class Module:
    no_of_phases: int
    name: str
    takes: 'list[str]'
    produces: 'list[str]'
    values: 'list[str]'
    prod_meta: 'dict[str, str]'

    # Executes module. Use yield to print a message informing about current
    # execution phase.
    # `ctx` is `ModuleContext`.
    def execute(self, ctx):
        return None

    # Returns paths for ouputs derived from given inputs.
    # `ctx` is `ModuleContext`.
    def map_io(self, ctx):
        return {}
    
    def __init__(self, params: 'dict[str, ] | None'):
        self.no_of_phases = 0
        self.current_phase = 0
        self.name = '<BASE STAGE>'
        self.prod_meta = {}

# A class for object holding mappings for dependencies and values as well as
# other information needed during modules execution.
class ModuleContext:
    share: str                 #   Absolute path to Symbiflow's share directory
    takes: SimpleNamespace     #   Maps symbolic dependency names to relative
                               # paths.
    produces: SimpleNamespace  #   Contains mappings for explicitely specified
                               # dependencies. Useful mostly for checking for
                               # on-demand optional outputs (such as logs)
                               # with `is_output_explicit` method.
    outputs: SimpleNamespace   #   Contains mappings for all available outputs.
    values: SimpleNamespace    #   Contains all available requested values. 
    r_env: ResolutionEnv       # `ResolutionEnvironmet` object holding mappings
                               # for current scope.
    module_name: str           # Name of the module.
    
    # True if user has explicitely specified output's path.
    def is_output_explicit(self, name: str):
        o = getattr(self.produces, name)
        return o is not None

    # Add attribute for a dependency or panic if a required dependency has not
    # been given to the module on its input.
    def _getreqmaybe(self, obj, deps: 'list[str]', deps_cfg: 'dict[str, ]'):
        for name in deps:
            name, required = decompose_depname(name)
            value = deps_cfg.get(name)
            if value is None and required:
                fatal(-1, f'Dependency `{name}` is required by module '
                          f'`{self.module_name}` but wasn\'t provided')
            setattr(obj, name, self.r_env.resolve(value))

    # `config` should be a dictionary given as modules input.
    def __init__(self, module: Module, config: 'dict[str, ]',
                 r_env: ResolutionEnv, share: str):
        self.module_name = module.name
        self.takes = SimpleNamespace()
        self.produces = SimpleNamespace()
        self.values = SimpleNamespace()
        self.outputs = SimpleNamespace()
        self.r_env = r_env
        self.share = share

        self._getreqmaybe(self.takes, module.takes, config['takes'])
        self._getreqmaybe(self.values, module.values, config['values'])

        produces_resolved = self.r_env.resolve(config['produces'])
        for name, value in produces_resolved.items():
            setattr(self.produces, name, value)

        outputs = module.map_io(self)
        outputs.update(produces_resolved)

        self._getreqmaybe(self.outputs, module.produces, outputs)

# get descriptions for produced dependencies.
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

def setup_module_arg_parser():
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

# Call it at the end of module's script. Wraps the module to be used
# through shell.
def do_module(module_ctor):
    parser = setup_module_arg_parser()
    args = parser.parse_args()
    config_json = sys.stdin.read()
    config = json.loads(config_json)

    module: Module = module_ctor(config.get('params'))

    if args.io:
        io = {
            'name': module.name,
            'takes': module.takes,
            'produces': module.produces,
            'meta': get_mod_metadata(module)
        }
        io_json = json.dumps(io)
        print(io_json)
        exit(0)

    if not args.share:
        fatal(-1, 'Symbiflow stage module requires "share" directory to be '
                  'specified using `-s` option.')
    
    share = os.path.realpath(args.share[0])


    r_env = ResolutionEnv({
        'shareDir': share
    })
    r_env.add_values(config['values'])

    mod_ctx = ModuleContext(module, config, r_env, share)

    if (args.map):
        json_map = json.dumps(vars(mod_ctx.outputs))
        print(json_map)
        return
    
    
    print( 'Executing module '
          f'`{Style.BRIGHT + module.name + Style.RESET_ALL}`:')
    current_phase = 1
    for phase_msg in module.execute(mod_ctx):
        print(f'    {Style.BRIGHT}[{current_phase}/{module.no_of_phases}]'
            f'{Style.RESET_ALL}: {phase_msg}')
        current_phase += 1
    print(f'Module `{Style.BRIGHT + module.name + Style.RESET_ALL}` '
           'has finished its work!')