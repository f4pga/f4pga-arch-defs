module tlul_adapter_reg (
	clk_i,
	rst_ni,
	tl_i,
	tl_o,
	re_o,
	we_o,
	addr_o,
	wdata_o,
	be_o,
	rdata_i,
	error_i
);
	localparam top_pkg_TL_AIW = 8;
	localparam top_pkg_TL_AW = 32;
	localparam top_pkg_TL_DBW = top_pkg_TL_DW >> 3;
	localparam top_pkg_TL_DIW = 1;
	localparam top_pkg_TL_DUW = 16;
	localparam top_pkg_TL_DW = 32;
	localparam top_pkg_TL_SZW = $clog2($clog2(32 >> 3) + 1);
	parameter ArbiterImpl = "PPC";
	localparam [2:0] AccessAck = 3'h 0;
	localparam [2:0] PutFullData = 3'h 0;
	localparam [2:0] AccessAckData = 3'h 1;
	localparam [2:0] PutPartialData = 3'h 1;
	localparam [2:0] Get = 3'h 4;
	parameter signed [31:0] RegAw = 8;
	parameter signed [31:0] RegDw = 32;
	localparam signed [31:0] RegBw = RegDw / 8;
	input clk_i;
	input rst_ni;
	input wire [((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_AW) + ((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW)) + top_pkg_TL_DW) + 17) - 1:0] tl_i;
	output wire [((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_DIW) + top_pkg_TL_DW) + top_pkg_TL_DUW) + 2) - 1:0] tl_o;
	output wire re_o;
	output wire we_o;
	output wire [RegAw - 1:0] addr_o;
	output wire [RegDw - 1:0] wdata_o;
	output wire [RegBw - 1:0] be_o;
	input [RegDw - 1:0] rdata_i;
	input error_i;
	localparam signed [31:0] IW = ((8 + (32 + ((((32 >> 3) - 1) >= 0 ? 32 >> 3 : 2 - (32 >> 3)) + 48))) >= (((8 + (32 + ((((32 >> 3) - 1) >= 0 ? 32 >> 3 : 2 - (32 >> 3)) + 48))) - ((8 + (32 + ((((32 >> 3) - 1) >= 0 ? 32 >> 3 : 2 - (32 >> 3)) + 48))) >= (32 + ((((32 >> 3) - 1) >= 0 ? 32 >> 3 : 2 - (32 >> 3)) + 49)) ? ((8 + (32 + ((((32 >> 3) - 1) >= 0 ? 32 >> 3 : 2 - (32 >> 3)) + 48))) - (32 + ((((32 >> 3) - 1) >= 0 ? 32 >> 3 : 2 - (32 >> 3)) + 49))) + 1 : ((32 + ((((32 >> 3) - 1) >= 0 ? 32 >> 3 : 2 - (32 >> 3)) + 49)) - (8 + (32 + ((((32 >> 3) - 1) >= 0 ? 32 >> 3 : 2 - (32 >> 3)) + 48)))) + 1)) + 1) ? ((top_pkg_TL_AIW + (top_pkg_TL_AW + (((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW) + (top_pkg_TL_DW + 16)))) - (((top_pkg_TL_AIW + (top_pkg_TL_AW + (((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW) + (top_pkg_TL_DW + 16)))) - ((8 + (32 + ((((32 >> 3) - 1) >= 0 ? 32 >> 3 : 2 - (32 >> 3)) + 48))) >= (32 + ((((32 >> 3) - 1) >= 0 ? 32 >> 3 : 2 - (32 >> 3)) + 49)) ? ((top_pkg_TL_AIW + (top_pkg_TL_AW + (((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW) + (top_pkg_TL_DW + 16)))) - (top_pkg_TL_AW + (((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW) + (top_pkg_TL_DW + 17)))) + 1 : ((top_pkg_TL_AW + (((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW) + (top_pkg_TL_DW + 17))) - (top_pkg_TL_AIW + (top_pkg_TL_AW + (((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW) + (top_pkg_TL_DW + 16))))) + 1)) + 1)) + 1 : ((((top_pkg_TL_AIW + (top_pkg_TL_AW + (((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW) + (top_pkg_TL_DW + 16)))) - ((8 + (32 + ((((32 >> 3) - 1) >= 0 ? 32 >> 3 : 2 - (32 >> 3)) + 48))) >= (32 + ((((32 >> 3) - 1) >= 0 ? 32 >> 3 : 2 - (32 >> 3)) + 49)) ? ((top_pkg_TL_AIW + (top_pkg_TL_AW + (((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW) + (top_pkg_TL_DW + 16)))) - (top_pkg_TL_AW + (((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW) + (top_pkg_TL_DW + 17)))) + 1 : ((top_pkg_TL_AW + (((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW) + (top_pkg_TL_DW + 17))) - (top_pkg_TL_AIW + (top_pkg_TL_AW + (((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW) + (top_pkg_TL_DW + 16))))) + 1)) + 1) - (top_pkg_TL_AIW + (top_pkg_TL_AW + (((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW) + (top_pkg_TL_DW + 16))))) + 1);
	localparam signed [31:0] SZW = (((($clog2($clog2(32 >> 3) + 1) - 1) >= 0 ? $clog2($clog2(32 >> 3) + 1) : 2 - $clog2($clog2(32 >> 3) + 1)) + (8 + (32 + ((((32 >> 3) - 1) >= 0 ? 32 >> 3 : 2 - (32 >> 3)) + 48)))) >= ((((($clog2($clog2(32 >> 3) + 1) - 1) >= 0 ? $clog2($clog2(32 >> 3) + 1) : 2 - $clog2($clog2(32 >> 3) + 1)) + (8 + (32 + ((((32 >> 3) - 1) >= 0 ? 32 >> 3 : 2 - (32 >> 3)) + 48)))) - (((($clog2($clog2(32 >> 3) + 1) - 1) >= 0 ? $clog2($clog2(32 >> 3) + 1) : 2 - $clog2($clog2(32 >> 3) + 1)) + (8 + (32 + ((((32 >> 3) - 1) >= 0 ? 32 >> 3 : 2 - (32 >> 3)) + 48)))) >= (8 + (32 + ((((32 >> 3) - 1) >= 0 ? 32 >> 3 : 2 - (32 >> 3)) + 49))) ? (((($clog2($clog2(32 >> 3) + 1) - 1) >= 0 ? $clog2($clog2(32 >> 3) + 1) : 2 - $clog2($clog2(32 >> 3) + 1)) + (8 + (32 + ((((32 >> 3) - 1) >= 0 ? 32 >> 3 : 2 - (32 >> 3)) + 48)))) - (8 + (32 + ((((32 >> 3) - 1) >= 0 ? 32 >> 3 : 2 - (32 >> 3)) + 49)))) + 1 : ((8 + (32 + ((((32 >> 3) - 1) >= 0 ? 32 >> 3 : 2 - (32 >> 3)) + 49))) - ((($clog2($clog2(32 >> 3) + 1) - 1) >= 0 ? $clog2($clog2(32 >> 3) + 1) : 2 - $clog2($clog2(32 >> 3) + 1)) + (8 + (32 + ((((32 >> 3) - 1) >= 0 ? 32 >> 3 : 2 - (32 >> 3)) + 48))))) + 1)) + 1) ? ((((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW) + (top_pkg_TL_AIW + (top_pkg_TL_AW + (((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW) + (top_pkg_TL_DW + 16))))) - (((((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW) + (top_pkg_TL_AIW + (top_pkg_TL_AW + (((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW) + (top_pkg_TL_DW + 16))))) - (((($clog2($clog2(32 >> 3) + 1) - 1) >= 0 ? $clog2($clog2(32 >> 3) + 1) : 2 - $clog2($clog2(32 >> 3) + 1)) + (8 + (32 + ((((32 >> 3) - 1) >= 0 ? 32 >> 3 : 2 - (32 >> 3)) + 48)))) >= (8 + (32 + ((((32 >> 3) - 1) >= 0 ? 32 >> 3 : 2 - (32 >> 3)) + 49))) ? ((((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW) + (top_pkg_TL_AIW + (top_pkg_TL_AW + (((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW) + (top_pkg_TL_DW + 16))))) - (top_pkg_TL_AIW + (top_pkg_TL_AW + (((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW) + (top_pkg_TL_DW + 17))))) + 1 : ((top_pkg_TL_AIW + (top_pkg_TL_AW + (((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW) + (top_pkg_TL_DW + 17)))) - (((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW) + (top_pkg_TL_AIW + (top_pkg_TL_AW + (((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW) + (top_pkg_TL_DW + 16)))))) + 1)) + 1)) + 1 : ((((((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW) + (top_pkg_TL_AIW + (top_pkg_TL_AW + (((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW) + (top_pkg_TL_DW + 16))))) - (((($clog2($clog2(32 >> 3) + 1) - 1) >= 0 ? $clog2($clog2(32 >> 3) + 1) : 2 - $clog2($clog2(32 >> 3) + 1)) + (8 + (32 + ((((32 >> 3) - 1) >= 0 ? 32 >> 3 : 2 - (32 >> 3)) + 48)))) >= (8 + (32 + ((((32 >> 3) - 1) >= 0 ? 32 >> 3 : 2 - (32 >> 3)) + 49))) ? ((((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW) + (top_pkg_TL_AIW + (top_pkg_TL_AW + (((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW) + (top_pkg_TL_DW + 16))))) - (top_pkg_TL_AIW + (top_pkg_TL_AW + (((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW) + (top_pkg_TL_DW + 17))))) + 1 : ((top_pkg_TL_AIW + (top_pkg_TL_AW + (((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW) + (top_pkg_TL_DW + 17)))) - (((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW) + (top_pkg_TL_AIW + (top_pkg_TL_AW + (((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW) + (top_pkg_TL_DW + 16)))))) + 1)) + 1) - (((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW) + (top_pkg_TL_AIW + (top_pkg_TL_AW + (((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW) + (top_pkg_TL_DW + 16)))))) + 1);
	reg outstanding;
	wire a_ack;
	wire d_ack;
	reg [RegDw - 1:0] rdata;
	reg error;
	wire err_internal;
	reg addr_align_err;
	wire malformed_meta_err;
	wire tl_err;
	reg [IW - 1:0] reqid;
	reg [SZW - 1:0] reqsz;
	reg [2:0] rspop;
	wire rd_req;
	wire wr_req;
	assign a_ack = tl_i[1 + (3 + (3 + (((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW) + (top_pkg_TL_AIW + (top_pkg_TL_AW + (((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW) + (top_pkg_TL_DW + 16)))))))] & tl_o[0];
	assign d_ack = tl_o[1 + (3 + (3 + (((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW) + (top_pkg_TL_AIW + (top_pkg_TL_DIW + (top_pkg_TL_DW + (top_pkg_TL_DUW + 1)))))))] & tl_i[0];
	assign wr_req = a_ack & ((tl_i[3 + (3 + (((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW) + (top_pkg_TL_AIW + (top_pkg_TL_AW + (((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW) + (top_pkg_TL_DW + 16))))))-:((3 + (3 + ((($clog2($clog2(32 >> 3) + 1) - 1) >= 0 ? $clog2($clog2(32 >> 3) + 1) : 2 - $clog2($clog2(32 >> 3) + 1)) + (8 + (32 + ((((32 >> 3) - 1) >= 0 ? 32 >> 3 : 2 - (32 >> 3)) + 48)))))) >= (3 + ((($clog2($clog2(32 >> 3) + 1) - 1) >= 0 ? $clog2($clog2(32 >> 3) + 1) : 2 - $clog2($clog2(32 >> 3) + 1)) + (8 + (32 + ((((32 >> 3) - 1) >= 0 ? 32 >> 3 : 2 - (32 >> 3)) + 49))))) ? ((3 + (3 + (((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW) + (top_pkg_TL_AIW + (top_pkg_TL_AW + (((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW) + (top_pkg_TL_DW + 16))))))) - (3 + (((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW) + (top_pkg_TL_AIW + (top_pkg_TL_AW + (((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW) + (top_pkg_TL_DW + 17))))))) + 1 : ((3 + (((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW) + (top_pkg_TL_AIW + (top_pkg_TL_AW + (((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW) + (top_pkg_TL_DW + 17)))))) - (3 + (3 + (((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW) + (top_pkg_TL_AIW + (top_pkg_TL_AW + (((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW) + (top_pkg_TL_DW + 16)))))))) + 1)] == PutFullData) | (tl_i[3 + (3 + (((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW) + (top_pkg_TL_AIW + (top_pkg_TL_AW + (((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW) + (top_pkg_TL_DW + 16))))))-:((3 + (3 + ((($clog2($clog2(32 >> 3) + 1) - 1) >= 0 ? $clog2($clog2(32 >> 3) + 1) : 2 - $clog2($clog2(32 >> 3) + 1)) + (8 + (32 + ((((32 >> 3) - 1) >= 0 ? 32 >> 3 : 2 - (32 >> 3)) + 48)))))) >= (3 + ((($clog2($clog2(32 >> 3) + 1) - 1) >= 0 ? $clog2($clog2(32 >> 3) + 1) : 2 - $clog2($clog2(32 >> 3) + 1)) + (8 + (32 + ((((32 >> 3) - 1) >= 0 ? 32 >> 3 : 2 - (32 >> 3)) + 49))))) ? ((3 + (3 + (((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW) + (top_pkg_TL_AIW + (top_pkg_TL_AW + (((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW) + (top_pkg_TL_DW + 16))))))) - (3 + (((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW) + (top_pkg_TL_AIW + (top_pkg_TL_AW + (((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW) + (top_pkg_TL_DW + 17))))))) + 1 : ((3 + (((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW) + (top_pkg_TL_AIW + (top_pkg_TL_AW + (((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW) + (top_pkg_TL_DW + 17)))))) - (3 + (3 + (((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW) + (top_pkg_TL_AIW + (top_pkg_TL_AW + (((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW) + (top_pkg_TL_DW + 16)))))))) + 1)] == PutPartialData));
	assign rd_req = a_ack & (tl_i[3 + (3 + (((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW) + (top_pkg_TL_AIW + (top_pkg_TL_AW + (((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW) + (top_pkg_TL_DW + 16))))))-:((3 + (3 + ((($clog2($clog2(32 >> 3) + 1) - 1) >= 0 ? $clog2($clog2(32 >> 3) + 1) : 2 - $clog2($clog2(32 >> 3) + 1)) + (8 + (32 + ((((32 >> 3) - 1) >= 0 ? 32 >> 3 : 2 - (32 >> 3)) + 48)))))) >= (3 + ((($clog2($clog2(32 >> 3) + 1) - 1) >= 0 ? $clog2($clog2(32 >> 3) + 1) : 2 - $clog2($clog2(32 >> 3) + 1)) + (8 + (32 + ((((32 >> 3) - 1) >= 0 ? 32 >> 3 : 2 - (32 >> 3)) + 49))))) ? ((3 + (3 + (((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW) + (top_pkg_TL_AIW + (top_pkg_TL_AW + (((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW) + (top_pkg_TL_DW + 16))))))) - (3 + (((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW) + (top_pkg_TL_AIW + (top_pkg_TL_AW + (((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW) + (top_pkg_TL_DW + 17))))))) + 1 : ((3 + (((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW) + (top_pkg_TL_AIW + (top_pkg_TL_AW + (((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW) + (top_pkg_TL_DW + 17)))))) - (3 + (3 + (((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW) + (top_pkg_TL_AIW + (top_pkg_TL_AW + (((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW) + (top_pkg_TL_DW + 16)))))))) + 1)] == Get);
	assign we_o = wr_req & ~err_internal;
	assign re_o = rd_req & ~err_internal;
	assign addr_o = {tl_i[(top_pkg_TL_AW + (((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW) + (top_pkg_TL_DW + 16))) - ((top_pkg_TL_AW - 1) - (RegAw - 1)):(top_pkg_TL_AW + (((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW) + (top_pkg_TL_DW + 16))) - ((top_pkg_TL_AW - 1) - 2)], 2'b00};
	assign wdata_o = tl_i[top_pkg_TL_DW + 16-:((top_pkg_TL_DW + 16) - 17) + 1];
	assign be_o = tl_i[((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW) + (top_pkg_TL_DW + 16)-:(((((32 >> 3) - 1) >= 0 ? 32 >> 3 : 2 - (32 >> 3)) + 48) >= 49 ? ((((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW) + (top_pkg_TL_DW + 16)) - (top_pkg_TL_DW + 17)) + 1 : ((top_pkg_TL_DW + 17) - (((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW) + (top_pkg_TL_DW + 16))) + 1)];
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			outstanding <= 1'b0;
		else if (a_ack)
			outstanding <= 1'b1;
		else if (d_ack)
			outstanding <= 1'b0;
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni) begin
			reqid <= 1'sb0;
			reqsz <= 1'sb0;
			rspop <= AccessAck;
		end
		else if (a_ack) begin
			reqid <= tl_i[top_pkg_TL_AIW + (top_pkg_TL_AW + (((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW) + (top_pkg_TL_DW + 16)))-:((8 + (32 + ((((32 >> 3) - 1) >= 0 ? 32 >> 3 : 2 - (32 >> 3)) + 48))) >= (32 + ((((32 >> 3) - 1) >= 0 ? 32 >> 3 : 2 - (32 >> 3)) + 49)) ? ((top_pkg_TL_AIW + (top_pkg_TL_AW + (((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW) + (top_pkg_TL_DW + 16)))) - (top_pkg_TL_AW + (((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW) + (top_pkg_TL_DW + 17)))) + 1 : ((top_pkg_TL_AW + (((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW) + (top_pkg_TL_DW + 17))) - (top_pkg_TL_AIW + (top_pkg_TL_AW + (((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW) + (top_pkg_TL_DW + 16))))) + 1)];
			reqsz <= tl_i[((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW) + (top_pkg_TL_AIW + (top_pkg_TL_AW + (((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW) + (top_pkg_TL_DW + 16))))-:(((($clog2($clog2(32 >> 3) + 1) - 1) >= 0 ? $clog2($clog2(32 >> 3) + 1) : 2 - $clog2($clog2(32 >> 3) + 1)) + (8 + (32 + ((((32 >> 3) - 1) >= 0 ? 32 >> 3 : 2 - (32 >> 3)) + 48)))) >= (8 + (32 + ((((32 >> 3) - 1) >= 0 ? 32 >> 3 : 2 - (32 >> 3)) + 49))) ? ((((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW) + (top_pkg_TL_AIW + (top_pkg_TL_AW + (((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW) + (top_pkg_TL_DW + 16))))) - (top_pkg_TL_AIW + (top_pkg_TL_AW + (((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW) + (top_pkg_TL_DW + 17))))) + 1 : ((top_pkg_TL_AIW + (top_pkg_TL_AW + (((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW) + (top_pkg_TL_DW + 17)))) - (((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW) + (top_pkg_TL_AIW + (top_pkg_TL_AW + (((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW) + (top_pkg_TL_DW + 16)))))) + 1)];
			rspop <= (rd_req ? AccessAckData : AccessAck);
		end
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni) begin
			rdata <= 1'sb0;
			error <= 1'b0;
		end
		else if (a_ack) begin
			rdata <= (err_internal ? 1'sb1 : rdata_i);
			error <= error_i | err_internal;
		end
	assign tl_o = sv2v_struct_18D63(outstanding, rspop, 1'sb0, reqsz, reqid, 1'sb0, rdata, 1'sb0, error, ~outstanding);
	assign err_internal = (addr_align_err | malformed_meta_err) | tl_err;
	assign malformed_meta_err = tl_i[9] == 1'b1;
	always @(*)
		if (wr_req)
			addr_align_err = |tl_i[(top_pkg_TL_AW + (((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW) + (top_pkg_TL_DW + 16))) - ((top_pkg_TL_AW - 1) - 1):(top_pkg_TL_AW + (((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW) + (top_pkg_TL_DW + 16))) - (top_pkg_TL_AW - 1)];
		else
			addr_align_err = 1'b0;
	tlul_err u_err(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.tl_i(tl_i),
		.err_o(tl_err)
	);
	function automatic [((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + ((top_pkg_TL_AIW - 1) >= 0 ? top_pkg_TL_AIW : 2 - top_pkg_TL_AIW)) + ((top_pkg_TL_DIW - 1) >= 0 ? top_pkg_TL_DIW : 2 - top_pkg_TL_DIW)) + ((top_pkg_TL_DW - 1) >= 0 ? top_pkg_TL_DW : 2 - top_pkg_TL_DW)) + ((top_pkg_TL_DUW - 1) >= 0 ? top_pkg_TL_DUW : 2 - top_pkg_TL_DUW)) + 2) - 1:0] sv2v_struct_18D63;
		input reg d_valid;
		input reg [2:0] d_opcode;
		input reg [2:0] d_param;
		input reg [top_pkg_TL_SZW - 1:0] d_size;
		input reg [top_pkg_TL_AIW - 1:0] d_source;
		input reg [top_pkg_TL_DIW - 1:0] d_sink;
		input reg [top_pkg_TL_DW - 1:0] d_data;
		input reg [top_pkg_TL_DUW - 1:0] d_user;
		input reg d_error;
		input reg a_ready;
		sv2v_struct_18D63 = {d_valid, d_opcode, d_param, d_size, d_source, d_sink, d_data, d_user, d_error, a_ready};
	endfunction
endmodule
