#!/usr/bin/python3

# Symbiflow Stage Module

# ----------------------------------------------------------------------------- #

import os
from symbiflow_common import *

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
    def map_io(self, config: dict, r_env: ResolutionEnv):
        mapping = {}
        eblif = r_env.resolve(config['takes']['eblif'])
        mapping['fasm'] = fasm_output_name(eblif)
        mapping.update(r_env.resolve(config['produces']))
        return mapping
    
    def execute(self, share: str, config: dict, outputs: dict,
                r_env: ResolutionEnv):
        eblif = os.path.realpath(r_env.resolve(config['takes']['eblif']))
        fasm_extra = config['takes'].get('fasm_extra')
        if fasm_extra:
            fasm_extra = os.path.realpath(r_env.resolve(fasm_extra))
        
        device = r_env.resolve(config['values']['device'])
        build_dir = os.path.dirname(eblif)
        
        vpr_options = []
        platform_pack_vpr_options = config['values'].get('vpr_options')
        if platform_pack_vpr_options:
            vpr_options = options_dict_to_list(platform_pack_vpr_options)
        
        vprargs = VprArgs(share, device, eblif, vpr_options=vpr_options)

        yield 'Generating FASM...'
        sub(*(['genfasm', vprargs.arch_def,
               eblif,
               '--device', vprargs.device_name,
               '--read_rr_graph', vprargs.rr_graph
        ] + vpr_options), cwd=build_dir)

        default_fasm_output_name = fasm_output_name(eblif)
        if default_fasm_output_name != outputs['fasm']:
            shutil.move(default_fasm_output_name, outputs['fasm'])

        if fasm_extra:
            yield 'Appending extra FASM...'
            concat_fasm(outputs['fasm'], fasm_extra, outputs['fasm'])
        else:
            yield 'No extra FASM to append'
    
    def __init__(self):
        self.stage_name = 'fasm'
        self.no_of_phases = 2

do_module(FasmModule())
