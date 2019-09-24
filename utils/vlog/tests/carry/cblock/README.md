## CARRY tests

This directory contains test for the `v2x_to_model.py` and `v2x_to_pb_type` tools.
Those tests should check the following features:

## Blackbox detection

 - [ ] model of the leaf pb\_type is generated
 - [ ] leaf pb\_type xml is generated
 - [ ] all dependency models and pb\_types are included in the output files

## Combinational connections

 - [ ] automatic inference of combinational connections between input and output ports

## Carry chain inference

 - [ ] carry chains inference - carry chains defined on wires with `carry` attribute should be propagated to pb\_type xml file

## Timings

 - [ ] all the timings defined in Verilog should be propagated to result pb\_type file
