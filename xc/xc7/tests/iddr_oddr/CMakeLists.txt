add_file_target(FILE iddr_oddr_basys3.v SCANNER_TYPE verilog)
add_file_target(FILE ioddr_tester.v SCANNER_TYPE verilog)
add_file_target(FILE iddr_wrapper.v SCANNER_TYPE verilog)
add_file_target(FILE oddr_wrapper.v SCANNER_TYPE verilog)
add_file_target(FILE data_generator.v SCANNER_TYPE verilog)

add_file_target(FILE iddr_oddr_basys3.pcf SCANNER_TYPE)

add_fpga_target(
  NAME          iddr_oddr_basys3
  BOARD         basys3-bottom
  SOURCES       iddr_oddr_basys3.v
                ioddr_tester.v
                iddr_wrapper.v
                oddr_wrapper.v
                data_generator.v
  INPUT_IO_FILE iddr_oddr_basys3.pcf
  EXPLICIT_ADD_FILE_TARGET
  )

add_vivado_target(
  NAME          iddr_oddr_basys3_vivado
  PARENT_NAME   iddr_oddr_basys3
  )
