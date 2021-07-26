#!/usr/bin/python3

import subprocess
import sys
import os
import json
import argparse
import re
from copy import copy
from subprocess import Popen, PIPE
from typing import Iterable
from colorama import Fore, Style
from symbiflow_common import ResolutionEnv, noisy_warnings, fatal
from symbiflow_module import *
from symbiflow_cache import SymbiCache

SYMBICACHEPATH = '.symbicache'

mypath = os.path.realpath(os.sys.argv[0])
mypath = os.path.dirname(mypath)

share_dir_path = os.path.realpath(os.path.join(mypath, '../share/symbiflow'))

def setup_argparser():
    parser = argparse.ArgumentParser(description="Execute SymbiFlow flow")
    parser.add_argument('flow', nargs=1, metavar='<flow path>', type=str,
                        help='Path to flow definition file')
    parser.add_argument('-t', '--target', metavar='<target name>', type=str,
                        help='Perform stages necessary to acquire target')
    parser.add_argument('-p', '--platform', nargs=1, metavar='<platform name>',
                        help='Target platform name')
    parser.add_argument('-P', '--pretend', action='store_true',
                        help='Show dependency resolution without executing flow')
    parser.add_argument('-i', '--info', action='store_true',
                        help='Display info about available targets')
    # Currently unsupported
    parser.add_argument('-T', '--take_explicit_paths', nargs='+',
                        metavar='<name=path, ...>', type=str,
                        help='Specify stage inputs explicitely. This might be '
                             'required if some files got renamed or deleted and '
                             'symbiflow is unable to deduce the flow that lead to '
                             'dependencies required by the requested stage')
    return parser

def run_module(path, mode, config):
    mod_res = None
    out = None
    config_json = json.dumps(config)
    if mode == 'map':
        cmd = ['python3', path, '--map', '--share', share_dir_path]
        with Popen(cmd, stdin=PIPE, stdout=PIPE) as p:
            out = p.communicate(input=config_json.encode())[0]
        mod_res = p
    elif mode == 'exec':
        # XXX: THIS IS SOOOO UGLY
        cmd = ['python3', path, '--share', share_dir_path]
        with Popen(cmd, stdout=sys.stdout, stdin=PIPE, bufsize=1) as p:
            p.stdin.write(config_json.encode())
            p.stdin.flush()
        mod_res = p
    elif mode == 'io':
        p = subprocess.run(['python3', path, '--io'], stdout=PIPE)
        mod_res = p
        out = p.stdout
    if mod_res.returncode != 0:
        print(f'Module `{path}` failed with code {mod_res.returncode}')
        exit(mod_res.returncode)
    if out:
        return json.loads(out.decode())
    else:
        return None

class StageIO:
    name: str
    qualifier: str
    auto_flow: bool

    def __init__(self, encoded_name: str):
        m = re.match('(->)?(!)?(\w+)(\?)?(->)?', encoded_name)
        span = m.span()
        if span[1] - span[0] != len(encoded_name):
            self.qualifier = 'invalid'
            return
        m_in, m_not, m_name, m_maybe, m_out = m.groups()
        if (not m_name) or (m_not and m_maybe) or (m_in and m_out) \
                or (m_out and m_not):
            self.qualifier = 'invalid'
            return
        self.name = m_name
        if m_not:
            self.qualifier = 'not'
        elif m_maybe:
            self.qualifier = 'maybe'
        else:
            self.qualifier = 'req'
        if m_in or m_out:
            self.auto_flow = True
        else:
            self.auto_flow = False
    
    def __repr__(self) -> str:
        return 'StageIO { name: \'' + self.name + '\', qualifier: ' + \
               self.qualifier + ', auto_flow: ' + str(self.auto_flow) + ' }'
class Stage:
    name: str
    takes: 'list[StageIO]'
    produces: 'list[StageIO]'
    args: 'list[str]'
    values: 'dict[str, ]'
    module: str
    meta: 'dict[str, str]'

    def __init__(self, mod_path, mod_opts, r_env: ResolutionEnv, bin='./'):
        self.module = os.path.join(bin, mod_path)
        
        if not os.path.isfile(self.module) and not os.path.islink(self.module):
            raise Exception(f'Module file {self.module} does not exist')
        
        mod_io = run_module(self.module, 'io', None)
        self.name = mod_io['name']

        if not mod_opts:
            mod_opts = {}
        
        values = mod_opts.get('values')
        if values:
            r_env = copy(r_env)
            platform_parse_values(values, r_env)
        
        self.takes = []
        for input in mod_io['takes']:
            io = StageIO(input)
            if io.qualifier == 'invalid':
                raise Exception(f'Invalid input token `{input}`')
            self.takes.append(io)
        
        self.produces = []
        for input in mod_io['produces']:
            io = StageIO(input)
            if io.qualifier == 'invalid':
                raise Exception(f'Invalid input token {input}')
            self.produces.append(io)
        
        self.meta = mod_io['meta']
        
        self.args = mod_opts['args'].copy() if mod_opts.get('args') else {}
        values = mod_opts.get('values')
        if values:
            self.values = r_env.resolve(values)
        else:
            self.values = {}

    def __repr__(self) -> str:
        return 'Stage \'' + self.name + '\' {' \
               f' values: {self.values},' \
               f' args: {self.args},' \
               f' takes: {self.takes},' \
               f' produces: {self.produces} ' + '}'

