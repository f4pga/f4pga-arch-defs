set(ARCH qlf_k4n8)

set(ARCH_DIR ${QLF_FPGA_DATABASE_DIR}/${ARCH})

set(FAST_CORNER_ARCH_DIR ${ARCH_DIR}/fast)
quicklogic_define_qlf_device (
  NAME     ${ARCH}_umc22_fast
  ARCH     ${ARCH}
  FAMILY   ${ARCH}
  LAYOUT   24x24
  ARCH_XML ${FAST_CORNER_ARCH_DIR}/vpr_arch/UMC22nm_vpr.xml
  RR_GRAPH ${FAST_CORNER_ARCH_DIR}/vpr_rr_graph/UMC22nm_vpr.bin.gz

  REPACKING_RULES ${ARCH_DIR}/repacking_rules.json

  ROUTE_CHAN_WIDTH 60
)

set(SLOW_CORNER_ARCH_DIR ${ARCH_DIR}/slow)
quicklogic_define_qlf_device (
  NAME     ${ARCH}_umc22_slow
  ARCH     ${ARCH}
  FAMILY   ${ARCH}
  LAYOUT   24x24
  ARCH_XML ${SLOW_CORNER_ARCH_DIR}/vpr_arch/UMC22nm_vpr.xml
  RR_GRAPH ${SLOW_CORNER_ARCH_DIR}/vpr_rr_graph/UMC22nm_vpr.bin.gz

  REPACKING_RULES ${ARCH_DIR}/repacking_rules.json

  ROUTE_CHAN_WIDTH 60
)
