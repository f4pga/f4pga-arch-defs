#!/usr/bin/env python3

""" Tool for generating artix7 architectures used in a partial reconfiguration designs

Tool generates an architecture JSON for a chosen ROI - it is
assumed that ROI covers whole clock domain.

artix7_partial_arch_gen.py <args>
"""
import json
import argparse
from collections import namedtuple


# type from ROI side (in/out/clk)
Signal = namedtuple('Signal', 'name width type')

### Bus Layouts

wishbone_layout = [
    Signal('wb_adr',   30, 'in'),
    Signal('wb_dat_w', 32, 'in'),
    Signal('wb_dat_r', 32, 'out'),
    Signal('wb_sel',   4,  'in'),
    Signal('wb_cyc',   1,  'in'),
    Signal('wb_stb',   1,  'in'),
    Signal('wb_ack',   1,  'out'),
    Signal('wb_we',    1,  'in'),
    Signal('wb_cti',   3,  'in'),
    Signal('wb_bte',   2,  'in'),
    Signal('wb_err',   1,  'out')
]

artix7_domains = {
    # Predefined Artix7 domains
    "X0Y2": {
        "x_min": 10,
        "x_max": 58,
        "y_min": 1,
        "y_max": 51,
        "int_x_ins_range": [24, 25],
        "int_x_outs_range": [22, 23],
        "int_y_range": [100, 149],
        "clk":   {"node": "CLK_HROW_TOP_R_X60Y130/CLK_HROW_CK_BUFHCLK_L0",
                  "wire": "HCLK_L_X53Y130/HCLK_CK_BUFHCLK0"}
    },
    "X0Y1": {
        "x_min": 10,
        "x_max": 58,
        "y_min": 53,
        "y_max": 103,
        "int_x_ins_range": [24, 25],
        "int_x_outs_range": [22, 23],
        "int_y_range": [50, 99],
        "clk":   {"node": "CLK_HROW_TOP_R_X60Y78/CLK_HROW_CK_BUFHCLK_L0",
                  "wire": "HCLK_L_X53Y78/HCLK_CK_BUFHCLK0"}
    },
    "X0Y0": {
        "x_min": 10,
        "x_max": 58,
        "y_min": 105,
        "y_max": 155,
        "int_x_ins_range": [24, 25],
        "int_x_outs_range": [22, 23],
        "int_y_range": [0, 49],
        "clk":   {"node": "CLK_HROW_TOP_R_X60Y26/CLK_HROW_CK_BUFHCLK_L0",
                  "wire": "HCLK_L_X53Y26/HCLK_CK_BUFHCLK0"}
    },
    "X1Y2": {
        "x_min": 62,
        "x_max": 91,
        "y_min": 1,
        "y_max": 51,
        "int_x_ins_range": [22, 23],
        "int_x_outs_range": [24, 25],
        "int_y_range": [100, 149],
        "clk":   {"node": "CLK_HROW_TOP_R_X60Y130/CLK_HROW_CK_BUFHCLK_L0",
                  "wire": "HCLK_R_X69Y130/HCLK_CK_BUFHCLK0"}
    },
    "X1Y1": {
        "x_min": 62,
        "x_max": 104,
        "y_min": 53,
        "y_max": 103,
        "int_x_ins_range": [22, 23],
        "int_x_outs_range": [24, 25],
        "clk":   {"node": "CLK_HROW_TOP_R_X60Y78/CLK_HROW_CK_BUFHCLK_L0",
                  "wire": "HCLK_R_X69Y78/HCLK_CK_BUFHCLK0"}
    },
    "X2Y0": {
        "x_min": 62,
        "x_max": 104,
        "y_min": 105,
        "y_max": 155,
        "int_x_ins_range": [22, 23],
        "int_x_outs_range": [24, 25],
        "clk":   {"node": "CLK_HROW_TOP_R_X60Y26/CLK_HROW_CK_BUFHCLK_L0",
                  "wire": "HCLK_R_X69Y26/HCLK_CK_BUFHCLK0"}
    }
}

