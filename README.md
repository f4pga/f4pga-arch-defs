# WARNING!

This repo is currently a **work in progress** nothing is currently yet working!

---

# SymbiFlow Architecture Definitions

This repo contains executable documentation of various FPGA architectures. The
aim is to include useful documentation (both human and machine readable) on the
primitives and routing infrastructure for real FPGA architectures.

We hope this enables growth in the open source FPGA tools space.

The architectures under development are currently;
 * Lattice iCE40
 * Artix 7

The repo includes;

 * Human readable documentation generated
   [with Sphinx](https://sphinx-doc.org).

 * Verilog models of the real hardware found in these FPGA architectures
   including both behaviour and timing.

 * Simulations and test benches for checking the correctness of these models
   and programmatically explaining their behaviour. (Think along the lines of
   [Python doctests](https://docs.python.org/3/library/doctest.html).)

 * Verilog "marco libraries" to provide compatibility with designs created for
   usage with vendor tools.

 * [Verilog To Routing Architecture Definitions](https://docs.verilogtorouting.org/en/latest/arch/)
   to enable [place and route of designs](https://en.wikipedia.org/wiki/Place_and_route).

# Structure

## Directories

 * `<arch name>` - Everything unique to a particular architecture. Current architectures are;

   * [`artix7`](artix7) - Xilinx Artix 7
   * [`ice40`](ice40) - Lattice iCE40
   * [`testarch`](testarch) - Demonstration architecture for testing features.

 * `<arch name>/devices/` - Top level description for an actual device.

   * `<arch name>/devices/<device name>-virt` - Frequently for testing we want
     something close to an actual device that isn't the real thing.

 * `<arch name>/primitives/` - The primitives that make up the architecture. What
   exactly is a "primitive" is a bit fuzzy, use your best judgment.

 * `<arch name>/tiles/` - The tiles found in the architecture.

 * [`tests/`](tests/) - Tests for making sure architectures works with VPR.

 * [`utils/`](utils/) - Python utilities for working with and generating
   different features.

   * [`mux_gen.py`](utils/mux_gen.py) - Utility for generating muxes found
     inside most FPGA architectures.

 * [`vpr`](vpr) - Common defines used by multiple architectures.

## Files

 * `XXX.pb_type.xml` - The Verilog to Routing
    [Complex Block](https://docs.verilogtorouting.org/en/latest/arch/reference/#complex-blocks)
    defintinition.
      * Inside `primitives` directory they should be intermediate or primitive
	`<pb_type>` and thus allow setting the `num_pb` attribute.

      * Inside `tiles` directory they should be top level `<pb_type>` and thus have,
         - `capacity` (if a pin type),
	 - `width` & `height` (and maybe `area`)

 * `XXX.model.xml` - The Verilog to Routing
    [Recognized BLIF Models](https://docs.verilogtorouting.org/en/latest/arch/reference/#recognized-blif-models-models)
    defintinition.

 * `XXX.sim.v` - A Verilog definition of the object. It should;
    - [ ] Match the definition in `model.xml` (should be one `module` in
          `sim.v` for every `model` in `model.xml`)

    - [ ] Include a `ifndef BLACKBOX` section which actually defines how the
          Verilog works.

## Names

Names are of the form `XXX_YY-aaaaaa` where;
 * `XXX` is the high level type of the block. It should be one of;
    - `BLK`, for composite blocks,
    - `BEL`, for primitives which can not be decomposed, or
    - `PAD`, for special input/output blocks.

 * `YY` is the subtype of the block. It is dependent on the high level block
   type.

 * `aaaaa` is the name of the block. The name should generally match both the
   file and directory that the files are found in.

 * `BLK_MB-block_1_name-block_2_name` - `BLOCK` which is a "**m**ega **b**lock". A "mega block" is a top level block which is made up of other blocks.
 * `BLK_XX-name`       - `BLOCK` which is the hierarchy. Maps to `BLK_SI` -> `SITE` and `BLK_TI` -> `TILE` in Xilinx terminology.
 * `BLK_IG-name`       - `BLOCK` which is ignored. They don't appear in the output hierarchy and are normally used when something is needed in the description which doesn't match actual architecture.
 * `BEL_RX-mux_name`   - `BEL` which is a **r**outing mu**x**. Routing muxes are statically configured at PnR time.
 * `BEL_MX-mux_name`   - `BEL` which is a **m**u**x** .
 * `BEL_LT-lut_name`   - `BEL` which is a **l**ook up **t**able.
 * `BEL_MM-mem_name`   - `BEL` which is a **m**e**m**ory.
 * `BEL_FF-ff_name`    - `BEL` which is a **f**lip **f**lop (`FF`).
 * `BEL_LL-latch_name` - `BEL` which is a **l**atch (`LL`).
 * `BEL_BB-name`       - `BEL` which is a **b**lack **b**ox (`BB`).
 * `PAD_IN-name`       - A signal input location.
 * `PAD_OT-name`       - A signal output location.

## Notes

 * Unless there is a good reason otherwise, all muxes should be generated via
   [`mux_gen.py`](utils/mux_gen.py)

 * DRY (Don't repeat yourself) - Uses
   [XML XIncludes](https://en.wikipedia.org/wiki/XInclude) to reuse stuff!

# Getting Started

Make sure git submodules are cloned:

```
git submodule init
git submodule update
```

Run the full suite:

```
# doesn't work yet
# export ARCH=artix7
export ARCH=testarch
make env
make .git/info/exclude
make redir
make

```
Test the rr_graph library:
```
export PATH=$PWD/env/conda/bin/:$PATH
export PYTHONPATH=$PWD/utils:$PYTHONPATH
python3 -m lib.rr_graph.graph
```

Parse an rr_graph.xml using rr_graph library:

```
cd tests
make wire.rr_graph.xml
stat build/testarch/2x4/wire.rr_graph.xml
# Run test suite
# Dump an rr_graph file
python3 -m lib.rr_graph.graph build/testarch/2x4/wire.rr_graph.xml
```

See some example vpr commands (while still in tests):

```
make V=1
```

## Debian

```shell
apt-get install xsltproc nodejs make inkscape graphviz coreutils
```

# Tools

## Toolchain

### [Yosys](http://www.clifford.at/yosys/)

Tool for Verilog parsing and synthesis. Used in for generation of logic
diagrams and Verilog to Routing architecture definitions from simulation files.

### [Verilog To Routing](https://verilogtorouting.org)

Place and route tool.

### Simulation

 * [Verilator](https://www.veripool.org/wiki/verilator)
 * [Icarus Verilog](http://iverilog.icarus.com/)

## Documentation

 * [Sphinx](http://www.sphinx-doc.org/en/master/) - Python Documentation Generator

 * [Breathe](http://www.sphinx-doc.org/en/master/),
   [Exhale](http://exhale.readthedocs.io/en/latest/) and
   [DoxygenVerilog](https://github.com/avelure/doxygen-verilog) extensions.

 * [Symbolator](https://kevinpt.github.io/symbolator/) (will be) used for
   generating component diagrams.

 * [Wavedrom](http://wavedrom.com/) (will be) used for timing and waveform
   diagrams.

 * [netlistsvg](https://github.com/nturley/netlistsvg),
   [Graphviz](https://www.graphviz.org/) and
   [Inkscape](https://inkscape.org/en/) are used for logic diagrams.
