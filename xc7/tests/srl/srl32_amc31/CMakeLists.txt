add_file_target(FILE basys3_top.v SCANNER_TYPE verilog)
add_file_target(FILE tb.v SCANNER_TYPE verilog)

add_fpga_target(
  NAME srl32_amc31
  BOARD basys3
  INPUT_IO_FILE ../../common/basys3.pcf
  SOURCES basys3_top.v ../common/srl_shift_tester.v ../common/rom.v
  TESTBENCH_SOURCES tb.v
  EXPLICIT_ADD_FILE_TARGET
  )
