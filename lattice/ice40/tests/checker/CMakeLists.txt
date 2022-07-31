add_fpga_target_boards(
  NAME checker
  BOARDS icestick
  SOURCES
    checker.v
  TESTBENCH_SOURCES
    checker_tb.v
  IMPLICIT_INPUT_IO_FILES
)
