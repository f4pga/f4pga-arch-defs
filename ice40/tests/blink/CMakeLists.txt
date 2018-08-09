add_fpga_target_boards(
  NAME blink
  BOARDS hx8k-b-evn iceblink40-lp1k icestick icevision tinyfpga-b2 tinyfpga-bx
  SOURCES
    example.v
  TESTBENCH_SOURCES
    example_tb.v
  IMPLICIT_INPUT_IO_FILES
)
