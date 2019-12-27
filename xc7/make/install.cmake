function(DEFINE_XC7_TOOLCHAIN_TARGET)
  set(options)
  set(oneValueArgs ARCH CONV_SCRIPT SYNTH_SCRIPT BIT_TO_BIN)
  set(multiValueArgs)

  cmake_parse_arguments(
    DEFINE_XC7_TOOLCHAIN_TARGET
    "${options}"
    "${oneValueArgs}"
    "${multiValueArgs}"
    "${ARGN}"
  )

  get_target_property_required(YOSYS env YOSYS)
  get_target_property(YOSYS_TARGET env YOSYS_TARGET)
  get_target_property_required(VPR env VPR)
  get_target_property(VPR_TARGET env VPR_TARGET)
  get_target_property_required(GENFASM env GENFASM)
  get_target_property(GENFASM_TARGET env GENFASM_TARGET)

  set(ARCH ${DEFINE_XC7_TOOLCHAIN_TARGET_ARCH})
  get_target_property_required(FASM_TO_BIT ${ARCH} FASM_TO_BIT)

  set(YOSYS_BINS "${YOSYS}" "${YOSYS}-abc" "${YOSYS}-smtbmc" "${YOSYS}-filterlib" "${YOSYS}-config")

  # install binaries
  install(FILES ${YOSYS_BINS} ${VPR} ${GENFASM}
          DESTINATION bin
          PERMISSIONS WORLD_EXECUTE WORLD_READ OWNER_WRITE OWNER_READ OWNER_EXECUTE GROUP_READ GROUP_EXECUTE)

  install(TARGETS ${DEFINE_XC7_TOOLCHAIN_TARGET_BIT_TO_BIN}
          RUNTIME
          DESTINATION bin
          PERMISSIONS WORLD_EXECUTE WORLD_READ OWNER_WRITE OWNER_READ OWNER_EXECUTE GROUP_READ GROUP_EXECUTE)

  # install python scripts
  install(FILES ${FASM_TO_BIT}
          DESTINATION bin/python
          PERMISSIONS WORLD_EXECUTE WORLD_READ OWNER_WRITE OWNER_READ OWNER_EXECUTE GROUP_READ GROUP_EXECUTE)

  # install yosys data
  install(DIRECTORY ${YOSYS_DATADIR}
          DESTINATION share)

  # install prjxray techmap
  install(DIRECTORY ${symbiflow-arch-defs_SOURCE_DIR}/xc7/techmap
          DESTINATION share/prjxray)

  # install Yosys script
  install(FILES ${DEFINE_XC7_TOOLCHAIN_TARGET_SYNTH_SCRIPT} ${DEFINE_XC7_TOOLCHAIN_TARGET_CONV_SCRIPT}
          DESTINATION share/prjxray)

endfunction()
