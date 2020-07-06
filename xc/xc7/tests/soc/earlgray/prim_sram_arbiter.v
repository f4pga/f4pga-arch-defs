module prim_sram_arbiter (
	clk_i,
	rst_ni,
	req,
	req_addr,
	req_write,
	req_wdata,
	gnt,
	rsp_rvalid,
	rsp_rdata,
	rsp_error,
	sram_req,
	sram_addr,
	sram_write,
	sram_wdata,
	sram_rvalid,
	sram_rdata,
	sram_rerror
);
	parameter signed [31:0] N = 4;
	parameter signed [31:0] SramDw = 32;
	parameter signed [31:0] SramAw = 12;
	parameter ArbiterImpl = "PPC";
	input clk_i;
	input rst_ni;
	input [N - 1:0] req;
	input [(0 >= (N - 1) ? ((SramAw - 1) >= 0 ? ((2 - N) * SramAw) + (((N - 1) * SramAw) - 1) : ((2 - N) * (2 - SramAw)) + (((SramAw - 1) + ((N - 1) * (2 - SramAw))) - 1)) : ((SramAw - 1) >= 0 ? (N * SramAw) + -1 : (N * (2 - SramAw)) + ((SramAw - 1) - 1))):(0 >= (N - 1) ? ((SramAw - 1) >= 0 ? (N - 1) * SramAw : (SramAw - 1) + ((N - 1) * (2 - SramAw))) : ((SramAw - 1) >= 0 ? 0 : SramAw - 1))] req_addr;
	input [0:N - 1] req_write;
	input [(0 >= (N - 1) ? ((SramDw - 1) >= 0 ? ((2 - N) * SramDw) + (((N - 1) * SramDw) - 1) : ((2 - N) * (2 - SramDw)) + (((SramDw - 1) + ((N - 1) * (2 - SramDw))) - 1)) : ((SramDw - 1) >= 0 ? (N * SramDw) + -1 : (N * (2 - SramDw)) + ((SramDw - 1) - 1))):(0 >= (N - 1) ? ((SramDw - 1) >= 0 ? (N - 1) * SramDw : (SramDw - 1) + ((N - 1) * (2 - SramDw))) : ((SramDw - 1) >= 0 ? 0 : SramDw - 1))] req_wdata;
	output wire [N - 1:0] gnt;
	output wire [N - 1:0] rsp_rvalid;
	output wire [(0 >= (N - 1) ? ((SramDw - 1) >= 0 ? ((2 - N) * SramDw) + (((N - 1) * SramDw) - 1) : ((2 - N) * (2 - SramDw)) + (((SramDw - 1) + ((N - 1) * (2 - SramDw))) - 1)) : ((SramDw - 1) >= 0 ? (N * SramDw) + -1 : (N * (2 - SramDw)) + ((SramDw - 1) - 1))):(0 >= (N - 1) ? ((SramDw - 1) >= 0 ? (N - 1) * SramDw : (SramDw - 1) + ((N - 1) * (2 - SramDw))) : ((SramDw - 1) >= 0 ? 0 : SramDw - 1))] rsp_rdata;
	output wire [(0 >= (N - 1) ? ((2 - N) * 2) + (((N - 1) * 2) - 1) : (N * 2) + -1):(0 >= (N - 1) ? (N - 1) * 2 : 0)] rsp_error;
	output wire sram_req;
	output wire [SramAw - 1:0] sram_addr;
	output wire sram_write;
	output wire [SramDw - 1:0] sram_wdata;
	input sram_rvalid;
	input [SramDw - 1:0] sram_rdata;
	input [1:0] sram_rerror;
	localparam signed [31:0] ARB_DW = ((((1 + ((SramAw - 1) >= 0 ? SramAw : 2 - SramAw)) + ((SramDw - 1) >= 0 ? SramDw : 2 - SramDw)) - 1) >= 0 ? (1 + ((SramAw - 1) >= 0 ? SramAw : 2 - SramAw)) + ((SramDw - 1) >= 0 ? SramDw : 2 - SramDw) : 2 - ((1 + ((SramAw - 1) >= 0 ? SramAw : 2 - SramAw)) + ((SramDw - 1) >= 0 ? SramDw : 2 - SramDw)));
	wire [(0 >= (N - 1) ? ((((1 + ((SramAw - 1) >= 0 ? SramAw : 2 - SramAw)) + ((SramDw - 1) >= 0 ? SramDw : 2 - SramDw)) - 1) >= 0 ? ((2 - N) * ((1 + ((SramAw - 1) >= 0 ? SramAw : 2 - SramAw)) + ((SramDw - 1) >= 0 ? SramDw : 2 - SramDw))) + (((N - 1) * ((1 + ((SramAw - 1) >= 0 ? SramAw : 2 - SramAw)) + ((SramDw - 1) >= 0 ? SramDw : 2 - SramDw))) - 1) : ((2 - N) * (2 - ((1 + ((SramAw - 1) >= 0 ? SramAw : 2 - SramAw)) + ((SramDw - 1) >= 0 ? SramDw : 2 - SramDw)))) + (((((1 + ((SramAw - 1) >= 0 ? SramAw : 2 - SramAw)) + ((SramDw - 1) >= 0 ? SramDw : 2 - SramDw)) - 1) + ((N - 1) * (2 - ((1 + ((SramAw - 1) >= 0 ? SramAw : 2 - SramAw)) + ((SramDw - 1) >= 0 ? SramDw : 2 - SramDw))))) - 1)) : ((((1 + ((SramAw - 1) >= 0 ? SramAw : 2 - SramAw)) + ((SramDw - 1) >= 0 ? SramDw : 2 - SramDw)) - 1) >= 0 ? (N * ((1 + ((SramAw - 1) >= 0 ? SramAw : 2 - SramAw)) + ((SramDw - 1) >= 0 ? SramDw : 2 - SramDw))) + -1 : (N * (2 - ((1 + ((SramAw - 1) >= 0 ? SramAw : 2 - SramAw)) + ((SramDw - 1) >= 0 ? SramDw : 2 - SramDw)))) + ((((1 + ((SramAw - 1) >= 0 ? SramAw : 2 - SramAw)) + ((SramDw - 1) >= 0 ? SramDw : 2 - SramDw)) - 1) - 1))):(0 >= (N - 1) ? ((((1 + ((SramAw - 1) >= 0 ? SramAw : 2 - SramAw)) + ((SramDw - 1) >= 0 ? SramDw : 2 - SramDw)) - 1) >= 0 ? (N - 1) * ((1 + ((SramAw - 1) >= 0 ? SramAw : 2 - SramAw)) + ((SramDw - 1) >= 0 ? SramDw : 2 - SramDw)) : (((1 + ((SramAw - 1) >= 0 ? SramAw : 2 - SramAw)) + ((SramDw - 1) >= 0 ? SramDw : 2 - SramDw)) - 1) + ((N - 1) * (2 - ((1 + ((SramAw - 1) >= 0 ? SramAw : 2 - SramAw)) + ((SramDw - 1) >= 0 ? SramDw : 2 - SramDw))))) : ((((1 + ((SramAw - 1) >= 0 ? SramAw : 2 - SramAw)) + ((SramDw - 1) >= 0 ? SramDw : 2 - SramDw)) - 1) >= 0 ? 0 : ((1 + ((SramAw - 1) >= 0 ? SramAw : 2 - SramAw)) + ((SramDw - 1) >= 0 ? SramDw : 2 - SramDw)) - 1))] req_packed;
	generate
		genvar i;
		for (i = 0; i < N; i = i + 1) begin : gen_reqs
			assign req_packed[((((1 + ((SramAw - 1) >= 0 ? SramAw : 2 - SramAw)) + ((SramDw - 1) >= 0 ? SramDw : 2 - SramDw)) - 1) >= 0 ? 0 : ((1 + ((SramAw - 1) >= 0 ? SramAw : 2 - SramAw)) + ((SramDw - 1) >= 0 ? SramDw : 2 - SramDw)) - 1) + ((0 >= (N - 1) ? i : (N - 1) - i) * ((((1 + ((SramAw - 1) >= 0 ? SramAw : 2 - SramAw)) + ((SramDw - 1) >= 0 ? SramDw : 2 - SramDw)) - 1) >= 0 ? (1 + ((SramAw - 1) >= 0 ? SramAw : 2 - SramAw)) + ((SramDw - 1) >= 0 ? SramDw : 2 - SramDw) : 2 - ((1 + ((SramAw - 1) >= 0 ? SramAw : 2 - SramAw)) + ((SramDw - 1) >= 0 ? SramDw : 2 - SramDw))))+:((((1 + ((SramAw - 1) >= 0 ? SramAw : 2 - SramAw)) + ((SramDw - 1) >= 0 ? SramDw : 2 - SramDw)) - 1) >= 0 ? (1 + ((SramAw - 1) >= 0 ? SramAw : 2 - SramAw)) + ((SramDw - 1) >= 0 ? SramDw : 2 - SramDw) : 2 - ((1 + ((SramAw - 1) >= 0 ? SramAw : 2 - SramAw)) + ((SramDw - 1) >= 0 ? SramDw : 2 - SramDw)))] = {req_write[i], req_addr[((SramAw - 1) >= 0 ? 0 : SramAw - 1) + ((0 >= (N - 1) ? i : (N - 1) - i) * ((SramAw - 1) >= 0 ? SramAw : 2 - SramAw))+:((SramAw - 1) >= 0 ? SramAw : 2 - SramAw)], req_wdata[((SramDw - 1) >= 0 ? 0 : SramDw - 1) + ((0 >= (N - 1) ? i : (N - 1) - i) * ((SramDw - 1) >= 0 ? SramDw : 2 - SramDw))+:((SramDw - 1) >= 0 ? SramDw : 2 - SramDw)]};
		end
	endgenerate
	wire [((1 + ((SramAw - 1) >= 0 ? SramAw : 2 - SramAw)) + ((SramDw - 1) >= 0 ? SramDw : 2 - SramDw)) - 1:0] sram_packed;
	assign sram_write = sram_packed[1 + (((SramAw - 1) >= 0 ? SramAw : 2 - SramAw) + (((SramDw - 1) >= 0 ? SramDw : 2 - SramDw) + -1))];
	assign sram_addr = sram_packed[((SramAw - 1) >= 0 ? SramAw : 2 - SramAw) + (((SramDw - 1) >= 0 ? SramDw : 2 - SramDw) + -1)-:((((SramAw - 1) >= 0 ? SramAw : 2 - SramAw) + (((SramDw - 1) >= 0 ? SramDw : 2 - SramDw) + -1)) >= ((SramDw - 1) >= 0 ? SramDw : 2 - SramDw) ? ((((SramAw - 1) >= 0 ? SramAw : 2 - SramAw) + (((SramDw - 1) >= 0 ? SramDw : 2 - SramDw) + -1)) - ((SramDw - 1) >= 0 ? SramDw : 2 - SramDw)) + 1 : (((SramDw - 1) >= 0 ? SramDw : 2 - SramDw) - (((SramAw - 1) >= 0 ? SramAw : 2 - SramAw) + (((SramDw - 1) >= 0 ? SramDw : 2 - SramDw) + -1))) + 1)];
	assign sram_wdata = sram_packed[((SramDw - 1) >= 0 ? SramDw : 2 - SramDw) + -1-:((((SramDw - 1) >= 0 ? SramDw : 2 - SramDw) + -1) >= 0 ? ((SramDw - 1) >= 0 ? SramDw : 2 - SramDw) : 1 - (((SramDw - 1) >= 0 ? SramDw : 2 - SramDw) + -1))];
	generate
		if (ArbiterImpl == "PPC") begin : gen_arb_ppc
			prim_arbiter_ppc #(
				.N(N),
				.DW(ARB_DW)
			) u_reqarb(
				.clk_i(clk_i),
				.rst_ni(rst_ni),
				.req_i(req),
				.data_i(req_packed),
				.gnt_o(gnt),
				.idx_o(),
				.valid_o(sram_req),
				.data_o(sram_packed),
				.ready_i(1'b1)
			);
		end
		else if (ArbiterImpl == "BINTREE") begin : gen_tree_arb
			prim_arbiter_arb #(
				.N(N),
				.DW(ARB_DW)
			) u_reqarb(
				.clk_i(clk_i),
				.rst_ni(rst_ni),
				.req_i(req),
				.data_i(req_packed),
				.gnt_o(gnt),
				.idx_o(),
				.valid_o(sram_req),
				.data_o(sram_packed),
				.ready_i(1'b1)
			);
		end
	endgenerate
	wire [N - 1:0] steer;
	wire sram_ack;
	assign sram_ack = sram_rvalid & |steer;
	prim_fifo_sync #(
		.Width(N),
		.Pass(1'b0),
		.Depth(4)
	) u_req_fifo(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.clr_i(1'b0),
		.wvalid(sram_req && !sram_write),
		.wready(),
		.wdata(gnt),
		.depth(),
		.rvalid(),
		.rready(sram_ack),
		.rdata(steer)
	);
	assign rsp_rvalid = steer & {N {sram_rvalid}};
	generate
		for (i = 0; i < N; i = i + 1) begin : gen_rsp
			assign rsp_rdata[((SramDw - 1) >= 0 ? 0 : SramDw - 1) + ((0 >= (N - 1) ? i : (N - 1) - i) * ((SramDw - 1) >= 0 ? SramDw : 2 - SramDw))+:((SramDw - 1) >= 0 ? SramDw : 2 - SramDw)] = sram_rdata;
			assign rsp_error[(0 >= (N - 1) ? i : (N - 1) - i) * 2+:2] = sram_rerror;
		end
	endgenerate
endmodule
