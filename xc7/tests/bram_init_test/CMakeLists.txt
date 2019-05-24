get_target_property_required(UART_SOURCES uart_library SOURCES)

list(APPEND SOURCES ../common/error_output_logic.v ../common/rom_test.v top.v)
add_file_target(FILE top.v SCANNER_TYPE verilog)

add_fpga_target(
  NAME bram_init_test
  BOARD basys3
  INPUT_IO_FILE ../common/basys3.pcf
  SOURCES ${UART_SOURCES} ${SOURCES}
  EXPLICIT_ADD_FILE_TARGET
  )

get_target_property_required(DEVICE basys3 DEVICE)
get_target_property_required(ARCH ${DEVICE} ARCH)
get_target_property_required(SYNTH_V bram_test SYNTH_V)
