add_file_target(FILE basys3_top.v SCANNER_TYPE verilog)
add_file_target(FILE srl32_chain_tb.v SCANNER_TYPE verilog)

add_fpga_target(
  NAME srl32_chain
  BOARD basys3
  INPUT_IO_FILE ${COMMON}/basys3.pcf
  SOURCES basys3_top.v ${SRL_COMMON}/srl32_chain_seg.v ${SRL_COMMON}/srl_shift_tester.v ${SRL_COMMON}/rom.v
  TESTBENCH_SOURCES srl32_chain_tb.v
  EXPLICIT_ADD_FILE_TARGET
  )

add_vivado_target(
  NAME srl32_chain_vivado
  PARENT_NAME srl32_chain
  CLOCK_PINS clk
  CLOCK_PERIODS 10.0
  # TODO: https://github.com/SymbiFlow/f4pga-arch-defs/issues/1019
  DISABLE_DIFF_TEST
  )

add_dependencies(all_xc7_tests
  testbench_srl32_chain_tb
  testbench_synth_srl32_chain_tb
  testbinch_srl32_chain_tb
)
