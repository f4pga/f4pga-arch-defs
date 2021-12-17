# EOS-S3 test targets
add_custom_target(all_eos_s3_tests)

add_custom_target(all_eos_s3_tests_regression)
add_custom_target(all_eos_s3_tests_bit)
add_custom_target(all_eos_s3_tests_bit_v)
add_custom_target(all_eos_s3_tests_prog)

add_dependencies(all_eos_s3_tests all_eos_s3_tests_regression)
add_dependencies(all_eos_s3_tests all_eos_s3_tests_bit)
add_dependencies(all_eos_s3_tests all_eos_s3_tests_bit_v)
add_dependencies(all_eos_s3_tests all_eos_s3_tests_prog)

# PP3E test targets
add_custom_target(all_pp3e_tests)

add_custom_target(all_pp3e_tests_bit)

add_dependencies(all_pp3e_tests all_pp3e_tests_bit)

# Bind to the all QuickLogic tests target
add_dependencies(all_quicklogic_tests all_eos_s3_tests)
add_dependencies(all_quicklogic_tests all_pp3e_tests)

# =============================================================================

# Tests for packing and placing primitives. Not to be run on actual HW !
add_subdirectory(wire)
add_subdirectory(lut)
add_subdirectory(consts)

# Test designs controlled by buttons
add_subdirectory(btn_xor)
add_subdirectory(btn_ff)
add_subdirectory(btn_counter)
add_subdirectory(sdiomux_xor)

# Test designs that use clock
add_subdirectory(counter)
# Tests that require an external clock/data
add_subdirectory(ext_counter)
add_subdirectory(ext_mult)

# Test design using RAM
add_subdirectory(bram)

# QuickLogic test suite
add_subdirectory(design_flow)
# Feature / regression tests
add_subdirectory(features)
