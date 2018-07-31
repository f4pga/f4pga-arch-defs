add_subdirectory(layouts)
add_subdirectory(top-routing-virt)

DEFINE_DEVICE(
  DEVICE hx1k
  ARCH ice40
  DEVICE_TYPE top-routing-virt
  PACKAGES tq144;ct256
  )

DEFINE_DEVICE(
  DEVICE lp1k
  ARCH ice40
  DEVICE_TYPE top-routing-virt
  PACKAGES qn84
  )

DEFINE_DEVICE(
  DEVICE lp8k
  ARCH ice40
  DEVICE_TYPE top-routing-virt
  PACKAGES cm81
  )

DEFINE_DEVICE(
  DEVICE up5k
  ARCH ice40
  DEVICE_TYPE top-routing-virt
  PACKAGES sg48
  )
