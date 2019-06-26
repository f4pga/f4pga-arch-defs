add_fpga_target(
  NAME srl32
  BOARD basys3
  INPUT_IO_FILE basys3.pcf
  SOURCES basys3_top.v srl_tester.v lfsr8_11d.v rom.v
  )
