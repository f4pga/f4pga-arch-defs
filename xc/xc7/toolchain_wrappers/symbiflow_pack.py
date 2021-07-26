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

        eblif = ctx.take_require('eblif')
        p = eblif
        build_dir = os.path.dirname(p)
        m = re.match('(.*)\\.[^.]*$', eblif)
        if m:
            p = m.groups()[0] 
        mapping['net'] = p + '.net'
        mapping['util_rpt'] = \
            os.path.join(build_dir, DEFAULT_UTIL_RPT)
        mapping['timing_rpt'] = \
            os.path.join(build_dir, DEFAULT_TIMING_RPT)
        mapping.update(ctx.r_env.resolve(ctx.produces))
        return mapping
    
    def execute(self, ctx: ModuleContext):
        eblif = os.path.realpath(ctx.take_require('eblif'))
        sdc = os.path.realpath(ctx.take_maybe('sdc'))
        device = ctx.value_require('device')
        platform_pack_vpr_options = ctx.value_maybe('vpr_options')
        vpr_options = []
        if platform_pack_vpr_options:
            vpr_options = options_dict_to_list(platform_pack_vpr_options)
        vpr_args = VprArgs(ctx.share, device, eblif, sdc_file=sdc,
                           vpr_options=vpr_options)
        build_dir = os.path.dirname(ctx.output('net'))

        noisy_warnings(device)

        yield 'Packing with VPR...'
        vpr('pack', vpr_args, cwd=build_dir)

        log = ctx.output('log')
        og_log = os.path.join(build_dir, 'vpr_stdout.log')

        yield 'Moving/deleting files...'
        if log:
            shutil.move(og_log, log)
        else:
            os.remove(og_log)
        
        timing_rpt = ctx.output('timing_rpt')
        if timing_rpt:
            shutil.move(os.path.join(build_dir, DEFAULT_TIMING_RPT), timing_rpt)
        util_rpt = ctx.output('util_rpt')
        if util_rpt:
            shutil.move(os.path.join(build_dir, DEFAULT_UTIL_RPT), util_rpt)
    
    def __init__(self):
        self.stage_name = 'pack'
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

do_module(PackModule())