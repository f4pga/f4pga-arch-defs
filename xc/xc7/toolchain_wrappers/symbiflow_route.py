#!/usr/bin/python3

# Symbiflow Stage Module

# ----------------------------------------------------------------------------- #

import os
import shutil
from symbiflow_common import *
from symbiflow_module import *

# ----------------------------------------------------------------------------- #

def route_place_file(eblif: str):
    p = eblif
    m = re.match('(.*)\\.[^.]*$', eblif)
    if m:
        p = m.groups()[0]
    return p + '.route' 

class RouteModule(Module):
    def map_io(self, ctx: ModuleContext):
        mapping = {}
        eblif =ctx.take_require('eblif')
        mapping['route'] = route_place_file(eblif)
        mapping.update(ctx.r_env.resolve(ctx.produces))
        return mapping
    
    def execute(self, ctx: ModuleContext):
        
        device = ctx.value_require('device')
        eblif = os.path.realpath(ctx.take_require('eblif'))
        build_dir = os.path.dirname(eblif)

        vpr_options = []
        platform_pack_vpr_options = ctx.value_maybe('vpr_options')
        if platform_pack_vpr_options:
            vpr_options = options_dict_to_list(platform_pack_vpr_options)
        
        vprargs = VprArgs(ctx.share, device, eblif, vpr_options=vpr_options)

        yield 'Routing with VPR...'
        vpr('route', vprargs, cwd=build_dir)

        if ctx.is_output_explicit('route'):
            shutil.move(route_place_file(eblif), ctx.output('route'))

        yield 'Saving log...'
        save_vpr_log('route.log', build_dir=build_dir)
        
    def __init__(self):
        self.stage_name = 'route'
        self.no_of_phases = 2
        self.takes = [ 'eblif' ]
        self.produces = [ 'route' ]

do_module(RouteModule())