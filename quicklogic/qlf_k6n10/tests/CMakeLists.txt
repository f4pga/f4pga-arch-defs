set(QL_DESIGNS_DIR ../../../../../quicklogic/designs)

add_custom_target(all_qlf_k6n10_tests_no_adder)
add_custom_target(all_qlf_k6n10_tests_adder)

add_subdirectory(design_flow)
add_subdirectory(features)

add_dependencies(all_quicklogic_tests all_qlf_k6n10_tests_no_adder)
add_dependencies(all_quicklogic_tests all_qlf_k6n10_tests_adder)
