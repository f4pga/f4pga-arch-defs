module gpio (
	clk_i,
	rst_ni,
	tl_i,
	tl_o,
	cio_gpio_i,
	cio_gpio_o,
	cio_gpio_en_o,
	intr_gpio_o
);
	localparam top_pkg_TL_AIW = 8;
	localparam top_pkg_TL_AW = 32;
	localparam top_pkg_TL_DBW = top_pkg_TL_DW >> 3;
	localparam top_pkg_TL_DIW = 1;
	localparam top_pkg_TL_DUW = 16;
	localparam top_pkg_TL_DW = 32;
	localparam top_pkg_TL_SZW = $clog2($clog2(32 >> 3) + 1);
	input clk_i;
	input rst_ni;
	input wire [((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_AW) + ((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW)) + top_pkg_TL_DW) + 17) - 1:0] tl_i;
	output wire [((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_DIW) + top_pkg_TL_DW) + top_pkg_TL_DUW) + 2) - 1:0] tl_o;
	input [31:0] cio_gpio_i;
	output wire [31:0] cio_gpio_o;
	output wire [31:0] cio_gpio_en_o;
	output wire [31:0] intr_gpio_o;
	parameter [5:0] GPIO_INTR_STATE_OFFSET = 6'h 0;
	parameter [5:0] GPIO_INTR_ENABLE_OFFSET = 6'h 4;
	parameter [5:0] GPIO_INTR_TEST_OFFSET = 6'h 8;
	parameter [5:0] GPIO_DATA_IN_OFFSET = 6'h c;
	parameter [5:0] GPIO_DIRECT_OUT_OFFSET = 6'h 10;
	parameter [5:0] GPIO_MASKED_OUT_LOWER_OFFSET = 6'h 14;
	parameter [5:0] GPIO_MASKED_OUT_UPPER_OFFSET = 6'h 18;
	parameter [5:0] GPIO_DIRECT_OE_OFFSET = 6'h 1c;
	parameter [5:0] GPIO_MASKED_OE_LOWER_OFFSET = 6'h 20;
	parameter [5:0] GPIO_MASKED_OE_UPPER_OFFSET = 6'h 24;
	parameter [5:0] GPIO_INTR_CTRL_EN_RISING_OFFSET = 6'h 28;
	parameter [5:0] GPIO_INTR_CTRL_EN_FALLING_OFFSET = 6'h 2c;
	parameter [5:0] GPIO_INTR_CTRL_EN_LVLHIGH_OFFSET = 6'h 30;
	parameter [5:0] GPIO_INTR_CTRL_EN_LVLLOW_OFFSET = 6'h 34;
	parameter [5:0] GPIO_CTRL_EN_INPUT_FILTER_OFFSET = 6'h 38;
	parameter [59:0] GPIO_PERMIT = {4'b 1111, 4'b 1111, 4'b 1111, 4'b 1111, 4'b 1111, 4'b 1111, 4'b 1111, 4'b 1111, 4'b 1111, 4'b 1111, 4'b 1111, 4'b 1111, 4'b 1111, 4'b 1111, 4'b 1111};
	localparam GPIO_INTR_STATE = 0;
	localparam GPIO_INTR_ENABLE = 1;
	localparam GPIO_INTR_CTRL_EN_RISING = 10;
	localparam GPIO_INTR_CTRL_EN_FALLING = 11;
	localparam GPIO_INTR_CTRL_EN_LVLHIGH = 12;
	localparam GPIO_INTR_CTRL_EN_LVLLOW = 13;
	localparam GPIO_CTRL_EN_INPUT_FILTER = 14;
	localparam GPIO_INTR_TEST = 2;
	localparam GPIO_DATA_IN = 3;
	localparam GPIO_DIRECT_OUT = 4;
	localparam GPIO_MASKED_OUT_LOWER = 5;
	localparam GPIO_MASKED_OUT_UPPER = 6;
	localparam GPIO_DIRECT_OE = 7;
	localparam GPIO_MASKED_OE_LOWER = 8;
	localparam GPIO_MASKED_OE_UPPER = 9;
	wire [458:0] reg2hw;
	wire [257:0] hw2reg;
	reg [31:0] cio_gpio_q;
	reg [31:0] cio_gpio_en_q;
	wire [31:0] data_in_d;
	generate
		genvar i;
		for (i = 0; i < 32; i = i + 1) begin : gen_filter
			prim_filter_ctr #(.Cycles(16)) filter(
				.clk_i(clk_i),
				.rst_ni(rst_ni),
				.enable_i(reg2hw[i]),
				.filter_i(cio_gpio_i[i]),
				.filter_o(data_in_d[i])
			);
		end
	endgenerate
	assign hw2reg[192] = 1'b1;
	assign hw2reg[224-:32] = data_in_d;
	assign cio_gpio_o = cio_gpio_q;
	assign cio_gpio_en_o = cio_gpio_en_q;
	assign hw2reg[191-:32] = cio_gpio_q;
	assign hw2reg[127-:16] = cio_gpio_q[31:16];
	assign hw2reg[111-:16] = 16'h 0;
	assign hw2reg[159-:16] = cio_gpio_q[15:0];
	assign hw2reg[143-:16] = 16'h 0;
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			cio_gpio_q <= 1'sb0;
		else if (reg2hw[329])
			cio_gpio_q <= reg2hw[361-:32];
		else if (reg2hw[278])
			cio_gpio_q[31:16] <= (reg2hw[277-:16] & reg2hw[294-:16]) | (~reg2hw[277-:16] & cio_gpio_q[31:16]);
		else if (reg2hw[312])
			cio_gpio_q[15:0] <= (reg2hw[311-:16] & reg2hw[328-:16]) | (~reg2hw[311-:16] & cio_gpio_q[15:0]);
	assign hw2reg[95-:32] = cio_gpio_en_q;
	assign hw2reg[31-:16] = cio_gpio_en_q[31:16];
	assign hw2reg[15-:16] = 16'h 0;
	assign hw2reg[63-:16] = cio_gpio_en_q[15:0];
	assign hw2reg[47-:16] = 16'h 0;
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			cio_gpio_en_q <= 1'sb0;
		else if (reg2hw[228])
			cio_gpio_en_q <= reg2hw[260-:32];
		else if (reg2hw[177])
			cio_gpio_en_q[31:16] <= (reg2hw[176-:16] & reg2hw[193-:16]) | (~reg2hw[176-:16] & cio_gpio_en_q[31:16]);
		else if (reg2hw[211])
			cio_gpio_en_q[15:0] <= (reg2hw[210-:16] & reg2hw[227-:16]) | (~reg2hw[210-:16] & cio_gpio_en_q[15:0]);
	reg [31:0] data_in_q;
	always @(posedge clk_i) data_in_q <= data_in_d;
	wire [31:0] event_intr_rise;
	wire [31:0] event_intr_fall;
	wire [31:0] event_intr_actlow;
	wire [31:0] event_intr_acthigh;
	wire [31:0] event_intr_combined;
	prim_intr_hw #(.Width(32)) intr_hw(
		.event_intr_i(event_intr_combined),
		.reg2hw_intr_enable_q_i(reg2hw[426-:32]),
		.reg2hw_intr_test_q_i(reg2hw[394-:32]),
		.reg2hw_intr_test_qe_i(reg2hw[362]),
		.reg2hw_intr_state_q_i(reg2hw[458-:32]),
		.hw2reg_intr_state_de_o(hw2reg[225]),
		.hw2reg_intr_state_d_o(hw2reg[257-:32]),
		.intr_o(intr_gpio_o)
	);
	assign event_intr_rise = (~data_in_q & data_in_d) & reg2hw[159-:32];
	assign event_intr_fall = (data_in_q & ~data_in_d) & reg2hw[127-:32];
	assign event_intr_acthigh = data_in_d & reg2hw[95-:32];
	assign event_intr_actlow = ~data_in_d & reg2hw[63-:32];
	assign event_intr_combined = ((event_intr_rise | event_intr_fall) | event_intr_actlow) | event_intr_acthigh;
	gpio_reg_top u_reg(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.tl_i(tl_i),
		.tl_o(tl_o),
		.reg2hw(reg2hw),
		.hw2reg(hw2reg),
		.devmode_i(1'b1)
	);
endmodule
