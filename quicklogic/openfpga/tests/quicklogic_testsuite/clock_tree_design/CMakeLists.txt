add_file_target(FILE clock_tree_design.v SCANNER_TYPE verilog)

add_fpga_target(
  NAME clock_tree_design-ql-openfpga-k4_N8-no-adder
  BOARD ql-openfpga-k4_N8_board
  SOURCES clock_tree_design.v
  EXPLICIT_ADD_FILE_TARGET
  )

add_fpga_target(
  NAME clock_tree_design-ql-openfpga-k4_N8-adder
  BOARD ql-openfpga-k4_N8_board
  SOURCES clock_tree_design.v
  EXPLICIT_ADD_FILE_TARGET
  DEFINES SYNTH_OPTS=-adder
  )

add_dependencies(all_openfpga_k4_N8_tests_no_adder clock_tree_design-ql-openfpga-k4_N8-no-adder_route)
add_dependencies(all_openfpga_k4_N8_tests_adder    clock_tree_design-ql-openfpga-k4_N8-adder_route)
