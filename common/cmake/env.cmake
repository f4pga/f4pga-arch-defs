function(REPLACE_WITH_ENV_IF_SET var)
  # Replaces var in parent scope with enviroment variable if set.
  if(NOT "$ENV{${var}}" STREQUAL "")
    set(${var} $ENV{${var}} PARENT_SCOPE)
  endif()
endfunction()

function(SETUP_ENV)
  # Creates a target "env" that has the properties that are all paths to
  # executables.  See OTHER_BINARIES and MAYBE_CONDA_BINARIES for list of
  # binaries.
  #
  # For executables listed in MAYBE_CONDA_BINARIES, if conda has been setup in
  # <root>/env, then each executable will point to <root>/env/conda/bin/<exe>.
  #
  # If conda is not present, then the executable is expected to be on the PATH.
  #
  # In all cases, setting an enviroment variable will override the default
  # behavior.
  #
  # Example: export VPR=<path to VPR>
  #
  # will cause get_target_property(var env VPR) to return $ENV{VPR}.
  #
  # FIXME: Consider using CMake CACHE variables instead of target properties.

  set(options)
  set(oneValueArgs)
  set(multiValueArgs)
  cmake_parse_arguments(
      SETUP_ENV
    "${options}"
    "${oneValueArgs}"
    "${multiValueArgs}"
    ${ARGN}
  )

  add_custom_target(env)
  set(
    MAYBE_CONDA_BINARIES
    python3
  )

  set_target_properties(env PROPERTIES USE_CONDA FALSE)
  foreach(binary ${MAYBE_CONDA_BINARIES})
    string(TOUPPER ${binary} binary_upper)
    if(DEFINED ENV{${binary_upper}})
      set(${binary_upper} $ENV{${binary_upper}})
    else()
      find_program(${binary_upper} ${binary})
    endif()

    set_target_properties(env PROPERTIES
      ${binary_upper} ${${binary_upper}}
      ${binary_upper}_TARGET ${binary}
        )
  endforeach()

  set(YOSYS_DATADIR ${ENV_DIR}/conda/share/yosys CACHE PATH "Path to yosys data directory")
  set(VPR_CAPNP_SCHEMA_DIR ${ENV_DIR}/conda/capnp CACHE PATH "Path to VPR schema directory")

  set_target_properties(env PROPERTIES
    QUIET_CMD ${symbiflow-arch-defs_SOURCE_DIR}/utils/quiet_cmd.sh
    QUIET_CMD_TARGET ""
    )
endfunction()

function(ADD_ENV_EXECUTABLE)
    set(options REQUIRED)
  set(oneValueArgs EXE)
  set(multiValueArgs)
  cmake_parse_arguments(
      ADD_ENV_EXECUTABLE
      "${options}"
      "${oneValueArgs}"
      "${multiValueArgs}"
       ${ARGN}
  )

  set(binary ${ADD_ENV_EXECUTABLE_EXE})
  string(TOUPPER ${binary} binary_upper)
  if(DEFINED ENV{${binary_upper}})
    set(${binary_upper} $ENV{${binary_upper}})
  else()
    find_program(${binary_upper} ${binary})
  endif()

  set_target_properties(env PROPERTIES
    ${binary_upper} ${${binary_upper}}
    )

  if(${ADD_ENV_EXECUTABLE_REQUIRED})
    if(NOT EXISTS ${${binary_upper}})
      message(FATAL_ERROR "Executable ${binary} not found and is marked required.  Either set env var ${binary_upper} or ensure ${binary} is on the path.")
    endif()
  endif()
endfunction()
