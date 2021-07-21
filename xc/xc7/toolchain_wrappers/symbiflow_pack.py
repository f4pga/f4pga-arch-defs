#!/usr/bin/python3

# Symbiflow Stage Module

# ----------------------------------------------------------------------------- #

import os
import re
from symbiflow_common import *

# ----------------------------------------------------------------------------- #

DEFAULT_TIMING_RPT = 'pre_pack.report_timing.setup.rpt'
DEFAULT_UTIL_RPT = 'packing_pin_util.rpt'

class PackModule(Module):
    def map_io(self, config, r_env):
        mapping = {}

        eblif = config['takes'].get('eblif')
        if eblif:
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
        mapping.update(r_env.resolve(config['produces']))
        return mapping
    
    def execute(self, share: str, config: dict, outputs: dict,
                r_env: ResolutionEnv):
        eblif = os.path.realpath(r_env.resolve(config['takes']['eblif']))
        sdc = os.path.realpath(r_env.resolve(config['takes'].get('sdc')))
        device = r_env.resolve(config['values']['device'])
        platform_pack_vpr_options = config['values'].get('vpr_options')
        vpr_options = []
        if platform_pack_vpr_options:
            vpr_options = options_dict_to_list(platform_pack_vpr_options)
        vpr_args = VprArgs(share, device, eblif, sdc_file=sdc,
                           vpr_options=vpr_options)
        build_dir = os.path.dirname(r_env.resolve(config['produces']['net']))

        noisy_warnings(config['values']['device'])

        yield 'Packing with VPR...'
        vpr('pack', vpr_args, cwd=build_dir)

        log = config['produces'].get('log')
        og_log = os.path.join(build_dir, 'vpr_stdout.log')

        yield 'Moving/deleting files...'
        if log:
            shutil.move(og_log, log)
        else:
            os.remove(og_log)
        
        timing_rpt = config.get('timing_rpt')
        if timing_rpt:
            shutil.move(os.path.join(build_dir, DEFAULT_TIMING_RPT), timing_rpt)
        util_rpt = config.get('utiling_rpt')
        if timing_rpt:
            shutil.move(os.path.join(build_dir, DEFAULT_UTIL_RPT), util_rpt)
    
    def __init__(self):
        self.stage_name = 'pack'
        self.no_of_phases = 2

do_module(PackModule())