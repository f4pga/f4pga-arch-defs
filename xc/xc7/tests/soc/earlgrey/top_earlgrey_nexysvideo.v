module top_earlgrey_nexysvideo (
	IO_CLK,
	IO_RST_N,
	IO_URX,
	IO_UTX
);
	input IO_CLK;
	input IO_RST_N;
	input IO_URX;
	output IO_UTX;
	wire clk_sys;
	wire clk_48mhz;
	wire rst_sys_n;
	wire [31:0] cio_gpio_p2d;
	wire [31:0] cio_gpio_d2p;
	wire [31:0] cio_gpio_en_d2p;
	wire cio_uart_rx_p2d;
	wire cio_uart_tx_d2p;
	wire cio_uart_tx_en_d2p;
	wire cio_spi_device_sck_p2d;
	wire cio_spi_device_csb_p2d;
	wire cio_spi_device_mosi_p2d;
	wire cio_spi_device_miso_d2p;
	wire cio_spi_device_miso_en_d2p;
	wire cio_jtag_tck_p2d;
	wire cio_jtag_tms_p2d;
	wire cio_jtag_tdi_p2d;
	wire cio_jtag_tdo_d2p;
	wire cio_jtag_trst_n_p2d;
	wire cio_jtag_srst_n_p2d;
	wire cio_usbdev_sense_p2d;
	wire cio_usbdev_pullup_d2p;
	wire cio_usbdev_pullup_en_d2p;
	wire cio_usbdev_dp_p2d;
	wire cio_usbdev_dp_d2p;
	wire cio_usbdev_dp_en_d2p;
	wire cio_usbdev_dn_p2d;
	wire cio_usbdev_dn_d2p;
	wire cio_usbdev_dn_en_d2p;
	wire IO_DPS0 = 0;
	wire IO_DPS3 = 0;
	wire IO_DPS1 = 0;
	wire IO_DPS4 = 0;
	wire IO_DPS5 = 0;
	wire IO_DPS2 = 0;
	wire IO_DPS6 = 0;
	wire IO_DPS7 = 0;
	wire IO_USB_DP0 = 0;
	wire IO_USB_DN0 = 0;
	wire IO_USB_SENSE0 = 0;
	wire IO_USB_PULLUP0;
	wire IO_GP0 = 0;
	wire IO_GP1 = 0;
	wire IO_GP2 = 0;
	wire IO_GP3 = 0;
	wire IO_GP4 = 0;
	wire IO_GP5 = 0;
	wire IO_GP6 = 0;
	wire IO_GP7 = 0;
	wire IO_GP8 = 0;
	wire IO_GP9 = 0;
	wire IO_GP10 = 0;
	wire IO_GP11 = 0;
	wire IO_GP12 = 0;
	wire IO_GP13 = 0;
	wire IO_GP14 = 0;
	wire IO_GP15 = 0;
	top_earlgrey #(.IbexPipeLine(1)) top_earlgrey(
		.clk_i(clk_sys),
		.rst_ni(rst_sys_n),
		.clk_usb_48mhz_i(clk_48mhz),
		.jtag_tck_i(cio_jtag_tck_p2d),
		.jtag_tms_i(cio_jtag_tms_p2d),
		.jtag_trst_ni(cio_jtag_trst_n_p2d),
		.jtag_td_i(cio_jtag_tdi_p2d),
		.jtag_td_o(cio_jtag_tdo_d2p),
		.mio_in_i(cio_gpio_p2d),
		.mio_out_o(cio_gpio_d2p),
		.mio_oe_o(cio_gpio_en_d2p),
		.dio_uart_rx_i(cio_uart_rx_p2d),
		.dio_uart_tx_o(cio_uart_tx_d2p),
		.dio_uart_tx_en_o(cio_uart_tx_en_d2p),
		.dio_spi_device_sck_i(1'b0),
		.dio_spi_device_csb_i(1'b0),
		.dio_spi_device_mosi_i(1'b0),
		.dio_spi_device_miso_o(cio_spi_device_miso_d2p),
		.dio_spi_device_miso_en_o(cio_spi_device_miso_en_d2p),
		.dio_usbdev_sense_i(cio_usbdev_sense_p2d),
		.dio_usbdev_pullup_o(cio_usbdev_pullup_d2p),
		.dio_usbdev_pullup_en_o(cio_usbdev_pullup_en_d2p),
		.dio_usbdev_dp_i(cio_usbdev_dp_p2d),
		.dio_usbdev_dp_o(cio_usbdev_dp_d2p),
		.dio_usbdev_dp_en_o(cio_usbdev_dp_en_d2p),
		.dio_usbdev_dn_i(cio_usbdev_dn_p2d),
		.dio_usbdev_dn_o(cio_usbdev_dn_d2p),
		.dio_usbdev_dn_en_o(cio_usbdev_dn_en_d2p),
		.scanmode_i(1'b0)
	);
	clkgen_xil7series clkgen(
		.IO_CLK(IO_CLK),
		.IO_RST_N(IO_RST_N),
		.clk_sys(clk_sys),
		.clk_48MHz(clk_48mhz),
		.rst_sys_n(rst_sys_n)
	);
	assign cio_uart_rx_p2d = IO_URX;
	assign IO_UTX = (cio_uart_tx_en_d2p ? cio_uart_tx_d2p : 1'bz);
	assign cio_gpio_p2d = 1'b0;
	assign cio_gpio_p2d = 1'b0;
	assign cio_usbdev_sense_p2d = 1'b0;
	assign cio_usbdev_dp_p2d = 1'b0;
	assign cio_usbdev_dn_p2d = 1'b0;
endmodule
