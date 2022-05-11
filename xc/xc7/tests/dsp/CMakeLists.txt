
#add Alinx AX7050 constraint file
add_file_target(FILE dsp2.xdc)
#add support for Alinx AX7050 board
add_file_target(FILE dsp2.v SCANNER_TYPE verilog)
add_fpga_target(
  NAME dsp2_ax7050
  BOARD ax7050
  SOURCES dsp2.v
  INPUT_XDC_FILES dsp2.xdc
  EXPLICIT_ADD_FILE_TARGET
)
