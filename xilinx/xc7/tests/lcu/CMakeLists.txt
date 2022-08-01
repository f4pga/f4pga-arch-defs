add_file_target(FILE lcu.v SCANNER_TYPE verilog)
add_file_target(FILE lcu_tb.v SCANNER_TYPE verilog)
add_file_target(FILE arty.pcf)
add_fpga_target(
  NAME lcu_arty
  BOARD arty-full
  SOURCES lcu.v
  INPUT_IO_FILE arty.pcf
  TESTBENCH_SOURCES lcu_tb.v
  EXPLICIT_ADD_FILE_TARGET
)

add_vivado_target(
  NAME lcu_arty_vivado
  PARENT_NAME lcu_arty
)

add_dependencies(all_xc7_tests
  testbench_lcu_tb
  testbench_synth_lcu_tb
  testbinch_lcu_tb
)
