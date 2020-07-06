module prim_fifo_async (
	clk_wr_i,
	rst_wr_ni,
	wvalid,
	wready,
	wdata,
	wdepth,
	clk_rd_i,
	rst_rd_ni,
	rvalid,
	rready,
	rdata,
	rdepth
);
	parameter [31:0] Width = 16;
	parameter [31:0] Depth = 3;
	localparam [31:0] DepthW = $clog2(Depth + 1);
	input clk_wr_i;
	input rst_wr_ni;
	input wvalid;
	output wready;
	input [Width - 1:0] wdata;
	output [DepthW - 1:0] wdepth;
	input clk_rd_i;
	input rst_rd_ni;
	output rvalid;
	input rready;
	output [Width - 1:0] rdata;
	output [DepthW - 1:0] rdepth;
	localparam [31:0] PTRV_W = $clog2(Depth);
	localparam [PTRV_W - 1:0] DepthMinus1 = sv2v_cast_473D1(Depth - 1);
	localparam [31:0] PTR_WIDTH = PTRV_W + 1;
	reg [PTR_WIDTH - 1:0] fifo_wptr;
	reg [PTR_WIDTH - 1:0] fifo_rptr;
	wire [PTR_WIDTH - 1:0] fifo_wptr_sync_combi;
	reg [PTR_WIDTH - 1:0] fifo_rptr_sync;
	wire [PTR_WIDTH - 1:0] fifo_wptr_gray_sync;
	wire [PTR_WIDTH - 1:0] fifo_rptr_gray_sync;
	reg [PTR_WIDTH - 1:0] fifo_wptr_gray;
	reg [PTR_WIDTH - 1:0] fifo_rptr_gray;
	wire fifo_incr_wptr;
	wire fifo_incr_rptr;
	wire empty;
	wire full_wclk;
	wire full_rclk;
	assign wready = !full_wclk;
	assign rvalid = !empty;
	assign fifo_incr_wptr = wvalid & wready;
	assign fifo_incr_rptr = rvalid & rready;
	always @(posedge clk_wr_i or negedge rst_wr_ni)
		if (!rst_wr_ni)
			fifo_wptr <= {PTR_WIDTH {1'b0}};
		else if (fifo_incr_wptr)
			if (fifo_wptr[PTR_WIDTH - 2:0] == DepthMinus1)
				fifo_wptr <= {~fifo_wptr[PTR_WIDTH - 1], {PTR_WIDTH - 1 {1'b0}}};
			else
				fifo_wptr <= fifo_wptr + {{PTR_WIDTH - 1 {1'b0}}, 1'b1};
	always @(posedge clk_wr_i or negedge rst_wr_ni)
		if (!rst_wr_ni)
			fifo_wptr_gray <= {PTR_WIDTH {1'b0}};
		else if (fifo_incr_wptr)
			if (fifo_wptr[PTR_WIDTH - 2:0] == DepthMinus1)
				fifo_wptr_gray <= dec2gray({~fifo_wptr[PTR_WIDTH - 1], {PTR_WIDTH - 1 {1'b0}}});
			else
				fifo_wptr_gray <= dec2gray(fifo_wptr + {{PTR_WIDTH - 1 {1'b0}}, 1'b1});
	prim_flop_2sync #(.Width(PTR_WIDTH)) sync_wptr(
		.clk_i(clk_rd_i),
		.rst_ni(rst_rd_ni),
		.d(fifo_wptr_gray),
		.q(fifo_wptr_gray_sync)
	);
	assign fifo_wptr_sync_combi = gray2dec(fifo_wptr_gray_sync);
	always @(posedge clk_rd_i or negedge rst_rd_ni)
		if (!rst_rd_ni)
			fifo_rptr <= {PTR_WIDTH {1'b0}};
		else if (fifo_incr_rptr)
			if (fifo_rptr[PTR_WIDTH - 2:0] == DepthMinus1)
				fifo_rptr <= {~fifo_rptr[PTR_WIDTH - 1], {PTR_WIDTH - 1 {1'b0}}};
			else
				fifo_rptr <= fifo_rptr + {{PTR_WIDTH - 1 {1'b0}}, 1'b1};
	always @(posedge clk_rd_i or negedge rst_rd_ni)
		if (!rst_rd_ni)
			fifo_rptr_gray <= {PTR_WIDTH {1'b0}};
		else if (fifo_incr_rptr)
			if (fifo_rptr[PTR_WIDTH - 2:0] == DepthMinus1)
				fifo_rptr_gray <= dec2gray({~fifo_rptr[PTR_WIDTH - 1], {PTR_WIDTH - 1 {1'b0}}});
			else
				fifo_rptr_gray <= dec2gray(fifo_rptr + {{PTR_WIDTH - 1 {1'b0}}, 1'b1});
	prim_flop_2sync #(.Width(PTR_WIDTH)) sync_rptr(
		.clk_i(clk_wr_i),
		.rst_ni(rst_wr_ni),
		.d(fifo_rptr_gray),
		.q(fifo_rptr_gray_sync)
	);
	always @(posedge clk_wr_i or negedge rst_wr_ni)
		if (!rst_wr_ni)
			fifo_rptr_sync <= {PTR_WIDTH {1'b0}};
		else
			fifo_rptr_sync <= gray2dec(fifo_rptr_gray_sync);
	assign full_wclk = fifo_wptr == (fifo_rptr_sync ^ {1'b1, {PTR_WIDTH - 1 {1'b0}}});
	assign full_rclk = fifo_wptr_sync_combi == (fifo_rptr ^ {1'b1, {PTR_WIDTH - 1 {1'b0}}});
	wire wptr_msb;
	wire rptr_sync_msb;
	wire [PTRV_W - 1:0] wptr_value;
	wire [PTRV_W - 1:0] rptr_sync_value;
	assign wptr_msb = fifo_wptr[PTR_WIDTH - 1];
	assign rptr_sync_msb = fifo_rptr_sync[PTR_WIDTH - 1];
	assign wptr_value = fifo_wptr[0+:PTRV_W];
	assign rptr_sync_value = fifo_rptr_sync[0+:PTRV_W];
	assign wdepth = (full_wclk ? sv2v_cast_5B341(Depth) : (wptr_msb == rptr_sync_msb ? sv2v_cast_5B341(wptr_value) - sv2v_cast_5B341(rptr_sync_value) : (sv2v_cast_5B341(Depth) - sv2v_cast_5B341(rptr_sync_value)) + sv2v_cast_5B341(wptr_value)));
	assign empty = fifo_wptr_sync_combi == fifo_rptr;
	wire rptr_msb;
	wire wptr_sync_msb;
	wire [PTRV_W - 1:0] rptr_value;
	wire [PTRV_W - 1:0] wptr_sync_value;
	assign wptr_sync_msb = fifo_wptr_sync_combi[PTR_WIDTH - 1];
	assign rptr_msb = fifo_rptr[PTR_WIDTH - 1];
	assign wptr_sync_value = fifo_wptr_sync_combi[0+:PTRV_W];
	assign rptr_value = fifo_rptr[0+:PTRV_W];
	assign rdepth = (full_rclk ? sv2v_cast_5B341(Depth) : (wptr_sync_msb == rptr_msb ? sv2v_cast_5B341(wptr_sync_value) - sv2v_cast_5B341(rptr_value) : (sv2v_cast_5B341(Depth) - sv2v_cast_5B341(rptr_value)) + sv2v_cast_5B341(wptr_sync_value)));
	reg [Width - 1:0] storage [0:Depth - 1];
	always @(posedge clk_wr_i)
		if (fifo_incr_wptr)
			storage[fifo_wptr[PTR_WIDTH - 2:0]] <= wdata;
	assign rdata = storage[fifo_rptr[PTR_WIDTH - 2:0]];
	function automatic [PTR_WIDTH - 1:0] dec2gray;
		input reg [PTR_WIDTH - 1:0] decval;
		reg [PTR_WIDTH - 1:0] decval_sub;
		reg [PTR_WIDTH - 2:0] decval_in;
		reg unused_decval_msb;
		begin
			decval_sub = (Depth - {1'b0, decval[PTR_WIDTH - 2:0]}) - 1'b1;
			{unused_decval_msb, decval_in} = (decval[PTR_WIDTH - 1] ? decval_sub : decval);
			dec2gray = {decval[PTR_WIDTH - 1], {1'b0, decval_in[PTR_WIDTH - 2:1]} ^ decval_in[PTR_WIDTH - 2:0]};
		end
	endfunction
	function automatic [PTR_WIDTH - 1:0] gray2dec;
		input reg [PTR_WIDTH - 1:0] grayval;
		reg [PTR_WIDTH - 2:0] dec_tmp;
		reg [PTR_WIDTH - 2:0] dec_tmp_sub;
		reg unused_decsub_msb;
		begin
			dec_tmp[PTR_WIDTH - 2] = grayval[PTR_WIDTH - 2];
			begin : sv2v_autoblock_146
				reg signed [31:0] i;
				for (i = PTR_WIDTH - 3; i >= 0; i = i - 1)
					dec_tmp[i] = dec_tmp[i + 1] ^ grayval[i];
			end
			{unused_decsub_msb, dec_tmp_sub} = (Depth - {1'b0, dec_tmp}) - 1'b1;
			if (grayval[PTR_WIDTH - 1])
				gray2dec = {1'b1, dec_tmp_sub};
			else
				gray2dec = {1'b0, dec_tmp};
		end
	endfunction
	function automatic [$clog2(Depth + 1) - 1:0] sv2v_cast_5B341;
		input reg [$clog2(Depth + 1) - 1:0] inp;
		sv2v_cast_5B341 = inp;
	endfunction
	function automatic [$clog2(Depth) - 1:0] sv2v_cast_473D1;
		input reg [$clog2(Depth) - 1:0] inp;
		sv2v_cast_473D1 = inp;
	endfunction
endmodule
