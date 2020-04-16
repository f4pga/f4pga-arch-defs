add_file_target(FILE mem.init)
add_file_target(FILE mem_1.init)

add_file_target(FILE top.sdc)
add_file_target(FILE top_clocks.xdc)

add_fpga_target(
  NAME baselitex_no_eth_nexys_video
  BOARD nexys_video
  SOURCES
    top.v
    VexRiscv_Linux.v
  INPUT_IO_FILE top.pcf
  INPUT_XDC_FILE top.xdc
  SDC_FILE top.sdc  
)

add_vivado_target(
    NAME baselitex_no_eth_nexys_video_vivado
    PARENT_NAME baselitex_no_eth_nexys_video
    XDC top_clocks.xdc
)
