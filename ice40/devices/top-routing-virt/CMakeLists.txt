add_subdirectory(tiles)

add_file_target(FILE arch.xml SCANNER_TYPE xml)

set(SDF_FILE ${CMAKE_SOURCE_DIR}/timings_hx1k.sdf)
set(TIMING_IMPORT_CMD "${CMAKE_SOURCE_DIR}/ice40/utils/ice40_import_bel_timing.py --read_sdf ${SDF_FILE} --write_arch_xml /dev/stdout --read_arch_xml")

define_device_type(
  DEVICE_TYPE top-routing-virt
  ARCH ice40
  ARCH_XML arch.xml
  SCRIPT_OUTPUT_NAME timing
  SCRIPTS ${TIMING_IMPORT_CMD}
  )

add_dependencies(ice40_top-routing-virt_arch  ice40_import_timing_deps)
