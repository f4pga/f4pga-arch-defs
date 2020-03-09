get_target_property_required(UART_SOURCES uart_library SOURCES)

list(APPEND SOURCES ${COMMON}/error_output_logic.v ${COMMON}/ram_test.v)

get_target_property_required(DEVICE basys3 DEVICE)
get_target_property_required(ARCH ${DEVICE} ARCH)

foreach(type 32x1d 64x1d 32m 64m)
  add_file_target(FILE dram_test_${type}.v SCANNER_TYPE verilog)
  add_fpga_target(
    NAME dram_test_${type}
    BOARD basys3
    INPUT_IO_FILE ${COMMON}/basys3.pcf
    SDC_FILE ${COMMON}/basys3.sdc
    SOURCES ${UART_SOURCES} ${symbiflow-arch-defs_SOURCE_DIR}/library/lfsr.v ${SOURCES} dram_test_${type}.v
    EXPLICIT_ADD_FILE_TARGET
    )

  get_target_property_required(SYNTH_V dram_test_${type} SYNTH_V)

  add_autosim(
      NAME dram_test_${type}_autosim_synth
      TOP top
      ARCH ${ARCH}
      SOURCES ${SYNTH_V}
      CYCLES 3000
      )

  add_vivado_target(
      NAME dram_test_${type}_vivado
      PARENT_NAME dram_test_${type}
      CLOCK_PINS clk
      CLOCK_PERIODS 10.0
      )

  add_vivado_pnr_target(
      NAME dram_test_${type}_vivado_pnr
      PARENT_NAME dram_test_${type}
      CLOCK_PINS clk
      CLOCK_PERIODS 10.0
      IOSTANDARD LVCMOS33
      )
endforeach()
