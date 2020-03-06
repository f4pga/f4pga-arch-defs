add_custom_target(all_ql_tests)

# A test for LUT -> LOGIC cell techmaps
add_subdirectory(techmaps)

# Tests for packing and placing primitives. Not to be run on actual HW !
add_subdirectory(wire)
add_subdirectory(lut)
add_subdirectory(consts)

# Test designs controlled by buttons
add_subdirectory(btn_xor)
add_subdirectory(btn_ff)
add_subdirectory(btn_counter)

# Test designs that use clock
add_subdirectory(counter)
add_subdirectory(soc_clocks)

# More complex tests/examples that use the SoC interface.
add_subdirectory(soc_litex_pwm)
