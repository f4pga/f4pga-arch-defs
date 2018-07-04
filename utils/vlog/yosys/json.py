#!/usr/bin/env python3
"""
This is intended to provide a range of helper functions around the output of
Yosys' `write_json`. Depending on the tasks, this may need to be flattened
and/or in AIG format. In any case, at minimum `proc` and usually `prep` should
be used before outputting the JSON.
"""

import os, sys
import json
import pprint


class YosysModule:
    def __init__(self, name, module_data):
        self.name = name
        self.data = module_data

    def __str__(self):
        return "YosysModule({},\n{})".format(
            self.name, pprint.pformat(self.data))

    @property
    def ports(self):
        """List of ports on a module.

        Returns a list of tuples:
        -------
        name : str
        width : int
            The width in bits
        dir : str
            The direction, should be either `input` or `output`
        """
        plist = []
        for port, pdata in sorted(self.data["ports"].items()):
            plist.append((port, len(pdata["bits"]), pdata["direction"]))
        return plist

    @property
    def cells(self):
        """List of cells of a module, excluding Yosys-internal cells
        beginning with $.

        Returns a list of tuples:
        -------
        name : str
        type: str
        """
        clist = []
        for cell, cdata in sorted(self.data["cells"].items()):
            if cell.startswith("$"):
                continue
            clist.append((cell, cdata["type"]))
        return clist

    @property
    def nets(self):
        """List the net ids avaliable in the design."""
        return list(sorted(set(n['bits'][0] for n in self.data["netnames"].values())))

    def cell_type(self, cell):
        """Return the type of a given cell"""
        for cname, cdata in self.data["cells"].items():
            if cname == cell:
                return cdata["type"]
        return None

    @property
    def module_attrs(self):
        """All attributes of a module as a dictionary"""
        return self.data["attributes"]

    def attr(self, attr, defval=None):
        """Get an attribute, or defval is not set"""
        if attr in self.module_attrs:
            return self.module_attrs[attr]
        else:
            return defval

    def __getattr__(self, attr):
        return self.attr(attr)

    def has_attr(self, attr):
        """Return true if an attribute exists"""
        return attr in self.module_attrs

    def cell_attrs(self, cell):
        """All attributes of a given cell as a dictionary"""
        return self.data["cells"][cell]["attributes"]

    def cell_attr(self, cell, attr, defval=None):
        """Get an attribute of a given cell, or defval is not set"""
        if attr in self.cell_attrs(cell):
            return self.cell_attrs(cell)[attr]
        else:
            return defval

    def net_attrs(self, netname):
        """Get all attributes of a given net as a dictionary"""
        return self.data["netnames"][netname]["attributes"]

    def net_attr(self, netname, attr, defval=None):
        """Get an attribute of a given net (specified by name), or defval is not set"""
        pnet = None
        if attr in self.net_attrs(netname):
            return self.net_attrs(netname)[attr]
        else:
            return defval

    # TODO: the below code is kind of ugly, but because module and cell IO
    # specifications are inconsistent in how they are represented in the JSON,
    # it's hard to make any nicer...

    def cell_conns(self, cell, direction="input"):
        """The connections of a cell in a given direction as a 2-tuple

        Returns a list of tuples:
        -------
        port : str
        net : int
        """
        cdata = self.data["cells"][cell]
        conns = []
        for port, condata in sorted(cdata["connections"].items()):
            if cdata["port_directions"][port] == direction:
                N = len(condata)
                if N == 1:
                    conns.append((port, condata[0]))
                else:
                    for i in range(N):
                        conns.append(("{}[{}]".format(port, i), condata[i]))
        return conns

    def conn_io(self, net, iodir):
        """Returns a list of top level IO matching a direction and connected net number

        Returns a list:
        -------
        port : str
        """
        conn_io = []
        for port, pdata in sorted(self.data["ports"].items()):
            if pdata["direction"] == iodir:
                if net in pdata["bits"]:
                    if len(pdata["bits"]) == 1:
                        conn_io.append(port)
                    else:
                        conn_io.append("{}[{}]".format(
                            port, pdata["bits"].index(net)))
        return conn_io

    def conn_ports(self, net, pdir):
        """Returns any cell ports matching a direction and connected net number

        Returns a list of tuples:
        -------
        cell : str
        port : str
        """
        conn_ports = []
        for cell in sorted(self.data["cells"].keys()):
            if cell.startswith("$"):
                continue
            cdata = self.data["cells"][cell]
            for port, condata in sorted(cdata["connections"].items()):
                if cdata["port_directions"][port] == pdir:
                    if net in condata:
                        if len(condata) == 1:
                            conn_ports.append((cell, port))
                        else:
                            conn_ports.append((cell, "{}[{}]".format(
                                port, condata.index(net))))
        return conn_ports

    def net_drivers(self, net):
        """Returns a list of drivers of a given net, both top level inputs.
        and cell outputs. "cell" is set to the name of the module for top level
        IO.

        Returns a list of tuples:
        -------
        cell : str
        port : str
        """
        # top level *inputs* and cell outputs are both drivers
        io_drivers = [(self.name, _) for _ in self.conn_io(net, "input")]
        cell_drivers = self.conn_ports(net, "output")
        return io_drivers + cell_drivers

    def net_sinks(self, net):
        """Returns a list of sinks of a given net, both top level outputs.
        and cell inputs. "cell" is set to the name of the module for top level
        IO.

        Returns a list of tuples:
        -------
        cell : str
        port : str
        """
        # top level *outputs* and cell inputs are both drivers
        io_drivers = [(self.name, _) for _ in self.conn_io(net, "output")]
        cell_drivers = self.conn_ports(net, "input")
        return io_drivers + cell_drivers


class YosysJSON:
    def __init__(self, j, top=None):
        """Takes either the filename to a JSON file, or already parsed JSON
        data as a dictionary. Optionally the top level module can be specified
        too."""
        if (isinstance(j, str)):
            with open(j, 'r') as f:
                self.data = json.load(f)
        else:
            self.data = j
        if top is None:
            if len(self.data["modules"]) == 1:
                self.top = list(self.data["modules"].keys())[0]
            else:
                self.top = None
        else:
            self.top = top

    def module(self, module):
        """Get a given module (by name) as a `YosysModule`"""
        if module not in self.data["modules"]:
            raise KeyError("No yosys module named {} (only have {})".format(
                module, self.data["modules"].keys()))
        return YosysModule(module, self.data["modules"][module])

    def modules_with_attr(self, attr_name, attr_value):
        """Return a list of `YosysModule`s, selecting based on a given attribute"""
        mods = []
        for mod in self.data["modules"]:
            ymod = self.module(mod)
            if ymod.has_attr(attr_name) and ymod.attr(attr_name) == attr_value:
                mods.append(ymod)
        return mods

    def all_modules(self):
        """Return a list of the names of all modules in the design, sorted alphabetically"""
        return sorted(self.data["modules"].keys())

    @property
    def top_module(self):
        """Get a given module (by name) as a `YosysModule`"""
        return self.module(self.top)

    def has_module(self, module):
        """Return true if a module exists"""
        return module in self.data["modules"]

    def get_module_file(self, module):
        """Return the filename in which a given module lives"""
        src = self.module(module).attr("src")
        cpos = src.rfind(":")
        return src[0:cpos]

