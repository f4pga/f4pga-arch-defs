function(icestorm_setup)
  get_target_property_required(PYTHON3 env PYTHON3)

  set(ICESTORM_SRC ${symbiflow-arch-defs_SOURCE_DIR}/third_party/icestorm CACHE PATH "Path to icestorm repository")
  set(PYUTILS_PATH ${symbiflow-arch-defs_SOURCE_DIR}/utils CACHE PATH "Path to python utils")

  get_target_property_required(PYTHON_PREFIX env CONDA_DIR)
  set(ICESTORM_PREFIX "PREFIX=${PYTHON_PREFIX}")

  add_thirdparty_package(
    NAME icestorm
    PROVIDES iceprog icebox_hlc2asc icebox_vlog icepack icetime icebox
    BUILD_INSTALL_COMMAND "make -C ${ICESTORM_SRC} ${ICESTORM_PREFIX} install"
  )

  get_target_property(ICEBOX_VLOG env ICEBOX_VLOG)
  get_target_property(ICEPACK env ICEPACK)
  get_target_property(ICETIME env ICETIME)
  get_target_property(ICEBOX_HLC2ASC env ICEBOX_HLC2ASC)

  get_target_property(ICEBOX_VLOG_TARGET env ICEBOX_VLOG_TARGET)
  get_target_property(ICEPACK_TARGET env ICEPACK_TARGET)
  get_target_property(ICETIME_TARGET env ICETIME_TARGET)
  get_target_property(ICEBOX_HLC2ASC_TARGET env ICEBOX_HLC2ASC_TARGET)

  get_target_property(ICEBOX env ICEBOX)
  get_filename_component(ICEBOX_PATH ${ICEBOX} DIRECTORY)

  set(PYPATH_ARG "PYTHONPATH=\${ICEBOX_PATH}:${PYUTILS_PATH}" CACHE STRING "environment variables for python namely PYTHONPATH")
  define_arch(
    ARCH ice40
    YOSYS_SCRIPT ${symbiflow-arch-defs_SOURCE_DIR}/ice40/yosys/synth.tcl
    DEVICE_FULL_TEMPLATE \${DEVICE}-\${PACKAGE}
    VPR_ARCH_ARGS
      --clock_modeling route
      --allow_unrelated_clustering off
      --target_ext_pin_util 0.7
    RR_PATCH_TOOL
      ${symbiflow-arch-defs_SOURCE_DIR}/ice40/utils/ice40_import_routing_from_icebox.py
    RR_PATCH_CMD "\${QUIET_CMD} \${CMAKE_COMMAND} -E env ${PYPATH_ARG} \
    \${PYTHON3} \${RR_PATCH_TOOL} \
    --device=\${DEVICE} \
    --read_rr_graph \${OUT_RRXML_VIRT} \
    --write_rr_graph \${OUT_RRXML_REAL}"
    PLACE_TOOL
      ${symbiflow-arch-defs_SOURCE_DIR}/ice40/utils/ice40_create_ioplace.py
    PLACE_TOOL_CMD "\${QUIET_CMD}  \${CMAKE_COMMAND} -E env  ${PYPATH_ARG} \
    \${PYTHON3} \${PLACE_TOOL} \
    --map \${PINMAP} \
    --blif \${OUT_EBLIF} \
    --pcf \${INPUT_IO_FILE}"
    CELLS_SIM ${YOSYS_DATADIR}/ice40/cells_sim.v
    BIT_TO_V ${ICEBOX_VLOG_TARGET}
    BIT_TO_V_CMD "${ICEBOX_VLOG} -D -c -n \${TOP} -p \${INPUT_IO_FILE} -d \${PACKAGE} \${OUT_BITSTREAM} > \${OUT_BIT_VERILOG}"
    BITSTREAM_EXTENSION asc
    BIT_TO_BIN ${ICEPACK_TARGET}
    BIT_TO_BIN_CMD "${ICEPACK} \${OUT_BITSTREAM} > \${OUT_BIN}"
    BIT_TIME ${ICETIME_TARGET}
    BIN_EXTENSION bin
    BIT_TIME_CMD "${ICETIME} -v -t -p \${INPUT_IO_FILE} -d \${DEVICE} \${OUT_BITSTREAM} -o \${OUT_TIME_VERILOG}"
    HLC_TO_BIT ${ICEBOX_HLC2ASC_TARGET}
    HLC_TO_BIT_CMD "${ICEBOX_HLC2ASC} \${OUT_HLC} > \${OUT_BITSTREAM}"
    ROUTE_CHAN_WIDTH 100
  )

endfunction()

icestorm_setup()

add_subdirectory(primitives)
add_subdirectory(cells)
add_subdirectory(devices)
include(boards.cmake)

add_subdirectory(tests)
