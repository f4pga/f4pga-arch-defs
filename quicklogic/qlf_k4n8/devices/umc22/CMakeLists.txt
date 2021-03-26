quicklogic_define_qlf_device (
  NAME     qlf_k4n8_umc22
  ARCH     qlf_k4n8
  FAMILY   qlf_k4n8
  LAYOUT   32x32
  ARCH_XML ${symbiflow-arch-defs_SOURCE_DIR}/third_party/qlfpga-symbiflow-plugins/qlf_k4n8/vpr_arch/UMC22nm_vpr.xml
  RR_GRAPH ${symbiflow-arch-defs_SOURCE_DIR}/third_party/qlfpga-symbiflow-plugins/qlf_k4n8/vpr_rr_graph/UMC22nm_vpr.bin.gz

  REPACKING_RULES ${symbiflow-arch-defs_SOURCE_DIR}/quicklogic/qlf_k4n8/devices/umc22/repacking_rules.json

  ROUTE_CHAN_WIDTH 60
)
