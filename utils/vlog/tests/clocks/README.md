## Clock detection tests

This directory contains test for the clock detection functionality for the
`v2x_to_model.py` tool.


## Detection of clock signals

 - [ ] Signal is named `clk`.
 - [ ] Signal has `clk` in the name.
 - [ ] Manually set via the `(* CLOCK *)` Verilog attribute.
 - [ ] Signal drives synchronous logic (IE flipflop).
 - [ ] Detection in recursive module includes.

## Detection of clock association

 - [ ] Clock comes from synchronous logic
 - [ ] Manually associated via `(* ASSOC_CLOCK="<clock signal"> *)` Verilog
       attribute.
 - [ ] Detection in recursive module includes.

