#!/usr/bin/python3

# Symbiflow Stage Module

# ----------------------------------------------------------------------------- #

import os
from symbiflow_common import *
from symbiflow_module import *

# ----------------------------------------------------------------------------- #

class IOPlaceModule(Module):
    def map_io(self, ctx: ModuleContext):
        mapping = {}
        net = ctx.take_require('net')

        p = net
        m = re.match('(.*)\\.[^.]*$', net)
        if m:
            p = m.groups()[0]

        mapping['place_constraints'] = p + '.preplace'

        mapping.update(ctx.r_env.resolve(ctx.produces))
        return mapping

    def execute(self, ctx: ModuleContext):
        eblif = ctx.take_require('eblif')
        net = ctx.take_require('net')
        ioplace = ctx.take_require('io_place')
        place_constraints = ctx.output('place_constraints')

        part = ctx.value_require('part_name')
        device = ctx.value_require('device')

        arch_dir = os.path.join(ctx.share, 'arch')
        arch_def = os.path.join(arch_dir, device, 'arch.timing.xml')

        constr_gen = \
            os.path.join(ctx.share, 'scripts/prjxray_create_place_constraints.py')
        vpr_grid_map = os.path.join(ctx.share, 'arch', device, 'vpr_grid_map.csv')

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
        self.takes = [
            'eblif',
            'net',
            'io_place'
        ]
        self.produces = [ 'place_constraints' ]

do_module(IOPlaceModule())