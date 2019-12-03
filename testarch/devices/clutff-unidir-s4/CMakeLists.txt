add_file_target(FILE arch.xml SCANNER_TYPE xml)

set(UPDATE_TILES "${symbiflow-arch-defs_SOURCE_DIR}/utils/update_arch_tiles.py")
set(UPDATE_TILES_CMD "${PYTHON3} ${UPDATE_TILES} --in_xml /dev/stdin --out_xml /dev/stdout")
set(UPDATE_TILES_DEPS "")

define_device_type(
  DEVICE_TYPE clutff-unidir-s4
  ARCH testarch
  ARCH_XML arch.xml
  SCRIPT_OUTPUT_NAME tiles
  SCRIPT_DEPS UPDATE_TILES_DEPS
  SCRIPTS UPDATE_TILES_CMD
  )
