add_file_target(FILE gtp_channel.v SCANNER_TYPE verilog)
add_file_target(FILE basys3.xdc)
add_file_target(FILE nexys_video.xdc)

add_fpga_target(
  NAME gtp_channel_basys3
  BOARD basys3-full
  INPUT_XDC_FILE basys3.xdc
  SOURCES gtp_channel.v
  EXPLICIT_ADD_FILE_TARGET
)

add_fpga_target(
  NAME gtp_channel_nexys_video
  BOARD nexys_video
  INPUT_XDC_FILE nexys_video.xdc
  SOURCES gtp_channel.v
  EXPLICIT_ADD_FILE_TARGET
)
