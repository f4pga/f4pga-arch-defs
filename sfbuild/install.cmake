function(DEFINE_SF_BUILD_TARGET)
# cmake_minimum_required(VERSION 3.19)

  find_package(Python3 COMPONENTS Interpreter REQUIRED)

  get_target_property_required(VPR env VPR)
  get_target_property_required(GENFASM env GENFASM)

  set(SYMBIFLOW_TOOLS
    __init__.py
    sfbuild.py
    sf_cache.py)
  set(SYMBIFLOW_TOOL_PATHS)

  set(SYMBIFLOW_COMMON
    __init__.py
    sf_common.py)
  set(SYMBIFLOW_COMMON_PATHS)
  
  set(SYMBIFLOW_MODULE
    __init__.py
    sf_module.py)
  set(SYMBIFLOW_MODULE_PATHS)
  
  set(COMMON_MODULES
    sf_fasm.py
    sf_ioplace.py
    sf_mkdirs.py
    sf_pack.py
    sf_place_constraints.py
    sf_place.py
    sf_route.py
    sf_synth.py)
  set(COMMON_MODULE_PATHS)

  foreach(TOOL ${SYMBIFLOW_TOOLS})
    set(SYMBIFLOW_TOOL_PATH "${symbiflow-arch-defs_SOURCE_DIR}/sfbuild/${TOOL}")
    list(APPEND SYMBIFLOW_TOOL_PATHS ${SYMBIFLOW_TOOL_PATH})
  endforeach()

  foreach(SRC ${SYMBIFLOW_COMMON})
    set(SYMBIFLOW_SRC_PATH "${symbiflow-arch-defs_SOURCE_DIR}/sfbuild/sf_common/${SRC}")
    list(APPEND SYMBIFLOW_COMMON_PATHS ${SYMBIFLOW_SRCL_PATH})
  endforeach()

  foreach(SRC ${SYMBIFLOW_MODULE})
    set(SYMBIFLOW_SRC_PATH "${symbiflow-arch-defs_SOURCE_DIR}/sfbuild/sf_module/${SRC}")
    list(APPEND SYMBIFLOW_MODULE_PATHS ${SYMBIFLOW_SRC_PATH})
  endforeach()
  
  foreach(MODULE ${COMMON_MODULES})
    set(SYMBIFLOW_MODULE_PATH "${symbiflow-arch-defs_SOURCE_DIR}/sfbuild/sf_common_modules/${MODULE}")
    list(APPEND COMMON_MODULE_PATHS ${SYMBIFLOW_MODULE_PATH})
  endforeach()

  # Create required directories
  set(MAKE_COMMON_PKG_DIR_CODE "file(MAKE_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/sf_common)")
  set(MAKE_COMMON_MODULES_PKG_DIR_CODE "file(MAKE_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/sf_common_modules)")
  set(MAKE_MODULE_PKG_DIR_CODE "file(MAKE_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/sf_modules)")
  install(CODE ${MAKE_COMMON_PKG_DIR_CODE})
  install(CODE ${MAKE_COMMON_MODULES_PKG_DIR_CODE})
  install(CODE ${MAKE_MODULE_PKG_DIR_CODE})

  # Install sfbuild
  install(FILES ${SYMBIFLOW_TOOL_PATHS}
          DESTINATION ${CMAKE_CURRENT_BINARY_DIR}
          PERMISSIONS WORLD_EXECUTE WORLD_READ OWNER_WRITE OWNER_READ OWNER_EXECUTE GROUP_READ GROUP_EXECUTE)
  install(FILES ${SYMBIFLOW_COMMON_PATHS}
          DESTINATION ${CMAKE_CURRENT_BINARY_DIR}/sf_common
          PERMISSIONS WORLD_EXECUTE WORLD_READ OWNER_WRITE OWNER_READ OWNER_EXECUTE GROUP_READ GROUP_EXECUTE)
  install(FILES ${SYMBIFLOW_MODULE_PATHS}
          DESTINATION ${CMAKE_CURRENT_BINARY_DIR}/sf_module
          PERMISSIONS WORLD_EXECUTE WORLD_READ OWNER_WRITE OWNER_READ OWNER_EXECUTE GROUP_READ GROUP_EXECUTE)
  install(FILES ${COMMON_MODULE_PATHS}
          DESTINATION ${CMAKE_CURRENT_BINARY_DIR}/sf_common_modules
          PERMISSIONS WORLD_EXECUTE WORLD_READ OWNER_WRITE OWNER_READ OWNER_EXECUTE GROUP_READ GROUP_EXECUTE)

  # Detect virtualenv and set pip args accordingly
  if(DEFINED ENV{VIRTUAL_ENV} OR DEFINED ENV{CONDA_PREFIX})
    set(_PIP_ARGS)
  else()
    set(_PIP_ARGS "--user")
  endif()
  # Install sfbuild package *this will allow users to acces python modules required to write their Symbiflow Modules.
  set(PYTHON_PKG_INSTALL_CODE "execute_process(COMMAND ${Python3_EXECUTABLE} -m pip install -e ${CMAKE_CURRENT_BINARY_DIR} ${_PIP_ARGS})")
  install(CODE ${PYTHON_PKG_INSTALL_CODE})

endfunction()