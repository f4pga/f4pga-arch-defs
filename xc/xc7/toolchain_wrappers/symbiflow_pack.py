#!/usr/bin/python3

# Symbiflow Stage Module

# ----------------------------------------------------------------------------- #

import os
import re
from symbiflow_common import *
from symbiflow_module import *

# ----------------------------------------------------------------------------- #

DEFAULT_TIMING_RPT = 'pre_pack.report_timing.setup.rpt'
DEFAULT_UTIL_RPT = 'packing_pin_util.rpt'

class PackModule(Module):
    def map_io(self, ctx: ModuleContext):
        mapping = {}

        p = ctx.takes.eblif
        build_dir = os.path.dirname(p)
        m = re.match('(.*)\\.[^.]*$', ctx.takes.eblif)
        if m:
            p = m.groups()[0] 
        mapping['net'] = p + '.net'
        mapping['util_rpt'] = \
            os.path.join(build_dir, DEFAULT_UTIL_RPT)
        mapping['timing_rpt'] = \
            os.path.join(build_dir, DEFAULT_TIMING_RPT)
        
        return mapping
    
    def execute(self, ctx: ModuleContext):
        eblif = os.path.realpath(ctx.takes.eblif)
        sdc = os.path.realpath(ctx.takes.sdc) if ctx.takes.sdc else None
        vpr_options = []
        if ctx.values.vpr_options:
            vpr_options = options_dict_to_list(ctx.values.vpr_options)
        vpr_args = VprArgs(ctx.share, ctx.values.device, eblif, sdc_file=sdc,
                           vpr_options=vpr_options)
        build_dir = os.path.dirname(ctx.outputs.net)

        noisy_warnings(ctx.values.device)

        yield 'Packing with VPR...'
        vpr('pack', vpr_args, cwd=build_dir)

        og_log = os.path.join(build_dir, 'vpr_stdout.log')

        yield 'Moving/deleting files...'
        if ctx.outputs.pack_log:
            shutil.move(og_log, ctx.outputs.pack_log)
        else:
            os.remove(og_log)
        
        if ctx.outputs.timing_rpt:
            shutil.move(os.path.join(build_dir, DEFAULT_TIMING_RPT),
                        ctx.outputs.timing_rpt)
        if ctx.outputs.util_rpt:
            shutil.move(os.path.join(build_dir, DEFAULT_UTIL_RPT),
                        ctx.outputs.util_rpt)
    
    def __init__(self, _):
        self.name = 'pack'
        self.no_of_phases = 2
        self.takes = [
            'eblif',
            'sdc?'
        ]
        self.produces = [
            'net',
            'util_rpt',
            'timing_rpt',
            'pack_log?'
        ]
        self.values = [
            'device',
            'vpr_options?'
        ]

do_module(PackModule)