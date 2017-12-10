module SB_CARRY (CO, I0, I1, CI);
	output wire CO;
	input wire I0;
	input wire I1;
	output wire CI;

	assign CO = (I0 && I1) || ((I0 || I1) && CI);
endmodule
