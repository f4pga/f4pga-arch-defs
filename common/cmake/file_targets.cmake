# This CMake include file defines utility functions for handling generated files
# that are required in another CMake directory other than the one where it was
# generated.
#
# Key functions:
#
# * ADD_FILE_TARGET - Creates a file target.  All source files, whether
#   generated or not should call this function.
# * GET_FILE_TARGET - Given a absolute or local source path, what is the target
#   that will build this file.
# * GET_REL_TARGET - Given a absolute or local source path and prefix
#   generates target name in a form $prefix_$file.
# * GET_FILE_LOCATION - Given a absolute or local source path, what is the
#   actual location of the file.
#
# When writing targets that rely on files using these functions, never use a raw
# source path, e.g. ${CMAKE_CURRENT_SOURCE_DIR}/example_dir/example.file or
# example.file.  Instead always call GET_FILE_LOCATION on the path.  This is
# because the actual source location may not be in the source tree, but instead
# be in the build tree.
#
# When writing targets that rely on files using these functions, always DEPEND
# on both the file location (from GET_FILE_LOCATION) and the file target (from
# GET_FILE_TARGET).  If you only DEPEND on the file location, the file will not
# be generated the first time through the build.
#
# Utility functions:
#
# * APPEND_FILE_LOCATION - Appends to a list the file location of specified
#   file.
# * APPEND_FILE_DEPENDENCY - Appends to a list both the file location and file
#   target of specified file.
function(GET_REL_TARGET var prefix src_file)
  if(${src_file} MATCHES "^/")
    set(SOURCE_LOCATION ${src_file})
  else()
    set(SOURCE_LOCATION ${CMAKE_CURRENT_SOURCE_DIR}/${src_file})
  endif()

  get_filename_component(CANON_LOCATION ${SOURCE_LOCATION}
      ABSOLUTE
      BASE_DIR ${symbiflow-arch-defs_SOURCE_DIR}
      )

  string(
    REPLACE
      "${symbiflow-arch-defs_SOURCE_DIR}"
      ""
      REL_CANON_LOCATION
      ${CANON_LOCATION}
      )
  string(
    REPLACE
      "/"
      "_"
      TARGET_PATH
      ${REL_CANON_LOCATION}
  )
  set(${var} ${prefix}${TARGET_PATH} PARENT_SCOPE)
endfunction()

function(GET_FILE_TARGET var src_file)
  get_rel_target(TARGET_PATH file ${src_file})
  set(${var} ${TARGET_PATH} PARENT_SCOPE)
endfunction()

function(GET_FILE_LOCATION var src_file)
  # Sets var in PARENT_SCOPE to file location for given src_file.
  get_file_target(SRC_TARGET ${src_file})
  get_target_property(SRC_LOCATION ${SRC_TARGET} LOCATION)
  if("${SRC_LOCATION}" STREQUAL "NOT_FOUND")
    message(
      FATAL_ERROR
        "File ${src_file} is not a valid verilog target, missing LOCATION."
    )
  endif()

  set(${var} ${SRC_LOCATION} PARENT_SCOPE)
endfunction()

function(APPEND_FILE_LOCATION var src_file)
  # Appends to list var in PARENT_SCOPE both file location for
  # given src_file.
  get_file_target(SRC_TARGET ${src_file})
  get_target_property(SRC_LOCATION ${SRC_TARGET} LOCATION)
  if("${SRC_LOCATION}" STREQUAL "NOT_FOUND")
    message(
      FATAL_ERROR
        "File ${src_file} is not a valid verilog target, missing LOCATION."
    )
  endif()

  list(APPEND ${var} ${SRC_LOCATION})
  set(${var} "${${var}}" PARENT_SCOPE)
endfunction()

