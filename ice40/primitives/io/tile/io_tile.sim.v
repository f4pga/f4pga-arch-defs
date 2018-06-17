`include "../in/io_in.sim.v"
`include "../inv/io_inv.sim.v"
`include "../oe/io_oe.sim.v"
`include "../out/io_out.sim.v"
`include "../tri/io_tri.sim.v"

module IO_TILE (
	// Connection to package
	PACKAGE_PIN_I,
	PACKAGE_PIN_O,
	PACKAGE_PIN_OE,

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

	(* DELAY_CONST_CLOCK_ENABLE="10e-12" *)
	(* DELAY_CONST_OUTPUT_ENABLE="10e-12" *)
	(* DELAY_CONST_D_OUT_0="10e-12" *)
	(* DELAY_CONST_D_OUT_1="10e-12" *)
	output wire PACKAGE_PIN_O;
	output wire PACKAGE_PIN_OE;

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
	(* DELAY_CONST_CLOCK_ENABLE="10e-12" *)
	(* DELAY_CONST_LATCH_INPUT_VALUE="10e-12" *)
	(* DELAY_CONST_PACKAGE_PIN_I="10e-12" *)
	output wire D_IN_0;
	/* Data to PACKAGE_PIN on falling clk edge */
	(* DELAY_CONST_CLOCK_ENABLE="10e-12" *)
	(* DELAY_CONST_LATCH_INPUT_VALUE="10e-12" *)
	(* DELAY_CONST_PACKAGE_PIN_I="10e-12" *)
	output wire D_IN_1;

	/*
	 * 01 - PIN_INPUT
	 * 11 - PIN_INPUT_LATCH
	 * 00 - PIN_INPUT_REGISTERED
	 * 00 - PIN_INPUT_REGISTERED_LATCH
	 * 00 - PIN_INPUT_DDR
	 * ---
	 * 0000 - PIN_NO_OUTPUT
	 * 0110 - PIN_OUTPUT
	 * 1010 - PIN_OUTPUT_TRISTATE
	 * 1110 - PIN_OUTPUT_ENABLE_REGISTERED
	 * 0101 - PIN_OUTPUT_REGISTERED
	 * 1001 - PIN_OUTPUT_REGISTERED_ENABLE
	 * 1101 - PIN_OUTPUT_REGISTERED_ENABLE_REGISTERED
	 * 0100 - PIN_OUTPUT_DDR
	 * 1000 - PIN_OUTPUT_DDR_ENABLE
	 * 1100 - PIN_OUTPUT_DDR_ENABLE_REGISTERED
	 * 0111 - PIN_OUTPUT_REGISTERED_INVERTED
	 * 1011 - PIN_OUTPUT_REGISTERED_ENABLE_INVERTED
	 * 1111 - PIN_OUTPUT_REGISTERED_ENABLE_REGISTERED_INVERTED
	 */
	//input wire [6:0] PIN_TYPE;
	//parameter [5:0] PIN_TYPE = 6'b000000;

	parameter MODE_OUT = "DDR";
	parameter MODE_IN  = "DDR";
	parameter MODE_OE  = "REGISTERED";

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

	/* Input path */
	wire iclk;
	assign iclk = INPUT_CLK & CLOCK_ENABLE;

	wire din;
	IO_IN #(
		.MODE(MODE_IN)
	) io_in(
		.CLK(iclk),
		.D_IN(din),
		.D_IN_P(D_IN_0), .D_IN_N(D_IN_1)
	);

	/* Output path */
	wire oclk;
	assign oclk = OUTPUT_CLK & CLOCK_ENABLE;

	wire dout;
	IO_OUT #(
		.MODE(MODE_OUT)
	) io_out(
		.CLK(oclk),
		.D_OUT_P(D_OUT_0), .D_OUT_N(D_OUT_1),
		.D_OUT(dout),
	);

	/* Tristate */
	wire oe;
	IO_OE #(
		.MODE(MODE_OE)
	) io_oe(
		.CLK(oclk),
		.OE_I(OUTPUT_ENABLE), .OE_O(oe)
	);

	IO_TRI io_tri(
		.I(din), .O(dout), .OE(oe),
		.PIN_I(PACKAGE_PIN_I), .PIN_O(PACKAGE_PIN_O), .PIN_OE(PACKAGE_PIN_OE)
	);

endmodule
