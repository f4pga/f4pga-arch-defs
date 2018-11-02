add_fpga_target(
  NAME dram_4_64x1s
  BOARD basys3
  INPUT_IO_FILE dram_4_64x1s.pcf
  SOURCES dram_4_64x1s.v
  )

add_fpga_target(
  NAME dram_2_64x1d
  BOARD basys3
  INPUT_IO_FILE dram_2_64x1d.pcf
  SOURCES dram_2_64x1d.v
  )

add_fpga_target(
  NAME dram_4_32x2s
  BOARD basys3
  INPUT_IO_FILE dram_4_32x2s.pcf
  SOURCES dram_4_32x2s.v
  )

add_custom_target(test_dram)
add_dependencies(test_dram dram_2_64x1d_bin dram_4_64x1s_bin dram_4_32x2s_bin)
