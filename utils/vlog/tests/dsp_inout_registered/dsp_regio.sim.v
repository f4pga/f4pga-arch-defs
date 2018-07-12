`include "../dsp_combinational/dsp_comb.sim.v"

/* DSP Block with register on both the inputs and the output */
module dsp_regio (clk, a, b, m, out);
	localparam DATA_WIDTH = 64;

	input wire clk;
	input wire [DATA_WIDTH/2-1:0] a;
	input wire [DATA_WIDTH/2-1:0] b;
	input wire m;
	output wire [DATA_WIDTH-1:0] out;

	/* Input registers */
	reg [DATA_WIDTH/2-1:0] q_a;
	reg [DATA_WIDTH/2-1:0] q_b;
	reg q_m;
	always @(posedge clk) begin
		q_a <= a;
		q_b <= b;
	end

	wire [DATA_WIDTH-1:0] c_out;
	dsp_comb comb (.a(a), .b(b), .m(m), .out(c_out));
	//dsp_comb comb (.a(q_a), .b(q_b), .m(q_m), .out(c_out));

	/* Output register */
	reg [DATA_WIDTH-1:0] q_out;
	always @(posedge clk) begin
		q_out <= c_out;
	end

	assign out = q_out;
endmodule
