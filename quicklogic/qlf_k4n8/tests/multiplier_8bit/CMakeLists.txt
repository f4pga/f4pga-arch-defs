add_file_target(FILE multiplier_8bit.v SCANNER_TYPE verilog)
add_file_target(FILE multiplier_8bit.pcf)

add_fpga_target(
  NAME multiplier_8bit-umc22-no-adder
  TOP multiplier_8bit
  BOARD qlf_k4n8-qlf_k4n8_umc22_board
  SOURCES  multiplier_8bit.v
  INPUT_IO_FILE multiplier_8bit.pcf
  EXPLICIT_ADD_FILE_TARGET
  DEFINES SYNTH_OPTS=-no_adder
  )

add_fpga_target(
  NAME multiplier_8bit-umc22-adder
  TOP multiplier_8bit
  BOARD qlf_k4n8-qlf_k4n8_umc22_board
  SOURCES  multiplier_8bit.v
  INPUT_IO_FILE multiplier_8bit.pcf
  EXPLICIT_ADD_FILE_TARGET
  )

add_dependencies(all_qlf_k4n8_tests_no_adder multiplier_8bit-umc22-no-adder_bit)
add_dependencies(all_qlf_k4n8_tests_adder    multiplier_8bit-umc22-adder_bit)
