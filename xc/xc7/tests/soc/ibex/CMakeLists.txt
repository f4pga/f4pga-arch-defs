add_file_target(FILE led.vmem)
add_file_target(FILE pins_artya7.sdc)

get_target_property_required(PYTHON3 env PYTHON3)

add_fpga_target(
  NAME ibex_arty
  BOARD arty-full
  SOURCES
    ibex_alu.v
    ibex_core.v
    ibex_decoder.v
    ibex_load_store_unit.v
    ibex_fetch_fifo.v
    ibex_id_stage.v
    ibex_if_stage.v
    ibex_pmp.v
    ibex_multdiv_fast.v
    ibex_controller.v
    ibex_compressed_decoder.v
    ibex_core_tracing.v
    ibex_multdiv_slow.v
    ibex_prefetch_buffer.v
    ibex_ex_block.v
    top_artya7.v
    ibex_register_file_ff.v
    clkgen_xil7series.v
    ram_1p.v
    ibex_cs_registers.v
  INPUT_IO_FILE pins_artya7.pcf
  SDC_FILE pins_artya7.sdc
)

add_vivado_target(
    NAME ibex_arty_vivado
    PARENT_NAME ibex_arty
)
