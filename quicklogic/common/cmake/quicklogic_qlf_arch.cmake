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

  set(FAMILY_DIR ${symbiflow-arch-defs_SOURCE_DIR}/quicklogic/${FAMILY})

  # Define the architecture
  define_arch(
    FAMILY ${FAMILY}
    ARCH ${ARCH}
    YOSYS_SYNTH_SCRIPT ${FAMILY_DIR}/yosys/synth.tcl
    YOSYS_CONV_SCRIPT ${FAMILY_DIR}/yosys/conv.tcl
    YOSYS_TECHMAP ${FAMILY_DIR}/techmap
    DEVICE_FULL_TEMPLATE \${DEVICE}
    VPR_ARCH_ARGS ${VPR_ARGS}
    CELLS_SIM ${FAMILY_DIR}/techmap/cells_sim.v

    RR_GRAPH_EXT ".bin"

    PLACE_TOOL
      ${symbiflow-arch-defs_SOURCE_DIR}/quicklogic/${FAMILY}/utils/create_ioplace.py
    PLACE_TOOL_CMD "${CMAKE_COMMAND} -E env \
      PYTHONPATH=${symbiflow-arch-defs_SOURCE_DIR}/utils:$PYTHONPATH:${symbiflow-arch-defs_SOURCE_DIR}/quicklogic/common/utils \
      \${PYTHON3} \${PLACE_TOOL} \
          --pinmap_xml \${PINMAP_XML} \
          --blif \${OUT_EBLIF} \
          --pcf \${INPUT_IO_FILE} \
          --net \${OUT_NET} \
          --csv_file \${PINMAP}"

    NO_TEST_PINS
    NO_PLACE_CONSTR

    NET_PATCH_TOOL
      ${symbiflow-arch-defs_SOURCE_DIR}/quicklogic/qlf_k4n8/utils/repacker/repack.py
    NET_PATCH_TOOL_CMD "${CMAKE_COMMAND} -E env \
     PYTHONPATH=${symbiflow-arch-defs_SOURCE_DIR}/utils \
     \${PYTHON3} \${NET_PATCH_TOOL} \
         --net-in \${IN_NET} \
         --eblif-in \${IN_EBLIF} \
         --place-in \${IN_PLACE} \
         --net-out \${OUT_NET} \
         --eblif-out \${OUT_EBLIF} \
         --place-out \${OUT_PLACE} \
         --vpr-arch \${VPR_ARCH} \
         --absorb_buffer_luts on"

    # With the current support there is no bitstream generation support yet.
    # A FASM file can be generated though but FASM annotation is also a subject
    # to change.
    NO_BITSTREAM

    NO_BIT_TO_BIN
    NO_BIT_TO_V
    NO_BIT_TIME
    USE_FASM

    ROUTE_CHAN_WIDTH ${QUICKLOGIC_DEFINE_QLF_ARCH_ROUTE_CHAN_WIDTH}
  )

endfunction()
