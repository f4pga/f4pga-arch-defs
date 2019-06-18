set(BASE_TEST_NAME bram_sdp_test)
get_target_property_required(UART_SOURCES uart_library SOURCES)

list(APPEND SOURCES ${symbiflow-arch-defs_SOURCE_DIR}/library/lfsr.v ../common/error_output_logic.v ../common/ram_test.v)

get_target_property_required(DEVICE basys3 DEVICE)
get_target_property_required(ARCH ${DEVICE} ARCH)

foreach(type 18 36)
  add_file_target(FILE ${BASE_TEST_NAME}_${type}.v SCANNER_TYPE verilog)
  add_fpga_target(
    NAME ${BASE_TEST_NAME}_${type}
    BOARD basys3
    INPUT_IO_FILE ../common/basys3.pcf
    SOURCES ${UART_SOURCES} ${SOURCES} ${BASE_TEST_NAME}_${type}.v
    EXPLICIT_ADD_FILE_TARGET
    )

  get_target_property_required(SYNTH_V ${BASE_TEST_NAME}_${type} SYNTH_V)

  add_autosim(
      NAME ${BASE_TEST_NAME}_${type}_autosim_synth
      TOP top
      ARCH ${ARCH}
      SOURCES ${SYNTH_V}
      CYCLES 3000
      )
endforeach()

