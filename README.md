# F4PGA Architecture Definitions

**This repository is used during the development of architecture support in F4PGA, if you are looking to use the**
**toolchain you should start with the [f4pga-examples repository](https://github.com/chipsalliance/f4pga-examples).**

<p align="center">
  <a title="License Status" href="https://github.com/SymbiFlow/f4pga-arch-defs/blob/master/COPYING"><img alt="License Status" src="https://img.shields.io/github/license/SymbiFlow/f4pga-arch-defs?longCache=true&style=flat-square&label=License"></a><!--
  -->
  <a title="Documentation Status" href="https://f4pga.readthedocs.io/projects/arch-defs/"><img alt="Documentation Status" src="https://img.shields.io/readthedocs/symbiflow-arch-defs/latest?longCache=true&style=flat-square&logo=ReadTheDocs&logoColor=fff&label=Docs"></a><!--
  -->
  <a title="'Automerge' workflow Status" href="https://github.com/SymbiFlow/f4pga-arch-defs/actions/workflows/Automerge.yml"><img alt="'Tests' workflow Status" src="https://img.shields.io/github/workflow/status/SymbiFlow/f4pga-arch-defs/Automerge/main?longCache=true&style=flat-square&label=Tests&logo=github%20actions&logoColor=fff"></a><!--
  -->
</p>

This repo contains documentation of various FPGA architectures, it is currently concentrating on:

* [Lattice iCE40](ice40)
* [Xilinx Series 7 (Artix 7 and Zynq 7)](xc/xc7)
* [QuickLogic](quicklogic)

The aim is to include useful documentation (both human and machine readable) on the primitives and routing
infrastructure for these architectures.
We hope this enables growth in the open source FPGA tools space.

The repo includes:

 * Black box part definitions
 * Verilog simulations
 * Verilog To Routing architecture definitions
 * Documentation for humans

The documentation can be generated using Sphinx.
