function(COMMON_VIVADO_TARGETS)
  # ~~~
  # COMMON_VIVADO_TARGETS(
  #   NAME <name>
  #   WORK_DIR <working directory>
  #   BITSTREAM <bitstream>
  #   DEPS <dependency list>
  #   [MAKE_DIFF_FASM]
  #   )
  # ~~~
  #
  # Generates common Vivado targets for running Vivado tcl scripts to generate
  # the Vivado checkpoint and project, and creates the following dummy targets:
  #
  # - ${NAME}_load_dcp - Load generated checkpoint.  This contains routing and
  #                      placement details.
  # - ${NAME}_load_xpr - Load generated project.  This can be used for
  #                      behavioral simulation.
  # - ${NAME}_sim - Load project and launches simulation.
  #
  # The MAKE_DIFF_FASM option generates a diff between the input BITSTREAM
  # and the output from Vivado, and attaches that diff generation to
  # "all_xc7_diff_fasm" which can used to verify FASM.
  #
  set(options MAKE_DIFF_FASM)
  set(oneValueArgs NAME WORK_DIR BITSTREAM)
  set(multiValueArgs DEPS)
  cmake_parse_arguments(
      COMMON_VIVADO_TARGETS
    "${options}"
    "${oneValueArgs}"
    "${multiValueArgs}"
    ${ARGN}
  )

  get_target_property_required(PYTHON3 env PYTHON3)
  get_target_property(PYTHON3_TARGET env PYTHON3_TARGET)

  set(NAME ${COMMON_VIVADO_TARGETS_NAME})
  set(WORK_DIR ${COMMON_VIVADO_TARGETS_WORK_DIR})
  set(DEPS ${COMMON_VIVADO_TARGETS_DEPS})
  set(BITSTREAM ${COMMON_VIVADO_TARGETS_BITSTREAM})

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
    DEPENDS ${DEPS} ${NAME}_runme.tcl
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

  set(CLEAN_JSON5 ${symbiflow-arch-defs_SOURCE_DIR}/utils/clean_json5.py)
  get_target_property(PYJSON5_TARGET env PYJSON5_TARGET)
  add_custom_command(
      OUTPUT ${WORK_DIR}/timing_${NAME}.json
      COMMAND ${PRJXRAY_DIR}/utils/vivado.sh
        design_${NAME}.dcp
        -mode batch
        -source
            ${symbiflow-arch-defs_SOURCE_DIR}/xc7/utils/output_timing.tcl
        -tclargs
            ${symbiflow-arch-defs_SOURCE_DIR}/xc7/utils/timing_utils.tcl
            ${CMAKE_CURRENT_BINARY_DIR}/${WORK_DIR}/timing_${NAME}.json5
        > ${CMAKE_CURRENT_BINARY_DIR}/${WORK_DIR}/vivado_timing.stdout.log
      COMMAND ${PYTHON3} ${CLEAN_JSON5}
        < ${CMAKE_CURRENT_BINARY_DIR}/${WORK_DIR}/timing_${NAME}.json5
        > ${CMAKE_CURRENT_BINARY_DIR}/${WORK_DIR}/timing_${NAME}.json
      WORKING_DIRECTORY ${WORK_DIR}
      DEPENDS
        ${WORK_DIR}/design_${NAME}.dcp
        ${PYTHON3} ${PYTHON3_TARGET} ${PYJSON5_TARGET}
      )

  add_custom_command(
      OUTPUT ${WORK_DIR}/design_${NAME}.bit.fasm
      COMMAND
      ${CMAKE_COMMAND} -E env PYTHONPATH=${PRJXRAY_DIR}:${PRJXRAY_DIR}/third_party/fasm
        ${PYTHON3} ${PRJXRAY_DIR}/utils/bit2fasm.py
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
  append_file_dependency(DEPS ${BITSTREAM})

  add_custom_target(${NAME} DEPENDS ${WORK_DIR}/design_${NAME}.dcp)
  add_custom_target(${NAME}_timing DEPENDS ${WORK_DIR}/timing_${NAME}.json)
  add_custom_target(${NAME}_fasm DEPENDS ${WORK_DIR}/design_${NAME}.bit.fasm)

  if(${COMMON_VIVADO_TARGETS_MAKE_DIFF_FASM})
    add_custom_target(${NAME}_diff_fasm
        COMMAND diff -u
            ${BITSTREAM_LOCATION}.fasm
            ${CMAKE_CURRENT_BINARY_DIR}/${WORK_DIR}/design_${NAME}.bit.fasm
        DEPENDS
            ${DEPS}
            ${CMAKE_CURRENT_BINARY_DIR}/${WORK_DIR}/design_${NAME}.bit.fasm
        )
    add_dependencies(all_xc7_diff_fasm ${NAME}_diff_fasm)
  endif()
endfunction()

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
  # the output of a 7-series FPGA target.
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

  # Run Vivado in the same directory as VPR was run, this ensures a unique
  # directory, and presents Vivado filename collisions.
  get_filename_component(WORK_DIR ${BIT_VERILOG} DIRECTORY)

  COMMON_VIVADO_TARGETS(
      NAME ${NAME}
      WORK_DIR ${WORK_DIR}
      DEPS ${DEPS}
      BITSTREAM ${BITSTREAM}
      MAKE_DIFF_FASM)

endfunction()

function(ADD_VIVADO_PNR_TARGET)
  # ~~~
  # ADD_VIVADO_PNR_TARGET(
  #   NAME <name>
  #   PARENT_NAME <name>
  #   CLOCK_PINS list of clock pins
  #   CLOCK_PERIODS list of clock periods
  #   [IOSTANDARD <iostandard>]
  #   [XDC <xdc file>]
  #   )
  # ~~~
  #
  # ADD_VIVADO_PNR_TARGET generates a Vivado project and design checkpoint from
  # the output of 7-series synthesis.
  #
    # Inputs to Vivado are the output verilog from the synthesis tool.
  #
  # PARENT_NAME is the name of the FPGA target being used as input for these
  # targets.
  #
  # CLOCK_PINS and CLOCK_PERIODS should be lists of the same length.
  # CLOCK_PERIODS should be in nanoseconds.
  #
  # Vivado requires pin constraints for all top-level IO.  ADD_VIVADO_PNR_TARGET
  # can generate constrains for a fixed IOSTANDARD if the IOSTANDARD argument
  # is supplied.  The XDC argument can be used if an existing constraint file
  # already exists.  For consistency, the port location constraints in the XDC
  # file should match the PCF file used for VPR.
  #
  # New targets:
  #  <NAME>_load_dcp - Launch vivado loading post-routing design checkpoint.
  #  <NAME>_load_xpr - Launch vivado loading project.
  #  <NAME>_sim - Launch vivado and setup simulation and clock forces.
  set(options)
  set(oneValueArgs NAME PARENT_NAME IOSTANDARD XDC)
  set(multiValueArgs CLOCK_PINS CLOCK_PERIODS)
  cmake_parse_arguments(
      ADD_VIVADO_PNR_TARGET
    "${options}"
    "${oneValueArgs}"
    "${multiValueArgs}"
    ${ARGN}
  )

  set(NAME ${ADD_VIVADO_PNR_TARGET_NAME})

  get_target_property_required(BITSTREAM ${ADD_VIVADO_PNR_TARGET_PARENT_NAME} BIN)
  get_target_property_required(SYNTH_V ${ADD_VIVADO_PNR_TARGET_PARENT_NAME} SYNTH_V)
  get_target_property_required(TOP ${ADD_VIVADO_PNR_TARGET_PARENT_NAME} TOP)
  get_target_property_required(BOARD ${ADD_VIVADO_PNR_TARGET_PARENT_NAME} BOARD)
  get_target_property_required(DEVICE ${BOARD} DEVICE)
  get_target_property_required(ARCH ${DEVICE} ARCH)
  get_target_property_required(PART ${ARCH}_${DEVICE}_${BOARD} PART)

  get_target_property_required(YOSYS env YOSYS)
  get_target_property(YOSYS_TARGET env YOSYS_TARGET)

  get_target_property_required(QUIET_CMD env QUIET_CMD)
  get_target_property(QUIET_CMD_TARGET env QUIET_CMD_TARGET)

  get_target_property_required(PYTHON3 env PYTHON3)
  get_target_property(PYTHON3_TARGET env PYTHON3_TARGET)

  set(DEPS "")
  append_file_dependency(SYNTH_DEPS ${SYNTH_V})
  get_file_location(SYNTH_V_LOC ${SYNTH_V})

  # Unmap VPR specific things from synthesis output.
  get_filename_component(SYNTH_OUT_BASE ${SYNTH_V_LOC} NAME)
  get_file_location(BITSTREAM_LOC ${BITSTREAM})
  get_filename_component(BASE_WORK_DIR ${BITSTREAM_LOC} DIRECTORY)
  set(SYNTH_OUT ${BASE_WORK_DIR}/${SYNTH_OUT_BASE}.vivado.v)
  set(UNMAP_V ${symbiflow-arch-defs_SOURCE_DIR}/xc7/techmap/unmap.v)

  add_custom_command(
      OUTPUT ${SYNTH_OUT}
      COMMAND ${QUIET_CMD} ${YOSYS}
        -b verilog -o ${SYNTH_OUT}
        -p "techmap -map ${UNMAP_V}"
        ${SYNTH_V_LOC}.premap.v
      DEPENDS ${YOSYS_TARGET} ${YOSYS}
        ${QUIET_CMD} ${QUIET_CMD_TARGET}
        ${SYNTH_DEPS} ${SYNTH_V_LOC}.premap.v ${UNMAP_V}
        )

  string(REPLACE "${CMAKE_CURRENT_BINARY_DIR}/" ""  SYNTH_OUT_REL ${SYNTH_OUT})
  add_file_target(FILE ${SYNTH_OUT_REL} GENERATED)
  append_file_dependency(DEPS ${SYNTH_OUT_REL})

  # Set or generate the XDC file
  set(XDC_FILE "")
  if(NOT ${ADD_VIVADO_PNR_TARGET_XDC} STREQUAL "UNDEFINED")
      get_file_location(XDC_FILE ${ADD_VIVADO_PNR_TARGET_XDC})
      append_file_dependency(DEPS ${ADD_VIVADO_PNR_TARGET_XDC})
  endif()
  if(NOT ${ADD_VIVADO_PNR_TARGET_IOSTANDARD} STREQUAL "UNDEFINED")
      if(NOT ${XDC_FILE} STREQUAL "")
          message(FATAL_ERROR "Cannot specify both XDC and IOSTANDARD")
      endif()

      get_target_property_required(
          INPUT_IO_FILE
          ${ADD_VIVADO_PNR_TARGET_PARENT_NAME} INPUT_IO_FILE)

      set(XDC_FILE ${CMAKE_CURRENT_BINARY_DIR}/${NAME}.xdc)
      set(XDC_DEPS)
      append_file_dependency(XDC_DEPS ${INPUT_IO_FILE})
      get_file_location(PCF_FILE ${INPUT_IO_FILE})
      set(PCF_TO_XDC_TOOL ${symbiflow-arch-defs_SOURCE_DIR}/xc7/utils/prjxray_pcf_to_xdc.py)

      add_custom_command(
          OUTPUT ${NAME}.xdc
          COMMAND
          ${CMAKE_COMMAND} -E env PYTHONPATH=${symbiflow-arch-defs_SOURCE_DIR}/utils
          ${PYTHON3} ${PCF_TO_XDC_TOOL}
            --pcf ${PCF_FILE}
            --xdc ${XDC_FILE}
            --iostandard ${ADD_VIVADO_PNR_TARGET_IOSTANDARD}
          DEPENDS ${PYTHON3} ${PYTHON3_TARGET} ${PCF_TO_XDC_TOOL} ${XDC_DEPS}
          )

      add_file_target(FILE ${NAME}.xdc GENERATED)

      append_file_dependency(DEPS ${NAME}.xdc)
  endif()

  if(${XDC_FILE} STREQUAL "")
      message(FATAL_ERROR "Must specify either XDC or IOSTANDARD")
  endif()

  set(CREATE_RUNME ${symbiflow-arch-defs_SOURCE_DIR}/xc7/utils/vivado_create_runme.py)
  add_custom_command(
      OUTPUT ${NAME}_runme.tcl
      COMMAND ${PYTHON3} ${CREATE_RUNME}
        --name ${NAME}
        --verilog ${SYNTH_OUT}
        --routing_tcl ${XDC_FILE}
        --top ${TOP}
        --part ${PART}
        --clock_pins "${ADD_VIVADO_PNR_TARGET_CLOCK_PINS}"
        --clock_periods "${ADD_VIVADO_PNR_TARGET_CLOCK_PERIODS}"
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
        --clock_pins "${ADD_VIVADO_PNR_TARGET_CLOCK_PINS}"
        --clock_periods "${ADD_VIVADO_PNR_TARGET_CLOCK_PERIODS}"
        --output_tcl ${CMAKE_CURRENT_BINARY_DIR}/${NAME}_sim.tcl
      DEPENDS
        ${PYTHON3_TARGET} ${PYTHON3}
        ${CREATE_SIM}
        )

  # Run vivado in another directory.
  set(WORK_DIR ${BASE_WORK_DIR}/vivado_pnr)
  string(REPLACE "${CMAKE_CURRENT_BINARY_DIR}/" ""  WORK_DIR ${WORK_DIR})
  add_custom_command(
      OUTPUT ${WORK_DIR}
      COMMAND ${CMAKE_COMMAND} -E make_directory ${WORK_DIR}
      )
  list(APPEND DEPS ${WORK_DIR})

  COMMON_VIVADO_TARGETS(
      NAME ${NAME}
      WORK_DIR ${WORK_DIR}
      DEPS ${DEPS}
      BITSTREAM ${BITSTREAM})
endfunction()
