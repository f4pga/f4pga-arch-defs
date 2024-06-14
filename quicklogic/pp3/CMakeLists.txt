add_subdirectory(utils)

# Copy map files to binary dir.
get_filename_component(FAMILY_NAME ${CMAKE_CURRENT_SOURCE_DIR} NAME)

add_custom_target(QL_CELLS_SIM_DEPS)
include(cells_sim_gen.cmake)

set(CELLS_SIM_FILE ${f4pga-arch-defs_BINARY_DIR}/quicklogic/${FAMILY_NAME}/techmap/cells_sim.v)
add_subdirectory(primitives)
set(CELLS_MAP_DEST_DIR ${f4pga-arch-defs_BINARY_DIR}/quicklogic/${FAMILY_NAME}/techmap/)
file(COPY "techmap/cells_map.v"  DESTINATION ${CELLS_MAP_DEST_DIR})
file(COPY "techmap/lut2tomux4.v" DESTINATION ${CELLS_MAP_DEST_DIR})
file(COPY "techmap/lut2tomux2.v" DESTINATION ${CELLS_MAP_DEST_DIR})
file(COPY "techmap/lut3tomux2.v" DESTINATION ${CELLS_MAP_DEST_DIR})
file(COPY "techmap/mux4tomux2.v" DESTINATION ${CELLS_MAP_DEST_DIR})

add_cells_sim_target(${CELLS_SIM_FILE} ${FAMILY_NAME})

set(SDF_TIMING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/timings)

get_target_property_required(QLFASM env QLFASM)

set(VPR_ARCH_ARGS "\
    --clock_modeling route \
    --place_delay_model delta_override \
    --router_lookahead extended_map \
    --check_route quick \
    --strict_checks off \
    --allow_dangling_combinational_nodes on \
    --disable_errors check_unbuffered_edges:check_route \
    --congested_routing_iteration_threshold 0.8 \
    --incremental_reroute_delay_ripup off \
    --base_cost_type delay_normalized_length_bounded \
    --bb_factor 10 \
    --initial_pres_fac 4.0 \
    --check_rr_graph off \
    --pack_high_fanout_threshold PB-LOGIC:18 \
    --suppress_warnings \${OUT_NOISY_WARNINGS},sum_pin_class:check_unbuffered_edges:load_rr_indexed_data_T_values:check_rr_node:trans_per_R:check_route:set_rr_graph_tool_comment "
)

define_arch(
  ARCH ql-s3
  FAMILY pp3
  YOSYS_TECHMAP ${f4pga-arch-defs_BINARY_DIR}/quicklogic/${FAMILY_NAME}/techmap
  DEVICE_FULL_TEMPLATE \${DEVICE}
  VPR_ARCH_ARGS ${VPR_ARCH_ARGS}

  RR_PATCH_CMD "\${CMAKE_COMMAND} -E env \
    PYTHONPATH=${f4pga-arch-defs_SOURCE_DIR}/utils:$PYTHONPATH \
    FPGA_FAM=eos-s3 \
    f4pga utils routing_import \
        --vpr-db ${CMAKE_CURRENT_BINARY_DIR}/devices/\${DEVICE_TYPE}/db_vpr.pickle \
        --rr-graph-in \${OUT_RRXML_VIRT} \
        --rr-graph-out \${OUT_RRXML_REAL}"

  PLACE_TOOL_CMD "${CMAKE_COMMAND} -E env \
    PYTHONPATH=${f4pga-arch-defs_SOURCE_DIR}/utils:$PYTHONPATH \
    f4pga utils create_ioplace \
        --map \${PINMAP} \
        --blif \${OUT_EBLIF} \
        --pcf \${INPUT_IO_FILE} \
        --net \${OUT_NET}"

  PLACE_CONSTR_TOOL_CMD "${CMAKE_COMMAND} -E env \
    PYTHONPATH=${f4pga-arch-defs_SOURCE_DIR}/utils \
    f4pga utils create_place_constraints \
        --map ${f4pga-arch-defs_BINARY_DIR}/quicklogic/${FAMILY_NAME}/\${BOARD}_clkmap.csv \
        --blif \${OUT_EBLIF} \
        --i /dev/stdin \
        --o /dev/stdout \
        \${PLACE_CONSTR_TOOL_EXTRA_ARGS}"

  FASM_TO_BIT
    ${QLFASM}
  FASM_TO_BIT_CMD "\${PYTHON3} \
    \${QLFASM} \
    --no-default-bitstream --dev-type \${DEVICE}
        \${OUT_FASM}
        \${OUT_BITSTREAM}
        \${FASM_TO_BIT_EXTRA_ARGS}"
  BITSTREAM_EXTENSION bit

  CELLS_SIM
    ${CELLS_SIM_FILE}

  NO_BIT_TO_BIN
  BIT_TO_V_CMD
    "${CMAKE_COMMAND} -E env PYTHONPATH=${f4pga-arch-defs_SOURCE_DIR}/utils:${f4pga-arch-defs_SOURCE_DIR}/quicklogic/${FAMILY_NAME}/utils:$PYTHONPATH \
    f4pga utils fasm2bels \${OUT_BITSTREAM}
      --phy-db ${CMAKE_CURRENT_BINARY_DIR}/devices/\${DEVICE_TYPE}/db_phy.pickle
      --input-type bitstream
      --output-verilog \${OUT_BIT_VERILOG}
      --output-pcf \${OUT_BIT_VERILOG}.pcf
      --output-qcf \${OUT_BIT_VERILOG}.qcf
      --input-pcf \${INPUT_IO_FILE}"
  BIT_TO_V_DEPS
    ${f4pga-arch-defs_SOURCE_DIR}/quicklogic/pp3/utils/verilogmodule.py
    ${CMAKE_CURRENT_BINARY_DIR}/devices/\${DEVICE_TYPE}/db_vpr.pickle
  NO_BIT_TIME

  ROUTE_CHAN_WIDTH 100
  USE_FASM
)

add_subdirectory(devices)
include(boards.cmake)
add_subdirectory(tests)

define_ql_toolchain_target(
  FAMILY pp3
  ARCH ql-s3
  ROUTE_CHAN_WIDTH 100
  CELLS_SIM ${CELLS_SIM_FILE}
  VPR_ARCH_ARGS ${VPR_ARCH_ARGS}
  SYNTH_SCRIPT ${YOSYS_SYNTH_SCRIPT}
)
