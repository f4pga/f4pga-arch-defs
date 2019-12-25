add_file_target(FILE mem.init)
add_file_target(FILE mem_1.init)
add_file_target(FILE top.sdc)
add_file_target(FILE AxiPeriph.v SCANNER_TYPE verilog)
add_file_target(FILE VexRiscv_LinuxNoDspFmax.v SCANNER_TYPE verilog)
add_file_target(FILE wb2axi.sv SCANNER_TYPE verilog)
add_file_target(FILE top.v SCANNER_TYPE verilog)
add_file_target(FILE top_ps7.v SCANNER_TYPE verilog)
add_file_target(FILE zybo.pcf)

add_fpga_target(
  NAME litex_linux_zybo
  BOARD zybo-full
  SOURCES AxiPeriph.v top.v top_ps7.v VexRiscv_LinuxNoDspFmax.v wb2axi.sv
  INPUT_IO_FILE zybo.pcf
  SDC_FILE top.sdc
  EXPLICIT_ADD_FILE_TARGET
  )
