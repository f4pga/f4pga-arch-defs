cmake_minimum_required(VERSION 3.14.0)
project(symbiflow-arch-defs)
enable_testing()

include(common/cmake/util.cmake)
include(common/cmake/file_targets.cmake)
include(common/cmake/env.cmake)
include(common/cmake/xml.cmake)
include(common/cmake/timings.cmake)
include(common/cmake/v2x.cmake)
include(common/cmake/install.cmake)
include(common/cmake/devices.cmake)
include(common/cmake/tools.cmake)

find_package(PythonInterp 3 REQUIRED)

add_custom_target(
   test_python
   DEPENDS
      conda_pytest all_pip
   )

# Some commands use file locks to prevent incorrect parallel access.
# All file locks are required to register a clean command with the clean_locks
# targets to prevent stale locks.
add_custom_target(clean_locks)

# Add dummy targets for attaching test targets too.
add_custom_target(all_xc7_tests)
add_custom_target(all_ice40_tests)

setup_env(
    MINICONDA3_VERSION py37_4.8.2
    )
add_conda_package(
  NAME yosys
  PROVIDES yosys
  PACKAGE_SPEC "yosys 0.8_3923_g8fe9c84e 20191206_160120"
  )
add_conda_package(
  NAME openocd
  PROVIDES openocd
  )

add_conda_package(
  NAME vtr
  PROVIDES vpr genfasm
  PACKAGE_SPEC "vtr 8.0.0.rc2_4003_g8980e4621 20200527_075234"
  )
add_conda_package(
  NAME libxslt
  PROVIDES xsltproc
  )
add_conda_package(
  NAME libxml2
  PROVIDES xmllint
  PACKAGE_SPEC "libxml2 2.9.9 h14c3975_5"
  )
add_conda_package(
  NAME pytest
  PROVIDES pytest
  )
add_conda_package(
  NAME flake8
  PROVIDES flake8
  )
add_conda_package(
  NAME yapf
  PROVIDES yapf
  PACKAGE_SPEC "yapf 0.26.0 py_0"
  )
add_conda_package(
  NAME nodejs
  PROVIDES node npm
  )
add_conda_package(
  NAME iverilog
  PROVIDES iverilog vvp
  )
add_conda_package(
  NAME yosys-plugins
  PACKAGE_SPEC "yosys-plugins 1.0.0.7_0025_ge04ea5b 20200308_024213"
  NO_EXE
  )

add_conda_package(
  NAME libiconv
  NO_EXE
)
add_conda_pip(
  NAME progressbar2
  NO_EXE
)
add_conda_pip(
  NAME pycapnp
  PACKAGE_SPEC "1.0.0b1"
  NO_EXE
)
add_conda_pip(
  NAME simplejson
  NO_EXE
)
add_conda_pip(
  NAME intervaltree
  NO_EXE
)
add_conda_pip(
  NAME pdfminer.six
  NO_EXE
)
add_conda_pip(
  NAME pyjson5
  NO_EXE
)
add_conda_pip(
  NAME ply
  NO_EXE
)
add_conda_pip(
  NAME svgwrite
  NO_EXE
)
add_conda_pip(
  NAME cairosvg
  NO_EXE
)
add_conda_pip(
  NAME gitpython
  NO_EXE
)
add_conda_pip(
  NAME hilbertcurve
  NO_EXE
)
add_conda_pip(
  NAME scipy
  NO_EXE
)
add_conda_pip(
  NAME matplotlib
  NO_EXE
)
add_conda_pip(
  NAME python-constraint
  NO_EXE
)

add_conda_pip(
  NAME numpy
  NO_EXE
)

get_target_property_required(PYTHON3 env PYTHON3)
get_target_property(PYTHON3_TARGET env PYTHON3_TARGET)
get_target_property(LIBICONV_TARGET env LIBICONV_TARGET)

add_thirdparty_package(
  NAME sdf_timing
  BUILD_INSTALL_COMMAND "cd ${symbiflow-arch-defs_SOURCE_DIR}/third_party/python-sdf-timing && ${PYTHON3} setup.py develop"
  NO_EXE
  DEPENDS ${PYTHON3_TARGET}
)

# FIXME: This is a workaround until fix for dependencies of arch.xml patching script(s) is in place
get_target_property(SDF_TIMING_TARGET env SDF_TIMING_TARGET)
add_dependencies(all_conda ${SDF_TIMING_TARGET})

add_thirdparty_package(
  NAME vtr_xml_utils
  BUILD_INSTALL_COMMAND "cd ${symbiflow-arch-defs_SOURCE_DIR}/third_party/vtr-xml-utils && ${PYTHON3} setup.py develop"
  PROVIDES vtr_xml_utils
  DEPENDS ${PYTHON3} ${PYTHON3_TARGET}
)

add_thirdparty_package(
  NAME v2x
  BUILD_INSTALL_COMMAND "cd ${symbiflow-arch-defs_SOURCE_DIR}/third_party/python-symbiflow-v2x && ${PYTHON3} setup.py develop"
  NO_EXE
  DEPENDS ${PYTHON3_TARGET} ${LIBICONV_TARGET}
)

