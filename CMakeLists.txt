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
include(common/cmake/sv2v.cmake)
include(common/cmake/litex.cmake)

# Parse lists of architectures / devices to be installed
parse_install_lists()

find_package(PythonInterp 3 REQUIRED)

add_custom_target(test_python)

# Dummy old targets, left in for backwards compability.
add_custom_target(all_conda)
add_custom_target(clean_locks)

# Add dummy targets for attaching test targets too.
add_custom_target(all_xc7_tests)
add_custom_target(all_ice40_tests)
add_custom_target(all_quicklogic_tests)

set(ENV_DIR ${symbiflow-arch-defs_SOURCE_DIR}/env/conda/envs/symbiflow_arch_def_base/ CACHE PATH "Path to environment")
set(YOSYS_DATADIR ${ENV_DIR}/share/yosys CACHE PATH "Path to yosys data directory")
set(OPENOCD_DATADIR ${ENV_DIR}/share/openocd CACHE PATH "Path to openocd data directory")
set(VPR_CAPNP_SCHEMA_DIR ${ENV_DIR}/capnp CACHE PATH "Path to VPR schema directory")


setup_env()
add_env_executable(EXE yosys REQUIRED)
add_env_executable(EXE vpr REQUIRED)
add_env_executable(EXE genfasm REQUIRED)
add_env_executable(EXE node REQUIRED)
add_env_executable(EXE npm REQUIRED)
add_env_executable(EXE pytest REQUIRED)
add_env_executable(EXE xmllint REQUIRED)
add_env_executable(EXE openocd REQUIRED)
add_env_executable(EXE yapf REQUIRED)
add_env_executable(EXE icebox.py REQUIRED)
add_env_executable(EXE icebox_hlc2asc REQUIRED)
add_env_executable(EXE icebox_vlog REQUIRED)
add_env_executable(EXE icepack REQUIRED)
add_env_executable(EXE icetime REQUIRED)
add_env_executable(EXE tinyfpgab REQUIRED)
add_env_executable(EXE tinyprog REQUIRED)
add_env_executable(EXE flake8 REQUIRED)
add_env_executable(EXE vvp REQUIRED)
add_env_executable(EXE iverilog REQUIRED)
add_env_executable(EXE xcfasm REQUIRED)
add_env_executable(EXE qlf_fasm REQUIRED)
add_env_executable(EXE xc7frames2bit REQUIRED)
add_env_executable(EXE bitread REQUIRED)
add_env_executable(EXE prjxray-config)

get_target_property_required(PYTHON3 env PYTHON3)

include(common/cmake/image_gen.cmake)
include(common/cmake/gen.cmake)

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
add_subdirectory(quicklogic)
add_subdirectory(testarch)
add_subdirectory(tests)

get_target_property_required(YAPF env YAPF)
add_custom_target(
  check_python
  COMMAND ${symbiflow-arch-defs_SOURCE_DIR}/common/python_health_helper.sh -c -y ${YAPF}
  )
add_custom_target(
  format_python
  COMMAND ${symbiflow-arch-defs_SOURCE_DIR}/common/python_health_helper.sh -f -y ${YAPF}
  )

get_target_property_required(FLAKE8 env FLAKE8)
add_custom_target(
  lint_python
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

add_custom_target(all_quicklogic)
add_dependencies(all_quicklogic
    all_quicklogic_tests
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
    all_arty100t-full_bin
    all_netv2-a100t_bin
    all_basys3_bin
    all_basys3-full_bin
    all_pynqz1-full_bin
    #all_basys3-bottom_bin
    # TODO(#548) Zybo targets not currently working, so removed from all target.
    #all_zybo_bin
    all_zybo-full_bin
    )
endif()

add_custom_target(all_xc7_diff_fasm)
if (NOT DEFINED ENV{CI} OR NOT $ENV{CI})
add_dependencies(all_xc7_diff_fasm
    all_artix7_diff_fasm
    all_artix7_100t_diff_fasm
    all_zynq7_diff_fasm
    all_zynq7_z020_diff_fasm
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
    all_nexys_video-mid_bin
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
    all_quicklogic_tests
    all_xc7_tests
    )

add_custom_target(docs)

add_custom_target(print_qor
    COMMAND ${PYTHON3} ${symbiflow-arch-defs_SOURCE_DIR}/utils/print_qor.py ${symbiflow-arch-defs_BINARY_DIR}
    )
