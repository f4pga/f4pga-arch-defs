## LUT tests

This directory contains test for the `v2x_to_model.py` and `v2x_to_pb_type` tools.
Those tests should check the following features:

## Blackbox detection

 - [ ] model of the leaf pb\_type is generated
 - [ ] leaf pb\_type xml is generated
 - [ ] all dependency models and pb\_types are included in the output files

## Carry chain inference

 - [ ] pack\_pattern inference - pack\_patterns defined on wires with `pack` attributes should be propagated to pb\_type xmls

## Timings

 - [ ] timings defined for wires with `DELAY_MATRIX` attribute should be propagated to pb\_type xml
