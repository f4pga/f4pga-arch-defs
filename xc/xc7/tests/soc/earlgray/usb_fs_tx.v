module usb_fs_tx (
	clk_i,
	rst_ni,
	link_reset_i,
	tx_osc_test_mode_i,
	bit_strobe_i,
	usb_oe_o,
	usb_d_o,
	usb_se0_o,
	pkt_start_i,
	pkt_end_o,
	pid_i,
	tx_data_avail_i,
	tx_data_get_o,
	tx_data_i
);
	localparam [1:0] OsIdle = 0;
	localparam [2:0] Idle = 0;
	localparam [1:0] OsWaitByte = 1;
	localparam [2:0] Sync = 1;
	localparam [1:0] OsTransmit = 2;
	localparam [2:0] Pid = 2;
	localparam [2:0] DataOrCrc160 = 3;
	localparam [2:0] Crc161 = 4;
	localparam [2:0] Eop = 5;
	localparam [2:0] OscTest = 6;
	input wire clk_i;
	input wire rst_ni;
	input wire link_reset_i;
	input wire tx_osc_test_mode_i;
	input wire bit_strobe_i;
	output wire usb_oe_o;
	output wire usb_d_o;
	output wire usb_se0_o;
	input wire pkt_start_i;
	output wire pkt_end_o;
	input wire [3:0] pid_i;
	input wire tx_data_avail_i;
	output wire tx_data_get_o;
	input wire [7:0] tx_data_i;
	reg [3:0] pid_q;
	wire [3:0] pid_d;
	wire bitstuff;
	reg bitstuff_q;
	reg bitstuff_q2;
	reg bitstuff_q3;
	reg bitstuff_q4;
	wire [5:0] bit_history;
	reg [2:0] state_d;
	reg [2:0] state_q;
	reg [1:0] out_state_d;
	reg [1:0] out_state_q;
	reg [7:0] data_shift_reg_q;
	reg [7:0] data_shift_reg_d;
	reg [7:0] oe_shift_reg_q;
	reg [7:0] oe_shift_reg_d;
	reg [7:0] se0_shift_reg_q;
	reg [7:0] se0_shift_reg_d;
	reg data_payload_q;
	reg data_payload_d;
	reg tx_data_get_q;
	reg tx_data_get_d;
	reg byte_strobe_q;
	reg byte_strobe_d;
	reg [4:0] bit_history_d;
	reg [4:0] bit_history_q;
	reg [2:0] bit_count_d;
	reg [2:0] bit_count_q;
	reg [15:0] crc16_d;
	reg [15:0] crc16_q;
	reg oe_q;
	reg oe_d;
	reg usb_d_q;
	reg usb_d_d;
	reg usb_se0_q;
	reg usb_se0_d;
	reg [2:0] dp_eop_q;
	reg [2:0] dp_eop_d;
	reg test_mode_start;
	wire serial_tx_data;
	wire serial_tx_oe;
	wire serial_tx_se0;
	wire crc16_invert;
	wire pkt_end;
	reg out_nrzi_en;
	always @(posedge clk_i or negedge rst_ni) begin : proc_pid
		if (!rst_ni)
			pid_q <= 0;
		else if (link_reset_i)
			pid_q <= 0;
		else
			pid_q <= pid_d;
	end
	assign pid_d = (pkt_start_i ? pid_i : pid_q);
	assign serial_tx_data = data_shift_reg_q[0];
	assign serial_tx_oe = oe_shift_reg_q[0];
	assign serial_tx_se0 = se0_shift_reg_q[0];
	assign bit_history = {serial_tx_data, bit_history_q};
	assign bitstuff = bit_history == 6'b111111;
	always @(posedge clk_i or negedge rst_ni) begin : proc_bitstuff
		if (!rst_ni) begin
			bitstuff_q <= 0;
			bitstuff_q2 <= 0;
			bitstuff_q3 <= 0;
			bitstuff_q4 <= 0;
		end
		else if (link_reset_i) begin
			bitstuff_q <= 0;
			bitstuff_q2 <= 0;
			bitstuff_q3 <= 0;
			bitstuff_q4 <= 0;
		end
		else begin
			bitstuff_q <= bitstuff;
			bitstuff_q2 <= bitstuff_q;
			bitstuff_q3 <= bitstuff_q2;
			bitstuff_q4 <= bitstuff_q3;
		end
	end
	assign pkt_end = bit_strobe_i && (se0_shift_reg_q[1:0] == 2'b01);
	assign pkt_end_o = pkt_end;
	always @(*) begin : proc_fsm
		state_d = state_q;
		data_shift_reg_d = data_shift_reg_q;
		oe_shift_reg_d = oe_shift_reg_q;
		se0_shift_reg_d = se0_shift_reg_q;
		data_payload_d = data_payload_q;
		tx_data_get_d = tx_data_get_q;
		bit_history_d = bit_history_q;
		bit_count_d = bit_count_q;
		test_mode_start = 0;
		case (state_q)
			Idle:
				if (tx_osc_test_mode_i) begin
					state_d = OscTest;
					test_mode_start = 1;
				end
				else if (pkt_start_i)
					state_d = Sync;
			Sync:
				if (byte_strobe_q) begin
					state_d = Pid;
					data_shift_reg_d = 8'b10000000;
					oe_shift_reg_d = 8'b11111111;
					se0_shift_reg_d = 8'b00000000;
				end
			Pid:
				if (byte_strobe_q) begin
					if (pid_q[1:0] == 2'b11)
						state_d = DataOrCrc160;
					else
						state_d = Eop;
					data_shift_reg_d = {~pid_q, pid_q};
					oe_shift_reg_d = 8'b11111111;
					se0_shift_reg_d = 8'b00000000;
				end
			DataOrCrc160:
				if (byte_strobe_q) begin
					if (tx_data_avail_i) begin
						state_d = DataOrCrc160;
						data_payload_d = 1;
						tx_data_get_d = 1;
						data_shift_reg_d = tx_data_i;
						oe_shift_reg_d = 8'b11111111;
						se0_shift_reg_d = 8'b00000000;
					end
					else begin
						state_d = Crc161;
						data_payload_d = 0;
						tx_data_get_d = 0;
						data_shift_reg_d = ~{crc16_q[8], crc16_q[9], crc16_q[10], crc16_q[11], crc16_q[12], crc16_q[13], crc16_q[14], crc16_q[15]};
						oe_shift_reg_d = 8'b11111111;
						se0_shift_reg_d = 8'b00000000;
					end
				end
				else
					tx_data_get_d = 0;
			Crc161:
				if (byte_strobe_q) begin
					state_d = Eop;
					data_shift_reg_d = ~{crc16_q[0], crc16_q[1], crc16_q[2], crc16_q[3], crc16_q[4], crc16_q[5], crc16_q[6], crc16_q[7]};
					oe_shift_reg_d = 8'b11111111;
					se0_shift_reg_d = 8'b00000000;
				end
			Eop:
				if (byte_strobe_q) begin
					state_d = Idle;
					oe_shift_reg_d = 8'b00000111;
					se0_shift_reg_d = 8'b00000111;
				end
			OscTest:
				if (!tx_osc_test_mode_i && byte_strobe_q) begin
					oe_shift_reg_d = 8'b00000000;
					state_d = Idle;
				end
				else if (byte_strobe_q) begin
					data_shift_reg_d = 8'b00000000;
					oe_shift_reg_d = 8'b11111111;
					se0_shift_reg_d = 8'b00000000;
				end
			default: state_d = Idle;
		endcase
		if (pkt_start_i) begin
			bit_count_d = 7;
			bit_history_d = 0;
		end
		else if (bit_strobe_i)
			if (bitstuff) begin
				bit_history_d = bit_history[5:1];
				data_shift_reg_d[0] = 0;
			end
			else begin
				bit_count_d = bit_count_q + 1;
				data_shift_reg_d = data_shift_reg_q >> 1;
				oe_shift_reg_d = oe_shift_reg_q >> 1;
				se0_shift_reg_d = se0_shift_reg_q >> 1;
				bit_history_d = bit_history[5:1];
			end
	end
	always @(*) begin : proc_byte_str
		if ((bit_strobe_i && !bitstuff) && !pkt_start_i)
			byte_strobe_d = bit_count_q == 3'b000;
		else
			byte_strobe_d = 0;
	end
	assign tx_data_get_o = tx_data_get_q;
	assign crc16_invert = serial_tx_data ^ crc16_q[15];
	always @(*) begin : proc_crc16
		crc16_d = crc16_q;
		if (pkt_start_i)
			crc16_d = 16'b1111111111111111;
		if (((bit_strobe_i && data_payload_q) && !bitstuff_q4) && !pkt_start_i)
			crc16_d = {crc16_q[14:0], 1'b0} ^ ({16 {crc16_invert}} & 16'b1000000000000101);
	end
	always @(posedge clk_i or negedge rst_ni) begin : proc_reg
		if (!rst_ni) begin
			state_q <= Idle;
			data_payload_q <= 0;
			data_shift_reg_q <= 0;
			oe_shift_reg_q <= 0;
			se0_shift_reg_q <= 0;
			tx_data_get_q <= 0;
			byte_strobe_q <= 0;
			bit_history_q <= 0;
			bit_count_q <= 0;
			crc16_q <= 0;
		end
		else if (link_reset_i) begin
			state_q <= Idle;
			data_payload_q <= 0;
			data_shift_reg_q <= 0;
			oe_shift_reg_q <= 0;
			se0_shift_reg_q <= 0;
			tx_data_get_q <= 0;
			byte_strobe_q <= 0;
			bit_history_q <= 0;
			bit_count_q <= 0;
			crc16_q <= 0;
		end
		else begin
			state_q <= state_d;
			data_payload_q <= data_payload_d;
			data_shift_reg_q <= data_shift_reg_d;
			oe_shift_reg_q <= oe_shift_reg_d;
			se0_shift_reg_q <= se0_shift_reg_d;
			tx_data_get_q <= tx_data_get_d;
			byte_strobe_q <= byte_strobe_d;
			bit_history_q <= bit_history_d;
			bit_count_q <= bit_count_d;
			crc16_q <= crc16_d;
		end
	end
	always @(*) begin : proc_out_fsm
		out_state_d = out_state_q;
		out_nrzi_en = 1'b0;
		case (out_state_q)
			OsIdle:
				if (pkt_start_i || test_mode_start)
					out_state_d = OsWaitByte;
			OsWaitByte:
				if (byte_strobe_q)
					out_state_d = OsTransmit;
			OsTransmit: begin
				out_nrzi_en = 1'b1;
				if (bit_strobe_i && !serial_tx_oe)
					out_state_d = OsIdle;
			end
			default: out_state_d = OsIdle;
		endcase
	end
	always @(*) begin : proc_diff
		usb_d_d = usb_d_q;
		usb_se0_d = usb_se0_q;
		oe_d = oe_q;
		dp_eop_d = dp_eop_q;
		if (pkt_start_i) begin
			usb_d_d = 1;
			dp_eop_d = 3'b100;
		end
		else if (bit_strobe_i && out_nrzi_en) begin
			oe_d = serial_tx_oe;
			if (serial_tx_se0) begin
				dp_eop_d = dp_eop_q >> 1;
				if (dp_eop_q[0]) begin
					usb_d_d = 1;
					usb_se0_d = 0;
				end
				else
					usb_se0_d = 1;
			end
			else if (serial_tx_data)
				;
			else
				usb_d_d = !usb_d_q;
			if (!oe_d)
				usb_d_d = 1;
		end
	end
	always @(posedge clk_i or negedge rst_ni) begin : proc_diff_reg
		if (!rst_ni) begin
			dp_eop_q <= 0;
			oe_q <= 0;
			usb_d_q <= 1;
			usb_se0_q <= 0;
			out_state_q <= OsIdle;
		end
		else if (link_reset_i) begin
			dp_eop_q <= 0;
			oe_q <= 0;
			usb_d_q <= 1;
			usb_se0_q <= 0;
			out_state_q <= OsIdle;
		end
		else begin
			dp_eop_q <= dp_eop_d;
			oe_q <= oe_d;
			usb_d_q <= usb_d_d;
			usb_se0_q <= usb_se0_d;
			out_state_q <= out_state_d;
		end
	end
	assign usb_oe_o = oe_q;
	assign usb_d_o = usb_d_q;
	assign usb_se0_o = usb_se0_q;
endmodule
