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

The documentation can be generated using Sphinx.

# Structure

## Directories

 * `XXX/arch/` - Full architecture definitions for
   [Verilog To Routing](https://verilogtorouting.org/)

   * `XXX/arch/YYYY-virt` - Verilog to Routing architecture definitions
     generally are not able to able to generate the **exact** model of many
     FPGA routing interconnects, but this is a pretty close.

 * `XXX/arch/primitives/` - The primitives that make up the iCE40. These
   are generally used inside the tiles.

 * `XXX/tiles/` - The tiles found in the architecture.

 * `XXX/tests/` - Tests for making sure the architecture specific features
   works with VPR.

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

# Tools

 * [`third_party/yosys/`](third_party/yosys/)
   Verilog parsing and synthesis.

 * [`third_party/vtr/`](third_party/vtr/)
   Place and route tool.

 * [`third_party/xmllint`](third_party/xmllint)
   Tool for parsing, formatting XML. Used to process the XML files before
   giving them to VPR.

 * [`third_party/sim/iverilog/`](third_party/sim/iverilog/)
   Very correct FOSS Verilog Simulator

 * [`third_party/sim/verilator/`](third_party/sim/verilator/)
   Fast FOSS Verilog Simulator

 * [`third_party/docgen/sphinx/`](third_party/docgen/sphinx/)
   Tool for generating nice looking documentation.

 * [`third_party/docgen/breathe/`](third_party/docgen/breathe)
   Tool for allowing Doxygen and Sphinx integration.

 * [`third_party/docgen/doxygen-verilog`](third_party/docgen/doxygen-verilog)
   Allows using Doxygen style comments inside Verilog files.

 * [`third_party/docgen/netlistsvg/`](third_party/docgen/netlistsvg)
   Tool for generating nice logic diagrams from Verilog code.

 * [`third_party/docgen/symbolator/`](third_party/docgen/symbolator)
   Tool for generating symbol diagrams from Verilog (and VHDL) code.

 * [`third_party/docgen/wavedrom/`](third_party/docgen/wavedrom/)
   Tool for generating waveform / timing diagrams.

