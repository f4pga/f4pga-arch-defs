add_file_target(FILE counter_emio.v SCANNER_TYPE verilog)
add_file_target(FILE zybo.xdc)

add_fpga_target(
  NAME counter_emio_zybo
  BOARD zybo-full
  SOURCES counter_emio.v
  INPUT_XDC_FILE zybo.xdc
  EXPLICIT_ADD_FILE_TARGET
)

add_vivado_target(
    NAME counter_emio_zybo_vivado
    PARENT_NAME counter_emio_zybo
)
