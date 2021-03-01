add_file_target(FILE gtp_channel.v SCANNER_TYPE verilog)

add_fpga_target(
  NAME gtp_channel_basys3
  BOARD basys3-full
  INPUT_IO_FILE ${COMMON}/basys3_gtp_channel.pcf
  SOURCES gtp_channel.v
  EXPLICIT_ADD_FILE_TARGET
  )

add_fpga_target(
  NAME gtp_channel_nexys_video
  BOARD nexys_video
  INPUT_IO_FILE ${COMMON}/nexys_video_gtp_channel.pcf
  SOURCES gtp_channel.v
  EXPLICIT_ADD_FILE_TARGET
  )
