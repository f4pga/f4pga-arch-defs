#!/usr/bin/python3

# Symbiflow Stage Module

# ----------------------------------------------------------------------------- #

import os
import shutil
from symbiflow_common import *
from symbiflow_module import *

# ----------------------------------------------------------------------------- #

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
    def map_io(self, ctx: ModuleContext):
        mapping = {}
        top = ctx.value_maybe('top')
        if top:
            mapping['eblif'] = os.path.realpath(top + '.eblif')
            mapping['fasm_extra'] = os.path.realpath(top + '_fasm_extra.fasm')
            mapping['json'] = os.path.realpath(top + '.json')
            mapping['synth_json'] = os.path.realpath(top + '_io.json')
            mapping['sdc'] = os.path.realpath(top + '.sdc')
            mapping['synth_v'] = os.path.realpath(top + '_synth.v')
        mapping.update(ctx.r_env.resolve(ctx.produces))
        return mapping
    
    def execute(self, ctx: ModuleContext):
        split_inouts = os.path.join(ctx.share, 'scripts/split_inouts.py')
        tcl_scripts = ctx.value_require('tcl_scripts')
        synth_tcl = os.path.join(tcl_scripts, 'synth.tcl')
        conv_tcl = os.path.join(tcl_scripts, 'conv.tcl')

        sources = ctx.take_require('sources')
        out_json = ctx.output('json')
        build_dir = os.path.dirname(out_json)
        techmap_path = ctx.value_require('techmap')
        synth_json = ctx.output('synth_json')
        top = ctx.value_maybe('top')
        if not top:
            top = 'top'
        xdc_files = ctx.take_maybe('xdc')
        if not xdc_files:
            xdc_files = []
        tcl_env = yosys_setup_tcl_env(share=ctx.share, build_dir=build_dir,
                                      top=top,
                                      bitstream_device=\
                                          ctx.value_require('bitstream_device'),
                                      part=ctx.value_require('part_name'),
                                      techmap_path=techmap_path,
                                      xdc_files=xdc_files, out_json=out_json,
                                      synth_json=synth_json,
                                      out_eblif=ctx.output('eblif'),
                                      out_sdc=ctx.output('sdc'),
                                      out_fasm_extra=ctx.output('fasm_extra'),
                                      out_synth_v=ctx.output('synth_v'))
                            
        yield f'Sythesizing sources: {sources}...'
        yosys_synth(synth_tcl, tcl_env, sources, ctx.output('log'))

        yield f'Splitting in/outs...'
        sub('python3', split_inouts, '-i', out_json, '-o', synth_json)

        yield f'Converting...'
        yosys_conv(conv_tcl, tcl_env, synth_json)
    
    def __init__(self):
        self.stage_name = 'synthesize'
        self.no_of_phases = 3
        self.takes = [
            'sources',
            'xdc?'
        ]
        self.produces = [
            'eblif',
            'fasm_extra?',
            'json',
            'synth_json',
            'sdc',
            'synth_v',
            'synth_log?'
        ]
        self.prod_meta = {
            'eblif': 'Extended BLIF hierarchical sequential designs file\n'
                     'generated by YOSYS',
            'json': 'JSON file containing a design generated by YOSYS',
            'synth_log': 'YOSYS synthesis log'
        }

do_module(SynthModule())