add_file_target(FILE dsp_modes.sim.v SCANNER_TYPE verilog)
v2x_test_both(NAME dsp_modes TOP_MODULE DSP_MODES TECHMAPS ../dsp_inout_registered/dsp_inout_registered.sim.v ../dsp_in_registered/dsp_in_registered.sim.v ../dsp_out_registered/dsp_out_registered.sim.v ../dsp_partial_registered/dsp_partial_registered.sim.v)
