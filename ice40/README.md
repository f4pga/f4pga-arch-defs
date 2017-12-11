# Lattice / SiliconBlue iCE40 FPGAs

 * [`arch`](arch) - iCE40 FPGA architectures, both fake and real.

   * [`arch/ice4`](arch/ice4) - A 4 x 4 tile version FPGA using iCE40 tiles.
     Useful for testing simple test cases.

   * [`arch/ice40-virt`](arch/ice40-virt) - Real iCE40 layout and tiles but
     using make up interconnects. Verilog to Routing architecture definition
     isn't able to generate /exactly/ model the iCE40 routing interconnects,
     but this is pretty close.

   * [`arch/ice40`](arch/ice40) - Real iCE40 layout and tiles and real
     interconnects generated from
     [Clifford Wolf's Project IceStorm](https://github.com/cliffordwolf/icestorm)
     information.

 * [`primitives/`](primitives) - The primitives that make up the iCE40. These
   are generally used inside the tiles.

 * [`tiles/`](tiles) - The tiles found in the iCE40 architecture. The iCE40
   only really have 3 tile types,
    - [`tiles/plb`](tiles/plb) - Logic tiles, called `PLB`s
    - [`tiles/pio`](tiles/pio) - IO tiles, called `PIO`s
    - [`tiles/block_ram`](tiles/block_ram) - Block Ram tiles, which don't
      really have a name.
