module tlul_adapter_host (
	clk_i,
	rst_ni,
	req_i,
	gnt_o,
	addr_i,
	we_i,
	wdata_i,
	be_i,
	size_i,
	valid_o,
	rdata_o,
	tl_o,
	tl_i
);
	localparam [2:0] tlul_pkg_Get = 3'h 4;
	localparam [2:0] tlul_pkg_PutFullData = 3'h 0;
	localparam top_pkg_TL_AIW = 8;
	localparam top_pkg_TL_AW = 32;
	localparam top_pkg_TL_DBW = top_pkg_TL_DW >> 3;
	localparam top_pkg_TL_DIW = 1;
	localparam top_pkg_TL_DUW = 16;
	localparam top_pkg_TL_DW = 32;
	localparam top_pkg_TL_SZW = $clog2($clog2(32 >> 3) + 1);
	parameter [31:0] AW = 32;
	parameter [31:0] DW = 32;
	input clk_i;
	input rst_ni;
	input req_i;
	output wire gnt_o;
	input [AW - 1:0] addr_i;
	input we_i;
	input [DW - 1:0] wdata_i;
	input [(DW / 8) - 1:0] be_i;
	input [1:0] size_i;
	output wire valid_o;
	output wire [DW - 1:0] rdata_o;
	output wire [((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_AW) + ((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW)) + top_pkg_TL_DW) + 17) - 1:0] tl_o;
	input wire [((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_DIW) + top_pkg_TL_DW) + top_pkg_TL_DUW) + 2) - 1:0] tl_i;
	wire [2:0] req_op;
	assign req_op = (we_i ? tlul_pkg_PutFullData : tlul_pkg_Get);
	assign tl_o = sv2v_struct_50735(req_i, req_op, 1'sb0, size_i, 1'sb0, addr_i, be_i, wdata_i, 1'sb0, 1'b1);
	assign gnt_o = tl_i[0];
	assign valid_o = tl_i[1 + (3 + (3 + (((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW) + (top_pkg_TL_AIW + (top_pkg_TL_DIW + (top_pkg_TL_DW + (top_pkg_TL_DUW + 1)))))))];
	assign rdata_o = tl_i[top_pkg_TL_DW + (top_pkg_TL_DUW + 1)-:((top_pkg_TL_DW + (top_pkg_TL_DUW + 1)) - (top_pkg_TL_DUW + 2)) + 1];
	function automatic [((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + ((top_pkg_TL_AIW - 1) >= 0 ? top_pkg_TL_AIW : 2 - top_pkg_TL_AIW)) + ((top_pkg_TL_AW - 1) >= 0 ? top_pkg_TL_AW : 2 - top_pkg_TL_AW)) + ((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW)) + ((top_pkg_TL_DW - 1) >= 0 ? top_pkg_TL_DW : 2 - top_pkg_TL_DW)) + 17) - 1:0] sv2v_struct_50735;
		input reg a_valid;
		input reg [2:0] a_opcode;
		input reg [2:0] a_param;
		input reg [top_pkg_TL_SZW - 1:0] a_size;
		input reg [top_pkg_TL_AIW - 1:0] a_source;
		input reg [top_pkg_TL_AW - 1:0] a_address;
		input reg [top_pkg_TL_DBW - 1:0] a_mask;
		input reg [top_pkg_TL_DW - 1:0] a_data;
		input reg [15:0] a_user;
		input reg d_ready;
		sv2v_struct_50735 = {a_valid, a_opcode, a_param, a_size, a_source, a_address, a_mask, a_data, a_user, d_ready};
	endfunction
endmodule
