cmake_minimum_required (VERSION 3.0)
project (symbiflow-arch-defs)

include(make/util.cmake)
include(make/env.cmake)
include(make/file_targets.cmake)
include(make/gen.cmake)
include(make/devices.cmake)

SETUP_ENV()

add_subdirectory(vpr)
add_subdirectory(artix7)
add_subdirectory(ice40)
add_subdirectory(testarch)
