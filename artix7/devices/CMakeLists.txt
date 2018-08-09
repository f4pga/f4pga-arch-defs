add_subdirectory(xc7a50t-roi-virt)

define_device(
  DEVICE xc7a50t
  ARCH artix7
  DEVICE_TYPE xc7a50t-roi-virt
  PACKAGES test
  )
