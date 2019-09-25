`include "../fig42-dff/dff.sim.v"
`include "../dsp_combinational/dsp_combinational.sim.v"

/* DSP Block with register on both the inputs and the output, which use different clocks */
module DSP_INOUT_REGISTERED_DUALCLK (iclk, oclk, a, b, m, out);
	localparam DATA_WIDTH = 4;

	input wire iclk;
	input wire oclk;
	input wire [DATA_WIDTH/2-1:0] a;
	input wire [DATA_WIDTH/2-1:0] b;
	input wire m;
	output wire [DATA_WIDTH-1:0] out;

	/* Input registers on iclk */
	(* pack="DFF-DSP" *)
	wire [DATA_WIDTH/2-1:0] q_a;
	(* pack="DFF-DSP" *)
	wire [DATA_WIDTH/2-1:0] q_b;
	(* pack="DFF-DSP" *)
	wire q_m;

	genvar i;
	for (i=0; i<DATA_WIDTH/2; i=i+1) begin: input_dffs_gen
		DFF q_a_ff(.D(a[i]), .Q(q_a[i]), .CLK(iclk));
		DFF q_b_ff(.D(b[i]), .Q(q_b[i]), .CLK(iclk));
	end
	DFF m_ff(.D(m), .Q(q_m), .CLK(iclk));

	/* Combinational logic */
	(* pack="DFF-DSP" *)
	wire [DATA_WIDTH-1:0] c_out;
	DSP_COMBINATIONAL comb (.a(q_a), .b(q_b), .m(q_m), .out(c_out));

	/* Output register on oclk */
	wire [DATA_WIDTH-1:0] q_out;
	genvar j;
	for (j=0; j<DATA_WIDTH; j=j+1) begin: output_dffs_gen
		DFF q_out_ff(.D(c_out[j]), .Q(out[j]), .CLK(oclk));
	end

endmodule
