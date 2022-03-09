function(ADD_QUICKLOGIC_PLUGINS)
  set(QLFPGA_LATEST_URL https://storage.googleapis.com/symbiflow-arch-defs-install/qlfpga_symbiflow_plugins/qlf_k4n8/latest)

  set(QLFPGA_LATEST_REL		    latest)
  set(QLFPGA_REPACKING_RULES_REL    repacking_rules.json)
  set(QLFPGA_FASM_DB_TAR_GZ_REL	    fasm_database.tar.gz)
  set(QLFPGA_FASM_DB_REL	    fasm_database)
  set(QLFPGA_FAST_VPR_ARCH_REL	    fast/vpr_arch/UMC22nm_vpr.xml)
  set(QLFPGA_FAST_VPR_RR_GRAPH_REL  fast/vpr_rr_graph/UMC22nm_vpr.bin.gz)
  set(QLFPGA_SLOW_VPR_ARCH_REL	    slow/vpr_arch/UMC22nm_vpr.xml)
  set(QLFPGA_SLOW_VPR_RR_GRAPH_REL  slow/vpr_rr_graph/UMC22nm_vpr.bin.gz)

  set(QLFPGA_BASE_DIR		    third_party/qlfpga-symbiflow-plugins/qlf_k4n8)

  set(QLFPGA_LATEST		    ${QLFPGA_BASE_DIR}/${QLFPGA_LATEST_REL})
  set(QLFPGA_REPACKING_RULES	    ${QLFPGA_BASE_DIR}/${QLFPGA_REPACKING_RULES_REL})
  set(QLFPGA_FASM_DB_TAR_GZ	    ${QLFPGA_BASE_DIR}/${QLFPGA_FASM_DB_TAR_GZ_REL})
  set(QLFPGA_FASM_DB		    ${QLFPGA_BASE_DIR}/${QLFPGA_FASM_DB_REL})
  set(QLFPGA_FAST_VPR_ARCH	    ${QLFPGA_BASE_DIR}/${QLFPGA_FAST_VPR_ARCH_REL})
  set(QLFPGA_FAST_VPR_RR_GRAPH	    ${QLFPGA_BASE_DIR}/${QLFPGA_FAST_VPR_RR_GRAPH_REL})
  set(QLFPGA_SLOW_VPR_ARCH	    ${QLFPGA_BASE_DIR}/${QLFPGA_SLOW_VPR_ARCH_REL})
  set(QLFPGA_SLOW_VPR_RR_GRAPH	    ${QLFPGA_BASE_DIR}/${QLFPGA_SLOW_VPR_RR_GRAPH_REL})

  # File with pointer to the latest version of qlfpga plugins
  add_custom_command(
	OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/${QLFPGA_LATEST}
    COMMAND
        ${CMAKE_COMMAND} -E make_directory
            ${QLFPGA_BASE_DIR}
	COMMAND bash -c
		'wget ${QLFPGA_LATEST_URL} -O ${QLFPGA_LATEST}'
	COMMENT "Generating ${QLFPGA_LATEST}"
  )
  add_file_target(FILE ${QLFPGA_LATEST} GENERATED)

  fetch_qlfpga(${QLFPGA_REPACKING_RULES}    ${QLFPGA_REPACKING_RULES_REL})
  fetch_qlfpga(${QLFPGA_FASM_DB_TAR_GZ}	    ${QLFPGA_FASM_DB_TAR_GZ_REL})
  fetch_qlfpga(${QLFPGA_FAST_VPR_ARCH}	    ${QLFPGA_FAST_VPR_ARCH_REL})
  fetch_qlfpga(${QLFPGA_FAST_VPR_RR_GRAPH}  ${QLFPGA_FAST_VPR_RR_GRAPH_REL})
  fetch_qlfpga(${QLFPGA_SLOW_VPR_ARCH}	    ${QLFPGA_SLOW_VPR_ARCH_REL})
  fetch_qlfpga(${QLFPGA_SLOW_VPR_RR_GRAPH}  ${QLFPGA_SLOW_VPR_RR_GRAPH_REL})

  get_file_target(QLFPGA_FASM_DB_TAR_GZ_TARGET ${QLFPGA_FASM_DB_TAR_GZ})
  add_custom_command(
	OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/${QLFPGA_FASM_DB}
	COMMAND bash -c 'tar -xf ${QLFPGA_FASM_DB_TAR_GZ} -C ${QLFPGA_BASE_DIR}'
        DEPENDS ${QLFPGA_FASM_DB_TAR_GZ_TARGET}
	COMMENT "Generating ${QLFPGA_FASM_DB}"
  )
  add_file_target(FILE ${QLFPGA_FASM_DB} GENERATED)

  set(QLFPGA_PLUGINS_FILES
    ${QLFPGA_REPACKING_RULES}
    ${QLFPGA_FASM_DB}
    ${QLFPGA_FAST_VPR_ARCH}
    ${QLFPGA_FAST_VPR_RR_GRAPH}
    ${QLFPGA_SLOW_VPR_ARCH}
    ${QLFPGA_SLOW_VPR_RR_GRAPH}
  )

  set(QLFPGA_PLUGINS_DEPS )
  foreach(FILE_NAME ${QLFPGA_PLUGINS_FILES})
    get_file_target(FILE_TARGET ${FILE_NAME})
    list(APPEND QLFPGA_PLUGINS_DEPS ${FILE_TARGET})
  endforeach()

  add_custom_target(qlfpga_plugins
    DEPENDS ${QLFPGA_PLUGINS_DEPS}
  )
endfunction()

function(FETCH_QLFPGA FILE_PATH FILE_REL_PATH)

  get_filename_component(FILE_DIRECTORY ${FILE_PATH} DIRECTORY)
  get_file_target(QLFPGA_LATEST_TARGET ${QLFPGA_LATEST})

  add_custom_command(
	OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/${FILE_PATH}
    COMMAND ${CMAKE_COMMAND} -E make_directory ${FILE_DIRECTORY}
	COMMAND bash -c 'wget `cat ${QLFPGA_LATEST}`/${FILE_REL_PATH} -O ${FILE_PATH}'
	DEPENDS ${QLFPGA_LATEST_TARGET}
	COMMENT "Generating ${FILE_PATH}"
  )
  add_file_target(FILE ${FILE_PATH} GENERATED)
endfunction()
