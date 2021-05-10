include(../common/cmake/quicklogic_board.cmake)
include(../common/cmake/quicklogic_qlf_device.cmake)
include(../common/cmake/quicklogic_qlf_arch.cmake)

get_filename_component(FAMILY ${CMAKE_CURRENT_SOURCE_DIR} NAME)

add_subdirectory(techmap)

# VPR args
set(VPR_ARCH_ARGS "\
    --clock_modeling ideal \
    --place_delta_delay_matrix_calculation_method dijkstra \
    --place_delay_model delta_override \
    --router_lookahead extended_map "
)

# Define the architecture
quicklogic_define_qlf_arch(
  FAMILY   ${FAMILY}
  ARCH     qlf_k6n10
  VPR_ARGS ${VPR_ARCH_ARGS}

  ROUTE_CHAN_WIDTH 10 # Will be overriden by each device
)

add_subdirectory(devices)
include(boards.cmake)


add_subdirectory(tests)
