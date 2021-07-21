#!/usr/bin/python3

# Symbiflow Stage Module

# ----------------------------------------------------------------------------- #

import os
from symbiflow_common import *

# ----------------------------------------------------------------------------- #

def place_constraints_file(config: dict, r_env: ResolutionEnv):
    dummy =- False
    p = config['takes'].get('place_constraints')
    if not p:
        p = config['takes'].get('io_place')
    if not p:
        dummy = True
        p = config['takes']['eblif']
    p = r_env.resolve(p)
    m = re.match('(.*)\\.[^.]*$', p)
    if m:
        p = m.groups()[0]
    
    return r_env.resolve(m + '.vpr.place'), dummy

class PlaceModule(Module):
    def map_io(self, config: dict, r_env: ResolutionEnv):
        mapping = {}
        p, _ = place_constraints_file(config, r_env)
        m = re.match('(.*)\\.[^.]*$', p)
        if m:
            p = m.groups()[0]
        
        mapping['place'] = m + '.vpr.place'
        mapping.update(r_env.resolve(config['produces']))
        return mapping
    
    def execute(self, share: str, config: dict, outputs: dict,
                r_env: ResolutionEnv):
        place_constraints, dummy = place_constraints_file(config, r_env)
        if dummy:
            with open(place_constraints, 'wb') as f:
                f.write(b'')
        
        device = config['values']['device']
        eblif = r_env.resolve(config['takes']['eblif'])

        build_dir = os.path.realpath(os.path.dirname(eblif))

        vpr_options = ['--fix_clusters', place_constraints]
        
        yield 'Running VPR...'
        vprargs = VprArgs(share, device, eblif, vpr_options=vpr_options)
        vpr('place', vprargs, cwd=build_dir)

        yield 'Saving log...'
        save_vpr_log('place.log')

    def __init__(self):
        self.stage_name = 'pack'
        self.no_of_phases = 2

do_module(PlaceModule())