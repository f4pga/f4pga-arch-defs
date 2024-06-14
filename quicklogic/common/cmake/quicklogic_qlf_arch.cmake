function(QUICKLOGIC_DEFINE_QLF_ARCH)
  # ~~~
  # QUICKLOGIC_DEFINE_QLF_ARCH(
  #   FAMILY <family>
  #   ARCH <arch>
  #   VPR_ARGS <VPR args common to the architecture>
  #   ROUTE_CHAN_WIDTH <channel width>
  #
  # The ROUTE_CHAN_WIDTH parameter specifies the channel width for the
  # architecture. It may be overriden per each device.

  set(options)
  set(oneValueArgs FAMILY ARCH ROUTE_CHAN_WIDTH)
  set(multiValueArgs VPR_ARGS)

  cmake_parse_arguments(
    QUICKLOGIC_DEFINE_QLF_ARCH
    "${options}"
    "${oneValueArgs}"
    "${multiValueArgs}"
    ${ARGN}
  )

  set(FAMILY   ${QUICKLOGIC_DEFINE_QLF_ARCH_FAMILY})
  set(ARCH     ${QUICKLOGIC_DEFINE_QLF_ARCH_ARCH})
  set(VPR_ARGS ${QUICKLOGIC_DEFINE_QLF_ARCH_VPR_ARGS})

  set(FAMILY_DIR ${f4pga-arch-defs_SOURCE_DIR}/quicklogic/${FAMILY})

  get_target_property_required(QLF_FASM env QLF_FASM)

  if("${FAMILY}" STREQUAL "qlf_k4n8")
    set(REPACKER_PATH "f4pga utils repack")
  else()
    set(REPACKER_PATH )
  endif()

  set(ARCH_DIR ${QLF_FPGA_PLUGINS_DIR}/${ARCH})
  set(ARCH_DIR_REL ${QLF_FPGA_DATABASE_DIR}/${ARCH})
  set(QLFPGA_FASM_DATABASE_LOC ${ARCH_DIR}/fasm_database)
  set(QLFPGA_FASM_DATABASE_LOC_REL ${f4pga-arch-defs_BINARY_DIR}/${ARCH_DIR_REL}/fasm_database)

  set(FASM_TO_BIT_DEPS "")
  append_file_dependency(FASM_TO_BIT_DEPS /${QLFPGA_FASM_DATABASE_LOC})

  # Define the architecture
  define_arch(
    FAMILY ${FAMILY}
    ARCH ${ARCH}
    YOSYS_TECHMAP ${FAMILY_DIR}/techmap
    DEVICE_FULL_TEMPLATE \${DEVICE}
    VPR_ARCH_ARGS ${VPR_ARGS}
    CELLS_SIM ${FAMILY_DIR}/techmap/cells_sim.v

    RR_GRAPH_EXT ".bin"

    # FIXME: Make common for k4n8 and k6n10
    PLACE_TOOL_CMD "${CMAKE_COMMAND} -E env \
      PYTHONPATH=${f4pga-arch-defs_SOURCE_DIR}/utils:$PYTHONPATH:${f4pga-arch-defs_SOURCE_DIR}/quicklogic/common/utils \
      f4pga utils create_ioplace \
          --pinmap_xml \${PINMAP_XML} \
          --blif \${OUT_EBLIF} \
          --pcf \${INPUT_IO_FILE} \
          --net \${OUT_NET} \
          --csv_file \${PINMAP}"

    NO_TEST_PINS
    NO_PLACE_CONSTR

    SDC_PATCH_TOOL
      ${SDC_PATCH_TOOL}
    SDC_PATCH_TOOL_CMD "${CMAKE_COMMAND} -E env \
      PYTHONPATH=${f4pga-arch-defs_SOURCE_DIR}/utils \
      \${QUIET_CMD} \${PYTHON3} \${SDC_PATCH_TOOL} \
         --sdc-in \${IN_SDC} \
         --pcf \${INPUT_IO_FILE} \
         --eblif \${OUT_EBLIF} \
         --pin-map \${PINMAP} \
         --sdc-out \${OUT_SDC}"

    NET_PATCH_TOOL
      ${REPACKER_PATH}
    # FIXME: change FPGA_FAM definition once qlf_k4n8 is supported in f4pba build flow
    NET_PATCH_TOOL_CMD "${CMAKE_COMMAND} -E env \
      PYTHONPATH=${f4pga-arch-defs_SOURCE_DIR}/utils \
      FPGA_FAM=eos-s3 \
      \${QUIET_CMD} \${NET_PATCH_TOOL} \
         --net-in \${IN_NET} \
         --eblif-in \${IN_EBLIF} \
         --place-in \${IN_PLACE} \
         --net-out \${OUT_NET} \
         --eblif-out \${OUT_EBLIF} \
         --place-out \${OUT_PLACE} \
         --vpr-arch \${VPR_ARCH} \
         --log \${OUT_NET}.log \
         --log-level DEBUG \
         --absorb_buffer_luts on"

    BITSTREAM_EXTENSION bit
    FASM_TO_BIT ${QLF_FASM}
    FASM_TO_BIT_CMD "${CMAKE_COMMAND} -E env \
      PYTHONPATH=${f4pga-arch-defs_BINARY_DIR}/env/conda/lib/python3.7/site-packages \
      \${QUIET_CMD} \${FASM_TO_BIT} \
        --db-root ${QLFPGA_FASM_DATABASE_LOC_REL} \
        --assemble \
        --format 4byte \
        \${OUT_FASM} \
        \${OUT_BITSTREAM} "
    FASM_TO_BIT_DEPS ${FASM_TO_BIT_DEPS}

    BIN_EXTENSION bin
    BIT_TO_BIN ${QLF_FASM}
    BIT_TO_BIN_CMD "${CMAKE_COMMAND} -E env \
      PYTHONPATH=${f4pga-arch-defs_BINARY_DIR}/env/conda/lib/python3.7/site-packages \
      \${QUIET_CMD} \${FASM_TO_BIT} \
        --db-root ${QLFPGA_FASM_DATABASE_LOC_REL} \
        --assemble \
        --format txt \
        \${OUT_FASM} \
        \${OUT_BIN} "

    BIT_TO_FASM ${QLF_FASM}
    BIT_TO_FASM_CMD "${CMAKE_COMMAND} -E env \
      PYTHONPATH=${f4pga-arch-defs_BINARY_DIR}/env/conda/lib/python3.7/site-packages \
      \${QUIET_CMD} \${BIT_TO_FASM} \
        --db-root ${QLFPGA_FASM_DATABASE_LOC_REL} \
        --disassemble \
        --format 4byte \
        \${OUT_BITSTREAM} \
        \${OUT_BIT_FASM} "

    NO_BIT_TO_V
    NO_BIT_TIME
    USE_FASM

    ROUTE_CHAN_WIDTH ${QUICKLOGIC_DEFINE_QLF_ARCH_ROUTE_CHAN_WIDTH}
  )

endfunction()
