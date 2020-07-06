module prim_flop_2sync (
	clk_i,
	rst_ni,
	d,
	q
);
	parameter signed [31:0] Width = 16;
	parameter ResetValue = 0;
	input clk_i;
	input rst_ni;
	input [Width - 1:0] d;
	output reg [Width - 1:0] q;
	reg [Width - 1:0] intq;
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni) begin
			intq <= {Width {ResetValue}};
			q <= {Width {ResetValue}};
		end
		else begin
			intq <= d;
			q <= intq;
		end
endmodule
