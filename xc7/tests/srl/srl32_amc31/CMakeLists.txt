add_file_target(FILE basys3_doutmux_top.v SCANNER_TYPE verilog)
#add_file_target(FILE basys3_dffmux_top.v SCANNER_TYPE verilog)
add_file_target(FILE srl32_doutmux_mc31_tb.v SCANNER_TYPE verilog)
#add_file_target(FILE srl32_dffmux_mc31_tb.v SCANNER_TYPE verilog)

add_fpga_target(
  NAME srl32_doutmux_mc31
  BOARD basys3
  INPUT_IO_FILE ../../common/basys3.pcf
  SOURCES basys3_doutmux_top.v ../common/srl_shift_tester.v ../common/rom.v
  TESTBENCH_SOURCES srl32_doutmux_mc31_tb.v
  EXPLICIT_ADD_FILE_TARGET
  )


# The DFFMUX.MC31 test is disabled as VPR refuses to pack both SRL and FF in
# the same slice. That could be solved via a pack pattern but that would
# require redefining COMMON_SLICE and SLICE_FF i.e. splitting them into
# SLICEM and SLICEL.


#add_fpga_target(
#  NAME srl32_dffmux_mc31
#  BOARD basys3
#  INPUT_IO_FILE ../../common/basys3.pcf
#  SOURCES basys3_dffmux_top.v ../common/srl_shift_tester.v ../common/rom.v
#  TESTBENCH_SOURCES srl32_dffmux_mc31_tb.v
#  EXPLICIT_ADD_FILE_TARGET
#  )

add_vivado_target(
  NAME srl32_doutmux_mc31_vivado
  PARENT_NAME srl32_doutmux_mc31
  CLOCK_PINS clk
  CLOCK_PERIODS 10.0
  # TODO: https://github.com/SymbiFlow/symbiflow-arch-defs/issues/1019
  DISABLE_DIFF_TEST
  )

#add_vivado_target(
#  NAME srl32_dffmux_mc31_vivado
#  PARENT_NAME srl32_dffmux_mc31
#  CLOCK_PINS clk
#  CLOCK_PERIODS 10.0
#  )

add_dependencies(all_xc7_tests
  testbench_srl32_doutmux_mc31_tb
  testbench_synth_srl32_doutmux_mc31_tb
  testbinch_srl32_doutmux_mc31_tb
#  testbench_srl32_dffmux_mc31_tb
#  testbench_synth_srl32_dffmux_mc31_tb
#  testbinch_srl32_dffmux_mc31_tb
)

