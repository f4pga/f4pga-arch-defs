function(ADD_JLINK_OUTPUT)
  # ~~~
  # ADD_JLINK_OUTPUT(
  #   PARENT <fpga target name>
  #   )
  # ~~~
  set(options)
  set(oneValueArgs PARENT)
  set(multiValueArgs)
  cmake_parse_arguments(
    ADD_JLINK_OUTPUT
    "${options}"
    "${oneValueArgs}"
    "${multiValueArgs}"
    ${ARGN}
  )

  set(PARENT ${ADD_JLINK_OUTPUT_PARENT})

  get_target_property_required(PYTHON3 env PYTHON3)
  get_target_property_required(PYTHON3_TARGET env PYTHON3_TARGET)

  get_target_property_required(QLFASM_TARGET env QLFASM_TARGET)

  get_target_property_required(EBLIF ${PARENT} EBLIF)
  get_target_property_required(PCF ${PARENT} INPUT_IO_FILE)
  get_target_property_required(BITSTREAM ${PARENT} BIT)

  # Get the output directory
  get_file_location(BITSTREAM_LOC ${BITSTREAM})
  get_filename_component(WORK_DIR ${BITSTREAM_LOC} DIRECTORY)
  file(RELATIVE_PATH WORK_DIR_REL ${CMAKE_CURRENT_BINARY_DIR} ${WORK_DIR})

  get_file_location(EBLIF_LOC ${EBLIF})
  get_file_location(PCF_LOC ${PCF})

  # Generate a JLINK script that sets IOMUX configuration.
  set(IOMUX_CONFIG_GEN ${symbiflow-arch-defs_SOURCE_DIR}/quicklogic/common/utils/eos_s3_iomux_config.py)
  set(IOMUX_CONFIG "top_iomux.jlink")

  add_custom_command(
    OUTPUT ${WORK_DIR}/${IOMUX_CONFIG}
    COMMAND ${CMAKE_COMMAND} -E env PYTHONPATH=${symbiflow-arch-defs_SOURCE_DIR}/utils:$PYTHONPATH
      ${PYTHON3} ${IOMUX_CONFIG_GEN}
        --eblif ${EBLIF_LOC}
        --pcf ${PCF_LOC}
        >${WORK_DIR}/${IOMUX_CONFIG}
    DEPENDS ${PYTHON3_TARGET} ${IOMUX_CONFIG_GEN} ${EBLIF} ${PCF}
  )

  add_file_target(FILE ${WORK_DIR_REL}/${IOMUX_CONFIG} GENERATED)

  # Convert the binary bitstream to a JLINK script
  set(BIT_TO_JLINK ${symbiflow-arch-defs_SOURCE_DIR}/quicklogic/common/utils/quicklogic-fasm/quicklogic_fasm/bitstream_to_jlink.py)
  set(BIT_AS_JLINK "top.bit.jlink")

  add_custom_command(
    OUTPUT ${WORK_DIR}/${BIT_AS_JLINK}
    COMMAND ${PYTHON3} ${BIT_TO_JLINK} ${BITSTREAM_LOC} ${WORK_DIR}/${BIT_AS_JLINK}
    DEPENDS ${PYTHON3_TARGET} ${QLFASM_TARGET} ${BIT_TO_JLINK} ${BITSTREAM}
  )

  add_file_target(FILE ${WORK_DIR_REL}/${BIT_AS_JLINK} GENERATED)

  # Concatenate th bitstream JLink script and the IOMUX config JLink script
  set(OUT_JLINK "top.jlink")
  add_custom_command(
    OUTPUT ${WORK_DIR}/${OUT_JLINK}
    COMMAND cat ${WORK_DIR}/${BIT_AS_JLINK} ${WORK_DIR}/${IOMUX_CONFIG} >${WORK_DIR}/${OUT_JLINK}
    DEPENDS ${WORK_DIR}/${BIT_AS_JLINK} ${WORK_DIR}/${IOMUX_CONFIG}
  )

  add_custom_target(${PARENT}_jlink DEPENDS ${WORK_DIR}/${OUT_JLINK})

endfunction()
