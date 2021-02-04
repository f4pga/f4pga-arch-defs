add_file_target(FILE counter.v SCANNER_TYPE verilog)
#add_file_target(FILE ql745a.pcf)

add_fpga_target(
  NAME counter-ql-openfpga-k4_N4
  BOARD ql-openfpga-k4_N4_board
  SOURCES counter.v
#  INPUT_IO_FILE ql745a.pcf
  EXPLICIT_ADD_FILE_TARGET
  )

add_fpga_target(
  NAME counter-ql-openfpga-k4_N8
  BOARD ql-openfpga-k4_N8_board
  SOURCES counter.v
#  INPUT_IO_FILE ql745a.pcf
  EXPLICIT_ADD_FILE_TARGET
)

