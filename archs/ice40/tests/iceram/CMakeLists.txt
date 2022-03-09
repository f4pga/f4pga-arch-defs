set(BOARDS iceblink40-lp1k icestick)

if (NOT LIGHT_BUILD)
list(APPEND BOARDS hx8k-b-evn tinyfpga-bx)
endif (NOT LIGHT_BUILD)

add_fpga_target_boards(
  NAME iceram
  BOARDS ${BOARDS}
  SOURCES
    iceram.v
  TESTBENCH_SOURCES
    iceram_tb.v
  IMPLICIT_INPUT_IO_FILES
)
