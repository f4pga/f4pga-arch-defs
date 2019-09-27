`ifndef DSP_COMB
`define DSP_COMB
(* whitebox *)
module DSP_COMBINATIONAL (
	a, b, m,
	out
);
	localparam DATA_WIDTH = 4;

	input wire [DATA_WIDTH/2-1:0] a;
	input wire [DATA_WIDTH/2-1:0] b;
	input wire m;

	(* DELAY_CONST_a="30e-12" *)
	(* DELAY_CONST_b="30e-12" *)
	(* DELAY_CONST_m="10e-12" *)
	output wire [DATA_WIDTH-1:0] out;

	// Full adder combinational logic
	assign out = m ? a * b : a / b;
endmodule
`endif
