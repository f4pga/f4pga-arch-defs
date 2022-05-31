
#add Alinx AX7050 constraint file
add_file_target(FILE dsp_ax7050.xdc)
#add support for Alinx AX7050 board
add_file_target(FILE dsp_ax7050.v SCANNER_TYPE verilog)
add_fpga_target(
  NAME dsp_ax7050
  BOARD ax7050
  SOURCES dsp_ax7050.v
  INPUT_XDC_FILES dsp_ax7050.xdc
  EXPLICIT_ADD_FILE_TARGET
)
