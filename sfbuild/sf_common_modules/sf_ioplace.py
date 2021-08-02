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

        p = ctx.takes.net
        m = re.match('(.*)\\.[^.]*$', ctx.takes.net)
        if m:
            p = m.groups()[0]

        mapping['io_place'] = p + '.ioplace'

        return mapping

    def execute(self, ctx: ModuleContext):
        io_gen = os.path.join(ctx.share, 'scripts/prjxray_create_ioplace.py')
        pinmap = os.path.join(ctx.share, 'arch', ctx.values.device,
                              ctx.values.part_name, 'pinmap.csv')

        if not os.path.isfile(pinmap) and not os.path.islink(pinmap):
            fatal(-1, f'Pinmap file \"{pinmap}\" not found')
        
        pcf_opts = ['--pcf', ctx.takes.pcf] if ctx.takes.pcf else []
    
        yield 'Generating io.place...'
        data = sub(*(['python3', io_gen,
                      '--blif', ctx.takes.eblif,
                      '--map', pinmap,
                      '--net', ctx.takes.net]
                      + pcf_opts))
        
        yield 'Saving ioplace data...'
        with open(ctx.outputs.io_place, 'wb') as f:
            f.write(data)

    def __init__(self, _):
        self.name = 'io_place'
        self.no_of_phases = 2
        self.takes = [
            'eblif',
            'net',
            'pcf?'
        ]
        self.produces = [ 'io_place' ]
        self.values = [
            'device',
            'part_name'
        ]



do_module(IOPlaceModule)