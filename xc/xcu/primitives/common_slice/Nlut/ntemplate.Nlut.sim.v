`include "lut5.sim.v"
`include "f6mux.sim.v"

// D6LUT, C6LUT, B6LUT, A6LUT == W6LUT
// A fracturable 6 input LUT. Can either be;
//  - 2 * 5 input, 1 output LUT
//  - 1 * 6 input, 1 output LUT
(* FASM_TYPE_2LUT5="SPLIT_LUT" *)
(* FASM_LUT_2LUT5="{N}LUT.INIT[31:0]={N}5LUT[0];{N}LUT.INIT[63:32]={N}5LUT[1]" *)
(* MODES="2LUT5" *)
module {N}LUT(A, O6, O5);

	input wire [5:0] A;

	(* DELAY_CONST_A1 = "1e-10" *)
	(* DELAY_CONST_A2 = "1e-10" *)
	(* DELAY_CONST_A3 = "1e-10" *)
	(* DELAY_CONST_A4 = "1e-10" *)
	(* DELAY_CONST_A5 = "1e-10" *)
	(* DELAY_CONST_A6 = "1e-10" *)
	output wire O6;

	(* DELAY_CONST_A1 = "1e-10" *)
	(* DELAY_CONST_A2 = "1e-10" *)
	(* DELAY_CONST_A3 = "1e-10" *)
	(* DELAY_CONST_A4 = "1e-10" *)
	(* DELAY_CONST_A5 = "1e-10" *)
	output wire O5;

	parameter MODE = "";
	if (MODE == "2LUT5") begin
		wire [1:0] LUT5_OUT;
		genvar i;
		generate
			for (i = 0; i < 2; i = i+1) begin
				LUT5 {N}LUT5(.in(A[4:0]), .out(LUT5_OUT[i]));
			end
		endgenerate

		wire F6MUX_O;
		F6MUX F6MUX(.I0(LUT5_OUT[0]), .I0(LUT5_OUT[1]), .S(A[5]), .O(F6MUX_O));

		assign O5 = LUT5_OUT[0];
		assign O6 = F6MUX_O;
	end

endmodule
