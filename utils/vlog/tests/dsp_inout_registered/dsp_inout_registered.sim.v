`include "../fig42-dff/dff.sim.v"
`include "../dsp_combinational/dsp_combinational.sim.v"

/* DSP Block with register on both the inputs and the output */
module DSP_INOUT_REGISTERED (clk, a, b, m, out);
	localparam DATA_WIDTH = 64;

	input wire clk;
	input wire [DATA_WIDTH/2-1:0] a;
	input wire [DATA_WIDTH/2-1:0] b;
	input wire m;
	output wire [DATA_WIDTH-1:0] out;

	/* Input registers */
	wire [DATA_WIDTH/2-1:0] q_a;
	wire [DATA_WIDTH/2-1:0] q_b;
	wire q_m;

	genvar i;
	for (i=0; i<DATA_WIDTH/2; i=i+1) begin: input_dffs_gen
		DFF q_a_ff(.d(a[i]), .q(q_a[i]), .clk(clk));
		DFF q_b_ff(.d(b[i]), .q(q_b[i]), .clk(clk));
	end
	DFF m_ff(.d(m), .q(q_m), .clk(clk));

	/* Combinational logic */
	wire [DATA_WIDTH-1:0] c_out;
	DSP_COMBINATIONAL comb (.a(q_a), .b(q_b), .m(q_m), .out(c_out));

	/* Output register */
	wire [DATA_WIDTH-1:0] q_out;
	genvar j;
	for (j=0; j<DATA_WIDTH; j=j+1) begin: output_dffs_gen
		DFF q_out_ff(.d(c_out[j]), .q(q_out[j]), .clk(clk));
	end

	assign out = q_out;
endmodule
