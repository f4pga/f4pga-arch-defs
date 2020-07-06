module dm_sba (
	clk_i,
	rst_ni,
	dmactive_i,
	master_req_o,
	master_add_o,
	master_we_o,
	master_wdata_o,
	master_be_o,
	master_gnt_i,
	master_r_valid_i,
	master_r_rdata_i,
	sbaddress_i,
	sbaddress_write_valid_i,
	sbreadonaddr_i,
	sbaddress_o,
	sbautoincrement_i,
	sbaccess_i,
	sbreadondata_i,
	sbdata_i,
	sbdata_read_valid_i,
	sbdata_write_valid_i,
	sbdata_o,
	sbdata_valid_o,
	sbbusy_o,
	sberror_valid_o,
	sberror_o
);
	localparam [2:0] Idle = 0;
	localparam [2:0] Read = 1;
	localparam [2:0] Write = 2;
	localparam [2:0] WaitRead = 3;
	localparam [2:0] WaitWrite = 4;
	parameter [31:0] BusWidth = 32;
	input wire clk_i;
	input wire rst_ni;
	input wire dmactive_i;
	output wire master_req_o;
	output wire [BusWidth - 1:0] master_add_o;
	output wire master_we_o;
	output wire [BusWidth - 1:0] master_wdata_o;
	output wire [(BusWidth / 8) - 1:0] master_be_o;
	input wire master_gnt_i;
	input wire master_r_valid_i;
	input wire [BusWidth - 1:0] master_r_rdata_i;
	input wire [BusWidth - 1:0] sbaddress_i;
	input wire sbaddress_write_valid_i;
	input wire sbreadonaddr_i;
	output reg [BusWidth - 1:0] sbaddress_o;
	input wire sbautoincrement_i;
	input wire [2:0] sbaccess_i;
	input wire sbreadondata_i;
	input wire [BusWidth - 1:0] sbdata_i;
	input wire sbdata_read_valid_i;
	input wire sbdata_write_valid_i;
	output wire [BusWidth - 1:0] sbdata_o;
	output wire sbdata_valid_o;
	output wire sbbusy_o;
	output reg sberror_valid_o;
	output reg [2:0] sberror_o;
	reg [2:0] state_d;
	reg [2:0] state_q;
	reg [BusWidth - 1:0] address;
	reg req;
	wire gnt;
	reg we;
	reg [(BusWidth / 8) - 1:0] be;
	reg [$clog2(BusWidth / 8) - 1:0] be_idx;
	assign sbbusy_o = sv2v_cast_1(state_q != Idle);
	always @(*) begin : p_fsm
		req = 1'b0;
		address = sbaddress_i;
		we = 1'b0;
		be = 1'sb0;
		be_idx = sbaddress_i[$clog2(BusWidth / 8) - 1:0];
		sberror_o = 1'sb0;
		sberror_valid_o = 1'b0;
		sbaddress_o = sbaddress_i;
		state_d = state_q;
		case (state_q)
			Idle: begin
				if (sbaddress_write_valid_i && sbreadonaddr_i)
					state_d = Read;
				if (sbdata_write_valid_i)
					state_d = Write;
				if (sbdata_read_valid_i && sbreadondata_i)
					state_d = Read;
			end
			Read: begin
				req = 1'b1;
				if (gnt)
					state_d = WaitRead;
			end
			Write: begin
				req = 1'b1;
				we = 1'b1;
				case (sbaccess_i)
					3'b000: be[be_idx] = 1'sb1;
					3'b001: be[sv2v_cast_32_signed({be_idx[(($clog2(BusWidth / 8) - 1) >= 0 ? $clog2(BusWidth / 8) - 1 : 0):1], 1'b0})+:2] = 1'sb1;
					3'b010:
						if (BusWidth == 32'd64)
							be[sv2v_cast_32_signed({be_idx[(($clog2(BusWidth / 8) - 1) >= 0 ? $clog2(BusWidth / 8) - 1 : 0)], 2'b0})+:4] = 1'sb1;
						else
							be = 1'sb1;
					3'b011: be = 1'sb1;
					default:
						;
				endcase
				if (gnt)
					state_d = WaitWrite;
			end
			WaitRead:
				if (sbdata_valid_o) begin
					state_d = Idle;
					if (sbautoincrement_i)
						sbaddress_o = sbaddress_i + (32'b1 << sbaccess_i);
				end
			WaitWrite:
				if (sbdata_valid_o) begin
					state_d = Idle;
					if (sbautoincrement_i)
						sbaddress_o = sbaddress_i + (32'b1 << sbaccess_i);
				end
			default: state_d = Idle;
		endcase
		if ((sbaccess_i > 3) && (state_q != Idle)) begin
			req = 1'b0;
			state_d = Idle;
			sberror_valid_o = 1'b1;
			sberror_o = 3'd3;
		end
	end
	always @(posedge clk_i or negedge rst_ni) begin : p_regs
		if (!rst_ni)
			state_q <= Idle;
		else
			state_q <= state_d;
	end
	assign master_req_o = req;
	assign master_add_o = address[BusWidth - 1:0];
	assign master_we_o = we;
	assign master_wdata_o = sbdata_i[BusWidth - 1:0];
	assign master_be_o = be[(BusWidth / 8) - 1:0];
	assign gnt = master_gnt_i;
	assign sbdata_valid_o = master_r_valid_i;
	assign sbdata_o = master_r_rdata_i[BusWidth - 1:0];
	function automatic [0:0] sv2v_cast_1;
		input reg [0:0] inp;
		sv2v_cast_1 = inp;
	endfunction
	function automatic signed [31:0] sv2v_cast_32_signed;
		input reg signed [31:0] inp;
		sv2v_cast_32_signed = inp;
	endfunction
endmodule
