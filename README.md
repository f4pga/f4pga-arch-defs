# SymbiFlow Architecture Definitions

[![Build Status](https://travis-ci.org/SymbiFlow/symbiflow-arch-defs.svg?branch=master)](https://travis-ci.org/SymbiFlow/symbiflow-arch-defs)

This repo contains documentation of various FPGA architectures, it is currently
concentrating on;

 * [Lattice iCE40](ice40)
 * [Xilinx Series 7 (Artix 7 and Zynq 7)](xc/xc7)

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

To initialize submodule and setup the CMake build system, from the root of the
`symbiflow-arch-defs` directory run:

```
make env
```

At this point a new directory `build` will have been created, which is where
you can invoke make to build various targets.

To initialize the conda environment that contains all the tools and libraries,
from the root of the `symbiflow-arch-defs` directory run:

```
make all_conda
```

To build all demo bitstreams there are 3 useful targets

```
# Build all demo bitstreams, targetting all architectures
make all_demos

# Build all 7-series demo bitstreams
make all_xc7

# Build all ice40 demo bitstreams
make all_ice40
```

Specific bitstreams can be built by specifying their target name, followed by
a suffix specifying the desired output. For example, the LUT-RAM test for the
RAM64X1D primative is called `dram_test_64x1d`.  Example targets are:


```
# Just run synthesis on the input Verilog
make dram_test_64x1d_eblif

# Complete synthesis and place and route the circuit
make dram_test_64x1d_route

# Create the output bitstream (including synthesis and place and route)
make dram_test_64x1d_bin

# Run bitstream back into Vivado for timing checks, etc.
make dram_test_64x1d_vivado
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

## Development notes

Because symbiflow-arch-defs relies on yosys and VPR, it may be useful to
override the default packaged binaries with locally supplied binaries.  The
build system allows this via environment variables matching the executable name.
Here is a list of common environment variables to defined when doing local yosys
and VPR development.

 - YOSYS : Path to yosys executable to use.
 - VPR : Path to VPR executable to use.
 - GENFASM : Path genfasm executable to use.

There are more binaries that are packaged (e.g. VVP), but the packaged versions
are typically good enough for most use cases.

After setting or clearing one of these environment variables, CMake needs to be
re-run.
