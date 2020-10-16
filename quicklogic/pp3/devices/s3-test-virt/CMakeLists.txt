add_file_target(FILE arch.xml SCANNER_TYPE xml)

# FIXME: This is hacky. We should have a function called "add_quicklogic_device_define_type" as for XC7

set(SDF_TIMING_DIRECTORY ${symbiflow-arch-defs_SOURCE_DIR}/quicklogic/timings)
set(UPDATE_ARCH_TIMINGS ${symbiflow-arch-defs_SOURCE_DIR}/utils/update_arch_timings.py)
set(PYTHON_SDF_TIMING_DIR ${symbiflow-arch-defs_SOURCE_DIR}/third_party/python-sdf-timing)
set(BELS_MAP ${symbiflow-arch-defs_SOURCE_DIR}/quicklogic/bels.json)

get_target_property(SDF_TIMING_TARGET env SDF_TIMING_TARGET)

set(TIMING_IMPORT "${PYTHON3} ${UPDATE_ARCH_TIMINGS} --sdf_dir ${SDF_TIMING_DIRECTORY} --bels_map ${BELS_MAP} --out_arch /dev/stdout --input_arch /dev/stdin")
set(TIMING_DEPS ${SDF_TIMING_TARGET})

define_device_type(
  DEVICE_TYPE ql-s3-test-virt
  ARCH ql-s3
  ARCH_XML arch.xml
  UPDATE_TILES
  SCRIPT_OUTPUT_NAME timing
  SCRIPTS ${TIMING_IMPORT}
  SCRIPT_DEPS TIMING_DEPS
)
