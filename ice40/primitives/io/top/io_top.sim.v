`include "../ff/io_ff.sim.v"
`include "../routing/rmux2/io_rmux2.sim.v"
`include "../routing/rmux4/io_rmux4.sim.v"

(*blackbox*) (* MODEL_NAME="IO_TOP" *)
module IO_TOP (
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

	(* DELAY_CONST_CLOCK_ENABLE="10e-12" *)
	(* DELAY_CONST_OUTPUT_ENABLE="10e-12" *)
	(* DELAY_CONST_D_OUT_0="10e-12" *)
	(* DELAY_CONST_D_OUT_1="10e-12" *)
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

	/* Path coming in from the IC */
	wire ICLK_P;
	wire ICLK_N;
	assign ICLK_P = INPUT_CLK & CLOCK_ENABLE;
	assign ICLK_N = ~ICLK_P;

	wire d_in_n0;
	IO_FF reg_d_in_0(.clk(ICLK_P), .D(PACKAGE_PIN_I), .Q(d_in_n0));
	IO_FF reg_d_in_1(.clk(ICLK_N), .D(PACKAGE_PIN_I), .Q(D_IN_1));

	wire imux_o;
	IO_RMUX4 imux(
		.S({PIN_TYPE[1] & LATCH_INPUT_VALUE, PIN_TYPE[0]}),
		/*
		 * 11 - omux_o
		 * 10 - omux_o
		 * 01 - PACKAGE_PIN_I
		 * 00 - d_in_n0
		 */
		.I({imux_o, imux_o, PACKAGE_PIN_I, d_in_n0}),
		.O(imux_o));

	/* Path going out of the IC */
	wire OCLK_P;
	wire OCLK_N;
	assign OCLK_P = OUTPUT_CLK & CLOCK_ENABLE;
	assign OCLK_N = ~OCLK_P;

	wire d_out_n0;
	wire d_out_n1;
	IO_FF reg_d_out_0(.clk(OCLK_P), .D(D_OUT_0), .Q(d_out_n0));
	IO_FF reg_d_out_1(.clk(OCLK_N), .D(D_OUT_1), .Q(d_out_n1));

	wire omux0_o;
	wire omux1_o;
	IO_RMUX2 omux0(.S(PIN_TYPE[2]), .I({d_out_n0, D_OUT_0}), .O(omux0_o));
	IO_RMUX2 omux1(.S(~(PIN_TYPE[2] | OCLK_P)), .I({d_out_n0, d_out_n1}), .O(omux1_o));
	IO_RMUX2 omux2(.S(PIN_TYPE[3]), .I({omux0_o, omux1_o}), .O(PACKAGE_PIN_O));

	// Output enable
	wire d_oe;
	IO_FF reg_d_oe(.clk(OCLK_P), .D(OUTPUT_ENABLE), .Q(d_oe));

	wire oemux_o;
	IO_RMUX4 oemux(
		.S({PIN_TYPE[5], PIN_TYPE[4]}),
		//   11        10       01 00
		.I({d_oe, OUTPUT_ENABLE, 1, 0}),
		.O(oemux_o));
endmodule
