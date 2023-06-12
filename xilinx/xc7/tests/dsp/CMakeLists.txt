add_file_target(FILE dsp.xdc)
add_file_target(FILE top.v SCANNER_TYPE verilog)
add_fpga_target(
  NAME dsp
  BOARD arty-full
  SOURCES top.v
  INPUT_XDC_FILES dsp.xdc
  EXPLICIT_ADD_FILE_TARGET
)
