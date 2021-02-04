add_file_target(FILE adder_64.v SCANNER_TYPE verilog)
add_file_target(FILE 32x32.pcf)

add_fpga_target(
  NAME adder_64-ql-openfpga-k4_N8-no-adder
  BOARD ql-openfpga-k4_N8_board
  SOURCES adder_64.v
#  INPUT_IO_FILE 32x32.pcf
  EXPLICIT_ADD_FILE_TARGET
  )

add_fpga_target(
  NAME adder_64-ql-openfpga-k4_N8-adder
  BOARD ql-openfpga-k4_N8_board
  SOURCES adder_64.v
#  INPUT_IO_FILE 32x32.pcf
  EXPLICIT_ADD_FILE_TARGET
  DEFINES SYNTH_OPTS=-adder
  )

add_dependencies(all_openfpga_k4_N8_tests_no_adder adder_64-ql-openfpga-k4_N8-no-adder_pack)
add_dependencies(all_openfpga_k4_N8_tests_adder    adder_64-ql-openfpga-k4_N8-adder_pack)
