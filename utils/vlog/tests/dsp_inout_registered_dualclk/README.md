## dsp\_inout\_registered\_dualclk tests

This directory contains test for the `v2x_to_model.py` and `v2x_to_pb_type` tools.
The tests use model from fig42-dff and dps\_combinational tests.
Those tests should check the following features:


## Detection of combinational connections

 - [ ] output has combinational connection with input
 - [ ] pack\_pattern defined on wire connections with `pack` attribute

## Blackbox detection

 - [ ] model of the leaf pb\_type is generated
 - [ ] leaf pb\_type xml is generated
 - [ ] all dependecy models and pb\_types are included in the output files

