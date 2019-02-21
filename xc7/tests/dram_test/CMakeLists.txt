get_target_property_required(UART_SOURCES uart_library SOURCES)

list(APPEND SOURCES ../common/error_output_logic.v)
foreach(file ram_test.v top.v)
    add_file_target(FILE ${file} SCANNER_TYPE verilog)
    list(APPEND SOURCES ${file})
endforeach()

add_fpga_target(
  NAME ram_test
  BOARD basys3
  INPUT_IO_FILE ../common/basys3.pcf
  SOURCES ${UART_SOURCES} ${symbiflow-arch-defs_SOURCE_DIR}/library/lfsr.v ${SOURCES}
  EXPLICIT_ADD_FILE_TARGET
  )

get_target_property_required(DEVICE basys3 DEVICE)
get_target_property_required(ARCH ${DEVICE} ARCH)
get_target_property_required(SYNTH_V ram_test SYNTH_V)

add_autosim(
    NAME ram_test_autosim_synth
    TOP top
    ARCH ${ARCH}
    SOURCES ${SYNTH_V}
    CYCLES 3000
    )
