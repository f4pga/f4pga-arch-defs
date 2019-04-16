include(v2x_tests.cmake)

add_subdirectory(dsp_combinational)
add_subdirectory(dsp_inout_registered)
#add_subdirectory(dsp_inout_registered_dualclk)
#add_subdirectory(dsp_in_registered)
#add_subdirectory(dsp_modes)
#add_subdirectory(dsp_out_registered)
#add_subdirectory(dsp_partial_registered)
add_subdirectory(fig41-full-adder)
add_subdirectory(simple_pll)

# Currently creates an extra 'combinational_sink_ports="q"' property on clock port
#add_subdirectory(fig42-dff)
