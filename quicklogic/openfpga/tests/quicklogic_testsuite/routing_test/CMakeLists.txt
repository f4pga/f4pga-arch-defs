add_file_target(FILE routing_test.v SCANNER_TYPE verilog)


add_fpga_target(
  NAME routing_test-ql-openfpga-k4_N8-no-adder
  BOARD ql-openfpga-k4_N8_board
  SOURCES routing_test.v
  EXPLICIT_ADD_FILE_TARGET
  )

add_fpga_target(
  NAME routing_test-ql-openfpga-k4_N8-adder
  BOARD ql-openfpga-k4_N8_board
  SOURCES routing_test.v
  EXPLICIT_ADD_FILE_TARGET
  DEFINES SYNTH_OPTS=-adder
  )

add_dependencies(all_openfpga_k4_N8_tests_no_adder routing_test-ql-openfpga-k4_N8-no-adder_route)
add_dependencies(all_openfpga_k4_N8_tests_adder    routing_test-ql-openfpga-k4_N8-adder_route)
