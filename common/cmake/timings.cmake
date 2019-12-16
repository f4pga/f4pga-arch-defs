function(UPDATE_ARCH_TIMINGS)
  set(options)
  set(oneValueArgs INPUT OUTPUT)
  set(multiValueArgs)
  cmake_parse_arguments(
    UPDATE_ARCH_TIMINGS
    "${options}"
    "${oneValueArgs}"
    "${multiValueArgs}"
    ${ARGN}
  )

  set(input ${UPDATE_ARCH_TIMINGS_INPUT})
  set(output ${UPDATE_ARCH_TIMINGS_OUTPUT})

  add_file_target(FILE ${output} GENERATED)

  if(IS_DIRECTORY ${SDF_TIMING_DIRECTORY} AND EXISTS ${BELS_MAP})
    get_target_property_required(PYTHON3 env PYTHON3)
    get_target_property(PYTHON3_TARGET env PYTHON3_TARGET)

    set(update_arch_timings ${symbiflow-arch-defs_SOURCE_DIR}/utils/update_arch_timings.py)

    add_custom_command(
      OUTPUT ${output}
      DEPENDS
        ${PYTHON3} ${PYTHON3_TARGET}
        ${update_arch_timings}
        ${input}
      COMMAND
      PYTHONPATH=${symbiflow-arch-defs_SOURCE_DIR}/third_party/python-sdf-timing:${symbiflow-arch-defs_BINARY_DIR}/env/conda/lib/python3.7/site-packages
        ${PYTHON3} ${update_arch_timings}
          --sdf_dir ${SDF_TIMING_DIRECTORY}
          --bels_map ${BELS_MAP}
          --input_arch ${input}
          --out_arch ${output}
    )
  else()
    configure_file(${input} ${output} COPY_ONLY)
  endif()
endfunction(UPDATE_ARCH_TIMINGS)
