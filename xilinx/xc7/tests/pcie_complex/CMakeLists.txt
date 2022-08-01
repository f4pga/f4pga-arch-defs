add_file_target(FILE pcie_complex.v SCANNER_TYPE verilog)

add_fpga_target(
  NAME pcie_complex_netv2_a100t
  BOARD netv2-a100t
  INPUT_XDC_FILES ${COMMON}/netv2_a100t_pcie_complex.xdc
  SOURCES pcie_complex.v
  EXPLICIT_ADD_FILE_TARGET
  )
