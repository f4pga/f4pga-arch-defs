#!/usr/bin/python3

import sys
import os
import json
import argparse
import shutil
import subprocess
import re
from copy import copy
from sys import stdin
from subprocess import Popen, PIPE, CalledProcessError
from symbiflow_common import ResolutionEnv, noisy_warnings, fatal

mypath = os.path.realpath(os.sys.argv[0])
mypath = os.path.dirname(mypath)

share_dir_path = os.path.realpath(os.path.join(mypath, '../share/symbiflow'))

def setup_argparser():
    parser = argparse.ArgumentParser(description="Execute SymbiFlow flow")
    parser.add_argument('flow', nargs=1, metavar='<flow path>', type=str,
                        help='Path to flow definition file')
    parser.add_argument('-s', '--stage', metavar='<stage name>', type=str,
                        help='Perform specified synthesis stage')
    parser.add_argument('-a', '--autoflow', action='store_true',
                        help='Execute as many following stages as possible')
    parser.add_argument('-p', '--platform', nargs=1, metavar='<platform name>',
                        help='Target platform name')
    # Currently unsupported
    parser.add_argument('-t', '--take_explicit_paths', nargs='+',
                        metavar='<name=path, ...>', type=str,
                        help='Specify stage inputs explicitely. This might be '
                             'required if some files got renamed or deleted and '
                             'symbiflow is unable to deduce the flow that lead to '
                             'dependencies required by the requested stage')
    return parser

def options_dict_to_list(opt_dict: dict):
    opts = []
    for key, val in opt_dict.items():
        opts.append(key)
        if not(type(val) is list and val == []):
            opts.append(str(val))
    return opts

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

    def __init__(self, name, stage_def, r_env: ResolutionEnv):
        if (not stage_def.get('takes')) or (not stage_def.get('produces')) or \
                (not stage_def.get('module')):
            raise Exception('Incorrect stage structure')
        
        values = stage_def.get('values')
        if values:
            r_env = copy(r_env)
            platform_parse_values(values, r_env)
        
        self.takes = []
        for input in stage_def['takes']:
            io = StageIO(input)
            if io.qualifier == 'invalid':
                raise Exception(f'Invalid input token `{input}`')
            self.takes.append(io)
        
        self.produces = []
        for input in stage_def['produces']:
            io = StageIO(input)
            if io.qualifier == 'invalid':
                raise Exception(f'Invalid input token {input}')
            self.produces.append(io)
        
        self.args = stage_def['args'].copy()
        values = stage_def.get('values')
        if values:
            self.values = r_env.resolve(values)
        else:
            self.values = []
        self.module = stage_def['module']
        self.name = name

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

def platform_stages(platform_flow, r_env):
    for stage_name, stage_def in platform_flow['stages'].items():
        # print(stage_def)
        yield Stage(stage_name, stage_def, r_env)

def find_stage_by_name(name, stages: 'list[Stage]'):
    m = [stage for stage in stages if stage.name == name]
    if len(m) > 1:
        fatal(f'Stage `{name}` is defined multiple times.')
    if len(m) == 0:
        return None
    return m[0]

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

def starting_stages(stages, p_flow, r_env):
    for stage in stages:
        if not stage.name in p_flow['stages'].keys():
            print(f'Stage `{stage.name}` rejected because it\'s not found')
            continue
        takes = p_flow['stages'][stage.name].get('takes')
        if not takes:
            print(f'Stage `{stage.name}` rejected because of no `takes`')
            continue
        valid = True
        for take in stage.takes:
            if take.qualifier == 'maybe':
                continue
            if take.qualifier == 'req':
                if take.name not in takes:
                    print(f'Stage `{stage.name}` rejected because `{take.name}` is not in `takes`')
                    valid = False
                    break
                paths = r_env.resolve(takes[take.name])
                if not req_exists(paths):
                    print(f'Stage `{stage.name}` rejected because `{take.name}: {paths}` does not exist')
                    valid = False
                    break

        if not valid:
            break
        yield stage

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

def resolve_dependency(name: str, os_map: 'dict[str, Stage]',
                       stage_cfg: 'dict | None', r_env: ResolutionEnv):
    provider_stage = os_map.get(name)
    take_dep_paths = ''
    missing_req = True
    if stage_cfg:
        takes_cfg = stage_cfg.get('takes')
        if takes_cfg:
            take_dep = takes_cfg.get(name)
            if take_dep:
                take_dep_paths = r_env.resolve(take_dep)
                missing_req = not req_exists(take_dep_paths)
                print(f'    Dependency \'{name}\' -> {take_dep_paths}: '
                      f'{"MISSING" if missing_req else "FOUND"}')
    if missing_req and not provider_stage:
        return None
    if not missing_req and take_dep_paths:
        return take_dep_paths
    return provider_stage

