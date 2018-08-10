add_subdirectory(tiles)

add_file_target(FILE arch.xml SCANNER_TYPE xml)
define_device_type(DEVICE_TYPE top-routing-virt ARCH ice40 ARCH_XML arch.xml)
