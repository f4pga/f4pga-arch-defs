add_file_target(FILE iobuf_infer_basys3.v SCANNER_TYPE verilog)

add_fpga_target(
  NAME iobuf_infer_basys3
  BOARD basys3-full
  SOURCES iobuf_infer_basys3.v
  INPUT_IO_FILE ${COMMON}/basys3_pmod.pcf
  EXPLICIT_ADD_FILE_TARGET
  )

add_vivado_target(
  NAME iobuf_infer_basys3_vivado
  PARENT_NAME iobuf_infer_basys3
  )

add_dependencies(all_xc7_tests
  iobuf_infer_basys3
)

