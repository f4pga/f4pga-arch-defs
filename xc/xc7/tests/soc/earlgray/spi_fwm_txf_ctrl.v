module spi_fwm_txf_ctrl (
	clk_i,
	rst_ni,
	base_index_i,
	limit_index_i,
	abort,
	wptr,
	rptr,
	depth,
	fifo_valid,
	fifo_ready,
	fifo_wdata,
	sram_req,
	sram_write,
	sram_addr,
	sram_wdata,
	sram_gnt,
	sram_rvalid,
	sram_rdata,
	sram_error
);
	localparam [2:0] StIdle = 'h0;
	localparam [2:0] StRead = 'h1;
	localparam [2:0] StLatch = 'h2;
	localparam [2:0] StPush = 'h3;
	localparam [2:0] StUpdate = 'h4;
	parameter signed [31:0] FifoDw = 8;
	parameter signed [31:0] SramAw = 11;
	parameter signed [31:0] SramDw = 32;
	localparam signed [31:0] NumBytes = SramDw / FifoDw;
	localparam signed [31:0] SDW = $clog2(SramDw / FifoDw);
	localparam signed [31:0] PtrW = (SramAw + SDW) + 1;
	input clk_i;
	input rst_ni;
	input [SramAw - 1:0] base_index_i;
	input [SramAw - 1:0] limit_index_i;
	input abort;
	input [PtrW - 1:0] wptr;
	output reg [PtrW - 1:0] rptr;
	output reg [PtrW - 1:0] depth;
	output reg fifo_valid;
	input fifo_ready;
	output reg [FifoDw - 1:0] fifo_wdata;
	output reg sram_req;
	output wire sram_write;
	output wire [SramAw - 1:0] sram_addr;
	output wire [SramDw - 1:0] sram_wdata;
	input sram_gnt;
	input sram_rvalid;
	input [SramDw - 1:0] sram_rdata;
	input [1:0] sram_error;
	reg [SDW - 1:0] pos;
	wire [SramAw - 1:0] sramf_limit;
	reg [SramDw - 1:0] sram_rdata_q;
	wire [SramDw - 1:0] fifo_wdata_d;
	reg [PtrW - 1:0] wptr_q;
	wire sramf_empty;
	wire cnt_eq_end;
	reg sram_req_d;
	reg update_rptr;
	reg latch_wptr;
	reg cnt_rst;
	reg cnt_incr;
	reg txf_sel;
	reg [2:0] st_next;
	reg [2:0] st;
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			st <= StIdle;
		else
			st <= st_next;
	assign sramf_empty = rptr == wptr_q;
	assign sramf_limit = limit_index_i - base_index_i;
	always @(*) begin
		st_next = StIdle;
		sram_req_d = 1'b0;
		update_rptr = 1'b0;
		latch_wptr = 1'b0;
		fifo_valid = 1'b0;
		txf_sel = 1'b0;
		cnt_rst = 1'b0;
		cnt_incr = 1'b0;
		case (st)
			StIdle: begin
				latch_wptr = 1'b1;
				if (!sramf_empty && fifo_ready) begin
					st_next = StRead;
					sram_req_d = 1'b1;
				end
				else
					st_next = StIdle;
			end
			StRead:
				if (sram_gnt) begin
					st_next = StLatch;
					cnt_rst = 1'b1;
					sram_req_d = 1'b0;
				end
				else begin
					st_next = StRead;
					sram_req_d = 1'b1;
				end
			StLatch:
				if (sram_rvalid) begin
					st_next = StPush;
					fifo_valid = 1'b1;
					txf_sel = 1'b0;
					cnt_incr = 1'b1;
				end
				else
					st_next = StLatch;
			StPush:
				if (abort)
					st_next = StUpdate;
				else if (!fifo_ready)
					st_next = StPush;
				else if (fifo_ready && !cnt_eq_end) begin
					st_next = StPush;
					fifo_valid = 1'b1;
					txf_sel = 1'b1;
					cnt_incr = 1'b1;
				end
				else
					st_next = StUpdate;
			StUpdate: begin
				st_next = StIdle;
				update_rptr = 1'b1;
			end
			default: st_next = StIdle;
		endcase
	end
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			pos <= 1'sb0;
		else if (cnt_rst)
			pos <= rptr[SDW - 1:0];
		else if (cnt_incr)
			pos <= pos + 1'b1;
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			wptr_q <= 1'sb0;
		else if (latch_wptr)
			wptr_q <= wptr;
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			rptr <= 1'sb0;
		else if (update_rptr)
			if (pos == 1'sb0) begin
				if (rptr[PtrW - 2:SDW] != sramf_limit) begin
					rptr[PtrW - 1:SDW] <= rptr[PtrW - 1:SDW] + 1'b1;
					rptr[SDW - 1:0] <= 1'sb0;
				end
				else begin
					rptr[PtrW - 1] <= ~rptr[PtrW - 1];
					rptr[PtrW - 2:SDW] <= 1'sb0;
					rptr[SDW - 1:0] <= 1'sb0;
				end
			end
			else
				rptr[SDW - 1:0] <= pos;
	always @(*)
		if (wptr[PtrW - 1] == rptr[PtrW - 1])
			depth = {1'b0, wptr[PtrW - 2:0]} - {1'b0, rptr[PtrW - 2:0]};
		else
			depth = {1'b0, wptr[PtrW - 2:0]} + (({1'b0, sramf_limit, {SDW {1'b1}}} - {1'b0, rptr[PtrW - 2:0]}) + 1'b1);
	assign cnt_eq_end = (wptr_q[PtrW - 1:SDW] == rptr[PtrW - 1:SDW] ? wptr_q[SDW - 1:0] == pos : pos == 1'sb0);
	assign sram_addr = base_index_i + rptr[PtrW - 2:SDW];
	assign sram_write = 1'b0;
	assign sram_wdata = 1'sb0;
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			sram_req <= 1'b0;
		else
			sram_req <= sram_req_d;
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			sram_rdata_q <= 1'sb0;
		else if (sram_rvalid)
			sram_rdata_q <= sram_rdata;
	assign fifo_wdata_d = (txf_sel ? sram_rdata_q : sram_rdata);
	always @(*) begin
		fifo_wdata = 1'sb0;
		begin : sv2v_autoblock_146
			reg signed [31:0] i;
			for (i = 0; i < NumBytes; i = i + 1)
				if (pos == i)
					fifo_wdata = fifo_wdata_d[8 * i+:8];
		end
	end
endmodule
