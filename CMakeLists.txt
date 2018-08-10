cmake_minimum_required(VERSION 3.3)
project(symbiflow-arch-defs)
enable_testing()

include(make/util.cmake)
include(make/env.cmake)
include(make/file_targets.cmake)
include(make/devices.cmake)

setup_env()

include(make/image_gen.cmake)
include(make/gen.cmake)

# Target for removing pip binaries, forcing them to retrieved again.
add_custom_target(clean_pip)

# Target for all check tests.
add_custom_target(all_check_tests)

# Target for all route tests.
add_custom_target(all_route_tests)

# Target for all merged_arch_xmls.
add_custom_target(all_merged_arch_xmls)

add_subdirectory(utils)
add_subdirectory(vpr)
add_subdirectory(yosys)
add_subdirectory(artix7)
add_subdirectory(ice40)
add_subdirectory(testarch)
add_subdirectory(tests)