def platform_parse_values(values: dict, r_env: ResolutionEnv):
    for k, v in values.items():
        vr = r_env.resolve(v)
        r_env.values[k] = vr

def platform_stages(platform_flow, r_env, bin='./'):
    module_options = platform_flow.get('module_options')
    for module_path in platform_flow['modules']:
        mod_opts = module_options.get(module_path) if module_options else None
        yield Stage(module_path, mod_opts, r_env, bin=bin)
        

def req_exists(r):
    if type(r) is str:
        if not os.path.isfile(r) and not os.path.islink(r):
            return False
    elif type(r) is list:
        return not (False in map(req_exists, r))
    else:
        raise Exception('Requirements can be currently checked only for single '
                        'paths, or path lists')
    return True

def map_outputs_to_stages(stages: 'list[Stage]'):
    os_map: 'dict[str, Stage]' = {} # Output-Stage map
    for stage in stages:
        for output in stage.produces:
            if not os_map.get(output.name):
                os_map[output.name] = stage
            elif os_map[output.name] != stage:
                raise Exception(f'Dependency `{output.name}` is generated by '
                                f'stage `{os_map[output.name].name}` and '
                                f'`{stage.name}`. Dependencies can have only one '
                                 'provider at most.')
    return os_map

def get_explicit_deps(flow: dict, platform_name: str, r_env: ResolutionEnv):
    deps = {}
    if flow.get('dependencies'):
        deps.update(r_env.resolve(flow['dependencies']))
    if flow[platform_name].get('dependencies'):
        deps.update(r_env.resolve(flow[platform_name]['dependencies']))
    return deps

def filter_existing_deps(deps: 'dict[str, ]', symbicache):
    return [(n, p) for n, p in deps.items() \
            if req_exists(p)] # and not dep_differ(p, symbicache)]

def print_dependency_availability(stages: 'Iterable[Stage]',
                                  dep_paths: 'dict[str, str]',
                                  os_map: 'dict[str, Stage]',
                                  symbicache: SymbiCache,
                                  rerun_stages: 'set[str]'):
    dependencies: 'set[str]' = set()
    for stage in stages:
        for take in stage.takes:
            dependencies.add(take.name)
        for prod in stage.produces:
            dependencies.add(prod.name)
    
    dependencies = list(dependencies)
    dependencies.sort()

    for dep_name in dependencies:
        status = Fore.RED + '[X]' + Fore.RESET
        source = Fore.YELLOW + 'MISSING' + Fore.RESET
        paths = dep_paths.get(dep_name)
        if paths:
            exists = req_exists(paths)
            provider = os_map.get(dep_name)
            rerun = provider.name in rerun_stages if provider else False
            #print(f'{dep_name} : {paths}')
            if exists and not rerun:
                if dep_differ(paths, symbicache):
                    status = Fore.GREEN + '[N]' + Fore.RESET
                else:
                    status = Fore.GREEN + '[O]' + Fore.RESET
                source = paths
            elif provider:
                if rerun:
                    status = Fore.YELLOW + '[R]' + Fore.RESET
                else:
                    status = Fore.YELLOW + '[S]' + Fore.RESET
                source = f'{Fore.BLUE + os_map[dep_name].name + Fore.RESET} ' \
                         f'-> {paths}'
        elif os_map.get(dep_name):
            status = Fore.RED + '[U]' + Fore.RESET
            source = f'{Fore.BLUE + os_map[dep_name].name + Fore.RESET} -> ???'
        
        print(f'    {Style.BRIGHT + status} {dep_name + Style.RESET_ALL}: {source}')

def get_flow_values(platform_flow: dict, flow: dict, platform_name):
    values = {}

    platform_flow_values = platform_flow.get('values')
    if platform_flow_values:
        values.update(platform_flow_values)
    
    project_flow_values = flow.get('values')
    if project_flow_values:
        values.update(project_flow_values)
    
    project_flow_platform_values = flow[platform_name].get('values')
    if project_flow_platform_values:
        values.update(project_flow_platform_values)

    return values

def get_stage_values_override(og_values: dict, stage: Stage):
    values = og_values.copy()
    values.update(stage.values)
    return values