function(APPEND_FILE_DEPENDENCY var src_file)
  # Appends to list var in PARENT_SCOPE both file location and file target for
  # given src_file.
  get_file_target(SRC_TARGET ${src_file})
  get_target_property(SRC_LOCATION ${SRC_TARGET} LOCATION)
  if("${SRC_LOCATION}" STREQUAL "NOT_FOUND")
    message(
      FATAL_ERROR
        "File ${src_file} is not a valid verilog target, missing LOCATION."
    )
  endif()

  list(APPEND ${var} ${SRC_TARGET})
  list(APPEND ${var} ${SRC_LOCATION})

  get_target_property(INCLUDE_FILES ${SRC_TARGET} INCLUDE_FILES)
  foreach(SRC ${INCLUDE_FILES})
    append_file_dependency(${var} ${SRC})
  endforeach()
  set(${var} "${${var}}" PARENT_SCOPE)
endfunction()

function(APPEND_FILE_INCLUDES var src_file)
  # Appends to list var in PARENT_SCOPE both includes listed for file target for
  # given src_file.
  get_file_target(SRC_TARGET ${src_file})
  get_target_property(SRC_INCLUDES ${SRC_TARGET} INCLUDES)
  if("${SRC_INCLUDES}" STREQUAL "NOT_FOUND")
    message(
      FATAL_ERROR
        "File ${SRC} is not a valid verilog target, missing INCLUDES list."
    )
  endif()

  list(APPEND ${var} ${SRC_INCLUDES})
  set(${var} "${${var}}" PARENT_SCOPE)
endfunction()

function(GET_VERILOG_INCLUDES var file)
  # Appends to list var in PARENT_SCOPE all verilog source dependency based on
  # scanning input at configure time.
  #
  # Note this function cannot be used at generation time because execute_process
  # is called during configure step and generated files don't exist yet.
  execute_process(
    COMMAND
      ${PYTHON_EXECUTABLE} ${symbiflow-arch-defs_SOURCE_DIR}/utils/deps_verilog.py
      --file_per_line ${CMAKE_CURRENT_SOURCE_DIR}/${file}
    WORKING_DIRECTORY ${symbiflow-arch-defs_SOURCE_DIR}
    OUTPUT_VARIABLE INCLUDES
  )

  string(
    REPLACE
      "\n"
      ";"
      INCLUDES_LIST
      "${INCLUDES}"
  )
  foreach(INCLUDE ${INCLUDES_LIST})
    string(STRIP ${INCLUDE} INCLUDE)
    if(NOT "${INCLUDE}" STREQUAL "")
      get_filename_component(
        ABS_PATH_TO_INCLUDE
        ${INCLUDE}
        ABSOLUTE
        BASE_DIR
        ${symbiflow-arch-defs_SOURCE_DIR}
      )
      list(APPEND ${var} ${ABS_PATH_TO_INCLUDE})
    endif()
  endforeach()
  set(${var} "${${var}}" PARENT_SCOPE)
endfunction()

function(GET_XML_INCLUDES var file)
  # Appends to list var in PARENT_SCOPE all xml source dependency based on
  # scanning input at configure time.
  #
  # Note this function cannot be used at generation time because execute_process
  # is called during configure step and generated files don't exist yet.
  execute_process(
    COMMAND
      ${PYTHON_EXECUTABLE} ${symbiflow-arch-defs_SOURCE_DIR}/utils/deps_xml.py
      --file_per_line ${CMAKE_CURRENT_SOURCE_DIR}/${file}
    WORKING_DIRECTORY ${symbiflow-arch-defs_SOURCE_DIR}
    OUTPUT_VARIABLE INCLUDES
  )

  string(
    REPLACE
      "\n"
      ";"
      INCLUDES_LIST
      "${INCLUDES}"
  )
  foreach(INCLUDE ${INCLUDES_LIST})
    string(STRIP ${INCLUDE} INCLUDE)
    if(NOT "${INCLUDE}" STREQUAL "")
      get_filename_component(
        ABS_PATH_TO_INCLUDE
        ${INCLUDE}
        ABSOLUTE
        BASE_DIR
        ${symbiflow-arch-defs_SOURCE_DIR}
      )
      list(APPEND ${var} ${ABS_PATH_TO_INCLUDE})
    endif()
  endforeach()
  set(${var} "${${var}}" PARENT_SCOPE)
endfunction()

