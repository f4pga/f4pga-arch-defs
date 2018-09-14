add_subdirectory(layouts)
add_subdirectory(top-routing-virt)

function(DEFINE_ICE40_DEVICE)
  set(options)
  set(oneValueArgs DEVICE DEVICE_TYPE PACKAGES)
  set(multiValueArgs)
  cmake_parse_arguments(
    DEFINE_ICE40_DEVICE
    "${options}"
    "${oneValueArgs}"
    "${multiValueArgs}"
    ${ARGN}
  )

  define_device(
    DEVICE ${DEFINE_ICE40_DEVICE_DEVICE}
    ARCH ice40
    DEVICE_TYPE ${DEFINE_ICE40_DEVICE_DEVICE_TYPE}
    PACKAGES ${DEFINE_ICE40_DEVICE_PACKAGES}
  )

  add_icebox_layouts(
    DEVICE
    ${DEFINE_ICE40_DEVICE_DEVICE}
    PACKAGES
    ${DEFINE_ICE40_DEVICE_PACKAGES}
  )
endfunction()


define_ice40_device(
  DEVICE
  hx1k
  DEVICE_TYPE
  top-routing-virt
  PACKAGES
  tq144;ct256
)

define_ice40_device(DEVICE lp1k DEVICE_TYPE top-routing-virt PACKAGES qn84)

if (NOT DEFINED ENV{CI} OR NOT $ENV{CI})
define_ice40_device(DEVICE hx8k DEVICE_TYPE top-routing-virt PACKAGES ct256)
define_ice40_device(DEVICE lp8k DEVICE_TYPE top-routing-virt PACKAGES cm81)
define_ice40_device(DEVICE up5k DEVICE_TYPE top-routing-virt PACKAGES sg48)
endif (NOT DEFINED ENV{CI} OR NOT $ENV{CI})
