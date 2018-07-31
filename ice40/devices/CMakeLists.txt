add_subdirectory(layouts)
add_subdirectory(top-routing-virt)

function(DEFINE_ICE40_DEVICE)
  set(options)
  set(oneValueArgs DEVICE DEVICE_TYPE PACKAGES)
  set(multiValueArgs)
  cmake_parse_arguments(DEFINE_ICE40_DEVICE "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

  DEFINE_DEVICE(
    DEVICE ${DEFINE_ICE40_DEVICE_DEVICE}
    ARCH ice40
    DEVICE_TYPE ${DEFINE_ICE40_DEVICE_DEVICE_TYPE}
    PACKAGES ${DEFINE_ICE40_DEVICE_PACKAGES}
    )

  ADD_ICEBOX_LAYOUTS(
    DEVICE ${DEFINE_ICE40_DEVICE_DEVICE}
    PACKAGES ${DEFINE_ICE40_DEVICE_PACKAGES}
    )
endfunction()

DEFINE_ICE40_DEVICE(
  DEVICE hx8k
  DEVICE_TYPE top-routing-virt
  PACKAGES ct256
  )

DEFINE_ICE40_DEVICE(
  DEVICE hx1k
  DEVICE_TYPE top-routing-virt
  PACKAGES tq144;ct256
  )

DEFINE_ICE40_DEVICE(
  DEVICE lp1k
  DEVICE_TYPE top-routing-virt
  PACKAGES qn84
  )

DEFINE_ICE40_DEVICE(
  DEVICE lp8k
  DEVICE_TYPE top-routing-virt
  PACKAGES cm81
  )

DEFINE_ICE40_DEVICE(
  DEVICE up5k
  DEVICE_TYPE top-routing-virt
  PACKAGES sg48
  )
