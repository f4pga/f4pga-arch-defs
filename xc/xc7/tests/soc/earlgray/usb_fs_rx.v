module usb_fs_rx (
	clk_i,
	rst_ni,
	link_reset_i,
	cfg_eop_single_bit_i,
	usb_d_i,
	usb_se0_i,
	tx_en_i,
	bit_strobe_o,
	pkt_start_o,
	pkt_end_o,
	pid_o,
	addr_o,
	endp_o,
	frame_num_o,
	rx_data_put_o,
	rx_data_o,
	valid_packet_o,
	crc_error_o,
	pid_error_o,
	bitstuff_error_o
);
	input wire clk_i;
	input wire rst_ni;
	input wire link_reset_i;
	input wire cfg_eop_single_bit_i;
	input wire usb_d_i;
	input wire usb_se0_i;
	input wire tx_en_i;
	output wire bit_strobe_o;
	output wire pkt_start_o;
	output wire pkt_end_o;
	output wire [3:0] pid_o;
	output wire [6:0] addr_o;
	output wire [3:0] endp_o;
	output wire [10:0] frame_num_o;
	output wire rx_data_put_o;
	output wire [7:0] rx_data_o;
	output wire valid_packet_o;
	output wire crc_error_o;
	output wire pid_error_o;
	output wire bitstuff_error_o;
	reg [6:0] bitstuff_history_q;
	reg [6:0] bitstuff_history_d;
	wire bitstuff_error;
	reg bitstuff_error_q;
	reg bitstuff_error_d;
	reg [2:0] line_state_q;
	reg [2:0] line_state_d;
	localparam [2:0] DT = 3'b100;
	localparam [2:0] DJ = 3'b010;
	localparam [2:0] SE0 = 3'b000;
	reg [1:0] dpair;
	always @(*) begin : proc_dpair_mute
		if (tx_en_i)
			dpair = DJ[1:0];
		else
			dpair = (usb_se0_i ? 2'b00 : {usb_d_i, ~usb_d_i});
	end
	always @(posedge clk_i or negedge rst_ni) begin : proc_line_state_q
		if (!rst_ni)
			line_state_q <= SE0;
		else if (link_reset_i)
			line_state_q <= SE0;
		else
			line_state_q <= line_state_d;
	end
	always @(*) begin : proc_line_state_d
		line_state_d = line_state_q;
		if (line_state_q == DT)
			line_state_d = {1'b0, dpair};
		else if (dpair != line_state_q[1:0])
			line_state_d = DT;
	end
	reg [1:0] bit_phase_q;
	wire [1:0] bit_phase_d;
	wire line_state_valid;
	assign line_state_valid = bit_phase_q == 2'd1;
	assign bit_strobe_o = bit_phase_q == 2'd2;
	assign bit_phase_d = (line_state_q == DT ? 0 : bit_phase_q + 1);
	always @(posedge clk_i or negedge rst_ni) begin : proc_bit_phase_q
		if (!rst_ni)
			bit_phase_q <= 0;
		else if (link_reset_i)
			bit_phase_q <= 0;
		else
			bit_phase_q <= bit_phase_d;
	end
	reg [11:0] line_history_q;
	wire [11:0] line_history_d;
	reg packet_valid_q;
	reg packet_valid_d;
	wire see_eop;
	wire packet_start;
	wire packet_end;
	assign packet_start = packet_valid_d & ~packet_valid_q;
	assign packet_end = ~packet_valid_d & packet_valid_q;
	assign see_eop = ((cfg_eop_single_bit_i && (line_history_q[1:0] == 2'b00)) || (line_history_q[3:0] == 4'b0000)) || bitstuff_error_q;
	always @(*) begin : proc_packet_valid_d
		if (line_state_valid) begin
			if (!packet_valid_q && (line_history_q[11:0] == 12'b011001100101))
				packet_valid_d = 1;
			else if (packet_valid_q && see_eop)
				packet_valid_d = 0;
			else
				packet_valid_d = packet_valid_q;
		end
		else
			packet_valid_d = packet_valid_q;
	end
	assign line_history_d = (line_state_valid ? {line_history_q[9:0], line_state_q[1:0]} : line_history_q);
	always @(posedge clk_i or negedge rst_ni) begin : proc_reg_pkt_line
		if (!rst_ni) begin
			packet_valid_q <= 0;
			line_history_q <= 12'b101010101010;
		end
		else if (link_reset_i) begin
			packet_valid_q <= 0;
			line_history_q <= 12'b101010101010;
		end
		else begin
			packet_valid_q <= packet_valid_d;
			line_history_q <= line_history_d;
		end
	end
	reg dvalid_raw;
	reg din;
	always @(*) begin
		case (line_history_q[3:0])
			4'b0101: din = 1;
			4'b0110: din = 0;
			4'b1001: din = 0;
			4'b1010: din = 1;
			default: din = 0;
		endcase
		if (packet_valid_q && line_state_valid)
			case (line_history_q[3:0])
				4'b0101: dvalid_raw = 1;
				4'b0110: dvalid_raw = 1;
				4'b1001: dvalid_raw = 1;
				4'b1010: dvalid_raw = 1;
				default: dvalid_raw = 0;
			endcase
		else
			dvalid_raw = 0;
	end
	always @(*) begin : proc_bitstuff_history_d
		if (packet_end)
			bitstuff_history_d = 1'sb0;
		else if (dvalid_raw)
			bitstuff_history_d = {bitstuff_history_q[5:0], din};
		else
			bitstuff_history_d = bitstuff_history_q;
	end
	always @(posedge clk_i or negedge rst_ni) begin : proc_bitstuff_history_q
		if (!rst_ni)
			bitstuff_history_q <= 0;
		else if (link_reset_i)
			bitstuff_history_q <= 0;
		else
			bitstuff_history_q <= bitstuff_history_d;
	end
	wire dvalid;
	assign dvalid = dvalid_raw && !(bitstuff_history_q[5:0] == 6'b111111);
	assign bitstuff_error = bitstuff_history_q == 7'b1111111;
	always @(*) begin : proc_bistuff_error_d
		bitstuff_error_d = bitstuff_error_q;
		if (packet_start)
			bitstuff_error_d = 0;
		else if (bitstuff_error && dvalid_raw)
			bitstuff_error_d = 1;
	end
	always @(posedge clk_i or negedge rst_ni) begin : proc_bitstuff_error_q
		if (!rst_ni)
			bitstuff_error_q <= 0;
		else
			bitstuff_error_q <= bitstuff_error_d;
	end
	assign bitstuff_error_o = bitstuff_error_q && packet_end;
	reg [8:0] full_pid_q;
	reg [8:0] full_pid_d;
	wire pid_valid;
	wire pid_complete;
	assign pid_valid = full_pid_q[4:1] == ~full_pid_q[8:5];
	assign pid_complete = full_pid_q[0];
	always @(*) begin : proc_full_pid_d
		if (dvalid && !pid_complete)
			full_pid_d = {din, full_pid_q[8:1]};
		else if (packet_start)
			full_pid_d = 9'b100000000;
		else
			full_pid_d = full_pid_q;
	end
	reg [4:0] crc5_q;
	reg [4:0] crc5_d;
	wire crc5_valid;
	wire crc5_invert;
	assign crc5_valid = crc5_q == 5'b01100;
	assign crc5_invert = din ^ crc5_q[4];
	always @(*) begin
		crc5_d = crc5_q;
		if (packet_start)
			crc5_d = 5'b11111;
		if (dvalid && pid_complete)
			crc5_d = {crc5_q[3:0], 1'b0} ^ ({5 {crc5_invert}} & 5'b00101);
	end
	reg [15:0] crc16_q;
	reg [15:0] crc16_d;
	wire crc16_valid;
	wire crc16_invert;
	assign crc16_valid = crc16_q == 16'b1000000000001101;
	assign crc16_invert = din ^ crc16_q[15];
	always @(*) begin
		crc16_d = crc16_q;
		if (packet_start)
			crc16_d = 16'b1111111111111111;
		if (dvalid && pid_complete)
			crc16_d = {crc16_q[14:0], 1'b0} ^ ({16 {crc16_invert}} & 16'b1000000000000101);
	end
	wire pkt_is_token;
	wire pkt_is_data;
	wire pkt_is_handshake;
	assign pkt_is_token = full_pid_q[2:1] == 2'b01;
	assign pkt_is_data = full_pid_q[2:1] == 2'b11;
	assign pkt_is_handshake = full_pid_q[2:1] == 2'b10;
	assign valid_packet_o = (pid_valid && !bitstuff_error_q) && ((pkt_is_handshake || (pkt_is_data && crc16_valid)) || (pkt_is_token && crc5_valid));
	assign crc_error_o = ((pkt_is_data && !crc16_valid) || (pkt_is_token && !crc5_valid)) && packet_end;
	assign pid_error_o = !pid_valid && packet_end;
	reg [11:0] token_payload_q;
	reg [11:0] token_payload_d;
	wire token_payload_done;
	assign token_payload_done = token_payload_q[0];
	reg [6:0] addr_q;
	reg [6:0] addr_d;
	reg [3:0] endp_q;
	reg [3:0] endp_d;
	reg [10:0] frame_num_q;
	reg [10:0] frame_num_d;
	always @(*) begin
		token_payload_d = token_payload_q;
		if (packet_start)
			token_payload_d = 12'b100000000000;
		if (((dvalid && pid_complete) && pkt_is_token) && !token_payload_done)
			token_payload_d = {din, token_payload_q[11:1]};
	end
	always @(*) begin
		addr_d = addr_q;
		endp_d = endp_q;
		frame_num_d = frame_num_q;
		if (token_payload_done && pkt_is_token) begin
			addr_d = token_payload_q[7:1];
			endp_d = token_payload_q[11:8];
			frame_num_d = token_payload_q[11:1];
		end
	end
	assign addr_o = addr_q;
	assign endp_o = endp_q;
	assign frame_num_o = frame_num_q;
	assign pid_o = full_pid_q[4:1];
	assign pkt_start_o = packet_start;
	assign pkt_end_o = packet_end;
	reg [8:0] rx_data_buffer_q;
	reg [8:0] rx_data_buffer_d;
	wire rx_data_buffer_full;
	assign rx_data_buffer_full = rx_data_buffer_q[0];
	assign rx_data_put_o = rx_data_buffer_full;
	assign rx_data_o = rx_data_buffer_q[8:1];
	always @(*) begin
		rx_data_buffer_d = rx_data_buffer_q;
		if (packet_start || rx_data_buffer_full)
			rx_data_buffer_d = 9'b100000000;
		if ((dvalid && pid_complete) && pkt_is_data)
			rx_data_buffer_d = {din, rx_data_buffer_q[8:1]};
	end
	always @(posedge clk_i or negedge rst_ni) begin : proc_gp_regs
		if (!rst_ni) begin
			full_pid_q <= 0;
			crc16_q <= 0;
			crc5_q <= 0;
			token_payload_q <= 0;
			addr_q <= 0;
			endp_q <= 0;
			frame_num_q <= 0;
			rx_data_buffer_q <= 0;
		end
		else if (link_reset_i) begin
			full_pid_q <= 0;
			crc16_q <= 0;
			crc5_q <= 0;
			token_payload_q <= 0;
			addr_q <= 0;
			endp_q <= 0;
			frame_num_q <= 0;
			rx_data_buffer_q <= 0;
		end
		else begin
			full_pid_q <= full_pid_d;
			crc16_q <= crc16_d;
			crc5_q <= crc5_d;
			token_payload_q <= token_payload_d;
			addr_q <= addr_d;
			endp_q <= endp_d;
			frame_num_q <= frame_num_d;
			rx_data_buffer_q <= rx_data_buffer_d;
		end
	end
endmodule
