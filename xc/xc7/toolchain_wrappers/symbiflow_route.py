#!/usr/bin/python3

# Symbiflow Stage Module

# ----------------------------------------------------------------------------- #

import os
import shutil
from symbiflow_common import *

# ----------------------------------------------------------------------------- #

def route_place_file(eblif: str):
    p = eblif
    m = re.match('(.*)\\.[^.]*$', eblif)
    if m:
        p = m.groups()[0]
    return p + '.route' 

class RouteModule(Module):
    def map_io(self, config: dict, r_env: ResolutionEnv):
        mapping = {}
        eblif = r_env.resolve(config['takes']['eblif'])
        mapping['route'] = route_place_file(eblif)
        mapping.update(r_env.resolve(config['produces']))
        return mapping
    
    def execute(self, share: str, config: dict, outputs: dict,
                r_env: ResolutionEnv):
        
        device = config['values']['device']
        eblif = os.path.realpath(config['takes']['eblif'])
        build_dir = os.path.dirname(eblif)

        vpr_options = []
        platform_pack_vpr_options = config['values'].get('vpr_options')
        if platform_pack_vpr_options:
            vpr_options = options_dict_to_list(platform_pack_vpr_options)
        
        vprargs = VprArgs(share, device, eblif, vpr_options=vpr_options)

        yield 'Routing with VPR...'
        vpr('route', vprargs, cwd=build_dir)

        if config['produces'].get('route'):
            shutil.move(route_place_file(eblif), outputs['route'])

        yield 'Saving log...'
        save_vpr_log('route.log', build_dir=build_dir)
        
    def __init__(self):
        self.stage_name = 'route'
        self.no_of_phases = 2

do_module(RouteModule())