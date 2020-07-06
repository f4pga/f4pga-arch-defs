module usbdev_iomux (
	clk_i,
	rst_ni,
	clk_usb_48mhz_i,
	rst_usb_48mhz_ni,
	rx_differential_mode_i,
	tx_differential_mode_i,
	sys_reg2hw_config_i,
	sys_usb_sense_o,
	cio_usb_d_i,
	cio_usb_dp_i,
	cio_usb_dn_i,
	cio_usb_d_o,
	cio_usb_se0_o,
	cio_usb_dp_o,
	cio_usb_dn_o,
	cio_usb_oe_o,
	cio_usb_tx_mode_se_o,
	cio_usb_sense_i,
	cio_usb_pullup_en_o,
	cio_usb_suspend_o,
	usb_rx_d_o,
	usb_rx_se0_o,
	usb_tx_d_i,
	usb_tx_se0_i,
	usb_tx_oe_i,
	usb_pwr_sense_o,
	usb_pullup_en_i,
	usb_suspend_i
);
	parameter signed [31:0] NEndpoints = 12;
	parameter [11:0] USBDEV_INTR_STATE_OFFSET = 12'h 0;
	parameter [11:0] USBDEV_INTR_ENABLE_OFFSET = 12'h 4;
	parameter [11:0] USBDEV_INTR_TEST_OFFSET = 12'h 8;
	parameter [11:0] USBDEV_USBCTRL_OFFSET = 12'h c;
	parameter [11:0] USBDEV_USBSTAT_OFFSET = 12'h 10;
	parameter [11:0] USBDEV_AVBUFFER_OFFSET = 12'h 14;
	parameter [11:0] USBDEV_RXFIFO_OFFSET = 12'h 18;
	parameter [11:0] USBDEV_RXENABLE_SETUP_OFFSET = 12'h 1c;
	parameter [11:0] USBDEV_RXENABLE_OUT_OFFSET = 12'h 20;
	parameter [11:0] USBDEV_IN_SENT_OFFSET = 12'h 24;
	parameter [11:0] USBDEV_STALL_OFFSET = 12'h 28;
	parameter [11:0] USBDEV_CONFIGIN0_OFFSET = 12'h 2c;
	parameter [11:0] USBDEV_CONFIGIN1_OFFSET = 12'h 30;
	parameter [11:0] USBDEV_CONFIGIN2_OFFSET = 12'h 34;
	parameter [11:0] USBDEV_CONFIGIN3_OFFSET = 12'h 38;
	parameter [11:0] USBDEV_CONFIGIN4_OFFSET = 12'h 3c;
	parameter [11:0] USBDEV_CONFIGIN5_OFFSET = 12'h 40;
	parameter [11:0] USBDEV_CONFIGIN6_OFFSET = 12'h 44;
	parameter [11:0] USBDEV_CONFIGIN7_OFFSET = 12'h 48;
	parameter [11:0] USBDEV_CONFIGIN8_OFFSET = 12'h 4c;
	parameter [11:0] USBDEV_CONFIGIN9_OFFSET = 12'h 50;
	parameter [11:0] USBDEV_CONFIGIN10_OFFSET = 12'h 54;
	parameter [11:0] USBDEV_CONFIGIN11_OFFSET = 12'h 58;
	parameter [11:0] USBDEV_ISO_OFFSET = 12'h 5c;
	parameter [11:0] USBDEV_DATA_TOGGLE_CLEAR_OFFSET = 12'h 60;
	parameter [11:0] USBDEV_PHY_CONFIG_OFFSET = 12'h 64;
	parameter [11:0] USBDEV_BUFFER_OFFSET = 12'h 800;
	parameter [11:0] USBDEV_BUFFER_SIZE = 12'h 800;
	parameter [103:0] USBDEV_PERMIT = {4'b 0011, 4'b 0011, 4'b 0011, 4'b 0111, 4'b 1111, 4'b 0001, 4'b 0111, 4'b 0011, 4'b 0011, 4'b 0011, 4'b 0011, 4'b 1111, 4'b 1111, 4'b 1111, 4'b 1111, 4'b 1111, 4'b 1111, 4'b 1111, 4'b 1111, 4'b 1111, 4'b 1111, 4'b 1111, 4'b 1111, 4'b 0011, 4'b 0011, 4'b 0001};
	localparam USBDEV_INTR_STATE = 0;
	localparam USBDEV_INTR_ENABLE = 1;
	localparam USBDEV_STALL = 10;
	localparam USBDEV_CONFIGIN0 = 11;
	localparam USBDEV_CONFIGIN1 = 12;
	localparam USBDEV_CONFIGIN2 = 13;
	localparam USBDEV_CONFIGIN3 = 14;
	localparam USBDEV_CONFIGIN4 = 15;
	localparam USBDEV_CONFIGIN5 = 16;
	localparam USBDEV_CONFIGIN6 = 17;
	localparam USBDEV_CONFIGIN7 = 18;
	localparam USBDEV_CONFIGIN8 = 19;
	localparam USBDEV_INTR_TEST = 2;
	localparam USBDEV_CONFIGIN9 = 20;
	localparam USBDEV_CONFIGIN10 = 21;
	localparam USBDEV_CONFIGIN11 = 22;
	localparam USBDEV_ISO = 23;
	localparam USBDEV_DATA_TOGGLE_CLEAR = 24;
	localparam USBDEV_PHY_CONFIG = 25;
	localparam USBDEV_USBCTRL = 3;
	localparam USBDEV_USBSTAT = 4;
	localparam USBDEV_AVBUFFER = 5;
	localparam USBDEV_RXFIFO = 6;
	localparam USBDEV_RXENABLE_SETUP = 7;
	localparam USBDEV_RXENABLE_OUT = 8;
	localparam USBDEV_IN_SENT = 9;
	input wire clk_i;
	input wire rst_ni;
	input wire clk_usb_48mhz_i;
	input wire rst_usb_48mhz_ni;
	input wire rx_differential_mode_i;
	input wire tx_differential_mode_i;
	input wire [4:0] sys_reg2hw_config_i;
	output wire sys_usb_sense_o;
	input wire cio_usb_d_i;
	input wire cio_usb_dp_i;
	input wire cio_usb_dn_i;
	output wire cio_usb_d_o;
	output wire cio_usb_se0_o;
	output reg cio_usb_dp_o;
	output reg cio_usb_dn_o;
	output wire cio_usb_oe_o;
	output reg cio_usb_tx_mode_se_o;
	input wire cio_usb_sense_i;
	output reg cio_usb_pullup_en_o;
	output reg cio_usb_suspend_o;
	output reg usb_rx_d_o;
	output reg usb_rx_se0_o;
	input wire usb_tx_d_i;
	input wire usb_tx_se0_i;
	input wire usb_tx_oe_i;
	output wire usb_pwr_sense_o;
	input wire usb_pullup_en_i;
	input wire usb_suspend_i;
	reg async_pwr_sense;
	wire sys_usb_sense;
	wire usb_rx_d;
	wire usb_rx_dp;
	wire usb_rx_dn;
	prim_flop_2sync #(.Width(1)) cdc_io_to_sys(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.d(cio_usb_sense_i),
		.q(sys_usb_sense)
	);
	assign sys_usb_sense_o = sys_usb_sense;
	prim_flop_2sync #(.Width(4)) cdc_io_to_usb(
		.clk_i(clk_usb_48mhz_i),
		.rst_ni(rst_usb_48mhz_ni),
		.d({cio_usb_dp_i, cio_usb_dn_i, cio_usb_d_i, async_pwr_sense}),
		.q({usb_rx_dp, usb_rx_dn, usb_rx_d, usb_pwr_sense_o})
	);
	always @(*) begin : proc_drive_out
		cio_usb_dn_o = 1'b0;
		cio_usb_dp_o = 1'b0;
		cio_usb_pullup_en_o = usb_pullup_en_i;
		cio_usb_suspend_o = usb_suspend_i;
		if (tx_differential_mode_i)
			cio_usb_tx_mode_se_o = 1'b0;
		else begin
			cio_usb_tx_mode_se_o = 1'b1;
			if (usb_tx_se0_i) begin
				cio_usb_dp_o = 1'b0;
				cio_usb_dn_o = 1'b0;
			end
			else begin
				cio_usb_dp_o = usb_tx_d_i;
				cio_usb_dn_o = !usb_tx_d_i;
			end
		end
	end
	assign cio_usb_d_o = usb_tx_d_i;
	assign cio_usb_se0_o = usb_tx_se0_i;
	assign cio_usb_oe_o = usb_tx_oe_i;
	always @(*) begin : proc_mux_data_input
		usb_rx_se0_o = ~usb_rx_dp & ~usb_rx_dn;
		if (rx_differential_mode_i)
			usb_rx_d_o = usb_rx_d;
		else
			usb_rx_d_o = usb_rx_dp;
	end
	always @(*) begin : proc_mux_pwr_input
		if (sys_reg2hw_config_i[1])
			async_pwr_sense = sys_reg2hw_config_i[0];
		else
			async_pwr_sense = cio_usb_sense_i;
	end
endmodule
