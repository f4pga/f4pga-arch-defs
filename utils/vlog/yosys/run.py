#!/usr/bin/env python3
import json
import os
import re
import subprocess
import tempfile
import yosys.utils


def get_verbose():
    """Return if in verbose mode."""
    verbose = 0
    for e in ["V", "VERBOSE"]:
        if e not in os.environ:
            continue
        verbose = int(os.environ[e])
        break
    return verbose > 0


def get_yosys():
    """Return how to execute Yosys: the value of $YOSYS if set, otherwise just
    `yosys`."""
    return os.getenv("YOSYS", "yosys")


def get_yosys_common_args():
    return ["-e", "wire '[^']*' is assigned in a block", "-q"]


def get_output(params):
    """Run Yosys with given command line parameters, and return stdout as a string"""

    verbose = get_verbose()

    cmd = [get_yosys()] + get_yosys_common_args() + params
    if verbose:
        print(cmd)

    p = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)

    # Get the output
    stdout, stderr = p.communicate()
    stdout = stdout.decode("utf-8")
    stderr = stderr.decode("utf-8")

    retcode = p.wait()

    msg = ""
    msg += "stdout" + "=" * 75 + "\n"
    msg += stdout + "\n"
    msg += "stderr" + "-" * 75 + "\n"
    msg += stderr + "\n"
    msg += "=" * 75 + "\n"
    msg += "Return Code: {}".format(retcode)

    if verbose:
        print(msg)

    if retcode != 0:
        emsg = ""
        emsg += "Failed to run {}".join(" ".join(cmd)) + "\n"
        emsg += msg

        raise subprocess.CalledProcessError(retcode, cmd, emsg)
    return stdout


defines = []
includes = []


def add_define(defname):
    """Add a Verilog define to the list of defines to set in Yosys"""
    defines.append(defname)


def get_defines():
    """Return a list of set Verilog defines, as a list of arguments to pass to Yosys
`read_verilog`"""
    return " ".join(["-D" + _ for _ in defines])


def add_include(path):
    """ Add a path to search when reading verilog to the list of includes set in Yosys"""
    includes.append(path)


def get_includes():
    """Return a list of include directories, as a list of arguments to pass to Yosys
`read_verilog`"""
    return " ".join(["-I" + _ for _ in includes])


def commands(commands, infiles=[]):
    """Run a given string containing Yosys commands

    Inputs
    -------
    commands : string of Yosys commands to run
    infiles : list of input files
    """
    commands = "read_verilog {} {} {}; ".format(
        get_defines(), get_includes(), " ".join(infiles)
    ) + commands
    params = ["-q", "-p", commands]
    return get_output(params)


def script(script, infiles=[]):
    """Run a Yosys script given a path to the script

    Inputs
    -------
    script : path to Yosys script to run
    infiles : list of input files
    """
    params = ["-q", "-s", script] + infiles
    return get_output(params)


def vlog_to_json(
        infiles, flatten=False, aig=False, mode=None, module_with_mode=None
):
    """
    Convert Verilog to a JSON representation using Yosys

    Inputs
    -------
    infiles : list of input files
    flatten : set to flatten output hierarchy
    aig : generate And-Inverter-Graph modules for gates
    mode : set to a value other than None to use `chparam` to set the value of the MODE parameter
    module_with_mode : the name of the module to apply `mode` to
    """
    prep_opts = "-flatten" if flatten else ""
    json_opts = "-aig" if aig else ""
    if mode is not None:
        mode_str = 'chparam -set MODE "{}" {}; '.format(mode, module_with_mode)
    else:
        mode_str = ""
    cmds = "{}prep {}; write_json {}".format(mode_str, prep_opts, json_opts)
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


def do_select(infiles, module, expr, prep=False, flatten=False):
    """
    Run a Yosys select command (given the expression and input files) on a module
    and return the result as a list of pins

    Inputs
    -------
    infiles: List of Verilog source files to pass to Yosys
    module: Name of module to run command on
    expr: Yosys selector expression for select command

    prep: Run prep command before selecting.
    flatten: Flatten module when running prep.
    """

    # TODO: All of these functions involve a fairly large number of calls to
    # Yosys. Although performance here is unlikely to be a major priority any
    # time soon, it might be worth investigating better options?

    f = ""
    if flatten:
        f = "-flatten"

    p = ""
    if prep:
        p = "prep -top {} {};".format(module, f)
    else:
        p = "proc;"

    outfile = tempfile.mktemp()
    sel_cmd = "{} cd {}; select -write {} {}".format(p, module, outfile, expr)
    commands(sel_cmd, infiles)
    pins = []
    with open(outfile, 'r') as f:
        for net in f:
            snet = net.strip()
            if (len(snet) > 0):
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
    return do_select(
        infiles, module, "{} %co* o:* %i {} %d".format(innet, innet)
    )


def list_clocks(infiles, module):
    """Return a list of clocks in the module

    Inputs
    -------
    infiles: List of Verilog source files to pass to Yosys
    module: Name of module to run command on
    """
    return do_select(
        infiles, module,
        "c:* %x:+[CLK]:+[clk]:+[clock]:+[CLOCK] a:CLOCK=1 %u c:* %d x:* %i"
    )


def get_clock_assoc_signals(infiles, module, clk):
    """Return the list of signals associated with a given clock.

    Inputs
    -------
    infiles: List of Verilog source files to pass to Yosys
    module: Name of module to run command on
    clk: Name of clock to find associated signals
    """
    return do_select(
        infiles, module,
        "select -list {} %a %co* %x i:* o:* %u %i a:ASSOC_CLOCK={} %u {} %d".
        format(clk, clk, clk)
    )


# Find things which affect the given output
# show w:*D_IN_0 %a %ci*

# Find things which are affected by the given clock.
# show w:*INPUT_CLK %a %co*

# Find things which are affect by the given signal - combinational only.
# select -list w:*INPUT_CLK %a %co* %x x:* %i


def get_related_output_for_input(infiles, module, signal):
    """.

    Inputs
    -------
    infiles: List of Verilog source files to pass to Yosys
    module: Name of module to run command on
    clk: Name of clock to find associated signals
    """
    return do_select(
        infiles, module, "select -list w:*{} %a %co* o:* %i".format(signal)
    )


def get_related_inputs_for_input(infiles, module, signal):
    """.

    Inputs
    -------
    infiles: List of Verilog source files to pass to Yosys
    module: Name of module to run command on
    clk: Name of clock to find associated signals
    """
    return [
        x for x in do_select(
            infiles, module,
            "select -list w:*{} %a %co* %x i:* %i".format(signal)
        ) if x != signal
    ]
