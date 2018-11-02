add_fpga_target(
  NAME dram_4_64x1s
  BOARD basys3
  INPUT_IO_FILE dram_4_64x1s.pcf
  SOURCES dram_4_64x1s.v
  ASSERT_USAGE BLK_SY-OUTPAD=4,BLK_SY-INPAD=12,BLK_TI-CLBLM_R=1
  )

add_fpga_target(
  NAME dram_2_64x1d
  BOARD basys3
  INPUT_IO_FILE dram_2_64x1d.pcf
  SOURCES dram_2_64x1d.v
  ASSERT_USAGE BLK_SY-OUTPAD=4,BLK_SY-INPAD=15,BLK_TI-CLBLM_R=1
  )

add_fpga_target(
  NAME dram_4_32x2s
  BOARD basys3
  INPUT_IO_FILE dram_4_32x2s.pcf
  SOURCES dram_4_32x2s.v
  ASSERT_USAGE BLK_SY-OUTPAD=8,BLK_SY-INPAD=15,BLK_TI-CLBLM_R=1
  )

add_custom_target(test_dram)
add_dependencies(test_dram
    dram_2_64x1d_bin dram_2_64x1d_assert_usage
    dram_4_64x1s_bin dram_4_64x1s_assert_usage
    dram_4_32x2s_bin dram_4_32x2s_assert_usage
    )
