## PAIR tests

This directory contains test for the `v2x_to_model.py` and `v2x_to_pb_type` tools.
The tests use models defined in ff, lut and omux tests.
Those tests should check the following features:

## Blackbox detection

 - [ ] model of the leaf pb\_type is generated
 - [ ] leaf pb\_type xml is generated
 - [ ] all dependency models and pb\_types are included in the output files

## Carry chain inference

 - [ ] pack\_pattern inference - pack\_patterns defined on wires with `pack` attributes should be propagated to pb\_type xmls
