module usbdev (
	clk_i,
	rst_ni,
	clk_usb_48mhz_i,
	rst_usb_48mhz_ni,
	tl_i,
	tl_o,
	cio_d_i,
	cio_dp_i,
	cio_dn_i,
	cio_d_o,
	cio_se0_o,
	cio_dp_o,
	cio_dn_o,
	cio_oe_o,
	cio_tx_mode_se_o,
	cio_sense_i,
	cio_pullup_en_o,
	cio_suspend_o,
	intr_pkt_received_o,
	intr_pkt_sent_o,
	intr_connected_o,
	intr_disconnected_o,
	intr_host_lost_o,
	intr_link_reset_o,
	intr_link_suspend_o,
	intr_link_resume_o,
	intr_av_empty_o,
	intr_rx_full_o,
	intr_av_overflow_o,
	intr_link_in_err_o,
	intr_rx_crc_err_o,
	intr_rx_pid_err_o,
	intr_rx_bitstuff_err_o,
	intr_frame_o
);
	localparam top_pkg_TL_AIW = 8;
	localparam top_pkg_TL_AW = 32;
	localparam top_pkg_TL_DBW = top_pkg_TL_DW >> 3;
	localparam top_pkg_TL_DIW = 1;
	localparam top_pkg_TL_DUW = 16;
	localparam top_pkg_TL_DW = 32;
	localparam top_pkg_TL_SZW = $clog2($clog2(32 >> 3) + 1);
	parameter signed [31:0] usbdev_reg_pkg_NEndpoints = 12;
	input wire clk_i;
	input wire rst_ni;
	input wire clk_usb_48mhz_i;
	input wire rst_usb_48mhz_ni;
	input wire [((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_AW) + ((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW)) + top_pkg_TL_DW) + 17) - 1:0] tl_i;
	output wire [((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_DIW) + top_pkg_TL_DW) + top_pkg_TL_DUW) + 2) - 1:0] tl_o;
	input wire cio_d_i;
	input wire cio_dp_i;
	input wire cio_dn_i;
	output wire cio_d_o;
	output wire cio_se0_o;
	output wire cio_dp_o;
	output wire cio_dn_o;
	output wire cio_oe_o;
	output wire cio_tx_mode_se_o;
	input wire cio_sense_i;
	output wire cio_pullup_en_o;
	output wire cio_suspend_o;
	output wire intr_pkt_received_o;
	output wire intr_pkt_sent_o;
	output wire intr_connected_o;
	output wire intr_disconnected_o;
	output wire intr_host_lost_o;
	output wire intr_link_reset_o;
	output wire intr_link_suspend_o;
	output wire intr_link_resume_o;
	output wire intr_av_empty_o;
	output wire intr_rx_full_o;
	output wire intr_av_overflow_o;
	output wire intr_link_in_err_o;
	output wire intr_rx_crc_err_o;
	output wire intr_rx_pid_err_o;
	output wire intr_rx_bitstuff_err_o;
	output wire intr_frame_o;
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
	localparam signed [31:0] SramDw = 32;
	localparam signed [31:0] SramDepth = 512;
	localparam signed [31:0] MaxPktSizeByte = 64;
	localparam signed [31:0] SramAw = 9;
	localparam signed [31:0] SizeWidth = 6;
	localparam signed [31:0] NBuf = (SramDepth * SramDw) / (MaxPktSizeByte * 8);
	localparam signed [31:0] NBufWidth = 5;
	localparam signed [31:0] AVFifoWidth = NBufWidth;
	localparam signed [31:0] AVFifoDepth = 4;
	localparam signed [31:0] RXFifoWidth = (NBufWidth + (1 + SizeWidth)) + 5;
	localparam signed [31:0] RXFifoDepth = 4;
	localparam signed [31:0] NEndpoints = usbdev_reg_pkg_NEndpoints;
	wire [343:0] reg2hw;
	reg [176:0] hw2reg;
	wire [((((((7 + (($clog2($clog2(32 >> 3) + 1) - 1) >= 0 ? $clog2($clog2(32 >> 3) + 1) : 2 - $clog2($clog2(32 >> 3) + 1))) + 40) + (((32 >> 3) - 1) >= 0 ? 32 >> 3 : 2 - (32 >> 3))) + 49) - 1) >= 0 ? (((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_AW) + ((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW)) + top_pkg_TL_DW) + 16 : (2 - ((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_AW) + ((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW)) + top_pkg_TL_DW) + 17)) + ((((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_AW) + ((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW)) + top_pkg_TL_DW) + 17) - 1) - 1)):((((((7 + (($clog2($clog2(32 >> 3) + 1) - 1) >= 0 ? $clog2($clog2(32 >> 3) + 1) : 2 - $clog2($clog2(32 >> 3) + 1))) + 40) + (((32 >> 3) - 1) >= 0 ? 32 >> 3 : 2 - (32 >> 3))) + 49) - 1) >= 0 ? 0 : ((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_AW) + ((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW)) + top_pkg_TL_DW) + 17) - 1)] tl_sram_h2d;
	wire [((((7 + (($clog2($clog2(32 >> 3) + 1) - 1) >= 0 ? $clog2($clog2(32 >> 3) + 1) : 2 - $clog2($clog2(32 >> 3) + 1))) + 59) - 1) >= 0 ? (((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_DIW) + top_pkg_TL_DW) + top_pkg_TL_DUW) + 1 : (2 - ((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_DIW) + top_pkg_TL_DW) + top_pkg_TL_DUW) + 2)) + ((((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_DIW) + top_pkg_TL_DW) + top_pkg_TL_DUW) + 2) - 1) - 1)):((((7 + (($clog2($clog2(32 >> 3) + 1) - 1) >= 0 ? $clog2($clog2(32 >> 3) + 1) : 2 - $clog2($clog2(32 >> 3) + 1))) + 59) - 1) >= 0 ? 0 : ((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_DIW) + top_pkg_TL_DW) + top_pkg_TL_DUW) + 2) - 1)] tl_sram_d2h;
	wire mem_a_req;
	wire mem_a_write;
	wire [SramAw - 1:0] mem_a_addr;
	wire [SramDw - 1:0] mem_a_wdata;
	wire mem_a_rvalid;
	wire [SramDw - 1:0] mem_a_rdata;
	wire [1:0] mem_a_rerror;
	wire usb_mem_b_req;
	wire usb_mem_b_write;
	wire [SramAw - 1:0] usb_mem_b_addr;
	wire [SramDw - 1:0] usb_mem_b_wdata;
	wire [SramDw - 1:0] usb_mem_b_rdata;
	wire usb_clr_devaddr;
	wire usb_event_av_empty;
	wire event_av_overflow;
	wire usb_event_rx_full;
	wire event_av_empty;
	wire event_rx_full;
	wire usb_event_link_reset;
	wire usb_event_link_suspend;
	wire usb_event_link_resume;
	wire usb_event_host_lost;
	wire usb_event_disconnect;
	wire usb_event_connect;
	wire usb_event_rx_crc_err;
	wire usb_event_rx_pid_err;
	wire usb_event_rx_bitstuff_err;
	wire usb_event_in_err;
	wire usb_event_frame;
	wire event_link_reset;
	wire event_link_suspend;
	wire event_link_resume;
	wire event_host_lost;
	wire event_disconnect;
	wire event_connect;
	wire event_rx_crc_err;
	wire event_rx_pid_err;
	wire event_rx_bitstuff_err;
	wire event_in_err;
	wire event_frame;
	wire [10:0] usb_frame;
	wire [2:0] usb_link_state;
	wire usb_enable;
	wire [6:0] usb_device_addr;
	wire usb_data_toggle_clear_en;
	reg [NEndpoints - 1:0] usb_data_toggle_clear;
	wire usb_rx_d;
	wire usb_rx_se0;
	wire usb_tx_d;
	wire usb_tx_se0;
	wire usb_tx_oe;
	wire usb_pwr_sense;
	wire usb_pullup_en;
	wire av_fifo_wready;
	wire event_pkt_received;
	wire usb_av_rvalid;
	wire usb_av_rready;
	wire usb_rx_wvalid;
	wire usb_rx_wready;
	wire rx_fifo_rvalid;
	wire [AVFifoWidth - 1:0] usb_av_rdata;
	wire [RXFifoWidth - 1:0] usb_rx_wdata;
	wire [RXFifoWidth - 1:0] rx_rdata_raw;
	wire [RXFifoWidth - 1:0] rx_rdata;
	assign event_av_overflow = reg2hw[266] & ~av_fifo_wready;
	always @(*) hw2reg[117] = ~av_fifo_wready;
	always @(*) hw2reg[113] = ~rx_fifo_rvalid;
	prim_fifo_async #(
		.Width(AVFifoWidth),
		.Depth(AVFifoDepth)
	) usbdev_avfifo(
		.clk_wr_i(clk_i),
		.rst_wr_ni(rst_ni),
		.wvalid(reg2hw[266]),
		.wready(av_fifo_wready),
		.wdata(reg2hw[271-:5]),
		.wdepth(hw2reg[120-:3]),
		.clk_rd_i(clk_usb_48mhz_i),
		.rst_rd_ni(rst_usb_48mhz_ni),
		.rvalid(usb_av_rvalid),
		.rready(usb_av_rready),
		.rdata(usb_av_rdata),
		.rdepth()
	);
	prim_fifo_async #(
		.Width(RXFifoWidth),
		.Depth(RXFifoDepth)
	) usbdev_rxfifo(
		.clk_wr_i(clk_usb_48mhz_i),
		.rst_wr_ni(rst_usb_48mhz_ni),
		.wvalid(usb_rx_wvalid),
		.wready(usb_rx_wready),
		.wdata(usb_rx_wdata),
		.wdepth(),
		.clk_rd_i(clk_i),
		.rst_rd_ni(rst_ni),
		.rvalid(rx_fifo_rvalid),
		.rready(reg2hw[260]),
		.rdata(rx_rdata_raw),
		.rdepth(hw2reg[116-:3])
	);
	assign rx_rdata = (rx_fifo_rvalid ? rx_rdata_raw : 1'sb0);
	always @(*) hw2reg[99-:4] = rx_rdata[16:13];
	always @(*) hw2reg[100] = rx_rdata[12];
	always @(*) hw2reg[107-:7] = rx_rdata[11:5];
	always @(*) hw2reg[112-:5] = rx_rdata[4:0];
	assign event_pkt_received = rx_fifo_rvalid;
	wire [2:0] unused_re;
	assign unused_re = {reg2hw[245], reg2hw[250], reg2hw[252]};
	reg [NBufWidth - 1:0] usb_in_buf [0:NEndpoints - 1];
	reg [SizeWidth:0] usb_in_size [0:NEndpoints - 1];
	wire [3:0] usb_in_endpoint;
	wire [NEndpoints - 1:0] usb_in_rdy;
	reg [NEndpoints - 1:0] clear_rdybit;
	reg [NEndpoints - 1:0] set_sentbit;
	reg [NEndpoints - 1:0] update_pend;
	wire usb_setup_received;
	wire setup_received;
	wire usb_set_sent;
	wire set_sent;
	reg [NEndpoints - 1:0] ep_iso;
	reg [NEndpoints - 1:0] enable_setup;
	reg [NEndpoints - 1:0] enable_out;
	reg [NEndpoints - 1:0] ep_stall;
	wire [NEndpoints - 1:0] usb_enable_setup;
	wire [NEndpoints - 1:0] usb_enable_out;
	wire [NEndpoints - 1:0] usb_ep_stall;
	reg [NEndpoints - 1:0] in_rdy_async;
	wire [3:0] usb_out_endpoint;
	always @(*) begin : proc_map_rxenable
		begin : sv2v_autoblock_156
			reg signed [31:0] i;
			for (i = 0; i < NEndpoints; i = i + 1)
				begin
					enable_setup[i] = reg2hw[233 + i];
					enable_out[i] = reg2hw[221 + i];
				end
		end
	end
	always @(*) begin : proc_map_stall
		begin : sv2v_autoblock_157
			reg signed [31:0] i;
			for (i = 0; i < NEndpoints; i = i + 1)
				ep_stall[i] = reg2hw[209 + i+:1];
		end
	end
	prim_flop_2sync #(.Width(3 * NEndpoints)) usbdev_sync_ep_cfg(
		.clk_i(clk_usb_48mhz_i),
		.rst_ni(rst_usb_48mhz_ni),
		.d({enable_setup, enable_out, ep_stall}),
		.q({usb_enable_setup, usb_enable_out, usb_ep_stall})
	);
	always @(*) begin : proc_map_iso
		begin : sv2v_autoblock_158
			reg signed [31:0] i;
			for (i = 0; i < NEndpoints; i = i + 1)
				ep_iso[i] = reg2hw[29 + i];
		end
	end
	always @(*) begin : proc_map_buf_size
		begin : sv2v_autoblock_159
			reg signed [31:0] i;
			for (i = 0; i < NEndpoints; i = i + 1)
				begin
					usb_in_buf[i] = reg2hw[41 + ((i * 14) + 13)-:5];
					usb_in_size[i] = reg2hw[41 + ((i * 14) + 8)-:7];
				end
		end
	end
	always @(*) begin : proc_map_rdy_reg2hw
		begin : sv2v_autoblock_160
			reg signed [31:0] i;
			for (i = 0; i < NEndpoints; i = i + 1)
				in_rdy_async[i] = reg2hw[41 + (i * 14)];
		end
	end
	prim_flop_2sync #(.Width(NEndpoints)) usbdev_rdysync(
		.clk_i(clk_usb_48mhz_i),
		.rst_ni(rst_usb_48mhz_ni),
		.d(in_rdy_async),
		.q(usb_in_rdy)
	);
	prim_pulse_sync usbdev_data_toggle_clear(
		.clk_src_i(clk_i),
		.clk_dst_i(clk_usb_48mhz_i),
		.rst_src_ni(rst_ni),
		.rst_dst_ni(rst_usb_48mhz_ni),
		.src_pulse_i(reg2hw[5]),
		.dst_pulse_o(usb_data_toggle_clear_en)
	);
	always @(*) begin : proc_usb_data_toggle_clear
		usb_data_toggle_clear = 1'sb0;
		begin : sv2v_autoblock_161
			reg signed [31:0] i;
			for (i = 0; i < NEndpoints; i = i + 1)
				if (usb_data_toggle_clear_en)
					usb_data_toggle_clear[i] = reg2hw[5 + ((i * 2) + 1)];
		end
	end
	prim_pulse_sync usbdev_setsent(
		.clk_src_i(clk_usb_48mhz_i),
		.clk_dst_i(clk_i),
		.rst_src_ni(rst_usb_48mhz_ni),
		.rst_dst_ni(rst_ni),
		.src_pulse_i(usb_set_sent),
		.dst_pulse_o(set_sent)
	);
	always @(*) begin
		set_sentbit = 1'sb0;
		if (set_sent)
			set_sentbit[usb_in_endpoint] = 1'b1;
	end
	always @(*) begin : proc_map_sent
		begin : sv2v_autoblock_162
			reg signed [31:0] i;
			for (i = 0; i < NEndpoints; i = i + 1)
				begin
					hw2reg[72 + (i * 2)] = set_sentbit[i];
					hw2reg[72 + ((i * 2) + 1)] = 1'b1;
				end
		end
	end
	prim_pulse_sync usbdev_sync_in_err(
		.clk_src_i(clk_usb_48mhz_i),
		.clk_dst_i(clk_i),
		.rst_src_ni(rst_usb_48mhz_ni),
		.rst_dst_ni(rst_ni),
		.src_pulse_i(usb_event_in_err),
		.dst_pulse_o(event_in_err)
	);
	prim_pulse_sync usbdev_outrdyclr(
		.clk_src_i(clk_usb_48mhz_i),
		.clk_dst_i(clk_i),
		.rst_src_ni(rst_usb_48mhz_ni),
		.rst_dst_ni(rst_ni),
		.src_pulse_i(usb_setup_received),
		.dst_pulse_o(setup_received)
	);
	prim_pulse_sync sync_usb_event_rx_crc_err(
		.clk_src_i(clk_usb_48mhz_i),
		.clk_dst_i(clk_i),
		.rst_src_ni(rst_usb_48mhz_ni),
		.rst_dst_ni(rst_ni),
		.src_pulse_i(usb_event_rx_crc_err),
		.dst_pulse_o(event_rx_crc_err)
	);
	prim_pulse_sync sync_usb_event_rx_pid_err(
		.clk_src_i(clk_usb_48mhz_i),
		.clk_dst_i(clk_i),
		.rst_src_ni(rst_usb_48mhz_ni),
		.rst_dst_ni(rst_ni),
		.src_pulse_i(usb_event_rx_pid_err),
		.dst_pulse_o(event_rx_pid_err)
	);
	prim_pulse_sync sync_usb_event_rx_bitstuff_err(
		.clk_src_i(clk_usb_48mhz_i),
		.clk_dst_i(clk_i),
		.rst_src_ni(rst_usb_48mhz_ni),
		.rst_dst_ni(rst_ni),
		.src_pulse_i(usb_event_rx_bitstuff_err),
		.dst_pulse_o(event_rx_bitstuff_err)
	);
	prim_pulse_sync sync_usb_event_frame(
		.clk_src_i(clk_usb_48mhz_i),
		.clk_dst_i(clk_i),
		.rst_src_ni(rst_usb_48mhz_ni),
		.rst_dst_ni(rst_ni),
		.src_pulse_i(usb_event_frame),
		.dst_pulse_o(event_frame)
	);
	reg event_link_reset_q;
	always @(posedge clk_usb_48mhz_i or negedge rst_usb_48mhz_ni)
		if (!rst_usb_48mhz_ni)
			event_link_reset_q <= 0;
		else
			event_link_reset_q <= event_link_reset;
	always @(*) begin
		clear_rdybit = 1'sb0;
		update_pend = 1'sb0;
		if (event_link_reset && !event_link_reset_q) begin
			clear_rdybit = {NEndpoints {1'b1}};
			update_pend = {NEndpoints {1'b1}};
		end
		else begin
			clear_rdybit[usb_out_endpoint] = setup_received;
			update_pend[usb_out_endpoint] = setup_received;
			clear_rdybit[usb_in_endpoint] = set_sent;
		end
	end
	always @(*) begin : proc_map_rdy_hw2reg
		begin : sv2v_autoblock_163
			reg signed [31:0] i;
			for (i = 0; i < NEndpoints; i = i + 1)
				begin
					hw2reg[i * 4] = clear_rdybit[i];
					hw2reg[(i * 4) + 1] = 1'b0;
				end
		end
	end
	always @(*) begin : proc_map_pend
		begin : sv2v_autoblock_164
			reg signed [31:0] i;
			for (i = 0; i < NEndpoints; i = i + 1)
				begin
					hw2reg[(i * 4) + 2] = update_pend[i];
					hw2reg[(i * 4) + 3] = reg2hw[41 + (i * 14)] | reg2hw[41 + ((i * 14) + 1)];
				end
		end
	end
	usbdev_usbif #(
		.NEndpoints(NEndpoints),
		.AVFifoWidth(AVFifoWidth),
		.RXFifoWidth(RXFifoWidth),
		.MaxPktSizeByte(MaxPktSizeByte),
		.NBuf(NBuf),
		.SramAw(SramAw)
	) usbdev_impl(
		.clk_48mhz_i(clk_usb_48mhz_i),
		.rst_ni(rst_usb_48mhz_ni),
		.usb_d_i(usb_rx_d),
		.usb_se0_i(usb_rx_se0),
		.usb_oe_o(usb_tx_oe),
		.usb_d_o(usb_tx_d),
		.usb_se0_o(usb_tx_se0),
		.usb_sense_i(usb_pwr_sense),
		.usb_pullup_en_o(usb_pullup_en),
		.rx_setup_i(usb_enable_setup),
		.rx_out_i(usb_enable_out),
		.rx_stall_i(usb_ep_stall),
		.av_rvalid_i(usb_av_rvalid),
		.av_rready_o(usb_av_rready),
		.av_rdata_i(usb_av_rdata),
		.event_av_empty_o(usb_event_av_empty),
		.rx_wvalid_o(usb_rx_wvalid),
		.rx_wready_i(usb_rx_wready),
		.rx_wdata_o(usb_rx_wdata),
		.event_rx_full_o(usb_event_rx_full),
		.setup_received_o(usb_setup_received),
		.out_endpoint_o(usb_out_endpoint),
		.in_buf_i(usb_in_buf[usb_in_endpoint]),
		.in_size_i(usb_in_size[usb_in_endpoint]),
		.in_stall_i(usb_ep_stall),
		.in_rdy_i(usb_in_rdy),
		.set_sent_o(usb_set_sent),
		.in_endpoint_o(usb_in_endpoint),
		.mem_req_o(usb_mem_b_req),
		.mem_write_o(usb_mem_b_write),
		.mem_addr_o(usb_mem_b_addr),
		.mem_wdata_o(usb_mem_b_wdata),
		.mem_rdata_i(usb_mem_b_rdata),
		.enable_i(usb_enable),
		.devaddr_i(usb_device_addr),
		.clr_devaddr_o(usb_clr_devaddr),
		.ep_iso_i(ep_iso),
		.cfg_eop_single_bit_i(reg2hw[2]),
		.tx_osc_test_mode_i(1'b0),
		.data_toggle_clear_i(usb_data_toggle_clear),
		.frame_o(usb_frame),
		.frame_start_o(usb_event_frame),
		.link_state_o(usb_link_state),
		.link_disconnect_o(usb_event_disconnect),
		.link_connect_o(usb_event_connect),
		.link_reset_o(usb_event_link_reset),
		.link_suspend_o(usb_event_link_suspend),
		.link_resume_o(usb_event_link_resume),
		.host_lost_o(usb_event_host_lost),
		.link_in_err_o(usb_event_in_err),
		.rx_crc_err_o(usb_event_rx_crc_err),
		.rx_pid_err_o(usb_event_rx_pid_err),
		.rx_bitstuff_err_o(usb_event_rx_bitstuff_err)
	);
	prim_flop_2sync #(.Width(14)) cdc_usb_to_sys(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.d({usb_link_state, usb_frame}),
		.q({hw2reg[124-:3], hw2reg[136-:11]})
	);
	prim_flop_2sync #(.Width(8)) cdc_sys_to_usb(
		.clk_i(clk_usb_48mhz_i),
		.rst_ni(rst_usb_48mhz_ni),
		.d({reg2hw[279], reg2hw[278-:7]}),
		.q({usb_enable, usb_device_addr})
	);
	usbdev_flop_2syncpulse #(.Width(5)) syncevent(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.d({usb_event_disconnect, usb_event_link_reset, usb_event_link_suspend, usb_event_host_lost, usb_event_connect}),
		.q({event_disconnect, event_link_reset, event_link_suspend, event_host_lost, event_connect})
	);
	prim_pulse_sync usbdev_resume(
		.clk_src_i(clk_usb_48mhz_i),
		.clk_dst_i(clk_i),
		.rst_src_ni(rst_usb_48mhz_ni),
		.rst_dst_ni(rst_ni),
		.src_pulse_i(usb_event_link_resume),
		.dst_pulse_o(event_link_resume)
	);
	always @(*) hw2reg[125] = event_host_lost;
	prim_pulse_sync usbdev_devclr(
		.clk_src_i(clk_usb_48mhz_i),
		.clk_dst_i(clk_i),
		.rst_src_ni(rst_usb_48mhz_ni),
		.rst_dst_ni(rst_ni),
		.src_pulse_i(usb_clr_devaddr),
		.dst_pulse_o(hw2reg[137])
	);
	always @(*) hw2reg[144-:7] = 1'sb0;
	prim_pulse_sync sync_usb_event_av_empty(
		.clk_src_i(clk_usb_48mhz_i),
		.clk_dst_i(clk_i),
		.rst_src_ni(rst_usb_48mhz_ni),
		.rst_dst_ni(rst_ni),
		.src_pulse_i(usb_event_av_empty),
		.dst_pulse_o(event_av_empty)
	);
	prim_pulse_sync sync_usb_event_rx_full(
		.clk_src_i(clk_usb_48mhz_i),
		.clk_dst_i(clk_i),
		.rst_src_ni(rst_usb_48mhz_ni),
		.rst_dst_ni(rst_ni),
		.src_pulse_i(usb_event_rx_full),
		.dst_pulse_o(event_rx_full)
	);
	always @(*) begin : proc_stall_tieoff
		begin : sv2v_autoblock_165
			reg signed [31:0] i;
			for (i = 0; i < NEndpoints; i = i + 1)
				begin
					hw2reg[48 + ((i * 2) + 1)] = 1'b0;
					if (setup_received && (usb_out_endpoint == sv2v_cast_4_signed(i)))
						hw2reg[48 + (i * 2)] = 1'b1;
					else
						hw2reg[48 + (i * 2)] = 1'b0;
				end
		end
	end
	wire unused_mem_a_rerror_d;
	tlul_adapter_sram #(
		.SramAw(SramAw),
		.ByteAccess(0)
	) u_tlul2sram(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.tl_i(tl_sram_h2d[((((((7 + (($clog2($clog2(32 >> 3) + 1) - 1) >= 0 ? $clog2($clog2(32 >> 3) + 1) : 2 - $clog2($clog2(32 >> 3) + 1))) + 40) + (((32 >> 3) - 1) >= 0 ? 32 >> 3 : 2 - (32 >> 3))) + 49) - 1) >= 0 ? 0 : ((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_AW) + ((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW)) + top_pkg_TL_DW) + 17) - 1)+:((((((7 + (($clog2($clog2(32 >> 3) + 1) - 1) >= 0 ? $clog2($clog2(32 >> 3) + 1) : 2 - $clog2($clog2(32 >> 3) + 1))) + 40) + (((32 >> 3) - 1) >= 0 ? 32 >> 3 : 2 - (32 >> 3))) + 49) - 1) >= 0 ? (((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_AW) + ((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW)) + top_pkg_TL_DW) + 17 : 2 - ((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_AW) + ((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW)) + top_pkg_TL_DW) + 17))]),
		.tl_o(tl_sram_d2h[((((7 + (($clog2($clog2(32 >> 3) + 1) - 1) >= 0 ? $clog2($clog2(32 >> 3) + 1) : 2 - $clog2($clog2(32 >> 3) + 1))) + 59) - 1) >= 0 ? 0 : ((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_DIW) + top_pkg_TL_DW) + top_pkg_TL_DUW) + 2) - 1)+:((((7 + (($clog2($clog2(32 >> 3) + 1) - 1) >= 0 ? $clog2($clog2(32 >> 3) + 1) : 2 - $clog2($clog2(32 >> 3) + 1))) + 59) - 1) >= 0 ? (((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_DIW) + top_pkg_TL_DW) + top_pkg_TL_DUW) + 2 : 2 - ((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_DIW) + top_pkg_TL_DW) + top_pkg_TL_DUW) + 2))]),
		.req_o(mem_a_req),
		.gnt_i(mem_a_req),
		.we_o(mem_a_write),
		.addr_o(mem_a_addr),
		.wdata_o(mem_a_wdata),
		.wmask_o(),
		.rdata_i(mem_a_rdata),
		.rvalid_i(mem_a_rvalid),
		.rerror_i(mem_a_rerror)
	);
	assign unused_mem_a_rerror_d = mem_a_rerror[1];
	prim_ram_2p_async_adv #(
		.Depth(SramDepth),
		.Width(SramDw),
		.CfgW(8),
		.EnableECC(0),
		.EnableParity(0),
		.EnableInputPipeline(0),
		.EnableOutputPipeline(0),
		.MemT("SRAM")
	) u_memory_2p(
		.clk_a_i(clk_i),
		.clk_b_i(clk_usb_48mhz_i),
		.rst_a_ni(rst_ni),
		.rst_b_ni(rst_usb_48mhz_ni),
		.a_req_i(mem_a_req),
		.a_write_i(mem_a_write),
		.a_addr_i(mem_a_addr),
		.a_wdata_i(mem_a_wdata),
		.a_rvalid_o(mem_a_rvalid),
		.a_rdata_o(mem_a_rdata),
		.a_rerror_o(mem_a_rerror),
		.b_req_i(usb_mem_b_req),
		.b_write_i(usb_mem_b_write),
		.b_addr_i(usb_mem_b_addr),
		.b_wdata_i(usb_mem_b_wdata),
		.b_rvalid_o(),
		.b_rdata_o(usb_mem_b_rdata),
		.b_rerror_o(),
		.cfg_i(8'h0)
	);
	usbdev_reg_top u_reg(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.tl_i(tl_i),
		.tl_o(tl_o),
		.tl_win_o(tl_sram_h2d),
		.tl_win_i(tl_sram_d2h),
		.reg2hw(reg2hw),
		.hw2reg(hw2reg),
		.devmode_i(1'b1)
	);
	prim_intr_hw #(.Width(1)) intr_hw_pkt_received(
		.event_intr_i(event_pkt_received),
		.reg2hw_intr_enable_q_i(reg2hw[327]),
		.reg2hw_intr_test_q_i(reg2hw[311]),
		.reg2hw_intr_test_qe_i(reg2hw[310]),
		.reg2hw_intr_state_q_i(reg2hw[343]),
		.hw2reg_intr_state_de_o(hw2reg[175]),
		.hw2reg_intr_state_d_o(hw2reg[176]),
		.intr_o(intr_pkt_received_o)
	);
	prim_intr_hw #(.Width(1)) intr_hw_pkt_sent(
		.event_intr_i(set_sent),
		.reg2hw_intr_enable_q_i(reg2hw[326]),
		.reg2hw_intr_test_q_i(reg2hw[309]),
		.reg2hw_intr_test_qe_i(reg2hw[308]),
		.reg2hw_intr_state_q_i(reg2hw[342]),
		.hw2reg_intr_state_de_o(hw2reg[173]),
		.hw2reg_intr_state_d_o(hw2reg[174]),
		.intr_o(intr_pkt_sent_o)
	);
	prim_intr_hw #(.Width(1)) intr_disconnected(
		.event_intr_i(event_disconnect),
		.reg2hw_intr_enable_q_i(reg2hw[325]),
		.reg2hw_intr_test_q_i(reg2hw[307]),
		.reg2hw_intr_test_qe_i(reg2hw[306]),
		.reg2hw_intr_state_q_i(reg2hw[341]),
		.hw2reg_intr_state_de_o(hw2reg[171]),
		.hw2reg_intr_state_d_o(hw2reg[172]),
		.intr_o(intr_disconnected_o)
	);
	prim_intr_hw #(.Width(1)) intr_connected(
		.event_intr_i(event_connect),
		.reg2hw_intr_enable_q_i(reg2hw[312]),
		.reg2hw_intr_test_q_i(reg2hw[281]),
		.reg2hw_intr_test_qe_i(reg2hw[280]),
		.reg2hw_intr_state_q_i(reg2hw[328]),
		.hw2reg_intr_state_de_o(hw2reg[145]),
		.hw2reg_intr_state_d_o(hw2reg[146]),
		.intr_o(intr_connected_o)
	);
	prim_intr_hw #(.Width(1)) intr_host_lost(
		.event_intr_i(event_host_lost),
		.reg2hw_intr_enable_q_i(reg2hw[324]),
		.reg2hw_intr_test_q_i(reg2hw[305]),
		.reg2hw_intr_test_qe_i(reg2hw[304]),
		.reg2hw_intr_state_q_i(reg2hw[340]),
		.hw2reg_intr_state_de_o(hw2reg[169]),
		.hw2reg_intr_state_d_o(hw2reg[170]),
		.intr_o(intr_host_lost_o)
	);
	prim_intr_hw #(.Width(1)) intr_link_reset(
		.event_intr_i(event_link_reset),
		.reg2hw_intr_enable_q_i(reg2hw[323]),
		.reg2hw_intr_test_q_i(reg2hw[303]),
		.reg2hw_intr_test_qe_i(reg2hw[302]),
		.reg2hw_intr_state_q_i(reg2hw[339]),
		.hw2reg_intr_state_de_o(hw2reg[167]),
		.hw2reg_intr_state_d_o(hw2reg[168]),
		.intr_o(intr_link_reset_o)
	);
	prim_intr_hw #(.Width(1)) intr_link_suspend(
		.event_intr_i(event_link_suspend),
		.reg2hw_intr_enable_q_i(reg2hw[322]),
		.reg2hw_intr_test_q_i(reg2hw[301]),
		.reg2hw_intr_test_qe_i(reg2hw[300]),
		.reg2hw_intr_state_q_i(reg2hw[338]),
		.hw2reg_intr_state_de_o(hw2reg[165]),
		.hw2reg_intr_state_d_o(hw2reg[166]),
		.intr_o(intr_link_suspend_o)
	);
	prim_intr_hw #(.Width(1)) intr_link_resume(
		.event_intr_i(event_link_resume),
		.reg2hw_intr_enable_q_i(reg2hw[321]),
		.reg2hw_intr_test_q_i(reg2hw[299]),
		.reg2hw_intr_test_qe_i(reg2hw[298]),
		.reg2hw_intr_state_q_i(reg2hw[337]),
		.hw2reg_intr_state_de_o(hw2reg[163]),
		.hw2reg_intr_state_d_o(hw2reg[164]),
		.intr_o(intr_link_resume_o)
	);
	prim_intr_hw #(.Width(1)) intr_av_empty(
		.event_intr_i(event_av_empty),
		.reg2hw_intr_enable_q_i(reg2hw[320]),
		.reg2hw_intr_test_q_i(reg2hw[297]),
		.reg2hw_intr_test_qe_i(reg2hw[296]),
		.reg2hw_intr_state_q_i(reg2hw[336]),
		.hw2reg_intr_state_de_o(hw2reg[161]),
		.hw2reg_intr_state_d_o(hw2reg[162]),
		.intr_o(intr_av_empty_o)
	);
	prim_intr_hw #(.Width(1)) intr_rx_full(
		.event_intr_i(event_rx_full),
		.reg2hw_intr_enable_q_i(reg2hw[319]),
		.reg2hw_intr_test_q_i(reg2hw[295]),
		.reg2hw_intr_test_qe_i(reg2hw[294]),
		.reg2hw_intr_state_q_i(reg2hw[335]),
		.hw2reg_intr_state_de_o(hw2reg[159]),
		.hw2reg_intr_state_d_o(hw2reg[160]),
		.intr_o(intr_rx_full_o)
	);
	prim_intr_hw #(.Width(1)) intr_av_overflow(
		.event_intr_i(event_av_overflow),
		.reg2hw_intr_enable_q_i(reg2hw[318]),
		.reg2hw_intr_test_q_i(reg2hw[293]),
		.reg2hw_intr_test_qe_i(reg2hw[292]),
		.reg2hw_intr_state_q_i(reg2hw[334]),
		.hw2reg_intr_state_de_o(hw2reg[157]),
		.hw2reg_intr_state_d_o(hw2reg[158]),
		.intr_o(intr_av_overflow_o)
	);
	prim_intr_hw #(.Width(1)) intr_link_in_err(
		.event_intr_i(event_in_err),
		.reg2hw_intr_enable_q_i(reg2hw[317]),
		.reg2hw_intr_test_q_i(reg2hw[291]),
		.reg2hw_intr_test_qe_i(reg2hw[290]),
		.reg2hw_intr_state_q_i(reg2hw[333]),
		.hw2reg_intr_state_de_o(hw2reg[155]),
		.hw2reg_intr_state_d_o(hw2reg[156]),
		.intr_o(intr_link_in_err_o)
	);
	prim_intr_hw #(.Width(1)) intr_rx_crc_err(
		.event_intr_i(event_rx_crc_err),
		.reg2hw_intr_enable_q_i(reg2hw[316]),
		.reg2hw_intr_test_q_i(reg2hw[289]),
		.reg2hw_intr_test_qe_i(reg2hw[288]),
		.reg2hw_intr_state_q_i(reg2hw[332]),
		.hw2reg_intr_state_de_o(hw2reg[153]),
		.hw2reg_intr_state_d_o(hw2reg[154]),
		.intr_o(intr_rx_crc_err_o)
	);
	prim_intr_hw #(.Width(1)) intr_rx_pid_err(
		.event_intr_i(event_rx_pid_err),
		.reg2hw_intr_enable_q_i(reg2hw[315]),
		.reg2hw_intr_test_q_i(reg2hw[287]),
		.reg2hw_intr_test_qe_i(reg2hw[286]),
		.reg2hw_intr_state_q_i(reg2hw[331]),
		.hw2reg_intr_state_de_o(hw2reg[151]),
		.hw2reg_intr_state_d_o(hw2reg[152]),
		.intr_o(intr_rx_pid_err_o)
	);
	prim_intr_hw #(.Width(1)) intr_rx_bitstuff_err(
		.event_intr_i(event_rx_bitstuff_err),
		.reg2hw_intr_enable_q_i(reg2hw[314]),
		.reg2hw_intr_test_q_i(reg2hw[285]),
		.reg2hw_intr_test_qe_i(reg2hw[284]),
		.reg2hw_intr_state_q_i(reg2hw[330]),
		.hw2reg_intr_state_de_o(hw2reg[149]),
		.hw2reg_intr_state_d_o(hw2reg[150]),
		.intr_o(intr_rx_bitstuff_err_o)
	);
	prim_intr_hw #(.Width(1)) intr_frame(
		.event_intr_i(event_frame),
		.reg2hw_intr_enable_q_i(reg2hw[313]),
		.reg2hw_intr_test_q_i(reg2hw[283]),
		.reg2hw_intr_test_qe_i(reg2hw[282]),
		.reg2hw_intr_state_q_i(reg2hw[329]),
		.hw2reg_intr_state_de_o(hw2reg[147]),
		.hw2reg_intr_state_d_o(hw2reg[148]),
		.intr_o(intr_frame_o)
	);
	usbdev_iomux i_usbdev_iomux(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.clk_usb_48mhz_i(clk_usb_48mhz_i),
		.rst_usb_48mhz_ni(rst_usb_48mhz_ni),
		.rx_differential_mode_i(reg2hw[4]),
		.tx_differential_mode_i(reg2hw[3]),
		.sys_reg2hw_config_i(reg2hw[4-:5]),
		.sys_usb_sense_o(hw2reg[121]),
		.cio_usb_d_i(cio_d_i),
		.cio_usb_dp_i(cio_dp_i),
		.cio_usb_dn_i(cio_dn_i),
		.cio_usb_d_o(cio_d_o),
		.cio_usb_se0_o(cio_se0_o),
		.cio_usb_dp_o(cio_dp_o),
		.cio_usb_dn_o(cio_dn_o),
		.cio_usb_oe_o(cio_oe_o),
		.cio_usb_tx_mode_se_o(cio_tx_mode_se_o),
		.cio_usb_sense_i(cio_sense_i),
		.cio_usb_pullup_en_o(cio_pullup_en_o),
		.cio_usb_suspend_o(cio_suspend_o),
		.usb_rx_d_o(usb_rx_d),
		.usb_rx_se0_o(usb_rx_se0),
		.usb_tx_d_i(usb_tx_d),
		.usb_tx_se0_i(usb_tx_se0),
		.usb_tx_oe_i(usb_tx_oe),
		.usb_pwr_sense_o(usb_pwr_sense),
		.usb_pullup_en_i(usb_pullup_en),
		.usb_suspend_i(usb_event_link_suspend)
	);
	function automatic signed [3:0] sv2v_cast_4_signed;
		input reg signed [3:0] inp;
		sv2v_cast_4_signed = inp;
	endfunction
endmodule
