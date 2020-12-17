include(install.cmake)

function(ADD_XC_ARCH_DEFINE)
  # ~~~
  # ADD_XC_ARCH_DEFINE(
  #   FAMILY <family>
  #   PRJRAY_DIR <documentation project dir>
  #   PRJRAY_DB_DIR <documentation project database dir>
  #   ARCH <arch>
  #   PRJRAY_ARCH <prjray_arch>
  #   PROTOTYPE_PART <prototype_part>
  #   YOSYS_SYNTH_SCRIPT <yosys_script>
  #   YOSYS_CONV_SCRIPT <yosys_script>
  #   YOSYS_UTILS_SCRIPT <yosys_script>
  #   )
  #
  # FAMILY: The family the architecture is belonging to (e.g. xc7).
  #
  # ARCH: The architecture to add (e.g. artix7).
  #
  # PRJRAY_ARCH: The architecture in PRJRAY that holds all the part data that need to be imported.
  #
  # PROTOTYPE_PART: The PART that is valid for all the different PARTs having the same ARCH.
  set(options)
  set(oneValueArgs
        FAMILY
        ARCH
        PRJRAY_ARCH
        PRJRAY_DIR
        PRJRAY_DB_DIR
        PRJRAY_NAME
        PROTOTYPE_PART
        YOSYS_SYNTH_SCRIPT
        YOSYS_CONV_SCRIPT
        YOSYS_UTILS_SCRIPT)
  set(multiValueArgs)
  cmake_parse_arguments(
    ADD_XC_ARCH_DEFINE
    "${options}"
    "${oneValueArgs}"
    "${multiValueArgs}"
    ${ARGN}
  )

  # The default IOSTANDARD and DRIVE to use in fasm2bels
  set(DEFAULT_IOSTANDARD "LVCMOS33")
  set(DEFAULT_DRIVE 12)

  set(FAMILY ${ADD_XC_ARCH_DEFINE_FAMILY})
  set(ARCH ${ADD_XC_ARCH_DEFINE_ARCH})
  if("${ADD_XC_ARCH_DEFINE_PRJRAY_ARCH}" STREQUAL "")
      set(PRJRAY_ARCH "${ARCH}")
  else()
      set(PRJRAY_ARCH "${ADD_XC_ARCH_DEFINE_PRJRAY_ARCH}")
  endif()
  set(PRJRAY_DIR ${ADD_XC_ARCH_DEFINE_PRJRAY_DIR})
  set(PRJRAY_DB_DIR ${ADD_XC_ARCH_DEFINE_PRJRAY_DB_DIR})
  set(PRJRAY_NAME ${ADD_XC_ARCH_DEFINE_PRJRAY_NAME})
  set(PROTOTYPE_PART ${ADD_XC_ARCH_DEFINE_PROTOTYPE_PART})
  set(YOSYS_SYNTH_SCRIPT ${ADD_XC_ARCH_DEFINE_YOSYS_SYNTH_SCRIPT})
  set(YOSYS_CONV_SCRIPT ${ADD_XC_ARCH_DEFINE_YOSYS_CONV_SCRIPT})
  set(YOSYS_UTILS_SCRIPT ${ADD_XC_ARCH_DEFINE_YOSYS_UTILS_SCRIPT})
  set(YOSYS_TECHMAP ${symbiflow-arch-defs_SOURCE_DIR}/xc/${FAMILY}/techmap)

  # Notes on optimized flag settings:
  # These flags have been optimized for the ibex and baselitex designs.
  # - place_delay_model: delta is ~5% faster than delta_override (default: delta)
  # - acc_fac: Lowering this to 0.7 slightly improves runtime 1-4% (default: 1)
  # - astar_fac: Increasing this to 1.8 reduces runtime 2-15% (default: 1.2)
  # - initial_pres_fac: Setting this to 2.828 reduces runtime 10-20% from the default,
  #   and about 3% faster than the previous value of 4 (default: 0.5)
  # - pres_fac_mult: A lower value of 1.2 performs better given the other parameters (default: 1.3)
  # Based on analysis performed on hydra.vtr.tools for the ibex, baselitex, and bram-n3 designs.
  # These changes did not have a measurable effect on QoR for these designs.
  # More details can be found in the report: https://colab.research.google.com/drive/1X91RGZnvlC7dBjJJUbS7JfqCbPCzJ3Xb
  # Also checked in at: utils/ipynb/Parameter_Sweep_using_fpga_tool_perf.ipynb
  set(VPR_ARCH_ARGS "\
      --router_heap bucket \
      --clock_modeling route \
      --place_delta_delay_matrix_calculation_method dijkstra \
      --place_delay_model delta \
      --router_lookahead extended_map \
      --check_route quick \
      --strict_checks off \
      --allow_dangling_combinational_nodes on \
      --disable_errors check_unbuffered_edges:check_route \
      --congested_routing_iteration_threshold 0.8 \
      --incremental_reroute_delay_ripup off \
      --base_cost_type delay_normalized_length_bounded \
      --bb_factor 10 \
      --acc_fac 0.7 \
      --astar_fac 1.8 \
      --initial_pres_fac 2.828 \
      --pres_fac_mult 1.2 \
      --check_rr_graph off \
      --suppress_warnings \${OUT_NOISY_WARNINGS},sum_pin_class:check_unbuffered_edges:load_rr_indexed_data_T_values:check_rr_node:trans_per_R:check_route:set_rr_graph_tool_comment:calculate_average_switch"
      )

  set(YOSYS_CELLS_SIM ${YOSYS_DATADIR}/xilinx/cells_sim.v)
  set(VPR_CELLS_SIM ${symbiflow-arch-defs_SOURCE_DIR}/xc/${FAMILY}/techmap/cells_sim.v)

  get_file_target(YOSYS_CELLS_SIM_TARGET ${YOSYS_CELLS_SIM})
  if (NOT TARGET ${YOSYS_CELLS_SIM_TARGET})
    add_file_target(FILE ${YOSYS_CELLS_SIM} ABSOLUTE)
  endif ()

  get_file_target(VPR_CELLS_SIM_TARGET ${VPR_CELLS_SIM})
  if (NOT TARGET ${VPR_CELLS_SIM_TARGET})
      add_file_target(FILE ${VPR_CELLS_SIM} ABSOLUTE)
  endif ()

  get_target_property_required(XCFASM env XCFASM)
  get_target_property_required(XC7FRAMES2BIT env XC7FRAMES2BIT)
  get_target_property_required(BITREAD env BITREAD)


  get_target_property_required(RAPIDWRIGHT_INSTALLED rapidwright RAPIDWRIGHT_INSTALLED)
  if(${RAPIDWRIGHT_INSTALLED})
    get_target_property_required(RAPIDWRIGHT_PATH rapidwright RAPIDWRIGHT_PATH)
    set(INTERCHANGE_FASM2BELS "--interchange_capnp_schema_dir ${RAPIDWRIGHT_PATH}/interchange
            --logical_netlist \${OUT_BIT_VERILOG}.netlist
            --physical_netlist \${OUT_BIT_VERILOG}.phys
            --interchange_xdc \${OUT_BIT_VERILOG}.inter.xdc")
  else()
    set(INTERCHANGE_FASM2BELS)
  endif()

  define_arch(
    ARCH ${ARCH}
    FAMILY ${FAMILY}
    DOC_PRJ ${PRJRAY_DIR}
    DOC_PRJ_DB ${PRJRAY_DB_DIR}
    DOC_PRJ_NAME ${PRJRAY_NAME}
    PROTOTYPE_PART ${PROTOTYPE_PART}
    YOSYS_SYNTH_SCRIPT ${YOSYS_SYNTH_SCRIPT}
    YOSYS_TECHMAP ${YOSYS_TECHMAP}
    YOSYS_CONV_SCRIPT ${YOSYS_CONV_SCRIPT}
    DEVICE_FULL_TEMPLATE \${DEVICE}-\${PACKAGE}
    CELLS_SIM ${YOSYS_CELLS_SIM} ${VPR_CELLS_SIM}
    VPR_ARCH_ARGS ${VPR_ARCH_ARGS}
    RR_PATCH_TOOL
      ${symbiflow-arch-defs_SOURCE_DIR}/xc/common/utils/prjxray_routing_import.py
    RR_PATCH_CMD "${CMAKE_COMMAND} -E env \
    PYTHONPATH=${PRJRAY_DIR}:${symbiflow-arch-defs_SOURCE_DIR}/utils:${symbiflow-arch-defs_BINARY_DIR}/utils \
        \${PYTHON3} \${RR_PATCH_TOOL} \
        --db_root ${PRJRAY_DB_DIR}/${PRJRAY_ARCH} \
        --part \${PART} \
        --read_rr_graph \${OUT_RRXML_VIRT} \
        --write_rr_graph \${OUT_RRXML_REAL} \
        --write_rr_node_map \${OUT_RRXML_REAL}.node_map.pickle \
        --vpr_capnp_schema_dir ${VPR_CAPNP_SCHEMA_DIR}
        "
    PLACE_TOOL
      ${symbiflow-arch-defs_SOURCE_DIR}/xc/common/utils/prjxray_create_ioplace.py
    PLACE_TOOL_CMD "${CMAKE_COMMAND} -E env \
    PYTHONPATH=${symbiflow-arch-defs_SOURCE_DIR}/utils \
    \${PYTHON3} \${PLACE_TOOL} \
        --map \${PINMAP} \
        --blif \${OUT_EBLIF} \
        \${PCF_INPUT_IO_FILE} \
        \${XDC_INPUT_IO_FILE} \
        --net \${OUT_NET}"
    PLACE_CONSTR_TOOL
      ${symbiflow-arch-defs_SOURCE_DIR}/xc/common/utils/prjxray_create_place_constraints.py
    PLACE_CONSTR_TOOL_CMD "${CMAKE_COMMAND} -E env \
    PYTHONPATH=${symbiflow-arch-defs_SOURCE_DIR}/utils \
    \${PYTHON3} \${PLACE_CONSTR_TOOL} \
        --net \${OUT_NET} \
        --arch \${DEVICE_MERGED_FILE_LOCATION} \
        --blif \${OUT_EBLIF} \
        --input /dev/stdin \
        --output /dev/stdout \
        \${PLACE_CONSTR_TOOL_EXTRA_ARGS}"
    BITSTREAM_EXTENSION bit
    FASM_TO_BIT ${XCFASM}
    FASM_TO_BIT_CMD "${CMAKE_COMMAND} -E env \
    PYTHONPATH=${symbiflow-arch-defs_BINARY_DIR}/env/conda/lib/python3.7/site-packages:${PRJRAY_DIR}:${PRJRAY_DIR}/third_party/fasm \
    \${FASM_TO_BIT} \
        --db-root ${PRJRAY_DB_DIR}/${PRJRAY_ARCH} \
        --sparse \
        --emit_pudc_b_pullup \
        --fn_in \${OUT_FASM} \
        --bit_out \${OUT_BITSTREAM} \
        --frm2bit ${XC7FRAMES2BIT} \
        \${FASM_TO_BIT_EXTRA_ARGS}"
    BIT_TO_V ${BITREAD}
    BIT_TO_V_CMD "${CMAKE_COMMAND} -E env \
    PYTHONPATH=${symbiflow-arch-defs_BINARY_DIR}/env/conda/lib/python3.7/site-packages:${PRJRAY_DIR}:${PRJRAY_DIR}/third_party/fasm:${symbiflow-arch-defs_SOURCE_DIR}/utils \
        \${PYTHON3} -mfasm2bels \
        \${BIT_TO_V_EXTRA_ARGS} \
        --db_root ${PRJRAY_DB_DIR}/${PRJRAY_ARCH} \
        --rr_graph \${OUT_RRBIN_REAL_LOCATION} \
        --vpr_capnp_schema_dir ${VPR_CAPNP_SCHEMA_DIR} \
        --route \${OUT_ROUTE} \
        --bitread ${BITREAD} \
        --bit_file \${OUT_BITSTREAM} \
        --fasm_file \${OUT_BITSTREAM}.fasm \
        --iostandard ${DEFAULT_IOSTANDARD} \
        --drive ${DEFAULT_DRIVE} \
        \${PCF_INPUT_IO_FILE} \
        --eblif \${OUT_EBLIF} \
        --top \${TOP} \
        --verilog_file \${OUT_BIT_VERILOG}
        --xdc_file \${OUT_BIT_VERILOG}.xdc ${INTERCHANGE_FASM2BELS}"
    NO_BIT_TO_BIN
    NO_BIT_TIME
    USE_FASM
    RR_GRAPH_EXT ".bin"
    ROUTE_CHAN_WIDTH 500
  )

  set_target_properties(${ARCH} PROPERTIES PRJRAY_ARCH ${PRJRAY_ARCH})
  add_custom_target(all_${ARCH}_diff_fasm)
  define_xc_toolchain_target(
      ARCH ${ARCH}
      ROUTE_CHAN_WIDTH 500
      VPR_ARCH_ARGS ${VPR_ARCH_ARGS}
      CONV_SCRIPT ${YOSYS_CONV_SCRIPT}
      SYNTH_SCRIPT ${YOSYS_SYNTH_SCRIPT}
      UTILS_SCRIPT ${YOSYS_UTILS_SCRIPT})

endfunction()
