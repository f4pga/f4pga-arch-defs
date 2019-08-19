add_file_target(FILE basys3_doutmux_top.v SCANNER_TYPE verilog)
add_file_target(FILE basys3_dffmux_top.v SCANNER_TYPE verilog)

add_fpga_target(
  NAME srl32_doutmux_mc31
  BOARD basys3
  INPUT_IO_FILE ../../common/basys3.pcf
  SOURCES basys3_doutmux_top.v ../common/srl_shift_tester.v ../common/rom.v
  EXPLICIT_ADD_FILE_TARGET
  )

add_fpga_target(
  NAME srl32_dffmux_mc31
  BOARD basys3
  INPUT_IO_FILE ../../common/basys3.pcf
  SOURCES basys3_dffmux_top.v ../common/srl_shift_tester.v ../common/rom.v
  EXPLICIT_ADD_FILE_TARGET
  )

