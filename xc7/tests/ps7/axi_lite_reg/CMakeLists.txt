add_file_target(FILE AxiInterface.v SCANNER_TYPE verilog)
add_file_target(FILE AxiPeriph.v SCANNER_TYPE verilog)
add_file_target(FILE axi_reg.v SCANNER_TYPE verilog)
add_file_target(FILE zybo.pcf)

add_fpga_target(
  NAME axi_regs_zybo
  BOARD zybo-full
  SOURCES AxiInterface.v AxiPeriph.v axi_reg.v
  INPUT_IO_FILE zybo.pcf
  EXPLICIT_ADD_FILE_TARGET
  )

#add_vivado_target(
#    NAME counter_emio_zybo_vivado
#    PARENT_NAME counter_emio_zybo
#    #DISABLE_DIFF_TEST
#    )
