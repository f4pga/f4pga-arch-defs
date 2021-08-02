add_fpga_target(
  NAME assp_mult-ql-jimbob4
  BOARD jimbob4
  SOURCES assp_mult.v
#  INPUT_IO_FILE jimbob4.pcf
)

add_fpga_target(
  NAME assp_ram512x36-ql-jimbob4
  BOARD jimbob4
  SOURCES assp_ram512x36.v
#  INPUT_IO_FILE jimbob4.pcf
)

add_fpga_target(
  NAME assp_ram512x32-ql-jimbob4
  BOARD jimbob4
  SOURCES assp_ram512x32.v
#  INPUT_IO_FILE jimbob4.pcf
)

add_fpga_target(
  NAME assp_ram4096x17-ql-jimbob4
  BOARD jimbob4
  SOURCES assp_ram4096x17.v
#  INPUT_IO_FILE jimbob4.pcf
)

add_dependencies(all_quick_tests assp_mult-ql-jimbob4_route)
add_dependencies(all_quick_tests assp_ram512x36-ql-jimbob4_route)
add_dependencies(all_quick_tests assp_ram512x32-ql-jimbob4_route)
add_dependencies(all_quick_tests assp_ram4096x17-ql-jimbob4_route)

