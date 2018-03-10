#!/usr/bin/env python3
import os, subprocess, sys, re
import tempfile, json
import yosys.utils

def get_yosys():
    """Return how to execute Yosys: the value of $YOSYS if set, otherwise just
    `yosys`."""
    return os.getenv("YOSYS", "yosys")

def get_output(params):
    """Run Yosys with given command line parameters, and return stdout as a string"""
    cmd = [get_yosys()] + params
    return subprocess.check_output(cmd).decode("utf-8")

defines = []

def add_define(defname):
    """Add a Verilog define to the list of defines to set in Yosys"""
    defines.append(defname)

def get_defines():
    """Return a list of set Verilog defines, as a list of arguments to pass to Yosys `read_verilog`"""
    return " ".join(["-D" + _ for _ in defines])

def commands(commands, infiles = []):
    """Run a given string containing Yosys commands

    Inputs
    -------
    commands : string of Yosys commands to run
    infiles : list of input files
    """
    commands = "read_verilog %s %s; " % (get_defines(), " ".join(infiles)) + commands
    params = ["-q", "-p", commands]
    return get_output(params)

def script(script, infiles = []):
    """Run a Yosys script given a path to the script

    Inputs
    -------
    script : path to Yosys script to run
    infiles : list of input files
    """
    params = ["-q", "-s", script] + infiles
    return get_output(params)

def vlog_to_json(infiles, flatten = False, aig = False, mode = None, mode_mod = None):
    """
    Convert Verilog to a JSON representation using Yosys

    Inputs
    -------
    infiles : list of input files
    flatten : set to flatten output hierarchy
    aig : generate And-Inverter-Graph modules for gates
    mode : set to a value other than None to use `chparam` to set the value of the MODE parameter
    mode_mod : the name of the module to apply `mode` to
    """
    prep_opts = "-flatten" if flatten else ""
    json_opts = "-aig" if aig else ""
    if mode is not None:
        mode_str = 'chparam -set MODE "%s" %s; ' % (mode, mode_mod)
    else:
        mode_str = ""
    cmds = "%sprep %s; write_json %s" % (mode_str, prep_opts, json_opts)
    j = yosys.utils.strip_yosys_json(commands(cmds, infiles))
    """with open('dump.json', 'w') as dbg:
        print(j,file=dbg)"""
    return json.loads(j)


def extract_pin(module, pstr, _regex=re.compile(r"([^/]+)/([^/]+)")):
    """
    Extract the pin from a line of the result of a Yosys select command, or
    None if the command result is irrelevant (e.g. does not correspond to the
    correct module)

    Inputs
    -------
    module: Name of module to extract pins from
    pstr: Line from Yosys select command (`module/pin` format)
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

    Inputs
    -------
    infiles: List of Verilog source files to pass to Yosys
    module: Name of module to run command on
    expr: Yosys selector expression for select command
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
    input.

    Inputs
    -------
    infiles: List of Verilog source files to pass to Yosys
    module: Name of module to run command on
    innet: Name of input net to find sinks of
    """
    return do_select(infiles, module, "%s %%coe* o:* %%i %s %%d" % (innet, innet))

def list_clocks(infiles, module):
    """Return a list of clocks in the module

    Inputs
    -------
    infiles: List of Verilog source files to pass to Yosys
    module: Name of module to run command on
    """
    return do_select(infiles, module, "c:* %x:+[CLK] a:CLOCK=1 %u c:* %d")

def get_clock_assoc_signals(infiles, module, clk):
    """Return the list of signals associated with a given clock.

    Inputs
    -------
    infiles: List of Verilog source files to pass to Yosys
    module: Name of module to run command on
    clk: Name of clock to find associated signals
    """
    return do_select(infiles, module, "select -list %s %%x* i:* o:* %%u %%i a:ASSOC_CLOCK=%s %%u %s %%d" % (clk, clk, clk))
