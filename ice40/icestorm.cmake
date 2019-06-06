function(icestorm_setup)
  get_target_property_required(PYTHON3 env PYTHON3)

  set(ICESTORM_SRC ${symbiflow-arch-defs_SOURCE_DIR}/third_party/icestorm CACHE PATH "Path to icestorm repository")
  set(PYUTILS_PATH ${symbiflow-arch-defs_SOURCE_DIR}/utils:${symbiflow-arch-defs_SOURCE_DIR}/ice40/utils/fasm_icebox)

  get_target_property_required(PYTHON_PREFIX env CONDA_DIR)
  set(ICESTORM_PREFIX "PREFIX=${PYTHON_PREFIX}")

  add_conda_package(
    NAME pkg-config
    PROVIDES pkg-config
    )
  add_conda_package(
    NAME libftdi
    NO_EXE
    )
  get_target_property(LIBFTDI_TARGET env LIBFTDI_TARGET)

  add_conda_pip(
    NAME numpy
    NO_EXE
    )

  add_thirdparty_package(
    NAME fasm
    BUILD_INSTALL_COMMAND "cd ${symbiflow-arch-defs_SOURCE_DIR}/third_party/fasm && ${PYTHON3} setup.py develop"
    PROVIDES fasm
    )

  get_target_property(FASM_TARGET env FASM_TARGET)

  set(FASM2ASC ${symbiflow-arch-defs_SOURCE_DIR}/ice40/utils/fasm_icebox/fasm2asc.py)
  add_custom_target(
    fasm2asc_deps
    DEPENDS numpy ${FASM_TARGET} ${FASM2ASC}
    )

  get_target_property(SDF_TIMING_TARGET env SDF_TIMING_TARGET)
  set(ICE40_IMPORT_TIMING ${symbiflow-arch-defs_SOURCE_DIR}/ice40/utils/ice40_import_bel_timing.py)
  add_custom_target(
    ice40_import_timing_deps
    DEPENDS ${ICE40_IMPORT_TIMING} ${SDF_TIMING_TARGET}
    )

  get_target_property_required(PKG-CONFIG env PKG-CONFIG)
  get_target_property_required(PKG-CONFIG_TARGET env PKG-CONFIG_TARGET)

  add_thirdparty_package(
    NAME icestorm
    PROVIDES iceprog icebox_hlc2asc icebox_vlog icepack icetime icebox
    BUILD_INSTALL_COMMAND "make -C ${ICESTORM_SRC} ${ICESTORM_PREFIX} PKG_CONFIG=${PKG-CONFIG} install"
    DEPENDS ${LIBFTDI_TARGET} ${PKG-CONFIG_TARGET}
    )

  get_target_property_required(ICEBOX_VLOG env ICEBOX_VLOG)
  get_target_property_required(ICEPACK env ICEPACK)
  get_target_property_required(ICETIME env ICETIME)
  get_target_property_required(ICEBOX_HLC2ASC env ICEBOX_HLC2ASC)

  get_target_property_required(ICEBOX_VLOG_TARGET env ICEBOX_VLOG_TARGET)
  get_target_property_required(ICEPACK_TARGET env ICEPACK_TARGET)
  get_target_property_required(ICETIME_TARGET env ICETIME_TARGET)
  get_target_property_required(ICEBOX_HLC2ASC_TARGET env ICEBOX_HLC2ASC_TARGET)

  get_target_property_required(ICEBOX env ICEBOX)
  get_filename_component(ICEBOX_PATH ${ICEBOX} DIRECTORY)
  set(ICEBOX_SHARE ${ICEBOX_PATH}/../share/icebox CACHE PATH "")
  message("elms ${ICEBOX_PATH} ${ICEBOX_SHARE}")

  set(PYPATH_ARG "PYTHONPATH=\${ICEBOX_PATH}:${PYUTILS_PATH}")
  define_arch(
    ARCH ice40
    YOSYS_SCRIPT ${symbiflow-arch-defs_SOURCE_DIR}/ice40/yosys/synth.tcl
    DEVICE_FULL_TEMPLATE \${DEVICE}-\${PACKAGE}
    VPR_ARCH_ARGS
      --clock_modeling route
      --allow_unrelated_clustering off
      --target_ext_pin_util 0.7
      --router_init_wirelength_abort_threshold 2
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
    FASM_TO_BIT fasm2asc_deps
    FASM_TO_BIT_CMD "\${QUIET_CMD}  \${CMAKE_COMMAND} -E env  ${PYPATH_ARG} \
    \${PYTHON3} ${FASM2ASC} --device \${DEVICE} \${OUT_FASM} \${OUT_BITSTREAM}"
    USE_FASM
    ROUTE_CHAN_WIDTH 100
  )

endfunction()
