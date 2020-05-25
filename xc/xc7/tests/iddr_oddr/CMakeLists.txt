add_file_target(FILE iddr_basys3.v SCANNER_TYPE verilog)
add_file_target(FILE iddr_basys3.pcf SCANNER_TYPE)

add_fpga_target(
  NAME          iddr_basys3
  BOARD         basys3-bottom
  SOURCES       iddr_basys3.v
  INPUT_IO_FILE iddr_basys3.pcf
  EXPLICIT_ADD_FILE_TARGET
  )

add_vivado_target(
  NAME          iddr_basys3_vivado
  PARENT_NAME   iddr_basys3
  )


add_file_target(FILE oddr_basys3.v SCANNER_TYPE verilog)
add_file_target(FILE oddr_basys3.pcf SCANNER_TYPE)

add_fpga_target(
  NAME          oddr_basys3
  BOARD         basys3-bottom
  SOURCES       oddr_basys3.v
  INPUT_IO_FILE oddr_basys3.pcf
  EXPLICIT_ADD_FILE_TARGET
  )

add_vivado_target(
  NAME          oddr_basys3_vivado
  PARENT_NAME   oddr_basys3
  )


add_file_target(FILE tddr_basys3.v SCANNER_TYPE verilog)

add_fpga_target(
  NAME          tddr_basys3
  BOARD         basys3-bottom
  SOURCES       tddr_basys3.v
  INPUT_IO_FILE oddr_basys3.pcf
  EXPLICIT_ADD_FILE_TARGET
  )

add_vivado_target(
  NAME          tddr_basys3_vivado
  PARENT_NAME   tddr_basys3
  )


