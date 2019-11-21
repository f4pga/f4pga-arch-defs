add_file_target(FILE arch.xml SCANNER_TYPE xml)

define_device_type(
  DEVICE_TYPE ql-s3-top-routing-virt
  ARCH ql-s3
  ARCH_XML arch.xml
  UPDATE_TILES
)
