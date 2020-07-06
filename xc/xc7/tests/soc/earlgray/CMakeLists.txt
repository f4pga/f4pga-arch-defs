add_file_target(FILE pins_nexys_video.sdc)
add_file_target(FILE boot_rom_fpga_nexysvideo.vmem)

get_target_property_required(PYTHON3 env PYTHON3)
get_target_property(PYTHON3_TARGET env PYTHON3_TARGET)

add_fpga_target(
  NAME earlgray_nexys_video
  BOARD nexys_video-mid
  SOURCES
    aes_cipher_control.v
    aes_cipher_core.v
    aes_control.v
    aes_core.v
    aes_key_expand.v
    aes_mix_columns.v
    aes_mix_single_column.v
    aes_reg_top.v
    aes_sbox_canright.v
    aes_sbox_lut.v
    aes_sbox.v
    aes_shift_rows.v
    aes_sub_bytes.v
    aes.v
    alert_handler_accu.v
    alert_handler_class.v
    alert_handler_esc_timer.v
    alert_handler_ping_timer.v
    alert_handler_reg_top.v
    alert_handler_reg_wrap.v
    alert_handler.v
    clkgen_xil7series.v
    debug_rom.v
    dm_csrs.v
    dmi_cdc.v
    dmi_jtag_tap.v
    dmi_jtag.v
    dm_mem.v
    dm_sba.v
    flash_ctrl_reg_top.v
    flash_ctrl.v
    flash_erase_ctrl.v
    flash_mp.v
    flash_phy.v
    flash_prog_ctrl.v
    flash_rd_ctrl.v
    gpio_reg_top.v
    gpio.v
    hmac_core.v
    hmac_reg_top.v
    hmac.v
    ibex_alu.v
    ibex_compressed_decoder.v
    ibex_controller.v
    ibex_core.v
    ibex_cs_registers.v
    ibex_decoder.v
    ibex_ex_block.v
    ibex_fetch_fifo.v
    ibex_id_stage.v
    ibex_if_stage.v
    ibex_load_store_unit.v
    ibex_multdiv_fast.v
    ibex_multdiv_slow.v
    ibex_pmp.v
    ibex_prefetch_buffer.v
    ibex_register_file_ff.v
    nmi_gen_reg_top.v
    nmi_gen.v
    padctl.v
    pinmux_reg_top.v
    pinmux.v
    pins_if.v
    prim_alert_receiver.v
    prim_alert_sender.v
    prim_arbiter_ppc.v
    prim_arbiter_tree.v
    prim_assert.v
    prim_clock_gating.v
    prim_clock_inverter.v
    prim_clock_mux2.v
    prim_diff_decode.v
    prim_esc_receiver.v
    prim_esc_sender.v
    prim_fifo_async.v
    prim_fifo_sync.v
    prim_filter_ctr.v
    prim_filter.v
    prim_flash.v
    prim_flop_2sync.v
    prim_generic_clock_gating.v
    prim_generic_clock_mux2.v
    prim_generic_flash.v
    prim_generic_pad_wrapper.v
    prim_generic_ram_1p.v
    prim_generic_ram_2p.v
    prim_generic_rom.v
    prim_intr_hw.v
    prim_lfsr.v
    prim_packer.v
    prim_pad_wrapper.v
    prim_present.v
    prim_prince.v
    prim_pulse_sync.v
    prim_ram_1p.v
    prim_ram_2p_adv.v
    prim_ram_2p_async_adv.v
    prim_ram_2p.v
    prim_rom.v
    prim_secded_39_32_dec.v
    prim_secded_39_32_enc.v
    prim_sram_arbiter.v
    prim_subreg_ext.v
    prim_subreg.v
    prim_xilinx_clock_gating.v
    prim_xilinx_clock_mux2.v
    prim_xilinx_pad_wrapper.v
    prim_xilinx_ram_1p.v
    prim_xilinx_ram_2p.v
    prim_xilinx_rom.v
    rv_core_ibex.v
    rv_dm.v
    rv_plic_gateway.v
    rv_plic_reg_top.v
    rv_plic_target.v
    rv_plic.v
    rv_timer_reg_top.v
    rv_timer.v
    sha2_pad.v
    sha2.v
    spi_device_reg_top.v
    spi_device.v
    spi_fwmode.v
    spi_fwm_rxf_ctrl.v
    spi_fwm_txf_ctrl.v
    sram2tlul.v
    timer_core.v
    tlul_adapter_host.v
    tlul_adapter_reg.v
    tlul_adapter_sram.v
    tlul_assert_multiple.v
    tlul_assert.v
    tlul_err_resp.v
    tlul_err.v
    tlul_fifo_async.v
    tlul_fifo_sync.v
    tlul_socket_1n.v
    tlul_socket_m1.v
    top_earlgrey_nexysvideo.v
    top_earlgrey.v
    uart_core.v
    uart_reg_top.v
    uart_rx.v
    uart_tx.v
    uart.v
    usbdev_flop_2syncpulse.v
    usbdev_iomux.v
    usbdev_linkstate.v
    usbdev_reg_top.v
    usbdev_usbif.v
    usbdev.v
    usb_fs_nb_in_pe.v
    usb_fs_nb_out_pe.v
    usb_fs_nb_pe.v
    usb_fs_rx.v
    usb_fs_tx_mux.v
    usb_fs_tx.v
    xbar_main.v
    xbar_peri.v
  INPUT_IO_FILE pins_nexys_video.pcf
  INPUT_XDC_FILE pins_nexysvideo.xdc
  SDC_FILE pins_nexys_video.sdc
)

# The following lines are needed if the memory file is read from local
# parameter in verilog source files.
# Alternatively we can explicitly set memory file in $readmemh() argument

add_dependencies(
  file_xc_xc7_tests_soc_earlgray_prim_generic_rom.v
  file_xc_xc7_tests_soc_earlgray_boot_rom_fpga_nexysvideo.vmem
)

add_dependencies(
  file_xc_xc7_tests_soc_earlgray_prim_xilinx_rom.v
  file_xc_xc7_tests_soc_earlgray_boot_rom_fpga_nexysvideo.vmem
)

add_vivado_target(
  NAME earlgray_nexys_video_vivado
  PARENT_NAME earlgray_nexys_video
)
