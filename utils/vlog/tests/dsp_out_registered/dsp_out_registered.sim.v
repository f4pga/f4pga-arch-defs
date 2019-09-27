`include "../fig42-dff/dff.sim.v"
`include "../dsp_combinational/dsp_combinational.sim.v"

/* DSP Block with register on the output */
module DSP_OUT_REGISTERED (clk, a, b, m, out);
	localparam DATA_WIDTH = 4;

	input wire clk;
	input wire [DATA_WIDTH/2-1:0] a;
	input wire [DATA_WIDTH/2-1:0] b;
	input wire m;
	output wire [DATA_WIDTH-1:0] out;

	/* Combinational logic */
	(* pack="DSP-DFF" *)
	wire [DATA_WIDTH-1:0] c_out;
	DSP_COMBINATIONAL comb (.a(a), .b(b), .m(m), .out(c_out));

	/* Output register on clk */
	genvar j;
	for (j=0; j<DATA_WIDTH; j=j+1) begin: output_dffs_gen
		DFF q_out_ff(.D(c_out[j]), .Q(out[j]), .CLK(clk));
	end
endmodule
