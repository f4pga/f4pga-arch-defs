add_fpga_target_boards(
  NAME iceram
  BOARDS hx8k-b-evn iceblink40-lp1k icestick tinyfpga-bx
  SOURCES
    iceram.v
  TESTBENCH_SOURCES
    iceram_tb.v
  IMPLICIT_INPUT_IO_FILES
)
