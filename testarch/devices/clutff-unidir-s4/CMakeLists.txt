add_file_target(FILE arch.xml SCANNER_TYPE xml)

get_target_property_required(PYTHON3 env PYTHON3)

set(UPDATE_TILES "${symbiflow-arch-defs_SOURCE_DIR}/utils/update_arch_tiles.py")
set(UPDATE_TILES_CMD "${PYTHON3} ${UPDATE_TILES} --in_xml /dev/stdin --out_xml /dev/stdout")

get_file_target(UPDATE_TILES_TARGET ${UPDATE_TILES})
set(UPDATE_TILES_DEPS ${UPDATE_TILES_TARGET})

define_device_type(
  DEVICE_TYPE clutff-unidir-s4
  ARCH testarch
  ARCH_XML arch.xml
  SCRIPT_OUTPUT_NAME tiles
  SCRIPT_DEPS UPDATE_TILES_DEPS
  SCRIPTS UPDATE_TILES_CMD
  )