def get_stage_cfg_args(stage: Stage, p_flow: dict):
    stages_cfg = p_flow.get('stages')
    if not stages:
        return
    stage_cfg = stages_cfg.get(stage.name)
    if not stage_cfg:
        return {}
    arg_cfg = stage_cfg.get('args')
    if arg_cfg:
        return arg_cfg
    else:
        return {}
    
def prepare_stage_input(stage: Stage, platform_name: str, values: dict, args,
                        dep_paths: 'dict[str, ]', config_paths: 'dict[str, ]'):
    takes = {}
    for take in stage.takes:
        paths = dep_paths.get(take.name)
        if paths: # Some takes may have 'maybe' qualifier and thus are not required
            takes[take.name] = paths
    
    produces = {}
    for prod in stage.produces:
        if dep_paths.get(prod.name):
            produces[prod.name] = dep_paths[prod.name]
        elif config_paths.get(prod.name):
            produces[prod.name] = config_paths[prod.name]
    
    stage_mod_cfg = {
        'takes': takes,
        'produces': produces,
        'args': args,
        'values': values,
        'platform': platform_name
    }
    return stage_mod_cfg

def dep_differ(paths, symbicache: SymbiCache):
    if type(paths) is str:
        s = symbicache.get_status(paths)
        if s == 'untracked':
            symbicache.update(paths)
        return symbicache.get_status(paths) != 'same'
    elif type(paths) is list:
        for p in paths:
            s = symbicache.get_status(p)
            if s != 'same':
                return True
    elif type(paths) is dict:
        for _, p in paths:
            s = symbicache.get_status(p)
            if s != 'same':
                return True
    return False

def dep_will_differ(target: str, paths, os_map: 'dict[str, Stage]',
                    rerun_stages: 'set[str]', symbicache: SymbiCache):
    provider = os_map.get(target)
    # print(f'depdif {target}: {paths}, prov: {provider.name if provider else None}')
    if provider:
        return (provider.name in rerun_stages) or dep_differ(paths, symbicache)
    return dep_differ(paths, symbicache)

def resolve_dependencies(target: str, os_map: 'dict[str, Stage]',
                         platform_name: str, values: 'dict[str, ]',
                         p_flow: dict, r_env: ResolutionEnv,
                         dep_paths: 'dict[str, ]', config_paths: 'dict[str, ]',
                         stages_checked: 'set[str]', rerun_stages: 'set[str]',
                         symbicache: SymbiCache):
    # TODO: Drop support for `not` qualifier
    # print(f'Resolving dependency {target}')
    # Check if dependency is already resolved
    paths = dep_paths.get(target)
    if paths and not os_map.get(target):
        # print(f'{target} not in os_map')
        return
    # Check if a stage can provide the required dependency
    provider = os_map.get(target)
    # print(f'PROV: {provider.name if provider else None}')
    if provider and provider.name not in stages_checked:
        for take in provider.takes:
            # print(f'take {take.name}')
            resolve_dependencies(take.name, os_map, platform_name, values,
                                 p_flow, r_env, dep_paths, config_paths,
                                 stages_checked, rerun_stages, symbicache)
            # If any of the required dependencies is unavailable, then the provider
            # stage cannot be run
            take_paths = dep_paths.get(take.name)
            if not take_paths and take.qualifier == 'req':
                print(f'    Stage `{provider.name}` is unreachable due to unmet '
                    f'dependency {take.name}')
                return
            
            if dep_will_differ(take.name, take_paths, os_map, rerun_stages,
                               symbicache):
                rerun_stages.add(provider.name)
        
        stages_checked.add(provider.name)
        # Prepare input for map mode
        stage_values = get_stage_values_override(values, provider)
        stage_args = get_stage_cfg_args(provider, p_flow)
        mod_input = prepare_stage_input(provider, platform_name, stage_values,
                                        stage_args, dep_paths, config_paths)
        # Query module for its outputs
        outputs = run_module(provider.module, 'map', mod_input)
        dep_paths.update(outputs)
                
def execute_flow(target: str, values: 'dict[str, ]',
                 os_map: 'dict[str, Stage]', 
                 dep_paths: 'dict[str, bool]',
                 rerun_stages: 'set[str]'):
    paths = dep_paths.get(target)
    provider = os_map.get(target)
    rerun = (provider.name in rerun_stages) if provider else False
    if paths:
        if req_exists(paths) and not rerun:
            return True
        else:
            
            if not provider:
                fatal(-1, 'Something went wrong')
            
            for p_dep in provider.takes:
                execute_flow(p_dep.name, values, os_map, dep_paths, rerun_stages)
                p_dep_paths = dep_paths.get(p_dep.name)
                if p_dep.qualifier == 'req' and not req_exists(p_dep_paths):
                    fatal(-1, f'Can\'t produce promised dependency '
                              f'`{p_dep.name}`. Something went wrong.')

            # Prepare inputs
            stage_values = get_stage_values_override(values, provider)
            stage_args = get_stage_cfg_args(provider, p_flow)
            mod_input = prepare_stage_input(provider, platform_name,
                                            stage_values, stage_args, dep_paths,
                                            {})
            # Run module
            run_module(provider.module, 'exec', mod_input)

            rerun_stages.discard(provider.name)

            return req_exists(paths)

