SB_GB_IO My_Clock_Buffer_Package_Pin ( // A users external Clock reference
pin
.PACKAGE_PIN (Package_Pin), // User’s Pin signal name
.LATCH_INPUT_VALUE (latch_input_value), // Latches/holds the Input value
.CLOCK_ENABLE (clock_enable), // Clock Enable common to input and
// output clock
ICE Technology Library 92
Lattice Semiconductor Corporation Confidential
.INPUT_CLK (input_clk), // Clock for the input registers
.OUTPUT_CLK (output_clk), // Clock for the output registers
.OUTPUT_ENABLE (output_enable), // Output Pin Tristate/Enable
// control
.D_OUT_0 (d_out_0), // Data 0 – out to Pin/Rising clk
// edge
.D_OUT_1 (d_out_1), // Data 1 - out to Pin/Falling clk
// edge
.D_IN_0 (d_in_0), // Data 0 - Pin input/Rising clk
// edge
.D_IN_1 (d_in_1) // Data 1 – Pin input/Falling clk
// edge
.GLOBAL_BUFFER_OUTPUT (Global_Buffered_User_Clock)
// Example use – clock buffer
//driven from the input pin
);
defparam My_Clock_Buffer_Package_Pin.PIN_TYPE = 6'b000000;
// See Input and Output Pin Function Tables.
// Default value of PIN_TYPE = 6’000000 i.e.
// an input pad, with the input signal
// registered


module SB_GB_IO (
	inout  PACKAGE_PIN,
	output GLOBAL_BUFFER_OUTPUT,
	input  LATCH_INPUT_VALUE,
	input  CLOCK_ENABLE,
	input  INPUT_CLK,
	input  OUTPUT_CLK,
	input  OUTPUT_ENABLE,
	input  D_OUT_0,
	input  D_OUT_1,
	output D_IN_0,
	output D_IN_1
);
	parameter [5:0] PIN_TYPE = 6'b000000;
	parameter [0:0] PULLUP = 1'b0;
	parameter [0:0] NEG_TRIGGER = 1'b0;
	parameter IO_STANDARD = "SB_LVCMOS";

	assign GLOBAL_BUFFER_OUTPUT = PACKAGE_PIN;

	SB_IO #(
		.PIN_TYPE(PIN_TYPE),
		.PULLUP(PULLUP),
		.NEG_TRIGGER(NEG_TRIGGER),
		.IO_STANDARD(IO_STANDARD)
	) IO (
		.PACKAGE_PIN(PACKAGE_PIN),
		.LATCH_INPUT_VALUE(LATCH_INPUT_VALUE),
		.CLOCK_ENABLE(CLOCK_ENABLE),
		.INPUT_CLK(INPUT_CLK),
		.OUTPUT_CLK(OUTPUT_CLK),
		.OUTPUT_ENABLE(OUTPUT_ENABLE),
		.D_OUT_0(D_OUT_0),
		.D_OUT_1(D_OUT_1),
		.D_IN_0(D_IN_0),
		.D_IN_1(D_IN_1)
	);
endmodule
