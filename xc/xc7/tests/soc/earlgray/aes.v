module aes (
	clk_i,
	rst_ni,
	tl_i,
	tl_o
);
	localparam top_pkg_TL_AIW = 8;
	localparam top_pkg_TL_AW = 32;
	localparam top_pkg_TL_DBW = top_pkg_TL_DW >> 3;
	localparam top_pkg_TL_DIW = 1;
	localparam top_pkg_TL_DUW = 16;
	localparam top_pkg_TL_DW = 32;
	localparam top_pkg_TL_SZW = $clog2($clog2(32 >> 3) + 1);
	parameter AES192Enable = 1;
	parameter SBoxImpl = "lut";
	input clk_i;
	input rst_ni;
	input wire [((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_AW) + ((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW)) + top_pkg_TL_DW) + 17) - 1:0] tl_i;
	output wire [((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_DIW) + top_pkg_TL_DW) + top_pkg_TL_DUW) + 2) - 1:0] tl_o;
	parameter signed [31:0] NumRegsKey = 8;
	parameter signed [31:0] NumRegsData = 4;
	parameter [6:0] AES_KEY0_OFFSET = 7'h 0;
	parameter [6:0] AES_KEY1_OFFSET = 7'h 4;
	parameter [6:0] AES_KEY2_OFFSET = 7'h 8;
	parameter [6:0] AES_KEY3_OFFSET = 7'h c;
	parameter [6:0] AES_KEY4_OFFSET = 7'h 10;
	parameter [6:0] AES_KEY5_OFFSET = 7'h 14;
	parameter [6:0] AES_KEY6_OFFSET = 7'h 18;
	parameter [6:0] AES_KEY7_OFFSET = 7'h 1c;
	parameter [6:0] AES_DATA_IN0_OFFSET = 7'h 20;
	parameter [6:0] AES_DATA_IN1_OFFSET = 7'h 24;
	parameter [6:0] AES_DATA_IN2_OFFSET = 7'h 28;
	parameter [6:0] AES_DATA_IN3_OFFSET = 7'h 2c;
	parameter [6:0] AES_DATA_OUT0_OFFSET = 7'h 30;
	parameter [6:0] AES_DATA_OUT1_OFFSET = 7'h 34;
	parameter [6:0] AES_DATA_OUT2_OFFSET = 7'h 38;
	parameter [6:0] AES_DATA_OUT3_OFFSET = 7'h 3c;
	parameter [6:0] AES_CTRL_OFFSET = 7'h 40;
	parameter [6:0] AES_TRIGGER_OFFSET = 7'h 44;
	parameter [6:0] AES_STATUS_OFFSET = 7'h 48;
	parameter [75:0] AES_PERMIT = {4'b 1111, 4'b 1111, 4'b 1111, 4'b 1111, 4'b 1111, 4'b 1111, 4'b 1111, 4'b 1111, 4'b 1111, 4'b 1111, 4'b 1111, 4'b 1111, 4'b 1111, 4'b 1111, 4'b 1111, 4'b 1111, 4'b 0001, 4'b 0001, 4'b 0001};
	localparam AES_KEY0 = 0;
	localparam AES_KEY1 = 1;
	localparam AES_DATA_IN2 = 10;
	localparam AES_DATA_IN3 = 11;
	localparam AES_DATA_OUT0 = 12;
	localparam AES_DATA_OUT1 = 13;
	localparam AES_DATA_OUT2 = 14;
	localparam AES_DATA_OUT3 = 15;
	localparam AES_CTRL = 16;
	localparam AES_TRIGGER = 17;
	localparam AES_STATUS = 18;
	localparam AES_KEY2 = 2;
	localparam AES_KEY3 = 3;
	localparam AES_KEY4 = 4;
	localparam AES_KEY5 = 5;
	localparam AES_KEY6 = 6;
	localparam AES_KEY7 = 7;
	localparam AES_DATA_IN0 = 8;
	localparam AES_DATA_IN1 = 9;
	wire [539:0] reg2hw;
	wire [536:0] hw2reg;
	aes_reg_top u_reg(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.tl_i(tl_i),
		.tl_o(tl_o),
		.reg2hw(reg2hw),
		.hw2reg(hw2reg),
		.devmode_i(1'b1)
	);
	aes_core #(
		.AES192Enable(AES192Enable),
		.SBoxImpl(SBoxImpl)
	) aes_core(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.reg2hw(reg2hw),
		.hw2reg(hw2reg)
	);
endmodule
