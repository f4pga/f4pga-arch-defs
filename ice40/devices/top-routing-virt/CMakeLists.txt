add_subdirectory(tiles)

add_file_target(FILE arch.xml SCANNER_TYPE xml)

get_target_property_required(CONDA_DIR env CONDA_DIR)
get_target_property_required(PYTHON3 env PYTHON3)
get_target_property_required(PYTHON3_TARGET env PYTHON3_TARGET)
get_target_property_required(ICESTORM_TARGET env ICESTORM_TARGET)

set(ICEBOX_TIMING ${symbiflow-arch-defs_SOURCE_DIR}/third_party/icestorm/icefuzz/timings.py)
set(CLEAN_ICEBOX_TIMING cleaned_timing.txt)
set(TIMING_TXT_FILE ${ICEBOX_SHARE}/timings_hx1k.txt)
set(SDF_FILE timings_hx1k.sdf)

add_custom_command(
  OUTPUT ${SDF_FILE}
  COMMAND grep -v \\* ${TIMING_TXT_FILE} > ${CLEAN_ICEBOX_TIMING}
  COMMAND ${PYTHON3} ${ICEBOX_TIMING} -t ${CLEAN_ICEBOX_TIMING} -s > ${SDF_FILE}
  BYPRODUCTS ${CLEAN_ICEBOX_TIMING}
  DEPENDS ${TIMING_TXT_FILE} ${ICESTORM_TARGET} ${ICEBOX_TIMING} ${PYTHON3} ${PYTHON3_TARGET}
  )

add_custom_target(
  ice40_sdf_target
  DEPENDS ${SDF_FILE}
  )
get_target_property_required(ICE40_IMPORT_TIMING ice40_import_timing_deps ICE40_IMPORT_TIMING)
set(TIMING_IMPORT_CMD "${PYTHON3} ${ICE40_IMPORT_TIMING} --read_sdf ${SDF_FILE} --write_arch_xml /dev/stdout --read_arch_xml /dev/stdin")

define_device_type(
  DEVICE_TYPE top-routing-virt
  ARCH ice40
  ARCH_XML arch.xml
  SCRIPT_OUTPUT_NAME timing
  SCRIPTS ${TIMING_IMPORT_CMD}
  UPDATE_TILES
  )

add_dependencies(ice40_top-routing-virt_arch ice40_import_timing_deps ice40_sdf_target)
get_target_property_required(VIRT_DEVICE_MERGED_FILE top-routing-virt DEVICE_MERGED_FILE)
get_file_target(DEVICE_MERGED_FILE_TARGET ${VIRT_DEVICE_MERGED_FILE})
add_dependencies(${DEVICE_MERGED_FILE_TARGET} ice40_import_timing_deps ice40_sdf_target)
