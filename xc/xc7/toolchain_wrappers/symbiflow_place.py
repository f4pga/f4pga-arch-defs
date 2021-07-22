#!/usr/bin/python3

# Symbiflow Stage Module

# ----------------------------------------------------------------------------- #

import os
from symbiflow_common import *

# ----------------------------------------------------------------------------- #

def default_output_name(place_constraints):
    p = place_constraints
    m = re.match('(.*)\\.[^.]*$', place_constraints)
    if m:
        p = m.groups()[0] + '.place'
    else:
        p += '.place'
    return p

def place_constraints_file(config: dict, r_env: ResolutionEnv):
    dummy =- False
    p = config['takes'].get('place_constraints')
    if not p:
        p = config['takes'].get('io_place')
    if not p:
        dummy = True
        p = config['takes']['eblif']
    p = r_env.resolve(p)
    if dummy:
        m = re.match('(.*)\\.[^.]*$', p)
        if m:
            p = m.groups()[0] + '.place'
    
    return r_env.resolve(p), dummy

class PlaceModule(Module):
    def map_io(self, config: dict, r_env: ResolutionEnv):
        mapping = {}
        p, _ = place_constraints_file(config, r_env)
        
        mapping['place'] = default_output_name(p)
        mapping.update(r_env.resolve(config['produces']))
        return mapping
    
    def execute(self, share: str, config: dict, outputs: dict,
                r_env: ResolutionEnv):
        place_constraints, dummy = place_constraints_file(config, r_env)
        place_constraints = os.path.realpath(place_constraints)
        if dummy:
            with open(place_constraints, 'wb') as f:
                f.write(b'')
        
        device = config['values']['device']
        eblif = os.path.realpath(r_env.resolve(config['takes']['eblif']))

        build_dir = os.path.realpath(os.path.dirname(eblif))

        vpr_options = ['--fix_clusters', place_constraints]
        platform_pack_vpr_options = config['values'].get('vpr_options')
        if platform_pack_vpr_options:
            vpr_options += options_dict_to_list(platform_pack_vpr_options)

        
        yield 'Running VPR...'
        vprargs = VprArgs(share, device, eblif, vpr_options=vpr_options)
        vpr('place', vprargs, cwd=build_dir)
        
        # VPR names output on its own. If user requested another name, the
        # output file should be moved.
        # TODO: This extends the set of names that would cause collisions.
        # As for now (22-07-2021), no collision detection is being done, but
        # when the problem gets tackled, we should keep in mind that VPR-based
        # modules may produce some temporary files with names that differ from
        # the ones in flow configuration.
        if config['produces'].get('place'):
            output_file = default_output_name(place_constraints)
            shutil.move(output_file, outputs['place'])

        yield 'Saving log...'
        save_vpr_log('place.log', build_dir=build_dir)

    def __init__(self):
        self.stage_name = 'place'
        self.no_of_phases = 2

do_module(PlaceModule())