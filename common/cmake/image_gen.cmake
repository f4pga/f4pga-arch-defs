find_program(EOG eog)
find_program(INKSCAPE inkscape)
set(IMAGE_GEN_DPI 300 CACHE STRING "DPI to use when generating images from Verilog SVGs")

set(NETLISTSVG ${symbiflow-arch-defs_SOURCE_DIR}/third_party/netlistsvg
  CACHE STRING "Directory to netlistsvg.")
set(NETLISTSVG_BIN ${NETLISTSVG}/bin/netlistsvg.js)
set(NETLISTSVG_SKIN ${NETLISTSVG}/lib/default.svg)
set(NETLISTSVG_LOCK ${NETLISTSVG}/package-lock.json)

function(setup_netlistsvg)
  # Creates target netlistsvg that installs netlistsvg to the local node
  # environment.
  get_target_property_required(NODE env NODE)
  get_target_property_required(NPM env NPM)
  add_custom_command(
    OUTPUT ${NETLISTSVG_LOCK}
    COMMAND ${NODE} ${NPM} install
    WORKING_DIRECTORY ${NETLISTSVG}
    DEPENDS
      ${NODE}
      ${NPM}
      ${NETLISTSVG}/package.json
    )

  add_custom_target(
    netlistsvg DEPENDS ${NETLISTSVG_LOCK}
    )
endfunction()

setup_netlistsvg()

function(add_svg_image)
  # ~~~
  # ADD_SVG_IMAGE(
  #   NAME <name>
  #   FILE <svg filename>
  #   )
  # ~~~
  #
  # ADD_SVG_IMAGE adds two targets, render_<name> and view_<name>.
  #
  # render_<name> will convert <svg filename> to a png with the name
  # <svg filename>.png. SVG will be rendered at IMAGE_GEN_DPI, a CMake cache
  # veriable, defaulting to 300.
  #
  # view_<name> will generated the render PNG and view it using eog.
  set(options)
  set(oneValueArgs NAME FILE)
  set(multiValueArgs)
  cmake_parse_arguments(
    ADD_SVG_IMAGE
    "${options}"
    "${oneValueArgs}"
    "${multiValueArgs}"
    ${ARGN}
  )

  set(SRC_SVG ${ADD_SVG_IMAGE_FILE})
  get_filename_component(SRC_BASE ${SRC_SVG} NAME)
  set(SRC_PNG ${SRC_BASE}.png)
  set(DEPS "")
  append_file_dependency(DEPS ${SRC_SVG})

  add_custom_command(
    OUTPUT ${SRC_PNG}
    COMMAND ${INKSCAPE} --export-png ${SRC_PNG} --export-dpi ${IMAGE_GEN_DPI} ${SRC_SVG}
    DEPENDS ${DEPS} ${INKSCAPE}
    )

  add_custom_target(
    render_${ADD_SVG_IMAGE_NAME}
    DEPENDS ${SRC_PNG} ${EOG}
    )

  add_custom_target(
    view_${ADD_SVG_IMAGE_NAME}
    COMMAND ${EOG} ${SRC_PNG}
    DEPENDS ${SRC_PNG} ${EOG}
    )
endfunction()

