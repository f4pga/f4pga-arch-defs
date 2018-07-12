`ifndef DSP_COMB
`define DSP_COMB
module dsp_comb (
	a, b, m,
	out
);
	localparam DATA_WIDTH = 64;

	input wire [DATA_WIDTH/2-1:0] a;
	input wire [DATA_WIDTH/2-1:0] b;
	input wire m;

	output wire [DATA_WIDTH-1:0] out;

	// Full adder combinational logic
	assign out = m ? a * b : a / b;
endmodule
`endif
