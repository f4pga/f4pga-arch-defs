#!/usr/bin/env python3
"""
This is intended to provide a range of helper functions around the output of 
Yosys' `write_json`. Depending on the tasks, this may need to be flattened
and/or in AIG format. In any case, at minimum `proc` and usually `prep` should
be used before outputting the JSON.
"""

import os, sys
import json

class YosysModule:
    def __init__(self, name, module_data):
        self.name = name
        self.data = module_data
    
    # Return the name of the module
    def get_name(self):
        return self.name
    
    # Return a list of ports of a module (default: top), as a 3-tuple (name, width, dir)
    def get_ports(self):
        plist = []
        for port, pdata in self.data["ports"].items():
            plist.append((port, len(pdata["bits"]), pdata["direction"]))
        return plist        

    # Return a list of cells of a module, as a 2-tuple (name, type)
    def get_cells(self, include_internal = False):
        clist = []
        for cell, cdata in self.data["cells"].items():
            if cell.startswith("$") and not include_internal:
                continue
            clist.append((cell, cdata["type"]))
        return clist
    # Return the attributes of a module as a dictionary
    def get_module_attrs(self):
        return self.data["attributes"]
    
    # Return the value of an attribute, or the default value if not set
    def get_attr(self, attr, defval = None):
        if attr in self.get_module_attrs():
            return self.get_module_attrs()[attr]
        else:
            return defval
            
    # Return the attributes of a cell instance as a dictionary
    def get_cell_attrs(self, cell):
        return self.data["cells"][cell]["attributes"]

    # Return the value of an attribute of a cell, or the default value if not set
    def get_cell_attr(self, cell, attr, defval = None):
        if attr in self.get_cell_attrs(cell):
            return self.get_cell_attrs(cell)[attr]
        else:
            return defval        
            
    # TODO: the below code is kind of ugly, but because module and cell IO
    # specifications are inconsistent in how they are represented in the JSON,
    # it's hard to make any nicer...
    
    # Return cell connections in a given direction as a 2-tuple (cell pin name, module net number)
    def get_cell_conns(self, cell, direction = "input"):
        cdata = self.data["cells"][cell]
        conns = []
        for port, condata in cdata["connections"].items():
            if cdata["port_directions"][port] == direction:
                N = len(condata)
                if N == 1:
                    conns.append((port, condata[0]))
                else:
                    for i in range(N):
                        conns.append(("%s[%d]" % (port, N), condata[i]))
        return conns
    
    # Returns any top level IO matching a direction and connected net number
    # Result is a list containing entries of the form A or A[15] for single bit 
    # or bus ports respectively
    def get_conn_io(self, net, iodir):
        conn_io = []
        for port, pdata in self.data["ports"].items():
            if pdata["direction"] == iodir:
                if net in pdata["bits"]:
                    if len(pdata["bits"]) == 1:
                        conn_io.append(port)
                    else:
                        conn_io.append("%s[%d]" % (port, pdata["bits"].index(net)))
        return conn_io
    
    # Returns any cell ports matching a direction and connected net number
    # Result is a list of tuples (cell, port)
    def get_conn_ports(self, net, pdir, include_internal = False):
        conn_ports = []
        for cell in self.data["cells"]:
            if cell.startswith("$") and not include_internal:
                continue
            cdata = self.data["cells"][cell]
            for port, condata in cdata["connections"].items():
                if cdata["port_directions"][port] == pdir:
                    if net in condata:
                        if len(condata) == 1:
                            conn_ports.append((cell, port))
                        else:
                            conn_ports.append((cell, "%s[%d]" % (port, condata.index(net))))
        return conn_ports
    
    # Return a list of drivers of a net (usually should only be one...) as a 2-tuple
    # (cell, port). cell is set to the name of the module for top level IOs
    def get_net_drivers(self, net):
        # top level *inputs* and cell outputs are both drivers
        io_drivers = [(self.name, _) for _ in self.get_conn_io(net, "input")]
        cell_drivers = self.get_conn_ports(net, "output")
        return io_drivers + cell_drivers
    
    # Return a list of sinks of a net, as a 2-tuple as above
    def get_net_sinks(self, net):
        # top level *outputs* and cell inputs are both drivers
        io_drivers = [(self.name, _) for _ in self.get_conn_io(net, "output")]
        cell_drivers = self.get_conn_ports(net, "input")
        return io_drivers + cell_drivers
class YosysJson:
    # Takes either a filename, or already parsed JSON as a dictionary
    # Also optionally pass the top level module
    def __init__(self, j, top = None):
        if(isinstance(j, str)):
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
    
    def get_top(self):
        if self.top is None:
            print("no top module selected")
            assert(False)
        return self.top
    
    def get_module(self, module):
        return YosysModule(module, self.data["modules"][module])
        
    def get_top_module(self):
        return self.get_module(self.get_top())

    # Return true if a module exists
    def has_module(self, module):
        return module in self.data["modules"]
    
