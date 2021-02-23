set(ARCH_XML qlf_k4n8_umc22-arch.xml)

quicklogic_define_qlf_device (
  NAME     qlf_k4n8_umc22
  ARCH     qlf_k4n8
  FAMILY   qlf_k4n8
  ARCH_XML ${ARCH_XML}
  LAYOUT   32x32

  ROUTE_CHAN_WIDTH 60
)
