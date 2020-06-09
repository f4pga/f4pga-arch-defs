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

  set(options)
  set(oneValueArgs MINICONDA3_VERSION)
  set(multiValueArgs)
  cmake_parse_arguments(
      SETUP_ENV
    "${options}"
    "${oneValueArgs}"
    "${multiValueArgs}"
    ${ARGN}
  )

  add_custom_target(env)
  set(ENV_DIR ${symbiflow-arch-defs_BINARY_DIR}/env)
  set(REL_ENV_DIR env)
  add_custom_target(clean_env
    COMMAND ${CMAKE_COMMAND} -E remove_directory ${ENV_DIR}
    )
  add_custom_target(clean_pip)
  add_custom_target(all_conda)
  add_custom_target(all_pip)

  set(
    MAYBE_CONDA_BINARIES
    python3
    pip
  )

  if(${USE_CONDA})
    set_target_properties(env PROPERTIES USE_CONDA TRUE)

    set(MINICONDA_FILE Miniconda3-${SETUP_ENV_MINICONDA3_VERSION}-Linux-x86_64.sh)
    set(MINICONDA_URL https://repo.continuum.io/miniconda/${MINICONDA_FILE})
    find_program(WGET wget)
    add_custom_command(
      OUTPUT ${ENV_DIR}/${MINICONDA_FILE}
      COMMAND ${CMAKE_COMMAND} -E make_directory ${ENV_DIR}
      COMMAND ${WGET} ${MINICONDA_URL} -O ${ENV_DIR}/${MINICONDA_FILE}
      COMMAND ${CMAKE_COMMAND} -E touch ${ENV_DIR}/${MINICONDA_FILE}
      DEPENDS ${WGET})
    set(CONDA_DIR ${ENV_DIR}/conda)
    set_target_properties(env PROPERTIES CONDA_DIR ${CONDA_DIR})

    set(CONDA_BIN ${CONDA_DIR}/bin/conda)
    set_target_properties(env PROPERTIES CONDA_BIN ${CONDA_BIN})
    set(OUTPUTS ${CONDA_BIN})
    foreach(BINARY ${MAYBE_CONDA_BINARIES})
      list(APPEND OUTPUTS ${CONDA_DIR}/bin/${BINARY})
    endforeach()

    add_file_target(FILE ${REL_ENV_DIR}/${MINICONDA_FILE} GENERATED)
    set(DEPS "")
    append_file_dependency(DEPS ${REL_ENV_DIR}/${MINICONDA_FILE})

    add_custom_command(
      OUTPUT ${OUTPUTS}
      COMMAND sh ${ENV_DIR}/${MINICONDA_FILE} -p ${CONDA_DIR} -b -f
      COMMAND ${CONDA_BIN} config --system --set always_yes yes
      COMMAND ${CONDA_BIN} config --system --add envs_dirs ${CONDA_DIR}/envs
      COMMAND ${CONDA_BIN} config --system --add pkgs_dirs ${CONDA_DIR}/pkgs
      COMMAND ${CONDA_BIN} config --add channels m-labs
      COMMAND ${CONDA_BIN} config --add channels conda-forge
      COMMAND ${CONDA_BIN} config --add channels pkgw-forge
      # Make sure symbiflow is highest priority channel
      COMMAND ${CONDA_BIN} config --add channels symbiflow
      COMMAND ${CONDA_BIN} install lxml
      COMMAND ${CMAKE_COMMAND} -E touch_nocreate ${CONDA_BIN}
      DEPENDS ${DEPS}
      )

    add_file_target(FILE ${REL_ENV_DIR}/conda/bin/conda GENERATED)
    append_file_dependency(DEPS ${REL_ENV_DIR}/conda/bin/conda)

    add_custom_target(
      conda DEPENDS ${DEPS}
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

    get_target_property_required(PIP env PIP)
    add_custom_target(clean_conda_locks
        COMMAND ${CMAKE_COMMAND} -E remove -f ${CONDA_BIN}.lock
        COMMAND ${CMAKE_COMMAND} -E remove -f ${PIP}.lock
        )

    add_dependencies(clean_locks clean_conda_locks)
  else()
    set_target_properties(env PROPERTIES USE_CONDA FALSE)
    foreach(binary ${MAYBE_CONDA_BINARIES})
      string(TOUPPER ${binary} binary_upper)
      if(DEFINED ENV{${binary_upper}})
        set(${binary_upper} $ENV{${binary_upper}})
      else()
        find_program(${binary_upper} ${binary})
      endif()
      # pip is not required for USE_CONDA=false
      if(NOT ${binary_upper} AND (NOT ${binary} STREQUAL "pip"))
        message(FATAL_ERROR "Could not find program ${binary}.")
      endif()
      add_custom_target(${binary})
      set_target_properties(env PROPERTIES
        ${binary_upper} ${${binary_upper}}
        ${binary_upper}_TARGET ${binary}
        )
    endforeach()
  endif()

  set(YOSYS_DATADIR ${ENV_DIR}/conda/share/yosys CACHE PATH "Path to yosys data directory")
  set(VPR_CAPNP_SCHEMA_DIR ${ENV_DIR}/conda/capnp CACHE PATH "Path to VPR schema directory")

  set_target_properties(env PROPERTIES
    QUIET_CMD ${symbiflow-arch-defs_SOURCE_DIR}/utils/quiet_cmd.sh
    QUIET_CMD_TARGET ""
    )
endfunction()

function(ADD_CONDA_PACKAGE)
  # ~~~
  # ADD_CONDA_PACKAGE(
  #   NAME <name>
  #   PROVIDES <exe list>
  #   [PACKAGE_SPEC <package_spec>]
  #   [NO_EXE]
  #   )
  # ~~~
  #
  # Installs a package via conda.  This generates two env properties per name
  # in PROVIDES list. <name> is set to the path the executable.  <name>_TARGET
  # is set to the target that will invoke conda.
  #
  # PACKAGE_SPEC can optionally be provided. This is useful to specify
  # version and build for debugging. See conda documention for details:
  # https://docs.conda.io/projects/conda-build/en/latest/source/package-spec.html#package-match-specifications
  # Find specific versions and builds: conda search <package>
  #
  set(options NO_EXE)
  set(oneValueArgs NAME PACKAGE_SPEC)
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

    if(${ADD_CONDA_PACKAGE_NO_EXE})
      list(LENGTH "${ADD_CONDA_PACKAGE_PROVIDES}" PROVIDES_LENGTH)
      if (NOT ${PROVIDES_LENGTH} EQUAL "0")
        message(FATAL_ERROR "for NO_EXE ${ADD_CONDA_PACKAGE_NAME} do not set PROVIDE")
      endif()
      set(ADD_CONDA_PACKAGE_PROVIDES ${ADD_CONDA_PACKAGE_NAME})

      list(APPEND OUTPUTS ${ADD_CONDA_PACKAGE_NAME}.conda)
      list(APPEND TOUCH_COMMANDS COMMAND ${CMAKE_COMMAND} -E touch ${ADD_CONDA_PACKAGE_NAME}.conda)
    else()
      foreach(OUTPUT ${ADD_CONDA_PACKAGE_PROVIDES})
        list(APPEND OUTPUTS ${CONDA_DIR}/bin/${OUTPUT})
        list(APPEND TOUCH_COMMANDS COMMAND ${CMAKE_COMMAND} -E touch_nocreate ${CONDA_DIR}/bin/${OUTPUT})
      endforeach()
    endif()

    if(NOT ${ADD_CONDA_PACKAGE_PACKAGE_SPEC} STREQUAL "")
      set(PACKAGE_SPEC ${ADD_CONDA_PACKAGE_PACKAGE_SPEC})
    else()
      set(PACKAGE_SPEC ${ADD_CONDA_PACKAGE_NAME})
    endif()

    add_custom_command(
      OUTPUT ${OUTPUTS}
      COMMAND ${CMAKE_COMMAND} -E echo "Taking ${CONDA_BIN}.lock"
      COMMAND flock ${CONDA_BIN}.lock ${CONDA_BIN} install --force ${PACKAGE_SPEC}
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
      if(DEFINED ENV{${binary_upper}})
        set(${binary_upper} $ENV{${binary_upper}})
      else()
        find_program(${binary_upper} ${OUTPUT})
      endif()
      if(NOT ${binary_upper})
        message(FATAL_ERROR "Could not find program ${OUTPUT}.")
      endif()
      add_custom_target(${OUTPUT})
      set_target_properties(env PROPERTIES
        ${binary_upper} ${${binary_upper}}
        ${binary_upper}_TARGET ${OUTPUT})
    endforeach()
  endif()
endfunction()

function(ADD_CONDA_PIP)
  # ~~~
  # ADD_CONDA_PIP(
  #   NAME <name>
  #   [PACKAGE_SPEC <package_spec>]
  #   [NO_EXE]
  #   )
  # ~~~
  #
  # Installs an executable via conda PIP.  This generates two env properties.
  # <name> is set to the path to the executable. <name>_TARGET is set to the
  # target that will invoke pip if not already installed.
  set(options NO_EXE)
  set(oneValueArgs NAME PACKAGE_SPEC)
  set(multiValueArgs)
  cmake_parse_arguments(
    ADD_CONDA_PIP
    "${options}"
    "${oneValueArgs}"
    "${multiValueArgs}"
    ${ARGN}
  )

  set(NAME ${ADD_CONDA_PIP_NAME})
  if(NOT ${ADD_CONDA_PIP_PACKAGE_SPEC} STREQUAL "")
    set(PACKAGE_SPEC "${ADD_CONDA_PIP_NAME}==${ADD_CONDA_PIP_PACKAGE_SPEC}")
  else()
    set(PACKAGE_SPEC ${ADD_CONDA_PIP_NAME})
  endif()

  get_target_property_required(USE_CONDA env USE_CONDA)
  string(TOUPPER ${NAME} binary_upper)
  if(${USE_CONDA})
    get_target_property_required(CONDA_DIR env CONDA_DIR)
    get_target_property_required(PIP env PIP)
    get_target_property_required(PYTHON3 env PYTHON3)
    get_target_property(PIP_TARGET env PIP_TARGET)

    if(ADD_CONDA_PIP_NO_EXE)
      add_custom_command(
        OUTPUT ${NAME}.pip
        COMMAND ${CMAKE_COMMAND} -E echo "Taking ${PIP}.lock"
        COMMAND flock ${PIP}.lock ${PYTHON3} -m pip install ${PACKAGE_SPEC}
        COMMAND ${CMAKE_COMMAND} -E touch ${NAME}.pip
        DEPENDS ${PYTHON3} ${PIP} ${PIP_TARGET}
        )

      add_custom_target(
        ${NAME}
        DEPENDS ${NAME}.pip
        )
      set_target_properties(env PROPERTIES ${binary_upper}_TARGET ${NAME})
    else()
      set(BIN ${CONDA_DIR}/bin/${NAME})
      add_custom_command(
        OUTPUT ${BIN}
        COMMAND ${CMAKE_COMMAND} -E echo "Taking ${PIP}.lock"
        COMMAND flock ${PIP}.lock ${PYTHON3} -m pip install ${PACKAGE_SPEC}
        DEPENDS ${PYTHON3} ${PIP} ${PIP_TARGET}
        )
      add_custom_target(
        ${NAME}
        DEPENDS ${BIN}
        )

      set(${binary_upper} ${BIN})
      replace_with_env_if_set(${binary_upper})
      set_target_properties(env PROPERTIES ${binary_upper} ${BIN})
      set_target_properties(env PROPERTIES ${binary_upper}_TARGET ${NAME})
    endif()

    add_dependencies(all_pip ${NAME})
    add_dependencies(all_conda ${NAME})

    add_custom_target(
      _clean_pip_${NAME}
      COMMAND ${PIP} uninstall -y ${NAME}
      )
    add_dependencies(clean_pip _clean_pip_${NAME})
  else()
    if(ADD_CONDA_PIP_NO_EXE)
      add_custom_target(${NAME})
      string(TOUPPER ${NAME} name_upper)
      set_target_properties(env PROPERTIES ${name_upper}_TARGET ${NAME})
    else()
      if(DEFINED ENV{${binary_upper}})
        set(${binary_upper} $ENV{${binary_upper}})
      else()
        find_program(${binary_upper} ${NAME})
      endif()
      if(NOT ${binary_upper})
        message(FATAL_ERROR "Could not find program ${NAME}.")
      endif()
      set_target_properties(env PROPERTIES ${binary_upper} ${${binary_upper}})
      set_target_properties(env PROPERTIES ${binary_upper}_TARGET "")
    endif()
  endif()
endfunction()



function(ADD_THIRDPARTY_PACKAGE)
  # ~~~
  # ADD_THIRDPARTY_PACKAGE(
  #   NAME <name>
  #   [NO_EXE]
  #   [PROVIDES <exe list>]
  #   [FILES <file list>]
  #   [BUILD_INSTALL_COMMAND <build_install command>]
  #   [DEPENDS <dependencies>]
  #   )
  # ~~~
  #
  # Provide target and dependency for thirdparty software
  # Package should be install in env directory.
  # This generates two env properties per name
  # in PROVIDES list. <name> is set to the path the executable.  <name>_TARGET
  # is set to the target that will invoke conda.
  #
  # The FILES argument is for non-binary outputs of the add_thirdparty_package.
  #
  set(options NO_EXE)
  set(oneValueArgs NAME BUILD_INSTALL_COMMAND)
  set(multiValueArgs PROVIDES FILES DEPENDS)
  cmake_parse_arguments(
    ADD_THIRDPARTY_PACKAGE
    "${options}"
    "${oneValueArgs}"
    "${multiValueArgs}"
    ${ARGN}
  )

  set(NAME ${ADD_THIRDPARTY_PACKAGE_NAME})
  get_target_property_required(USE_CONDA env USE_CONDA)

  #if using conda and a command given, run it then look in conda
  # otherwise just look for it. This is so python packages show up in site-packages
  if( ${USE_CONDA})
    if (NOT ADD_THIRDPARTY_PACKAGE_BUILD_INSTALL_COMMAND)
      message(FATAL_ERROR "BUILD_INSTALL_COMMAND not supplied for thirdparty package ${NAME}")
    endif()

    set(INSTALL_COMMAND ${ADD_THIRDPARTY_PACKAGE_BUILD_INSTALL_COMMAND})

    set(OUTPUTS "")
    set(TOUCH_COMMANDS "")
    get_target_property_required(PREFIX env CONDA_DIR)

    if(${ADD_THIRDPARTY_PACKAGE_NO_EXE})
      list(APPEND OUTPUTS ${PREFIX}/bin/${ADD_THIRDPARTY_PACKAGE_NAME}.install)
      list(APPEND TOUCH_COMMANDS COMMAND ${CMAKE_COMMAND} -E touch ${PREFIX}/bin/${ADD_THIRDPARTY_PACKAGE_NAME}.install)
    else()
      foreach(OUTPUT ${ADD_THIRDPARTY_PACKAGE_PROVIDES})
        list(APPEND OUTPUTS ${PREFIX}/bin/${OUTPUT})
        list(APPEND TOUCH_COMMANDS COMMAND ${CMAKE_COMMAND} -E touch_nocreate ${PREFIX}/bin/${OUTPUT})
      endforeach()
      foreach(OUTPUT ${ADD_THIRDPARTY_PACKAGE_FILES})
        list(APPEND OUTPUTS ${PREFIX}/${OUTPUT})
      endforeach()
    endif()

    get_target_property_required(PIP env PIP)

    add_custom_command(
      OUTPUT ${OUTPUTS}
      COMMAND ${CMAKE_COMMAND} -E echo "Taking ${PIP}.lock"
      COMMAND flock ${PIP}.lock -c "${INSTALL_COMMAND}"
      ${TOUCH_COMMANDS}
      DEPENDS ${ADD_THIRDPARTY_PACKAGE_DEPENDS}
      VERBATIM
      )

    add_custom_target(${NAME} DEPENDS ${OUTPUTS})
    string(TOUPPER ${NAME} name_upper)
    set_target_properties(env PROPERTIES ${name_upper}_TARGET ${NAME})

    foreach(OUTPUT ${ADD_THIRDPARTY_PACKAGE_PROVIDES})
      string(TOUPPER ${OUTPUT} binary_upper)
      set(${binary_upper} ${PREFIX}/bin/${OUTPUT})
      replace_with_env_if_set(${binary_upper})
      set_target_properties(env PROPERTIES
        ${binary_upper} ${${binary_upper}}
        ${binary_upper}_TARGET ${NAME})
    endforeach()
  else()
    add_custom_target(${NAME})
    string(TOUPPER ${NAME} name_upper)
    set_target_properties(env PROPERTIES ${name_upper}_TARGET ${NAME})
    if(NOT ${ADD_THIRDPARTY_PACKAGE_NO_EXE})
      # if command not provide, just look the provides
      foreach(OUTPUT ${ADD_THIRDPARTY_PACKAGE_PROVIDES})
        string(TOUPPER ${OUTPUT} binary_upper)
        if(DEFINED ENV{${binary_upper}})
          set(${binary_upper} $ENV{${binary_upper}})
        else()
          find_program(${binary_upper} ${OUTPUT})
        endif()
        if(NOT ${binary_upper})
          message(FATAL_ERROR "Could not find program ${OUTPUT}.")
        endif()
        if(NOT TARGET ${OUTPUT})
          add_custom_target(${OUTPUT})
        endif()
        set_target_properties(env PROPERTIES
          ${binary_upper} ${${binary_upper}}
          ${binary_upper}_TARGET ${OUTPUT})
      endforeach()
    endif()
  endif()

endfunction(ADD_THIRDPARTY_PACKAGE)
