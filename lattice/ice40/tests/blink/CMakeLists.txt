set(BOARDS iceblink40-lp1k icestick)

if (NOT LIGHT_BUILD)
list(APPEND BOARDS hx8k-b-evn icevision tinyfpga-b2 tinyfpga-bx)
endif (NOT LIGHT_BUILD)

add_fpga_target_boards(
  NAME blink
  BOARDS ${BOARDS}
  SOURCES
    example.v
  TESTBENCH_SOURCES
    example_tb.v
  IMPLICIT_INPUT_IO_FILES
)
