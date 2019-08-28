`include "../fig42-dff/dff.sim.v"
`include "../dsp_combinational/dsp_combinational.sim.v"

/* DSP Block with register on only some inputs */
module DSP_PARTIAL_REGISTERED (clk, a, b, m, out);
	localparam DATA_WIDTH = 64;

	input wire clk;
	input wire [DATA_WIDTH/2-1:0] a;
	input wire [DATA_WIDTH/2-1:0] b;
	input wire m;
	output wire [DATA_WIDTH-1:0] out;

	/* Input registers */
	(* pack="DFF-DSP" *)
	wire [DATA_WIDTH/2-1:0] q_a;
	(* pack="DFF-DSP" *)
	wire [DATA_WIDTH/2-1:0] q_b;

	genvar i;
	for (i=0; i<DATA_WIDTH/2; i=i+1) begin: dffs_gen
		DFF q_a_ff(.D(a[i]), .Q(q_a[i]), .CLK(clk));
		DFF q_b_ff(.D(b[i]), .Q(q_b[i]), .CLK(clk));
	end

	/* Combinational Logic */
	DSP_COMBINATIONAL comb (.a(q_a), .b(q_b), .m(m), .out(out));
endmodule
