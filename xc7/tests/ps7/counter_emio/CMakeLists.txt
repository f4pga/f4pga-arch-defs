add_file_target(FILE counter_emio.v SCANNER_TYPE verilog)
add_file_target(FILE zybo.pcf)

add_fpga_target(
  NAME counter_emio_zybo
  BOARD zybo-full
  SOURCES counter_emio.v
  INPUT_IO_FILE zybo.pcf
  EXPLICIT_ADD_FILE_TARGET
  )

add_vivado_target(
    NAME counter_emio_zybo_vivado
    PARENT_NAME counter_emio_zybo
    BIT_TO_V_EXTRA_ARGS --allow-non-dedicated-clk-routes
    )
