set(DESIGN_DIR ${QL_DESIGNS_DIR}/inferred_ram_test)

add_fpga_target(
  NAME inferred_ram_test-ql-chandalar
  BOARD chandalar
  SOURCES
    ${DESIGN_DIR}/AL4S3B_FPGA_IP.v
    ${DESIGN_DIR}/AL4S3B_FPGA_QL_Reserved.v
    ${DESIGN_DIR}/AL4S3B_FPGA_RAMs.v
    ${DESIGN_DIR}/AL4S3B_FPGA_Registers.v
    ${DESIGN_DIR}/AL4S3B_FPGA_Top.v
    ${DESIGN_DIR}/r1024x16_1024x16.v
    ${DESIGN_DIR}/r1024x8_1024x8.v
    ${DESIGN_DIR}/r2048x8_2048x8.v
    ${DESIGN_DIR}/r512x16_512x16.v
    ${DESIGN_DIR}/r512x32_512x32.v
  INPUT_IO_FILE chandalar.pcf
  AUTO_ADD_FILE_TARGET
)


add_jlink_output(
  PARENT inferred_ram_test-ql-chandalar
)

add_openocd_output(
  PARENT inferred_ram_test-ql-chandalar
)

add_dependencies(all_eos_s3_tests_prog  inferred_ram_test-ql-chandalar_jlink)
add_dependencies(all_eos_s3_tests_prog  inferred_ram_test-ql-chandalar_openocd)

add_dependencies(all_eos_s3_tests_bit   inferred_ram_test-ql-chandalar_bit)
add_dependencies(all_eos_s3_tests_bit_v inferred_ram_test-ql-chandalar_bit_v)

add_dependencies(inferred_ram_test-ql-chandalar_analysis inferred_ram_test-ql-chandalar_bit_v)

# Make target for the HEX files and make them depend on the relevant sources
foreach (TYPE 1024x16 1024x8 2048x8 512x16 512x32)
    set(HEX_NAME ${DESIGN_DIR}/init_${TYPE}.hex)
    set(SRC_NAME ${DESIGN_DIR}/r${TYPE}_${TYPE}.v)

    add_file_target(FILE ${HEX_NAME})
    get_file_target(HEX_TARGET ${HEX_NAME})
    get_file_target(SRC_TARGET ${SRC_NAME})

    add_dependencies(${SRC_TARGET} ${HEX_TARGET})
endforeach()


