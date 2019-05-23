include(icestorm.cmake)

icestorm_setup()

add_subdirectory(primitives)
add_subdirectory(cells)
add_subdirectory(devices)
include(boards.cmake)

add_subdirectory(tests)
