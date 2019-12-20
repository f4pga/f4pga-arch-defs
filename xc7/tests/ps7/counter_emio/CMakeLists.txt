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
    # Disabled until PS7 is supported in fasm2bels
    DISABLE_DIFF_TEST
    )
