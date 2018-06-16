(*blackbox*) (* MODEL_NAME="SB_IO" *)
module SB_IO (
	// Connection to package
	PACKAGE_PIN_I,
	PACKAGE_PIN_O,

	// ???
	LATCH_INPUT_VALUE,

	// Clock enable for both clocks
	CLOCK_ENABLE,

	// Tristate
	OUTPUT_ENABLE,

	// Data going out the IC
	OUTPUT_CLK,
	D_OUT_0, D_OUT_1,
	// Data coming into the IC
	INPUT_CLK,
	D_IN_0, D_IN_1

);
	input wire PACKAGE_PIN_I;

	(* DELAY_CONST_OUTPUT_ENABLE="10e-12" *)
	(* DELAY_CONST_D_IN_0="10e-12" *)
	(* DELAY_CONST_D_IN_1="10e-12" *)
	output wire PACKAGE_PIN_O;

	input wire LATCH_INPUT_VALUE;
	input wire OUTPUT_ENABLE;

	/* Clock enable for both clocks */
	input wire CLOCK_ENABLE;
	/* Output registers clock */
	input wire OUTPUT_CLK;
	/* Input registers clock */
	input wire INPUT_CLK;

	/* Data from PACKAGE_PIN on rising clk edge */
	input wire D_OUT_0;
	/* Data from PACKAGE_PIN on falling clk edge */
	input wire D_OUT_1;

	/* Data to PACKAGE_PIN on rising clk edge */
	(* DELAY_CONST_OUTPUT_ENABLE="10e-12" *)
	(* DELAY_CONST_PACKAGE_PIN_I="10e-12" *)
	output wire D_IN_0;
	/* Data to PACKAGE_PIN on falling clk edge */
	(* DELAY_CONST_OUTPUT_ENABLE="10e-12" *)
	(* DELAY_CONST_PACKAGE_PIN_I="10e-12" *)
	output wire D_IN_1;

	parameter [5:0] PIN_TYPE = 6'b000000;

	/* IE - enable input buffers */

	/* REN */
	parameter [0:0] PULLUP = 1'b0;

	/* 1'b0 - Registers are positive edge trigger
	 * 1'b1 - Registers are negative edge trigger
	 */
	parameter [0:0] NEG_TRIGGER = 1'b0;

	/* Bank 3 / left edge
	 * -- SB_LVDS_INPUT
	 * - SB_SSTL2_CLASS_2,
	 * - SB_SSTL2_CLASS_1,
	 * - SB_SSTL18_FULL,
	 * - SB_SSTL18_HALF,
	 * - SB_MDDR10,
	 * - SB_MDDR8,
	 * - SB_MDDR4,
	 * - SB_MDDR2
	 */
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
