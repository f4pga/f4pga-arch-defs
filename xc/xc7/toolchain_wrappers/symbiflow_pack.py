#!/usr/bin/python3

# Symbiflow Stage Module

# ----------------------------------------------------------------------------- #

import os
import re
from symbiflow_common import *

# ----------------------------------------------------------------------------- #

class PackModule(Module):
    def map_io(self, config, r_env):
        mapping = {}
        for name, value in config['takes'].items():
            if name == 'eblif':
                p = value
                m = re.match('(.*)\\.[^.]*$', value)
                if m:
                    p = m.groups[0] 
                mapping['net'] = p + '.net'
                mapping['util_rpt'] = p + '_util.rpt'
                mapping['timing_rpt'] = p + '_timing.rpt'
        mapping.update(r_env.resolve(config['produces']))
        return mapping
    
    def execute(self, share: str, config: dict, outputs: dict,
                r_env: ResolutionEnv):
        eblif = config['takes']['eblif']
        sdc = config['takes'].get('sdc')
        device = config['values']['device']
        platform_pack_vpr_options = config['values'].get('vpr_options')
        vpr_options = []
        if platform_pack_vpr_options:
            vpr_options = options_dict_to_list(platform_pack_vpr_options)
        vpr_args = VprArgs(share, device, eblif, sdc_file=sdc,
                           vpr_options=vpr_options)
        build_dir = os.path.dirname(config['produces']['net'])

        noisy_warnings(config['values']['device'])

        yield 'Packing with VPR...'
        vpr('pack', vpr_args, cwd=build_dir)

        log = config['produces'].get('log')
        og_log = os.path.join(build_dir, 'vpr_stdout.log')

        if log:
            yield 'Moving log file...'
            shutil.move(og_log, log)
        else:
            yield 'Deleting log file...'
            os.remove(og_log)
    
    def __init__(self):
        self.stage_name = 'Packing'
        self.no_of_phases = 2