# Lattice / SiliconBlue iCE40 FPGAs

 * [`devices`](devices) - iCE40 FPGA devices. The devices architecture
   descriptions have approximations of the real fabric, to get real fabric you
   have to override the `rr_graph.xml` file.

   * [`devices/layouts`](devices/layouts) - Tile layout descriptions for devices.

   * [`devices/tile-routing-virt`](devices/tile-routing-virt) - Version of
     architecture which uses;
      * Local tracks inside a tile.
      * Fake fabric which "approximates" the real fabric inside the iCE40.

   * [`devices/top-routing-virt`](devices/top-routing-virt) - Version of
     architecture which uses;
      * Local tracks at rr_graph level.
      * Fake fabric which "approximates" the real fabric inside the iCE40.

 * [`primitives/`](primitives) - The primitives that make up the iCE40. These
   are generally used inside the tiles.

 * [`tiles/`](tiles) - The tiles found in the iCE40 architecture. The iCE40
   only really have 3 tile types,
    - [`tiles/plb`](tiles/plb) - Logic tiles, called `PLB`s
    - [`tiles/pio`](tiles/pio) - IO tiles, called `PIO`s
    - [`tiles/block_ram`](tiles/block_ram) - Block Ram tiles, which don't
      really have a name.
