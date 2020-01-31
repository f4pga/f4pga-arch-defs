add_subdirectory(layouts)
add_subdirectory(routing)
add_subdirectory(clutff-unidir-s4)

define_device(
  DEVICE 4x4
  ARCH testarch
  DEVICE_TYPE clutff-unidir-s4
  PACKAGES dummy
  RR_PATCH_DEPS intervaltree progressbar2
  CACHE_ARGS --route_chan_width 100
  )

define_device(
  DEVICE 10x10
  ARCH testarch
  DEVICE_TYPE clutff-unidir-s4
  PACKAGES dummy
  RR_PATCH_DEPS intervaltree progressbar2
  CACHE_ARGS --route_chan_width 100
  )
