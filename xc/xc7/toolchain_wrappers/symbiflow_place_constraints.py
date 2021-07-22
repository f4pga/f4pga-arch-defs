#!/usr/bin/python3

# Symbiflow Stage Module

# ----------------------------------------------------------------------------- #

import os
from symbiflow_common import *

# ----------------------------------------------------------------------------- #

class IOPlaceModule(Module):
    def map_io(self, config: dict, r_env: ResolutionEnv):
        mapping = {}
        net = config['takes']['net']

        p = net
        m = re.match('(.*)\\.[^.]*$', net)
        if m:
            p = m.groups()[0]

        mapping['place_constraints'] = p + '.preplace'

        mapping.update(r_env.resolve(config['produces']))
        return mapping

    def execute(self, share: str, config: dict, outputs: dict,
                r_env: ResolutionEnv):
        eblif = r_env.resolve(config['takes']['eblif'])
        net = r_env.resolve(config['takes']['net'])
        ioplace = r_env.resolve(config['takes']['io_place'])
        place_constraints = r_env.resolve(outputs['place_constraints'])

        part = config['values']['part_name']
        device = config['values']['device']

        arch_dir = os.path.join(share, 'arch')
        arch_def = os.path.join(arch_dir, device, 'arch.timing.xml')

        constr_gen = \
            os.path.join(share, 'scripts/prjxray_create_place_constraints.py')
        vpr_grid_map = os.path.join(share, 'arch', device, 'vpr_grid_map.csv')

        if not os.path.isfile(vpr_grid_map) and not os.path.islink(vpr_grid_map):
            fatal(-1, f'Gridmap file \"{vpr_grid_map}\" not found')
        
        database = sub('prjxray-config').decode().replace('\n', '')
        
        yield 'Generating .place...'
        data = sub('python3', constr_gen,
                   '--net', net,
                   '--arch', arch_def,
                   '--blif', eblif,
                   '--vpr_grid_map', vpr_grid_map,
                   '--input', ioplace,
                   '--db_root', database,
                   '--part', part)
        
        yield 'Saving place constraint data...'
        with open(place_constraints, 'wb') as f:
            f.write(data)

    def __init__(self):
        self.stage_name = 'place_constraints'
        self.no_of_phases = 2



do_module(IOPlaceModule())