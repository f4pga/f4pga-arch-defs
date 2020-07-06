module prim_packer (
	clk_i,
	rst_ni,
	valid_i,
	data_i,
	mask_i,
	ready_o,
	valid_o,
	data_o,
	mask_o,
	ready_i,
	flush_i,
	flush_done_o
);
	localparam [0:0] FlushIdle = 0;
	localparam [0:0] FlushWait = 1;
	parameter signed [31:0] InW = 32;
	parameter signed [31:0] OutW = 32;
	input clk_i;
	input rst_ni;
	input valid_i;
	input [InW - 1:0] data_i;
	input [InW - 1:0] mask_i;
	output ready_o;
	output wire valid_o;
	output wire [OutW - 1:0] data_o;
	output wire [OutW - 1:0] mask_o;
	input ready_i;
	input flush_i;
	output wire flush_done_o;
	localparam signed [31:0] Width = InW + OutW;
	localparam signed [31:0] PtrW = $clog2((InW + OutW) + 1);
	localparam signed [31:0] MaxW = (InW > OutW ? InW : OutW);
	wire valid_next;
	wire ready_next;
	reg [MaxW - 1:0] stored_data;
	reg [MaxW - 1:0] stored_mask;
	wire [Width - 1:0] concat_data;
	wire [Width - 1:0] concat_mask;
	wire [Width - 1:0] shiftl_data;
	wire [Width - 1:0] shiftl_mask;
	reg [PtrW - 1:0] pos;
	wire [PtrW - 1:0] pos_next;
	reg [$clog2(InW) - 1:0] lod_idx;
	reg [$clog2(InW + 1) - 1:0] inmask_ones;
	wire ack_in;
	wire ack_out;
	reg flush_ready;
	always @(*) begin
		inmask_ones = 1'sb0;
		begin : sv2v_autoblock_146
			reg signed [31:0] i;
			for (i = 0; i < InW; i = i + 1)
				inmask_ones = inmask_ones + mask_i[i];
		end
	end
	assign pos_next = (valid_i ? pos + sv2v_cast_64F7A(inmask_ones) : pos);
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			pos <= 1'sb0;
		else if (flush_ready)
			pos <= 1'sb0;
		else if (ack_out)
			pos <= pos_next - OutW;
		else if (ack_in)
			pos <= pos_next;
	always @(*) begin
		lod_idx = 0;
		begin : sv2v_autoblock_147
			reg signed [31:0] i;
			for (i = InW - 1; i >= 0; i = i - 1)
				if (mask_i[i] == 1'b1)
					lod_idx = i;
		end
	end
	assign ack_in = valid_i & ready_o;
	assign ack_out = valid_o & ready_i;
	assign shiftl_data = (valid_i ? sv2v_cast_FCDDD(data_i >> lod_idx) << pos : 1'sb0);
	assign shiftl_mask = (valid_i ? sv2v_cast_FCDDD(mask_i >> lod_idx) << pos : 1'sb0);
	assign concat_data = {{Width - MaxW {1'b0}}, stored_data & stored_mask} | (shiftl_data & shiftl_mask);
	assign concat_mask = {{Width - MaxW {1'b0}}, stored_mask} | shiftl_mask;
	wire [MaxW - 1:0] stored_data_next;
	wire [MaxW - 1:0] stored_mask_next;
	generate
		if (InW >= OutW) begin : gen_stored_in
			assign stored_data_next = concat_data[OutW+:InW];
			assign stored_mask_next = concat_mask[OutW+:InW];
		end
		else begin : gen_stored_out
			assign stored_data_next = {{OutW - InW {1'b0}}, concat_data[OutW+:InW]};
			assign stored_mask_next = {{OutW - InW {1'b0}}, concat_mask[OutW+:InW]};
		end
	endgenerate
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni) begin
			stored_data <= 1'sb0;
			stored_mask <= 1'sb0;
		end
		else if (flush_ready) begin
			stored_data <= 1'sb0;
			stored_mask <= 1'sb0;
		end
		else if (ack_out) begin
			stored_data <= stored_data_next;
			stored_mask <= stored_mask_next;
		end
		else if (ack_in) begin
			stored_data <= concat_data[MaxW - 1:0];
			stored_mask <= concat_mask[MaxW - 1:0];
		end
	reg [0:0] flush_st;
	reg [0:0] flush_st_next;
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			flush_st <= FlushIdle;
		else
			flush_st <= flush_st_next;
	always @(*) begin
		flush_st_next = FlushIdle;
		flush_ready = 1'b0;
		case (flush_st)
			FlushIdle:
				if (flush_i && !ready_i) begin
					flush_st_next = FlushWait;
					flush_ready = 1'b0;
				end
				else if (flush_i && ready_i) begin
					flush_st_next = FlushIdle;
					flush_ready = 1'b1;
				end
				else
					flush_st_next = FlushIdle;
			FlushWait:
				if (ready_i) begin
					flush_st_next = FlushIdle;
					flush_ready = 1'b1;
				end
				else begin
					flush_st_next = FlushWait;
					flush_ready = 1'b0;
				end
			default: begin
				flush_st_next = FlushIdle;
				flush_ready = 1'b0;
			end
		endcase
	end
	assign flush_done_o = flush_ready;
	assign valid_next = (pos_next >= OutW ? 1'b 1 : flush_ready & (pos != 1'sb0));
	assign ready_next = (ack_out ? 1'b1 : pos_next <= MaxW);
	assign valid_o = valid_next;
	assign data_o = concat_data[OutW - 1:0];
	assign mask_o = concat_mask[OutW - 1:0];
	assign ready_o = ready_next;
	function automatic [$clog2((InW + OutW) + 1) - 1:0] sv2v_cast_64F7A;
		input reg [$clog2((InW + OutW) + 1) - 1:0] inp;
		sv2v_cast_64F7A = inp;
	endfunction
	function automatic [(InW + OutW) - 1:0] sv2v_cast_FCDDD;
		input reg [(InW + OutW) - 1:0] inp;
		sv2v_cast_FCDDD = inp;
	endfunction
endmodule
