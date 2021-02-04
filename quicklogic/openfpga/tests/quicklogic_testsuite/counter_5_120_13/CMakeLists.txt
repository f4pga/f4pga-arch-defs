add_file_target(FILE counter_5_120_13.v SCANNER_TYPE verilog)

add_fpga_target(
  NAME counter_5_120_13-ql-openfpga-k4_N8-no-adder
  BOARD ql-openfpga-k4_N8_board
  SOURCES counter_5_120_13.v
  EXPLICIT_ADD_FILE_TARGET
  )

add_fpga_target(
  NAME counter_5_120_13-ql-openfpga-k4_N8-adder
  BOARD ql-openfpga-k4_N8_board
  SOURCES counter_5_120_13.v
  EXPLICIT_ADD_FILE_TARGET
  DEFINES SYNTH_OPTS=-adder
  )

add_dependencies(all_openfpga_k4_N8_tests_no_adder counter_5_120_13-ql-openfpga-k4_N8-no-adder_route)
add_dependencies(all_openfpga_k4_N8_tests_adder    counter_5_120_13-ql-openfpga-k4_N8-adder_route)
