module usb_fs_nb_pe (
	clk_48mhz_i,
	rst_ni,
	link_reset_i,
	dev_addr_i,
	cfg_eop_single_bit_i,
	tx_osc_test_mode_i,
	data_toggle_clear_i,
	out_ep_current_o,
	out_ep_data_put_o,
	out_ep_put_addr_o,
	out_ep_data_o,
	out_ep_newpkt_o,
	out_ep_acked_o,
	out_ep_rollback_o,
	out_ep_setup_o,
	out_ep_full_i,
	out_ep_stall_i,
	out_ep_iso_i,
	in_ep_current_o,
	in_ep_rollback_o,
	in_ep_acked_o,
	in_ep_get_addr_o,
	in_ep_data_get_o,
	in_ep_newpkt_o,
	in_ep_stall_i,
	in_ep_has_data_i,
	in_ep_data_i,
	in_ep_data_done_i,
	in_ep_iso_i,
	sof_valid_o,
	frame_index_o,
	rx_crc_err_o,
	rx_pid_err_o,
	rx_bitstuff_err_o,
	usb_d_i,
	usb_se0_i,
	usb_d_o,
	usb_se0_o,
	usb_oe_o
);
	parameter [31:0] NumOutEps = 2;
	parameter [31:0] NumInEps = 2;
	parameter [31:0] MaxPktSizeByte = 32;
	localparam [31:0] PktW = $clog2(MaxPktSizeByte);
	input wire clk_48mhz_i;
	input wire rst_ni;
	input wire link_reset_i;
	input wire [6:0] dev_addr_i;
	input wire cfg_eop_single_bit_i;
	input wire tx_osc_test_mode_i;
	input wire [NumOutEps - 1:0] data_toggle_clear_i;
	output wire [3:0] out_ep_current_o;
	output wire out_ep_data_put_o;
	output wire [PktW - 1:0] out_ep_put_addr_o;
	output wire [7:0] out_ep_data_o;
	output wire out_ep_newpkt_o;
	output wire out_ep_acked_o;
	output wire out_ep_rollback_o;
	output wire [NumOutEps - 1:0] out_ep_setup_o;
	input wire [NumOutEps - 1:0] out_ep_full_i;
	input wire [NumOutEps - 1:0] out_ep_stall_i;
	input wire [NumOutEps - 1:0] out_ep_iso_i;
	output wire [3:0] in_ep_current_o;
	output wire in_ep_rollback_o;
	output wire in_ep_acked_o;
	output wire [PktW - 1:0] in_ep_get_addr_o;
	output wire in_ep_data_get_o;
	output wire in_ep_newpkt_o;
	input wire [NumInEps - 1:0] in_ep_stall_i;
	input wire [NumInEps - 1:0] in_ep_has_data_i;
	input wire [7:0] in_ep_data_i;
	input wire [NumInEps - 1:0] in_ep_data_done_i;
	input wire [NumInEps - 1:0] in_ep_iso_i;
	output wire sof_valid_o;
	output wire [10:0] frame_index_o;
	output wire rx_crc_err_o;
	output wire rx_pid_err_o;
	output wire rx_bitstuff_err_o;
	input wire usb_d_i;
	input wire usb_se0_i;
	output wire usb_d_o;
	output wire usb_se0_o;
	output wire usb_oe_o;
	localparam [1:0] UsbPidTypeSpecial = 2'b00;
	localparam [1:0] UsbPidTypeToken = 2'b01;
	localparam [1:0] UsbPidTypeHandshake = 2'b10;
	localparam [1:0] UsbPidTypeData = 2'b11;
	localparam [3:0] UsbPidOut = 4'b0001;
	localparam [3:0] UsbPidAck = 4'b0010;
	localparam [3:0] UsbPidData0 = 4'b0011;
	localparam [3:0] UsbPidSof = 4'b0101;
	localparam [3:0] UsbPidNyet = 4'b0110;
	localparam [3:0] UsbPidData2 = 4'b0111;
	localparam [3:0] UsbPidIn = 4'b1001;
	localparam [3:0] UsbPidNak = 4'b1010;
	localparam [3:0] UsbPidData1 = 4'b1011;
	localparam [3:0] UsbPidSetup = 4'b1101;
	localparam [3:0] UsbPidStall = 4'b1110;
	localparam [3:0] UsbPidMData = 4'b1111;
	localparam [7:0] SetupGetStatus = 8'd0;
	localparam [7:0] DscrTypeDevice = 8'd1;
	localparam [7:0] SetupClearFeature = 8'd1;
	localparam [7:0] SetupGetInterface = 8'd10;
	localparam [7:0] SetupSetInterface = 8'd11;
	localparam [7:0] SetupSynchFrame = 8'd12;
	localparam [7:0] DscrTypeConfiguration = 8'd2;
	localparam [7:0] DscrTypeString = 8'd3;
	localparam [7:0] SetupSetFeature = 8'd3;
	localparam [7:0] DscrTypeInterface = 8'd4;
	localparam [7:0] DscrTypeEndpoint = 8'd5;
	localparam [7:0] SetupSetAddress = 8'd5;
	localparam [7:0] DscrTypeDevQual = 8'd6;
	localparam [7:0] SetupGetDescriptor = 8'd6;
	localparam [7:0] DscrTypeOthrSpd = 8'd7;
	localparam [7:0] SetupSetDescriptor = 8'd7;
	localparam [7:0] DscrTypeIntPwr = 8'd8;
	localparam [7:0] SetupGetConfiguration = 8'd8;
	localparam [7:0] SetupSetConfiguration = 8'd9;
	wire bit_strobe;
	wire rx_pkt_start;
	wire rx_pkt_end;
	wire [3:0] rx_pid;
	wire [6:0] rx_addr;
	wire [3:0] rx_endp;
	wire [10:0] rx_frame_num;
	wire rx_data_put;
	wire [7:0] rx_data;
	wire rx_pkt_valid;
	wire in_tx_pkt_start;
	wire [3:0] in_tx_pid;
	wire out_tx_pkt_start;
	wire [3:0] out_tx_pid;
	wire tx_pkt_start;
	wire tx_pkt_end;
	wire [3:0] tx_pid;
	wire tx_data_avail;
	wire tx_data_get;
	wire [7:0] tx_data;
	wire usb_oe;
	assign sof_valid_o = (rx_pkt_end & rx_pkt_valid) & (sv2v_cast_4(rx_pid) == UsbPidSof);
	assign frame_index_o = rx_frame_num;
	assign usb_oe_o = usb_oe;
	usb_fs_nb_in_pe #(
		.NumInEps(NumInEps),
		.MaxInPktSizeByte(MaxPktSizeByte)
	) u_usb_fs_nb_in_pe(
		.clk_48mhz_i(clk_48mhz_i),
		.rst_ni(rst_ni),
		.link_reset_i(link_reset_i),
		.dev_addr_i(dev_addr_i),
		.in_ep_current_o(in_ep_current_o),
		.in_ep_rollback_o(in_ep_rollback_o),
		.in_ep_acked_o(in_ep_acked_o),
		.in_ep_get_addr_o(in_ep_get_addr_o),
		.in_ep_data_get_o(in_ep_data_get_o),
		.in_ep_newpkt_o(in_ep_newpkt_o),
		.in_ep_stall_i(in_ep_stall_i),
		.in_ep_has_data_i(in_ep_has_data_i),
		.in_ep_data_i(in_ep_data_i),
		.in_ep_data_done_i(in_ep_data_done_i),
		.in_ep_iso_i(in_ep_iso_i),
		.data_toggle_clear_i(data_toggle_clear_i),
		.rx_pkt_start_i(rx_pkt_start),
		.rx_pkt_end_i(rx_pkt_end),
		.rx_pkt_valid_i(rx_pkt_valid),
		.rx_pid_i(rx_pid),
		.rx_addr_i(rx_addr),
		.rx_endp_i(rx_endp),
		.tx_pkt_start_o(in_tx_pkt_start),
		.tx_pkt_end_i(tx_pkt_end),
		.tx_pid_o(in_tx_pid),
		.tx_data_avail_o(tx_data_avail),
		.tx_data_get_i(tx_data_get),
		.tx_data_o(tx_data)
	);
	usb_fs_nb_out_pe #(
		.NumOutEps(NumOutEps),
		.MaxOutPktSizeByte(MaxPktSizeByte)
	) u_usb_fs_nb_out_pe(
		.clk_48mhz_i(clk_48mhz_i),
		.rst_ni(rst_ni),
		.link_reset_i(link_reset_i),
		.dev_addr_i(dev_addr_i),
		.out_ep_current_o(out_ep_current_o),
		.out_ep_data_put_o(out_ep_data_put_o),
		.out_ep_put_addr_o(out_ep_put_addr_o),
		.out_ep_data_o(out_ep_data_o),
		.out_ep_newpkt_o(out_ep_newpkt_o),
		.out_ep_acked_o(out_ep_acked_o),
		.out_ep_rollback_o(out_ep_rollback_o),
		.out_ep_setup_o(out_ep_setup_o),
		.out_ep_full_i(out_ep_full_i),
		.out_ep_stall_i(out_ep_stall_i),
		.out_ep_iso_i(out_ep_iso_i),
		.data_toggle_clear_i(data_toggle_clear_i),
		.rx_pkt_start_i(rx_pkt_start),
		.rx_pkt_end_i(rx_pkt_end),
		.rx_pkt_valid_i(rx_pkt_valid),
		.rx_pid_i(rx_pid),
		.rx_addr_i(rx_addr),
		.rx_endp_i(rx_endp),
		.rx_data_put_i(rx_data_put),
		.rx_data_i(rx_data),
		.tx_pkt_start_o(out_tx_pkt_start),
		.tx_pkt_end_i(tx_pkt_end),
		.tx_pid_o(out_tx_pid)
	);
	usb_fs_rx u_usb_fs_rx(
		.clk_i(clk_48mhz_i),
		.rst_ni(rst_ni),
		.link_reset_i(link_reset_i),
		.cfg_eop_single_bit_i(cfg_eop_single_bit_i),
		.usb_d_i(usb_d_i),
		.usb_se0_i(usb_se0_i),
		.tx_en_i(usb_oe),
		.bit_strobe_o(bit_strobe),
		.pkt_start_o(rx_pkt_start),
		.pkt_end_o(rx_pkt_end),
		.pid_o(rx_pid),
		.addr_o(rx_addr),
		.endp_o(rx_endp),
		.frame_num_o(rx_frame_num),
		.rx_data_put_o(rx_data_put),
		.rx_data_o(rx_data),
		.valid_packet_o(rx_pkt_valid),
		.crc_error_o(rx_crc_err_o),
		.pid_error_o(rx_pid_err_o),
		.bitstuff_error_o(rx_bitstuff_err_o)
	);
	usb_fs_tx_mux u_usb_fs_tx_mux(
		.in_tx_pkt_start_i(in_tx_pkt_start),
		.in_tx_pid_i(in_tx_pid),
		.out_tx_pkt_start_i(out_tx_pkt_start),
		.out_tx_pid_i(out_tx_pid),
		.tx_pkt_start_o(tx_pkt_start),
		.tx_pid_o(tx_pid)
	);
	usb_fs_tx u_usb_fs_tx(
		.clk_i(clk_48mhz_i),
		.rst_ni(rst_ni),
		.link_reset_i(link_reset_i),
		.tx_osc_test_mode_i(tx_osc_test_mode_i),
		.bit_strobe_i(bit_strobe),
		.usb_d_o(usb_d_o),
		.usb_se0_o(usb_se0_o),
		.usb_oe_o(usb_oe),
		.pkt_start_i(tx_pkt_start),
		.pkt_end_o(tx_pkt_end),
		.pid_i(tx_pid),
		.tx_data_avail_i(tx_data_avail),
		.tx_data_get_o(tx_data_get),
		.tx_data_i(tx_data)
	);
	function automatic [3:0] sv2v_cast_4;
		input reg [3:0] inp;
		sv2v_cast_4 = inp;
	endfunction
endmodule
