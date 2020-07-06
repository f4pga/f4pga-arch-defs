module spi_fwm_rxf_ctrl (
	clk_i,
	rst_ni,
	base_index_i,
	limit_index_i,
	timer_v,
	rptr,
	wptr,
	depth,
	full,
	fifo_valid,
	fifo_ready,
	fifo_rdata,
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
	localparam [2:0] StPop = 'h1;
	localparam [2:0] StWait = 'h2;
	localparam [2:0] StRead = 'h3;
	localparam [2:0] StModify = 'h4;
	localparam [2:0] StWrite = 'h5;
	localparam [2:0] StUpdate = 'h6;
	parameter [31:0] FifoDw = 8;
	parameter [31:0] SramAw = 11;
	parameter [31:0] SramDw = 32;
	localparam [31:0] NumBytes = SramDw / FifoDw;
	localparam [31:0] SDW = $clog2(SramDw / FifoDw);
	localparam [31:0] PtrW = (SramAw + SDW) + 1;
	input clk_i;
	input rst_ni;
	input [SramAw - 1:0] base_index_i;
	input [SramAw - 1:0] limit_index_i;
	input [7:0] timer_v;
	input [PtrW - 1:0] rptr;
	output reg [PtrW - 1:0] wptr;
	output reg [PtrW - 1:0] depth;
	output wire full;
	input fifo_valid;
	output reg fifo_ready;
	input [FifoDw - 1:0] fifo_rdata;
	output reg sram_req;
	output reg sram_write;
	output wire [SramAw - 1:0] sram_addr;
	output reg [SramDw - 1:0] sram_wdata;
	input sram_gnt;
	input sram_rvalid;
	input [SramDw - 1:0] sram_rdata;
	input [1:0] sram_error;
	reg [NumBytes - 1:0] byte_enable;
	reg [SDW - 1:0] pos;
	reg [7:0] cur_timer;
	wire [SramAw - 1:0] sramf_limit;
	wire sramf_full;
	wire full_sramwidth;
	wire timer_expired;
	reg update_wdata;
	reg clr_byte_enable;
	reg sram_req_d;
	reg sram_write_d;
	reg sram_wdata_sel;
	reg timer_rst;
	reg update_wptr;
	reg [2:0] st_next;
	reg [2:0] st;
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			st <= StIdle;
		else
			st <= st_next;
	wire [PtrW - 1:0] ptr_cmp;
	assign ptr_cmp = rptr ^ wptr;
	assign sramf_full = (ptr_cmp[PtrW - 1] == 1'b1) && (ptr_cmp[PtrW - 2:SDW] == 1'sb0);
	assign full = sramf_full;
	assign sramf_limit = limit_index_i - base_index_i;
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			wptr <= 1'sb0;
		else if (update_wptr)
			if (byte_enable == 1'sb0) begin
				if (wptr[PtrW - 2:SDW] == sramf_limit) begin
					wptr[PtrW - 1] <= ~wptr[PtrW - 1];
					wptr[PtrW - 2:0] <= 1'sb0;
				end
				else begin
					wptr[PtrW - 2:SDW] <= wptr[PtrW - 2:SDW] + 1'b1;
					wptr[SDW - 1:0] <= 1'sb0;
				end
			end
			else
				wptr[SDW - 1:0] <= pos;
	assign full_sramwidth = 1'b1 == &byte_enable;
	always @(*)
		if (wptr[PtrW - 1] == rptr[PtrW - 1])
			depth = {1'b0, wptr[PtrW - 2:0]} - {1'b0, rptr[PtrW - 2:0]};
		else
			depth = {1'b0, wptr[PtrW - 2:0]} + (({1'b0, sramf_limit, {SDW {1'b1}}} - {1'b0, rptr[PtrW - 2:0]}) + 1'b1);
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			cur_timer <= 1'sb1;
		else if (timer_rst)
			cur_timer <= timer_v;
		else if (st == StWait)
			if (cur_timer != 1'sb0)
				cur_timer <= cur_timer - 1'b1;
	assign timer_expired = cur_timer == 1'sb0;
	assign sram_addr = base_index_i + wptr[PtrW - 2:SDW];
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni) begin
			byte_enable <= 1'sb0;
			pos <= 1'sb0;
		end
		else if (update_wdata) begin
			byte_enable[pos] <= 1'b1;
			if (pos == sv2v_cast_EE4C7(NumBytes - 1))
				pos <= 1'sb0;
			else
				pos <= pos + 1'b1;
		end
		else if (clr_byte_enable) begin
			byte_enable <= 1'sb0;
			pos <= 1'sb0;
		end
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			sram_wdata <= 1'sb0;
		else if (update_wdata)
			sram_wdata[8 * pos+:8] <= fifo_rdata;
		else if (sram_wdata_sel == 1'b1) begin : sv2v_autoblock_146
			reg signed [31:0] i;
			for (i = 0; i < NumBytes; i = i + 1)
				if (!byte_enable[i])
					sram_wdata[8 * i+:8] <= sram_rdata[8 * i+:8];
		end
	always @(*) begin
		fifo_ready = 1'b0;
		update_wdata = 1'b0;
		clr_byte_enable = 1'b0;
		sram_req_d = 1'b0;
		sram_write_d = 1'b0;
		sram_wdata_sel = 1'b0;
		timer_rst = 1'b0;
		update_wptr = 1'b0;
		case (st)
			StIdle:
				if (fifo_valid && !sramf_full) begin
					st_next = StPop;
					fifo_ready = 1'b1;
					update_wdata = 1'b1;
				end
				else
					st_next = StIdle;
			StPop:
				if (fifo_valid && !full_sramwidth) begin
					st_next = StPop;
					fifo_ready = 1'b1;
					update_wdata = 1'b1;
				end
				else if (full_sramwidth) begin
					st_next = StWrite;
					clr_byte_enable = 1'b1;
					sram_req_d = 1'b1;
					sram_write_d = 1'b1;
				end
				else begin
					st_next = StWait;
					timer_rst = 1'b1;
				end
			StWait:
				if (fifo_valid) begin
					st_next = StPop;
					fifo_ready = 1'b1;
					update_wdata = 1'b1;
				end
				else if (!fifo_valid && timer_expired) begin
					st_next = StRead;
					sram_req_d = 1'b1;
					sram_write_d = 1'b0;
				end
				else
					st_next = StWait;
			StRead:
				if (sram_gnt)
					st_next = StModify;
				else begin
					st_next = StRead;
					sram_req_d = 1'b1;
					sram_write_d = 1'b0;
				end
			StModify:
				if (sram_rvalid) begin
					st_next = StWrite;
					sram_req_d = 1'b1;
					sram_write_d = 1'b1;
					sram_wdata_sel = 1'b1;
				end
				else
					st_next = StModify;
			StWrite:
				if (sram_gnt)
					st_next = StUpdate;
				else begin
					st_next = StWrite;
					sram_req_d = 1'b1;
					sram_write_d = 1'b1;
				end
			StUpdate: begin
				st_next = StIdle;
				update_wptr = 1'b1;
			end
			default: st_next = StIdle;
		endcase
	end
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni) begin
			sram_req <= 1'b0;
			sram_write <= 1'b0;
		end
		else begin
			sram_req <= sram_req_d;
			sram_write <= sram_write_d;
		end
	function automatic [$clog2(SramDw / FifoDw) - 1:0] sv2v_cast_EE4C7;
		input reg [$clog2(SramDw / FifoDw) - 1:0] inp;
		sv2v_cast_EE4C7 = inp;
	endfunction
endmodule
