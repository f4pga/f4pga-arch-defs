# Tools

## Installed via submodules

 * [`third_party/netlistsvg`](https://github.com/nturley/netlistsvg/)
   Tool for generating nice logic diagrams from Verilog code.

 * [`third_party/icestorm`](https://github.com/cliffordwolf/icestorm/)
   Bitstream and timing database + tools for the Lattice iCE40.

 * [`third_party/prjxray`](https://github.com/f4pga/prjxray/)
   Tools for the Xilinx Series 7 parts.

 * [`third_party/prjxray-db`](https://github.com/f4pga/prjxray-db/)
   Bitstream and timing database for the Xilinx Series 7 parts.

## Installed via conda

 * [yosys](https://github.com/YosysHQ/yosys)
   Verilog parsing and synthesis.

 * [vtr](https://github.com/verilog-to-routing/vtr-verilog-to-routing)
   Place and route tool.

 * [iverilog](https://github.com/steveicarus/iverilog)
   Very correct FOSS Verilog Simulator

## Potentially used in the future

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

# Pre-built architecture files

The Continuous Integration system builds and uploads the various architecture data files.
A set of latest architecture build artifact links is generated and uploaded to a dedicated [GCS bucket](https://storage.cloud.google.com/symbiflow-arch-defs-gha/).

# Resource Requirements

To run examples provided, please make sure these resources are available:
 * Memory: 5.5G
 * Disk space: 20G
