get_filename_component(OPENTITAN_DIR ${CMAKE_CURRENT_SOURCE_DIR}/../../../../../third_party/opentitan ABSOLUTE)

set(SV2V_ROM_INIT_FILE boot_rom_fpga_nexysvideo.vmem)
set(SV2V_EARLGREY_FLAGS --define=SYNTHESIS --define=ROM_INIT_FILE=${SV2V_ROM_INIT_FILE} --define=PRIM_DEFAULT_IMPL=prim_pkg::ImplXilinx)

set(SV2V_FILE_LIST
  prim_assert.sv
  prim_ram_2p.sv
  top_pkg.sv
  prim_generic_clock_mux2.sv
  flash_rd_ctrl.sv
  flash_ctrl.sv
  flash_mp.sv
  flash_ctrl_reg_top.sv
  flash_phy.sv
  flash_prog_ctrl.sv
  flash_ctrl_reg_pkg.sv
  flash_erase_ctrl.sv
  prim_xilinx_pad_wrapper.sv
  uart_tx.sv
  uart_core.sv
  uart_reg_pkg.sv
  uart.sv
  uart_reg_top.sv
  uart_rx.sv
  prim_xilinx_rom.sv
  prim_generic_ram_2p.sv
  prim_clock_gating.sv
  tlul_err.sv
  tlul_fifo_async.sv
  tlul_fifo_sync.sv
  tlul_assert_multiple.sv
  tlul_assert.sv
  prim_generic_flash.sv
  usb_fs_nb_out_pe.sv
  usb_fs_tx_mux.sv
  usb_fs_nb_in_pe.sv
  usb_consts_pkg.sv
  usb_fs_tx.sv
  usb_fs_nb_pe.sv
  usb_fs_rx.sv
  rv_core_ibex.sv
  prim_diff_decode.sv
  nmi_gen_reg_pkg.sv
  nmi_gen_reg_top.sv
  nmi_gen.sv
  flash_ctrl_pkg.sv
  debug_rom.sv
  dmi_jtag_tap.sv
  dm_csrs.sv
  dm_pkg.sv
  dmi_jtag.sv
  dm_mem.sv
  dmi_cdc.sv
  dm_sba.sv
  prim_generic_pad_wrapper.sv
  tlul_adapter_sram.sv
  prim_xilinx_ram_2p.sv
  spi_device_reg_pkg.sv
  spi_fwm_rxf_ctrl.sv
  spi_fwmode.sv
  spi_device_pkg.sv
  spi_fwm_txf_ctrl.sv
  spi_device.sv
  spi_device_reg_top.sv
  hmac_core.sv
  hmac_pkg.sv
  sha2.sv
  sha2_pad.sv
  hmac_reg_pkg.sv
  hmac_reg_top.sv
  prim_clock_mux2.sv
  prim_xilinx_clock_gating.sv
  prim_generic_clock_gating.sv
  sram2tlul.sv
  tl_main_pkg.sv
  xbar_main.sv
  pinmux.sv
  prim_generic_rom.sv
  tlul_adapter_reg.sv
  padctl.sv
  top_earlgrey.sv
  timer_core.sv
  rv_timer_reg_top.sv
  rv_timer.sv
  rv_timer_reg_pkg.sv
  prim_generic_ram_1p.sv
  rv_plic_reg_top.sv
  rv_plic_reg_pkg.sv
  rv_plic.sv
  aes_sbox.sv
  aes_cipher_control.sv
  aes_sub_bytes.sv
  aes_sbox_lut.sv
  aes_cipher_core.sv
  aes_shift_rows.sv
  aes_core.sv
  aes_key_expand.sv
  aes_reg_pkg.sv
  aes_reg_top.sv
  aes_control.sv
  aes_mix_single_column.sv
  aes_sbox_canright.sv
  aes_pkg.sv
  aes.sv
  aes_mix_columns.sv
  clkgen_xil7series.sv
  rv_plic_gateway.sv
  rv_plic_target.sv
  pinmux_reg_pkg.sv
  pinmux_reg_top.sv
  prim_xilinx_clock_mux2.sv
  prim_pad_wrapper.sv
  prim_filter.sv
  prim_alert_pkg.sv
  prim_secded_39_32_dec.sv
  prim_ram_2p_adv.sv
  prim_esc_pkg.sv
  prim_subreg_ext.sv
  prim_present.sv
  prim_arbiter_tree.sv
  prim_alert_receiver.sv
  prim_subreg.sv
  prim_lfsr.sv
  prim_alert_sender.sv
  prim_flop_2sync.sv
  prim_pulse_sync.sv
  prim_sram_arbiter.sv
  prim_arbiter_ppc.sv
  prim_packer.sv
  prim_filter_ctr.sv
  prim_clock_inverter.sv
  prim_intr_hw.sv
  prim_ram_2p_async_adv.sv
  prim_esc_receiver.sv
  prim_fifo_async.sv
  prim_prince.sv
  prim_secded_39_32_enc.sv
  prim_fifo_sync.sv
  prim_esc_sender.sv
  alert_handler_reg_pkg.sv
  alert_handler_reg_top.sv
  prim_ram_1p.sv
  gpio_reg_pkg.sv
  gpio_reg_top.sv
  gpio.sv
  tlul_err_resp.sv
  tlul_socket_1n.sv
  prim_pkg.sv
  rv_dm.sv
  tlul_adapter_host.sv
  alert_handler_ping_timer.sv
  alert_handler_accu.sv
  alert_handler_class.sv
  alert_handler_esc_timer.sv
  alert_pkg.sv
  alert_handler.sv
  alert_handler_reg_wrap.sv
  tlul_pkg.sv
  tlul_socket_m1.sv
  prim_flash.sv
  prim_rom.sv
  usbdev_reg_top.sv
  usbdev.sv
  usbdev_iomux.sv
  usbdev_linkstate.sv
  usbdev_flop_2syncpulse.sv
  usbdev_usbif.sv
  usbdev_reg_pkg.sv
  tl_peri_pkg.sv
  xbar_peri.sv
  ibex_alu.sv
  ibex_register_file_ff.sv
  ibex_ex_block.sv
  ibex_load_store_unit.sv
  ibex_pkg.sv
  ibex_multdiv_fast.sv
  ibex_cs_registers.sv
  ibex_id_stage.sv
  ibex_decoder.sv
  ibex_fetch_fifo.sv
  ibex_core.sv
  ibex_multdiv_slow.sv
  ibex_controller.sv
  ibex_pmp.sv
  ibex_if_stage.sv
  ibex_prefetch_buffer.sv
  ibex_compressed_decoder.sv
  pins_if.sv
  hmac.sv
)

