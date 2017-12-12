module CARRY4(CO, O, CI, CYINIT, DI, S);
	output [3:0] CO;
	output [3:0] O;
	input wire CI;
	input wire CYINIT;
	input wire [3:0] DI;
	input wire S;

	assign O = S ^ {CO[2:0], CI | CYINIT};
	assign CO[0] = S[0] ? CI | CYINIT : DI[0];
	assign CO[1] = S[1] ? CO[0] : DI[1];
	assign CO[2] = S[2] ? CO[1] : DI[2];
	assign CO[3] = S[3] ? CO[2] : DI[3];
endmodule
