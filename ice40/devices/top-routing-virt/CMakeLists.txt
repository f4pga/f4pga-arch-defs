add_subdirectory(tiles)

MAKE_FILE_TARGET(
  FILE arch.xml
  SCANNER_TYPE xml
  )

DEFINE_DEVICE_TYPE(
  DEVICE_TYPE top-routing-virt
  ARCH ice40
  ARCH_XML arch.xml
  )