function(ADD_FILE_TARGET)
  # ~~~
  # ADD_FILE_TARGET(
  #   FILE <source file location>
  #   [GENERATED | SCANNER_TYPE <verilog|xml>]
  #   [ABSOLUTE]
  #   )
  # ~~~
  #
  # Creates new file target for given source location.  Even if ADD_FILE_TARGET
  # is being called on a file that is located in the binary directory, always
  # pass the source location it would have if the source and binary directories
  # were the same.  This is important for dependency definitions that assume all
  # inputs are in one folder.
  #
  # ADD_FILE_TARGET ensures that all sources are in one folder, because of how
  # the verilog include directive is defined.
  #
  # SCANNER_TYPE argument can be used if GENERATED or ABSOLUTE are not set.  Valid
  # SCANNER_TYPE are "verilog" and "xml".
  # ABSOLUTE parameter must be used to mark passed path is absolute
  #
  # GENERATED must be passed if the source file is generated and is placed
  # within the binary directory.
  set(options GENERATED ABSOLUTE)
  set(oneValueArgs FILE SCANNER_TYPE)
  set(multiValueArgs)
  cmake_parse_arguments(
    ADD_FILE_TARGET
    "${options}"
    "${oneValueArgs}"
    "${multiValueArgs}"
    ${ARGN}
  )

  get_file_target(TARGET_NAME ${ADD_FILE_TARGET_FILE})

  set(INCLUDE_FILES "")
  if(NOT ${ADD_FILE_TARGET_GENERATED})
    if("${ADD_FILE_TARGET_SCANNER_TYPE}" STREQUAL "")

    elseif("${ADD_FILE_TARGET_SCANNER_TYPE}" STREQUAL "verilog")
      get_verilog_includes(INCLUDE_FILES ${ADD_FILE_TARGET_FILE})
    elseif("${ADD_FILE_TARGET_SCANNER_TYPE}" STREQUAL "xml")
      get_xml_includes(INCLUDE_FILES ${ADD_FILE_TARGET_FILE})
    else()
      message(
        FATAL_ERROR "Unknown SCANNER_TYPE=${ADD_FILE_TARGET_SCANNER_TYPE}."
      )
    endif()
  endif()

  set(INCLUDE_FILES_TARGETS "")
  foreach(INCLUDE ${INCLUDE_FILES})
    append_file_dependency(INCLUDE_FILES_TARGETS ${INCLUDE})
  endforeach()

  if(NOT ${ADD_FILE_TARGET_GENERATED} AND NOT ${ADD_FILE_TARGET_ABSOLUTE})
    get_filename_component(DEST_PATH ${CMAKE_CURRENT_BINARY_DIR}/${ADD_FILE_TARGET_FILE} DIRECTORY)
    add_custom_command(
      OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/${ADD_FILE_TARGET_FILE}
      COMMAND
        ${CMAKE_COMMAND} -E make_directory
        ${DEST_PATH}
      COMMAND
        ${CMAKE_COMMAND} -E create_symlink
        ${CMAKE_CURRENT_SOURCE_DIR}/${ADD_FILE_TARGET_FILE}
        ${CMAKE_CURRENT_BINARY_DIR}/${ADD_FILE_TARGET_FILE}
    )
  endif()

  if(${ADD_FILE_TARGET_ABSOLUTE})
    set(FILE_PATH ${ADD_FILE_TARGET_FILE})
  else()
    set(FILE_PATH ${CMAKE_CURRENT_BINARY_DIR}/${ADD_FILE_TARGET_FILE})
  endif()

  add_custom_target(
    ${TARGET_NAME}
    DEPENDS
      ${FILE_PATH}
      ${INCLUDE_FILES_TARGETS}
  )

  set_target_properties(
    ${TARGET_NAME}
    PROPERTIES LOCATION ${FILE_PATH}
  )
  set_target_properties(${TARGET_NAME} PROPERTIES INCLUDE_FILES "${INCLUDE_FILES}")
  set_target_properties(${TARGET_NAME} PROPERTIES INCLUDES "")
  set_target_properties(${TARGET_NAME} PROPERTIES INCLUDE_FILES "${INCLUDE_FILES}")
endfunction(ADD_FILE_TARGET)
