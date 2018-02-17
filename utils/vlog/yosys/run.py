#!/usr/bin/env python3
import os, subprocess, sys, json
import yosys.utils, tempfile, re

def get_yosys():
    return os.getenv('YOSYS', "yosys")

def yosys_get_output(params):
    cmd = [get_yosys()] + params
    return subprocess.check_output(cmd).decode("utf-8")

def yosys_commands(commands, infiles = []):
    params = ["-q", "-p", commands] + infiles
    return yosys_get_output(params)

def yosys_script(script, infiles = []):
    params = ["-q", "-s", script] + infiles
    return yosys_get_output(params)

def vlog_to_json(infiles, flatten = False, aig = False):
    prep_opts = "-flatten" if flatten else ""
    json_opts = "-aig" if aig else ""
    cmds = "prep %s; write_json %s" % (prep_opts, json_opts)
    j = yosys.utils.strip_yosys_json(yosys_commands(cmds, infiles))
    """with open('dump.json', 'w') as dbg:
        print(j,file=dbg)"""
    return json.loads(j)

"""
Extract the pin from a line of the result of a Yosys select command
"""
def extract_pin(module, pstr, _regex=re.compile(r"([^/]+)/([^/]+)")):
    m = re.match(r"([^/]+)/([^/]+)", pstr)
    if m and m.group(1) == module:
        return m.group(2)
    else:
        return None


"""
Run a Yosys select command (given the expression and input files) on a module
and return the result as a list of pins

TODO: All of these functions involve a fairly large number of calls to Yosys
Although performance here is unlikely to be a major priority any time soon,
it might be worth investigating better options?

"""
def do_select(infiles, module, expr):
    outfile = tempfile.mktemp()
    sel_cmd = "prep -top %s -flatten; cd %s; select -write %s %s" % (module, module, outfile, expr)
    yosys_commands(sel_cmd, infiles)
    pins = []
    with open(outfile, 'r') as f:
        for net in f:
            snet = net.strip()
            if(len(snet) > 0):
                pin = extract_pin(module, snet)
                if pin is not None:
                    pins.append(pin)
    os.remove(outfile)
    return pins

def get_combinational_sinks(infiles, module, innet):
    return do_select(infiles, module, "%s %%coe* o:* %%i %s %%d" % (innet, innet))

def list_clocks(infiles, module):
    return do_select(infiles, module, "c:* %x:+[CLK] c:* %d")

def get_clock_assoc_signals(infiles, module, clk):
    return do_select(infiles, module, "select -list %s %%x* i:* o:* %%u %%i %s %%d" % (clk, clk))
