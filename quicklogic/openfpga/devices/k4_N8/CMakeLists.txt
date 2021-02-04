file(RELATIVE_PATH
  ARCH_XML
  ${CMAKE_CURRENT_SOURCE_DIR}
  ${symbiflow-arch-defs_SOURCE_DIR}/third_party/SOFA/ARCH/vpr_arch/k4_N8_tileable_reset_softadder_register_scan_chain_nonLR_caravel_io_skywater130nm.xml
)

quicklogic_define_openfpga_device (
  NAME     k4_N8
  ARCH     ql-openfpga
  FAMILY   openfpga
  ARCH_XML ${ARCH_XML}
  LAYOUT   32x32

  ROUTE_CHAN_WIDTH 60
)
