(* blackbox *)
(* MODEL_NAME="CARRY4" *)
(* ALTERNATIVE_TO="CARRY4" *)
module CARRY4_COMPLETE(CO, O, CIN, DI, S);
	(* DELAY_CONST_CIN = "10e-12" *)
	(* DELAY_CONST_DI = "10e-12" *)
	(* DELAY_CONST_S = "10e-12" *)
	output [3:0] CO;

	(* DELAY_CONST_CIN = "10e-12" *)
	(* DELAY_CONST_DI = "10e-12" *)
	(* DELAY_CONST_S = "10e-12" *)
	output [3:0] O;

	input wire CIN;
	input [3:0] DI;
	input [3:0] S;

	assign O[0] = S ^ CIN;
	assign O[1] = S ^ CO[0];
	assign O[2] = S ^ CO[1];
	assign O[3] = S ^ CO[2];
	assign CO[0] = S[0] ? CIN : DI[0];
	assign CO[1] = S[1] ? CO[0] : DI[1];
	assign CO[2] = S[2] ? CO[1] : DI[2];
	assign CO[3] = S[3] ? CO[2] : DI[3];
endmodule
