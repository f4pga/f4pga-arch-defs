set(CLK_TREE ${QL_DESIGNS_DIR}/clock_tree_design/clock_tree_design.v)
add_file_target(FILE clock_tree_design.pcf)

add_fpga_target(
  NAME clock_tree_design_test2-umc22-adder
  TOP clock_tree_design
  BOARD qlf_k4n8-qlf_k4n8_umc22_slow_board
  INPUT_IO_FILE clock_tree_design.pcf
  SOURCES ${CLK_TREE}
  EXPLICIT_ADD_FILE_TARGET
  )

add_dependencies(all_qlf_k4n8_tests_adder   clock_tree_design_test2-umc22-adder_bit)
