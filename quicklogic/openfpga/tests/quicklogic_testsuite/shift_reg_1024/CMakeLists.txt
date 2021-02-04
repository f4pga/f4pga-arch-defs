add_file_target(FILE shift_reg_1024.v SCANNER_TYPE verilog)

add_fpga_target(
  NAME shift_reg_1024-ql-openfpga-k4_N8-no-adder
  BOARD ql-openfpga-k4_N8_board
  SOURCES shift_reg_1024.v
  EXPLICIT_ADD_FILE_TARGET
  )

add_fpga_target(
  NAME shift_reg_1024-ql-openfpga-k4_N8-adder
  BOARD ql-openfpga-k4_N8_board
  SOURCES shift_reg_1024.v
  EXPLICIT_ADD_FILE_TARGET
  DEFINES SYNTH_OPTS=-adder
  )

add_dependencies(all_openfpga_k4_N8_tests_no_adder shift_reg_1024-ql-openfpga-k4_N8-no-adder_route)
add_dependencies(all_openfpga_k4_N8_tests_adder    shift_reg_1024-ql-openfpga-k4_N8-adder_route)
