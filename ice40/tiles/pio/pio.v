module SB_PIO (LATCH_INPUT_VALUE, CLOCK_ENABLE, INPUT_CLK, OUTPUT_CLK, OUTPUT_ENABLE, D_OUT_0, D_OUT_1, D_IN_0, D_IN_1);

	input wire  INPUT_CLK;
	input wire  OUTPUT_CLK;
	input wire  CLOCK_ENABLE;

	input wire  LATCH_INPUT_VALUE;
	input wire  D_OUT_0;
	input wire  D_OUT_1;

	output wire D_IN_0;
	output wire D_IN_1;
	input wire  OUTPUT_ENABLE;

	parameter [5:0] PIN_TYPE = 6'b000000;
	parameter [0:0] PULLUP = 1'b0;
	parameter [0:0] NEG_TRIGGER = 1'b0;
	parameter IO_STANDARD = "SB_LVCMOS";

endmodule
