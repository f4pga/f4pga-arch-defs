#!/usr/bin/python3

# Symbiflow Stage Module

# ----------------------------------------------------------------------------- #

import os
from sf_common import *
from sf_module import *

# ----------------------------------------------------------------------------- #

class IOPlaceModule(Module):
    def map_io(self, ctx: ModuleContext):
        mapping = {}
        net = ctx.takes.net

        p = net
        m = re.match('(.*)\\.[^.]*$', net)
        if m:
            p = m.groups()[0]

        mapping['place_constraints'] = p + '.preplace'

        return mapping

    def execute(self, ctx: ModuleContext):
        arch_dir = os.path.join(ctx.share, 'arch')
        arch_def = os.path.join(arch_dir, ctx.values.device, 'arch.timing.xml')

        constr_gen = os.path.join(ctx.share,
                                  'scripts/prjxray_create_place_constraints.py')
        vpr_grid_map = os.path.join(ctx.share, 'arch', ctx.values.device,
                                    'vpr_grid_map.csv')

        if not os.path.isfile(vpr_grid_map) and not os.path.islink(vpr_grid_map):
            fatal(-1, f'Gridmap file \"{vpr_grid_map}\" not found')
        
        database = sub('prjxray-config').decode().replace('\n', '')
        
        yield 'Generating .place...'
        data = sub('python3', constr_gen,
                   '--net', ctx.takes.net,
                   '--arch', arch_def,
                   '--blif', ctx.takes.eblif,
                   '--vpr_grid_map', vpr_grid_map,
                   '--input', ctx.takes.io_place,
                   '--db_root', database,
                   '--part', ctx.values.part_name)
        
        yield 'Saving place constraint data...'
        with open(ctx.outputs.place_constraints, 'wb') as f:
            f.write(data)

    def __init__(self, _):
        self.name = 'place_constraints'
        self.no_of_phases = 2
        self.takes = [
            'eblif',
            'net',
            'io_place'
        ]
        self.produces = [ 'place_constraints' ]
        self.values = [
            'device',
            'part_name'
        ]

do_module(IOPlaceModule)