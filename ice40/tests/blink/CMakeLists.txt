set(BOARDS iceblink40-lp1k icestick)

if (NOT DEFINED ENV{CI} OR NOT $ENV{CI})
set(BOARDS ${BOARDS} hx8k-b-evn icevision tinyfpga-b2 tinyfpga-bx)
endif (NOT DEFINED ENV{CI} OR NOT $ENV{CI})

add_fpga_target_boards(
  NAME blink
  BOARDS ${BOARDS}
  SOURCES
    example.v
  TESTBENCH_SOURCES
    example_tb.v
  IMPLICIT_INPUT_IO_FILES
)
