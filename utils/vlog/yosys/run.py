#!/usr/bin/env python3
import os, subprocess, sys, re
import tempfile, json
import yosys.utils

def get_yosys():
    return os.getenv('YOSYS', "yosys")

def get_output(params):
    cmd = [get_yosys()] + params
    return subprocess.check_output(cmd).decode("utf-8")

defines = []

def add_define(defname):
    defines.append(defname)

def get_defines():
    return " ".join(["-D" + _ for _ in defines])

def commands(commands, infiles = []):
    commands = "read_verilog %s %s; " % (get_defines(), " ".join(infiles)) + commands
    params = ["-q", "-p", commands]
    return get_output(params)

def script(script, infiles = []):
    params = ["-q", "-s", script] + infiles
    return get_output(params)

def vlog_to_json(infiles, flatten = False, aig = False):
    """
    Convert Verilog to a JSON representation using Yosys

    Inputs
    -------
    infiles : list of input files
    flatten : set to flatten output hierarchy
    aig : generate And-Inverter-Graph modules for gates
    """
    prep_opts = "-flatten" if flatten else ""
    json_opts = "-aig" if aig else ""
    cmds = "prep %s; write_json %s" % (prep_opts, json_opts)
    j = yosys.utils.strip_yosys_json(commands(cmds, infiles))
    """with open('dump.json', 'w') as dbg:
        print(j,file=dbg)"""
    return json.loads(j)


def extract_pin(module, pstr, _regex=re.compile(r"([^/]+)/([^/]+)")):
    """
    Extract the pin from a line of the result of a Yosys select command
    """
    m = re.match(r"([^/]+)/([^/]+)", pstr)
    if m and m.group(1) == module:
        return m.group(2)
    else:
        return None



def do_select(infiles, module, expr):
    """
    Run a Yosys select command (given the expression and input files) on a module
    and return the result as a list of pins
    """

    """TODO: All of these functions involve a fairly large number of calls to Yosys
    Although performance here is unlikely to be a major priority any time soon,
    it might be worth investigating better options?"""


    outfile = tempfile.mktemp()
    sel_cmd = "prep -top %s -flatten; cd %s; select -write %s %s" % (module, module, outfile, expr)
    commands(sel_cmd, infiles)
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
    """Return a list of output ports which are combinational sinks of a given
    input."""
    return do_select(infiles, module, "%s %%coe* o:* %%i %s %%d" % (innet, innet))

def list_clocks(infiles, module):
    """Return a list of clocks in the module"""
    return do_select(infiles, module, "c:* %x:+[CLK] a:CLOCK=1 %u c:* %d")

def get_clock_assoc_signals(infiles, module, clk):
    """Return the list of signals associated with a given clock."""
    return do_select(infiles, module, "select -list %s %%x* i:* o:* %%u %%i a:ASSOC_CLOCK=%s %%u %s %%d" % (clk, clk, clk))
