add_conda_pip(
  NAME termcolor
  NO_EXE
)

get_target_property_required(PYTHON3 env PYTHON3)
get_target_property_required(PYTHON3_TARGET env PYTHON3_TARGET)

get_target_property_required(TERMCOLOR_TARGET env TERMCOLOR_TARGET)
get_target_property_required(SDF_TIMING_TARGET env SDF_TIMING_TARGET)

# Add the timing importer utility
add_thirdparty_package(
  NAME quicklogic_timings_importer
  PROVIDES quicklogic_timings_importer
  BUILD_INSTALL_COMMAND "cd ${symbiflow-arch-defs_SOURCE_DIR}/quicklogic/common/utils/quicklogic-timings-importer && ${PYTHON3} setup.py develop"
  DEPENDS ${PYTHON3} ${PYTHON3_TARGET} ${TERMCOLOR_TARGET} ${SDF_TIMING_TARGET}
)
