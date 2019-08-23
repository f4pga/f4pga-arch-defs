add_file_target(FILE basys3_top.v SCANNER_TYPE verilog)
add_file_target(FILE srl16_shift_tb.v SCANNER_TYPE verilog)

add_fpga_target(
  NAME srl16_shift
  BOARD basys3
  INPUT_IO_FILE ../../common/basys3.pcf
  SOURCES basys3_top.v ../common/srl_shift_tester.v ../common/rom.v
  TESTBENCH_SOURCES srl16_shift_tb.v
  EXPLICIT_ADD_FILE_TARGET
  )

add_vivado_target(
  NAME srl16_shift_vivado
  PARENT_NAME srl16_shift
  CLOCK_PINS clk
  CLOCK_PERIODS 10.0
  )

add_dependencies(all_xc7_tests
  testbench_srl16_shift_tb
  testbench_synth_srl16_shift_tb
  #testbinch_srl16_shift_tb
)
