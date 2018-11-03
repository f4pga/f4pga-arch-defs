add_fpga_target(
  NAME dram_4_32x1s
  BOARD basys3
  INPUT_IO_FILE dram_4_32x1s.pcf
  SOURCES dram_4_32x1s.v
  ASSERT_USAGE BLK_SY-OUTPAD=4,BLK_SY-INPAD=11,BLK_TI-CLBLM_R=1
  )

add_fpga_target(
  NAME dram_4_32x2s
  BOARD basys3
  INPUT_IO_FILE dram_4_32x2s.pcf
  SOURCES dram_4_32x2s.v
  ASSERT_USAGE BLK_SY-OUTPAD=8,BLK_SY-INPAD=15,BLK_TI-CLBLM_R=1
  )

add_fpga_target(
  NAME dram_2_32x1d
  BOARD basys3
  INPUT_IO_FILE dram_2_32x1d.pcf
  SOURCES dram_2_32x1d.v
  ASSERT_USAGE BLK_SY-OUTPAD=4,BLK_SY-INPAD=14,BLK_TI-CLBLM_R=1
  )

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
  ASSERT_USAGE BLK_SY-OUTPAD=4,BLK_SY-INPAD=16,BLK_TI-CLBLM_R=1
  )

add_fpga_target(
  NAME dram_2_128x1s
  BOARD basys3
  INPUT_IO_FILE dram_2_128x1s.pcf
  SOURCES dram_2_128x1s.v
  ASSERT_USAGE BLK_SY-OUTPAD=2,BLK_SY-INPAD=11,BLK_TI-CLBLM_R=1
  )

add_fpga_target(
  NAME dram_1_128x1d
  BOARD basys3
  INPUT_IO_FILE dram_1_128x1d.pcf
  SOURCES dram_1_128x1d.v
  ASSERT_USAGE BLK_SY-OUTPAD=2,BLK_SY-INPAD=17,BLK_TI-CLBLM_R=1
  )

add_fpga_target(
  NAME dram_1_256x1s
  BOARD basys3
  INPUT_IO_FILE dram_1_256x1s.pcf
  SOURCES dram_1_256x1s.v
  ASSERT_USAGE BLK_SY-OUTPAD=1,BLK_SY-INPAD=11,BLK_TI-CLBLM_R=1
  )

add_custom_target(test_dram)
add_dependencies(test_dram
    dram_4_32x1s_bin  dram_4_32x1s_assert_usage
    dram_2_32x1d_bin  dram_2_32x1d_assert_usage
    dram_4_32x2s_bin  dram_4_32x2s_assert_usage
    dram_2_64x1d_bin  dram_2_64x1d_assert_usage
    dram_4_64x1s_bin  dram_4_64x1s_assert_usage
    dram_2_128x1s_bin dram_2_128x1s_assert_usage
    dram_1_128x1d_bin dram_1_128x1d_assert_usage
    dram_1_256x1s_bin dram_1_256x1s_assert_usage
    )
