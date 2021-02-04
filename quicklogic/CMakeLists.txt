#include(common/cmake/quicklogic_fasm.cmake)
#add_quicklogic_fasm_package()

#include(common/cmake/quicklogic_timings.cmake)

# VPR architecture args for PP3
#set(VPR_PP3_ARCH_ARGS "\
#    --clock_modeling route \
#    --place_delay_model delta_override \
#    --router_lookahead map \
#    --check_route quick \
#    --strict_checks off \
#    --allow_dangling_combinational_nodes on \
#    --disable_errors check_unbuffered_edges:check_route \
#    --congested_routing_iteration_threshold 0.8 \
#    --incremental_reroute_delay_ripup off \
#    --base_cost_type delay_normalized_length_bounded \
#    --bb_factor 10 \
#    --initial_pres_fac 4.0 \
#    --check_rr_graph off \
#    --pack_high_fanout_threshold PB-LOGIC:18 \
#    --suppress_warnings \${OUT_NOISY_WARNINGS},sum_pin_class:check_unbuffered_edges:load_rr_indexed_data_T_values:check_rr_node:trans_per_R:check_route:set_rr_graph_tool_comment "
#)

# VPR architecture args common for AP3
set(VPR_AP3_COMMON_ARCH_ARGS "\
    --place_delay_model delta_override \
    --place_delta_delay_matrix_calculation_method dijkstra \
    --router_lookahead extended_map \
    --check_route quick \
    --strict_checks off \
    --allow_dangling_combinational_nodes on \
    --disable_errors check_unbuffered_edges:check_route \
    --congested_routing_iteration_threshold 0.8 \
    --incremental_reroute_delay_ripup off \
    --base_cost_type delay_normalized_length_bounded \
    --bb_factor 3 \
    --initial_pres_fac 10.0 \
    --pres_fac_mult 1.5 \
    --acc_fac 5.0 \
    --check_rr_graph off \
    --pack_high_fanout_threshold SUPER_LOGIC_CELL:18 \
    --suppress_warnings \${OUT_NOISY_WARNINGS},sum_pin_class:check_unbuffered_edges:load_rr_indexed_data_T_values:check_rr_node:trans_per_R:check_route:set_rr_graph_tool_comment "
)

# VPR architecture args for AP3
#set(VPR_AP3_ARCH_ARGS "\
#    ${VPR_AP3_COMMON_ARCH_ARGS} \
#    --target_ext_pin_util SUPER_LOGIC_CELL:0.75,1.0 \
#    --clock_modeling route "
#)

# VPR architecture args for AP3 with OpenFPGA
set(VPR_AP3_OPENFPGA_ARCH_ARGS "\
    ${VPR_AP3_COMMON_ARCH_ARGS} \
    --clock_modeling ideal "
)

add_subdirectory(common)
#add_subdirectory(pp3)
#add_subdirectory(ap3)
#add_subdirectory(ap3_openfpga)

# Architectures using OpenFPGA VPR architecture directly
add_subdirectory(openfpga)
