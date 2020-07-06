module usb_fs_nb_in_pe (
	clk_48mhz_i,
	rst_ni,
	link_reset_i,
	dev_addr_i,
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
	data_toggle_clear_i,
	rx_pkt_start_i,
	rx_pkt_end_i,
	rx_pkt_valid_i,
	rx_pid_i,
	rx_addr_i,
	rx_endp_i,
	tx_pkt_start_o,
	tx_pkt_end_i,
	tx_pid_o,
	tx_data_avail_o,
	tx_data_get_i,
	tx_data_o
);
	localparam [1:0] StIdle = 0;
	localparam [1:0] StRcvdIn = 1;
	localparam [1:0] StSendData = 2;
	localparam [1:0] StWaitAck = 3;
	parameter [4:0] NumInEps = 12;
	parameter [31:0] MaxInPktSizeByte = 32;
	localparam [31:0] InEpW = $clog2(NumInEps);
	localparam [31:0] PktW = $clog2(MaxInPktSizeByte);
	input wire clk_48mhz_i;
	input wire rst_ni;
	input wire link_reset_i;
	input wire [6:0] dev_addr_i;
	output reg [3:0] in_ep_current_o;
	output reg in_ep_rollback_o;
	output wire in_ep_acked_o;
	output reg [PktW - 1:0] in_ep_get_addr_o;
	output reg in_ep_data_get_o;
	output reg in_ep_newpkt_o;
	input wire [NumInEps - 1:0] in_ep_stall_i;
	input wire [NumInEps - 1:0] in_ep_has_data_i;
	input wire [7:0] in_ep_data_i;
	input wire [NumInEps - 1:0] in_ep_data_done_i;
	input wire [NumInEps - 1:0] in_ep_iso_i;
	input wire [NumInEps - 1:0] data_toggle_clear_i;
	input wire rx_pkt_start_i;
	input wire rx_pkt_end_i;
	input wire rx_pkt_valid_i;
	input wire [3:0] rx_pid_i;
	input wire [6:0] rx_addr_i;
	input wire [3:0] rx_endp_i;
	output reg tx_pkt_start_o;
	input wire tx_pkt_end_i;
	output reg [3:0] tx_pid_o;
	output wire tx_data_avail_o;
	input wire tx_data_get_i;
	output reg [7:0] tx_data_o;
	wire unused_1;
	wire unused_2;
	assign unused_1 = tx_pkt_end_i;
	assign unused_2 = rx_pkt_start_i;
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
	reg [1:0] in_xfr_state;
	reg [1:0] in_xfr_state_next;
	reg in_xfr_end;
	assign in_ep_acked_o = in_xfr_end;
	reg [NumInEps - 1:0] data_toggle_q;
	reg [NumInEps - 1:0] data_toggle_d;
	wire token_received;
	wire setup_token_received;
	wire in_token_received;
	wire ack_received;
	wire more_data_to_send;
	wire ep_impl;
	wire [3:0] in_ep_current_d;
	wire [1:0] rx_pid_type;
	wire [3:0] rx_pid;
	assign rx_pid_type = sv2v_cast_2(rx_pid_i[1:0]);
	assign rx_pid = sv2v_cast_4(rx_pid_i);
	assign ep_impl = {1'b0, rx_endp_i} < NumInEps;
	assign token_received = (((rx_pkt_end_i && rx_pkt_valid_i) && (rx_pid_type == UsbPidTypeToken)) && (rx_addr_i == dev_addr_i)) && ep_impl;
	assign setup_token_received = token_received && (rx_pid == UsbPidSetup);
	assign in_token_received = token_received && (rx_pid == UsbPidIn);
	assign ack_received = (rx_pkt_end_i && rx_pkt_valid_i) && (rx_pid == UsbPidAck);
	assign in_ep_current_d = (ep_impl ? rx_endp_i : 1'sb0);
	wire [InEpW - 1:0] in_ep_index;
	wire [InEpW - 1:0] in_ep_index_d;
	assign in_ep_index = in_ep_current_o[0+:InEpW];
	assign in_ep_index_d = in_ep_current_d[0+:InEpW];
	assign more_data_to_send = in_ep_has_data_i[in_ep_index] & ~in_ep_data_done_i[in_ep_index];
	assign tx_data_avail_o = sv2v_cast_1(in_xfr_state == StSendData) & more_data_to_send;
	reg rollback_in_xfr;
	always @(*) begin
		in_xfr_state_next = in_xfr_state;
		in_xfr_end = 1'b0;
		tx_pkt_start_o = 1'b0;
		tx_pid_o = 4'b0000;
		rollback_in_xfr = 1'b0;
		case (in_xfr_state)
			StIdle:
				if (in_token_received)
					in_xfr_state_next = StRcvdIn;
				else
					in_xfr_state_next = StIdle;
			StRcvdIn: begin
				tx_pkt_start_o = 1'b1;
				if (in_ep_stall_i[in_ep_index]) begin
					in_xfr_state_next = StIdle;
					tx_pid_o = UsbPidStall;
				end
				else if (in_ep_iso_i[in_ep_index]) begin
					in_xfr_state_next = StSendData;
					tx_pid_o = {data_toggle_q[in_ep_index], 1'b0, UsbPidTypeData};
				end
				else if (in_ep_has_data_i[in_ep_index]) begin
					in_xfr_state_next = StSendData;
					tx_pid_o = {data_toggle_q[in_ep_index], 1'b0, UsbPidTypeData};
				end
				else begin
					in_xfr_state_next = StIdle;
					tx_pid_o = UsbPidNak;
				end
			end
			StSendData:
				if (!more_data_to_send || (&in_ep_get_addr_o && tx_data_get_i)) begin
					if (in_ep_iso_i[in_ep_index])
						in_xfr_state_next = StIdle;
					else
						in_xfr_state_next = StWaitAck;
				end
				else
					in_xfr_state_next = StSendData;
			StWaitAck:
				if (ack_received) begin
					in_xfr_state_next = StIdle;
					in_xfr_end = 1'b1;
				end
				else if (in_token_received) begin
					in_xfr_state_next = StRcvdIn;
					rollback_in_xfr = 1'b1;
				end
				else if (rx_pkt_end_i) begin
					in_xfr_state_next = StIdle;
					rollback_in_xfr = 1'b1;
				end
				else
					in_xfr_state_next = StWaitAck;
			default: in_xfr_state_next = StIdle;
		endcase
	end
	always @(posedge clk_48mhz_i or negedge rst_ni)
		if (!rst_ni)
			tx_data_o <= 1'sb0;
		else
			tx_data_o <= in_ep_data_i;
	always @(posedge clk_48mhz_i or negedge rst_ni)
		if (!rst_ni) begin
			in_xfr_state <= StIdle;
			in_ep_rollback_o <= 1'b0;
		end
		else if (link_reset_i) begin
			in_xfr_state <= StIdle;
			in_ep_rollback_o <= 1'b0;
		end
		else begin
			in_xfr_state <= in_xfr_state_next;
			in_ep_rollback_o <= rollback_in_xfr;
		end
	always @(posedge clk_48mhz_i or negedge rst_ni)
		if (!rst_ni)
			in_ep_get_addr_o <= 1'sb0;
		else if (in_xfr_state == StIdle)
			in_ep_get_addr_o <= 1'sb0;
		else if ((in_xfr_state == StSendData) && tx_data_get_i)
			in_ep_get_addr_o <= in_ep_get_addr_o + 1'b1;
	always @(posedge clk_48mhz_i or negedge rst_ni)
		if (!rst_ni) begin
			in_ep_newpkt_o <= 1'b0;
			in_ep_current_o <= 1'sb0;
		end
		else if (in_token_received) begin
			in_ep_current_o <= in_ep_current_d;
			in_ep_newpkt_o <= 1'b1;
		end
		else
			in_ep_newpkt_o <= 1'b0;
	always @(*) begin : proc_data_toggle_d
		data_toggle_d = data_toggle_q;
		if (setup_token_received)
			data_toggle_d[in_ep_index_d] = 1'b1;
		else if ((in_xfr_state == StWaitAck) && ack_received)
			data_toggle_d[in_ep_index] = ~data_toggle_q[in_ep_index];
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
		if (!rst_ni)
			in_ep_data_get_o <= 1'b0;
		else if ((in_xfr_state == StSendData) && tx_data_get_i)
			in_ep_data_get_o <= 1'b1;
		else
			in_ep_data_get_o <= 1'b0;
	function automatic [0:0] sv2v_cast_1;
		input reg [0:0] inp;
		sv2v_cast_1 = inp;
	endfunction
	function automatic [1:0] sv2v_cast_2;
		input reg [1:0] inp;
		sv2v_cast_2 = inp;
	endfunction
	function automatic [3:0] sv2v_cast_4;
		input reg [3:0] inp;
		sv2v_cast_4 = inp;
	endfunction
endmodule