include(common/cmake/image_gen.cmake)
include(common/cmake/gen.cmake)

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

# Target to validate pbtype files using vpr
add_custom_target(all_vpr_test_pbtype)

add_subdirectory(common)
add_subdirectory(utils)
add_subdirectory(vpr)
add_subdirectory(library)
# Disable 7-series support in CI because it consumes too much memory.
if (NOT DEFINED ENV{CI} OR NOT $ENV{CI})
add_subdirectory(xc)
endif (NOT DEFINED ENV{CI} OR NOT $ENV{CI})
add_subdirectory(ice40)
add_subdirectory(testarch)
add_subdirectory(tests)

get_target_property_required(YAPF env YAPF)
get_target_property_required(YAPF_TARGET env YAPF_TARGET)
add_custom_target(
  check_python
  DEPENDS ${YAPF_TARGET}
  COMMAND ${symbiflow-arch-defs_SOURCE_DIR}/common/python_health_helper.sh -c -y ${YAPF}
  )
add_custom_target(
  format_python
  DEPENDS ${YAPF_TARGET}
  COMMAND ${symbiflow-arch-defs_SOURCE_DIR}/common/python_health_helper.sh -f -y ${YAPF}
  )

get_target_property_required(FLAKE8 env FLAKE8)
get_target_property_required(FLAKE8_TARGET env FLAKE8_TARGET)
add_custom_target(
  lint_python
  DEPENDS ${FLAKE8_TARGET}
  COMMAND ${symbiflow-arch-defs_SOURCE_DIR}/common/python_health_helper.sh -l -p "${FLAKE8}"
  )


add_custom_target(all_ice40_demos)
add_dependencies(all_ice40_demos
    all_icestick_bin
    all_iceblink40-lp1k_bin
    )

add_custom_target(all_ice40_route_tests)
add_dependencies(all_ice40_route_tests
    all_dummy_ice40_hx1k_tq144_route
    all_dummy_ice40_lp1k_qn84_route
    all_dummy_ice40_hx1k_tq144_route
    )

if (NOT DEFINED ENV{CI} OR NOT $ENV{CI})
add_dependencies(all_ice40_demos
    all_icevision_bin
    all_hx8k-b-evn_bin
    all_tinyfpga-bx_bin
    all_tinyfpga-b2_bin
    )
add_dependencies(all_ice40_route_tests
    all_dummy_ice40_up5k_sg48_route
    all_dummy_ice40_lp8k_cm81_route
    all_dummy_ice40_hx8k_ct256_route
    )
endif()

add_custom_target(all_ice40)
add_dependencies(all_ice40
    all_ice40_demos
    all_ice40_tests
    all_ice40_route_tests
    )

add_custom_target(all_xc7_route_tests)


if (NOT DEFINED ENV{CI} OR NOT $ENV{CI})
add_dependencies(all_xc7_route_tests
    all_dummy_artix7_xc7a50t-arty-swbut_test_route
    all_dummy_artix7_xc7a50t-arty-uart_test_route
    all_dummy_artix7_xc7a50t-basys3_test_route
    )
endif()

add_custom_target(all_xc7_demos)
if (NOT DEFINED ENV{CI} OR NOT $ENV{CI})
add_dependencies(all_xc7_demos
    all_arty-swbut_bin
    all_arty-uart_bin
    all_arty-full_bin
    all_basys3_bin
    all_basys3-full_bin
    #all_basys3-bottom_bin
    # TODO(#548) Zybo targets not currently working, so removed from all target.
    #all_zybo_bin
    #all_zybo-full_bin
    )
endif()

add_custom_target(all_xc7_diff_fasm)
if (NOT DEFINED ENV{CI} OR NOT $ENV{CI})
add_dependencies(all_xc7_diff_fasm
    all_artix7_diff_fasm
    all_zynq7_diff_fasm
    )
endif()

add_custom_target(all_xc7)
add_dependencies(all_xc7
    all_xc7_demos
    all_xc7_route_tests
    all_xc7_tests
    )
if (NOT DEFINED ENV{CI} OR NOT $ENV{CI})
add_dependencies(all_xc7
    test_dram_packing
    )
endif()

add_custom_target(all_xc7_200t)
if (NOT DEFINED ENV{CI} OR NOT $ENV{CI})
add_dependencies(all_xc7_200t
    all_nexys_video_bin
    )
endif()

add_custom_target(all_testarch)
add_dependencies(all_testarch
    all_dummy_testarch_10x10_dummy_route
    all_dummy_testarch_4x4_dummy_route
    )

add_custom_target(all_demos)
add_dependencies(all_demos
    all_ice40_demos
    all_xc7_demos
    )

add_custom_target(all_tests)
add_dependencies(all_tests
    all_testarch
    all_ice40_tests
    all_xc7_tests
    )

add_custom_target(docs)

add_custom_target(print_qor
    COMMAND ${PYTHON3} ${symbiflow-arch-defs_SOURCE_DIR}/utils/print_qor.py ${symbiflow-arch-defs_BINARY_DIR}
    DEPENDS ${PYTHON3_TARGET}
    )
