#!/usr/bin/python3

# Symbiflow Stage Module

# ----------------------------------------------------------------------------- #

import sys
import os
import shutil
import symbiflow_common
from symbiflow_common import *

# ----------------------------------------------------------------------------- #

mypath = os.path.realpath(sys.argv[0])
mypath = os.path.dirname(mypath)

# Setup environmental variables for YOSYS TCL scripts
def yosys_setup_tcl_env(share, build_dir, top, bitstream_device, part,
                        techmap_path, out_json=None, out_sdc=None,
                        synth_json=None, out_synth_v=None, out_eblif=None,
                        out_fasm_extra=None, database_dir=None, use_roi=False,
                        xdc_files=None):
    utils_path = os.path.join(share, 'scripts')

    if not out_json:
        out_json = os.path.join(build_dir, top + '.json')
    if not out_sdc:
        out_sdc = os.path.join(build_dir, top + '.sdc')
    if not synth_json:
        synth_json = os.path.join(build_dir, top + '_io.json')
    if not out_synth_v:
        out_synth_v = os.path.join(build_dir, top + '_synth.v')
    if not out_eblif:
        out_eblif = os.path.join(build_dir, top + '.eblif')
    if not out_fasm_extra:
        out_fasm_extra = os.path.join(build_dir, top + '_fasm_extra.fasm')
    if not database_dir:
        database_dir = sub('prjxray-config').decode().replace('\n', '')
    part_json_path = \
        os.path.join(database_dir, bitstream_device, part, 'part.json')
    env = {
        'USE_ROI': 'FALSE',
        'TOP': top,
        'OUT_JSON': out_json,
        'OUT_SDC': out_sdc,
        'PART_JSON': os.path.realpath(part_json_path),
        'OUT_FASM_EXTRA': out_fasm_extra,
        'TECHMAP_PATH': techmap_path,
        'OUT_SYNTH_V': out_synth_v,
        'OUT_EBLIF': out_eblif,
        'PYTHON3': shutil.which('python3'),
        'UTILS_PATH': utils_path
    }
    if use_roi:
        env['USE_ROI'] = 'TRUE'
    if xdc_files and len(xdc_files) > 0:
        env['INPUT_XDC_FILES'] = ' '.join(xdc_files)
    return env

def yosys_synth(tcl, tcl_env, verilog_files=[], log=None):
    # Set up environment for TCL weirdness
    optional = []
    if log:
        optional += ['-l', log]
    env = os.environ.copy()
    env.update(tcl_env)
    
    # Execute YOSYS command
    return sub(*(['yosys', '-p', 'tcl ' + tcl] + optional + verilog_files),
               env=env)

def yosys_conv(tcl, tcl_env, synth_json):
    # Set up environment for TCL weirdness
    env = os.environ.copy()
    env.update(tcl_env)

    # Execute YOSYS command
    return sub('yosys', '-p', 'read_json ' + synth_json + '; tcl ' + tcl,
               env=env)

# ----------------------------------------------------------------------------- #

class SynthModule(Module):
    def map_io(self, config, r_env):
        mapping = {}
        for name, value in config['args'].items():
            if name == 'top':
                mapping['eblif'] = \
                    os.path.realpath(r_env.resolve(value + '.eblif'))
                mapping['fasm_extra'] = \
                    os.path.realpath(r_env.resolve(value + '_fasm_extra.fasm'))
                mapping['json'] = os.path.realpath(r_env.resolve(value + '.json'))
                mapping['synth_json'] = \
                    os.path.realpath(r_env.resolve(value + '_io.json'))
                mapping['sdc'] = os.path.realpath(r_env.resolve(value + '.sdc'))
                mapping['synth_v'] = \
                    os.path.realpath(r_env.resolve(value + '_synth.v'))
        # TODO: This doesn't work for some weird reaason
        mapping.update(r_env.resolve(config['produces']))
        return mapping
    
    def execute(self, share: str, config: dict, outputs: dict,
                r_env: ResolutionEnv):
        print('xd')
        split_inouts = os.path.join(share, 'scripts/split_inouts.py')
        tcl_scripts = r_env.resolve(config['values']['tcl_scripts'])
        synth_tcl = os.path.join(tcl_scripts, 'synth.tcl')
        conv_tcl = os.path.join(tcl_scripts, 'conv.tcl')

        sources = list(map(r_env.resolve, config['takes']['sources']))
        build_dir = r_env.resolve(config['values']['build_dir'])
        xdc_files = []
        out_json = outputs['json']
        synth_json = outputs['synth_json']
        top = r_env.resolve(config['args']['top'])
        if config['takes'].get('xdc'):
            xdc_files = list(map(r_env.resolve, config['takes']['xdc']))
        tcl_env = yosys_setup_tcl_env(share=share, build_dir=build_dir,
                                      top=top,
                                      bitstream_device=\
                                          config['values']['bitstream_device'],
                                      part=config['values']['part_name'],
                                      techmap_path=config['values']['techmap'],
                                      xdc_files=xdc_files, out_json=out_json,
                                      synth_json=synth_json,
                                      out_eblif=outputs['eblif'],
                                      out_sdc=outputs['sdc'],
                                      out_fasm_extra=outputs['fasm_extra'],
                                      out_synth_v=outputs['synth_v'])
                            
        yield f'Sythesizing sources: {sources}...'
        yosys_synth(synth_tcl, tcl_env, sources, config['produces'].get('log'))

        yield f'Splitting in/outs...'
        sub('python3', split_inouts, '-i', out_json, '-o', synth_json)

        yield f'Converting...'
        yosys_conv(conv_tcl, tcl_env, synth_json)
    
    def __init__(self):
        self.stage_name = 'Synthesis'
        self.no_of_phases = 3


do_module(SynthModule())