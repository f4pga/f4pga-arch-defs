include(v2x_tests.cmake)

add_subdirectory(clocks)
add_subdirectory(fig41-full-adder)
add_subdirectory(fig42-dff)
add_subdirectory(common)
add_subdirectory(dsp_combinational)
# FIXME: Output is incorrectly marked as being clocked.
#add_subdirectory(dsp_in_registered)
# FIXME: utils/vlog/tests/dsp_inout_registered/dsp_inout_registered.arch.merged.xml:-1
# <pb_type> 'dff' timing-annotation/<model> mismatch on port 'd' of model
# 'dff', port is a sequential input but has neither T_setup nor T_hold
# specified
#add_subdirectory(dsp_inout_registered)
#add_subdirectory(dsp_inout_registered_dualclk)
# FIXME: Input is incorrectly marked as being clocked.
#add_subdirectory(dsp_out_registered)
# FIXME: Input `m` and output is incorrectly marked as being clocked.
#add_subdirectory(dsp_partial_registered)
#add_subdirectory(dsp_modes)
add_subdirectory(simple_pll)
add_subdirectory(multiple_instance)
add_subdirectory(fasm_features)
add_subdirectory(fasm_features_lut)
add_subdirectory(fasm_features_child)
add_subdirectory(fasm_features_modes)
add_subdirectory(fasm_features_ic_direct)
add_subdirectory(sanity_checks)
