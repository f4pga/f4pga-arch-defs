add_custom_target(test_dram_packing)

function(dram_tests dram_num_instances dram_mode block_type_usage)
  add_file_target(FILE dram_${dram_num_instances}_${dram_mode}.v SCANNER_TYPE verilog)
  add_fpga_target(
    NAME dram_${dram_num_instances}_${dram_mode}
    BOARD basys3
    SOURCES dram_${dram_num_instances}_${dram_mode}.v
    INPUT_IO_FILE ${COMMON}/basys3.pcf
    ASSERT_BLOCK_TYPES_ARE_USED ${block_type_usage}
    EXPLICIT_ADD_FILE_TARGET
    )

  add_vivado_target(
    NAME dram_${dram_num_instances}_${dram_mode}_vivado
    PARENT_NAME dram_${dram_num_instances}_${dram_mode}
    )

  add_dependencies(test_dram_packing
    dram_${dram_num_instances}_${dram_mode}_bit
    dram_${dram_num_instances}_${dram_mode}_assert_usage
  )

endfunction()

# dram_tests(<dram_num_instances> <dram_mode> <block_type_usage>)
dram_tests(4 32x1s SYN-OUTPAD=17,SYN-INPAD=18,BLK-TL-SLICEM=1)
# Design uses 8 RAM32X1S primitives. Each primitive occupy 1 LUT and
# there are 4 LUTs per SLICE so 2 SLICEM are required
dram_tests(8 32x1s SYN-OUTPAD=17,SYN-INPAD=18,BLK-TL-SLICEM=2)
dram_tests(2 32x1d SYN-OUTPAD=17,SYN-INPAD=18,BLK-TL-SLICEM=1)
dram_tests(4 32x2s SYN-OUTPAD=17,SYN-INPAD=18,BLK-TL-SLICEM=1)
dram_tests(2 64x1d SYN-OUTPAD=17,SYN-INPAD=18,BLK-TL-SLICEM=1)
dram_tests(4 64x1s SYN-OUTPAD=17,SYN-INPAD=18,BLK-TL-SLICEM=1)
dram_tests(2 128x1s SYN-OUTPAD=17,SYN-INPAD=18,BLK-TL-SLICEM=1)
dram_tests(1 128x1d SYN-OUTPAD=17,SYN-INPAD=18,BLK-TL-SLICEM=1)
dram_tests(1 256x1s SYN-OUTPAD=17,SYN-INPAD=18,BLK-TL-SLICEM=1)
dram_tests(1 32m SYN-OUTPAD=17,SYN-INPAD=18,BLK-TL-SLICEM=1)
dram_tests(1 64m SYN-OUTPAD=17,SYN-INPAD=18,BLK-TL-SLICEM=1)
