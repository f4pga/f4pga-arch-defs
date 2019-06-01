# SymbiFlow Architecture Definitions

[![Build Status](https://travis-ci.org/SymbiFlow/symbiflow-arch-defs.svg?branch=master)](https://travis-ci.org/SymbiFlow/symbiflow-arch-defs)

This repo contains documentation of various FPGA architectures, it is currently
concentrating on;

 * [Lattice iCE40](ice40)
 * [Xilinx Series 7 (Artix 7 and Zynq 7)](xc7)

The aim is to include useful documentation (both human and machine readable) on
the primitives and routing infrastructure for these architectures. We hope this
enables growth in the open source FPGA tools space.

The repo includes;

 * Black box part definitions
 * Verilog simulations
 * Verilog To Routing architecture definitions
 * Documentation for humans

The documentation can be generated using Sphinx.

# Getting Started

Make sure git submodules are cloned:

```
git submodule init
git submodule update
```

Install Python libraries:

```
# Make sure additional libraries are installed
sudo apt-get install libxml2-dev libxslt1-dev lib32z1-dev
pip install -r requirements.txt
```

Run the full suite:

```
make
```

# Tools installed via submodules

 * [`third_party/netlistsvg`](https://github.com/nturley/netlistsvg/)
   Tool for generating nice logic diagrams from Verilog code.

 * [`third_party/icestorm`](https://github.com/cliffordwolf/icestorm/)
   Bitstream and timing database + tools for the Lattice iCE40.

 * [`third_party/prjxray`](https://github.com/SymbiFlow/prjxray/)
   Tools for the Xilinx Series 7 parts.

 * [`third_party/prjxray-db`](https://github.com/SymbiFlow/prjxray-db/)
   Bitstream and timing database for the Xilinx Series 7 parts.

## Tools installed via conda

 * [yosys](https://github.com/YosysHQ/yosys)
   Verilog parsing and synthesis.

 * [vtr](https://github.com/SymbiFlow/vtr-verilog-to-routing)
   Place and route tool.

 * [iverilog](https://github.com/steveicarus/iverilog)
   Very correct FOSS Verilog Simulator

## Tools potentially used in the future

 * [verilator](https://www.veripool.org/wiki/verilator)
   Fast FOSS Verilog Simulator

 * [sphinx](http://www.sphinx-doc.org/en/master/)
   Tool for generating nice looking documentation.

 * [breathe](https://breathe.readthedocs.io/en/latest/)
   Tool for allowing Doxygen and Sphinx integration.

 * doxygen-verilog
   Allows using Doxygen style comments inside Verilog files.

 * [symbolator](https://kevinpt.github.io/symbolator/)
   Tool for generating symbol diagrams from Verilog (and VHDL) code.

 * [wavedrom](https://wavedrom.com/)
   Tool for generating waveform / timing diagrams.

## Resource Requirements

To run examples provided, please make sure these resources are available:
 * Memory: 5.5G
 * Disk space: 20G

