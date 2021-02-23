add_file_target(FILE cells_sim.v)
add_file_target(FILE cells_map.v)

get_file_target(CELLS_SIM_TARGET cells_sim.v)
get_file_target(CELLS_MAP_TARGET cells_map.v)

add_dependencies(
    ${CELLS_SIM_TARGET}
    ${CELLS_MAP_TARGET}
)
