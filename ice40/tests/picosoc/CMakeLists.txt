add_file_target(FILE spiflash.v SCANNER_TYPE verilog)

add_fpga_target(
  NAME picosoc
  BOARD hx8k-b-evn
  TOP hx8kdemo
  SOURCES
    hx8kdemo.v
    picosoc.v
    picorv32.v
    simpleuart.v
    spimemio.v
  TESTBENCH_SOURCES hx8kdemo_tb.v
  INPUT_IO_FILE hx8k-b-evn.pcf
)
