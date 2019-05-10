function(ADD_VIVADO_TARGET)
  # ~~~
  # ADD_VIVADO_TARGET(
  #   NAME <name>
  #   PARENT_NAME <name>
  #   CLOCK_PINS list of clock pins
  #   CLOCK_PERIODS list of clock periods
  #   )
  # ~~~
  #
  # ADD_VIVADO_TARGET generates a Vivado project and design checkpoint from
  # output of a 7-series FPGA target.
  #
  # Inputs to Vivado are the output of the FASM to verilog process.
  #
  # PARENT_NAME is the name of the FPGA target being used as input for these
  # targets.
  #
  # CLOCK_PINS and CLOCK_PERIODS should be lists of the same length.
  # CLOCK_PERIODS should be in nanoseconds.
  #
  # New targets:
  #  <NAME>_load_dcp - Launch vivado loading post-routing design checkpoint.
  #  <NAME>_load_xpr - Launch vivado loading project.
  #  <NAME>_sim - Launch vivado and setup simulation and clock forces.
  set(options)
  set(oneValueArgs NAME PARENT_NAME)
  set(multiValueArgs CLOCK_PINS CLOCK_PERIODS)
  cmake_parse_arguments(
    ADD_VIVADO_TARGET
    "${options}"
    "${oneValueArgs}"
    "${multiValueArgs}"
    ${ARGN}
  )

  set(NAME ${ADD_VIVADO_TARGET_NAME})
  if(NOT DEFINED ENV{XRAY_VIVADO_SETTINGS})
      message( WARNING "Vivado targets for ${NAME} not emitted, XRAY_VIVADO_SETTINGS env var must be set to point to Vivado settings.sh" )
      return()
  endif()


  get_target_property_required(BITSTREAM ${ADD_VIVADO_TARGET_PARENT_NAME} BIN)
  get_target_property_required(BIT_VERILOG ${ADD_VIVADO_TARGET_PARENT_NAME} BIT_V)
  get_target_property_required(TOP ${ADD_VIVADO_TARGET_PARENT_NAME} TOP)
  get_target_property_required(BOARD ${ADD_VIVADO_TARGET_PARENT_NAME} BOARD)
  get_target_property_required(DEVICE ${BOARD} DEVICE)
  get_target_property_required(ARCH ${DEVICE} ARCH)
  get_target_property_required(PART ${ARCH}_${DEVICE}_${BOARD} PART)

  set(DEPS)
  append_file_dependency(DEPS ${BIT_VERILOG})

  get_file_location(BIT_VERILOG_LOCATION ${BIT_VERILOG})
  set(BIT_TCL_LOCATION ${BIT_VERILOG_LOCATION}.tcl)

  list(LENGTH ${ADD_VIVADO_TARGET_CLOCK_PINS} NUM_CLOCKS)
  list(LENGTH ${ADD_VIVADO_TARGET_CLOCK_PERIODS} NUM_CLOCK_PERIODS)

  if(NOT ${NUM_CLOCKS} EQUAL ${NUM_CLOCK_PERIODS})
    message( FATAL_ERROR "Number of clock pins (${NUM_CLOCKS}) must match number of periods (${NUM_CLOCK_PERIODS})")
  endif()

  get_target_property_required(PYTHON3 env PYTHON3)
  get_target_property(PYTHON3_TARGET env PYTHON3_TARGET)

  set(CREATE_RUNME ${symbiflow-arch-defs_SOURCE_DIR}/xc7/utils/vivado_create_runme.py)
  add_custom_command(
      OUTPUT ${NAME}_runme.tcl
      COMMAND ${PYTHON3} ${CREATE_RUNME}
        --name ${NAME}
        --verilog ${BIT_VERILOG_LOCATION}
        --routing_tcl ${BIT_TCL_LOCATION}
        --top ${TOP}
        --part ${PART}
        --clock_pins "${ADD_VIVADO_TARGET_CLOCK_PINS}"
        --clock_periods "${ADD_VIVADO_TARGET_CLOCK_PERIODS}"
        --output_tcl ${CMAKE_CURRENT_BINARY_DIR}/${NAME}_runme.tcl
      DEPENDS
        ${PYTHON3_TARGET} ${PYTHON3}
        ${CREATE_RUNME}
        )

  set(CREATE_SIM ${symbiflow-arch-defs_SOURCE_DIR}/xc7/utils/vivado_create_sim.py)
  add_custom_command(
      OUTPUT ${NAME}_sim.tcl
      COMMAND ${PYTHON3} ${CREATE_SIM}
        --top ${TOP}
        --clock_pins "${ADD_VIVADO_TARGET_CLOCK_PINS}"
        --clock_periods "${ADD_VIVADO_TARGET_CLOCK_PERIODS}"
        --output_tcl ${CMAKE_CURRENT_BINARY_DIR}/${NAME}_sim.tcl
      DEPENDS
        ${PYTHON3_TARGET} ${PYTHON3}
        ${CREATE_SIM}
        )

  set(CREATE_OUTPUT_TIMING
    ${symbiflow-arch-defs_SOURCE_DIR}/xc7/utils/vivado_output_timing.py)
  add_custom_command(
      OUTPUT ${NAME}_output_timing.tcl
      COMMAND ${PYTHON3} ${CREATE_OUTPUT_TIMING}
        --name ${NAME}
        --output_tcl ${CMAKE_CURRENT_BINARY_DIR}/${NAME}_output_timing.tcl
        --util_tcl ${symbiflow-arch-defs_SOURCE_DIR}/xc7/utils/timing_utils.tcl
      DEPENDS
        ${PYTHON3_TARGET} ${PYTHON3}
        ${CREATE_OUTPUT_TIMING}
        )

  # Run Vivado in the same directory as VPR was run, this ensures a unique
  # directory, and presents Vivado filename collisions.
  get_filename_component(WORK_DIR ${BIT_VERILOG} DIRECTORY)

  add_custom_command(
    OUTPUT
        ${WORK_DIR}/design_${NAME}.dcp
        ${WORK_DIR}/design_${NAME}.xpr
        ${WORK_DIR}/design_${NAME}.bit
    COMMAND ${CMAKE_COMMAND} -E remove -f ${WORK_DIR}/design_${NAME}.dcp
    COMMAND ${CMAKE_COMMAND} -E remove -f ${WORK_DIR}/design_${NAME}.xpr
    COMMAND ${PRJXRAY_DIR}/utils/vivado.sh -mode batch -source
        ${CMAKE_CURRENT_BINARY_DIR}/${NAME}_runme.tcl
        > ${CMAKE_CURRENT_BINARY_DIR}/${WORK_DIR}/vivado.stdout.log
    WORKING_DIRECTORY ${WORK_DIR}
    DEPENDS ${DEPS} ${BIT_TCL_LOCATION} ${NAME}_runme.tcl
    )

  add_custom_target(
      ${NAME}_load_dcp
      COMMAND ${PRJXRAY_DIR}/utils/vivado.sh design_${NAME}.dcp
      WORKING_DIRECTORY ${WORK_DIR}
      DEPENDS ${WORK_DIR}/design_${NAME}.dcp
      )

  add_custom_target(
      ${NAME}_load_xpr
      COMMAND ${PRJXRAY_DIR}/utils/vivado.sh design_${NAME}.xpr
      WORKING_DIRECTORY ${WORK_DIR}
      DEPENDS ${WORK_DIR}/design_${NAME}.xpr
      )

  add_custom_target(
      ${NAME}_sim
      COMMAND ${PRJXRAY_DIR}/utils/vivado.sh
        design_${NAME}.xpr -source ${CMAKE_CURRENT_BINARY_DIR}/${NAME}_sim.tcl
      WORKING_DIRECTORY ${WORK_DIR}
      DEPENDS ${WORK_DIR}/design_${NAME}.xpr ${NAME}_sim.tcl
      )

  add_custom_command(
      OUTPUT ${WORK_DIR}/timing_${NAME}.json5
      COMMAND ${PRJXRAY_DIR}/utils/vivado.sh
        design_${NAME}.dcp
        -mode batch
        -source ${CMAKE_CURRENT_BINARY_DIR}/${NAME}_output_timing.tcl
        > ${CMAKE_CURRENT_BINARY_DIR}/${WORK_DIR}/vivado_timing.stdout.log
      WORKING_DIRECTORY ${WORK_DIR}
      DEPENDS ${NAME}_output_timing.tcl ${WORK_DIR}/design_${NAME}.dcp
      )

  add_custom_command(
      OUTPUT ${WORK_DIR}/design_${NAME}.bit.fasm
      COMMAND
      ${CMAKE_COMMAND} -E env PYTHONPATH=${PRJXRAY_DIR}:${PRJXRAY_DIR}/third_party/fasm
        ${PRJXRAY_DIR}/utils/bit2fasm.py
          --part ${PART}
          --db-root ${PRJXRAY_DB_DIR}/${ARCH}
          --bitread $<TARGET_FILE:bitread>
          ${CMAKE_CURRENT_BINARY_DIR}/${WORK_DIR}/design_${NAME}.bit
          > ${CMAKE_CURRENT_BINARY_DIR}/${WORK_DIR}/design_${NAME}.bit.fasm
      WORKING_DIRECTORY ${WORK_DIR}
      DEPENDS
        ${PYTHON3} ${PYTHON3_TARGET}
        ${WORK_DIR}/design_${NAME}.bit
      )

  get_file_location(BITSTREAM_LOCATION ${BITSTREAM})

  add_custom_target(${NAME} DEPENDS ${WORK_DIR}/design_${NAME}.dcp)
  add_custom_target(${NAME}_timing DEPENDS ${WORK_DIR}/timing_${NAME}.json5)
  add_custom_target(${NAME}_fasm DEPENDS ${WORK_DIR}/design_${NAME}.bit.fasm)
  add_custom_target(${NAME}_diff_fasm
      COMMAND diff -u
        ${BITSTREAM_LOCATION}.fasm
        ${CMAKE_CURRENT_BINARY_DIR}/${WORK_DIR}/design_${NAME}.bit.fasm
      DEPENDS
        ${DEPS}
        ${BITSTREAM_LOCATION}.fasm
        ${CMAKE_CURRENT_BINARY_DIR}/${WORK_DIR}/design_${NAME}.bit.fasm
      )
endfunction()
