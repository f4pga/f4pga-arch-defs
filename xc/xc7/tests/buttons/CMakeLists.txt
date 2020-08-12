add_file_target(FILE buttons_arty.v SCANNER_TYPE verilog)
add_file_target(FILE buttons_arty_rev.v SCANNER_TYPE verilog)
add_fpga_target(
  NAME buttons_arty
  BOARD arty-swbut
  SOURCES buttons_arty.v
  INPUT_IO_FILE ${COMMON}/arty_swbut.pcf
  EXPLICIT_ADD_FILE_TARGET
  )

add_fpga_target(
  NAME buttons_arty_pr
  BOARD arty-swbut-pr
  SOURCES buttons_arty.v
  INPUT_IO_FILE ${COMMON}/arty_swbut_pr.pcf
  EXPLICIT_ADD_FILE_TARGET
  )

add_fpga_target(
  NAME buttons_arty_pr_rev
  BOARD arty-swbut-pr
  SOURCES buttons_arty_rev.v
  INPUT_IO_FILE ${COMMON}/arty_swbut_pr.pcf
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

add_file_target(FILE buttons_arty_overlay.v SCANNER_TYPE verilog)
add_fpga_target(
  NAME buttons_arty_overlay
  BOARD arty-swbut-overlay
  SOURCES buttons_arty_overlay.v
  INPUT_IO_FILE ${COMMON}/arty_swbut_pr_overlay.pcf
  EXPLICIT_ADD_FILE_TARGET
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
add_file_target(FILE buttons_zedboard.v SCANNER_TYPE verilog)
add_file_target(FILE buttons_pynqz1.v SCANNER_TYPE verilog)
add_file_target(FILE buttons_marszx3.v SCANNER_TYPE verilog)

#add_fpga_target(
#  NAME buttons_zybo
#  BOARD zybo-full
#  SOURCES buttons_zybo.v
#  INPUT_IO_FILE ${COMMON}/zybo.pcf
#  EXPLICIT_ADD_FILE_TARGET
#  )

#add_vivado_target(
#  NAME buttons_zybo_vivado
#  PARENT_NAME buttons_zybo
#  # TODO: https://github.com/SymbiFlow/symbiflow-arch-defs/issues/1018
#  DISABLE_DIFF_TEST
#  )

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

#add_fpga_target(
#  NAME buttons_zedboard
#  BOARD zedboard-full
#  SOURCES buttons_zedboard.v
#  INPUT_IO_FILE ${COMMON}/zedboard.pcf
#  EXPLICIT_ADD_FILE_TARGET
#  )

#add_vivado_target(
#  NAME buttons_zedboard_vivado
#  PARENT_NAME buttons_zedboard
#  )

add_fpga_target(
  NAME buttons_pynqz1
  BOARD pynqz1-full
  SOURCES buttons_pynqz1.v
  INPUT_IO_FILE ../common/pynqz1.pcf
  EXPLICIT_ADD_FILE_TARGET
 )

add_vivado_target(
  NAME buttons_pynqz1_vivado
  PARENT_NAME buttons_pynqz1
  )

#add_fpga_target(
#  NAME buttons_marszx3
#  BOARD marszx3-full
#  SOURCES buttons_marszx3.v
#  INPUT_IO_FILE ../common/marszx3.pcf
#  EXPLICIT_ADD_FILE_TARGET
#  )

#add_vivado_target(
#  NAME buttons_marszx3_vivado
#  PARENT_NAME buttons_marszx3
#  )
