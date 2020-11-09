function(QUICKLOGIC_FASM)
  # ~~~
  # QUICKLOGIC_FASM(
  # NAME <name>
  # FILE <input-file-name>
  # OUTPUT <output-file-name>
  # [VERBOSE]
  # )
  #
  # Generates a bitstream from the FASM files for the QuickLogic FPGAs using qlfasm.
  set(options VERBOSE)
  set(oneValueArgs NAME FILE OUTPUT)
  set(multiValueArgs)
  cmake_parse_arguments(
    QUICKLOGIC_FASM
    "${options}"
    "${oneValueArgs}"
    "${multiValueArgs}"
    ${ARGN}
    )

  get_target_property_required(QLFASM env QLFASM)

  set(DEPS "")
  append_file_dependency(DEPS ${QUICKLOGIC_FASM_FILE})

  set(CMD_ARGS "")
  if(${QUICKLOGIC_FASM_VERBOSE})
    list(APPEND CMD_ARGS "-v")
  endif()

  add_custom_command(
    OUTPUT ${QUICKLOGIC_FASM_OUTPUT}
    DEPENDS ${DEPS} ${QLFASM}
    COMMAND qlfasm ${CMD_ARGS} ${QUICKLOGIC_FASM_FILE} ${QUICKLOGIC_FASM_OUTPUT}
    )
  add_file_target(FILE ${QUICKLOGIC_FASM_OUTPUT} GENERATED)

  get_rel_target(REL_QUICKLOGIC_FASM_NAME quicklogic_fasm ${QUICKLOGIC_FASM_NAME})
  add_custom_target(
    ${REL_QUICKLOGIC_FASM_NAME}
    DEPENDS ${QUICKLOGIC_FASM_OUTPUT}
    )
endfunction(QUICKLOGIC_FASM)
