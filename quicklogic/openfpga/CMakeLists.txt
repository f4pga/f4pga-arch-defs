include(../common/cmake/install.cmake)
include(../common/cmake/quicklogic_openfpga_arch.cmake)
include(../common/cmake/quicklogic_openfpga_device.cmake)
include(../common/cmake/quicklogic_board.cmake)

get_filename_component(FAMILY ${CMAKE_CURRENT_SOURCE_DIR} NAME)

add_subdirectory(techmap)

# VPR args
set(VPR_ARCH_ARGS "\
    --clock_modeling ideal "
)

# Define the architecture
quicklogic_define_openfpga_arch(
  FAMILY   ${FAMILY}
  ARCH     ql-openfpga
  VPR_ARGS ${VPR_ARCH_ARGS}

  ROUTE_CHAN_WIDTH 100 # Will be overriden by each device
)

add_subdirectory(devices)
include(boards.cmake)

add_subdirectory(tests)