function(add_verilog_image_gen)
  # ~~~
  # ADD_VERILOG_IMAGE_GEN(
  #   FILE <verilog filename>
  #   )
  # ~~~
  #
  # ADD_VERILOG_IMAGE_GEN converts a verilog file into several image outputs.
  #
  # ADD_VERILOG_IMAGE_GEN always generates output file names by first stripping
  # all extensions from the input filename.  So ff.sim.v has a basename of ff.
  #
  # ADD_VERILOG_IMAGE_GEN first generates an SVG, and then uses ADD_SVG_IMAGE
  # to render the SVG and view it.
  #
  # Output SVGs:
  #
  #  * <basename>.bb.yosys.svg - Netlist rendered by yosys, not flattened.
  #  * <basename>.flat.yosys.svg - Netlist rendered by yosys, flattened.
  #  * <basename>.bb.svg - Netlist rendered by netlistsvg, not flattened.
  #  * <basename>.flat.svg - Netlist rendered by yosys, flattened.
  #  * <basename>.aig.svg - Netlist rendered by yosys, flattened and run
  #    through yosys's aigmap.
  #
  # ADD_VERILOG_IMAGE_GEN generates viewing targets with the following
  # convention:
  #
  # view_<relative directory from root, slashes replaced with underscores>_<basename>.<bb|flat|aig>[.yosys]
  #
  # Example:
  #
  # view_testarch_primitives_ff_ff.aig
  # view_testarch_primitives_ff_ff.bb.yosys
  #
  set(options)
  set(oneValueArgs FILE)
  set(multiValueArgs)
  cmake_parse_arguments(
    ADD_VERILOG_IMAGE_GEN
    "${options}"
    "${oneValueArgs}"
    "${multiValueArgs}"
    ${ARGN}
  )

  set(SRC ${ADD_VERILOG_IMAGE_GEN_FILE})
  set(DEPS "")
  append_file_dependency(DEPS ${SRC})
  get_file_location(SRC_LOCATION ${SRC})

  get_filename_component(SRC_BASE ${SRC} NAME_WE)
  string(TOUPPER ${SRC_BASE} SIM_TOP)
  get_filename_component(SRC_DIR ${SRC} DIRECTORY)


  set(SRC_BB_JSON ${SRC_BASE}.bb.json)
  set(SRC_AIG_JSON ${SRC_BASE}.aig.json)
  set(SRC_FLAT_JSON ${SRC_BASE}.flat.json)
  set(SRC_BB_YOSYS_SVG ${SRC_BASE}.bb.yosys.svg)
  set(SRC_FLAT_YOSYS_SVG ${SRC_BASE}.flat.yosys.svg)
  set(SVGS ${SRC_BB_YOSYS_SVG} ${SRC_FLAT_YOSYS_SVG})

  get_target_property_required(YOSYS env YOSYS)
  get_target_property_required(NODE env NODE)
  add_custom_command(
    OUTPUT ${SRC_BB_JSON}
    COMMAND ${YOSYS} -p "prep -top ${SIM_TOP} $<SEMICOLON> write_json ${SRC_BB_JSON}" ${SRC_LOCATION}
    DEPENDS ${DEPS} ${YOSYS}
    WORKING_DIRECTORY ${SRC_DIR}
    VERBATIM
    )

  add_custom_command(
    OUTPUT ${SRC_BB_YOSYS_SVG}
    COMMAND ${YOSYS} -p "prep -top ${SIM_TOP} $<SEMICOLON> show -format svg -prefix ${SRC_BASE}.bb.yosys ${SIM_TOP}" ${SRC}
    DEPENDS ${DEPS} ${YOSYS}
    WORKING_DIRECTORY ${SRC_DIR}
    VERBATIM
    )

  add_custom_command(
    OUTPUT ${SRC_AIG_JSON}
    COMMAND ${YOSYS} -p "prep -top ${SIM_TOP} -flatten $<SEMICOLON> aigmap $<SEMICOLON> write_json ${SRC_AIG_JSON}" ${SRC}
    DEPENDS ${DEPS} ${YOSYS}
    WORKING_DIRECTORY ${SRC_DIR}
    VERBATIM
    )

  add_custom_command(
    OUTPUT ${SRC_FLAT_JSON}
    COMMAND ${YOSYS} -p "prep -top ${SIM_TOP} -flatten $<SEMICOLON> write_json ${SRC_FLAT_JSON}" ${SRC}
    DEPENDS ${DEPS} ${YOSYS}
    WORKING_DIRECTORY ${SRC_DIR}
    VERBATIM
    )

  add_custom_command(
    OUTPUT ${SRC_FLAT_YOSYS_SVG}
    COMMAND ${YOSYS} -p "prep -top ${SIM_TOP} -flatten $<SEMICOLON> show -format svg -prefix ${SRC_BASE}.flat.yosys ${SIM_TOP}" ${SRC}
    DEPENDS ${DEPS} ${YOSYS}
    WORKING_DIRECTORY ${SRC_DIR}
    VERBATIM
    )

  foreach(SRC_JSON ${SRC_BB_JSON} ${SRC_AIG_JSON} ${SRC_FLAT_JSON})
    string(REGEX REPLACE "json$" "svg"
      SRC_SVG ${SRC_JSON})
    list(APPEND SVGS ${SRC_SVG})

    add_custom_command(
      OUTPUT ${SRC_SVG}
      COMMAND ${NODE} ${NETLISTSVG_BIN} ${SRC_JSON} -o ${SRC_SVG} --skin ${NETLISTSVG_SKIN}
      DEPENDS ${NODE} ${NETLISTSVG_BIN} ${NETLISTSVG_SKIN} netlistsvg ${SRC_JSON}
      )
  endforeach()

  foreach(SRC_SVG ${SVGS})
    add_file_target(FILE ${SRC_SVG} GENERATED)
    string(REGEX REPLACE "\.svg$" ""
      BASENAME ${SRC_SVG})
    set(DIR ${CMAKE_CURRENT_SOURCE_DIR})
    string(REPLACE ${symbiflow-arch-defs_SOURCE_DIR}/ "" BASE_FOLDER ${DIR})
    string(REPLACE "/" "_" BASE_FOLDER_UNDERSCORE ${BASE_FOLDER})
    add_svg_image(
      NAME ${BASE_FOLDER_UNDERSCORE}_${BASENAME}
      FILE ${SRC_SVG}
      )
  endforeach()
endfunction()
