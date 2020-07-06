module usbdev_usbif (
	clk_48mhz_i,
	rst_ni,
	usb_d_i,
	usb_se0_i,
	usb_d_o,
	usb_se0_o,
	usb_oe_o,
	usb_pullup_en_o,
	usb_sense_i,
	rx_setup_i,
	rx_out_i,
	rx_stall_i,
	av_rvalid_i,
	av_rready_o,
	av_rdata_i,
	event_av_empty_o,
	rx_wvalid_o,
	rx_wready_i,
	rx_wdata_o,
	event_rx_full_o,
	setup_received_o,
	out_endpoint_o,
	in_buf_i,
	in_size_i,
	in_stall_i,
	in_rdy_i,
	set_sent_o,
	in_endpoint_o,
	mem_req_o,
	mem_write_o,
	mem_addr_o,
	mem_wdata_o,
	mem_rdata_i,
	enable_i,
	devaddr_i,
	clr_devaddr_o,
	ep_iso_i,
	cfg_eop_single_bit_i,
	tx_osc_test_mode_i,
	data_toggle_clear_i,
	frame_start_o,
	frame_o,
	link_state_o,
	link_disconnect_o,
	link_connect_o,
	link_reset_o,
	link_suspend_o,
	link_resume_o,
	link_in_err_o,
	host_lost_o,
	rx_crc_err_o,
	rx_pid_err_o,
	rx_bitstuff_err_o
);
	parameter signed [31:0] NEndpoints = 12;
	parameter signed [31:0] AVFifoWidth = 4;
	parameter signed [31:0] RXFifoWidth = 4;
	parameter signed [31:0] MaxPktSizeByte = 64;
	parameter signed [31:0] NBuf = 4;
	parameter signed [31:0] SramAw = 4;
	localparam signed [31:0] NBufWidth = $clog2(NBuf);
	localparam signed [31:0] PktW = $clog2(MaxPktSizeByte);
	input wire clk_48mhz_i;
	input wire rst_ni;
	input wire usb_d_i;
	input wire usb_se0_i;
	output wire usb_d_o;
	output wire usb_se0_o;
	output wire usb_oe_o;
	output wire usb_pullup_en_o;
	input wire usb_sense_i;
	input wire [NEndpoints - 1:0] rx_setup_i;
	input wire [NEndpoints - 1:0] rx_out_i;
	input wire [NEndpoints - 1:0] rx_stall_i;
	input wire av_rvalid_i;
	output reg av_rready_o;
	input wire [AVFifoWidth - 1:0] av_rdata_i;
	output wire event_av_empty_o;
	output wire rx_wvalid_o;
	input wire rx_wready_i;
	output wire [RXFifoWidth - 1:0] rx_wdata_o;
	output wire event_rx_full_o;
	output wire setup_received_o;
	output [3:0] out_endpoint_o;
	input wire [NBufWidth - 1:0] in_buf_i;
	input wire [PktW:0] in_size_i;
	input wire [NEndpoints - 1:0] in_stall_i;
	input wire [NEndpoints - 1:0] in_rdy_i;
	output wire set_sent_o;
	output [3:0] in_endpoint_o;
	output wire mem_req_o;
	output wire mem_write_o;
	output wire [SramAw - 1:0] mem_addr_o;
	output wire [31:0] mem_wdata_o;
	input wire [31:0] mem_rdata_i;
	input wire enable_i;
	input wire [6:0] devaddr_i;
	output wire clr_devaddr_o;
	input wire [NEndpoints - 1:0] ep_iso_i;
	input wire cfg_eop_single_bit_i;
	input wire tx_osc_test_mode_i;
	input wire [NEndpoints - 1:0] data_toggle_clear_i;
	output wire frame_start_o;
	output reg [10:0] frame_o;
	output wire [2:0] link_state_o;
	output wire link_disconnect_o;
	output wire link_connect_o;
	output wire link_reset_o;
	output wire link_suspend_o;
	output wire link_resume_o;
	output wire link_in_err_o;
	output wire host_lost_o;
	output wire rx_crc_err_o;
	output wire rx_pid_err_o;
	output wire rx_bitstuff_err_o;
	assign usb_pullup_en_o = enable_i;
	reg [PktW:0] out_max_used_d;
	reg [PktW:0] out_max_used_q;
	wire [PktW - 1:0] out_ep_put_addr;
	wire [7:0] out_ep_data;
	wire [3:0] out_ep_current;
	wire out_ep_data_put;
	wire out_ep_acked;
	wire out_ep_rollback;
	wire current_setup;
	wire all_out_blocked;
	wire out_ep_newpkt;
	wire [NEndpoints - 1:0] out_ep_setup;
	wire [NEndpoints - 1:0] out_ep_full;
	wire [NEndpoints - 1:0] out_ep_stall;
	wire [NEndpoints - 1:0] setup_blocked;
	wire [NEndpoints - 1:0] out_blocked;
	reg [31:0] wdata;
	wire mem_read;
	wire [SramAw - 1:0] mem_waddr;
	wire [SramAw - 1:0] mem_raddr;
	wire link_reset;
	wire sof_valid;
	assign out_endpoint_o = (out_ep_current < NEndpoints ? out_ep_current : 1'sb0);
	assign link_reset_o = link_reset;
	assign clr_devaddr_o = ~enable_i | link_reset;
	assign frame_start_o = sof_valid;
	always @(*)
		if (out_ep_acked || out_ep_rollback)
			out_max_used_d = 0;
		else if (out_ep_data_put) begin
			if (out_max_used_q < (MaxPktSizeByte - 1))
				out_max_used_d = out_ep_put_addr;
			else if (out_max_used_q < (MaxPktSizeByte + 1))
				out_max_used_d = out_max_used_q + 1;
			else
				out_max_used_d = out_max_used_q;
		end
		else
			out_max_used_d = out_max_used_q;
	wire std_write_d;
	reg std_write_q;
	assign std_write_d = out_ep_data_put & ((out_max_used_q < (MaxPktSizeByte - 1)) & (out_ep_put_addr[1:0] == 2'b11));
	always @(posedge clk_48mhz_i or negedge rst_ni)
		if (!rst_ni) begin
			out_max_used_q <= 1'sb0;
			wdata <= 1'sb0;
			std_write_q <= 1'b0;
		end
		else begin
			out_max_used_q <= out_max_used_d;
			std_write_q <= std_write_d;
			if (out_ep_data_put)
				case (out_ep_put_addr[1:0])
					0: wdata[7:0] <= out_ep_data;
					1: wdata[15:8] <= out_ep_data;
					2: wdata[23:16] <= out_ep_data;
					3: wdata[31:24] <= out_ep_data;
				endcase
		end
	assign mem_write_o = std_write_q | ((~out_max_used_q[PktW] & (out_max_used_q[1:0] != 2'b11)) & out_ep_acked);
	assign mem_waddr = {av_rdata_i, out_max_used_q[PktW - 1:2]};
	assign mem_wdata_o = wdata;
	assign mem_addr_o = (mem_write_o ? mem_waddr : mem_raddr);
	assign mem_req_o = mem_read | mem_write_o;
	assign current_setup = out_ep_setup[out_endpoint_o];
	wire [PktW:0] out_max_minus1;
	assign out_max_minus1 = out_max_used_q - 1;
	assign rx_wdata_o = {out_endpoint_o, current_setup, out_max_minus1, av_rdata_i};
	assign rx_wvalid_o = out_ep_acked & ~all_out_blocked;
	always @(posedge clk_48mhz_i or negedge rst_ni)
		if (!rst_ni)
			av_rready_o <= 1'b0;
		else
			av_rready_o <= rx_wvalid_o;
	assign setup_blocked = out_ep_setup & ~rx_setup_i;
	assign out_blocked = ~out_ep_setup & ~rx_out_i;
	assign all_out_blocked = ~rx_wready_i | ~av_rvalid_i;
	assign event_av_empty_o = out_ep_newpkt & ~av_rvalid_i;
	assign event_rx_full_o = out_ep_newpkt & ~rx_wready_i;
	assign out_ep_full = ({NEndpoints {all_out_blocked}} | setup_blocked) | out_blocked;
	assign out_ep_stall = rx_stall_i;
	assign setup_received_o = current_setup & rx_wvalid_o;
	wire in_ep_acked;
	wire in_ep_data_get;
	wire in_data_done;
	wire in_ep_newpkt;
	reg pkt_start_rd;
	reg [NEndpoints - 1:0] in_ep_data_done;
	wire [PktW - 1:0] in_ep_get_addr;
	wire [7:0] in_ep_data;
	wire [3:0] in_ep_current;
	assign in_endpoint_o = (in_ep_current < NEndpoints ? in_ep_current : 1'sb0);
	assign in_data_done = {1'b0, in_ep_get_addr} == in_size_i;
	always @(*) begin
		in_ep_data_done = 1'sb0;
		in_ep_data_done[in_endpoint_o] = in_data_done;
	end
	always @(posedge clk_48mhz_i or negedge rst_ni)
		if (!rst_ni)
			pkt_start_rd <= 1'b0;
		else
			pkt_start_rd <= in_ep_newpkt;
	assign mem_raddr = {in_buf_i, in_ep_get_addr[PktW - 1:2]};
	assign mem_read = pkt_start_rd | (in_ep_data_get & (in_ep_get_addr[1:0] == 2'b0));
	assign in_ep_data = (in_ep_get_addr[1] ? (in_ep_get_addr[0] ? mem_rdata_i[31:24] : mem_rdata_i[23:16]) : (in_ep_get_addr[0] ? mem_rdata_i[15:8] : mem_rdata_i[7:0]));
	assign set_sent_o = in_ep_acked;
	wire [10:0] frame_index_raw;
	usb_fs_nb_pe #(
		.NumOutEps(NEndpoints),
		.NumInEps(NEndpoints),
		.MaxPktSizeByte(MaxPktSizeByte)
	) u_usb_fs_nb_pe(
		.clk_48mhz_i(clk_48mhz_i),
		.rst_ni(rst_ni),
		.link_reset_i(link_reset),
		.cfg_eop_single_bit_i(cfg_eop_single_bit_i),
		.tx_osc_test_mode_i(tx_osc_test_mode_i),
		.data_toggle_clear_i(data_toggle_clear_i),
		.usb_d_i(usb_d_i),
		.usb_se0_i(usb_se0_i),
		.usb_d_o(usb_d_o),
		.usb_se0_o(usb_se0_o),
		.usb_oe_o(usb_oe_o),
		.dev_addr_i(devaddr_i),
		.out_ep_current_o(out_ep_current),
		.out_ep_newpkt_o(out_ep_newpkt),
		.out_ep_data_put_o(out_ep_data_put),
		.out_ep_put_addr_o(out_ep_put_addr),
		.out_ep_data_o(out_ep_data),
		.out_ep_acked_o(out_ep_acked),
		.out_ep_rollback_o(out_ep_rollback),
		.out_ep_setup_o(out_ep_setup),
		.out_ep_full_i(out_ep_full),
		.out_ep_stall_i(out_ep_stall),
		.out_ep_iso_i(ep_iso_i),
		.in_ep_current_o(in_ep_current),
		.in_ep_rollback_o(link_in_err_o),
		.in_ep_acked_o(in_ep_acked),
		.in_ep_get_addr_o(in_ep_get_addr),
		.in_ep_data_get_o(in_ep_data_get),
		.in_ep_newpkt_o(in_ep_newpkt),
		.in_ep_stall_i(in_stall_i),
		.in_ep_has_data_i(in_rdy_i),
		.in_ep_data_i(in_ep_data),
		.in_ep_data_done_i(in_ep_data_done),
		.in_ep_iso_i(ep_iso_i),
		.rx_crc_err_o(rx_crc_err_o),
		.rx_pid_err_o(rx_pid_err_o),
		.rx_bitstuff_err_o(rx_bitstuff_err_o),
		.sof_valid_o(sof_valid),
		.frame_index_o(frame_index_raw)
	);
	reg [5:0] ns_cnt;
	wire us_tick;
	assign us_tick = ns_cnt == 6'd48;
	always @(posedge clk_48mhz_i or negedge rst_ni)
		if (!rst_ni)
			ns_cnt <= 1'sb0;
		else if (us_tick)
			ns_cnt <= 1'sb0;
		else
			ns_cnt <= ns_cnt + 1'b1;
	always @(posedge clk_48mhz_i or negedge rst_ni)
		if (!rst_ni)
			frame_o <= 1'sb0;
		else if (sof_valid)
			frame_o <= frame_index_raw;
	usbdev_linkstate u_usbdev_linkstate(
		.clk_48mhz_i(clk_48mhz_i),
		.rst_ni(rst_ni),
		.us_tick_i(us_tick),
		.usb_sense_i(usb_sense_i),
		.usb_rx_d_i(usb_d_i),
		.usb_rx_se0_i(usb_se0_i),
		.sof_valid_i(sof_valid),
		.link_disconnect_o(link_disconnect_o),
		.link_connect_o(link_connect_o),
		.link_reset_o(link_reset),
		.link_suspend_o(link_suspend_o),
		.link_resume_o(link_resume_o),
		.link_state_o(link_state_o),
		.host_lost_o(host_lost_o)
	);
endmodule
