get_filename_component(IBEX_DIR ${CMAKE_CURRENT_SOURCE_DIR}/../../../../../third_party/ibex ABSOLUTE)

set(SV2V_ROM_INIT_FILE led.vmem)
set(SV2V_IBEX_FLAGS --define=RegFile=ibex_pkg::RegFileFF --define=SRAMInitFile=${SV2V_ROM_INIT_FILE})

set(SOURCE_FILE_LIST
  prim_assert.sv
  clkgen_xil7series.sv
  ram_1p.sv
  ibex_pkg.sv
  prim_pkg.sv
  prim_generic_clock_gating.sv
  prim_secded_28_22_dec.sv
  prim_secded_28_22_enc.sv
  prim_secded_39_32_dec.sv
  prim_secded_39_32_enc.sv
  prim_secded_72_64_dec.sv
  prim_secded_72_64_enc.sv
  prim_xilinx_clock_gating.sv
  prim_generic_ram_1p.sv
  prim_lfsr.sv
  prim_clock_gating.sv
  prim_badbit_ram_1p.sv
  prim_ram_1p.sv
  ibex_icache.sv
  ibex_alu.sv
  ibex_compressed_decoder.sv
  ibex_controller.sv
  ibex_cs_registers.sv
  ibex_counter.sv
  ibex_decoder.sv
  ibex_ex_block.sv
  ibex_fetch_fifo.sv
  ibex_id_stage.sv
  ibex_if_stage.sv
  ibex_load_store_unit.sv
  ibex_multdiv_fast.sv
  ibex_multdiv_slow.sv
  ibex_prefetch_buffer.sv
  ibex_pmp.sv
  ibex_wb_stage.sv
  ibex_dummy_instr.sv
  ibex_register_file_ff.sv
  ibex_register_file_fpga.sv
  ibex_register_file_latch.sv
  ibex_core.sv
  top_artya7.sv
)

set(INCLUDE_FILE_LIST
  prim_util_memload.svh
  prim_assert_dummy_macros.svh
  prim_assert_yosys_macros.svh
  prim_assert_standard_macros.svh
)

add_custom_command(
  OUTPUT ${SOURCE_FILE_LIST} ${INCLUDE_FILE_LIST}
  COMMAND
    bash -c \"cd ${IBEX_DIR} && git apply ${CMAKE_CURRENT_SOURCE_DIR}/ibex.patch\"
  COMMAND
    ${PYTHON3} -m pip install -r ${IBEX_DIR}/python-requirements.txt &&
    fusesoc --cores-root=${IBEX_DIR} run --target=synth --setup lowrisc:ibex:top_artya7 --part xc7a35ticsg324-1L
  COMMAND
    for file in ${SOURCE_FILE_LIST}\; do find build -name \"$$file\" -exec cp {} . \\\; \; done
  COMMAND
    for file in ${INCLUDE_FILE_LIST}\; do find build -name \"$$file\" -exec cp {} . \\\; \; done
  COMMAND
    bash -c \"cd ${IBEX_DIR} && git apply -R ${CMAKE_CURRENT_SOURCE_DIR}/ibex.patch\"
  WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
  DEPENDS ${PYTHON3} ${IBEX_DIR}
)

add_file_target(FILE ${SV2V_ROM_INIT_FILE})

foreach(SRC ${SOURCE_FILE_LIST})
  add_file_target(FILE ${SRC} GENERATED)
endforeach()

foreach(INC ${INCLUDE_FILE_LIST})
  add_file_target(FILE ${INC} GENERATED)
endforeach()

# sv2v conversion

add_sv2v_target(
  NAME ibex
  INCLUDES ${INCLUDE_FILE_LIST}
  SOURCES ${SOURCE_FILE_LIST}
  FLAGS ${SV2V_IBEX_FLAGS}
  EXPLICIT_ADD_FILE_TARGET
)

# Arty Board

add_file_target(FILE pins_artya7.sdc)
add_file_target(FILE pins_artya7.pcf)

add_fpga_target(
  NAME ibex_arty
  BOARD arty-full
  TOP top_artya7
  INCLUDES
    ${INCLUDE_FILE_LIST}
    ${SV2V_ROM_INIT_FILE}
  SOURCES ibex_sv2v.v
  INPUT_IO_FILE pins_artya7.pcf
  SDC_FILE pins_artya7.sdc
  EXPLICIT_ADD_FILE_TARGET
)

add_vivado_target(
  NAME ibex_arty_vivado
  PARENT_NAME ibex_arty
)

# Nexys Video Board

add_file_target(FILE pins_nexys_video.sdc)
add_file_target(FILE pins_nexys_video.pcf)

add_fpga_target(
  NAME ibex_nexys_video
  BOARD nexys_video-mid
  TOP top_artya7
  INCLUDES
    ${INCLUDE_FILE_LIST}
    ${SV2V_ROM_INIT_FILE}
  SOURCES ibex_sv2v.v
  INPUT_IO_FILE pins_nexys_video.pcf
  SDC_FILE pins_nexys_video.sdc
  EXPLICIT_ADD_FILE_TARGET
)

add_vivado_target(
  NAME ibex_nexys_video_vivado
  PARENT_NAME ibex_nexys_video
)
