import os
import sys
import json
from symbiflow_common import *

class Module:
    no_of_phases: int
    stage_name: str
    takes: 'list[str]'
    produces: 'list[str]'
    prod_meta: 'dict[str, str]'

    def execute(self, ctx):
        return None

    def map_io(self, config: dict, r_env: ResolutionEnv):
        return {}
    
    def __init__(self):
        self.no_of_phases = 0
        self.current_phase = 0
        self.stage_name = '<BASE STAGE>'
        self.prod_meta = {}

class ModuleContext:
    share: str
    takes: 'dict[str, ]'
    produces: 'dict[str, ]'
    outputs: 'dict[str, ]'
    values: 'dict[str, ]'
    r_env: ResolutionEnv
    module_name: str

    def take_require(self, name: str):
        take = self.takes.get(name)
        if take is None:
            fatal(-1, f'Required input `{name}` for module `{self.module_name}` '
                       'was not supplied.')
        return take
    
    def value_require(self, name: str):
        value = self.values.get(name)
        if value is None:
            fatal(-1, f'Required value `{name}` for module `{self.module_name}` '
                       'was not supplied.')
        return self.r_env.resolve(value)

    def take_maybe(self, name: str):
        return self.r_env.resolve(self.takes.get(name))
    
    def value_maybe(self, name: str):
        return self.r_env.resolve(self.values.get(name))
    
    # Un-usable in map_io mode!
    def output(self, name: str):
        return self.r_env.resolve(self.outputs.get(name))
    
    def is_output_explicit(self, name: str):
        o = self.produces.get(name)
        return o is not None

    def __init__(self, module: Module, config: 'dict[str, ]',
                 r_env: ResolutionEnv, share: str):
        self.module_name = module.stage_name
        self.takes = config['takes']
        self.produces = config['produces']
        self.values = config['values']
        self.r_env = r_env
        self.share = share
        self.outputs = module.map_io(self)

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
        fatal(-1, 'Symbiflow stage module requires "share" directory to be '
                  'specified using `-s` option.')
    
    share = os.path.realpath(args.share[0])

    config_json = sys.stdin.read()
    config = json.loads(config_json)

    r_env = ResolutionEnv({
        'shareDir': share
    })
    r_env.add_values(config['values'])

    mod_ctx = ModuleContext(module, config, r_env, share)

    if (args.map):
        json_map = json.dumps(mod_ctx.outputs)
        print(json_map)
        return
    
    
    print(f'Executing module `{module.stage_name}`:')
    current_phase = 1
    for phase_msg in module.execute(mod_ctx):
        print(f'    [{current_phase}/{module.no_of_phases}]: {phase_msg}')
        current_phase += 1
    print(f'Module `{module.stage_name}` has finished its work!')