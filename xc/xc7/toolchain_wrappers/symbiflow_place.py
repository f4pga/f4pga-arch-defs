#!/usr/bin/python3

# Symbiflow Stage Module

# ----------------------------------------------------------------------------- #

import os
from symbiflow_common import *
from symbiflow_module import *

# ----------------------------------------------------------------------------- #

def default_output_name(place_constraints):
    p = place_constraints
    m = re.match('(.*)\\.[^.]*$', place_constraints)
    if m:
        p = m.groups()[0] + '.place'
    else:
        p += '.place'
    return p

def place_constraints_file(ctx: ModuleContext):
    dummy =- False
    p = ctx.take_maybe('place_constraints')
    if not p:
        p = ctx.take_maybe('io_place')
    if not p:
        dummy = True
        p = ctx.take_require('eblif')
    if dummy:
        m = re.match('(.*)\\.[^.]*$', p)
        if m:
            p = m.groups()[0] + '.place'
    
    return p, dummy

class PlaceModule(Module):
    def map_io(self, ctx: ModuleContext):
        mapping = {}
        p, _ = place_constraints_file(ctx)
        
        mapping['place'] = default_output_name(p)
        mapping.update(ctx.r_env.resolve(ctx.produces))
        return mapping
    
    def execute(self, ctx: ModuleContext):
        place_constraints, dummy = place_constraints_file(ctx)
        place_constraints = os.path.realpath(place_constraints)
        if dummy:
            with open(place_constraints, 'wb') as f:
                f.write(b'')
        
        device = ctx.value_require('device')
        eblif = os.path.realpath(ctx.take_require('eblif'))

        build_dir = os.path.dirname(eblif)

        vpr_options = ['--fix_clusters', place_constraints]
        platform_pack_vpr_options = ctx.value_maybe('vpr_options')
        if platform_pack_vpr_options:
            vpr_options += options_dict_to_list(platform_pack_vpr_options)

        
        yield 'Running VPR...'
        vprargs = VprArgs(ctx.share, device, eblif, vpr_options=vpr_options)
        vpr('place', vprargs, cwd=build_dir)
        
        # VPR names output on its own. If user requested another name, the
        # output file should be moved.
        # TODO: This extends the set of names that would cause collisions.
        # As for now (22-07-2021), no collision detection is being done, but
        # when the problem gets tackled, we should keep in mind that VPR-based
        # modules may produce some temporary files with names that differ from
        # the ones in flow configuration.
        if ctx.is_output_explicit('place'):
            output_file = default_output_name(place_constraints)
            shutil.move(output_file, ctx.output('place'))

        yield 'Saving log...'
        save_vpr_log('place.log', build_dir=build_dir)

    def __init__(self):
        self.stage_name = 'place'
        self.no_of_phases = 2
        self.takes = [
            'eblif',
            'place_constraints?',
            'io_place?'
        ]
        self.produces = [ 'place' ]

do_module(PlaceModule())