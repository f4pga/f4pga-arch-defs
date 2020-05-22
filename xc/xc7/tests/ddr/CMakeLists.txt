add_file_target(FILE mem.init)
add_file_target(FILE mem_1.init)

add_file_target(FILE ddr_uart.v SCANNER_TYPE verilog)
add_file_target(FILE arty.pcf)
add_file_target(FILE arty.xdc)
add_file_target(FILE arty_clocks.xdc)
add_file_target(FILE arty.sdc)

get_target_property_required(PYTHON3 env PYTHON3)
get_target_property(PYTHON3_TARGET env PYTHON3_TARGET)

add_fpga_target(
  NAME ddr_uart_arty
  BOARD arty-full
  SOURCES
    ddr_uart.v
  INPUT_IO_FILE arty.pcf
  INPUT_XDC_FILE arty.xdc
  SDC_FILE arty.sdc
  EXPLICIT_ADD_FILE_TARGET
)

add_vivado_target(
    NAME ddr_uart_arty_vivado
    PARENT_NAME ddr_uart_arty
    XDC arty_clocks.xdc
)

add_file_target(FILE ddr_uart_100t.v SCANNER_TYPE verilog)
add_fpga_target(
  NAME ddr_uart_arty100t
  BOARD arty100t-full
  SOURCES
    ddr_uart_100t.v
  INPUT_IO_FILE arty.pcf
  INPUT_XDC_FILE arty.xdc
  SDC_FILE arty.sdc
  EXPLICIT_ADD_FILE_TARGET
)

add_vivado_target(
  NAME ddr_uart_arty100t_vivado
  PARENT_NAME ddr_uart_arty100t
)
