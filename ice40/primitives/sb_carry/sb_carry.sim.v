module SB_CARRY (CO, LO, I0, I1, CI);
	output wire CO;
	output wire LO;
	input wire I0;
	input wire I1;
	input wire CI;

	assign CO = (I0 && I1) || ((I0 || I1) && CI);
	assign LO = CO;
endmodule
