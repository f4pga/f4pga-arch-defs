module prim_generic_flash (
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
	localparam [2:0] StReset = 'h0;
	localparam [2:0] StInit = 'h1;
	localparam [2:0] StIdle = 'h2;
	localparam [2:0] StHostRead = 'h3;
	localparam [2:0] StRead = 'h4;
	localparam [2:0] StProg = 'h5;
	localparam [2:0] StErase = 'h6;
	parameter signed [31:0] PagesPerBank = 256;
	parameter signed [31:0] WordsPerPage = 256;
	parameter signed [31:0] DataWidth = 32;
	parameter SkipInit = 1;
	localparam signed [31:0] PageW = $clog2(PagesPerBank);
	localparam signed [31:0] WordW = $clog2(WordsPerPage);
	localparam signed [31:0] AddrW = PageW + WordW;
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
	output reg host_req_rdy_o;
	output reg host_req_done_o;
	output reg rd_done_o;
	output reg prog_done_o;
	output reg erase_done_o;
	output wire [DataWidth - 1:0] rd_data_o;
	output reg init_busy_o;
	localparam signed [31:0] ReadCycles = 1;
	localparam signed [31:0] ProgCycles = 50;
	localparam signed [31:0] PgEraseCycles = 200;
	localparam signed [31:0] BkEraseCycles = 2000;
	localparam signed [31:0] WordsPerBank = PagesPerBank * WordsPerPage;
	reg [2:0] st_next;
	reg [2:0] st;
	reg [31:0] time_cnt;
	reg [31:0] index_cnt;
	reg time_cnt_inc;
	reg time_cnt_clr;
	reg time_cnt_set1;
	reg index_cnt_inc;
	reg index_cnt_clr;
	reg [31:0] index_limit;
	reg [31:0] index_limit_next;
	reg [31:0] time_limit;
	reg [31:0] time_limit_next;
	reg prog_pend;
	reg prog_pend_next;
	reg mem_req;
	reg mem_wr;
	reg [AddrW - 1:0] mem_addr;
	reg [DataWidth - 1:0] held_data;
	reg [DataWidth - 1:0] mem_wdata;
	reg hold_rd_cmd;
	reg [AddrW - 1:0] held_rd_addr;
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			st <= StReset;
		else
			st <= st_next;
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			held_rd_addr <= 1'sb0;
		else if (hold_rd_cmd)
			held_rd_addr <= host_addr_i;
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni) begin
			time_cnt <= 32'h0;
			index_cnt <= 32'h0;
			time_limit <= 32'h0;
			index_limit <= 32'h0;
			held_data <= 'h0;
			prog_pend <= 1'h0;
		end
		else begin
			time_limit <= time_limit_next;
			index_limit <= index_limit_next;
			prog_pend <= prog_pend_next;
			if (time_cnt_inc)
				time_cnt <= time_cnt + 1'b1;
			else if (time_cnt_set1)
				time_cnt <= 32'h1;
			else if (time_cnt_clr)
				time_cnt <= 32'h0;
			if (index_cnt_inc)
				index_cnt <= index_cnt + 1'b1;
			else if (index_cnt_clr)
				index_cnt <= 32'h0;
			if (prog_pend)
				held_data <= rd_data_o;
		end
	always @(*) begin
		st_next = st;
		index_limit_next = index_limit;
		time_limit_next = time_limit;
		prog_pend_next = prog_pend;
		mem_req = 'h0;
		mem_wr = 'h0;
		mem_addr = 'h0;
		mem_wdata = 'h0;
		time_cnt_inc = 1'h0;
		time_cnt_clr = 1'h0;
		time_cnt_set1 = 1'h0;
		index_cnt_inc = 1'h0;
		index_cnt_clr = 1'h0;
		rd_done_o = 1'h0;
		prog_done_o = 1'h0;
		erase_done_o = 1'h0;
		init_busy_o = 1'h0;
		host_req_rdy_o = 1'h1;
		host_req_done_o = 1'h0;
		hold_rd_cmd = 1'h0;
		case (st)
			StReset: begin
				host_req_rdy_o = 1'b0;
				init_busy_o = 1'h1;
				st_next = StInit;
			end
			StInit: begin
				host_req_rdy_o = 1'b0;
				init_busy_o = 1'h1;
				if ((index_cnt < WordsPerBank) && !SkipInit) begin
					st_next = StInit;
					index_cnt_inc = 1'b1;
					mem_req = 1'h0;
					mem_wr = 1'h0;
					mem_addr = index_cnt[AddrW - 1:0];
					mem_wdata = {DataWidth {1'b1}};
				end
				else begin
					st_next = StIdle;
					index_cnt_clr = 1'b1;
				end
			end
			StIdle:
				if (host_req_i) begin
					hold_rd_cmd = 1'b1;
					mem_addr = host_addr_i;
					mem_req = 1'b1;
					time_cnt_inc = 1'b1;
					st_next = StHostRead;
				end
				else if (req_i && rd_i)
					st_next = StRead;
				else if (req_i && prog_i) begin
					st_next = StRead;
					prog_pend_next = 1'b1;
				end
				else if (req_i && pg_erase_i) begin
					st_next = StErase;
					index_limit_next = WordsPerPage;
					time_limit_next = PgEraseCycles;
				end
				else if (req_i && bk_erase_i) begin
					st_next = StErase;
					index_limit_next = WordsPerBank;
					time_limit_next = BkEraseCycles;
				end
			StHostRead: begin
				mem_addr = held_rd_addr;
				if (time_cnt < ReadCycles) begin
					mem_req = 1'b1;
					time_cnt_inc = 1'b1;
					host_req_rdy_o = 1'b0;
				end
				else begin
					host_req_done_o = 1'b1;
					if (host_req_i) begin
						hold_rd_cmd = 1'b1;
						mem_addr = host_addr_i;
						mem_req = 1'b1;
						time_cnt_set1 = 1'b1;
						st_next = StHostRead;
					end
					else begin
						time_cnt_clr = 1'b1;
						st_next = StIdle;
					end
				end
			end
			StRead: begin
				host_req_rdy_o = 1'b0;
				mem_addr = addr_i;
				if (time_cnt < ReadCycles) begin
					mem_req = 1'b1;
					time_cnt_inc = 1'b1;
				end
				else begin
					prog_pend_next = 1'b0;
					rd_done_o = 1'b1;
					time_cnt_clr = 1'b1;
					st_next = (prog_pend ? StProg : StIdle);
				end
			end
			StProg: begin
				host_req_rdy_o = 1'b0;
				mem_addr = addr_i;
				mem_wdata = prog_data_i & held_data;
				if (time_cnt < ProgCycles) begin
					mem_req = 1'b1;
					mem_wr = 1'b1;
					time_cnt_inc = 1'b1;
				end
				else begin
					st_next = StIdle;
					prog_done_o = 1'b1;
					time_cnt_clr = 1'b1;
				end
			end
			StErase: begin
				host_req_rdy_o = 1'b0;
				if ((index_cnt < index_limit) || (time_cnt < time_limit)) begin
					mem_req = 1'b1;
					mem_wr = 1'b1;
					mem_wdata = {DataWidth {1'b1}};
					mem_addr = addr_i + index_cnt[AddrW - 1:0];
					time_cnt_inc = time_cnt < time_limit;
					index_cnt_inc = index_cnt < index_limit;
				end
				else begin
					st_next = StIdle;
					erase_done_o = 1'b1;
					time_cnt_clr = 1'b1;
					index_cnt_clr = 1'b1;
				end
			end
			default: begin
				host_req_rdy_o = 1'b0;
				st_next = StIdle;
			end
		endcase
	end
	prim_ram_1p #(
		.Width(DataWidth),
		.Depth(WordsPerBank),
		.DataBitsPerMask(DataWidth)
	) u_mem(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.req_i(mem_req),
		.write_i(mem_wr),
		.addr_i(mem_addr),
		.wdata_i(mem_wdata),
		.wmask_i({DataWidth {1'b1}}),
		.rvalid_o(),
		.rdata_o(rd_data_o)
	);
endmodule
