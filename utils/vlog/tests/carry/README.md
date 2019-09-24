## CARRY tests

This directory contains test for the `v2x_to_model.py` and `v2x_to_pb_type` tools.
The tests use model defined in CBLOCK tests.
Those tests should check the following features:

## Blackbox detection

 - [ ] model of the leaf pb\_type is generated
 - [ ] leaf pb\_type xml is generated
 - [ ] all dependency models and pb\_types are included in the output files

## Carry chain inference

 - [ ] automatic inference of carry chains - carry chains defined on ports of included blocks should be propagated to top level module
