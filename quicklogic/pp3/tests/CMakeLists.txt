add_custom_target(all_ql_tests_bit_v)
add_custom_target(all_ql_tests_bit)
add_custom_target(all_ql_tests_prog)

add_dependencies(all_ql_tests_prog all_ql_tests_bit)

add_custom_target(all_ql_tests)
add_dependencies(all_quicklogic_tests all_ql_tests)
add_dependencies(all_ql_tests all_ql_tests_bit)
add_dependencies(all_ql_tests all_ql_tests_bit_v)

add_custom_target(all_quick_tests)

# Tests for packing and placing primitives. Not to be run on actual HW !
add_subdirectory(wire)
add_subdirectory(lut)
add_subdirectory(consts)

# Test designs controlled by buttons
add_subdirectory(btn_counter)

# Test designs that use clock
add_subdirectory(counter)

add_subdirectory(assp)
add_subdirectory(features)

