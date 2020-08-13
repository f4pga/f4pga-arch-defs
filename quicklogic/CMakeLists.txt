include(common/cmake/quicklogic_fasm.cmake)
add_quicklogic_fasm_package()

include(common/cmake/quicklogic_timings.cmake)

add_custom_target(QL_CELLS_SIM_DEPS)

include(common/cmake/cells_sim_gen.cmake)

set(VPR_ARCH_ARGS "\
    --clock_modeling route \
    --place_delay_model delta_override \
    --router_lookahead map \
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

add_subdirectory(pp3)
add_subdirectory(common)
