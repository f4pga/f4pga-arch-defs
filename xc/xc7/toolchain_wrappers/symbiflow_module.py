import os
import sys
import json
from types import SimpleNamespace
from symbiflow_common import *

class Module:
    no_of_phases: int
    stage_name: str
    takes: 'list[str]'
    produces: 'list[str]'
    values: 'list[str]'
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

def _decompose_depname(name: str):
    required = True
    if name[len(name) - 1] == '?':
        required = False
        name = name[:len(name) - 1]
    return name, required

class ModuleContext:
    share: str
    takes: SimpleNamespace
    produces: SimpleNamespace
    outputs: SimpleNamespace
    values: SimpleNamespace
    r_env: ResolutionEnv
    module_name: str
    
    def is_output_explicit(self, name: str):
        o = getattr(self.produces, name)
        return o is not None

    def _getreqmaybe(self, obj, deps: 'list[str]', deps_cfg: 'dict[str, ]'):
        for name in deps:
            name, required = _decompose_depname(name)
            value = deps_cfg.get(name)
            if value is None and required:
                fatal(-1, f'Dependency `{name}` is required by module '
                          f'`{self.module_name}` but wasn\'t provided')
            setattr(obj, name, self.r_env.resolve(value))

    def __init__(self, module: Module, config: 'dict[str, ]',
                 r_env: ResolutionEnv, share: str):
        self.module_name = module.stage_name
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
        json_map = json.dumps(vars(mod_ctx.outputs))
        print(json_map)
        return
    
    
    print(f'Executing module `{module.stage_name}`:')
    current_phase = 1
    for phase_msg in module.execute(mod_ctx):
        print(f'    [{current_phase}/{module.no_of_phases}]: {phase_msg}')
        current_phase += 1
    print(f'Module `{module.stage_name}` has finished its work!')