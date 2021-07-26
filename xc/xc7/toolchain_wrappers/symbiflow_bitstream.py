#!/usr/bin/python3

# Symbiflow Stage Module

# ----------------------------------------------------------------------------- #

import os
from symbiflow_common import *
from symbiflow_module import *

# ----------------------------------------------------------------------------- #

def bitstream_output_name(fasm: str):
    p = fasm
    m = re.match('(.*)\\.[^.]*$', fasm)
    if m:
        p = m.groups()[0]
    return p + '.bit'

class BitstreamModule(Module):
    def map_io(self, ctx: ModuleContext):
        mapping = {}
        oname = bitstream_output_name(ctx.take_require('fasm'))
        mapping['bitstream'] = oname
        mapping.update(ctx.r_env.resolve(ctx.produces))
        return mapping
    
    def execute(self, ctx: ModuleContext):
        fasm = os.path.realpath(ctx.take_require('fasm'))
        bitstream_device = ctx.value_require('bitstream_device')
        part = ctx.value_require('part_name')
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
               '--bit_out', ctx.output('bitstream')
               ]))
    
    def __init__(self):
        self.stage_name = 'bitstream'
        self.no_of_phases = 1
        self.takes = [ 'fasm' ]
        self.produces = [ 'bitstream' ]

do_module(BitstreamModule())