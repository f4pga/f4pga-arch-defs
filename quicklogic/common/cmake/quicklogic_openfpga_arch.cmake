function(QUICKLOGIC_DEFINE_OPENFPGA_ARCH)
  # ~~~
  # QUICKLOGIC_DEFINE_OPENFPGA_ARCH(
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
    QUICKLOGIC_DEFINE_OPENFPGA_ARCH
    "${options}"
    "${oneValueArgs}"
    "${multiValueArgs}"
    ${ARGN}
  )

  set(FAMILY   ${QUICKLOGIC_DEFINE_OPENFPGA_ARCH_FAMILY})
  set(ARCH     ${QUICKLOGIC_DEFINE_OPENFPGA_ARCH_ARCH})
  set(VPR_ARGS ${QUICKLOGIC_DEFINE_OPENFPGA_ARCH_VPR_ARGS})

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

    RR_PATCH_TOOL
      ${symbiflow-arch-defs_SOURCE_DIR}/quicklogic/openfpga/utils/fixup_rr_graph.py
    RR_PATCH_CMD "\${CMAKE_COMMAND} -E env \
      PYTHONPATH=${symbiflow-arch-defs_SOURCE_DIR}/utils:$PYTHONPATH:${symbiflow-arch-defs_SOURCE_DIR}/quicklogic/common/utils \
      \${PYTHON3} \${RR_PATCH_TOOL} \
          --rr-graph-in \${OUT_RRXML_VIRT} \
          --rr-graph-out \${OUT_RRXML_REAL}"
  
    NO_PINS
    NO_PLACE 
#    PLACE_TOOL
#      ${symbiflow-arch-defs_SOURCE_DIR}/quicklogic/common/utils/create_ioplace.py
#    PLACE_TOOL_CMD "${CMAKE_COMMAND} -E env \
#      PYTHONPATH=${symbiflow-arch-defs_SOURCE_DIR}/utils:$PYTHONPATH \
#      \${PYTHON3} \${PLACE_TOOL} \
#          --map \${PINMAP} \
#          --blif \${OUT_EBLIF} \
#          --pcf \${INPUT_IO_FILE} \
#          --net \${OUT_NET}"

    NO_PLACE_CONSTR  
#    PLACE_CONSTR_TOOL
#      ${symbiflow-arch-defs_SOURCE_DIR}/quicklogic/common/utils/create_place_constraints.py
#    PLACE_CONSTR_TOOL_CMD "${CMAKE_COMMAND} -E env \
#      PYTHONPATH=${symbiflow-arch-defs_SOURCE_DIR}/utils \
#      \${PYTHON3} \${PLACE_CONSTR_TOOL} \
#          --family ${FAMILY_NAME} \
#          --map ${symbiflow-arch-defs_BINARY_DIR}/quicklogic/${FAMILY_NAME}/\${BOARD}_clkmap.csv \
#          --blif \${OUT_EBLIF} \
#          --i /dev/stdin \
#          --o /dev/stdout \
#          \${PLACE_CONSTR_TOOL_EXTRA_ARGS}"
  
    NO_BITSTREAM  
#    FASM_TO_BIT
#      ${QLFASM}
#    FASM_TO_BIT_CMD "\${PYTHON3} \
#      \${QLFASM} \
#          \${OUT_FASM}
#          \${OUT_BITSTREAM}
#          \${FASM_TO_BIT_EXTRA_ARGS}"
#    FASM_TO_BIT_DEPS
#      ${QLFASM_TARGET}
#    BITSTREAM_EXTENSION bit
  
    NO_BIT_TO_BIN
    NO_BIT_TO_V
    NO_BIT_TIME
    USE_FASM

    ROUTE_CHAN_WIDTH ${QUICKLOGIC_DEFINE_OPENFPGA_ARCH_ROUTE_CHAN_WIDTH}
  )

#  # Define toolchain installation target
#  define_ql_toolchain_target(
#    FAMILY ap3
#    ARCH ql-ap3
#    ROUTE_CHAN_WIDTH 100
#    CELLS_SIM ${CELLS_SIM_FILE}
#    VPR_ARCH_ARGS ${VPR_AP3_ARCH_ARGS}
#    CONV_SCRIPT ${YOSYS_CONV_SCRIPT}
#    SYNTH_SCRIPT ${YOSYS_SYNTH_SCRIPT}
#  )

endfunction()
