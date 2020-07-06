module prim_ram_2p_adv (
	clk_i,
	rst_ni,
	a_req_i,
	a_write_i,
	a_addr_i,
	a_wdata_i,
	a_rvalid_o,
	a_rdata_o,
	a_rerror_o,
	b_req_i,
	b_write_i,
	b_addr_i,
	b_wdata_i,
	b_rvalid_o,
	b_rdata_o,
	b_rerror_o,
	cfg_i
);
	localparam prim_pkg_ImplGeneric = 0;
	parameter signed [31:0] Depth = 512;
	parameter signed [31:0] Width = 32;
	parameter signed [31:0] CfgW = 8;
	parameter EnableECC = 0;
	parameter EnableParity = 0;
	parameter EnableInputPipeline = 0;
	parameter EnableOutputPipeline = 0;
	parameter MemT = "REGISTER";
	parameter signed [31:0] SramAw = $clog2(Depth);
	input clk_i;
	input rst_ni;
	input a_req_i;
	input a_write_i;
	input [SramAw - 1:0] a_addr_i;
	input [Width - 1:0] a_wdata_i;
	output wire a_rvalid_o;
	output wire [Width - 1:0] a_rdata_o;
	output wire [1:0] a_rerror_o;
	input b_req_i;
	input b_write_i;
	input [SramAw - 1:0] b_addr_i;
	input [Width - 1:0] b_wdata_i;
	output wire b_rvalid_o;
	output wire [Width - 1:0] b_rdata_o;
	output wire [1:0] b_rerror_o;
	input [CfgW - 1:0] cfg_i;
	localparam signed [31:0] ParWidth = (EnableParity ? 1 : (!EnableECC ? 0 : (Width <= 4 ? 4 : (Width <= 11 ? 5 : (Width <= 26 ? 6 : (Width <= 57 ? 7 : (Width <= 120 ? 8 : 8)))))));
	localparam signed [31:0] TotalWidth = Width + ParWidth;
	reg a_req_q;
	wire a_req_d;
	reg a_write_q;
	wire a_write_d;
	reg [SramAw - 1:0] a_addr_q;
	wire [SramAw - 1:0] a_addr_d;
	reg [TotalWidth - 1:0] a_wdata_q;
	wire [TotalWidth - 1:0] a_wdata_d;
	reg a_rvalid_q;
	wire a_rvalid_d;
	reg a_rvalid_sram;
	reg [Width - 1:0] a_rdata_q;
	wire [Width - 1:0] a_rdata_d;
	wire [TotalWidth - 1:0] a_rdata_sram;
	reg [1:0] a_rerror_q;
	wire [1:0] a_rerror_d;
	reg b_req_q;
	wire b_req_d;
	reg b_write_q;
	wire b_write_d;
	reg [SramAw - 1:0] b_addr_q;
	wire [SramAw - 1:0] b_addr_d;
	reg [TotalWidth - 1:0] b_wdata_q;
	wire [TotalWidth - 1:0] b_wdata_d;
	reg b_rvalid_q;
	wire b_rvalid_d;
	reg b_rvalid_sram;
	reg [Width - 1:0] b_rdata_q;
	wire [Width - 1:0] b_rdata_d;
	wire [TotalWidth - 1:0] b_rdata_sram;
	reg [1:0] b_rerror_q;
	wire [1:0] b_rerror_d;
	generate
		if (MemT == "REGISTER") begin : gen_regmem
			prim_ram_2p #(
				.Width(TotalWidth),
				.Depth(Depth),
				.Impl(prim_pkg_ImplGeneric)
			) u_mem(
				.clk_a_i(clk_i),
				.clk_b_i(clk_i),
				.a_req_i(a_req_q),
				.a_write_i(a_write_q),
				.a_addr_i(a_addr_q),
				.a_wdata_i(a_wdata_q),
				.a_rdata_o(a_rdata_sram),
				.b_req_i(b_req_q),
				.b_write_i(b_write_q),
				.b_addr_i(b_addr_q),
				.b_wdata_i(b_wdata_q),
				.b_rdata_o(b_rdata_sram)
			);
		end
		else if (MemT == "SRAM") begin : gen_srammem
			prim_ram_2p #(
				.Width(TotalWidth),
				.Depth(Depth)
			) u_mem(
				.clk_a_i(clk_i),
				.clk_b_i(clk_i),
				.a_req_i(a_req_q),
				.a_write_i(a_write_q),
				.a_addr_i(a_addr_q),
				.a_wdata_i(a_wdata_q),
				.a_rdata_o(a_rdata_sram),
				.b_req_i(b_req_q),
				.b_write_i(b_write_q),
				.b_addr_i(b_addr_q),
				.b_wdata_i(b_wdata_q),
				.b_rdata_o(b_rdata_sram)
			);
		end
	endgenerate
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni) begin
			a_rvalid_sram <= 1'sb0;
			b_rvalid_sram <= 1'sb0;
		end
		else begin
			a_rvalid_sram <= a_req_q & ~a_write_q;
			b_rvalid_sram <= b_req_q & ~b_write_q;
		end
	assign a_req_d = a_req_i;
	assign a_write_d = a_write_i;
	assign a_addr_d = a_addr_i;
	assign a_rvalid_o = a_rvalid_q;
	assign a_rdata_o = a_rdata_q;
	assign a_rerror_o = a_rerror_q;
	assign b_req_d = b_req_i;
	assign b_write_d = b_write_i;
	assign b_addr_d = b_addr_i;
	assign b_rvalid_o = b_rvalid_q;
	assign b_rdata_o = b_rdata_q;
	assign b_rerror_o = b_rerror_q;
	generate
		if ((EnableParity == 0) && EnableECC) begin : gen_secded
			if (Width == 32) begin : gen_secded_39_32
				prim_secded_39_32_enc u_enc_a(
					.in(a_wdata_i),
					.out(a_wdata_d)
				);
				prim_secded_39_32_dec u_dec_a(
					.in(a_rdata_sram),
					.d_o(a_rdata_d),
					.syndrome_o(),
					.err_o(a_rerror_d)
				);
				prim_secded_39_32_enc u_enc_b(
					.in(b_wdata_i),
					.out(b_wdata_d)
				);
				prim_secded_39_32_dec u_dec_b(
					.in(b_rdata_sram),
					.d_o(b_rdata_d),
					.syndrome_o(),
					.err_o(b_rerror_d)
				);
				assign a_rvalid_d = a_rvalid_sram;
				assign b_rvalid_d = b_rvalid_sram;
			end
		end
		else begin : gen_nosecded
			assign a_wdata_d[0+:Width] = a_wdata_i;
			assign b_wdata_d[0+:Width] = b_wdata_i;
			assign a_rdata_d = a_rdata_sram;
			assign b_rdata_d = b_rdata_sram;
			assign a_rvalid_d = a_rvalid_sram;
			assign b_rvalid_d = b_rvalid_sram;
			assign a_rerror_d = 2'b00;
			assign b_rerror_d = 2'b00;
		end
	endgenerate
	generate
		if (EnableInputPipeline) begin : gen_regslice_input
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni) begin
					a_req_q <= 1'sb0;
					a_write_q <= 1'sb0;
					a_addr_q <= 1'sb0;
					a_wdata_q <= 1'sb0;
					b_req_q <= 1'sb0;
					b_write_q <= 1'sb0;
					b_addr_q <= 1'sb0;
					b_wdata_q <= 1'sb0;
				end
				else begin
					a_req_q <= a_req_d;
					a_write_q <= a_write_d;
					a_addr_q <= a_addr_d;
					a_wdata_q <= a_wdata_d;
					b_req_q <= b_req_d;
					b_write_q <= b_write_d;
					b_addr_q <= b_addr_d;
					b_wdata_q <= b_wdata_d;
				end
		end
		else begin : gen_dirconnect_input
			always @(*) a_req_q = a_req_d;
			always @(*) a_write_q = a_write_d;
			always @(*) a_addr_q = a_addr_d;
			always @(*) a_wdata_q = a_wdata_d;
			always @(*) b_req_q = b_req_d;
			always @(*) b_write_q = b_write_d;
			always @(*) b_addr_q = b_addr_d;
			always @(*) b_wdata_q = b_wdata_d;
		end
	endgenerate
	generate
		if (EnableOutputPipeline) begin : gen_regslice_output
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni) begin
					a_rvalid_q <= 1'sb0;
					a_rdata_q <= 1'sb0;
					a_rerror_q <= 1'sb0;
					b_rvalid_q <= 1'sb0;
					b_rdata_q <= 1'sb0;
					b_rerror_q <= 1'sb0;
				end
				else begin
					a_rvalid_q <= a_rvalid_d;
					a_rdata_q <= a_rdata_d;
					a_rerror_q <= a_rerror_d;
					b_rvalid_q <= b_rvalid_d;
					b_rdata_q <= b_rdata_d;
					b_rerror_q <= b_rerror_d;
				end
		end
		else begin : gen_dirconnect_output
			always @(*) a_rvalid_q = a_rvalid_d;
			always @(*) a_rdata_q = a_rdata_d;
			always @(*) a_rerror_q = a_rerror_d;
			always @(*) b_rvalid_q = b_rvalid_d;
			always @(*) b_rdata_q = b_rdata_d;
			always @(*) b_rerror_q = b_rerror_d;
		end
	endgenerate
endmodule