class StageDepNode:
    stage: Stage
    depends_on: 'list[StageDepNode]'
    wants: 'list[StageDepNode]'

    def __init__(self, stage: Stage):
        self.stage = stage
        self.depends_on = []
        self.wants = []
    
    def __repr__(self) -> str:
        return 'StageDepNode { stage: `' + self.stage.name + \
               '`, depends_on: ' + str(self.depends_on) + ', wants: ' + \
               str(self.wants) + ' }'

def resolve_dependencies(stage: Stage, os_map: 'dict[str, Stage]', p_flow: dict,
                         r_env: ResolutionEnv,
                         dep_tree: 'dict[str, StageDepNode]'):
    # TODO: Drop support for `not` qualifier
    print(f'Resolving stage {stage.name}')
    dependency_stages: 'dict[Stage, str]' = {}
    for input in stage.takes:
        stage_cfg = p_flow['stages'].get(stage.name)
        provider = resolve_dependency(input.name, os_map, stage_cfg, r_env)
        print(f'        \'{input.name}\' -> '
              f'{"stage " + provider.name if type(provider) is Stage else provider}')
        if input.qualifier == 'req' and not provider:
            raise Exception(f'Dependency {input.name} cannot be resolved')
        if type(provider) is Stage:
            if dependency_stages.get(provider):
                if dependency_stages[provider] == 'req':
                    continue # Prevent changing 'req' to 'maybe'
            dependency_stages[provider] = input.qualifier
    my_node = StageDepNode(stage)
    for p_stage, p_qualifier in dependency_stages.items():
        if p_stage.name == stage.name:
            raise Exception(f'Stage `{stage.name}` cannot depend on itself!')
        dep = dep_tree.get(p_stage.name)
        if not dep:
            dep = resolve_dependencies(p_stage, os_map, p_flow, r_env, dep_tree)
        if p_qualifier == 'req':
            my_node.depends_on.append(dep)
        elif p_qualifier == 'maybe':
            my_node.wants.append(dep)
    dep_tree[stage.name] = my_node
    return my_node
                

parser = setup_argparser()
args = parser.parse_args()

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
# verify_flow(flow)

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
device = platform_flow['device']
p_flow = flow[platform_name]

r_env = ResolutionEnv({
    "shareDir": share_dir_path,
    "noisyWarnings": noisy_warnings(device)
})

p_flow_values = p_flow.get('values')
if p_flow_values:
    r_env.add_values(p_flow_values)

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
    if mod_res.returncode != 0:
        print(f'Module `{path}` failed with code {mod_res.returncode}')
        exit(mod_res.returncode)
    if out:
        return json.loads(out.decode())
    else:
        return None

stages = list(platform_stages(platform_flow, r_env))

if len(stages) == 0:
    fatal('Platform flow does not define any stage')

stage = None
if args.stage:
    stage = find_stage_by_name(args.stage, stages)
    if not stage:
        fatal(-1, f'Stage {args.stage} is undefined')
else:
    stage = stages[0]

os_map = map_outputs_to_stages(stages)
dep_tree = resolve_dependencies(stage, os_map, p_flow, r_env, {})
print(f'Stage dependency tree: {dep_tree}')

stage_cfg = p_flow['stages'][stage.name]

# TODO: Implement filename deduction algorithm
takes = stage_cfg['takes']

module = os.path.realpath(os.path.join(mypath, r_env.resolve(stage.module)))

platform_values =  platform_flow.get('values')
if not platform_values:
    platform_values = {}
produces_explicit = stage_cfg.get('produces')
if not produces_explicit:
    produces_explicit = {}
mod_args = stage_cfg.get('args')
if not mod_args:
    mod_args = {}
mod_config = {
    'takes': stage_cfg['takes'],
    'produces': produces_explicit,
    'values': platform_values,
    'args': mod_args,
    'platform': platform_name
}
mod_config['values'].update(stage.values)
if p_flow.get('values'):
    mod_config['values'].update(p_flow['values'])
if stage_cfg.get('values'):
    mod_config['values'].update(stage_cfg['values'])

outputs = run_module(module, 'map', mod_config)

mod_config['produces'].update(outputs)

# run_module(module, 'exec', mod_config)

print('Symbiflow: DONE')