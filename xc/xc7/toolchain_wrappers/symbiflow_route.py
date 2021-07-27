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
        mapping['route'] = route_place_file(ctx.takes.eblif)
        return mapping
    
    def execute(self, ctx: ModuleContext):
        build_dir = os.path.dirname(ctx.takes.eblif)

        vpr_options = []
        if ctx.values.vpr_options:
            vpr_options = options_dict_to_list(ctx.values.vpr_options)
        
        vprargs = VprArgs(ctx.share, ctx.values.device, ctx.takes.eblif,
                          vpr_options=vpr_options)

        yield 'Routing with VPR...'
        vpr('route', vprargs, cwd=build_dir)

        if ctx.is_output_explicit('route'):
            shutil.move(route_place_file(ctx.takes.eblif), ctx.outputs.route)

        yield 'Saving log...'
        save_vpr_log('route.log', build_dir=build_dir)
        
    def __init__(self):
        self.stage_name = 'route'
        self.no_of_phases = 2
        self.takes = [ 'eblif' ]
        self.produces = [ 'route' ]
        self.values = [
            'device',
            'vpr_options?'
        ]

do_module(RouteModule())