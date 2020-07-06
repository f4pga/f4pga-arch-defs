module usb_fs_nb_out_pe (
	clk_48mhz_i,
	rst_ni,
	link_reset_i,
	dev_addr_i,
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
	data_toggle_clear_i,
	rx_pkt_start_i,
	rx_pkt_end_i,
	rx_pkt_valid_i,
	rx_pid_i,
	rx_addr_i,
	rx_endp_i,
	rx_data_put_i,
	rx_data_i,
	tx_pkt_start_o,
	tx_pkt_end_i,
	tx_pid_o
);
	localparam [2:0] StIdle = 0;
	localparam [2:0] StRcvdOut = 1;
	localparam [2:0] StRcvdDataStart = 2;
	localparam [2:0] StRcvdDataEnd = 3;
	localparam [2:0] StRcvdIsoDataEnd = 4;
	parameter [4:0] NumOutEps = 1;
	parameter [31:0] MaxOutPktSizeByte = 32;
	localparam [31:0] OutEpW = $clog2(NumOutEps);
	localparam [31:0] PktW = $clog2(MaxOutPktSizeByte);
	input wire clk_48mhz_i;
	input wire rst_ni;
	input wire link_reset_i;
	input wire [6:0] dev_addr_i;
	output reg [3:0] out_ep_current_o;
	output reg out_ep_data_put_o;
	output reg [PktW - 1:0] out_ep_put_addr_o;
	output reg [7:0] out_ep_data_o;
	output reg out_ep_newpkt_o;
	output reg out_ep_acked_o;
	output wire out_ep_rollback_o;
	output reg [NumOutEps - 1:0] out_ep_setup_o;
	input wire [NumOutEps - 1:0] out_ep_full_i;
	input wire [NumOutEps - 1:0] out_ep_stall_i;
	input wire [NumOutEps - 1:0] out_ep_iso_i;
	input wire [NumOutEps - 1:0] data_toggle_clear_i;
	input wire rx_pkt_start_i;
	input wire rx_pkt_end_i;
	input wire rx_pkt_valid_i;
	input wire [3:0] rx_pid_i;
	input wire [6:0] rx_addr_i;
	input wire [3:0] rx_endp_i;
	input wire rx_data_put_i;
	input wire [7:0] rx_data_i;
	output reg tx_pkt_start_o;
	input wire tx_pkt_end_i;
	output reg [3:0] tx_pid_o;
	wire unused_1;
	assign unused_1 = tx_pkt_end_i;
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
	reg [2:0] out_xfr_state;
	reg [2:0] out_xfr_state_next;
	reg out_xfr_start;
	reg new_pkt_end;
	reg rollback_data;
	reg nak_out_transfer;
	reg [NumOutEps - 1:0] data_toggle_q;
	reg [NumOutEps - 1:0] data_toggle_d;
	wire token_received;
	wire out_token_received;
	wire setup_token_received;
	wire invalid_packet_received;
	wire data_packet_received;
	wire non_data_packet_received;
	wire bad_data_toggle;
	wire ep_impl;
	wire [3:0] out_ep_current_d;
	reg current_xfer_setup_q;
	wire [1:0] rx_pid_type;
	wire [3:0] rx_pid;
	assign rx_pid_type = sv2v_cast_2(rx_pid_i[1:0]);
	assign rx_pid = sv2v_cast_4(rx_pid_i);
	assign ep_impl = {1'b0, rx_endp_i} < NumOutEps;
	assign token_received = (((rx_pkt_end_i && rx_pkt_valid_i) && (rx_pid_type == UsbPidTypeToken)) && (rx_addr_i == dev_addr_i)) && ep_impl;
	assign out_token_received = token_received && (rx_pid == UsbPidOut);
	assign setup_token_received = token_received && (rx_pid == UsbPidSetup);
	assign invalid_packet_received = rx_pkt_end_i && !rx_pkt_valid_i;
	assign data_packet_received = (rx_pkt_end_i && rx_pkt_valid_i) && ((rx_pid == UsbPidData0) || (rx_pid == UsbPidData1));
	assign non_data_packet_received = (rx_pkt_end_i && rx_pkt_valid_i) && !((rx_pid == UsbPidData0) || (rx_pid == UsbPidData1));
	assign out_ep_current_d = (ep_impl ? rx_endp_i : 1'sb0);
	wire [OutEpW - 1:0] out_ep_index;
	wire [OutEpW - 1:0] out_ep_index_d;
	assign out_ep_index = out_ep_current_o[0+:OutEpW];
	assign out_ep_index_d = out_ep_current_d[0+:OutEpW];
	assign bad_data_toggle = data_packet_received && (rx_pid_i[3] != data_toggle_q[out_ep_index_d]);
	always @(posedge clk_48mhz_i or negedge rst_ni)
		if (!rst_ni)
			out_ep_setup_o <= 1'sb0;
		else if (setup_token_received)
			out_ep_setup_o[out_ep_index_d] <= 1'b1;
		else if (out_token_received)
			out_ep_setup_o[out_ep_index_d] <= 1'b0;
	always @(posedge clk_48mhz_i or negedge rst_ni)
		if (!rst_ni)
			out_ep_data_o <= 0;
		else if (rx_data_put_i)
			out_ep_data_o <= rx_data_i;
	always @(*) begin
		out_ep_acked_o = 1'b0;
		out_xfr_start = 1'b0;
		out_xfr_state_next = out_xfr_state;
		tx_pkt_start_o = 1'b0;
		tx_pid_o = 4'b0000;
		new_pkt_end = 1'b0;
		rollback_data = 1'b0;
		case (out_xfr_state)
			StIdle:
				if (out_token_received || setup_token_received) begin
					out_xfr_state_next = StRcvdOut;
					out_xfr_start = 1'b1;
				end
				else
					out_xfr_state_next = StIdle;
			StRcvdOut:
				if (rx_pkt_start_i)
					out_xfr_state_next = StRcvdDataStart;
				else
					out_xfr_state_next = StRcvdOut;
			StRcvdDataStart:
				if (out_ep_iso_i[out_ep_index] && data_packet_received)
					out_xfr_state_next = StRcvdIsoDataEnd;
				else if (bad_data_toggle) begin
					out_xfr_state_next = StIdle;
					rollback_data = 1'b1;
					tx_pkt_start_o = 1'b1;
					tx_pid_o = UsbPidAck;
				end
				else if (invalid_packet_received || non_data_packet_received) begin
					out_xfr_state_next = StIdle;
					rollback_data = 1'b1;
				end
				else if (data_packet_received)
					out_xfr_state_next = StRcvdDataEnd;
				else
					out_xfr_state_next = StRcvdDataStart;
			StRcvdDataEnd: begin
				out_xfr_state_next = StIdle;
				tx_pkt_start_o = 1'b1;
				if (out_ep_stall_i[out_ep_index] && !current_xfer_setup_q)
					tx_pid_o = UsbPidStall;
				else if (nak_out_transfer) begin
					tx_pid_o = UsbPidNak;
					rollback_data = 1'b1;
				end
				else begin
					tx_pid_o = UsbPidAck;
					new_pkt_end = 1'b1;
					out_ep_acked_o = 1'b1;
				end
			end
			StRcvdIsoDataEnd: begin
				out_xfr_state_next = StIdle;
				if (out_ep_stall_i[out_ep_index] && !current_xfer_setup_q) begin
					tx_pkt_start_o = 1'b1;
					tx_pid_o = UsbPidStall;
				end
				else if (nak_out_transfer)
					rollback_data = 1'b1;
				else begin
					new_pkt_end = 1'b1;
					out_ep_acked_o = 1'b1;
				end
			end
			default: out_xfr_state_next = StIdle;
		endcase
	end
	assign out_ep_rollback_o = rollback_data;
	always @(posedge clk_48mhz_i or negedge rst_ni)
		if (!rst_ni)
			out_xfr_state <= StIdle;
		else
			out_xfr_state <= (link_reset_i ? StIdle : out_xfr_state_next);
	always @(*) begin : proc_data_toggle_d
		data_toggle_d = data_toggle_q;
		if (setup_token_received)
			data_toggle_d[out_ep_index_d] = 1'b0;
		else if (new_pkt_end)
			data_toggle_d[out_ep_index] = ~data_toggle_q[out_ep_index];
		data_toggle_d = data_toggle_d & ~data_toggle_clear_i;
	end
	always @(posedge clk_48mhz_i or negedge rst_ni)
		if (!rst_ni)
			data_toggle_q <= 1'sb0;
		else if (link_reset_i)
			data_toggle_q <= 1'sb0;
		else
			data_toggle_q <= data_toggle_d;
	always @(posedge clk_48mhz_i or negedge rst_ni)
		if (!rst_ni) begin
			out_ep_newpkt_o <= 1'b0;
			out_ep_current_o <= 1'sb0;
			current_xfer_setup_q <= 1'b0;
		end
		else if (out_xfr_start) begin
			out_ep_newpkt_o <= 1'b1;
			out_ep_current_o <= out_ep_current_d;
			current_xfer_setup_q <= setup_token_received;
		end
		else
			out_ep_newpkt_o <= 1'b0;
	always @(posedge clk_48mhz_i or negedge rst_ni)
		if (!rst_ni)
			out_ep_data_put_o <= 1'b0;
		else
			out_ep_data_put_o <= (out_xfr_state == StRcvdDataStart) && rx_data_put_i;
	always @(posedge clk_48mhz_i or negedge rst_ni)
		if (!rst_ni)
			nak_out_transfer <= 1'b0;
		else if ((out_xfr_state == StIdle) || (out_xfr_state == StRcvdOut))
			nak_out_transfer <= 1'b0;
		else if (out_ep_data_put_o && out_ep_full_i[out_ep_index])
			nak_out_transfer <= 1'b1;
	wire increment_addr;
	assign increment_addr = (!nak_out_transfer && ~&out_ep_put_addr_o) && out_ep_data_put_o;
	always @(posedge clk_48mhz_i or negedge rst_ni)
		if (!rst_ni)
			out_ep_put_addr_o <= 1'sb0;
		else if (out_xfr_state == StRcvdOut)
			out_ep_put_addr_o <= 1'sb0;
		else if ((out_xfr_state == StRcvdDataStart) && increment_addr)
			out_ep_put_addr_o <= out_ep_put_addr_o + 1;
	function automatic [1:0] sv2v_cast_2;
		input reg [1:0] inp;
		sv2v_cast_2 = inp;
	endfunction
	function automatic [3:0] sv2v_cast_4;
		input reg [3:0] inp;
		sv2v_cast_4 = inp;
	endfunction
endmodule
