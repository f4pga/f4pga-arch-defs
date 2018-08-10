add_subdirectory(layouts)
add_subdirectory(routing)
add_subdirectory(clutff-unidir-s4)

define_device(
  DEVICE 4x4
  ARCH testarch
  DEVICE_TYPE clutff-unidir-s4
  PACKAGES dummy
  )

