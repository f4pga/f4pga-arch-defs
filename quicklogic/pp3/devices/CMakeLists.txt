quicklogic_define_device(
  FAMILY pp3
  ARCH ql-s3
  DEVICES ql-eos-s3 ql-pp3e
  PACKAGES wlcsp wlcsp
)

define_ql_device_cells_install_target(
  DEVICE ql-eos-s3
  DEVICE_TYPE ql-eos-s3-virt
  PACKAGE wlcsp
)

define_ql_device_cells_install_target(
  DEVICE ql-pp3e
  DEVICE_TYPE ql-pp3e-virt
  PACKAGE wlcsp
)
