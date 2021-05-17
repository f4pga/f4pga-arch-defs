add_file_target(FILE clock_tree_design.v SCANNER_TYPE verilog)
add_file_target(FILE clock_tree_design.pcf)

add_fpga_target(
  NAME clock_tree_design-umc22-no-adder
  TOP clock_tree_design
  BOARD qlf_k4n8-qlf_k4n8_umc22_board
  SOURCES clock_tree_design.v
  INPUT_IO_FILE clock_tree_design.pcf
  EXPLICIT_ADD_FILE_TARGET
  DEFINES SYNTH_OPTS=-no_adder
  )

add_fpga_target(
  NAME clock_tree_design-umc22-adder
  TOP clock_tree_design
  BOARD qlf_k4n8-qlf_k4n8_umc22_board
  SOURCES clock_tree_design.v
  INPUT_IO_FILE clock_tree_design.pcf
  EXPLICIT_ADD_FILE_TARGET
  )

add_dependencies(all_qlf_k4n8_tests_no_adder clock_tree_design-umc22-no-adder_bit)
add_dependencies(all_qlf_k4n8_tests_adder    clock_tree_design-umc22-adder_bit)
