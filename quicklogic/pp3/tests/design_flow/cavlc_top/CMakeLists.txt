set(DESIGN_DIR ${QL_DESIGNS_DIR}/cavlc_top)

# File targets already defined under qlf_k4n8/tests/design_flow/cavlc_top
#add_file_target(FILE ${DESIGN_DIR}/defines.v SCANNER_TYPE verilog)
#add_file_target(FILE ${DESIGN_DIR}/cavlc_fsm.v SCANNER_TYPE verilog)
#add_file_target(FILE ${DESIGN_DIR}/cavlc_len_gen.v SCANNER_TYPE verilog)
#add_file_target(FILE ${DESIGN_DIR}/cavlc_read_levels.v SCANNER_TYPE verilog)
#add_file_target(FILE ${DESIGN_DIR}/cavlc_read_run_befores.v SCANNER_TYPE verilog)
#add_file_target(FILE ${DESIGN_DIR}/cavlc_read_total_coeffs.v SCANNER_TYPE verilog)
#add_file_target(FILE ${DESIGN_DIR}/cavlc_read_total_zeros.v SCANNER_TYPE verilog)
#add_file_target(FILE ${DESIGN_DIR}/cavlc_top.v SCANNER_TYPE verilog)
add_file_target(FILE chandalar.pcf)

add_fpga_target(
  NAME cavlc-ql-chandalar
  BOARD chandalar
  SOURCES
    ${DESIGN_DIR}/cavlc_fsm.v
    ${DESIGN_DIR}/cavlc_len_gen.v
    ${DESIGN_DIR}/cavlc_read_levels.v
    ${DESIGN_DIR}/cavlc_read_run_befores.v
    ${DESIGN_DIR}/cavlc_read_total_coeffs.v
    ${DESIGN_DIR}/cavlc_read_total_zeros.v
    ${DESIGN_DIR}/cavlc_top.v
  INPUT_IO_FILE chandalar.pcf
  EXPLICIT_ADD_FILE_TARGET
  )

add_jlink_output(
  PARENT cavlc-ql-chandalar
)

add_openocd_output(
  PARENT cavlc-ql-chandalar
)

# FIXME: Temporarily disable due to not enough resources after packing
#add_dependencies(all_eos_s3_tests cavlc-ql-chandalar_bit)
#add_dependencies(all_eos_s3_tests cavlc-ql-chandalar_jlink)
#add_dependencies(all_eos_s3_tests cavlc-ql-chandalar_openocd)

