function(REPLACE_WITH_ENV_IF_SET var)
  # Replaces var in parent scope with enviroment variable if set.
  if(NOT "$ENV{${var}}" STREQUAL "")
    set(${var} $ENV{${var}} PARENT_SCOPE)
  endif()
endfunction()

set(USE_CONDA TRUE
  CACHE BOOL "Whether to create a conda enviroment for tools.")

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
  add_custom_target(env)
  set(ENV_DIR ${symbiflow-arch-defs_BINARY_DIR}/env)
  add_custom_target(clean_env
    COMMAND ${CMAKE_COMMAND} -E remove_directory ${ENV_DIR}
    )
  add_custom_target(clean_pip)
  add_custom_target(all_conda)

  set(
    MAYBE_CONDA_BINARIES
    python3
    pip
  )

  if(${USE_CONDA})
    set_target_properties(env PROPERTIES USE_CONDA TRUE)

    set(MINICONDA_FILE Miniconda3-latest-Linux-x86_64.sh)
    set(MINICONDA_URL https://repo.continuum.io/miniconda/${MINICONDA_FILE})
    find_program(WGET wget)
    add_custom_command(
      OUTPUT ${ENV_DIR}/${MINICONDA_FILE}
      COMMAND ${CMAKE_COMMAND} -E make_directory ${ENV_DIR}
      COMMAND ${WGET} ${MINICONDA_URL} -O ${ENV_DIR}/${MINICONDA_FILE}
      DEPENDS ${WGET})
    set(CONDA_DIR ${ENV_DIR}/conda)
    set_target_properties(env PROPERTIES CONDA_DIR ${CONDA_DIR})

    set(CONDA_BIN ${CONDA_DIR}/bin/conda)
    set_target_properties(env PROPERTIES CONDA_BIN ${CONDA_BIN})
    set(OUTPUTS ${CONDA_BIN})
    foreach(BINARY ${MAYBE_CONDA_BINARIES})
      list(APPEND OUTPUTS ${CONDA_DIR}/bin/${BINARY})
    endforeach()

    add_custom_command(
      OUTPUT ${OUTPUTS}
      COMMAND sh ${ENV_DIR}/${MINICONDA_FILE} -p ${CONDA_DIR} -b -f
      COMMAND ${CONDA_BIN} config --system --set always_yes yes
      COMMAND ${CONDA_BIN} config --system --add envs_dirs ${CONDA_DIR}/envs
      COMMAND ${CONDA_BIN} config --system --add pkgs_dirs ${CONDA_DIR}/pkgs
      COMMAND ${CONDA_BIN} config --add channels symbiflow
      COMMAND ${CONDA_BIN} config --add channels conda-forge
      COMMAND ${CONDA_BIN} install lxml
      COMMAND ${CMAKE_COMMAND} -E touch_nocreate ${CONDA_BIN}
      DEPENDS ${ENV_DIR}/${MINICONDA_FILE}
      )

    add_custom_target(
      conda DEPENDS ${CONDA_BIN}
      )

    foreach(binary ${MAYBE_CONDA_BINARIES})
      string(TOUPPER ${binary} binary_upper)
      set(${binary_upper} ${CONDA_DIR}/bin/${binary})
      replace_with_env_if_set(${binary_upper})
      set_target_properties(env PROPERTIES
        ${binary_upper} ${${binary_upper}}
        ${binary_upper}_TARGET conda
        )
    endforeach()
  else()
    set_target_properties(env PROPERTIES USE_CONDA FALSE)
    foreach(binary ${MAYBE_CONDA_BINARIES})
      string(TOUPPER ${binary} binary_upper)
      set(${binary_upper} ${binary})
      replace_with_env_if_set(${binary_upper})
      set_target_properties(env PROPERTIES
        ${binary_upper} ${${binary_upper}}
        ${binary_upper}_TARGET ""
        )
    endforeach()
  endif()

  set(YOSYS_DATADIR ${ENV_DIR}/conda/share/yosys CACHE PATH "Path to yosys data directory")

  set_target_properties(env PROPERTIES
    QUIET_CMD ${symbiflow-arch-defs_SOURCE_DIR}/utils/quiet_cmd.sh
    QUIET_CMD_TARGET ""
    )
endfunction()

function(ADD_CONDA_PACKAGE)
  # ~~~
  # ADD_CONDA_PACKAGE(
  #   PACKAGE <name>
  #   PROVIDES <exe list>
  #   )
  # ~~~
  #
  # Installs a package via conda.  This generates two env properties per name
  # in PROVIDES list. <name> is set to the path the executable.  <name>_TARGET
  # is set to the target that will invoke conda.
  set(options)
  set(oneValueArgs NAME)
  set(multiValueArgs PROVIDES)
  cmake_parse_arguments(
    ADD_CONDA_PACKAGE
    "${options}"
    "${oneValueArgs}"
    "${multiValueArgs}"
    ${ARGN}
  )

  get_target_property_required(USE_CONDA env USE_CONDA)

  if(${USE_CONDA})
    set(OUTPUTS "")
    set(TOUCH_COMMANDS "")
    get_target_property_required(CONDA_DIR env CONDA_DIR)
    get_target_property_required(CONDA_BIN env CONDA_BIN)
    foreach(OUTPUT ${ADD_CONDA_PACKAGE_PROVIDES})
      list(APPEND OUTPUTS ${CONDA_DIR}/bin/${OUTPUT})
      list(APPEND TOUCH_COMMANDS COMMAND ${CMAKE_COMMAND} -E touch_nocreate ${CONDA_DIR}/bin/${OUTPUT})
    endforeach()

    add_custom_command(
      OUTPUT ${OUTPUTS}
      COMMAND ${CONDA_BIN} install -f ${ADD_CONDA_PACKAGE_NAME}
      ${TOUCH_COMMANDS}
      DEPENDS conda ${CONDA_BIN}
      )

    set(TARGET conda_${ADD_CONDA_PACKAGE_NAME})
    add_custom_target(${TARGET} DEPENDS ${OUTPUTS})
    add_dependencies(all_conda ${TARGET})

    foreach(OUTPUT ${ADD_CONDA_PACKAGE_PROVIDES})
      string(TOUPPER ${OUTPUT} binary_upper)
      set(${binary_upper} ${CONDA_DIR}/bin/${OUTPUT})
      replace_with_env_if_set(${binary_upper})
      set_target_properties(env PROPERTIES
        ${binary_upper} ${${binary_upper}}
        ${binary_upper}_TARGET ${TARGET})
    endforeach()
  else()
    foreach(OUTPUT ${ADD_CONDA_PACKAGE_PROVIDES})
      string(TOUPPER ${OUTPUT} binary_upper)
      set(${binary_upper} ${OUTPUT})
      replace_with_env_if_set(${binary_upper})
      set_target_properties(env PROPERTIES
        ${binary_upper} ${${binary_upper}}
        ${binary_upper}_TARGET "")
    endforeach()
  endif()
endfunction()

function(ADD_CONDA_PIP)
  # ~~~
  # ADD_CONDA_PIP(
  #   NAME <name>
  #   )
  # ~~~
  #
  # Installs an executable via conda PIP.  This generates two env properties.
  # <name> is set to the path to the executable. <name>_TARGET is set to the
  # target that will invoke pip if not already installed.
  set(options)
  set(oneValueArgs NAME)
  set(multiValueArgs)
  cmake_parse_arguments(
    ADD_CONDA_PIP
    "${options}"
    "${oneValueArgs}"
    "${multiValueArgs}"
    ${ARGN}
  )

  set(NAME ${ADD_CONDA_PIP_NAME})
  get_target_property_required(USE_CONDA env USE_CONDA)
  string(TOUPPER ${NAME} binary_upper)
  if(${USE_CONDA})
    get_target_property_required(CONDA_DIR env CONDA_DIR)
    get_target_property_required(PIP env PIP)
    get_target_property(PIP_TARGET env PIP_TARGET)

    set(BIN ${CONDA_DIR}/bin/${NAME})
    add_custom_command(
      OUTPUT ${BIN}
      COMMAND ${PIP} install ${NAME}
      DEPENDS ${PIP} ${PIP_TARGET}
      )
    add_custom_target(
      ${NAME}
      DEPENDS ${BIN}
      )
    add_dependencies(all_conda ${NAME})

    add_custom_target(
      _clean_pip_${NAME}
      COMMAND ${PIP} uninstall -y ${NAME}
      )
    add_dependencies(clean_pip _clean_pip_${NAME})

    set(${binary_upper} ${BIN})
    replace_with_env_if_set(${binary_upper})
    set_target_properties(env PROPERTIES ${binary_upper} ${BIN})
    set_target_properties(env PROPERTIES ${binary_upper}_TARGET ${NAME})
  else()
    set(${binary_upper} ${NAME})
    replace_with_env_if_set(${binary_upper})
    set_target_properties(env PROPERTIES ${binary_upper} ${${binary_upper}})
    set_target_properties(env PROPERTIES ${binary_upper}_TARGET "")
  endif()
endfunction()
