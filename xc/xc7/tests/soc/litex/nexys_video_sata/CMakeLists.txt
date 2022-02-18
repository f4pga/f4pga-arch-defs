add_file_target(FILE top.xdc)
add_file_target(FILE mem.init)
add_file_target(FILE mem_1.init)
add_file_target(FILE mem_2.init)
add_file_target(FILE top.v SCANNER_TYPE verilog)

add_fpga_target(
  NAME nexys_video_sata
  BOARD nexys_video
  SOURCES
    top.v
    ${VEXRISCV}
  INPUT_XDC_FILES top.xdc
  EXPLICIT_ADD_FILE_TARGET
)
