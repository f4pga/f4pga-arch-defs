add_file_target(FILE spiflash.v SCANNER_TYPE verilog)

add_file_target(FILE picosoc.v SCANNER_TYPE verilog)
add_file_target(FILE picorv32.v SCANNER_TYPE verilog)
add_file_target(FILE simpleuart.v SCANNER_TYPE verilog)
add_file_target(FILE spimemio.v SCANNER_TYPE verilog)

add_file_target(FILE hx8kdemo.v SCANNER_TYPE verilog)
add_file_target(FILE hx8kdemo_tb.v SCANNER_TYPE verilog)
add_file_target(FILE hx8k-b-evn.pcf)

add_file_target(FILE basys3_demo.v SCANNER_TYPE verilog)
add_file_target(FILE basys3_demo_tb.v SCANNER_TYPE verilog)
add_file_target(FILE basys3.pcf)

if (NOT DEFINED ENV{CI} OR NOT $ENV{CI})
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
  EXPLICIT_ADD_FILE_TARGET
)

add_fpga_target(
  NAME picosoc_basys3
  BOARD basys3
  TOP basys3_demo
  SOURCES
    basys3_demo.v
    picosoc.v
    picorv32.v
    simpleuart.v
    spimemio.v
  TESTBENCH_SOURCES basys3_demo_tb.v
  INPUT_IO_FILE basys3.pcf
  EXPLICIT_ADD_FILE_TARGET
)
endif (NOT DEFINED ENV{CI} OR NOT $ENV{CI})
