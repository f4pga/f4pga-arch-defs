`include "../dsp_combinational/dsp_combinational.sim.v"

/* DSP Block with register on the output */
module dsp_out_registered (clk, a, b, m, out);
	localparam DATA_WIDTH = 64;

	input wire clk;
	input wire [DATA_WIDTH/2-1:0] a;
	input wire [DATA_WIDTH/2-1:0] b;
	input wire m;
	output wire [DATA_WIDTH-1:0] out;

	wire [DATA_WIDTH-1:0] c_out;
	dsp_combinational comb (.a(a), .b(b), .m(m), .out(c_out));

	reg [DATA_WIDTH-1:0] q_out;
	always @(posedge clk) begin
		q_out <= c_out;
	end

	assign out = q_out;
endmodule
