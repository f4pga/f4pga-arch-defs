SB_IO IO_PIN_INST
(
.PACKAGE_PIN (Package_Pin), // User’s Pin signal name
.LATCH_INPUT_VALUE (latch_input_value), // Latches/holds the Input value
.CLOCK_ENABLE (clock_enable), // Clock Enable common to input and
// output clock
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
) /* synthesis DRIVE_STRENGTH= x2 */;
defparam IO_PIN_INST.PIN_TYPE = 6'b000000;
// See Input and Output Pin Function Tables.
// Default value of PIN_TYPE = 6’000000 i.e.
// an input pad, with the input signal
// registered.
defparam IO_PIN_INST.PULLUP = 1'b0;
// By default, the IO will have NO pull up.
// This parameter is used only on bank 0, 1,
// and 2. Ignored when it is placed at bank 3
defparam IO_PIN_INST.NEG_TRIGGER = 1'b0;
// Specify the polarity of all FFs in the IO to
// be falling edge when NEG_TRIGGER = 1.
// Default is rising edge.
defparam IO_PIN_INST.IO_STANDARD = "SB_LVCMOS";
// Other IO standards are supported in bank 3
// only: SB_SSTL2_CLASS_2, SB_SSTL2_CLASS_1,
// SB_SSTL18_FULL, SB_SSTL18_HALF, SB_MDDR10,
// SB_MDDR8, SB_MDDR4, SB_MDDR2 etc.


module SB_IO (
	inout  PACKAGE_PIN,
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

`ifndef BLACKBOX
	reg dout, din_0, din_1;
	reg din_q_0, din_q_1;
	reg dout_q_0, dout_q_1;
	reg outena_q;

	generate if (!NEG_TRIGGER) begin
		always @(posedge INPUT_CLK)  if (CLOCK_ENABLE) din_q_0  <= PACKAGE_PIN;
		always @(negedge INPUT_CLK)  if (CLOCK_ENABLE) din_q_1  <= PACKAGE_PIN;
		always @(posedge OUTPUT_CLK) if (CLOCK_ENABLE) dout_q_0 <= D_OUT_0;
		always @(negedge OUTPUT_CLK) if (CLOCK_ENABLE) dout_q_1 <= D_OUT_1;
		always @(posedge OUTPUT_CLK) if (CLOCK_ENABLE) outena_q <= OUTPUT_ENABLE;
	end else begin
		always @(negedge INPUT_CLK)  if (CLOCK_ENABLE) din_q_0  <= PACKAGE_PIN;
		always @(posedge INPUT_CLK)  if (CLOCK_ENABLE) din_q_1  <= PACKAGE_PIN;
		always @(negedge OUTPUT_CLK) if (CLOCK_ENABLE) dout_q_0 <= D_OUT_0;
		always @(posedge OUTPUT_CLK) if (CLOCK_ENABLE) dout_q_1 <= D_OUT_1;
		always @(negedge OUTPUT_CLK) if (CLOCK_ENABLE) outena_q <= OUTPUT_ENABLE;
	end endgenerate

	always @* begin
		if (!PIN_TYPE[1] || !LATCH_INPUT_VALUE)
			din_0 = PIN_TYPE[0] ? PACKAGE_PIN : din_q_0;
		din_1 = din_q_1;
	end

	// work around simulation glitches on dout in DDR mode
	reg outclk_delayed_1;
	reg outclk_delayed_2;
	always @* outclk_delayed_1 <= OUTPUT_CLK;
	always @* outclk_delayed_2 <= outclk_delayed_1;

	always @* begin
		if (PIN_TYPE[3])
			dout = PIN_TYPE[2] ? !dout_q_0 : D_OUT_0;
		else
			dout = (outclk_delayed_2 ^ NEG_TRIGGER) || PIN_TYPE[2] ? dout_q_0 : dout_q_1;
	end

	assign D_IN_0 = din_0, D_IN_1 = din_1;

	generate
		if (PIN_TYPE[5:4] == 2'b01) assign PACKAGE_PIN = dout;
		if (PIN_TYPE[5:4] == 2'b10) assign PACKAGE_PIN = OUTPUT_ENABLE ? dout : 1'bz;
		if (PIN_TYPE[5:4] == 2'b11) assign PACKAGE_PIN = outena_q ? dout : 1'bz;
	endgenerate
`endif
endmodule
