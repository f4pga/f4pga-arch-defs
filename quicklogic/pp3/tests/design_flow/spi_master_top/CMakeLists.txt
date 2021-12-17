set(DESIGN_DIR ${QL_DESIGNS_DIR}/spi_master_top)

add_fpga_target(
  NAME spi_master_top-ql-chandalar
  BOARD chandalar
  SOURCES
    ${DESIGN_DIR}/baud_generator.v
    ${DESIGN_DIR}/ql_clkgate_x4.v
    ${DESIGN_DIR}/ql_mux2_x2.v
    ${DESIGN_DIR}/registers.v
    ${DESIGN_DIR}/serializer_deserializer.v
    ${DESIGN_DIR}/spi_master_top.v
  INPUT_IO_FILE chandalar.pcf
  AUTO_ADD_FILE_TARGET

  ASSERT_USAGE PB-CLOCK=2,PB-GMUX=2,PB-LOGIC<=136
)


add_jlink_output(
  PARENT spi_master_top-ql-chandalar
)

add_openocd_output(
  PARENT spi_master_top-ql-chandalar
)

# FIXME: The EOS-S3 fabric does not provide sufficient IO count
#add_dependencies(all_eos_s3_tests_prog  spi_master_top-ql-chandalar_jlink)
#add_dependencies(all_eos_s3_tests_prog  spi_master_top-ql-chandalar_openocd)

#add_dependencies(all_eos_s3_tests_bit   spi_master_top-ql-chandalar_bit)
#add_dependencies(all_eos_s3_tests_bit_v spi_master_top-ql-chandalar_bit_v)

add_dependencies(spi_master_top-ql-chandalar_analysis spi_master_top-ql-chandalar_bit_v)

#add_dependencies(all_eos_s3_tests_regression spi_master_top-ql-chandalar_assert_usage)

