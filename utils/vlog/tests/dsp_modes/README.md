## dsp\_modes tests

This directory contains test for the `v2x_to_model.py` and `v2x_to_pb_type` tools.
The tests use models from other DSP test.
Those tests should check the following features:

## Blackbox detection

 - [ ] model of the leaf pb\_type is generated
 - [ ] leaf pb\_type xml is generated
 - [ ] all dependency models and pb\_types are included in the output files

## Modes generation

 - [ ] all the modes from list defined with `MODES` attribute
 - [ ] mode setting is included in pb\_type generation (correct part of logic is used)
 - [ ] modes connections are generated correctly