def update_dep_statuses(paths, symbicache: SymbiCache):
    if type(paths) is str:
        symbicache.update(paths)
    elif type(paths) is list:
        for p in paths:
            update_dep_statuses(p, symbicache)
    elif type(paths) is dict:
        for _, p in paths.items():
            update_dep_statuses(p, symbicache)

def display_dep_info(stages: 'Iterable[Stage]'):
    print('Platform dependencies/targets:')
    longest_out_name_len = 0
    for stage in stages:
        for out in stage.produces:
            l = len(out.name)
            if l > longest_out_name_len:
                longest_out_name_len = l
    
    desc_indent = longest_out_name_len + 7
    nl_indentstr = '\n'
    for _ in range(0, desc_indent):
        nl_indentstr += ' '

    for stage in stages:
        for out in stage.produces:
            pname = Style.BRIGHT + out.name + Style.RESET_ALL
            indent = ''
            for _ in range(0, desc_indent - len(pname) + 3):
                indent += ' '
            pgen = f'{Style.DIM}module: `{stage.name}`{Style.RESET_ALL}'
            pdesc = stage.meta[out.name].replace('\n', nl_indentstr)
            print(f'    {Style.BRIGHT + out.name + Style.RESET_ALL}:'
                  f'{indent}{pdesc}{nl_indentstr}{pgen}')

parser = setup_argparser()
args = parser.parse_args()

print('Symbiflow Build System')

if not args.platform:
    fatal(-1, 'You have to specify a platform name with `-p` option')

platform_name = args.platform[0]

flow_path = args.flow[0]

flow_def = None
try:
    with open(flow_path, 'r') as flow_def_file:
        flow_def = flow_def_file.read()
except FileNotFoundError as _:
    fatal(-1, 'The provided flow definition file does not exist')

flow = json.loads(flow_def)

platform_path = platform_name + '.json'
platform_def = None
try:
    with open(platform_path) as platform_file:
        platform_def = platform_file.read()
except FileNotFoundError as _:
    fatal(-1, f'The platform flow definition file {platform_path} for the platform '
          f'{flow["platform_name"]} referenced in flow definition file {flow_path} '
          'cannot be found.')

platform_flow = json.loads(platform_def)
device = platform_flow['values']['device']
p_flow = flow[platform_name]

r_env = ResolutionEnv({
    "shareDir": share_dir_path,
    "noisyWarnings": noisy_warnings(device)
})

p_flow_values = p_flow.get('values')
if p_flow_values:
    r_env.add_values(p_flow_values)

print('Scanning modules...')
stages = list(platform_stages(platform_flow, r_env, bin=mypath))

if len(stages) == 0:
    fatal(-1, 'Platform flow does not define any stage')

if args.info:
    display_dep_info(stages)
    exit(0)

if not args.target:
    fatal(-1, 'Please specify desired target using `--target` option')

os_map = map_outputs_to_stages(stages)
stage = os_map.get(args.target)

symbicache = SymbiCache(SYMBICACHEPATH)

config_paths: 'dict[str, ]' = get_explicit_deps(flow, platform_name, r_env)
update_dep_statuses(config_paths, symbicache)

dep_paths = dict(filter_existing_deps(config_paths, symbicache))
values = get_flow_values(platform_flow, flow, platform_name)
rerun_stages = set()

# print(f'Cache status: {symbicache.status}')
# print(f'dep_paths: {dep_paths}')
resolve_dependencies(args.target, os_map, platform_name, values, p_flow, r_env,
                     dep_paths, config_paths, set(), rerun_stages, symbicache)

print('\nProject status:')
print_dependency_availability(stages, dep_paths, os_map, symbicache,
                              rerun_stages)
print('')

# print(f'Stages to rerun: {rerun_stages}')

if args.pretend:
    exit(0)

r = execute_flow(args.target, values, os_map, dep_paths, rerun_stages)

update_dep_statuses(dep_paths, symbicache)
symbicache.save()

if dep_paths.get(args.target):
    print(f'Target `{Style.BRIGHT + args.target + Style.RESET_ALL}` -> '
          f'{dep_paths[args.target]}')

print(f'Symbiflow: {Style.BRIGHT + Fore.GREEN}DONE'
      f'{Style.RESET_ALL + Fore.RESET}')
