add_file_target(FILE and2.v SCANNER_TYPE verilog)

add_fpga_target(
  NAME and2-ql-openfpga-k4_N8-no-adder
  BOARD ql-openfpga-k4_N8_board
  SOURCES and2.v
  EXPLICIT_ADD_FILE_TARGET
  )

add_fpga_target(
  NAME and2-ql-openfpga-k4_N8-adder
  BOARD ql-openfpga-k4_N8_board
  SOURCES and2.v
  EXPLICIT_ADD_FILE_TARGET
  DEFINES SYNTH_OPTS=-adder
  )

add_dependencies(all_openfpga_k4_N8_tests_no_adder and2-ql-openfpga-k4_N8-no-adder_route)
add_dependencies(all_openfpga_k4_N8_tests_adder    and2-ql-openfpga-k4_N8-adder_route)
