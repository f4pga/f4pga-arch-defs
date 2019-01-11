# WARNING!

This repo is currently a **work in progress** nothing is currently yet working!

---

# SymbiFlow Architecture Definitions

[![Build Status](https://travis-ci.org/SymbiFlow/symbiflow-arch-defs.svg?branch=master)](https://travis-ci.org/SymbiFlow/symbiflow-arch-defs)

This repo contains documentation of various FPGA architectures, it is currently
concentrating on;

 * Lattice iCE40
 * Artix 7

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

Run the full suite:

```
make
```

# Tools

 * [`third_party/netlistsvg`](https://github.com/nturley/netlistsvg/)

 * [`third_party/icestorm`](https://github.com/cliffordwolf/icestorm/)

 * [`third_party/prjxray-db`](https://github.com/SymbiFlow/prjxray-db/)

## Tools used via conda

 * [yosys](https://github.com/YosysHQ/yosys)
   Verilog parsing and synthesis.

 * [vtr](https://github.com/SymbiFlow/vtr-verilog-to-routing)
   Place and route tool.

 * [iverilog](https://github.com/steveicarus/iverilog)
   Very correct FOSS Verilog Simulator

## Tools to use in the future
 * [verilator](https://www.veripool.org/wiki/verilator)
   Fast FOSS Verilog Simulator

 * sphinx
   Tool for generating nice looking documentation.

 * breathe
   Tool for allowing Doxygen and Sphinx integration.

 * doxygen-verilog
   Allows using Doxygen style comments inside Verilog files.

 * netlistsvg
   Tool for generating nice logic diagrams from Verilog code.

 * symbolator
   Tool for generating symbol diagrams from Verilog (and VHDL) code.

 * wavedrom
   Tool for generating waveform / timing diagrams.

