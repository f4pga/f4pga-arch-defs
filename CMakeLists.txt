cmake_minimum_required(VERSION 3.3)
project(symbiflow-arch-defs)
enable_testing()

include(make/util.cmake)
include(make/env.cmake)
include(make/file_targets.cmake)
include(make/xml.cmake)
include(make/devices.cmake)

find_package(PythonInterp 3 REQUIRED)

setup_env()
add_conda_package(
  NAME yosys
  PROVIDES yosys
  PACKAGE_SPEC "yosys 0.8 0461.1903060506.g12a8e092"
  )
add_conda_package(
  NAME openocd
  PROVIDES openocd
  )
add_conda_package(
  NAME vtr
  PROVIDES vpr genhlc genfasm
  PACKAGE_SPEC "vtr 7.0.5 6718.1903061900.g6477cceff"
  )
add_conda_package(
  NAME libxslt
  PROVIDES xsltproc
  )
add_conda_package(
  NAME libxml2
  PROVIDES xmllint
  )
add_conda_package(
  NAME pytest
  PROVIDES pytest
  )
add_conda_package(
  NAME yapf
  PROVIDES yapf
  )
add_conda_package(
  NAME nodejs
  PROVIDES node npm
  )
add_conda_package(
  NAME iverilog
  PROVIDES iverilog vvp
  )

include(make/image_gen.cmake)
include(make/gen.cmake)

add_subdirectory(${CMAKE_CURRENT_SOURCE_DIR}/third_party/prjxray)

# Target for all check tests.
add_custom_target(all_check_tests)

# Target for all route tests.
add_custom_target(all_route_tests)

# Target for all merged_arch_xmls.
add_custom_target(all_merged_arch_xmls)

# Target for all rrgraph xmls.
add_custom_target(all_rrgraph_xmls)

# Target to lint all xml files.
add_custom_target(all_xml_lint)

add_subdirectory(utils)
add_subdirectory(vpr)
add_subdirectory(yosys)
add_subdirectory(library)
# Disable 7-series support in CI because it consumes too much memory.
if (NOT DEFINED ENV{CI} OR NOT $ENV{CI})
add_subdirectory(xc7)
endif (NOT DEFINED ENV{CI} OR NOT $ENV{CI})
add_subdirectory(ice40)
add_subdirectory(testarch)
add_subdirectory(tests)
add_subdirectory(soc_tests)
