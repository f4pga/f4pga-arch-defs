add_custom_target(all_ql_tests)
add_custom_target(all_quick_tests)

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
add_subdirectory(sdiomux_xor)

# Tests that require an external clock/data
add_subdirectory(ext_counter)
add_subdirectory(ext_mult)

# Global clock network tests
add_subdirectory(gclk_counter)

# Test designs that use clock
add_subdirectory(counter)
add_subdirectory(soc_clocks)
add_subdirectory(sdiomux_counter)

# More complex tests/examples that use the SoC interface.
add_subdirectory(soc_litex_pwm)

# QuickLogic test suite
add_subdirectory(quicklogic_testsuite)

# Hardblocks tests
add_subdirectory(ram)
add_subdirectory(bram_init)
add_subdirectory(mult)
