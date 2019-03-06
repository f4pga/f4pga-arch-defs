get_target_property_required(UART_SOURCES uart_library SOURCES)

list(APPEND SOURCES ../common/error_output_logic.v)
foreach(file rom_test.v top.v)
    add_file_target(FILE ${file} SCANNER_TYPE verilog)
    list(APPEND SOURCES ${file})
endforeach()

add_fpga_target(
  NAME bram_sdp_init_test
  BOARD basys3
  INPUT_IO_FILE ../common/basys3.pcf
  SOURCES ${UART_SOURCES} ${SOURCES}
  EXPLICIT_ADD_FILE_TARGET
  )
