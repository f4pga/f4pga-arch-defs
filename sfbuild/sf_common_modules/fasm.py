#!/usr/bin/python3

# Symbiflow Stage Module

# ----------------------------------------------------------------------------- #

import os
from sf_common import *
from sf_module import *

# ----------------------------------------------------------------------------- #

def concat_fasm(fasm: str, fasm_extra: str, output: str):
    fasm_data = None
    fasm_extra_data = None
    with open(fasm, 'r') as fasm_file, open(fasm_extra, 'r') as fasm_extra_file:
        fasm_data = fasm_file.read()
        fasm_extra_data = fasm_extra_file.read()
    data = fasm_data + '\n' + fasm_extra_data

    with open(output, 'w') as output_file:
        output_file.write(data)

def fasm_output_name(eblif: str):
    p = eblif
    m = re.match('(.*)\\.[^.]*$', eblif)
    if m:
        p = m.groups()[0]
    return p + '.fasm'

class FasmModule(Module):

    def map_io(self, ctx: ModuleContext):
        mapping = {}
        mapping['fasm'] = fasm_output_name(ctx.takes.eblif)
        return mapping
    
    def execute(self, ctx: ModuleContext):        
        build_dir = os.path.dirname(ctx.takes.eblif)
        
        vpr_options = []
        if ctx.values.vpr_options:
            vpr_options = options_dict_to_list(ctx.values.vpr_options)
        
        vprargs = VprArgs(ctx.share, ctx.values.device, ctx.takes.eblif,
                          vpr_options=vpr_options)

        yield 'Generating FASM...'
        sub(*(['genfasm', vprargs.arch_def,
               os.path.realpath(ctx.takes.eblif),
               '--device', vprargs.device_name,
               '--read_rr_graph', vprargs.rr_graph
        ] + vpr_options), cwd=build_dir)

        default_fasm_output_name = fasm_output_name(ctx.takes.eblif)
        if default_fasm_output_name != ctx.outputs.fasm:
            shutil.move(default_fasm_output_name, ctx.outputs.fasm)

        if ctx.takes.fasm_extra:
            yield 'Appending extra FASM...'
            concat_fasm(ctx.outputs.fasm, ctx.takes.fasm_extra, ctx.outputs.fasm)
        else:
            yield 'No extra FASM to append'
    
    def __init__(self, _):
        self.name = 'fasm'
        self.no_of_phases = 2
        self.takes = [
            'eblif',
            'net',
            'place',
            'route',
            'fasm_extra?'
        ]
        self.produces = [ 'fasm' ]
        self.values = [
            'device',
            'vpr_options?'
        ]

do_module(FasmModule)
