module prim_flash (
	clk_i,
	rst_ni,
	req_i,
	host_req_i,
	host_addr_i,
	rd_i,
	prog_i,
	pg_erase_i,
	bk_erase_i,
	addr_i,
	prog_data_i,
	host_req_rdy_o,
	host_req_done_o,
	rd_done_o,
	prog_done_o,
	erase_done_o,
	rd_data_o,
	init_busy_o
);
	localparam prim_pkg_ImplXilinx = 1;
	parameter integer Impl = prim_pkg_ImplXilinx;
	parameter signed [31:0] PagesPerBank = 256;
	parameter signed [31:0] WordsPerPage = 256;
	parameter signed [31:0] DataWidth = 32;
	parameter signed [31:0] PageW = $clog2(PagesPerBank);
	parameter signed [31:0] WordW = $clog2(WordsPerPage);
	parameter signed [31:0] AddrW = PageW + WordW;
	input clk_i;
	input rst_ni;
	input req_i;
	input host_req_i;
	input [AddrW - 1:0] host_addr_i;
	input rd_i;
	input prog_i;
	input pg_erase_i;
	input bk_erase_i;
	input [AddrW - 1:0] addr_i;
	input [DataWidth - 1:0] prog_data_i;
	output wire host_req_rdy_o;
	output wire host_req_done_o;
	output wire rd_done_o;
	output wire prog_done_o;
	output wire erase_done_o;
	output wire [DataWidth - 1:0] rd_data_o;
	output wire init_busy_o;
	localparam ImplGeneric = 0;
	localparam ImplXilinx = 1;
	generate
		if ((Impl == ImplGeneric) || (Impl == ImplXilinx)) begin : gen_flash
			prim_generic_flash #(
				.PagesPerBank(PagesPerBank),
				.WordsPerPage(WordsPerPage),
				.DataWidth(DataWidth)
			) u_impl_generic(
				.clk_i(clk_i),
				.rst_ni(rst_ni),
				.req_i(req_i),
				.host_req_i(host_req_i),
				.host_addr_i(host_addr_i),
				.rd_i(rd_i),
				.prog_i(prog_i),
				.pg_erase_i(pg_erase_i),
				.bk_erase_i(bk_erase_i),
				.addr_i(addr_i),
				.prog_data_i(prog_data_i),
				.host_req_rdy_o(host_req_rdy_o),
				.host_req_done_o(host_req_done_o),
				.rd_done_o(rd_done_o),
				.prog_done_o(prog_done_o),
				.erase_done_o(erase_done_o),
				.rd_data_o(rd_data_o),
				.init_busy_o(init_busy_o)
			);
		end
	endgenerate
endmodule
