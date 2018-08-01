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
  # In all cases, setting an enviroment variable will override the default behavior.
  #
  # Example:
  #  export VPR=<path to VPR>
  #
  #  will cause get_target_property(var env VPR) to return $ENV{VPR}.
  #
  # FIXME: Consider using CMake CACHE variables instead of target properties.
  add_custom_target(env)

  set(OTHER_BINARIES inkscape)
  set(MAYBE_CONDA_BINARIES yosys vpr xsltproc pytest yapf node npm iverilog python3 pip cocotb)

  # FIXME: Add target to configure conda.
  set(ENV_DIR ${symbiflow-arch-defs_SOURCE_DIR}/env)
  if(IS_DIRECTORY ${ENV_DIR})
    set(CONDA_DIR ${ENV_DIR}/conda)

    foreach(binary ${MAYBE_CONDA_BINARIES})
      string(TOUPPER ${binary} binary_upper)
      set(${binary_upper} ${CONDA_DIR}/bin/${binary})
      REPLACE_WITH_ENV_IF_SET(${binary_upper})
      set_target_properties(
        env
        PROPERTIES
        ${binary_upper} ${${binary_upper}}
        )
    endforeach()
  else()
    foreach(binary ${MAYBE_CONDA_BINARIES})
      string(TOUPPER ${binary} binary_upper)
      set(${binary_upper} ${binary})
      REPLACE_WITH_ENV_IF_SET(${binary_upper})
      set_target_properties(
        env
        PROPERTIES
        ${binary_upper} ${${binary_upper}}
        )
    endforeach()
  endif()

  foreach(binary ${OTHER_BINARIES})
    string(TOUPPER ${binary} binary_upper)
    set(${binary_upper} ${binary})
    REPLACE_WITH_ENV_IF_SET(${binary_upper})
    set_target_properties(
      env
      PROPERTIES
      ${binary_upper} ${${binary_upper}}
      )
  endforeach()
endfunction()
