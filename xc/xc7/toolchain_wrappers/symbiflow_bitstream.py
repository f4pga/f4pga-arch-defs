#!/usr/bin/python3

# Symbiflow Stage Module

# ----------------------------------------------------------------------------- #

import os
from symbiflow_common import *

# ----------------------------------------------------------------------------- #

def bitstream_output_name(fasm: str):
    p = fasm
    m = re.match('(.*)\\.[^.]*$', fasm)
    if m:
        p = m.groups()[0]
    return p + '.bit'

class BitstreamModule(Module):
    def map_io(self, config: dict, r_env: ResolutionEnv):
        mapping = {}
        oname = r_env.resolve(bitstream_output_name(config['takes']['fasm']))
        mapping['bitstream'] = oname
        mapping.update(r_env.resolve(config['produces']))
        return mapping
    
    def execute(self, share: str, config: dict, outputs: dict,
                r_env: ResolutionEnv):
        fasm = os.path.realpath(r_env.resolve(config['takes']['fasm']))
        bitstream_device = r_env.resolve(config['values']['bitstream_device'])
        part = r_env.resolve(config['values']['part_name'])
        database = sub('prjxray-config').decode().replace('\n', '')
        database = os.path.join(database, bitstream_device)

        yield 'Compiling FASM to bitstream...'
        sub(*(['xcfasm',
               '--db-root', database,
               '--part', part,
               '--part_file', os.path.join(database, part, 'part.yaml'),
               '--sparse',
               '--emit_pudc_b_pullup',
               '--fn_in', fasm,
               '--frm2bit', 'xc7frames2bit',
               '--bit_out', outputs['bitstream']
               ]))
    
    def __init__(self):
        self.stage_name = 'bitstream'
        self.no_of_phases = 1
        self.takes = [ 'fasm' ]
        self.produces = [ 'bitstream' ]

do_module(BitstreamModule())