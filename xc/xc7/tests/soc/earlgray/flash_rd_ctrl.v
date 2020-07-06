module flash_rd_ctrl (
	clk_i,
	rst_ni,
	op_start_i,
	op_num_words_i,
	op_done_o,
	op_err_o,
	op_addr_i,
	data_rdy_i,
	data_o,
	data_wr_o,
	flash_req_o,
	flash_addr_o,
	flash_ovfl_o,
	flash_data_i,
	flash_done_i,
	flash_error_i
);
	localparam [0:0] StNorm = 'h0;
	localparam [0:0] StErr = 'h1;
	parameter signed [31:0] AddrW = 10;
	parameter signed [31:0] DataW = 32;
	input clk_i;
	input rst_ni;
	input op_start_i;
	input [11:0] op_num_words_i;
	output reg op_done_o;
	output reg op_err_o;
	input [AddrW - 1:0] op_addr_i;
	input data_rdy_i;
	output wire [DataW - 1:0] data_o;
	output reg data_wr_o;
	output reg flash_req_o;
	output wire [AddrW - 1:0] flash_addr_o;
	output wire flash_ovfl_o;
	input [DataW - 1:0] flash_data_i;
	input flash_done_i;
	input flash_error_i;
	reg [0:0] st;
	reg [0:0] st_nxt;
	reg [11:0] cnt;
	reg [11:0] cnt_nxt;
	wire cnt_hit;
	wire [AddrW:0] int_addr;
	wire txn_done;
	reg err_sel;
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni) begin
			cnt <= 1'sb0;
			st <= StNorm;
		end
		else begin
			cnt <= cnt_nxt;
			st <= st_nxt;
		end
	assign txn_done = flash_req_o & flash_done_i;
	assign cnt_hit = cnt == op_num_words_i;
	always @(*) begin
		st_nxt = st;
		cnt_nxt = cnt;
		flash_req_o = 1'b0;
		data_wr_o = 1'b0;
		op_done_o = 1'b0;
		op_err_o = 1'b0;
		err_sel = 1'b0;
		case (st)
			StNorm: begin
				flash_req_o = op_start_i & data_rdy_i;
				if (txn_done && cnt_hit) begin
					cnt_nxt = 1'sb0;
					data_wr_o = 1'b1;
					op_done_o = 1'b1;
					op_err_o = flash_error_i;
				end
				else if (txn_done) begin
					cnt_nxt = cnt + 1'b1;
					data_wr_o = 1'b1;
					err_sel = flash_error_i;
					st_nxt = (flash_error_i ? StErr : StNorm);
				end
			end
			StErr: begin
				data_wr_o = data_rdy_i;
				err_sel = 1'b1;
				if (data_rdy_i && cnt_hit) begin
					st_nxt = StNorm;
					cnt_nxt = 1'sb0;
					op_done_o = 1'b1;
					op_err_o = 1'b1;
				end
				else if (data_rdy_i)
					cnt_nxt = cnt + 1'b1;
			end
			default:
				;
		endcase
	end
	assign int_addr = op_addr_i + sv2v_cast_BA3C3(cnt);
	assign flash_addr_o = int_addr[0+:AddrW];
	assign flash_ovfl_o = int_addr[AddrW];
	assign data_o = (err_sel ? {DataW {1'b1}} : flash_data_i);
	function automatic [AddrW - 1:0] sv2v_cast_BA3C3;
		input reg [AddrW - 1:0] inp;
		sv2v_cast_BA3C3 = inp;
	endfunction
endmodule
