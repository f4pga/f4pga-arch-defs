This repo contains documentation of various FPGA architectures, it is currently
concentrating on;

 * Lattice iCE40

The aim is to include useful documentation (both human and machine readable) on
the primitives and routing infrastructure for these architectures. We hope this
enables growth in the open source FPGA tools space.

The repo includes;

 * Black box part definitions
 * Verilog simulations
 * Verilog To Routing architecture definitions
 * Documentation for humans

The documentation can be generated using sphinx.

# Structure

## Directories

 * [`arch/`](arch) - Full architecture definitions for
   [Verilog To Routing](https://verilogtorouting.org/)

   * [`arch/XXXX-virt'](arch/ice40-virt) - Verilog to Routing architecture
     definition isn't able to generate /exactly/ model of many FPGA routing
     interconnects, but this is a pretty close.

 * [`primitives/`](primitives) - The primitives that make up the iCE40. These
   are generally used inside the tiles.

 * [`tiles/`](tiles) - The tiles found in the iCE40 architecture.

 * [`tests/`](tests) - Tests for making sure the architecture works with vpr.

## Files

 * `pb_type.xml` - The Verilog to Routing
    [Complex Block](https://docs.verilogtorouting.org/en/latest/arch/reference/#complex-blocks)
    defintinition.
      * Inside `primitives` directory they should be intermediate or primitive
	`<pb_type>` and thus allow setting the `num_pb` attribute.

      * Inside `tiles` directory they should be top level `<pb_type>` and thus have,
         - `capacity` (if a pin type),
	 - `width` & `height` (and maybe `area`)

 * `model.xml` - The Verilog to Routing
    [Recognized BLIF Models](https://docs.verilogtorouting.org/en/latest/arch/reference/#recognized-blif-models-models)
    defintinition.

 * `sim.v` - A Verilog definition of the object. It should;
    - [ ] Match the definition in `model.xml` (should be one `module` in
          `sim.v` for every `model` in `model.xml`)

    - [ ] Include a `ifndef BLACKBOX` section which actually defines how the
          Verilog works.

 * `macro.v` - A Verilog definition of the object which a user might
   instantiate in their own code when specifying a primitive. This should match
   the definition provided by a manufacturer. Examples would be the definitions
   in;
    - [Lattice iCE Technology Library](http://www.latticesemi.com/~/media/LatticeSemi/Documents/TechnicalBriefs/SBTICETechnologyLibrary201504.pdf)
    - [UG953: Vivado Design Suite 7 Series FPGA and Zynq-7000 All Programmable SoC Libraries Guide](https://www.xilinx.com/support/documentation/sw_manuals/xilinx2017_3/ug953-vivado-7series-libraries.pdf)

## Notes

 * Unless there is a good reason otherwise, all muxes should be generated via
   [`mux_gen.py`](utils/mux_gen.py)

 * DRY (Don't repeat yourself) - Uses
   [XML XIncludes](https://en.wikipedia.org/wiki/XInclude) to reuse stuff!

