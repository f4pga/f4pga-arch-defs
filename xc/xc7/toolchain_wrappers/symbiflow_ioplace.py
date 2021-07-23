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

        mapping['io_place'] = p + '.ioplace'

        mapping.update(r_env.resolve(config['produces']))
        return mapping

    def execute(self, share: str, config: dict, outputs: dict,
                r_env: ResolutionEnv):
        eblif = r_env.resolve(config['takes']['eblif'])
        net = r_env.resolve(config['takes']['net'])
        pcf = r_env.resolve(config['takes'].get('pcf'))
        part = config['values']['part_name']
        device = config['values']['device']
        ioplace = r_env.resolve(outputs['io_place'])

        io_gen = os.path.join(share, 'scripts/prjxray_create_ioplace.py')
        pinmap = os.path.join(share, 'arch', device, part, 'pinmap.csv')

        if not os.path.isfile(pinmap) and not os.path.islink(pinmap):
            fatal(-1, f'Pinmap file \"{pinmap}\" not found')
        
        pcf_opts = ['--pcf', r_env.resolve(pcf)] if pcf else []
    
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