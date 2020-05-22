add_file_target(FILE buttons_arty.v SCANNER_TYPE verilog)
add_fpga_target(
  NAME buttons_arty
  BOARD arty-swbut
  SOURCES buttons_arty.v
  INPUT_IO_FILE ${COMMON}/arty_swbut.pcf
  EXPLICIT_ADD_FILE_TARGET
  )

add_fpga_target(
  NAME buttons_arty100t
  BOARD arty100t-full
  SOURCES buttons_arty.v
  INPUT_IO_FILE ${COMMON}/arty_swbut.pcf
  EXPLICIT_ADD_FILE_TARGET
  )

add_vivado_target(
  NAME buttons_arty100t_vivado
  PARENT_NAME buttons_arty100t
  )

add_file_target(FILE buttons_basys3.v SCANNER_TYPE verilog)
 add_fpga_target(
  NAME buttons_basys3
  BOARD basys3
  SOURCES buttons_basys3.v
  INPUT_IO_FILE ${COMMON}/basys3.pcf
  EXPLICIT_ADD_FILE_TARGET
  )

add_vivado_target(
  NAME buttons_basys3_vivado
  PARENT_NAME buttons_basys3
  # TODO: https://github.com/SymbiFlow/symbiflow-arch-defs/issues/1018
  DISABLE_DIFF_TEST
  )

add_file_target(FILE buttons_basys3_full.v SCANNER_TYPE verilog)

add_fpga_target(
  NAME buttons_basys3_full
  BOARD basys3-full
  SOURCES buttons_basys3_full.v
  INPUT_IO_FILE ${COMMON}/basys3.pcf
  EXPLICIT_ADD_FILE_TARGET
  )

add_vivado_target(
  NAME buttons_basys3_full_vivado
  PARENT_NAME buttons_basys3_full
  )

add_file_target(FILE buttons_zybo.v SCANNER_TYPE verilog)

add_fpga_target(
  NAME buttons_zybo
  BOARD zybo-full
  SOURCES buttons_zybo.v
  INPUT_IO_FILE ${COMMON}/zybo.pcf
  EXPLICIT_ADD_FILE_TARGET
  )

add_vivado_target(
  NAME buttons_zybo_vivado
  PARENT_NAME buttons_zybo
  # TODO: https://github.com/SymbiFlow/symbiflow-arch-defs/issues/1018
  DISABLE_DIFF_TEST
  )

#add_fpga_target(
#  NAME buttons_zyboz7
#  BOARD zyboz7-full
#  SOURCES buttons_zybo.v
#  INPUT_IO_FILE ${COMMON}/zyboz7.pcf
#  EXPLICIT_ADD_FILE_TARGET
#  )

add_file_target(FILE buttons_nexys_video.v SCANNER_TYPE verilog)

add_fpga_target(
  NAME buttons_nexys_video
  BOARD nexys_video
  SOURCES buttons_nexys_video.v
  INPUT_IO_FILE ${COMMON}/nexys_video.pcf
  INPUT_XDC_FILE ${COMMON}/nexys_video.xdc
  EXPLICIT_ADD_FILE_TARGET
  )

add_vivado_target(
  NAME buttons_nexys_video_vivado
  PARENT_NAME buttons_nexys_video
  )
