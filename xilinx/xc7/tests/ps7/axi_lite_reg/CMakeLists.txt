add_file_target(FILE AxiPeriph.v SCANNER_TYPE verilog)
add_file_target(FILE axi_reg.v SCANNER_TYPE verilog)
add_file_target(FILE zybo.xdc)

add_fpga_target(
  NAME axi_regs_zybo
  BOARD zybo-full
  SOURCES AxiPeriph.v axi_reg.v
  INPUT_XDC_FILES zybo.xdc
  EXPLICIT_ADD_FILE_TARGET
  )

add_vivado_target(
  NAME axi_regs_zybo_vivado
  PARENT_NAME axi_regs_zybo
  # FIXME: https://github.com/SymbiFlow/f4pga-arch-defs/issues/1346
  # Vivado rejects the valid BUFH -> PS7 placement, so disable the test for
  # now.
  DISABLE_DIFF_TEST
  )