class ROIConfig():
    def __init__(self, domain, name="pr", pips=1):
        assert domain in ['X0Y0', 'X0Y1', 'X0Y2', 'X1Y0', 'X1Y1', 'X1Y2']

        self.domain = artix7_domains[domain]
        self.name = name
        self.pips = pips

        self.iter = -1 if 'X0' in domain else 1

        # Pick proper nodes for inputs and outputs.
        # It is assumed that ROI output node must route a signal outside
        # the ROI and for an input a signal must be routed to the insides
        # of the ROI.
        self.roi_outs_node = 'EE4BEG' if 'X0' in domain else 'WW4BEG'
        self.roi_ins_node = 'WW4BEG' if 'X0' in domain else 'EE4BEG'

        self.roi_signals = []
        self.arch = {}

    def add_clk(self):
        clk = Signal('prm_clk', 1, 'clk')
        self.roi_signals.append(clk)

    def add_rst(self):
        rst = Signal('prm_rst', 1, 'in')
        self.roi_signals.append(rst)

    def add_bus(self, bus):
        for sig in bus:
            self.roi_signals.append(sig)

    def add_roi_inputs(self, inputs):
        assert len(inputs) % 2 == 0
        sig_num = int(len(inputs) / 2)
        # Pack list into Signal
        for i in range(sig_num):
            self.roi_signals.append(Signal(inputs[i], int(inputs[i + 1]), 'in'))

    def add_roi_outputs(self, outputs):
        assert len(outputs) % 2 == 0
        sig_num = int(len(outputs) / 2)
        # Pack list into Signal
        for i in range(sig_num):
            self.roi_signals.append(Signal(outputs[i], int(outputs[i + 1]), 'out'))

    def generate_architecture(self):
        # Prepare architecture info
        self.arch["info"] = {
            "name": self.name,
            "GRID_X_MAX": self.domain["x_max"],
            "GRID_X_MIN": self.domain["x_min"],
            "GRID_Y_MAX": self.domain["y_max"],
            "GRID_Y_MIN": self.domain["y_min"]
        }

        # Prepare architecture ports
        self.arch["ports"] = []
        global_syn_index = 0
        ins_x_index = self.domain["int_x_ins_range"][0]
        outs_x_index = self.domain["int_x_outs_range"][0]
        y_min = ins_y_index = outs_y_index = self.domain["int_y_range"][0]
        y_max = self.domain["int_y_range"][1]
        in_pip = 0
        out_pip = 0
        for sig in self.roi_signals:
            for i in range(sig.width):
                port = {}
                if sig.type == "clk":
                    port = {
                        "name": sig.name,
                        "type": sig.type,
                        "node": self.domain["clk"]["node"],
                        "wire": self.domain["clk"]["wire"],
                        "pin": "SYN{}".format(global_syn_index)
                    }
                elif sig.type == "in":
                    interconnect = "INT_R" if ins_x_index % 2 else "INT_L"
                    coord = "X{}Y{}".format(ins_x_index, ins_y_index)
                    node_pip = self.roi_ins_node + str(in_pip)
                    node = "{}_{}/{}".format(interconnect, coord, node_pip)
                    sig_name = sig.name if sig.name == "prm_rst" else sig.name + str(i)
                    port = {
                        "name": sig_name,
                        "type": sig.type,
                        "node": node,
                        "pin": "SYN{}".format(global_syn_index)
                    }
                    in_pip += 1
                else:
                    interconnect = "INT_R" if outs_x_index % 2 else "INT_L"
                    coord = "X{}Y{}".format(outs_x_index, outs_y_index)
                    node_pip = self.roi_outs_node + str(out_pip)
                    node = "{}_{}/{}".format(interconnect, coord, node_pip)
                    sig_name = sig.name + str(i)
                    port = {
                        "name": sig_name,
                        "type": sig.type,
                        "node": node,
                        "pin": "SYN{}".format(global_syn_index)
                    }
                    out_pip += 1

                if in_pip > (self.pips - 1):
                    in_pip = 0
                    ins_y_index += 1
                if out_pip > (self.pips - 1):
                    out_pip = 0
                    outs_y_index += 1
                if ins_y_index > y_max:
                    ins_y_index = y_min
                    ins_x_index += -self.iter
                if outs_y_index > y_max:
                    outs_y_index = y_min
                    outs_x_index += self.iter
                if ins_x_index not in self.domain["int_x_ins_range"]:
                    raise Exception("Too much ROI input signals!" \
                                    " Not enough interconnect tiles.")
                if outs_x_index not in self.domain["int_x_outs_range"]:
                    raise Exception("Too much ROI output signals!" \
                                     " Not enough interconnect tiles.")
                global_syn_index += 1
                self.arch["ports"].append(port)

        return self.arch


def main():
    parser = argparse.ArgumentParser(description="Artix7 partial architecture generator")
    parser.add_argument("--arch-name",   default="pr",          help="Architecture name")
    parser.add_argument("--arch-type",   required=True,         help="Architecture type: roi / overlay")
    parser.add_argument("--domain",      required=True,         help="Domain used for ROI (X0Y0, X0Y1, X0Y2, X1Y0, X1Y1, X1Y2)")
    parser.add_argument("--no-bus",      action="store_true",   help="Generate architecture without bus")
    parser.add_argument("--no-clk",      action="store_true",   help="Generate architecture without clk")
    parser.add_argument("--no-rst",      action="store_true",   help="Generate architecture without rst")
    parser.add_argument("--inputs",      nargs="+", default=[], help="List of ROI inputs in a form: <name0> <width0> <name1> <width1> ...")
    parser.add_argument("--outputs",     nargs="+", default=[], help="List of ROI outputs in a form: <name0> <width0> <name1> <width1> ...")
    parser.add_argument("--pips",        type=int, default=1,   help="Pips used per tile (1, 4)")
    parser.add_argument("--dump-file",   default="design.json", help="JSON file name (default: design.json)")
    parser.add_argument("--dump-stdout", action="store_true",   help="Dumps generated JSON to stdout")

    args = parser.parse_args()

    roi_config = ROIConfig(args.domain, args.arch_name, args.pips)

    if not args.no_clk:
        roi_config.add_clk()

    if not args.no_rst:
        roi_config.add_rst()

    if not args.no_bus:
        roi_config.add_bus(wishbone_layout)

    roi_config.add_roi_inputs(args.inputs)
    roi_config.add_roi_outputs(args.outputs)

    roi_config.generate_architecture()

    with open(args.dump_file, "w") as f:
        if args.arch_type == "roi":
            json.dump(roi_config.arch, f, indent=4)
        else:
            json.dump([roi_config.arch], f, indent=4)

    if args.dump_stdout:
        print(roi_config.arch)

if __name__ == "__main__":
    main()
