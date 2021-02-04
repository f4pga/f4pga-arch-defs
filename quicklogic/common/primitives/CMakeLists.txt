include(../cmake/cells_sim_gen.cmake)

add_custom_target(QL_COMMON_CELLS_SIM_DEPS)

add_subdirectory(vpr_pad)
add_subdirectory(logic_0)
add_subdirectory(logic_1)

set(CELLS_SIM_FILE ${symbiflow-arch-defs_BINARY_DIR}/quicklogic/common/techmap/cells_sim.v)
add_cells_sim_target(${CELLS_SIM_FILE} COMMON)

