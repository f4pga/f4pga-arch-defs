`include "../dsp_combinational/dsp_comb.sim.v"

module dsp_regi (clk, a, b, m, out);
	localparam DATA_WIDTH = 64;

	input wire clk;
	input wire [DATA_WIDTH/2-1:0] a;
	input wire [DATA_WIDTH/2-1:0] b;
	input wire m;
	output wire [DATA_WIDTH-1:0] out;

	reg [DATA_WIDTH/2-1:0] q_a;
	reg [DATA_WIDTH/2-1:0] q_b;
	reg q_m;
	always @(posedge clk) begin
		q_a <= a;
		q_b <= b;
		q_m <= m;
	end

	dsp_comb comb (.a(q_a), .b(q_b), .m(q_m), .out(out));
endmodule
