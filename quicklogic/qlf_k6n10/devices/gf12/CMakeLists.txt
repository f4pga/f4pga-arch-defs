quicklogic_define_qlf_device (
  NAME    qlf_k6n10_gf12
  ARCH     qlf_k6n10
  FAMILY   qlf_k6n10
  LAYOUT   128x128
  ARCH_XML ${symbiflow-arch-defs_SOURCE_DIR}/third_party/qlfpga-symbiflow-plugins/qlf_k6n10/vpr_arch/GF12nm_vpr.xml
  RR_GRAPH ${symbiflow-arch-defs_SOURCE_DIR}/third_party/qlfpga-symbiflow-plugins/qlf_k6n10/vpr_rr_graph/GF12nm_vpr.bin.gz
  #TODO : Add physical implementation of blocks to the arch, then we'll use repacking_rules.
  REPACKING_RULES ${symbiflow-arch-defs_SOURCE_DIR}/third_party/qlfpga-symbiflow-plugins/qlf_k6n10/vpr_arch/repacking_rules.json

  ROUTE_CHAN_WIDTH 200
)
