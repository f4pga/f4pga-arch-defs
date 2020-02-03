add_file_target(FILE mem.init)
add_file_target(FILE mem_1.init)

add_file_target(FILE arty.sdc)
add_file_target(FILE arty.json) # IOSTANDARD defs for fasm2bels

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
)

add_vivado_target(
    NAME ddr_uart_arty_vivado
    PARENT_NAME ddr_uart_arty
)
