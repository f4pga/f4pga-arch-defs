add_subdirectory(tiles)

add_file_target(FILE arch.xml SCANNER_TYPE xml)

get_target_property_required(CONDA_DIR env CONDA_DIR)
get_target_property_required(PYTHON3 env PYTHON3)

set(ICEBOX_TIMING ${symbiflow-arch-defs_SOURCE_DIR}/third_party/icestorm/icefuzz/timings.py)
set(CLEAN_ICEBOX_TIMING cleaned_timing.txt)
set(TIMING_TXT_FILE ${ICEBOX_SHARE}/timings_hx1k.txt)
set(SDF_FILE timings_hx1k.sdf)

add_custom_command(
  OUTPUT ${CLEAN_ICEBOX_TIMING}
  COMMAND grep -v \\* ${TIMING_TXT_FILE} > ${CLEAN_ICEBOX_TIMING}
  DEPENDS ${TIMING_TXT_FILE} thirdparty_icestorm
  )

add_custom_command(
  OUTPUT ${SDF_FILE}
  COMMAND ${PYTHON3} ${ICEBOX_TIMING} -t ${CLEAN_ICEBOX_TIMING} -s > ${SDF_FILE}
  DEPENDS ${ICEBOX_TIMING} ${CLEAN_ICEBOX_TIMING}
  )

add_custom_target(
  sdf_target
  DEPENDS ${SDF_FILE}
  )

get_target_property_required(PYTHON3 env PYTHON3)
set(TIMING_IMPORT_CMD "${PYTHON3} ${CMAKE_SOURCE_DIR}/ice40/utils/ice40_import_bel_timing.py --read_sdf ${SDF_FILE} --write_arch_xml /dev/stdout --read_arch_xml /dev/stdin")

define_device_type(
  DEVICE_TYPE top-routing-virt
  ARCH ice40
  ARCH_XML arch.xml
  SCRIPT_OUTPUT_NAME timing
  SCRIPTS ${TIMING_IMPORT_CMD}
  )

add_dependencies(ice40_top-routing-virt_arch ice40_import_timing_deps sdf_target)
get_target_property_required(VIRT_DEVICE_MERGED_FILE top-routing-virt DEVICE_MERGED_FILE)
get_file_target(DEVICE_MERGED_FILE_TARGET ${VIRT_DEVICE_MERGED_FILE})
add_dependencies(${DEVICE_MERGED_FILE_TARGET} ice40_import_timing_deps sdf_target)