set(CUSTOM_FILE_LIST
  prim_xilinx_ram_1p.v
  top_earlgrey_nexysvideo.v
)

add_custom_command(
  OUTPUT ${SV2V_FILE_LIST}
  COMMAND
    bash -c \"cd ${OPENTITAN_DIR} && git apply ${CMAKE_CURRENT_SOURCE_DIR}/earlgrey.patch\"
  COMMAND
    ${PYTHON3} -m pip install -r ${OPENTITAN_DIR}/python-requirements.txt
  COMMAND
    fusesoc --cores-root ${OPENTITAN_DIR} run --target=synth --setup lowrisc:systems:top_earlgrey_nexysvideo
  COMMAND
    for file in ${SV2V_FILE_LIST}\; do find build -name \"$$file\" -exec cp {} . \\\; \; done
  COMMAND
    bash -c \"cd ${OPENTITAN_DIR} && git apply -R ${CMAKE_CURRENT_SOURCE_DIR}/earlgrey.patch\"
  WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
  DEPENDS ${PYTHON3}
)

add_file_target(FILE ${SV2V_ROM_INIT_FILE})

foreach(SRC ${SV2V_FILE_LIST})
  add_file_target(FILE ${SRC} GENERATED)
endforeach()

foreach(SRC ${CUSTOM_FILE_LIST})
  add_file_target(FILE ${SRC})
endforeach()

# sv2v conversion

add_sv2v_target(
  NAME earlgrey
  SOURCES ${SV2V_FILE_LIST}
  FLAGS ${SV2V_EARLGREY_FLAGS}
  EXPLICIT_ADD_FILE_TARGET
)

# Nexys Video Board

add_file_target(FILE pins_nexys_video.sdc)
add_file_target(FILE pins_nexys_video.pcf)

add_fpga_target(
  NAME earlgrey_nexys_video
  BOARD nexys_video-mid
  TOP top_earlgrey_nexysvideo
  INCLUDES ${SV2V_ROM_INIT_FILE}
  SOURCES
    earlgrey_sv2v.v
    top_earlgrey_nexysvideo.v
    prim_xilinx_ram_1p.v
  INPUT_IO_FILE pins_nexys_video.pcf
  SDC_FILE pins_nexys_video.sdc
  EXPLICIT_ADD_FILE_TARGET
)

add_vivado_target(
  NAME earlgrey_nexys_video_vivado
  PARENT_NAME earlgrey_nexys_video
)
