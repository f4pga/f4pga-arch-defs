#!/usr/bin/env python3
import os, subprocess, sys, json
import yosys_utils

def get_yosys():
    return os.getenv('YOSYS', "yosys")

def run_yosys_get_output(params):
    cmd = [get_yosys()] + params
    return subprocess.check_output(cmd).decode("utf-8")

def run_yosys_commands(commands, infiles = []):
    params = ["-q", "-p", commands] + infiles
    return run_yosys_get_output(params)

def run_yosys_script(script, infiles = []):
    params = ["-q", "-s", script] + infiles
    return run_yosys_get_output(params)

def vlog_to_json(infiles, flatten = False, aig = False):
    prep_opts = "-flatten" if flatten else ""
    json_opts = "-aig" if aig else ""
    cmds = "prep %s; write_json %s" % (prep_opts, json_opts)
    j = yosys_utils.strip_yosys_json(run_yosys_commands(cmds, infiles))
    """with open('dump.json', 'w') as dbg:
        print(j,file=dbg)"""
    return json.loads(j)
