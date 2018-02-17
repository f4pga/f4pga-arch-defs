#!/usr/bin/python3

import json
import os, sys

"""
This is intended to provide a range of helper functions around the output of 
Yosys' `write_json`. Depending on the tasks, this may need to be flattened
and/or in AIG format. In any case, at minimum `proc` and usually `prep` should
be used before outputting the JSON.
"""

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
    
    # Return a list of ports of a module (default: top), as a 3-tuple (name, width, dir)
    def get_ports(self, module = None):
        if module is None:
            if self.top is None:
                print("no top module selected, can't get_ports")
                assert(False)
            module = self.top
        plist = []
        for port, pdata in self.data["modules"][module]["ports"].items():
            plist.append((port, len(pdata["bits"]), pdata["direction"]))
        return plist
    
    # Return a list of cells of a module, as a 2-tuple (name, type)
    def get_cells(self, module = None, include_hidden = True):
        if module is None:
            if self.top is None:
                print("no top module selected, can't get_cells")
                assert(False)
            module = self.top
        clist = []
        for cell, cdata in self.data["modules"][module]["cells"].items():
            if include_hidden or not cdata["hide_name"]:
                clist.append((cell, cdata["type"]))
