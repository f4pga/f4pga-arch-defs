add_file_target(FILE lut4_8ffs.v SCANNER_TYPE verilog)

add_fpga_target(
  NAME lut4_8ffs-ql-openfpga-k4_N8-no-adder
  BOARD ql-openfpga-k4_N8_board
  SOURCES lut4_8ffs.v
  EXPLICIT_ADD_FILE_TARGET
  )

add_fpga_target(
  NAME lut4_8ffs-ql-openfpga-k4_N8-adder
  BOARD ql-openfpga-k4_N8_board
  SOURCES lut4_8ffs.v
  EXPLICIT_ADD_FILE_TARGET
  DEFINES SYNTH_OPTS=-adder
  )

add_dependencies(all_openfpga_k4_N8_tests_no_adder lut4_8ffs-ql-openfpga-k4_N8-no-adder_route)
add_dependencies(all_openfpga_k4_N8_tests_adder    lut4_8ffs-ql-openfpga-k4_N8-adder_route)
