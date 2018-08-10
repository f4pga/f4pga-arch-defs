add_subdirectory(dummy)
add_file_target(FILE arch.xml SCANNER_TYPE xml)

define_device_type(
  DEVICE_TYPE xc7a50t-roi-virt
  ARCH artix7
  ARCH_XML arch.xml
  )
