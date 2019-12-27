function(DEFINE_XC7_TOOLCHAIN_TARGET)
  set(options)
  set(oneValueArgs ARCH CONV_SCRIPT SYNTH_SCRIPT BIT_TO_BIN)
  set(multiValueArgs VPR_ARCH_ARGS)

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
  set(VPR_ARCH_ARGS ${DEFINE_XC7_TOOLCHAIN_TARGET_VPR_ARCH_ARGS})
  get_target_property_required(FASM_TO_BIT ${ARCH} FASM_TO_BIT)

  set(YOSYS_BINS "${YOSYS}" "${YOSYS}-abc" "${YOSYS}-smtbmc" "${YOSYS}-filterlib" "${YOSYS}-config")
  set(WRAPPERS env generate_constrains pack place route synth write_bitstream write_fasm)
  set(TOOLCHAIN_WRAPPERS)

  foreach(WRAPPER ${WRAPPERS})
    set(WRAPPER_PATH "${symbiflow-arch-defs_SOURCE_DIR}/xc7/toolchain_wrappers/${WRAPPER}")
    list(APPEND TOOLCHAIN_WRAPPERS ${WRAPPER_PATH})
  endforeach()

  set(VPR_COMMON_TEMPLATE "${symbiflow-arch-defs_SOURCE_DIR}/xc7/toolchain_wrappers/vpr_common")
  set(VPR_COMMON "${CMAKE_CURRENT_BINARY_DIR}/vpr_common")
  configure_file(${VPR_COMMON_TEMPLATE} "${VPR_COMMON}" @ONLY)

  install(FILES ${TOOLCHAIN_WRAPPERS} ${VPR_COMMON}
          DESTINATION bin
          PERMISSIONS WORLD_EXECUTE WORLD_READ OWNER_WRITE OWNER_READ OWNER_EXECUTE GROUP_READ GROUP_EXECUTE)
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

  # install prjxray database
  install(DIRECTORY ${PRJXRAY_DB_DIR}
          DESTINATION share/prjxray)

  # install Yosys scripts
  install(FILES ${DEFINE_XC7_TOOLCHAIN_TARGET_SYNTH_SCRIPT} ${DEFINE_XC7_TOOLCHAIN_TARGET_CONV_SCRIPT}
          DESTINATION share/prjxray)

endfunction()
