add_fpga_target(
  NAME blink
  BOARD icestick
  SOURCES
    example.v
  TESTBENCH_SOURCES
    example_tb.v
  INPUT_IO_FILE icestick.pcf
)
