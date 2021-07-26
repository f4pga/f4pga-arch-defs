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

        mapping['io_place'] = p + '.ioplace'

        mapping.update(ctx.r_env.resolve(ctx.produces))
        return mapping

    def execute(self, ctx: ModuleContext):
        eblif = ctx.take_require('eblif')
        net = ctx.take_require('net')
        pcf = ctx.take_maybe('pcf')
        part = ctx.value_require('part_name')
        device = ctx.value_require('device')
        ioplace = ctx.output('io_place')

        io_gen = os.path.join(ctx.share, 'scripts/prjxray_create_ioplace.py')
        pinmap = os.path.join(ctx.share, 'arch', device, part, 'pinmap.csv')

        if not os.path.isfile(pinmap) and not os.path.islink(pinmap):
            fatal(-1, f'Pinmap file \"{pinmap}\" not found')
        
        pcf_opts = ['--pcf', pcf] if pcf else []
    
        yield 'Generating io.place...'
        data = sub(*(['python3', io_gen,
                      '--blif', eblif,
                      '--map', pinmap,
                      '--net', net]
                      + pcf_opts))
        
        yield 'Saving ioplace data...'
        with open(ioplace, 'wb') as f:
            f.write(data)

    def __init__(self):
        self.stage_name = 'io_place'
        self.no_of_phases = 2
        self.takes = [
            'eblif',
            'net',
            'pcf?'
        ]
        self.produces = [ 'io_place' ]



do_module(IOPlaceModule())