add_file_target(FILE obuftds_basys3.v SCANNER_TYPE verilog)
add_file_target(FILE basys3.pcf)

add_fpga_target(
  NAME obuftds_basys3
  BOARD basys3-bottom
  SOURCES obuftds_basys3.v
  INPUT_IO_FILE basys3.pcf
  EXPLICIT_ADD_FILE_TARGET
  )

# Disabling Vivado target due to #1169
#add_vivado_target(
#  NAME obuftds_basys3_vivado
#  PARENT_NAME obuftds_basys3
#  )

add_dependencies(all_xc7_tests
  obuftds_basys3
)

