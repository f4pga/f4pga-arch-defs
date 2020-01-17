add_custom_target(test_dram_packing)

function(dram_tests dram_num_instances dram_mode outpad inpad)
  add_fpga_target(
    NAME dram_${dram_num_instances}_${dram_mode}
    BOARD basys3
    SOURCES dram_${dram_num_instances}_${dram_mode}.v
    INPUT_IO_FILE dram_${dram_num_instances}_${dram_mode}.pcf
    ASSERT_USAGE SYN-OUTPAD=${outpad},SYN-INPAD=${inpad},BLK-TL-SLICEM=1
    )

  # TODO: Vivado target for drams was added with https://github.com/SymbiFlow/symbiflow-arch-defs/pull/1234
  # but it was not active before, therefore its failure was never caught.
  # For now the vivado target is disabled.
  #add_vivado_target(
  #  NAME dram_${dram_num_instances}_${dram_mode}_vivado
  #  PARENT_NAME dram_${dram_num_instances}_${dram_mode}
  #  )

  add_dependencies(test_dram_packing
    dram_${dram_num_instances}_${dram_mode}_bin
    dram_${dram_num_instances}_${dram_mode}_assert_usage
  )

endfunction()

# dram_tests(<dram_num_instances> <dram_mode> <syn_outpad_assert_usage> <syn_inpad_assert_usage>)
dram_tests(4 32x1s 4 11)
dram_tests(8 32x1s 8 11)
dram_tests(2 32x1d 8 15)
dram_tests(4 32x2s 4 14)
dram_tests(2 64x1d 4 12)
dram_tests(4 64x1s 4 16)
dram_tests(2 128x1s 2 11)
dram_tests(1 128x1d 2 17)
dram_tests(1 256x1s 1 11)
dram_tests(1 32m 8 17)
dram_tests(1 64m 4 17)
