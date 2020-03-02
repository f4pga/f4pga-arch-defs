add_custom_target(test_dram_packing)

function(dram_tests dram_num_instances dram_mode outpad inpad enable_vivado_target)
  add_file_target(FILE dram_${dram_num_instances}_${dram_mode}.v SCANNER_TYPE verilog)
  add_fpga_target(
    NAME dram_${dram_num_instances}_${dram_mode}
    BOARD basys3
    SOURCES dram_${dram_num_instances}_${dram_mode}.v
    INPUT_IO_FILE ${COMMON}/basys3.pcf
    ASSERT_USAGE SYN-OUTPAD=${outpad},SYN-INPAD=${inpad},BLK-TL-SLICEM=1
    EXPLICIT_ADD_FILE_TARGET
    )

  # TODO: Some vivado targets are disabled until
  # https://github.com/SymbiFlow/symbiflow-arch-defs/issues/1269 gets solved
  if(${enable_vivado_target} STREQUAL "Y")
    add_vivado_target(
      NAME dram_${dram_num_instances}_${dram_mode}_vivado
      PARENT_NAME dram_${dram_num_instances}_${dram_mode}
      )
  endif()

  add_dependencies(test_dram_packing
    dram_${dram_num_instances}_${dram_mode}_bin
    dram_${dram_num_instances}_${dram_mode}_assert_usage
  )

endfunction()

# dram_tests(<dram_num_instances> <dram_mode> <syn_outpad_assert_usage> <syn_inpad_assert_usage> <enable_vivado_target>)
dram_tests(4 32x1s 4 11 Y)
dram_tests(8 32x1s 8 11 Y)
dram_tests(2 32x1d 8 15 Y)
dram_tests(4 32x2s 4 14 Y)
dram_tests(2 64x1d 4 12 Y)
dram_tests(4 64x1s 4 16 Y)
dram_tests(2 128x1s 2 11 Y)
dram_tests(1 128x1d 2 17 Y)
dram_tests(1 256x1s 1 11 N)
dram_tests(1 32m 8 17 Y)
dram_tests(1 64m 4 17 Y)
