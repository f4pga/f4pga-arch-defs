add_file_target(FILE arch.xml SCANNER_TYPE xml)

define_device_type(
  DEVICE_TYPE clutff-unidir-s4
  ARCH testarch
  ARCH_XML arch.xml
  UPDATE_TILES
  )
