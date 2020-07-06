module rv_plic_reg_top (
	clk_i,
	rst_ni,
	tl_i,
	tl_o,
	reg2hw,
	hw2reg,
	devmode_i
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
	output wire [327:0] reg2hw;
	input wire [164:0] hw2reg;
	input devmode_i;
	parameter signed [31:0] NumSrc = 79;
	parameter signed [31:0] NumTarget = 1;
	parameter [9:0] RV_PLIC_IP0_OFFSET = 10'h 0;
	parameter [9:0] RV_PLIC_IP1_OFFSET = 10'h 4;
	parameter [9:0] RV_PLIC_IP2_OFFSET = 10'h 8;
	parameter [9:0] RV_PLIC_LE0_OFFSET = 10'h c;
	parameter [9:0] RV_PLIC_LE1_OFFSET = 10'h 10;
	parameter [9:0] RV_PLIC_LE2_OFFSET = 10'h 14;
	parameter [9:0] RV_PLIC_PRIO0_OFFSET = 10'h 18;
	parameter [9:0] RV_PLIC_PRIO1_OFFSET = 10'h 1c;
	parameter [9:0] RV_PLIC_PRIO2_OFFSET = 10'h 20;
	parameter [9:0] RV_PLIC_PRIO3_OFFSET = 10'h 24;
	parameter [9:0] RV_PLIC_PRIO4_OFFSET = 10'h 28;
	parameter [9:0] RV_PLIC_PRIO5_OFFSET = 10'h 2c;
	parameter [9:0] RV_PLIC_PRIO6_OFFSET = 10'h 30;
	parameter [9:0] RV_PLIC_PRIO7_OFFSET = 10'h 34;
	parameter [9:0] RV_PLIC_PRIO8_OFFSET = 10'h 38;
	parameter [9:0] RV_PLIC_PRIO9_OFFSET = 10'h 3c;
	parameter [9:0] RV_PLIC_PRIO10_OFFSET = 10'h 40;
	parameter [9:0] RV_PLIC_PRIO11_OFFSET = 10'h 44;
	parameter [9:0] RV_PLIC_PRIO12_OFFSET = 10'h 48;
	parameter [9:0] RV_PLIC_PRIO13_OFFSET = 10'h 4c;
	parameter [9:0] RV_PLIC_PRIO14_OFFSET = 10'h 50;
	parameter [9:0] RV_PLIC_PRIO15_OFFSET = 10'h 54;
	parameter [9:0] RV_PLIC_PRIO16_OFFSET = 10'h 58;
	parameter [9:0] RV_PLIC_PRIO17_OFFSET = 10'h 5c;
	parameter [9:0] RV_PLIC_PRIO18_OFFSET = 10'h 60;
	parameter [9:0] RV_PLIC_PRIO19_OFFSET = 10'h 64;
	parameter [9:0] RV_PLIC_PRIO20_OFFSET = 10'h 68;
	parameter [9:0] RV_PLIC_PRIO21_OFFSET = 10'h 6c;
	parameter [9:0] RV_PLIC_PRIO22_OFFSET = 10'h 70;
	parameter [9:0] RV_PLIC_PRIO23_OFFSET = 10'h 74;
	parameter [9:0] RV_PLIC_PRIO24_OFFSET = 10'h 78;
	parameter [9:0] RV_PLIC_PRIO25_OFFSET = 10'h 7c;
	parameter [9:0] RV_PLIC_PRIO26_OFFSET = 10'h 80;
	parameter [9:0] RV_PLIC_PRIO27_OFFSET = 10'h 84;
	parameter [9:0] RV_PLIC_PRIO28_OFFSET = 10'h 88;
	parameter [9:0] RV_PLIC_PRIO29_OFFSET = 10'h 8c;
	parameter [9:0] RV_PLIC_PRIO30_OFFSET = 10'h 90;
	parameter [9:0] RV_PLIC_PRIO31_OFFSET = 10'h 94;
	parameter [9:0] RV_PLIC_PRIO32_OFFSET = 10'h 98;
	parameter [9:0] RV_PLIC_PRIO33_OFFSET = 10'h 9c;
	parameter [9:0] RV_PLIC_PRIO34_OFFSET = 10'h a0;
	parameter [9:0] RV_PLIC_PRIO35_OFFSET = 10'h a4;
	parameter [9:0] RV_PLIC_PRIO36_OFFSET = 10'h a8;
	parameter [9:0] RV_PLIC_PRIO37_OFFSET = 10'h ac;
	parameter [9:0] RV_PLIC_PRIO38_OFFSET = 10'h b0;
	parameter [9:0] RV_PLIC_PRIO39_OFFSET = 10'h b4;
	parameter [9:0] RV_PLIC_PRIO40_OFFSET = 10'h b8;
	parameter [9:0] RV_PLIC_PRIO41_OFFSET = 10'h bc;
	parameter [9:0] RV_PLIC_PRIO42_OFFSET = 10'h c0;
	parameter [9:0] RV_PLIC_PRIO43_OFFSET = 10'h c4;
	parameter [9:0] RV_PLIC_PRIO44_OFFSET = 10'h c8;
	parameter [9:0] RV_PLIC_PRIO45_OFFSET = 10'h cc;
	parameter [9:0] RV_PLIC_PRIO46_OFFSET = 10'h d0;
	parameter [9:0] RV_PLIC_PRIO47_OFFSET = 10'h d4;
	parameter [9:0] RV_PLIC_PRIO48_OFFSET = 10'h d8;
	parameter [9:0] RV_PLIC_PRIO49_OFFSET = 10'h dc;
	parameter [9:0] RV_PLIC_PRIO50_OFFSET = 10'h e0;
	parameter [9:0] RV_PLIC_PRIO51_OFFSET = 10'h e4;
	parameter [9:0] RV_PLIC_PRIO52_OFFSET = 10'h e8;
	parameter [9:0] RV_PLIC_PRIO53_OFFSET = 10'h ec;
	parameter [9:0] RV_PLIC_PRIO54_OFFSET = 10'h f0;
	parameter [9:0] RV_PLIC_PRIO55_OFFSET = 10'h f4;
	parameter [9:0] RV_PLIC_PRIO56_OFFSET = 10'h f8;
	parameter [9:0] RV_PLIC_PRIO57_OFFSET = 10'h fc;
	parameter [9:0] RV_PLIC_PRIO58_OFFSET = 10'h 100;
	parameter [9:0] RV_PLIC_PRIO59_OFFSET = 10'h 104;
	parameter [9:0] RV_PLIC_PRIO60_OFFSET = 10'h 108;
	parameter [9:0] RV_PLIC_PRIO61_OFFSET = 10'h 10c;
	parameter [9:0] RV_PLIC_PRIO62_OFFSET = 10'h 110;
	parameter [9:0] RV_PLIC_PRIO63_OFFSET = 10'h 114;
	parameter [9:0] RV_PLIC_PRIO64_OFFSET = 10'h 118;
	parameter [9:0] RV_PLIC_PRIO65_OFFSET = 10'h 11c;
	parameter [9:0] RV_PLIC_PRIO66_OFFSET = 10'h 120;
	parameter [9:0] RV_PLIC_PRIO67_OFFSET = 10'h 124;
	parameter [9:0] RV_PLIC_PRIO68_OFFSET = 10'h 128;
	parameter [9:0] RV_PLIC_PRIO69_OFFSET = 10'h 12c;
	parameter [9:0] RV_PLIC_PRIO70_OFFSET = 10'h 130;
	parameter [9:0] RV_PLIC_PRIO71_OFFSET = 10'h 134;
	parameter [9:0] RV_PLIC_PRIO72_OFFSET = 10'h 138;
	parameter [9:0] RV_PLIC_PRIO73_OFFSET = 10'h 13c;
	parameter [9:0] RV_PLIC_PRIO74_OFFSET = 10'h 140;
	parameter [9:0] RV_PLIC_PRIO75_OFFSET = 10'h 144;
	parameter [9:0] RV_PLIC_PRIO76_OFFSET = 10'h 148;
	parameter [9:0] RV_PLIC_PRIO77_OFFSET = 10'h 14c;
	parameter [9:0] RV_PLIC_PRIO78_OFFSET = 10'h 150;
	parameter [9:0] RV_PLIC_IE00_OFFSET = 10'h 200;
	parameter [9:0] RV_PLIC_IE01_OFFSET = 10'h 204;
	parameter [9:0] RV_PLIC_IE02_OFFSET = 10'h 208;
	parameter [9:0] RV_PLIC_THRESHOLD0_OFFSET = 10'h 20c;
	parameter [9:0] RV_PLIC_CC0_OFFSET = 10'h 210;
	parameter [9:0] RV_PLIC_MSIP0_OFFSET = 10'h 214;
	parameter [363:0] RV_PLIC_PERMIT = {4'b 1111, 4'b 1111, 4'b 0011, 4'b 1111, 4'b 1111, 4'b 0011, 4'b 0001, 4'b 0001, 4'b 0001, 4'b 0001, 4'b 0001, 4'b 0001, 4'b 0001, 4'b 0001, 4'b 0001, 4'b 0001, 4'b 0001, 4'b 0001, 4'b 0001, 4'b 0001, 4'b 0001, 4'b 0001, 4'b 0001, 4'b 0001, 4'b 0001, 4'b 0001, 4'b 0001, 4'b 0001, 4'b 0001, 4'b 0001, 4'b 0001, 4'b 0001, 4'b 0001, 4'b 0001, 4'b 0001, 4'b 0001, 4'b 0001, 4'b 0001, 4'b 0001, 4'b 0001, 4'b 0001, 4'b 0001, 4'b 0001, 4'b 0001, 4'b 0001, 4'b 0001, 4'b 0001, 4'b 0001, 4'b 0001, 4'b 0001, 4'b 0001, 4'b 0001, 4'b 0001, 4'b 0001, 4'b 0001, 4'b 0001, 4'b 0001, 4'b 0001, 4'b 0001, 4'b 0001, 4'b 0001, 4'b 0001, 4'b 0001, 4'b 0001, 4'b 0001, 4'b 0001, 4'b 0001, 4'b 0001, 4'b 0001, 4'b 0001, 4'b 0001, 4'b 0001, 4'b 0001, 4'b 0001, 4'b 0001, 4'b 0001, 4'b 0001, 4'b 0001, 4'b 0001, 4'b 0001, 4'b 0001, 4'b 0001, 4'b 0001, 4'b 0001, 4'b 0001, 4'b 1111, 4'b 1111, 4'b 0011, 4'b 0001, 4'b 0001, 4'b 0001};
	localparam RV_PLIC_IP0 = 0;
	localparam RV_PLIC_IP1 = 1;
	localparam RV_PLIC_PRIO4 = 10;
	localparam RV_PLIC_PRIO5 = 11;
	localparam RV_PLIC_PRIO6 = 12;
	localparam RV_PLIC_PRIO7 = 13;
	localparam RV_PLIC_PRIO8 = 14;
	localparam RV_PLIC_PRIO9 = 15;
	localparam RV_PLIC_PRIO10 = 16;
	localparam RV_PLIC_PRIO11 = 17;
	localparam RV_PLIC_PRIO12 = 18;
	localparam RV_PLIC_PRIO13 = 19;
	localparam RV_PLIC_IP2 = 2;
	localparam RV_PLIC_PRIO14 = 20;
	localparam RV_PLIC_PRIO15 = 21;
	localparam RV_PLIC_PRIO16 = 22;
	localparam RV_PLIC_PRIO17 = 23;
	localparam RV_PLIC_PRIO18 = 24;
	localparam RV_PLIC_PRIO19 = 25;
	localparam RV_PLIC_PRIO20 = 26;
	localparam RV_PLIC_PRIO21 = 27;
	localparam RV_PLIC_PRIO22 = 28;
	localparam RV_PLIC_PRIO23 = 29;
	localparam RV_PLIC_LE0 = 3;
	localparam RV_PLIC_PRIO24 = 30;
	localparam RV_PLIC_PRIO25 = 31;
	localparam RV_PLIC_PRIO26 = 32;
	localparam RV_PLIC_PRIO27 = 33;
	localparam RV_PLIC_PRIO28 = 34;
	localparam RV_PLIC_PRIO29 = 35;
	localparam RV_PLIC_PRIO30 = 36;
	localparam RV_PLIC_PRIO31 = 37;
	localparam RV_PLIC_PRIO32 = 38;
	localparam RV_PLIC_PRIO33 = 39;
	localparam RV_PLIC_LE1 = 4;
	localparam RV_PLIC_PRIO34 = 40;
	localparam RV_PLIC_PRIO35 = 41;
	localparam RV_PLIC_PRIO36 = 42;
	localparam RV_PLIC_PRIO37 = 43;
	localparam RV_PLIC_PRIO38 = 44;
	localparam RV_PLIC_PRIO39 = 45;
	localparam RV_PLIC_PRIO40 = 46;
	localparam RV_PLIC_PRIO41 = 47;
	localparam RV_PLIC_PRIO42 = 48;
	localparam RV_PLIC_PRIO43 = 49;
	localparam RV_PLIC_LE2 = 5;
	localparam RV_PLIC_PRIO44 = 50;
	localparam RV_PLIC_PRIO45 = 51;
	localparam RV_PLIC_PRIO46 = 52;
	localparam RV_PLIC_PRIO47 = 53;
	localparam RV_PLIC_PRIO48 = 54;
	localparam RV_PLIC_PRIO49 = 55;
	localparam RV_PLIC_PRIO50 = 56;
	localparam RV_PLIC_PRIO51 = 57;
	localparam RV_PLIC_PRIO52 = 58;
	localparam RV_PLIC_PRIO53 = 59;
	localparam RV_PLIC_PRIO0 = 6;
	localparam RV_PLIC_PRIO54 = 60;
	localparam RV_PLIC_PRIO55 = 61;
	localparam RV_PLIC_PRIO56 = 62;
	localparam RV_PLIC_PRIO57 = 63;
	localparam RV_PLIC_PRIO58 = 64;
	localparam RV_PLIC_PRIO59 = 65;
	localparam RV_PLIC_PRIO60 = 66;
	localparam RV_PLIC_PRIO61 = 67;
	localparam RV_PLIC_PRIO62 = 68;
	localparam RV_PLIC_PRIO63 = 69;
	localparam RV_PLIC_PRIO1 = 7;
	localparam RV_PLIC_PRIO64 = 70;
	localparam RV_PLIC_PRIO65 = 71;
	localparam RV_PLIC_PRIO66 = 72;
	localparam RV_PLIC_PRIO67 = 73;
	localparam RV_PLIC_PRIO68 = 74;
	localparam RV_PLIC_PRIO69 = 75;
	localparam RV_PLIC_PRIO70 = 76;
	localparam RV_PLIC_PRIO71 = 77;
	localparam RV_PLIC_PRIO72 = 78;
	localparam RV_PLIC_PRIO73 = 79;
	localparam RV_PLIC_PRIO2 = 8;
	localparam RV_PLIC_PRIO74 = 80;
	localparam RV_PLIC_PRIO75 = 81;
	localparam RV_PLIC_PRIO76 = 82;
	localparam RV_PLIC_PRIO77 = 83;
	localparam RV_PLIC_PRIO78 = 84;
	localparam RV_PLIC_IE00 = 85;
	localparam RV_PLIC_IE01 = 86;
	localparam RV_PLIC_IE02 = 87;
	localparam RV_PLIC_THRESHOLD0 = 88;
	localparam RV_PLIC_CC0 = 89;
	localparam RV_PLIC_PRIO3 = 9;
	localparam RV_PLIC_MSIP0 = 90;
	localparam signed [31:0] AW = 10;
	localparam signed [31:0] DW = 32;
	localparam signed [31:0] DBW = DW / 8;
	wire reg_we;
	wire reg_re;
	wire [AW - 1:0] reg_addr;
	wire [DW - 1:0] reg_wdata;
	wire [DBW - 1:0] reg_be;
	wire [DW - 1:0] reg_rdata;
	wire reg_error;
	wire addrmiss;
	reg wr_err;
	reg [DW - 1:0] reg_rdata_next;
	wire [((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_AW) + ((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW)) + top_pkg_TL_DW) + 17) - 1:0] tl_reg_h2d;
	wire [((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_DIW) + top_pkg_TL_DW) + top_pkg_TL_DUW) + 2) - 1:0] tl_reg_d2h;
	assign tl_reg_h2d = tl_i;
	assign tl_o = tl_reg_d2h;
	tlul_adapter_reg #(
		.RegAw(AW),
		.RegDw(DW)
	) u_reg_if(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.tl_i(tl_reg_h2d),
		.tl_o(tl_reg_d2h),
		.we_o(reg_we),
		.re_o(reg_re),
		.addr_o(reg_addr),
		.wdata_o(reg_wdata),
		.be_o(reg_be),
		.rdata_i(reg_rdata),
		.error_i(reg_error)
	);
	assign reg_rdata = reg_rdata_next;
	assign reg_error = (devmode_i & addrmiss) | wr_err;
	wire ip0_p0_qs;
	wire ip0_p1_qs;
	wire ip0_p2_qs;
	wire ip0_p3_qs;
	wire ip0_p4_qs;
	wire ip0_p5_qs;
	wire ip0_p6_qs;
	wire ip0_p7_qs;
	wire ip0_p8_qs;
	wire ip0_p9_qs;
	wire ip0_p10_qs;
	wire ip0_p11_qs;
	wire ip0_p12_qs;
	wire ip0_p13_qs;
	wire ip0_p14_qs;
	wire ip0_p15_qs;
	wire ip0_p16_qs;
	wire ip0_p17_qs;
	wire ip0_p18_qs;
	wire ip0_p19_qs;
	wire ip0_p20_qs;
	wire ip0_p21_qs;
	wire ip0_p22_qs;
	wire ip0_p23_qs;
	wire ip0_p24_qs;
	wire ip0_p25_qs;
	wire ip0_p26_qs;
	wire ip0_p27_qs;
	wire ip0_p28_qs;
	wire ip0_p29_qs;
	wire ip0_p30_qs;
	wire ip0_p31_qs;
	wire ip1_p32_qs;
	wire ip1_p33_qs;
	wire ip1_p34_qs;
	wire ip1_p35_qs;
	wire ip1_p36_qs;
	wire ip1_p37_qs;
	wire ip1_p38_qs;
	wire ip1_p39_qs;
	wire ip1_p40_qs;
	wire ip1_p41_qs;
	wire ip1_p42_qs;
	wire ip1_p43_qs;
	wire ip1_p44_qs;
	wire ip1_p45_qs;
	wire ip1_p46_qs;
	wire ip1_p47_qs;
	wire ip1_p48_qs;
	wire ip1_p49_qs;
	wire ip1_p50_qs;
	wire ip1_p51_qs;
	wire ip1_p52_qs;
	wire ip1_p53_qs;
	wire ip1_p54_qs;
	wire ip1_p55_qs;
	wire ip1_p56_qs;
	wire ip1_p57_qs;
	wire ip1_p58_qs;
	wire ip1_p59_qs;
	wire ip1_p60_qs;
	wire ip1_p61_qs;
	wire ip1_p62_qs;
	wire ip1_p63_qs;
	wire ip2_p64_qs;
	wire ip2_p65_qs;
	wire ip2_p66_qs;
	wire ip2_p67_qs;
	wire ip2_p68_qs;
	wire ip2_p69_qs;
	wire ip2_p70_qs;
	wire ip2_p71_qs;
	wire ip2_p72_qs;
	wire ip2_p73_qs;
	wire ip2_p74_qs;
	wire ip2_p75_qs;
	wire ip2_p76_qs;
	wire ip2_p77_qs;
	wire ip2_p78_qs;
	wire le0_le0_qs;
	wire le0_le0_wd;
	wire le0_le0_we;
	wire le0_le1_qs;
	wire le0_le1_wd;
	wire le0_le1_we;
	wire le0_le2_qs;
	wire le0_le2_wd;
	wire le0_le2_we;
	wire le0_le3_qs;
	wire le0_le3_wd;
	wire le0_le3_we;
	wire le0_le4_qs;
	wire le0_le4_wd;
	wire le0_le4_we;
	wire le0_le5_qs;
	wire le0_le5_wd;
	wire le0_le5_we;
	wire le0_le6_qs;
	wire le0_le6_wd;
	wire le0_le6_we;
	wire le0_le7_qs;
	wire le0_le7_wd;
	wire le0_le7_we;
	wire le0_le8_qs;
	wire le0_le8_wd;
	wire le0_le8_we;
	wire le0_le9_qs;
	wire le0_le9_wd;
	wire le0_le9_we;
	wire le0_le10_qs;
	wire le0_le10_wd;
	wire le0_le10_we;
	wire le0_le11_qs;
	wire le0_le11_wd;
	wire le0_le11_we;
	wire le0_le12_qs;
	wire le0_le12_wd;
	wire le0_le12_we;
	wire le0_le13_qs;
	wire le0_le13_wd;
	wire le0_le13_we;
	wire le0_le14_qs;
	wire le0_le14_wd;
	wire le0_le14_we;
	wire le0_le15_qs;
	wire le0_le15_wd;
	wire le0_le15_we;
	wire le0_le16_qs;
	wire le0_le16_wd;
	wire le0_le16_we;
	wire le0_le17_qs;
	wire le0_le17_wd;
	wire le0_le17_we;
	wire le0_le18_qs;
	wire le0_le18_wd;
	wire le0_le18_we;
	wire le0_le19_qs;
	wire le0_le19_wd;
	wire le0_le19_we;
	wire le0_le20_qs;
	wire le0_le20_wd;
	wire le0_le20_we;
	wire le0_le21_qs;
	wire le0_le21_wd;
	wire le0_le21_we;
	wire le0_le22_qs;
	wire le0_le22_wd;
	wire le0_le22_we;
	wire le0_le23_qs;
	wire le0_le23_wd;
	wire le0_le23_we;
	wire le0_le24_qs;
	wire le0_le24_wd;
	wire le0_le24_we;
	wire le0_le25_qs;
	wire le0_le25_wd;
	wire le0_le25_we;
	wire le0_le26_qs;
	wire le0_le26_wd;
	wire le0_le26_we;
	wire le0_le27_qs;
	wire le0_le27_wd;
	wire le0_le27_we;
	wire le0_le28_qs;
	wire le0_le28_wd;
	wire le0_le28_we;
	wire le0_le29_qs;
	wire le0_le29_wd;
	wire le0_le29_we;
	wire le0_le30_qs;
	wire le0_le30_wd;
	wire le0_le30_we;
	wire le0_le31_qs;
	wire le0_le31_wd;
	wire le0_le31_we;
	wire le1_le32_qs;
	wire le1_le32_wd;
	wire le1_le32_we;
	wire le1_le33_qs;
	wire le1_le33_wd;
	wire le1_le33_we;
	wire le1_le34_qs;
	wire le1_le34_wd;
	wire le1_le34_we;
	wire le1_le35_qs;
	wire le1_le35_wd;
	wire le1_le35_we;
	wire le1_le36_qs;
	wire le1_le36_wd;
	wire le1_le36_we;
	wire le1_le37_qs;
	wire le1_le37_wd;
	wire le1_le37_we;
	wire le1_le38_qs;
	wire le1_le38_wd;
	wire le1_le38_we;
	wire le1_le39_qs;
	wire le1_le39_wd;
	wire le1_le39_we;
	wire le1_le40_qs;
	wire le1_le40_wd;
	wire le1_le40_we;
	wire le1_le41_qs;
	wire le1_le41_wd;
	wire le1_le41_we;
	wire le1_le42_qs;
	wire le1_le42_wd;
	wire le1_le42_we;
	wire le1_le43_qs;
	wire le1_le43_wd;
	wire le1_le43_we;
	wire le1_le44_qs;
	wire le1_le44_wd;
	wire le1_le44_we;
	wire le1_le45_qs;
	wire le1_le45_wd;
	wire le1_le45_we;
	wire le1_le46_qs;
	wire le1_le46_wd;
	wire le1_le46_we;
	wire le1_le47_qs;
	wire le1_le47_wd;
	wire le1_le47_we;
	wire le1_le48_qs;
	wire le1_le48_wd;
	wire le1_le48_we;
	wire le1_le49_qs;
	wire le1_le49_wd;
	wire le1_le49_we;
	wire le1_le50_qs;
	wire le1_le50_wd;
	wire le1_le50_we;
	wire le1_le51_qs;
	wire le1_le51_wd;
	wire le1_le51_we;
	wire le1_le52_qs;
	wire le1_le52_wd;
	wire le1_le52_we;
	wire le1_le53_qs;
	wire le1_le53_wd;
	wire le1_le53_we;
	wire le1_le54_qs;
	wire le1_le54_wd;
	wire le1_le54_we;
	wire le1_le55_qs;
	wire le1_le55_wd;
	wire le1_le55_we;
	wire le1_le56_qs;
	wire le1_le56_wd;
	wire le1_le56_we;
	wire le1_le57_qs;
	wire le1_le57_wd;
	wire le1_le57_we;
	wire le1_le58_qs;
	wire le1_le58_wd;
	wire le1_le58_we;
	wire le1_le59_qs;
	wire le1_le59_wd;
	wire le1_le59_we;
	wire le1_le60_qs;
	wire le1_le60_wd;
	wire le1_le60_we;
	wire le1_le61_qs;
	wire le1_le61_wd;
	wire le1_le61_we;
	wire le1_le62_qs;
	wire le1_le62_wd;
	wire le1_le62_we;
	wire le1_le63_qs;
	wire le1_le63_wd;
	wire le1_le63_we;
	wire le2_le64_qs;
	wire le2_le64_wd;
	wire le2_le64_we;
	wire le2_le65_qs;
	wire le2_le65_wd;
	wire le2_le65_we;
	wire le2_le66_qs;
	wire le2_le66_wd;
	wire le2_le66_we;
	wire le2_le67_qs;
	wire le2_le67_wd;
	wire le2_le67_we;
	wire le2_le68_qs;
	wire le2_le68_wd;
	wire le2_le68_we;
	wire le2_le69_qs;
	wire le2_le69_wd;
	wire le2_le69_we;
	wire le2_le70_qs;
	wire le2_le70_wd;
	wire le2_le70_we;
	wire le2_le71_qs;
	wire le2_le71_wd;
	wire le2_le71_we;
	wire le2_le72_qs;
	wire le2_le72_wd;
	wire le2_le72_we;
	wire le2_le73_qs;
	wire le2_le73_wd;
	wire le2_le73_we;
	wire le2_le74_qs;
	wire le2_le74_wd;
	wire le2_le74_we;
	wire le2_le75_qs;
	wire le2_le75_wd;
	wire le2_le75_we;
	wire le2_le76_qs;
	wire le2_le76_wd;
	wire le2_le76_we;
	wire le2_le77_qs;
	wire le2_le77_wd;
	wire le2_le77_we;
	wire le2_le78_qs;
	wire le2_le78_wd;
	wire le2_le78_we;
	wire [1:0] prio0_qs;
	wire [1:0] prio0_wd;
	wire prio0_we;
	wire [1:0] prio1_qs;
	wire [1:0] prio1_wd;
	wire prio1_we;
	wire [1:0] prio2_qs;
	wire [1:0] prio2_wd;
	wire prio2_we;
	wire [1:0] prio3_qs;
	wire [1:0] prio3_wd;
	wire prio3_we;
	wire [1:0] prio4_qs;
	wire [1:0] prio4_wd;
	wire prio4_we;
	wire [1:0] prio5_qs;
	wire [1:0] prio5_wd;
	wire prio5_we;
	wire [1:0] prio6_qs;
	wire [1:0] prio6_wd;
	wire prio6_we;
	wire [1:0] prio7_qs;
	wire [1:0] prio7_wd;
	wire prio7_we;
	wire [1:0] prio8_qs;
	wire [1:0] prio8_wd;
	wire prio8_we;
	wire [1:0] prio9_qs;
	wire [1:0] prio9_wd;
	wire prio9_we;
	wire [1:0] prio10_qs;
	wire [1:0] prio10_wd;
	wire prio10_we;
	wire [1:0] prio11_qs;
	wire [1:0] prio11_wd;
	wire prio11_we;
	wire [1:0] prio12_qs;
	wire [1:0] prio12_wd;
	wire prio12_we;
	wire [1:0] prio13_qs;
	wire [1:0] prio13_wd;
	wire prio13_we;
	wire [1:0] prio14_qs;
	wire [1:0] prio14_wd;
	wire prio14_we;
	wire [1:0] prio15_qs;
	wire [1:0] prio15_wd;
	wire prio15_we;
	wire [1:0] prio16_qs;
	wire [1:0] prio16_wd;
	wire prio16_we;
	wire [1:0] prio17_qs;
	wire [1:0] prio17_wd;
	wire prio17_we;
	wire [1:0] prio18_qs;
	wire [1:0] prio18_wd;
	wire prio18_we;
	wire [1:0] prio19_qs;
	wire [1:0] prio19_wd;
	wire prio19_we;
	wire [1:0] prio20_qs;
	wire [1:0] prio20_wd;
	wire prio20_we;
	wire [1:0] prio21_qs;
	wire [1:0] prio21_wd;
	wire prio21_we;
	wire [1:0] prio22_qs;
	wire [1:0] prio22_wd;
	wire prio22_we;
	wire [1:0] prio23_qs;
	wire [1:0] prio23_wd;
	wire prio23_we;
	wire [1:0] prio24_qs;
	wire [1:0] prio24_wd;
	wire prio24_we;
	wire [1:0] prio25_qs;
	wire [1:0] prio25_wd;
	wire prio25_we;
	wire [1:0] prio26_qs;
	wire [1:0] prio26_wd;
	wire prio26_we;
	wire [1:0] prio27_qs;
	wire [1:0] prio27_wd;
	wire prio27_we;
	wire [1:0] prio28_qs;
	wire [1:0] prio28_wd;
	wire prio28_we;
	wire [1:0] prio29_qs;
	wire [1:0] prio29_wd;
	wire prio29_we;
	wire [1:0] prio30_qs;
	wire [1:0] prio30_wd;
	wire prio30_we;
	wire [1:0] prio31_qs;
	wire [1:0] prio31_wd;
	wire prio31_we;
	wire [1:0] prio32_qs;
	wire [1:0] prio32_wd;
	wire prio32_we;
	wire [1:0] prio33_qs;
	wire [1:0] prio33_wd;
	wire prio33_we;
	wire [1:0] prio34_qs;
	wire [1:0] prio34_wd;
	wire prio34_we;
	wire [1:0] prio35_qs;
	wire [1:0] prio35_wd;
	wire prio35_we;
	wire [1:0] prio36_qs;
	wire [1:0] prio36_wd;
	wire prio36_we;
	wire [1:0] prio37_qs;
	wire [1:0] prio37_wd;
	wire prio37_we;
	wire [1:0] prio38_qs;
	wire [1:0] prio38_wd;
	wire prio38_we;
	wire [1:0] prio39_qs;
	wire [1:0] prio39_wd;
	wire prio39_we;
	wire [1:0] prio40_qs;
	wire [1:0] prio40_wd;
	wire prio40_we;
	wire [1:0] prio41_qs;
	wire [1:0] prio41_wd;
	wire prio41_we;
	wire [1:0] prio42_qs;
	wire [1:0] prio42_wd;
	wire prio42_we;
	wire [1:0] prio43_qs;
	wire [1:0] prio43_wd;
	wire prio43_we;
	wire [1:0] prio44_qs;
	wire [1:0] prio44_wd;
	wire prio44_we;
	wire [1:0] prio45_qs;
	wire [1:0] prio45_wd;
	wire prio45_we;
	wire [1:0] prio46_qs;
	wire [1:0] prio46_wd;
	wire prio46_we;
	wire [1:0] prio47_qs;
	wire [1:0] prio47_wd;
	wire prio47_we;
	wire [1:0] prio48_qs;
	wire [1:0] prio48_wd;
	wire prio48_we;
	wire [1:0] prio49_qs;
	wire [1:0] prio49_wd;
	wire prio49_we;
	wire [1:0] prio50_qs;
	wire [1:0] prio50_wd;
	wire prio50_we;
	wire [1:0] prio51_qs;
	wire [1:0] prio51_wd;
	wire prio51_we;
	wire [1:0] prio52_qs;
	wire [1:0] prio52_wd;
	wire prio52_we;
	wire [1:0] prio53_qs;
	wire [1:0] prio53_wd;
	wire prio53_we;
	wire [1:0] prio54_qs;
	wire [1:0] prio54_wd;
	wire prio54_we;
	wire [1:0] prio55_qs;
	wire [1:0] prio55_wd;
	wire prio55_we;
	wire [1:0] prio56_qs;
	wire [1:0] prio56_wd;
	wire prio56_we;
	wire [1:0] prio57_qs;
	wire [1:0] prio57_wd;
	wire prio57_we;
	wire [1:0] prio58_qs;
	wire [1:0] prio58_wd;
	wire prio58_we;
	wire [1:0] prio59_qs;
	wire [1:0] prio59_wd;
	wire prio59_we;
	wire [1:0] prio60_qs;
	wire [1:0] prio60_wd;
	wire prio60_we;
	wire [1:0] prio61_qs;
	wire [1:0] prio61_wd;
	wire prio61_we;
	wire [1:0] prio62_qs;
	wire [1:0] prio62_wd;
	wire prio62_we;
	wire [1:0] prio63_qs;
	wire [1:0] prio63_wd;
	wire prio63_we;
	wire [1:0] prio64_qs;
	wire [1:0] prio64_wd;
	wire prio64_we;
	wire [1:0] prio65_qs;
	wire [1:0] prio65_wd;
	wire prio65_we;
	wire [1:0] prio66_qs;
	wire [1:0] prio66_wd;
	wire prio66_we;
	wire [1:0] prio67_qs;
	wire [1:0] prio67_wd;
	wire prio67_we;
	wire [1:0] prio68_qs;
	wire [1:0] prio68_wd;
	wire prio68_we;
	wire [1:0] prio69_qs;
	wire [1:0] prio69_wd;
	wire prio69_we;
	wire [1:0] prio70_qs;
	wire [1:0] prio70_wd;
	wire prio70_we;
	wire [1:0] prio71_qs;
	wire [1:0] prio71_wd;
	wire prio71_we;
	wire [1:0] prio72_qs;
	wire [1:0] prio72_wd;
	wire prio72_we;
	wire [1:0] prio73_qs;
	wire [1:0] prio73_wd;
	wire prio73_we;
	wire [1:0] prio74_qs;
	wire [1:0] prio74_wd;
	wire prio74_we;
	wire [1:0] prio75_qs;
	wire [1:0] prio75_wd;
	wire prio75_we;
	wire [1:0] prio76_qs;
	wire [1:0] prio76_wd;
	wire prio76_we;
	wire [1:0] prio77_qs;
	wire [1:0] prio77_wd;
	wire prio77_we;
	wire [1:0] prio78_qs;
	wire [1:0] prio78_wd;
	wire prio78_we;
	wire ie00_e0_qs;
	wire ie00_e0_wd;
	wire ie00_e0_we;
	wire ie00_e1_qs;
	wire ie00_e1_wd;
	wire ie00_e1_we;
	wire ie00_e2_qs;
	wire ie00_e2_wd;
	wire ie00_e2_we;
	wire ie00_e3_qs;
	wire ie00_e3_wd;
	wire ie00_e3_we;
	wire ie00_e4_qs;
	wire ie00_e4_wd;
	wire ie00_e4_we;
	wire ie00_e5_qs;
	wire ie00_e5_wd;
	wire ie00_e5_we;
	wire ie00_e6_qs;
	wire ie00_e6_wd;
	wire ie00_e6_we;
	wire ie00_e7_qs;
	wire ie00_e7_wd;
	wire ie00_e7_we;
	wire ie00_e8_qs;
	wire ie00_e8_wd;
	wire ie00_e8_we;
	wire ie00_e9_qs;
	wire ie00_e9_wd;
	wire ie00_e9_we;
	wire ie00_e10_qs;
	wire ie00_e10_wd;
	wire ie00_e10_we;
	wire ie00_e11_qs;
	wire ie00_e11_wd;
	wire ie00_e11_we;
	wire ie00_e12_qs;
	wire ie00_e12_wd;
	wire ie00_e12_we;
	wire ie00_e13_qs;
	wire ie00_e13_wd;
	wire ie00_e13_we;
	wire ie00_e14_qs;
	wire ie00_e14_wd;
	wire ie00_e14_we;
	wire ie00_e15_qs;
	wire ie00_e15_wd;
	wire ie00_e15_we;
	wire ie00_e16_qs;
	wire ie00_e16_wd;
	wire ie00_e16_we;
	wire ie00_e17_qs;
	wire ie00_e17_wd;
	wire ie00_e17_we;
	wire ie00_e18_qs;
	wire ie00_e18_wd;
	wire ie00_e18_we;
	wire ie00_e19_qs;
	wire ie00_e19_wd;
	wire ie00_e19_we;
	wire ie00_e20_qs;
	wire ie00_e20_wd;
	wire ie00_e20_we;
	wire ie00_e21_qs;
	wire ie00_e21_wd;
	wire ie00_e21_we;
	wire ie00_e22_qs;
	wire ie00_e22_wd;
	wire ie00_e22_we;
	wire ie00_e23_qs;
	wire ie00_e23_wd;
	wire ie00_e23_we;
	wire ie00_e24_qs;
	wire ie00_e24_wd;
	wire ie00_e24_we;
	wire ie00_e25_qs;
	wire ie00_e25_wd;
	wire ie00_e25_we;
	wire ie00_e26_qs;
	wire ie00_e26_wd;
	wire ie00_e26_we;
	wire ie00_e27_qs;
	wire ie00_e27_wd;
	wire ie00_e27_we;
	wire ie00_e28_qs;
	wire ie00_e28_wd;
	wire ie00_e28_we;
	wire ie00_e29_qs;
	wire ie00_e29_wd;
	wire ie00_e29_we;
	wire ie00_e30_qs;
	wire ie00_e30_wd;
	wire ie00_e30_we;
	wire ie00_e31_qs;
	wire ie00_e31_wd;
	wire ie00_e31_we;
	wire ie01_e32_qs;
	wire ie01_e32_wd;
	wire ie01_e32_we;
	wire ie01_e33_qs;
	wire ie01_e33_wd;
	wire ie01_e33_we;
	wire ie01_e34_qs;
	wire ie01_e34_wd;
	wire ie01_e34_we;
	wire ie01_e35_qs;
	wire ie01_e35_wd;
	wire ie01_e35_we;
	wire ie01_e36_qs;
	wire ie01_e36_wd;
	wire ie01_e36_we;
	wire ie01_e37_qs;
	wire ie01_e37_wd;
	wire ie01_e37_we;
	wire ie01_e38_qs;
	wire ie01_e38_wd;
	wire ie01_e38_we;
	wire ie01_e39_qs;
	wire ie01_e39_wd;
	wire ie01_e39_we;
	wire ie01_e40_qs;
	wire ie01_e40_wd;
	wire ie01_e40_we;
	wire ie01_e41_qs;
	wire ie01_e41_wd;
	wire ie01_e41_we;
	wire ie01_e42_qs;
	wire ie01_e42_wd;
	wire ie01_e42_we;
	wire ie01_e43_qs;
	wire ie01_e43_wd;
	wire ie01_e43_we;
	wire ie01_e44_qs;
	wire ie01_e44_wd;
	wire ie01_e44_we;
	wire ie01_e45_qs;
	wire ie01_e45_wd;
	wire ie01_e45_we;
	wire ie01_e46_qs;
	wire ie01_e46_wd;
	wire ie01_e46_we;
	wire ie01_e47_qs;
	wire ie01_e47_wd;
	wire ie01_e47_we;
	wire ie01_e48_qs;
	wire ie01_e48_wd;
	wire ie01_e48_we;
	wire ie01_e49_qs;
	wire ie01_e49_wd;
	wire ie01_e49_we;
	wire ie01_e50_qs;
	wire ie01_e50_wd;
	wire ie01_e50_we;
	wire ie01_e51_qs;
	wire ie01_e51_wd;
	wire ie01_e51_we;
	wire ie01_e52_qs;
	wire ie01_e52_wd;
	wire ie01_e52_we;
	wire ie01_e53_qs;
	wire ie01_e53_wd;
	wire ie01_e53_we;
	wire ie01_e54_qs;
	wire ie01_e54_wd;
	wire ie01_e54_we;
	wire ie01_e55_qs;
	wire ie01_e55_wd;
	wire ie01_e55_we;
	wire ie01_e56_qs;
	wire ie01_e56_wd;
	wire ie01_e56_we;
	wire ie01_e57_qs;
	wire ie01_e57_wd;
	wire ie01_e57_we;
	wire ie01_e58_qs;
	wire ie01_e58_wd;
	wire ie01_e58_we;
	wire ie01_e59_qs;
	wire ie01_e59_wd;
	wire ie01_e59_we;
	wire ie01_e60_qs;
	wire ie01_e60_wd;
	wire ie01_e60_we;
	wire ie01_e61_qs;
	wire ie01_e61_wd;
	wire ie01_e61_we;
	wire ie01_e62_qs;
	wire ie01_e62_wd;
	wire ie01_e62_we;
	wire ie01_e63_qs;
	wire ie01_e63_wd;
	wire ie01_e63_we;
	wire ie02_e64_qs;
	wire ie02_e64_wd;
	wire ie02_e64_we;
	wire ie02_e65_qs;
	wire ie02_e65_wd;
	wire ie02_e65_we;
	wire ie02_e66_qs;
	wire ie02_e66_wd;
	wire ie02_e66_we;
	wire ie02_e67_qs;
	wire ie02_e67_wd;
	wire ie02_e67_we;
	wire ie02_e68_qs;
	wire ie02_e68_wd;
	wire ie02_e68_we;
	wire ie02_e69_qs;
	wire ie02_e69_wd;
	wire ie02_e69_we;
	wire ie02_e70_qs;
	wire ie02_e70_wd;
	wire ie02_e70_we;
	wire ie02_e71_qs;
	wire ie02_e71_wd;
	wire ie02_e71_we;
	wire ie02_e72_qs;
	wire ie02_e72_wd;
	wire ie02_e72_we;
	wire ie02_e73_qs;
	wire ie02_e73_wd;
	wire ie02_e73_we;
	wire ie02_e74_qs;
	wire ie02_e74_wd;
	wire ie02_e74_we;
	wire ie02_e75_qs;
	wire ie02_e75_wd;
	wire ie02_e75_we;
	wire ie02_e76_qs;
	wire ie02_e76_wd;
	wire ie02_e76_we;
	wire ie02_e77_qs;
	wire ie02_e77_wd;
	wire ie02_e77_we;
	wire ie02_e78_qs;
	wire ie02_e78_wd;
	wire ie02_e78_we;
	wire [1:0] threshold0_qs;
	wire [1:0] threshold0_wd;
	wire threshold0_we;
	wire [6:0] cc0_qs;
	wire [6:0] cc0_wd;
	wire cc0_we;
	wire cc0_re;
	wire msip0_qs;
	wire msip0_wd;
	wire msip0_we;
	prim_subreg #(
		.DW(1),
		.SWACCESS("RO"),
		.RESVAL(1'h0)
	) u_ip0_p0(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(1'b0),
		.wd(1'sb0),
		.de(hw2reg[7]),
		.d(hw2reg[8]),
		.qe(),
		.q(),
		.qs(ip0_p0_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RO"),
		.RESVAL(1'h0)
	) u_ip0_p1(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(1'b0),
		.wd(1'sb0),
		.de(hw2reg[9]),
		.d(hw2reg[10]),
		.qe(),
		.q(),
		.qs(ip0_p1_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RO"),
		.RESVAL(1'h0)
	) u_ip0_p2(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(1'b0),
		.wd(1'sb0),
		.de(hw2reg[11]),
		.d(hw2reg[12]),
		.qe(),
		.q(),
		.qs(ip0_p2_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RO"),
		.RESVAL(1'h0)
	) u_ip0_p3(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(1'b0),
		.wd(1'sb0),
		.de(hw2reg[13]),
		.d(hw2reg[14]),
		.qe(),
		.q(),
		.qs(ip0_p3_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RO"),
		.RESVAL(1'h0)
	) u_ip0_p4(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(1'b0),
		.wd(1'sb0),
		.de(hw2reg[15]),
		.d(hw2reg[16]),
		.qe(),
		.q(),
		.qs(ip0_p4_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RO"),
		.RESVAL(1'h0)
	) u_ip0_p5(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(1'b0),
		.wd(1'sb0),
		.de(hw2reg[17]),
		.d(hw2reg[18]),
		.qe(),
		.q(),
		.qs(ip0_p5_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RO"),
		.RESVAL(1'h0)
	) u_ip0_p6(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(1'b0),
		.wd(1'sb0),
		.de(hw2reg[19]),
		.d(hw2reg[20]),
		.qe(),
		.q(),
		.qs(ip0_p6_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RO"),
		.RESVAL(1'h0)
	) u_ip0_p7(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(1'b0),
		.wd(1'sb0),
		.de(hw2reg[21]),
		.d(hw2reg[22]),
		.qe(),
		.q(),
		.qs(ip0_p7_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RO"),
		.RESVAL(1'h0)
	) u_ip0_p8(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(1'b0),
		.wd(1'sb0),
		.de(hw2reg[23]),
		.d(hw2reg[24]),
		.qe(),
		.q(),
		.qs(ip0_p8_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RO"),
		.RESVAL(1'h0)
	) u_ip0_p9(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(1'b0),
		.wd(1'sb0),
		.de(hw2reg[25]),
		.d(hw2reg[26]),
		.qe(),
		.q(),
		.qs(ip0_p9_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RO"),
		.RESVAL(1'h0)
	) u_ip0_p10(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(1'b0),
		.wd(1'sb0),
		.de(hw2reg[27]),
		.d(hw2reg[28]),
		.qe(),
		.q(),
		.qs(ip0_p10_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RO"),
		.RESVAL(1'h0)
	) u_ip0_p11(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(1'b0),
		.wd(1'sb0),
		.de(hw2reg[29]),
		.d(hw2reg[30]),
		.qe(),
		.q(),
		.qs(ip0_p11_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RO"),
		.RESVAL(1'h0)
	) u_ip0_p12(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(1'b0),
		.wd(1'sb0),
		.de(hw2reg[31]),
		.d(hw2reg[32]),
		.qe(),
		.q(),
		.qs(ip0_p12_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RO"),
		.RESVAL(1'h0)
	) u_ip0_p13(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(1'b0),
		.wd(1'sb0),
		.de(hw2reg[33]),
		.d(hw2reg[34]),
		.qe(),
		.q(),
		.qs(ip0_p13_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RO"),
		.RESVAL(1'h0)
	) u_ip0_p14(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(1'b0),
		.wd(1'sb0),
		.de(hw2reg[35]),
		.d(hw2reg[36]),
		.qe(),
		.q(),
		.qs(ip0_p14_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RO"),
		.RESVAL(1'h0)
	) u_ip0_p15(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(1'b0),
		.wd(1'sb0),
		.de(hw2reg[37]),
		.d(hw2reg[38]),
		.qe(),
		.q(),
		.qs(ip0_p15_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RO"),
		.RESVAL(1'h0)
	) u_ip0_p16(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(1'b0),
		.wd(1'sb0),
		.de(hw2reg[39]),
		.d(hw2reg[40]),
		.qe(),
		.q(),
		.qs(ip0_p16_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RO"),
		.RESVAL(1'h0)
	) u_ip0_p17(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(1'b0),
		.wd(1'sb0),
		.de(hw2reg[41]),
		.d(hw2reg[42]),
		.qe(),
		.q(),
		.qs(ip0_p17_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RO"),
		.RESVAL(1'h0)
	) u_ip0_p18(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(1'b0),
		.wd(1'sb0),
		.de(hw2reg[43]),
		.d(hw2reg[44]),
		.qe(),
		.q(),
		.qs(ip0_p18_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RO"),
		.RESVAL(1'h0)
	) u_ip0_p19(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(1'b0),
		.wd(1'sb0),
		.de(hw2reg[45]),
		.d(hw2reg[46]),
		.qe(),
		.q(),
		.qs(ip0_p19_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RO"),
		.RESVAL(1'h0)
	) u_ip0_p20(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(1'b0),
		.wd(1'sb0),
		.de(hw2reg[47]),
		.d(hw2reg[48]),
		.qe(),
		.q(),
		.qs(ip0_p20_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RO"),
		.RESVAL(1'h0)
	) u_ip0_p21(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(1'b0),
		.wd(1'sb0),
		.de(hw2reg[49]),
		.d(hw2reg[50]),
		.qe(),
		.q(),
		.qs(ip0_p21_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RO"),
		.RESVAL(1'h0)
	) u_ip0_p22(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(1'b0),
		.wd(1'sb0),
		.de(hw2reg[51]),
		.d(hw2reg[52]),
		.qe(),
		.q(),
		.qs(ip0_p22_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RO"),
		.RESVAL(1'h0)
	) u_ip0_p23(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(1'b0),
		.wd(1'sb0),
		.de(hw2reg[53]),
		.d(hw2reg[54]),
		.qe(),
		.q(),
		.qs(ip0_p23_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RO"),
		.RESVAL(1'h0)
	) u_ip0_p24(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(1'b0),
		.wd(1'sb0),
		.de(hw2reg[55]),
		.d(hw2reg[56]),
		.qe(),
		.q(),
		.qs(ip0_p24_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RO"),
		.RESVAL(1'h0)
	) u_ip0_p25(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(1'b0),
		.wd(1'sb0),
		.de(hw2reg[57]),
		.d(hw2reg[58]),
		.qe(),
		.q(),
		.qs(ip0_p25_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RO"),
		.RESVAL(1'h0)
	) u_ip0_p26(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(1'b0),
		.wd(1'sb0),
		.de(hw2reg[59]),
		.d(hw2reg[60]),
		.qe(),
		.q(),
		.qs(ip0_p26_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RO"),
		.RESVAL(1'h0)
	) u_ip0_p27(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(1'b0),
		.wd(1'sb0),
		.de(hw2reg[61]),
		.d(hw2reg[62]),
		.qe(),
		.q(),
		.qs(ip0_p27_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RO"),
		.RESVAL(1'h0)
	) u_ip0_p28(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(1'b0),
		.wd(1'sb0),
		.de(hw2reg[63]),
		.d(hw2reg[64]),
		.qe(),
		.q(),
		.qs(ip0_p28_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RO"),
		.RESVAL(1'h0)
	) u_ip0_p29(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(1'b0),
		.wd(1'sb0),
		.de(hw2reg[65]),
		.d(hw2reg[66]),
		.qe(),
		.q(),
		.qs(ip0_p29_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RO"),
		.RESVAL(1'h0)
	) u_ip0_p30(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(1'b0),
		.wd(1'sb0),
		.de(hw2reg[67]),
		.d(hw2reg[68]),
		.qe(),
		.q(),
		.qs(ip0_p30_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RO"),
		.RESVAL(1'h0)
	) u_ip0_p31(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(1'b0),
		.wd(1'sb0),
		.de(hw2reg[69]),
		.d(hw2reg[70]),
		.qe(),
		.q(),
		.qs(ip0_p31_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RO"),
		.RESVAL(1'h0)
	) u_ip1_p32(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(1'b0),
		.wd(1'sb0),
		.de(hw2reg[71]),
		.d(hw2reg[72]),
		.qe(),
		.q(),
		.qs(ip1_p32_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RO"),
		.RESVAL(1'h0)
	) u_ip1_p33(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(1'b0),
		.wd(1'sb0),
		.de(hw2reg[73]),
		.d(hw2reg[74]),
		.qe(),
		.q(),
		.qs(ip1_p33_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RO"),
		.RESVAL(1'h0)
	) u_ip1_p34(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(1'b0),
		.wd(1'sb0),
		.de(hw2reg[75]),
		.d(hw2reg[76]),
		.qe(),
		.q(),
		.qs(ip1_p34_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RO"),
		.RESVAL(1'h0)
	) u_ip1_p35(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(1'b0),
		.wd(1'sb0),
		.de(hw2reg[77]),
		.d(hw2reg[78]),
		.qe(),
		.q(),
		.qs(ip1_p35_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RO"),
		.RESVAL(1'h0)
	) u_ip1_p36(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(1'b0),
		.wd(1'sb0),
		.de(hw2reg[79]),
		.d(hw2reg[80]),
		.qe(),
		.q(),
		.qs(ip1_p36_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RO"),
		.RESVAL(1'h0)
	) u_ip1_p37(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(1'b0),
		.wd(1'sb0),
		.de(hw2reg[81]),
		.d(hw2reg[82]),
		.qe(),
		.q(),
		.qs(ip1_p37_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RO"),
		.RESVAL(1'h0)
	) u_ip1_p38(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(1'b0),
		.wd(1'sb0),
		.de(hw2reg[83]),
		.d(hw2reg[84]),
		.qe(),
		.q(),
		.qs(ip1_p38_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RO"),
		.RESVAL(1'h0)
	) u_ip1_p39(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(1'b0),
		.wd(1'sb0),
		.de(hw2reg[85]),
		.d(hw2reg[86]),
		.qe(),
		.q(),
		.qs(ip1_p39_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RO"),
		.RESVAL(1'h0)
	) u_ip1_p40(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(1'b0),
		.wd(1'sb0),
		.de(hw2reg[87]),
		.d(hw2reg[88]),
		.qe(),
		.q(),
		.qs(ip1_p40_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RO"),
		.RESVAL(1'h0)
	) u_ip1_p41(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(1'b0),
		.wd(1'sb0),
		.de(hw2reg[89]),
		.d(hw2reg[90]),
		.qe(),
		.q(),
		.qs(ip1_p41_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RO"),
		.RESVAL(1'h0)
	) u_ip1_p42(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(1'b0),
		.wd(1'sb0),
		.de(hw2reg[91]),
		.d(hw2reg[92]),
		.qe(),
		.q(),
		.qs(ip1_p42_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RO"),
		.RESVAL(1'h0)
	) u_ip1_p43(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(1'b0),
		.wd(1'sb0),
		.de(hw2reg[93]),
		.d(hw2reg[94]),
		.qe(),
		.q(),
		.qs(ip1_p43_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RO"),
		.RESVAL(1'h0)
	) u_ip1_p44(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(1'b0),
		.wd(1'sb0),
		.de(hw2reg[95]),
		.d(hw2reg[96]),
		.qe(),
		.q(),
		.qs(ip1_p44_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RO"),
		.RESVAL(1'h0)
	) u_ip1_p45(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(1'b0),
		.wd(1'sb0),
		.de(hw2reg[97]),
		.d(hw2reg[98]),
		.qe(),
		.q(),
		.qs(ip1_p45_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RO"),
		.RESVAL(1'h0)
	) u_ip1_p46(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(1'b0),
		.wd(1'sb0),
		.de(hw2reg[99]),
		.d(hw2reg[100]),
		.qe(),
		.q(),
		.qs(ip1_p46_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RO"),
		.RESVAL(1'h0)
	) u_ip1_p47(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(1'b0),
		.wd(1'sb0),
		.de(hw2reg[101]),
		.d(hw2reg[102]),
		.qe(),
		.q(),
		.qs(ip1_p47_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RO"),
		.RESVAL(1'h0)
	) u_ip1_p48(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(1'b0),
		.wd(1'sb0),
		.de(hw2reg[103]),
		.d(hw2reg[104]),
		.qe(),
		.q(),
		.qs(ip1_p48_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RO"),
		.RESVAL(1'h0)
	) u_ip1_p49(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(1'b0),
		.wd(1'sb0),
		.de(hw2reg[105]),
		.d(hw2reg[106]),
		.qe(),
		.q(),
		.qs(ip1_p49_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RO"),
		.RESVAL(1'h0)
	) u_ip1_p50(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(1'b0),
		.wd(1'sb0),
		.de(hw2reg[107]),
		.d(hw2reg[108]),
		.qe(),
		.q(),
		.qs(ip1_p50_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RO"),
		.RESVAL(1'h0)
	) u_ip1_p51(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(1'b0),
		.wd(1'sb0),
		.de(hw2reg[109]),
		.d(hw2reg[110]),
		.qe(),
		.q(),
		.qs(ip1_p51_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RO"),
		.RESVAL(1'h0)
	) u_ip1_p52(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(1'b0),
		.wd(1'sb0),
		.de(hw2reg[111]),
		.d(hw2reg[112]),
		.qe(),
		.q(),
		.qs(ip1_p52_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RO"),
		.RESVAL(1'h0)
	) u_ip1_p53(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(1'b0),
		.wd(1'sb0),
		.de(hw2reg[113]),
		.d(hw2reg[114]),
		.qe(),
		.q(),
		.qs(ip1_p53_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RO"),
		.RESVAL(1'h0)
	) u_ip1_p54(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(1'b0),
		.wd(1'sb0),
		.de(hw2reg[115]),
		.d(hw2reg[116]),
		.qe(),
		.q(),
		.qs(ip1_p54_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RO"),
		.RESVAL(1'h0)
	) u_ip1_p55(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(1'b0),
		.wd(1'sb0),
		.de(hw2reg[117]),
		.d(hw2reg[118]),
		.qe(),
		.q(),
		.qs(ip1_p55_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RO"),
		.RESVAL(1'h0)
	) u_ip1_p56(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(1'b0),
		.wd(1'sb0),
		.de(hw2reg[119]),
		.d(hw2reg[120]),
		.qe(),
		.q(),
		.qs(ip1_p56_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RO"),
		.RESVAL(1'h0)
	) u_ip1_p57(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(1'b0),
		.wd(1'sb0),
		.de(hw2reg[121]),
		.d(hw2reg[122]),
		.qe(),
		.q(),
		.qs(ip1_p57_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RO"),
		.RESVAL(1'h0)
	) u_ip1_p58(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(1'b0),
		.wd(1'sb0),
		.de(hw2reg[123]),
		.d(hw2reg[124]),
		.qe(),
		.q(),
		.qs(ip1_p58_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RO"),
		.RESVAL(1'h0)
	) u_ip1_p59(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(1'b0),
		.wd(1'sb0),
		.de(hw2reg[125]),
		.d(hw2reg[126]),
		.qe(),
		.q(),
		.qs(ip1_p59_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RO"),
		.RESVAL(1'h0)
	) u_ip1_p60(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(1'b0),
		.wd(1'sb0),
		.de(hw2reg[127]),
		.d(hw2reg[128]),
		.qe(),
		.q(),
		.qs(ip1_p60_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RO"),
		.RESVAL(1'h0)
	) u_ip1_p61(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(1'b0),
		.wd(1'sb0),
		.de(hw2reg[129]),
		.d(hw2reg[130]),
		.qe(),
		.q(),
		.qs(ip1_p61_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RO"),
		.RESVAL(1'h0)
	) u_ip1_p62(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(1'b0),
		.wd(1'sb0),
		.de(hw2reg[131]),
		.d(hw2reg[132]),
		.qe(),
		.q(),
		.qs(ip1_p62_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RO"),
		.RESVAL(1'h0)
	) u_ip1_p63(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(1'b0),
		.wd(1'sb0),
		.de(hw2reg[133]),
		.d(hw2reg[134]),
		.qe(),
		.q(),
		.qs(ip1_p63_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RO"),
		.RESVAL(1'h0)
	) u_ip2_p64(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(1'b0),
		.wd(1'sb0),
		.de(hw2reg[135]),
		.d(hw2reg[136]),
		.qe(),
		.q(),
		.qs(ip2_p64_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RO"),
		.RESVAL(1'h0)
	) u_ip2_p65(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(1'b0),
		.wd(1'sb0),
		.de(hw2reg[137]),
		.d(hw2reg[138]),
		.qe(),
		.q(),
		.qs(ip2_p65_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RO"),
		.RESVAL(1'h0)
	) u_ip2_p66(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(1'b0),
		.wd(1'sb0),
		.de(hw2reg[139]),
		.d(hw2reg[140]),
		.qe(),
		.q(),
		.qs(ip2_p66_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RO"),
		.RESVAL(1'h0)
	) u_ip2_p67(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(1'b0),
		.wd(1'sb0),
		.de(hw2reg[141]),
		.d(hw2reg[142]),
		.qe(),
		.q(),
		.qs(ip2_p67_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RO"),
		.RESVAL(1'h0)
	) u_ip2_p68(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(1'b0),
		.wd(1'sb0),
		.de(hw2reg[143]),
		.d(hw2reg[144]),
		.qe(),
		.q(),
		.qs(ip2_p68_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RO"),
		.RESVAL(1'h0)
	) u_ip2_p69(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(1'b0),
		.wd(1'sb0),
		.de(hw2reg[145]),
		.d(hw2reg[146]),
		.qe(),
		.q(),
		.qs(ip2_p69_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RO"),
		.RESVAL(1'h0)
	) u_ip2_p70(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(1'b0),
		.wd(1'sb0),
		.de(hw2reg[147]),
		.d(hw2reg[148]),
		.qe(),
		.q(),
		.qs(ip2_p70_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RO"),
		.RESVAL(1'h0)
	) u_ip2_p71(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(1'b0),
		.wd(1'sb0),
		.de(hw2reg[149]),
		.d(hw2reg[150]),
		.qe(),
		.q(),
		.qs(ip2_p71_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RO"),
		.RESVAL(1'h0)
	) u_ip2_p72(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(1'b0),
		.wd(1'sb0),
		.de(hw2reg[151]),
		.d(hw2reg[152]),
		.qe(),
		.q(),
		.qs(ip2_p72_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RO"),
		.RESVAL(1'h0)
	) u_ip2_p73(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(1'b0),
		.wd(1'sb0),
		.de(hw2reg[153]),
		.d(hw2reg[154]),
		.qe(),
		.q(),
		.qs(ip2_p73_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RO"),
		.RESVAL(1'h0)
	) u_ip2_p74(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(1'b0),
		.wd(1'sb0),
		.de(hw2reg[155]),
		.d(hw2reg[156]),
		.qe(),
		.q(),
		.qs(ip2_p74_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RO"),
		.RESVAL(1'h0)
	) u_ip2_p75(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(1'b0),
		.wd(1'sb0),
		.de(hw2reg[157]),
		.d(hw2reg[158]),
		.qe(),
		.q(),
		.qs(ip2_p75_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RO"),
		.RESVAL(1'h0)
	) u_ip2_p76(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(1'b0),
		.wd(1'sb0),
		.de(hw2reg[159]),
		.d(hw2reg[160]),
		.qe(),
		.q(),
		.qs(ip2_p76_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RO"),
		.RESVAL(1'h0)
	) u_ip2_p77(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(1'b0),
		.wd(1'sb0),
		.de(hw2reg[161]),
		.d(hw2reg[162]),
		.qe(),
		.q(),
		.qs(ip2_p77_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RO"),
		.RESVAL(1'h0)
	) u_ip2_p78(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(1'b0),
		.wd(1'sb0),
		.de(hw2reg[163]),
		.d(hw2reg[164]),
		.qe(),
		.q(),
		.qs(ip2_p78_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_le0_le0(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(le0_le0_we),
		.wd(le0_le0_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[249]),
		.qs(le0_le0_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_le0_le1(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(le0_le1_we),
		.wd(le0_le1_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[250]),
		.qs(le0_le1_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_le0_le2(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(le0_le2_we),
		.wd(le0_le2_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[251]),
		.qs(le0_le2_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_le0_le3(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(le0_le3_we),
		.wd(le0_le3_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[252]),
		.qs(le0_le3_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_le0_le4(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(le0_le4_we),
		.wd(le0_le4_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[253]),
		.qs(le0_le4_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_le0_le5(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(le0_le5_we),
		.wd(le0_le5_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[254]),
		.qs(le0_le5_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_le0_le6(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(le0_le6_we),
		.wd(le0_le6_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[255]),
		.qs(le0_le6_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_le0_le7(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(le0_le7_we),
		.wd(le0_le7_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[256]),
		.qs(le0_le7_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_le0_le8(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(le0_le8_we),
		.wd(le0_le8_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[257]),
		.qs(le0_le8_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_le0_le9(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(le0_le9_we),
		.wd(le0_le9_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[258]),
		.qs(le0_le9_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_le0_le10(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(le0_le10_we),
		.wd(le0_le10_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[259]),
		.qs(le0_le10_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_le0_le11(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(le0_le11_we),
		.wd(le0_le11_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[260]),
		.qs(le0_le11_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_le0_le12(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(le0_le12_we),
		.wd(le0_le12_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[261]),
		.qs(le0_le12_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_le0_le13(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(le0_le13_we),
		.wd(le0_le13_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[262]),
		.qs(le0_le13_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_le0_le14(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(le0_le14_we),
		.wd(le0_le14_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[263]),
		.qs(le0_le14_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_le0_le15(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(le0_le15_we),
		.wd(le0_le15_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[264]),
		.qs(le0_le15_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_le0_le16(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(le0_le16_we),
		.wd(le0_le16_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[265]),
		.qs(le0_le16_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_le0_le17(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(le0_le17_we),
		.wd(le0_le17_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[266]),
		.qs(le0_le17_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_le0_le18(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(le0_le18_we),
		.wd(le0_le18_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[267]),
		.qs(le0_le18_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_le0_le19(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(le0_le19_we),
		.wd(le0_le19_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[268]),
		.qs(le0_le19_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_le0_le20(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(le0_le20_we),
		.wd(le0_le20_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[269]),
		.qs(le0_le20_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_le0_le21(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(le0_le21_we),
		.wd(le0_le21_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[270]),
		.qs(le0_le21_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_le0_le22(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(le0_le22_we),
		.wd(le0_le22_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[271]),
		.qs(le0_le22_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_le0_le23(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(le0_le23_we),
		.wd(le0_le23_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[272]),
		.qs(le0_le23_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_le0_le24(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(le0_le24_we),
		.wd(le0_le24_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[273]),
		.qs(le0_le24_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_le0_le25(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(le0_le25_we),
		.wd(le0_le25_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[274]),
		.qs(le0_le25_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_le0_le26(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(le0_le26_we),
		.wd(le0_le26_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[275]),
		.qs(le0_le26_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_le0_le27(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(le0_le27_we),
		.wd(le0_le27_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[276]),
		.qs(le0_le27_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_le0_le28(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(le0_le28_we),
		.wd(le0_le28_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[277]),
		.qs(le0_le28_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_le0_le29(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(le0_le29_we),
		.wd(le0_le29_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[278]),
		.qs(le0_le29_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_le0_le30(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(le0_le30_we),
		.wd(le0_le30_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[279]),
		.qs(le0_le30_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_le0_le31(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(le0_le31_we),
		.wd(le0_le31_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[280]),
		.qs(le0_le31_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_le1_le32(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(le1_le32_we),
		.wd(le1_le32_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[281]),
		.qs(le1_le32_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_le1_le33(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(le1_le33_we),
		.wd(le1_le33_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[282]),
		.qs(le1_le33_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_le1_le34(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(le1_le34_we),
		.wd(le1_le34_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[283]),
		.qs(le1_le34_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_le1_le35(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(le1_le35_we),
		.wd(le1_le35_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[284]),
		.qs(le1_le35_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_le1_le36(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(le1_le36_we),
		.wd(le1_le36_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[285]),
		.qs(le1_le36_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_le1_le37(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(le1_le37_we),
		.wd(le1_le37_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[286]),
		.qs(le1_le37_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_le1_le38(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(le1_le38_we),
		.wd(le1_le38_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[287]),
		.qs(le1_le38_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_le1_le39(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(le1_le39_we),
		.wd(le1_le39_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[288]),
		.qs(le1_le39_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_le1_le40(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(le1_le40_we),
		.wd(le1_le40_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[289]),
		.qs(le1_le40_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_le1_le41(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(le1_le41_we),
		.wd(le1_le41_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[290]),
		.qs(le1_le41_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_le1_le42(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(le1_le42_we),
		.wd(le1_le42_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[291]),
		.qs(le1_le42_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_le1_le43(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(le1_le43_we),
		.wd(le1_le43_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[292]),
		.qs(le1_le43_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_le1_le44(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(le1_le44_we),
		.wd(le1_le44_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[293]),
		.qs(le1_le44_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_le1_le45(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(le1_le45_we),
		.wd(le1_le45_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[294]),
		.qs(le1_le45_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_le1_le46(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(le1_le46_we),
		.wd(le1_le46_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[295]),
		.qs(le1_le46_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_le1_le47(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(le1_le47_we),
		.wd(le1_le47_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[296]),
		.qs(le1_le47_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_le1_le48(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(le1_le48_we),
		.wd(le1_le48_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[297]),
		.qs(le1_le48_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_le1_le49(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(le1_le49_we),
		.wd(le1_le49_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[298]),
		.qs(le1_le49_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_le1_le50(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(le1_le50_we),
		.wd(le1_le50_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[299]),
		.qs(le1_le50_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_le1_le51(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(le1_le51_we),
		.wd(le1_le51_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[300]),
		.qs(le1_le51_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_le1_le52(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(le1_le52_we),
		.wd(le1_le52_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[301]),
		.qs(le1_le52_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_le1_le53(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(le1_le53_we),
		.wd(le1_le53_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[302]),
		.qs(le1_le53_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_le1_le54(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(le1_le54_we),
		.wd(le1_le54_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[303]),
		.qs(le1_le54_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_le1_le55(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(le1_le55_we),
		.wd(le1_le55_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[304]),
		.qs(le1_le55_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_le1_le56(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(le1_le56_we),
		.wd(le1_le56_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[305]),
		.qs(le1_le56_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_le1_le57(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(le1_le57_we),
		.wd(le1_le57_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[306]),
		.qs(le1_le57_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_le1_le58(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(le1_le58_we),
		.wd(le1_le58_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[307]),
		.qs(le1_le58_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_le1_le59(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(le1_le59_we),
		.wd(le1_le59_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[308]),
		.qs(le1_le59_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_le1_le60(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(le1_le60_we),
		.wd(le1_le60_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[309]),
		.qs(le1_le60_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_le1_le61(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(le1_le61_we),
		.wd(le1_le61_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[310]),
		.qs(le1_le61_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_le1_le62(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(le1_le62_we),
		.wd(le1_le62_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[311]),
		.qs(le1_le62_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_le1_le63(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(le1_le63_we),
		.wd(le1_le63_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[312]),
		.qs(le1_le63_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_le2_le64(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(le2_le64_we),
		.wd(le2_le64_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[313]),
		.qs(le2_le64_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_le2_le65(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(le2_le65_we),
		.wd(le2_le65_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[314]),
		.qs(le2_le65_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_le2_le66(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(le2_le66_we),
		.wd(le2_le66_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[315]),
		.qs(le2_le66_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_le2_le67(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(le2_le67_we),
		.wd(le2_le67_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[316]),
		.qs(le2_le67_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_le2_le68(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(le2_le68_we),
		.wd(le2_le68_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[317]),
		.qs(le2_le68_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_le2_le69(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(le2_le69_we),
		.wd(le2_le69_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[318]),
		.qs(le2_le69_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_le2_le70(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(le2_le70_we),
		.wd(le2_le70_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[319]),
		.qs(le2_le70_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_le2_le71(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(le2_le71_we),
		.wd(le2_le71_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[320]),
		.qs(le2_le71_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_le2_le72(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(le2_le72_we),
		.wd(le2_le72_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[321]),
		.qs(le2_le72_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_le2_le73(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(le2_le73_we),
		.wd(le2_le73_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[322]),
		.qs(le2_le73_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_le2_le74(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(le2_le74_we),
		.wd(le2_le74_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[323]),
		.qs(le2_le74_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_le2_le75(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(le2_le75_we),
		.wd(le2_le75_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[324]),
		.qs(le2_le75_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_le2_le76(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(le2_le76_we),
		.wd(le2_le76_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[325]),
		.qs(le2_le76_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_le2_le77(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(le2_le77_we),
		.wd(le2_le77_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[326]),
		.qs(le2_le77_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_le2_le78(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(le2_le78_we),
		.wd(le2_le78_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[327]),
		.qs(le2_le78_qs)
	);
	prim_subreg #(
		.DW(2),
		.SWACCESS("RW"),
		.RESVAL(2'h0)
	) u_prio0(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(prio0_we),
		.wd(prio0_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[248-:2]),
		.qs(prio0_qs)
	);
	prim_subreg #(
		.DW(2),
		.SWACCESS("RW"),
		.RESVAL(2'h0)
	) u_prio1(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(prio1_we),
		.wd(prio1_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[246-:2]),
		.qs(prio1_qs)
	);
	prim_subreg #(
		.DW(2),
		.SWACCESS("RW"),
		.RESVAL(2'h0)
	) u_prio2(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(prio2_we),
		.wd(prio2_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[244-:2]),
		.qs(prio2_qs)
	);
	prim_subreg #(
		.DW(2),
		.SWACCESS("RW"),
		.RESVAL(2'h0)
	) u_prio3(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(prio3_we),
		.wd(prio3_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[242-:2]),
		.qs(prio3_qs)
	);
	prim_subreg #(
		.DW(2),
		.SWACCESS("RW"),
		.RESVAL(2'h0)
	) u_prio4(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(prio4_we),
		.wd(prio4_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[240-:2]),
		.qs(prio4_qs)
	);
	prim_subreg #(
		.DW(2),
		.SWACCESS("RW"),
		.RESVAL(2'h0)
	) u_prio5(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(prio5_we),
		.wd(prio5_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[238-:2]),
		.qs(prio5_qs)
	);
	prim_subreg #(
		.DW(2),
		.SWACCESS("RW"),
		.RESVAL(2'h0)
	) u_prio6(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(prio6_we),
		.wd(prio6_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[236-:2]),
		.qs(prio6_qs)
	);
	prim_subreg #(
		.DW(2),
		.SWACCESS("RW"),
		.RESVAL(2'h0)
	) u_prio7(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(prio7_we),
		.wd(prio7_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[234-:2]),
		.qs(prio7_qs)
	);
	prim_subreg #(
		.DW(2),
		.SWACCESS("RW"),
		.RESVAL(2'h0)
	) u_prio8(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(prio8_we),
		.wd(prio8_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[232-:2]),
		.qs(prio8_qs)
	);
	prim_subreg #(
		.DW(2),
		.SWACCESS("RW"),
		.RESVAL(2'h0)
	) u_prio9(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(prio9_we),
		.wd(prio9_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[230-:2]),
		.qs(prio9_qs)
	);
	prim_subreg #(
		.DW(2),
		.SWACCESS("RW"),
		.RESVAL(2'h0)
	) u_prio10(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(prio10_we),
		.wd(prio10_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[228-:2]),
		.qs(prio10_qs)
	);
	prim_subreg #(
		.DW(2),
		.SWACCESS("RW"),
		.RESVAL(2'h0)
	) u_prio11(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(prio11_we),
		.wd(prio11_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[226-:2]),
		.qs(prio11_qs)
	);
	prim_subreg #(
		.DW(2),
		.SWACCESS("RW"),
		.RESVAL(2'h0)
	) u_prio12(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(prio12_we),
		.wd(prio12_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[224-:2]),
		.qs(prio12_qs)
	);
	prim_subreg #(
		.DW(2),
		.SWACCESS("RW"),
		.RESVAL(2'h0)
	) u_prio13(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(prio13_we),
		.wd(prio13_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[222-:2]),
		.qs(prio13_qs)
	);
	prim_subreg #(
		.DW(2),
		.SWACCESS("RW"),
		.RESVAL(2'h0)
	) u_prio14(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(prio14_we),
		.wd(prio14_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[220-:2]),
		.qs(prio14_qs)
	);
	prim_subreg #(
		.DW(2),
		.SWACCESS("RW"),
		.RESVAL(2'h0)
	) u_prio15(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(prio15_we),
		.wd(prio15_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[218-:2]),
		.qs(prio15_qs)
	);
	prim_subreg #(
		.DW(2),
		.SWACCESS("RW"),
		.RESVAL(2'h0)
	) u_prio16(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(prio16_we),
		.wd(prio16_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[216-:2]),
		.qs(prio16_qs)
	);
	prim_subreg #(
		.DW(2),
		.SWACCESS("RW"),
		.RESVAL(2'h0)
	) u_prio17(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(prio17_we),
		.wd(prio17_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[214-:2]),
		.qs(prio17_qs)
	);
	prim_subreg #(
		.DW(2),
		.SWACCESS("RW"),
		.RESVAL(2'h0)
	) u_prio18(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(prio18_we),
		.wd(prio18_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[212-:2]),
		.qs(prio18_qs)
	);
	prim_subreg #(
		.DW(2),
		.SWACCESS("RW"),
		.RESVAL(2'h0)
	) u_prio19(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(prio19_we),
		.wd(prio19_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[210-:2]),
		.qs(prio19_qs)
	);
	prim_subreg #(
		.DW(2),
		.SWACCESS("RW"),
		.RESVAL(2'h0)
	) u_prio20(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(prio20_we),
		.wd(prio20_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[208-:2]),
		.qs(prio20_qs)
	);
	prim_subreg #(
		.DW(2),
		.SWACCESS("RW"),
		.RESVAL(2'h0)
	) u_prio21(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(prio21_we),
		.wd(prio21_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[206-:2]),
		.qs(prio21_qs)
	);
	prim_subreg #(
		.DW(2),
		.SWACCESS("RW"),
		.RESVAL(2'h0)
	) u_prio22(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(prio22_we),
		.wd(prio22_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[204-:2]),
		.qs(prio22_qs)
	);
	prim_subreg #(
		.DW(2),
		.SWACCESS("RW"),
		.RESVAL(2'h0)
	) u_prio23(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(prio23_we),
		.wd(prio23_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[202-:2]),
		.qs(prio23_qs)
	);
	prim_subreg #(
		.DW(2),
		.SWACCESS("RW"),
		.RESVAL(2'h0)
	) u_prio24(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(prio24_we),
		.wd(prio24_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[200-:2]),
		.qs(prio24_qs)
	);
	prim_subreg #(
		.DW(2),
		.SWACCESS("RW"),
		.RESVAL(2'h0)
	) u_prio25(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(prio25_we),
		.wd(prio25_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[198-:2]),
		.qs(prio25_qs)
	);
	prim_subreg #(
		.DW(2),
		.SWACCESS("RW"),
		.RESVAL(2'h0)
	) u_prio26(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(prio26_we),
		.wd(prio26_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[196-:2]),
		.qs(prio26_qs)
	);
	prim_subreg #(
		.DW(2),
		.SWACCESS("RW"),
		.RESVAL(2'h0)
	) u_prio27(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(prio27_we),
		.wd(prio27_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[194-:2]),
		.qs(prio27_qs)
	);
	prim_subreg #(
		.DW(2),
		.SWACCESS("RW"),
		.RESVAL(2'h0)
	) u_prio28(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(prio28_we),
		.wd(prio28_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[192-:2]),
		.qs(prio28_qs)
	);
	prim_subreg #(
		.DW(2),
		.SWACCESS("RW"),
		.RESVAL(2'h0)
	) u_prio29(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(prio29_we),
		.wd(prio29_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[190-:2]),
		.qs(prio29_qs)
	);
	prim_subreg #(
		.DW(2),
		.SWACCESS("RW"),
		.RESVAL(2'h0)
	) u_prio30(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(prio30_we),
		.wd(prio30_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[188-:2]),
		.qs(prio30_qs)
	);
	prim_subreg #(
		.DW(2),
		.SWACCESS("RW"),
		.RESVAL(2'h0)
	) u_prio31(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(prio31_we),
		.wd(prio31_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[186-:2]),
		.qs(prio31_qs)
	);
	prim_subreg #(
		.DW(2),
		.SWACCESS("RW"),
		.RESVAL(2'h0)
	) u_prio32(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(prio32_we),
		.wd(prio32_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[184-:2]),
		.qs(prio32_qs)
	);
	prim_subreg #(
		.DW(2),
		.SWACCESS("RW"),
		.RESVAL(2'h0)
	) u_prio33(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(prio33_we),
		.wd(prio33_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[182-:2]),
		.qs(prio33_qs)
	);
	prim_subreg #(
		.DW(2),
		.SWACCESS("RW"),
		.RESVAL(2'h0)
	) u_prio34(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(prio34_we),
		.wd(prio34_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[180-:2]),
		.qs(prio34_qs)
	);
	prim_subreg #(
		.DW(2),
		.SWACCESS("RW"),
		.RESVAL(2'h0)
	) u_prio35(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(prio35_we),
		.wd(prio35_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[178-:2]),
		.qs(prio35_qs)
	);
	prim_subreg #(
		.DW(2),
		.SWACCESS("RW"),
		.RESVAL(2'h0)
	) u_prio36(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(prio36_we),
		.wd(prio36_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[176-:2]),
		.qs(prio36_qs)
	);
	prim_subreg #(
		.DW(2),
		.SWACCESS("RW"),
		.RESVAL(2'h0)
	) u_prio37(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(prio37_we),
		.wd(prio37_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[174-:2]),
		.qs(prio37_qs)
	);
	prim_subreg #(
		.DW(2),
		.SWACCESS("RW"),
		.RESVAL(2'h0)
	) u_prio38(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(prio38_we),
		.wd(prio38_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[172-:2]),
		.qs(prio38_qs)
	);
	prim_subreg #(
		.DW(2),
		.SWACCESS("RW"),
		.RESVAL(2'h0)
	) u_prio39(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(prio39_we),
		.wd(prio39_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[170-:2]),
		.qs(prio39_qs)
	);
	prim_subreg #(
		.DW(2),
		.SWACCESS("RW"),
		.RESVAL(2'h0)
	) u_prio40(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(prio40_we),
		.wd(prio40_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[168-:2]),
		.qs(prio40_qs)
	);
	prim_subreg #(
		.DW(2),
		.SWACCESS("RW"),
		.RESVAL(2'h0)
	) u_prio41(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(prio41_we),
		.wd(prio41_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[166-:2]),
		.qs(prio41_qs)
	);
	prim_subreg #(
		.DW(2),
		.SWACCESS("RW"),
		.RESVAL(2'h0)
	) u_prio42(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(prio42_we),
		.wd(prio42_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[164-:2]),
		.qs(prio42_qs)
	);
	prim_subreg #(
		.DW(2),
		.SWACCESS("RW"),
		.RESVAL(2'h0)
	) u_prio43(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(prio43_we),
		.wd(prio43_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[162-:2]),
		.qs(prio43_qs)
	);
	prim_subreg #(
		.DW(2),
		.SWACCESS("RW"),
		.RESVAL(2'h0)
	) u_prio44(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(prio44_we),
		.wd(prio44_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[160-:2]),
		.qs(prio44_qs)
	);
	prim_subreg #(
		.DW(2),
		.SWACCESS("RW"),
		.RESVAL(2'h0)
	) u_prio45(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(prio45_we),
		.wd(prio45_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[158-:2]),
		.qs(prio45_qs)
	);
	prim_subreg #(
		.DW(2),
		.SWACCESS("RW"),
		.RESVAL(2'h0)
	) u_prio46(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(prio46_we),
		.wd(prio46_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[156-:2]),
		.qs(prio46_qs)
	);
	prim_subreg #(
		.DW(2),
		.SWACCESS("RW"),
		.RESVAL(2'h0)
	) u_prio47(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(prio47_we),
		.wd(prio47_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[154-:2]),
		.qs(prio47_qs)
	);
	prim_subreg #(
		.DW(2),
		.SWACCESS("RW"),
		.RESVAL(2'h0)
	) u_prio48(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(prio48_we),
		.wd(prio48_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[152-:2]),
		.qs(prio48_qs)
	);
	prim_subreg #(
		.DW(2),
		.SWACCESS("RW"),
		.RESVAL(2'h0)
	) u_prio49(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(prio49_we),
		.wd(prio49_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[150-:2]),
		.qs(prio49_qs)
	);
	prim_subreg #(
		.DW(2),
		.SWACCESS("RW"),
		.RESVAL(2'h0)
	) u_prio50(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(prio50_we),
		.wd(prio50_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[148-:2]),
		.qs(prio50_qs)
	);
	prim_subreg #(
		.DW(2),
		.SWACCESS("RW"),
		.RESVAL(2'h0)
	) u_prio51(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(prio51_we),
		.wd(prio51_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[146-:2]),
		.qs(prio51_qs)
	);
	prim_subreg #(
		.DW(2),
		.SWACCESS("RW"),
		.RESVAL(2'h0)
	) u_prio52(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(prio52_we),
		.wd(prio52_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[144-:2]),
		.qs(prio52_qs)
	);
	prim_subreg #(
		.DW(2),
		.SWACCESS("RW"),
		.RESVAL(2'h0)
	) u_prio53(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(prio53_we),
		.wd(prio53_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[142-:2]),
		.qs(prio53_qs)
	);
	prim_subreg #(
		.DW(2),
		.SWACCESS("RW"),
		.RESVAL(2'h0)
	) u_prio54(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(prio54_we),
		.wd(prio54_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[140-:2]),
		.qs(prio54_qs)
	);
	prim_subreg #(
		.DW(2),
		.SWACCESS("RW"),
		.RESVAL(2'h0)
	) u_prio55(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(prio55_we),
		.wd(prio55_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[138-:2]),
		.qs(prio55_qs)
	);
	prim_subreg #(
		.DW(2),
		.SWACCESS("RW"),
		.RESVAL(2'h0)
	) u_prio56(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(prio56_we),
		.wd(prio56_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[136-:2]),
		.qs(prio56_qs)
	);
	prim_subreg #(
		.DW(2),
		.SWACCESS("RW"),
		.RESVAL(2'h0)
	) u_prio57(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(prio57_we),
		.wd(prio57_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[134-:2]),
		.qs(prio57_qs)
	);
	prim_subreg #(
		.DW(2),
		.SWACCESS("RW"),
		.RESVAL(2'h0)
	) u_prio58(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(prio58_we),
		.wd(prio58_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[132-:2]),
		.qs(prio58_qs)
	);
	prim_subreg #(
		.DW(2),
		.SWACCESS("RW"),
		.RESVAL(2'h0)
	) u_prio59(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(prio59_we),
		.wd(prio59_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[130-:2]),
		.qs(prio59_qs)
	);
	prim_subreg #(
		.DW(2),
		.SWACCESS("RW"),
		.RESVAL(2'h0)
	) u_prio60(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(prio60_we),
		.wd(prio60_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[128-:2]),
		.qs(prio60_qs)
	);
	prim_subreg #(
		.DW(2),
		.SWACCESS("RW"),
		.RESVAL(2'h0)
	) u_prio61(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(prio61_we),
		.wd(prio61_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[126-:2]),
		.qs(prio61_qs)
	);
	prim_subreg #(
		.DW(2),
		.SWACCESS("RW"),
		.RESVAL(2'h0)
	) u_prio62(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(prio62_we),
		.wd(prio62_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[124-:2]),
		.qs(prio62_qs)
	);
	prim_subreg #(
		.DW(2),
		.SWACCESS("RW"),
		.RESVAL(2'h0)
	) u_prio63(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(prio63_we),
		.wd(prio63_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[122-:2]),
		.qs(prio63_qs)
	);
	prim_subreg #(
		.DW(2),
		.SWACCESS("RW"),
		.RESVAL(2'h0)
	) u_prio64(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(prio64_we),
		.wd(prio64_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[120-:2]),
		.qs(prio64_qs)
	);
	prim_subreg #(
		.DW(2),
		.SWACCESS("RW"),
		.RESVAL(2'h0)
	) u_prio65(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(prio65_we),
		.wd(prio65_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[118-:2]),
		.qs(prio65_qs)
	);
	prim_subreg #(
		.DW(2),
		.SWACCESS("RW"),
		.RESVAL(2'h0)
	) u_prio66(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(prio66_we),
		.wd(prio66_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[116-:2]),
		.qs(prio66_qs)
	);
	prim_subreg #(
		.DW(2),
		.SWACCESS("RW"),
		.RESVAL(2'h0)
	) u_prio67(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(prio67_we),
		.wd(prio67_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[114-:2]),
		.qs(prio67_qs)
	);
	prim_subreg #(
		.DW(2),
		.SWACCESS("RW"),
		.RESVAL(2'h0)
	) u_prio68(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(prio68_we),
		.wd(prio68_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[112-:2]),
		.qs(prio68_qs)
	);
	prim_subreg #(
		.DW(2),
		.SWACCESS("RW"),
		.RESVAL(2'h0)
	) u_prio69(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(prio69_we),
		.wd(prio69_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[110-:2]),
		.qs(prio69_qs)
	);
	prim_subreg #(
		.DW(2),
		.SWACCESS("RW"),
		.RESVAL(2'h0)
	) u_prio70(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(prio70_we),
		.wd(prio70_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[108-:2]),
		.qs(prio70_qs)
	);
	prim_subreg #(
		.DW(2),
		.SWACCESS("RW"),
		.RESVAL(2'h0)
	) u_prio71(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(prio71_we),
		.wd(prio71_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[106-:2]),
		.qs(prio71_qs)
	);
	prim_subreg #(
		.DW(2),
		.SWACCESS("RW"),
		.RESVAL(2'h0)
	) u_prio72(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(prio72_we),
		.wd(prio72_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[104-:2]),
		.qs(prio72_qs)
	);
	prim_subreg #(
		.DW(2),
		.SWACCESS("RW"),
		.RESVAL(2'h0)
	) u_prio73(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(prio73_we),
		.wd(prio73_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[102-:2]),
		.qs(prio73_qs)
	);
	prim_subreg #(
		.DW(2),
		.SWACCESS("RW"),
		.RESVAL(2'h0)
	) u_prio74(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(prio74_we),
		.wd(prio74_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[100-:2]),
		.qs(prio74_qs)
	);
	prim_subreg #(
		.DW(2),
		.SWACCESS("RW"),
		.RESVAL(2'h0)
	) u_prio75(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(prio75_we),
		.wd(prio75_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[98-:2]),
		.qs(prio75_qs)
	);
	prim_subreg #(
		.DW(2),
		.SWACCESS("RW"),
		.RESVAL(2'h0)
	) u_prio76(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(prio76_we),
		.wd(prio76_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[96-:2]),
		.qs(prio76_qs)
	);
	prim_subreg #(
		.DW(2),
		.SWACCESS("RW"),
		.RESVAL(2'h0)
	) u_prio77(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(prio77_we),
		.wd(prio77_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[94-:2]),
		.qs(prio77_qs)
	);
	prim_subreg #(
		.DW(2),
		.SWACCESS("RW"),
		.RESVAL(2'h0)
	) u_prio78(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(prio78_we),
		.wd(prio78_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[92-:2]),
		.qs(prio78_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_ie00_e0(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(ie00_e0_we),
		.wd(ie00_e0_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[12]),
		.qs(ie00_e0_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_ie00_e1(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(ie00_e1_we),
		.wd(ie00_e1_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[13]),
		.qs(ie00_e1_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_ie00_e2(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(ie00_e2_we),
		.wd(ie00_e2_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[14]),
		.qs(ie00_e2_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_ie00_e3(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(ie00_e3_we),
		.wd(ie00_e3_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[15]),
		.qs(ie00_e3_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_ie00_e4(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(ie00_e4_we),
		.wd(ie00_e4_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[16]),
		.qs(ie00_e4_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_ie00_e5(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(ie00_e5_we),
		.wd(ie00_e5_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[17]),
		.qs(ie00_e5_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_ie00_e6(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(ie00_e6_we),
		.wd(ie00_e6_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[18]),
		.qs(ie00_e6_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_ie00_e7(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(ie00_e7_we),
		.wd(ie00_e7_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[19]),
		.qs(ie00_e7_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_ie00_e8(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(ie00_e8_we),
		.wd(ie00_e8_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[20]),
		.qs(ie00_e8_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_ie00_e9(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(ie00_e9_we),
		.wd(ie00_e9_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[21]),
		.qs(ie00_e9_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_ie00_e10(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(ie00_e10_we),
		.wd(ie00_e10_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[22]),
		.qs(ie00_e10_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_ie00_e11(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(ie00_e11_we),
		.wd(ie00_e11_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[23]),
		.qs(ie00_e11_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_ie00_e12(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(ie00_e12_we),
		.wd(ie00_e12_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[24]),
		.qs(ie00_e12_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_ie00_e13(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(ie00_e13_we),
		.wd(ie00_e13_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[25]),
		.qs(ie00_e13_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_ie00_e14(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(ie00_e14_we),
		.wd(ie00_e14_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[26]),
		.qs(ie00_e14_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_ie00_e15(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(ie00_e15_we),
		.wd(ie00_e15_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[27]),
		.qs(ie00_e15_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_ie00_e16(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(ie00_e16_we),
		.wd(ie00_e16_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[28]),
		.qs(ie00_e16_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_ie00_e17(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(ie00_e17_we),
		.wd(ie00_e17_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[29]),
		.qs(ie00_e17_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_ie00_e18(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(ie00_e18_we),
		.wd(ie00_e18_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[30]),
		.qs(ie00_e18_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_ie00_e19(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(ie00_e19_we),
		.wd(ie00_e19_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[31]),
		.qs(ie00_e19_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_ie00_e20(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(ie00_e20_we),
		.wd(ie00_e20_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[32]),
		.qs(ie00_e20_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_ie00_e21(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(ie00_e21_we),
		.wd(ie00_e21_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[33]),
		.qs(ie00_e21_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_ie00_e22(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(ie00_e22_we),
		.wd(ie00_e22_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[34]),
		.qs(ie00_e22_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_ie00_e23(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(ie00_e23_we),
		.wd(ie00_e23_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[35]),
		.qs(ie00_e23_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_ie00_e24(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(ie00_e24_we),
		.wd(ie00_e24_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[36]),
		.qs(ie00_e24_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_ie00_e25(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(ie00_e25_we),
		.wd(ie00_e25_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[37]),
		.qs(ie00_e25_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_ie00_e26(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(ie00_e26_we),
		.wd(ie00_e26_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[38]),
		.qs(ie00_e26_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_ie00_e27(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(ie00_e27_we),
		.wd(ie00_e27_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[39]),
		.qs(ie00_e27_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_ie00_e28(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(ie00_e28_we),
		.wd(ie00_e28_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[40]),
		.qs(ie00_e28_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_ie00_e29(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(ie00_e29_we),
		.wd(ie00_e29_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[41]),
		.qs(ie00_e29_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_ie00_e30(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(ie00_e30_we),
		.wd(ie00_e30_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[42]),
		.qs(ie00_e30_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_ie00_e31(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(ie00_e31_we),
		.wd(ie00_e31_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[43]),
		.qs(ie00_e31_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_ie01_e32(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(ie01_e32_we),
		.wd(ie01_e32_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[44]),
		.qs(ie01_e32_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_ie01_e33(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(ie01_e33_we),
		.wd(ie01_e33_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[45]),
		.qs(ie01_e33_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_ie01_e34(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(ie01_e34_we),
		.wd(ie01_e34_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[46]),
		.qs(ie01_e34_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_ie01_e35(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(ie01_e35_we),
		.wd(ie01_e35_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[47]),
		.qs(ie01_e35_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_ie01_e36(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(ie01_e36_we),
		.wd(ie01_e36_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[48]),
		.qs(ie01_e36_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_ie01_e37(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(ie01_e37_we),
		.wd(ie01_e37_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[49]),
		.qs(ie01_e37_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_ie01_e38(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(ie01_e38_we),
		.wd(ie01_e38_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[50]),
		.qs(ie01_e38_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_ie01_e39(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(ie01_e39_we),
		.wd(ie01_e39_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[51]),
		.qs(ie01_e39_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_ie01_e40(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(ie01_e40_we),
		.wd(ie01_e40_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[52]),
		.qs(ie01_e40_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_ie01_e41(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(ie01_e41_we),
		.wd(ie01_e41_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[53]),
		.qs(ie01_e41_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_ie01_e42(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(ie01_e42_we),
		.wd(ie01_e42_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[54]),
		.qs(ie01_e42_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_ie01_e43(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(ie01_e43_we),
		.wd(ie01_e43_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[55]),
		.qs(ie01_e43_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_ie01_e44(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(ie01_e44_we),
		.wd(ie01_e44_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[56]),
		.qs(ie01_e44_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_ie01_e45(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(ie01_e45_we),
		.wd(ie01_e45_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[57]),
		.qs(ie01_e45_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_ie01_e46(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(ie01_e46_we),
		.wd(ie01_e46_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[58]),
		.qs(ie01_e46_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_ie01_e47(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(ie01_e47_we),
		.wd(ie01_e47_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[59]),
		.qs(ie01_e47_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_ie01_e48(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(ie01_e48_we),
		.wd(ie01_e48_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[60]),
		.qs(ie01_e48_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_ie01_e49(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(ie01_e49_we),
		.wd(ie01_e49_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[61]),
		.qs(ie01_e49_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_ie01_e50(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(ie01_e50_we),
		.wd(ie01_e50_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[62]),
		.qs(ie01_e50_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_ie01_e51(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(ie01_e51_we),
		.wd(ie01_e51_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[63]),
		.qs(ie01_e51_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_ie01_e52(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(ie01_e52_we),
		.wd(ie01_e52_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[64]),
		.qs(ie01_e52_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_ie01_e53(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(ie01_e53_we),
		.wd(ie01_e53_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[65]),
		.qs(ie01_e53_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_ie01_e54(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(ie01_e54_we),
		.wd(ie01_e54_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[66]),
		.qs(ie01_e54_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_ie01_e55(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(ie01_e55_we),
		.wd(ie01_e55_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[67]),
		.qs(ie01_e55_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_ie01_e56(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(ie01_e56_we),
		.wd(ie01_e56_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[68]),
		.qs(ie01_e56_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_ie01_e57(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(ie01_e57_we),
		.wd(ie01_e57_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[69]),
		.qs(ie01_e57_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_ie01_e58(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(ie01_e58_we),
		.wd(ie01_e58_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[70]),
		.qs(ie01_e58_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_ie01_e59(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(ie01_e59_we),
		.wd(ie01_e59_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[71]),
		.qs(ie01_e59_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_ie01_e60(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(ie01_e60_we),
		.wd(ie01_e60_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[72]),
		.qs(ie01_e60_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_ie01_e61(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(ie01_e61_we),
		.wd(ie01_e61_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[73]),
		.qs(ie01_e61_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_ie01_e62(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(ie01_e62_we),
		.wd(ie01_e62_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[74]),
		.qs(ie01_e62_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_ie01_e63(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(ie01_e63_we),
		.wd(ie01_e63_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[75]),
		.qs(ie01_e63_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_ie02_e64(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(ie02_e64_we),
		.wd(ie02_e64_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[76]),
		.qs(ie02_e64_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_ie02_e65(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(ie02_e65_we),
		.wd(ie02_e65_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[77]),
		.qs(ie02_e65_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_ie02_e66(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(ie02_e66_we),
		.wd(ie02_e66_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[78]),
		.qs(ie02_e66_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_ie02_e67(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(ie02_e67_we),
		.wd(ie02_e67_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[79]),
		.qs(ie02_e67_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_ie02_e68(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(ie02_e68_we),
		.wd(ie02_e68_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[80]),
		.qs(ie02_e68_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_ie02_e69(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(ie02_e69_we),
		.wd(ie02_e69_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[81]),
		.qs(ie02_e69_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_ie02_e70(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(ie02_e70_we),
		.wd(ie02_e70_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[82]),
		.qs(ie02_e70_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_ie02_e71(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(ie02_e71_we),
		.wd(ie02_e71_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[83]),
		.qs(ie02_e71_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_ie02_e72(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(ie02_e72_we),
		.wd(ie02_e72_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[84]),
		.qs(ie02_e72_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_ie02_e73(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(ie02_e73_we),
		.wd(ie02_e73_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[85]),
		.qs(ie02_e73_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_ie02_e74(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(ie02_e74_we),
		.wd(ie02_e74_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[86]),
		.qs(ie02_e74_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_ie02_e75(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(ie02_e75_we),
		.wd(ie02_e75_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[87]),
		.qs(ie02_e75_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_ie02_e76(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(ie02_e76_we),
		.wd(ie02_e76_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[88]),
		.qs(ie02_e76_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_ie02_e77(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(ie02_e77_we),
		.wd(ie02_e77_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[89]),
		.qs(ie02_e77_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_ie02_e78(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(ie02_e78_we),
		.wd(ie02_e78_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[90]),
		.qs(ie02_e78_qs)
	);
	prim_subreg #(
		.DW(2),
		.SWACCESS("RW"),
		.RESVAL(2'h0)
	) u_threshold0(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(threshold0_we),
		.wd(threshold0_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[11-:2]),
		.qs(threshold0_qs)
	);
	prim_subreg_ext #(.DW(7)) u_cc0(
		.re(cc0_re),
		.we(cc0_we),
		.wd(cc0_wd),
		.d(hw2reg[6-:7]),
		.qre(reg2hw[1]),
		.qe(reg2hw[2]),
		.q(reg2hw[9-:7]),
		.qs(cc0_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_msip0(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(msip0_we),
		.wd(msip0_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[0]),
		.qs(msip0_qs)
	);
	reg [90:0] addr_hit;
	always @(*) begin
		addr_hit = 1'sb0;
		addr_hit[0] = reg_addr == RV_PLIC_IP0_OFFSET;
		addr_hit[1] = reg_addr == RV_PLIC_IP1_OFFSET;
		addr_hit[2] = reg_addr == RV_PLIC_IP2_OFFSET;
		addr_hit[3] = reg_addr == RV_PLIC_LE0_OFFSET;
		addr_hit[4] = reg_addr == RV_PLIC_LE1_OFFSET;
		addr_hit[5] = reg_addr == RV_PLIC_LE2_OFFSET;
		addr_hit[6] = reg_addr == RV_PLIC_PRIO0_OFFSET;
		addr_hit[7] = reg_addr == RV_PLIC_PRIO1_OFFSET;
		addr_hit[8] = reg_addr == RV_PLIC_PRIO2_OFFSET;
		addr_hit[9] = reg_addr == RV_PLIC_PRIO3_OFFSET;
		addr_hit[10] = reg_addr == RV_PLIC_PRIO4_OFFSET;
		addr_hit[11] = reg_addr == RV_PLIC_PRIO5_OFFSET;
		addr_hit[12] = reg_addr == RV_PLIC_PRIO6_OFFSET;
		addr_hit[13] = reg_addr == RV_PLIC_PRIO7_OFFSET;
		addr_hit[14] = reg_addr == RV_PLIC_PRIO8_OFFSET;
		addr_hit[15] = reg_addr == RV_PLIC_PRIO9_OFFSET;
		addr_hit[16] = reg_addr == RV_PLIC_PRIO10_OFFSET;
		addr_hit[17] = reg_addr == RV_PLIC_PRIO11_OFFSET;
		addr_hit[18] = reg_addr == RV_PLIC_PRIO12_OFFSET;
		addr_hit[19] = reg_addr == RV_PLIC_PRIO13_OFFSET;
		addr_hit[20] = reg_addr == RV_PLIC_PRIO14_OFFSET;
		addr_hit[21] = reg_addr == RV_PLIC_PRIO15_OFFSET;
		addr_hit[22] = reg_addr == RV_PLIC_PRIO16_OFFSET;
		addr_hit[23] = reg_addr == RV_PLIC_PRIO17_OFFSET;
		addr_hit[24] = reg_addr == RV_PLIC_PRIO18_OFFSET;
		addr_hit[25] = reg_addr == RV_PLIC_PRIO19_OFFSET;
		addr_hit[26] = reg_addr == RV_PLIC_PRIO20_OFFSET;
		addr_hit[27] = reg_addr == RV_PLIC_PRIO21_OFFSET;
		addr_hit[28] = reg_addr == RV_PLIC_PRIO22_OFFSET;
		addr_hit[29] = reg_addr == RV_PLIC_PRIO23_OFFSET;
		addr_hit[30] = reg_addr == RV_PLIC_PRIO24_OFFSET;
		addr_hit[31] = reg_addr == RV_PLIC_PRIO25_OFFSET;
		addr_hit[32] = reg_addr == RV_PLIC_PRIO26_OFFSET;
		addr_hit[33] = reg_addr == RV_PLIC_PRIO27_OFFSET;
		addr_hit[34] = reg_addr == RV_PLIC_PRIO28_OFFSET;
		addr_hit[35] = reg_addr == RV_PLIC_PRIO29_OFFSET;
		addr_hit[36] = reg_addr == RV_PLIC_PRIO30_OFFSET;
		addr_hit[37] = reg_addr == RV_PLIC_PRIO31_OFFSET;
		addr_hit[38] = reg_addr == RV_PLIC_PRIO32_OFFSET;
		addr_hit[39] = reg_addr == RV_PLIC_PRIO33_OFFSET;
		addr_hit[40] = reg_addr == RV_PLIC_PRIO34_OFFSET;
		addr_hit[41] = reg_addr == RV_PLIC_PRIO35_OFFSET;
		addr_hit[42] = reg_addr == RV_PLIC_PRIO36_OFFSET;
		addr_hit[43] = reg_addr == RV_PLIC_PRIO37_OFFSET;
		addr_hit[44] = reg_addr == RV_PLIC_PRIO38_OFFSET;
		addr_hit[45] = reg_addr == RV_PLIC_PRIO39_OFFSET;
		addr_hit[46] = reg_addr == RV_PLIC_PRIO40_OFFSET;
		addr_hit[47] = reg_addr == RV_PLIC_PRIO41_OFFSET;
		addr_hit[48] = reg_addr == RV_PLIC_PRIO42_OFFSET;
		addr_hit[49] = reg_addr == RV_PLIC_PRIO43_OFFSET;
		addr_hit[50] = reg_addr == RV_PLIC_PRIO44_OFFSET;
		addr_hit[51] = reg_addr == RV_PLIC_PRIO45_OFFSET;
		addr_hit[52] = reg_addr == RV_PLIC_PRIO46_OFFSET;
		addr_hit[53] = reg_addr == RV_PLIC_PRIO47_OFFSET;
		addr_hit[54] = reg_addr == RV_PLIC_PRIO48_OFFSET;
		addr_hit[55] = reg_addr == RV_PLIC_PRIO49_OFFSET;
		addr_hit[56] = reg_addr == RV_PLIC_PRIO50_OFFSET;
		addr_hit[57] = reg_addr == RV_PLIC_PRIO51_OFFSET;
		addr_hit[58] = reg_addr == RV_PLIC_PRIO52_OFFSET;
		addr_hit[59] = reg_addr == RV_PLIC_PRIO53_OFFSET;
		addr_hit[60] = reg_addr == RV_PLIC_PRIO54_OFFSET;
		addr_hit[61] = reg_addr == RV_PLIC_PRIO55_OFFSET;
		addr_hit[62] = reg_addr == RV_PLIC_PRIO56_OFFSET;
		addr_hit[63] = reg_addr == RV_PLIC_PRIO57_OFFSET;
		addr_hit[64] = reg_addr == RV_PLIC_PRIO58_OFFSET;
		addr_hit[65] = reg_addr == RV_PLIC_PRIO59_OFFSET;
		addr_hit[66] = reg_addr == RV_PLIC_PRIO60_OFFSET;
		addr_hit[67] = reg_addr == RV_PLIC_PRIO61_OFFSET;
		addr_hit[68] = reg_addr == RV_PLIC_PRIO62_OFFSET;
		addr_hit[69] = reg_addr == RV_PLIC_PRIO63_OFFSET;
		addr_hit[70] = reg_addr == RV_PLIC_PRIO64_OFFSET;
		addr_hit[71] = reg_addr == RV_PLIC_PRIO65_OFFSET;
		addr_hit[72] = reg_addr == RV_PLIC_PRIO66_OFFSET;
		addr_hit[73] = reg_addr == RV_PLIC_PRIO67_OFFSET;
		addr_hit[74] = reg_addr == RV_PLIC_PRIO68_OFFSET;
		addr_hit[75] = reg_addr == RV_PLIC_PRIO69_OFFSET;
		addr_hit[76] = reg_addr == RV_PLIC_PRIO70_OFFSET;
		addr_hit[77] = reg_addr == RV_PLIC_PRIO71_OFFSET;
		addr_hit[78] = reg_addr == RV_PLIC_PRIO72_OFFSET;
		addr_hit[79] = reg_addr == RV_PLIC_PRIO73_OFFSET;
		addr_hit[80] = reg_addr == RV_PLIC_PRIO74_OFFSET;
		addr_hit[81] = reg_addr == RV_PLIC_PRIO75_OFFSET;
		addr_hit[82] = reg_addr == RV_PLIC_PRIO76_OFFSET;
		addr_hit[83] = reg_addr == RV_PLIC_PRIO77_OFFSET;
		addr_hit[84] = reg_addr == RV_PLIC_PRIO78_OFFSET;
		addr_hit[85] = reg_addr == RV_PLIC_IE00_OFFSET;
		addr_hit[86] = reg_addr == RV_PLIC_IE01_OFFSET;
		addr_hit[87] = reg_addr == RV_PLIC_IE02_OFFSET;
		addr_hit[88] = reg_addr == RV_PLIC_THRESHOLD0_OFFSET;
		addr_hit[89] = reg_addr == RV_PLIC_CC0_OFFSET;
		addr_hit[90] = reg_addr == RV_PLIC_MSIP0_OFFSET;
	end
	assign addrmiss = (reg_re || reg_we ? ~|addr_hit : 1'b0);
	always @(*) begin
		wr_err = 1'b0;
		if ((addr_hit[0] && reg_we) && (RV_PLIC_PERMIT[360+:4] != (RV_PLIC_PERMIT[360+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[1] && reg_we) && (RV_PLIC_PERMIT[356+:4] != (RV_PLIC_PERMIT[356+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[2] && reg_we) && (RV_PLIC_PERMIT[352+:4] != (RV_PLIC_PERMIT[352+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[3] && reg_we) && (RV_PLIC_PERMIT[348+:4] != (RV_PLIC_PERMIT[348+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[4] && reg_we) && (RV_PLIC_PERMIT[344+:4] != (RV_PLIC_PERMIT[344+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[5] && reg_we) && (RV_PLIC_PERMIT[340+:4] != (RV_PLIC_PERMIT[340+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[6] && reg_we) && (RV_PLIC_PERMIT[336+:4] != (RV_PLIC_PERMIT[336+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[7] && reg_we) && (RV_PLIC_PERMIT[332+:4] != (RV_PLIC_PERMIT[332+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[8] && reg_we) && (RV_PLIC_PERMIT[328+:4] != (RV_PLIC_PERMIT[328+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[9] && reg_we) && (RV_PLIC_PERMIT[324+:4] != (RV_PLIC_PERMIT[324+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[10] && reg_we) && (RV_PLIC_PERMIT[320+:4] != (RV_PLIC_PERMIT[320+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[11] && reg_we) && (RV_PLIC_PERMIT[316+:4] != (RV_PLIC_PERMIT[316+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[12] && reg_we) && (RV_PLIC_PERMIT[312+:4] != (RV_PLIC_PERMIT[312+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[13] && reg_we) && (RV_PLIC_PERMIT[308+:4] != (RV_PLIC_PERMIT[308+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[14] && reg_we) && (RV_PLIC_PERMIT[304+:4] != (RV_PLIC_PERMIT[304+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[15] && reg_we) && (RV_PLIC_PERMIT[300+:4] != (RV_PLIC_PERMIT[300+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[16] && reg_we) && (RV_PLIC_PERMIT[296+:4] != (RV_PLIC_PERMIT[296+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[17] && reg_we) && (RV_PLIC_PERMIT[292+:4] != (RV_PLIC_PERMIT[292+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[18] && reg_we) && (RV_PLIC_PERMIT[288+:4] != (RV_PLIC_PERMIT[288+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[19] && reg_we) && (RV_PLIC_PERMIT[284+:4] != (RV_PLIC_PERMIT[284+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[20] && reg_we) && (RV_PLIC_PERMIT[280+:4] != (RV_PLIC_PERMIT[280+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[21] && reg_we) && (RV_PLIC_PERMIT[276+:4] != (RV_PLIC_PERMIT[276+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[22] && reg_we) && (RV_PLIC_PERMIT[272+:4] != (RV_PLIC_PERMIT[272+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[23] && reg_we) && (RV_PLIC_PERMIT[268+:4] != (RV_PLIC_PERMIT[268+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[24] && reg_we) && (RV_PLIC_PERMIT[264+:4] != (RV_PLIC_PERMIT[264+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[25] && reg_we) && (RV_PLIC_PERMIT[260+:4] != (RV_PLIC_PERMIT[260+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[26] && reg_we) && (RV_PLIC_PERMIT[256+:4] != (RV_PLIC_PERMIT[256+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[27] && reg_we) && (RV_PLIC_PERMIT[252+:4] != (RV_PLIC_PERMIT[252+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[28] && reg_we) && (RV_PLIC_PERMIT[248+:4] != (RV_PLIC_PERMIT[248+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[29] && reg_we) && (RV_PLIC_PERMIT[244+:4] != (RV_PLIC_PERMIT[244+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[30] && reg_we) && (RV_PLIC_PERMIT[240+:4] != (RV_PLIC_PERMIT[240+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[31] && reg_we) && (RV_PLIC_PERMIT[236+:4] != (RV_PLIC_PERMIT[236+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[32] && reg_we) && (RV_PLIC_PERMIT[232+:4] != (RV_PLIC_PERMIT[232+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[33] && reg_we) && (RV_PLIC_PERMIT[228+:4] != (RV_PLIC_PERMIT[228+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[34] && reg_we) && (RV_PLIC_PERMIT[224+:4] != (RV_PLIC_PERMIT[224+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[35] && reg_we) && (RV_PLIC_PERMIT[220+:4] != (RV_PLIC_PERMIT[220+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[36] && reg_we) && (RV_PLIC_PERMIT[216+:4] != (RV_PLIC_PERMIT[216+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[37] && reg_we) && (RV_PLIC_PERMIT[212+:4] != (RV_PLIC_PERMIT[212+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[38] && reg_we) && (RV_PLIC_PERMIT[208+:4] != (RV_PLIC_PERMIT[208+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[39] && reg_we) && (RV_PLIC_PERMIT[204+:4] != (RV_PLIC_PERMIT[204+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[40] && reg_we) && (RV_PLIC_PERMIT[200+:4] != (RV_PLIC_PERMIT[200+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[41] && reg_we) && (RV_PLIC_PERMIT[196+:4] != (RV_PLIC_PERMIT[196+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[42] && reg_we) && (RV_PLIC_PERMIT[192+:4] != (RV_PLIC_PERMIT[192+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[43] && reg_we) && (RV_PLIC_PERMIT[188+:4] != (RV_PLIC_PERMIT[188+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[44] && reg_we) && (RV_PLIC_PERMIT[184+:4] != (RV_PLIC_PERMIT[184+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[45] && reg_we) && (RV_PLIC_PERMIT[180+:4] != (RV_PLIC_PERMIT[180+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[46] && reg_we) && (RV_PLIC_PERMIT[176+:4] != (RV_PLIC_PERMIT[176+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[47] && reg_we) && (RV_PLIC_PERMIT[172+:4] != (RV_PLIC_PERMIT[172+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[48] && reg_we) && (RV_PLIC_PERMIT[168+:4] != (RV_PLIC_PERMIT[168+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[49] && reg_we) && (RV_PLIC_PERMIT[164+:4] != (RV_PLIC_PERMIT[164+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[50] && reg_we) && (RV_PLIC_PERMIT[160+:4] != (RV_PLIC_PERMIT[160+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[51] && reg_we) && (RV_PLIC_PERMIT[156+:4] != (RV_PLIC_PERMIT[156+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[52] && reg_we) && (RV_PLIC_PERMIT[152+:4] != (RV_PLIC_PERMIT[152+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[53] && reg_we) && (RV_PLIC_PERMIT[148+:4] != (RV_PLIC_PERMIT[148+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[54] && reg_we) && (RV_PLIC_PERMIT[144+:4] != (RV_PLIC_PERMIT[144+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[55] && reg_we) && (RV_PLIC_PERMIT[140+:4] != (RV_PLIC_PERMIT[140+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[56] && reg_we) && (RV_PLIC_PERMIT[136+:4] != (RV_PLIC_PERMIT[136+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[57] && reg_we) && (RV_PLIC_PERMIT[132+:4] != (RV_PLIC_PERMIT[132+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[58] && reg_we) && (RV_PLIC_PERMIT[128+:4] != (RV_PLIC_PERMIT[128+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[59] && reg_we) && (RV_PLIC_PERMIT[124+:4] != (RV_PLIC_PERMIT[124+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[60] && reg_we) && (RV_PLIC_PERMIT[120+:4] != (RV_PLIC_PERMIT[120+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[61] && reg_we) && (RV_PLIC_PERMIT[116+:4] != (RV_PLIC_PERMIT[116+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[62] && reg_we) && (RV_PLIC_PERMIT[112+:4] != (RV_PLIC_PERMIT[112+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[63] && reg_we) && (RV_PLIC_PERMIT[108+:4] != (RV_PLIC_PERMIT[108+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[64] && reg_we) && (RV_PLIC_PERMIT[104+:4] != (RV_PLIC_PERMIT[104+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[65] && reg_we) && (RV_PLIC_PERMIT[100+:4] != (RV_PLIC_PERMIT[100+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[66] && reg_we) && (RV_PLIC_PERMIT[96+:4] != (RV_PLIC_PERMIT[96+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[67] && reg_we) && (RV_PLIC_PERMIT[92+:4] != (RV_PLIC_PERMIT[92+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[68] && reg_we) && (RV_PLIC_PERMIT[88+:4] != (RV_PLIC_PERMIT[88+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[69] && reg_we) && (RV_PLIC_PERMIT[84+:4] != (RV_PLIC_PERMIT[84+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[70] && reg_we) && (RV_PLIC_PERMIT[80+:4] != (RV_PLIC_PERMIT[80+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[71] && reg_we) && (RV_PLIC_PERMIT[76+:4] != (RV_PLIC_PERMIT[76+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[72] && reg_we) && (RV_PLIC_PERMIT[72+:4] != (RV_PLIC_PERMIT[72+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[73] && reg_we) && (RV_PLIC_PERMIT[68+:4] != (RV_PLIC_PERMIT[68+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[74] && reg_we) && (RV_PLIC_PERMIT[64+:4] != (RV_PLIC_PERMIT[64+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[75] && reg_we) && (RV_PLIC_PERMIT[60+:4] != (RV_PLIC_PERMIT[60+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[76] && reg_we) && (RV_PLIC_PERMIT[56+:4] != (RV_PLIC_PERMIT[56+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[77] && reg_we) && (RV_PLIC_PERMIT[52+:4] != (RV_PLIC_PERMIT[52+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[78] && reg_we) && (RV_PLIC_PERMIT[48+:4] != (RV_PLIC_PERMIT[48+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[79] && reg_we) && (RV_PLIC_PERMIT[44+:4] != (RV_PLIC_PERMIT[44+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[80] && reg_we) && (RV_PLIC_PERMIT[40+:4] != (RV_PLIC_PERMIT[40+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[81] && reg_we) && (RV_PLIC_PERMIT[36+:4] != (RV_PLIC_PERMIT[36+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[82] && reg_we) && (RV_PLIC_PERMIT[32+:4] != (RV_PLIC_PERMIT[32+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[83] && reg_we) && (RV_PLIC_PERMIT[28+:4] != (RV_PLIC_PERMIT[28+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[84] && reg_we) && (RV_PLIC_PERMIT[24+:4] != (RV_PLIC_PERMIT[24+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[85] && reg_we) && (RV_PLIC_PERMIT[20+:4] != (RV_PLIC_PERMIT[20+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[86] && reg_we) && (RV_PLIC_PERMIT[16+:4] != (RV_PLIC_PERMIT[16+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[87] && reg_we) && (RV_PLIC_PERMIT[12+:4] != (RV_PLIC_PERMIT[12+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[88] && reg_we) && (RV_PLIC_PERMIT[8+:4] != (RV_PLIC_PERMIT[8+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[89] && reg_we) && (RV_PLIC_PERMIT[4+:4] != (RV_PLIC_PERMIT[4+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[90] && reg_we) && (RV_PLIC_PERMIT[0+:4] != (RV_PLIC_PERMIT[0+:4] & reg_be)))
			wr_err = 1'b1;
	end
	assign le0_le0_we = (addr_hit[3] & reg_we) & ~wr_err;
	assign le0_le0_wd = reg_wdata[0];
	assign le0_le1_we = (addr_hit[3] & reg_we) & ~wr_err;
	assign le0_le1_wd = reg_wdata[1];
	assign le0_le2_we = (addr_hit[3] & reg_we) & ~wr_err;
	assign le0_le2_wd = reg_wdata[2];
	assign le0_le3_we = (addr_hit[3] & reg_we) & ~wr_err;
	assign le0_le3_wd = reg_wdata[3];
	assign le0_le4_we = (addr_hit[3] & reg_we) & ~wr_err;
	assign le0_le4_wd = reg_wdata[4];
	assign le0_le5_we = (addr_hit[3] & reg_we) & ~wr_err;
	assign le0_le5_wd = reg_wdata[5];
	assign le0_le6_we = (addr_hit[3] & reg_we) & ~wr_err;
	assign le0_le6_wd = reg_wdata[6];
	assign le0_le7_we = (addr_hit[3] & reg_we) & ~wr_err;
	assign le0_le7_wd = reg_wdata[7];
	assign le0_le8_we = (addr_hit[3] & reg_we) & ~wr_err;
	assign le0_le8_wd = reg_wdata[8];
	assign le0_le9_we = (addr_hit[3] & reg_we) & ~wr_err;
	assign le0_le9_wd = reg_wdata[9];
	assign le0_le10_we = (addr_hit[3] & reg_we) & ~wr_err;
	assign le0_le10_wd = reg_wdata[10];
	assign le0_le11_we = (addr_hit[3] & reg_we) & ~wr_err;
	assign le0_le11_wd = reg_wdata[11];
	assign le0_le12_we = (addr_hit[3] & reg_we) & ~wr_err;
	assign le0_le12_wd = reg_wdata[12];
	assign le0_le13_we = (addr_hit[3] & reg_we) & ~wr_err;
	assign le0_le13_wd = reg_wdata[13];
	assign le0_le14_we = (addr_hit[3] & reg_we) & ~wr_err;
	assign le0_le14_wd = reg_wdata[14];
	assign le0_le15_we = (addr_hit[3] & reg_we) & ~wr_err;
	assign le0_le15_wd = reg_wdata[15];
	assign le0_le16_we = (addr_hit[3] & reg_we) & ~wr_err;
	assign le0_le16_wd = reg_wdata[16];
	assign le0_le17_we = (addr_hit[3] & reg_we) & ~wr_err;
	assign le0_le17_wd = reg_wdata[17];
	assign le0_le18_we = (addr_hit[3] & reg_we) & ~wr_err;
	assign le0_le18_wd = reg_wdata[18];
	assign le0_le19_we = (addr_hit[3] & reg_we) & ~wr_err;
	assign le0_le19_wd = reg_wdata[19];
	assign le0_le20_we = (addr_hit[3] & reg_we) & ~wr_err;
	assign le0_le20_wd = reg_wdata[20];
	assign le0_le21_we = (addr_hit[3] & reg_we) & ~wr_err;
	assign le0_le21_wd = reg_wdata[21];
	assign le0_le22_we = (addr_hit[3] & reg_we) & ~wr_err;
	assign le0_le22_wd = reg_wdata[22];
	assign le0_le23_we = (addr_hit[3] & reg_we) & ~wr_err;
	assign le0_le23_wd = reg_wdata[23];
	assign le0_le24_we = (addr_hit[3] & reg_we) & ~wr_err;
	assign le0_le24_wd = reg_wdata[24];
	assign le0_le25_we = (addr_hit[3] & reg_we) & ~wr_err;
	assign le0_le25_wd = reg_wdata[25];
	assign le0_le26_we = (addr_hit[3] & reg_we) & ~wr_err;
	assign le0_le26_wd = reg_wdata[26];
	assign le0_le27_we = (addr_hit[3] & reg_we) & ~wr_err;
	assign le0_le27_wd = reg_wdata[27];
	assign le0_le28_we = (addr_hit[3] & reg_we) & ~wr_err;
	assign le0_le28_wd = reg_wdata[28];
	assign le0_le29_we = (addr_hit[3] & reg_we) & ~wr_err;
	assign le0_le29_wd = reg_wdata[29];
	assign le0_le30_we = (addr_hit[3] & reg_we) & ~wr_err;
	assign le0_le30_wd = reg_wdata[30];
	assign le0_le31_we = (addr_hit[3] & reg_we) & ~wr_err;
	assign le0_le31_wd = reg_wdata[31];
	assign le1_le32_we = (addr_hit[4] & reg_we) & ~wr_err;
	assign le1_le32_wd = reg_wdata[0];
	assign le1_le33_we = (addr_hit[4] & reg_we) & ~wr_err;
	assign le1_le33_wd = reg_wdata[1];
	assign le1_le34_we = (addr_hit[4] & reg_we) & ~wr_err;
	assign le1_le34_wd = reg_wdata[2];
	assign le1_le35_we = (addr_hit[4] & reg_we) & ~wr_err;
	assign le1_le35_wd = reg_wdata[3];
	assign le1_le36_we = (addr_hit[4] & reg_we) & ~wr_err;
	assign le1_le36_wd = reg_wdata[4];
	assign le1_le37_we = (addr_hit[4] & reg_we) & ~wr_err;
	assign le1_le37_wd = reg_wdata[5];
	assign le1_le38_we = (addr_hit[4] & reg_we) & ~wr_err;
	assign le1_le38_wd = reg_wdata[6];
	assign le1_le39_we = (addr_hit[4] & reg_we) & ~wr_err;
	assign le1_le39_wd = reg_wdata[7];
	assign le1_le40_we = (addr_hit[4] & reg_we) & ~wr_err;
	assign le1_le40_wd = reg_wdata[8];
	assign le1_le41_we = (addr_hit[4] & reg_we) & ~wr_err;
	assign le1_le41_wd = reg_wdata[9];
	assign le1_le42_we = (addr_hit[4] & reg_we) & ~wr_err;
	assign le1_le42_wd = reg_wdata[10];
	assign le1_le43_we = (addr_hit[4] & reg_we) & ~wr_err;
	assign le1_le43_wd = reg_wdata[11];
	assign le1_le44_we = (addr_hit[4] & reg_we) & ~wr_err;
	assign le1_le44_wd = reg_wdata[12];
	assign le1_le45_we = (addr_hit[4] & reg_we) & ~wr_err;
	assign le1_le45_wd = reg_wdata[13];
	assign le1_le46_we = (addr_hit[4] & reg_we) & ~wr_err;
	assign le1_le46_wd = reg_wdata[14];
	assign le1_le47_we = (addr_hit[4] & reg_we) & ~wr_err;
	assign le1_le47_wd = reg_wdata[15];
	assign le1_le48_we = (addr_hit[4] & reg_we) & ~wr_err;
	assign le1_le48_wd = reg_wdata[16];
	assign le1_le49_we = (addr_hit[4] & reg_we) & ~wr_err;
	assign le1_le49_wd = reg_wdata[17];
	assign le1_le50_we = (addr_hit[4] & reg_we) & ~wr_err;
	assign le1_le50_wd = reg_wdata[18];
	assign le1_le51_we = (addr_hit[4] & reg_we) & ~wr_err;
	assign le1_le51_wd = reg_wdata[19];
	assign le1_le52_we = (addr_hit[4] & reg_we) & ~wr_err;
	assign le1_le52_wd = reg_wdata[20];
	assign le1_le53_we = (addr_hit[4] & reg_we) & ~wr_err;
	assign le1_le53_wd = reg_wdata[21];
	assign le1_le54_we = (addr_hit[4] & reg_we) & ~wr_err;
	assign le1_le54_wd = reg_wdata[22];
	assign le1_le55_we = (addr_hit[4] & reg_we) & ~wr_err;
	assign le1_le55_wd = reg_wdata[23];
	assign le1_le56_we = (addr_hit[4] & reg_we) & ~wr_err;
	assign le1_le56_wd = reg_wdata[24];
	assign le1_le57_we = (addr_hit[4] & reg_we) & ~wr_err;
	assign le1_le57_wd = reg_wdata[25];
	assign le1_le58_we = (addr_hit[4] & reg_we) & ~wr_err;
	assign le1_le58_wd = reg_wdata[26];
	assign le1_le59_we = (addr_hit[4] & reg_we) & ~wr_err;
	assign le1_le59_wd = reg_wdata[27];
	assign le1_le60_we = (addr_hit[4] & reg_we) & ~wr_err;
	assign le1_le60_wd = reg_wdata[28];
	assign le1_le61_we = (addr_hit[4] & reg_we) & ~wr_err;
	assign le1_le61_wd = reg_wdata[29];
	assign le1_le62_we = (addr_hit[4] & reg_we) & ~wr_err;
	assign le1_le62_wd = reg_wdata[30];
	assign le1_le63_we = (addr_hit[4] & reg_we) & ~wr_err;
	assign le1_le63_wd = reg_wdata[31];
	assign le2_le64_we = (addr_hit[5] & reg_we) & ~wr_err;
	assign le2_le64_wd = reg_wdata[0];
	assign le2_le65_we = (addr_hit[5] & reg_we) & ~wr_err;
	assign le2_le65_wd = reg_wdata[1];
	assign le2_le66_we = (addr_hit[5] & reg_we) & ~wr_err;
	assign le2_le66_wd = reg_wdata[2];
	assign le2_le67_we = (addr_hit[5] & reg_we) & ~wr_err;
	assign le2_le67_wd = reg_wdata[3];
	assign le2_le68_we = (addr_hit[5] & reg_we) & ~wr_err;
	assign le2_le68_wd = reg_wdata[4];
	assign le2_le69_we = (addr_hit[5] & reg_we) & ~wr_err;
	assign le2_le69_wd = reg_wdata[5];
	assign le2_le70_we = (addr_hit[5] & reg_we) & ~wr_err;
	assign le2_le70_wd = reg_wdata[6];
	assign le2_le71_we = (addr_hit[5] & reg_we) & ~wr_err;
	assign le2_le71_wd = reg_wdata[7];
	assign le2_le72_we = (addr_hit[5] & reg_we) & ~wr_err;
	assign le2_le72_wd = reg_wdata[8];
	assign le2_le73_we = (addr_hit[5] & reg_we) & ~wr_err;
	assign le2_le73_wd = reg_wdata[9];
	assign le2_le74_we = (addr_hit[5] & reg_we) & ~wr_err;
	assign le2_le74_wd = reg_wdata[10];
	assign le2_le75_we = (addr_hit[5] & reg_we) & ~wr_err;
	assign le2_le75_wd = reg_wdata[11];
	assign le2_le76_we = (addr_hit[5] & reg_we) & ~wr_err;
	assign le2_le76_wd = reg_wdata[12];
	assign le2_le77_we = (addr_hit[5] & reg_we) & ~wr_err;
	assign le2_le77_wd = reg_wdata[13];
	assign le2_le78_we = (addr_hit[5] & reg_we) & ~wr_err;
	assign le2_le78_wd = reg_wdata[14];
	assign prio0_we = (addr_hit[6] & reg_we) & ~wr_err;
	assign prio0_wd = reg_wdata[1:0];
	assign prio1_we = (addr_hit[7] & reg_we) & ~wr_err;
	assign prio1_wd = reg_wdata[1:0];
	assign prio2_we = (addr_hit[8] & reg_we) & ~wr_err;
	assign prio2_wd = reg_wdata[1:0];
	assign prio3_we = (addr_hit[9] & reg_we) & ~wr_err;
	assign prio3_wd = reg_wdata[1:0];
	assign prio4_we = (addr_hit[10] & reg_we) & ~wr_err;
	assign prio4_wd = reg_wdata[1:0];
	assign prio5_we = (addr_hit[11] & reg_we) & ~wr_err;
	assign prio5_wd = reg_wdata[1:0];
	assign prio6_we = (addr_hit[12] & reg_we) & ~wr_err;
	assign prio6_wd = reg_wdata[1:0];
	assign prio7_we = (addr_hit[13] & reg_we) & ~wr_err;
	assign prio7_wd = reg_wdata[1:0];
	assign prio8_we = (addr_hit[14] & reg_we) & ~wr_err;
	assign prio8_wd = reg_wdata[1:0];
	assign prio9_we = (addr_hit[15] & reg_we) & ~wr_err;
	assign prio9_wd = reg_wdata[1:0];
	assign prio10_we = (addr_hit[16] & reg_we) & ~wr_err;
	assign prio10_wd = reg_wdata[1:0];
	assign prio11_we = (addr_hit[17] & reg_we) & ~wr_err;
	assign prio11_wd = reg_wdata[1:0];
	assign prio12_we = (addr_hit[18] & reg_we) & ~wr_err;
	assign prio12_wd = reg_wdata[1:0];
	assign prio13_we = (addr_hit[19] & reg_we) & ~wr_err;
	assign prio13_wd = reg_wdata[1:0];
	assign prio14_we = (addr_hit[20] & reg_we) & ~wr_err;
	assign prio14_wd = reg_wdata[1:0];
	assign prio15_we = (addr_hit[21] & reg_we) & ~wr_err;
	assign prio15_wd = reg_wdata[1:0];
	assign prio16_we = (addr_hit[22] & reg_we) & ~wr_err;
	assign prio16_wd = reg_wdata[1:0];
	assign prio17_we = (addr_hit[23] & reg_we) & ~wr_err;
	assign prio17_wd = reg_wdata[1:0];
	assign prio18_we = (addr_hit[24] & reg_we) & ~wr_err;
	assign prio18_wd = reg_wdata[1:0];
	assign prio19_we = (addr_hit[25] & reg_we) & ~wr_err;
	assign prio19_wd = reg_wdata[1:0];
	assign prio20_we = (addr_hit[26] & reg_we) & ~wr_err;
	assign prio20_wd = reg_wdata[1:0];
	assign prio21_we = (addr_hit[27] & reg_we) & ~wr_err;
	assign prio21_wd = reg_wdata[1:0];
	assign prio22_we = (addr_hit[28] & reg_we) & ~wr_err;
	assign prio22_wd = reg_wdata[1:0];
	assign prio23_we = (addr_hit[29] & reg_we) & ~wr_err;
	assign prio23_wd = reg_wdata[1:0];
	assign prio24_we = (addr_hit[30] & reg_we) & ~wr_err;
	assign prio24_wd = reg_wdata[1:0];
	assign prio25_we = (addr_hit[31] & reg_we) & ~wr_err;
	assign prio25_wd = reg_wdata[1:0];
	assign prio26_we = (addr_hit[32] & reg_we) & ~wr_err;
	assign prio26_wd = reg_wdata[1:0];
	assign prio27_we = (addr_hit[33] & reg_we) & ~wr_err;
	assign prio27_wd = reg_wdata[1:0];
	assign prio28_we = (addr_hit[34] & reg_we) & ~wr_err;
	assign prio28_wd = reg_wdata[1:0];
	assign prio29_we = (addr_hit[35] & reg_we) & ~wr_err;
	assign prio29_wd = reg_wdata[1:0];
	assign prio30_we = (addr_hit[36] & reg_we) & ~wr_err;
	assign prio30_wd = reg_wdata[1:0];
	assign prio31_we = (addr_hit[37] & reg_we) & ~wr_err;
	assign prio31_wd = reg_wdata[1:0];
	assign prio32_we = (addr_hit[38] & reg_we) & ~wr_err;
	assign prio32_wd = reg_wdata[1:0];
	assign prio33_we = (addr_hit[39] & reg_we) & ~wr_err;
	assign prio33_wd = reg_wdata[1:0];
	assign prio34_we = (addr_hit[40] & reg_we) & ~wr_err;
	assign prio34_wd = reg_wdata[1:0];
	assign prio35_we = (addr_hit[41] & reg_we) & ~wr_err;
	assign prio35_wd = reg_wdata[1:0];
	assign prio36_we = (addr_hit[42] & reg_we) & ~wr_err;
	assign prio36_wd = reg_wdata[1:0];
	assign prio37_we = (addr_hit[43] & reg_we) & ~wr_err;
	assign prio37_wd = reg_wdata[1:0];
	assign prio38_we = (addr_hit[44] & reg_we) & ~wr_err;
	assign prio38_wd = reg_wdata[1:0];
	assign prio39_we = (addr_hit[45] & reg_we) & ~wr_err;
	assign prio39_wd = reg_wdata[1:0];
	assign prio40_we = (addr_hit[46] & reg_we) & ~wr_err;
	assign prio40_wd = reg_wdata[1:0];
	assign prio41_we = (addr_hit[47] & reg_we) & ~wr_err;
	assign prio41_wd = reg_wdata[1:0];
	assign prio42_we = (addr_hit[48] & reg_we) & ~wr_err;
	assign prio42_wd = reg_wdata[1:0];
	assign prio43_we = (addr_hit[49] & reg_we) & ~wr_err;
	assign prio43_wd = reg_wdata[1:0];
	assign prio44_we = (addr_hit[50] & reg_we) & ~wr_err;
	assign prio44_wd = reg_wdata[1:0];
	assign prio45_we = (addr_hit[51] & reg_we) & ~wr_err;
	assign prio45_wd = reg_wdata[1:0];
	assign prio46_we = (addr_hit[52] & reg_we) & ~wr_err;
	assign prio46_wd = reg_wdata[1:0];
	assign prio47_we = (addr_hit[53] & reg_we) & ~wr_err;
	assign prio47_wd = reg_wdata[1:0];
	assign prio48_we = (addr_hit[54] & reg_we) & ~wr_err;
	assign prio48_wd = reg_wdata[1:0];
	assign prio49_we = (addr_hit[55] & reg_we) & ~wr_err;
	assign prio49_wd = reg_wdata[1:0];
	assign prio50_we = (addr_hit[56] & reg_we) & ~wr_err;
	assign prio50_wd = reg_wdata[1:0];
	assign prio51_we = (addr_hit[57] & reg_we) & ~wr_err;
	assign prio51_wd = reg_wdata[1:0];
	assign prio52_we = (addr_hit[58] & reg_we) & ~wr_err;
	assign prio52_wd = reg_wdata[1:0];
	assign prio53_we = (addr_hit[59] & reg_we) & ~wr_err;
	assign prio53_wd = reg_wdata[1:0];
	assign prio54_we = (addr_hit[60] & reg_we) & ~wr_err;
	assign prio54_wd = reg_wdata[1:0];
	assign prio55_we = (addr_hit[61] & reg_we) & ~wr_err;
	assign prio55_wd = reg_wdata[1:0];
	assign prio56_we = (addr_hit[62] & reg_we) & ~wr_err;
	assign prio56_wd = reg_wdata[1:0];
	assign prio57_we = (addr_hit[63] & reg_we) & ~wr_err;
	assign prio57_wd = reg_wdata[1:0];
	assign prio58_we = (addr_hit[64] & reg_we) & ~wr_err;
	assign prio58_wd = reg_wdata[1:0];
	assign prio59_we = (addr_hit[65] & reg_we) & ~wr_err;
	assign prio59_wd = reg_wdata[1:0];
	assign prio60_we = (addr_hit[66] & reg_we) & ~wr_err;
	assign prio60_wd = reg_wdata[1:0];
	assign prio61_we = (addr_hit[67] & reg_we) & ~wr_err;
	assign prio61_wd = reg_wdata[1:0];
	assign prio62_we = (addr_hit[68] & reg_we) & ~wr_err;
	assign prio62_wd = reg_wdata[1:0];
	assign prio63_we = (addr_hit[69] & reg_we) & ~wr_err;
	assign prio63_wd = reg_wdata[1:0];
	assign prio64_we = (addr_hit[70] & reg_we) & ~wr_err;
	assign prio64_wd = reg_wdata[1:0];
	assign prio65_we = (addr_hit[71] & reg_we) & ~wr_err;
	assign prio65_wd = reg_wdata[1:0];
	assign prio66_we = (addr_hit[72] & reg_we) & ~wr_err;
	assign prio66_wd = reg_wdata[1:0];
	assign prio67_we = (addr_hit[73] & reg_we) & ~wr_err;
	assign prio67_wd = reg_wdata[1:0];
	assign prio68_we = (addr_hit[74] & reg_we) & ~wr_err;
	assign prio68_wd = reg_wdata[1:0];
	assign prio69_we = (addr_hit[75] & reg_we) & ~wr_err;
	assign prio69_wd = reg_wdata[1:0];
	assign prio70_we = (addr_hit[76] & reg_we) & ~wr_err;
	assign prio70_wd = reg_wdata[1:0];
	assign prio71_we = (addr_hit[77] & reg_we) & ~wr_err;
	assign prio71_wd = reg_wdata[1:0];
	assign prio72_we = (addr_hit[78] & reg_we) & ~wr_err;
	assign prio72_wd = reg_wdata[1:0];
	assign prio73_we = (addr_hit[79] & reg_we) & ~wr_err;
	assign prio73_wd = reg_wdata[1:0];
	assign prio74_we = (addr_hit[80] & reg_we) & ~wr_err;
	assign prio74_wd = reg_wdata[1:0];
	assign prio75_we = (addr_hit[81] & reg_we) & ~wr_err;
	assign prio75_wd = reg_wdata[1:0];
	assign prio76_we = (addr_hit[82] & reg_we) & ~wr_err;
	assign prio76_wd = reg_wdata[1:0];
	assign prio77_we = (addr_hit[83] & reg_we) & ~wr_err;
	assign prio77_wd = reg_wdata[1:0];
	assign prio78_we = (addr_hit[84] & reg_we) & ~wr_err;
	assign prio78_wd = reg_wdata[1:0];
	assign ie00_e0_we = (addr_hit[85] & reg_we) & ~wr_err;
	assign ie00_e0_wd = reg_wdata[0];
	assign ie00_e1_we = (addr_hit[85] & reg_we) & ~wr_err;
	assign ie00_e1_wd = reg_wdata[1];
	assign ie00_e2_we = (addr_hit[85] & reg_we) & ~wr_err;
	assign ie00_e2_wd = reg_wdata[2];
	assign ie00_e3_we = (addr_hit[85] & reg_we) & ~wr_err;
	assign ie00_e3_wd = reg_wdata[3];
	assign ie00_e4_we = (addr_hit[85] & reg_we) & ~wr_err;
	assign ie00_e4_wd = reg_wdata[4];
	assign ie00_e5_we = (addr_hit[85] & reg_we) & ~wr_err;
	assign ie00_e5_wd = reg_wdata[5];
	assign ie00_e6_we = (addr_hit[85] & reg_we) & ~wr_err;
	assign ie00_e6_wd = reg_wdata[6];
	assign ie00_e7_we = (addr_hit[85] & reg_we) & ~wr_err;
	assign ie00_e7_wd = reg_wdata[7];
	assign ie00_e8_we = (addr_hit[85] & reg_we) & ~wr_err;
	assign ie00_e8_wd = reg_wdata[8];
	assign ie00_e9_we = (addr_hit[85] & reg_we) & ~wr_err;
	assign ie00_e9_wd = reg_wdata[9];
	assign ie00_e10_we = (addr_hit[85] & reg_we) & ~wr_err;
	assign ie00_e10_wd = reg_wdata[10];
	assign ie00_e11_we = (addr_hit[85] & reg_we) & ~wr_err;
	assign ie00_e11_wd = reg_wdata[11];
	assign ie00_e12_we = (addr_hit[85] & reg_we) & ~wr_err;
	assign ie00_e12_wd = reg_wdata[12];
	assign ie00_e13_we = (addr_hit[85] & reg_we) & ~wr_err;
	assign ie00_e13_wd = reg_wdata[13];
	assign ie00_e14_we = (addr_hit[85] & reg_we) & ~wr_err;
	assign ie00_e14_wd = reg_wdata[14];
	assign ie00_e15_we = (addr_hit[85] & reg_we) & ~wr_err;
	assign ie00_e15_wd = reg_wdata[15];
	assign ie00_e16_we = (addr_hit[85] & reg_we) & ~wr_err;
	assign ie00_e16_wd = reg_wdata[16];
	assign ie00_e17_we = (addr_hit[85] & reg_we) & ~wr_err;
	assign ie00_e17_wd = reg_wdata[17];
	assign ie00_e18_we = (addr_hit[85] & reg_we) & ~wr_err;
	assign ie00_e18_wd = reg_wdata[18];
	assign ie00_e19_we = (addr_hit[85] & reg_we) & ~wr_err;
	assign ie00_e19_wd = reg_wdata[19];
	assign ie00_e20_we = (addr_hit[85] & reg_we) & ~wr_err;
	assign ie00_e20_wd = reg_wdata[20];
	assign ie00_e21_we = (addr_hit[85] & reg_we) & ~wr_err;
	assign ie00_e21_wd = reg_wdata[21];
	assign ie00_e22_we = (addr_hit[85] & reg_we) & ~wr_err;
	assign ie00_e22_wd = reg_wdata[22];
	assign ie00_e23_we = (addr_hit[85] & reg_we) & ~wr_err;
	assign ie00_e23_wd = reg_wdata[23];
	assign ie00_e24_we = (addr_hit[85] & reg_we) & ~wr_err;
	assign ie00_e24_wd = reg_wdata[24];
	assign ie00_e25_we = (addr_hit[85] & reg_we) & ~wr_err;
	assign ie00_e25_wd = reg_wdata[25];
	assign ie00_e26_we = (addr_hit[85] & reg_we) & ~wr_err;
	assign ie00_e26_wd = reg_wdata[26];
	assign ie00_e27_we = (addr_hit[85] & reg_we) & ~wr_err;
	assign ie00_e27_wd = reg_wdata[27];
	assign ie00_e28_we = (addr_hit[85] & reg_we) & ~wr_err;
	assign ie00_e28_wd = reg_wdata[28];
	assign ie00_e29_we = (addr_hit[85] & reg_we) & ~wr_err;
	assign ie00_e29_wd = reg_wdata[29];
	assign ie00_e30_we = (addr_hit[85] & reg_we) & ~wr_err;
	assign ie00_e30_wd = reg_wdata[30];
	assign ie00_e31_we = (addr_hit[85] & reg_we) & ~wr_err;
	assign ie00_e31_wd = reg_wdata[31];
	assign ie01_e32_we = (addr_hit[86] & reg_we) & ~wr_err;
	assign ie01_e32_wd = reg_wdata[0];
	assign ie01_e33_we = (addr_hit[86] & reg_we) & ~wr_err;
	assign ie01_e33_wd = reg_wdata[1];
	assign ie01_e34_we = (addr_hit[86] & reg_we) & ~wr_err;
	assign ie01_e34_wd = reg_wdata[2];
	assign ie01_e35_we = (addr_hit[86] & reg_we) & ~wr_err;
	assign ie01_e35_wd = reg_wdata[3];
	assign ie01_e36_we = (addr_hit[86] & reg_we) & ~wr_err;
	assign ie01_e36_wd = reg_wdata[4];
	assign ie01_e37_we = (addr_hit[86] & reg_we) & ~wr_err;
	assign ie01_e37_wd = reg_wdata[5];
	assign ie01_e38_we = (addr_hit[86] & reg_we) & ~wr_err;
	assign ie01_e38_wd = reg_wdata[6];
	assign ie01_e39_we = (addr_hit[86] & reg_we) & ~wr_err;
	assign ie01_e39_wd = reg_wdata[7];
	assign ie01_e40_we = (addr_hit[86] & reg_we) & ~wr_err;
	assign ie01_e40_wd = reg_wdata[8];
	assign ie01_e41_we = (addr_hit[86] & reg_we) & ~wr_err;
	assign ie01_e41_wd = reg_wdata[9];
	assign ie01_e42_we = (addr_hit[86] & reg_we) & ~wr_err;
	assign ie01_e42_wd = reg_wdata[10];
	assign ie01_e43_we = (addr_hit[86] & reg_we) & ~wr_err;
	assign ie01_e43_wd = reg_wdata[11];
	assign ie01_e44_we = (addr_hit[86] & reg_we) & ~wr_err;
	assign ie01_e44_wd = reg_wdata[12];
	assign ie01_e45_we = (addr_hit[86] & reg_we) & ~wr_err;
	assign ie01_e45_wd = reg_wdata[13];
	assign ie01_e46_we = (addr_hit[86] & reg_we) & ~wr_err;
	assign ie01_e46_wd = reg_wdata[14];
	assign ie01_e47_we = (addr_hit[86] & reg_we) & ~wr_err;
	assign ie01_e47_wd = reg_wdata[15];
	assign ie01_e48_we = (addr_hit[86] & reg_we) & ~wr_err;
	assign ie01_e48_wd = reg_wdata[16];
	assign ie01_e49_we = (addr_hit[86] & reg_we) & ~wr_err;
	assign ie01_e49_wd = reg_wdata[17];
	assign ie01_e50_we = (addr_hit[86] & reg_we) & ~wr_err;
	assign ie01_e50_wd = reg_wdata[18];
	assign ie01_e51_we = (addr_hit[86] & reg_we) & ~wr_err;
	assign ie01_e51_wd = reg_wdata[19];
	assign ie01_e52_we = (addr_hit[86] & reg_we) & ~wr_err;
	assign ie01_e52_wd = reg_wdata[20];
	assign ie01_e53_we = (addr_hit[86] & reg_we) & ~wr_err;
	assign ie01_e53_wd = reg_wdata[21];
	assign ie01_e54_we = (addr_hit[86] & reg_we) & ~wr_err;
	assign ie01_e54_wd = reg_wdata[22];
	assign ie01_e55_we = (addr_hit[86] & reg_we) & ~wr_err;
	assign ie01_e55_wd = reg_wdata[23];
	assign ie01_e56_we = (addr_hit[86] & reg_we) & ~wr_err;
	assign ie01_e56_wd = reg_wdata[24];
	assign ie01_e57_we = (addr_hit[86] & reg_we) & ~wr_err;
	assign ie01_e57_wd = reg_wdata[25];
	assign ie01_e58_we = (addr_hit[86] & reg_we) & ~wr_err;
	assign ie01_e58_wd = reg_wdata[26];
	assign ie01_e59_we = (addr_hit[86] & reg_we) & ~wr_err;
	assign ie01_e59_wd = reg_wdata[27];
	assign ie01_e60_we = (addr_hit[86] & reg_we) & ~wr_err;
	assign ie01_e60_wd = reg_wdata[28];
	assign ie01_e61_we = (addr_hit[86] & reg_we) & ~wr_err;
	assign ie01_e61_wd = reg_wdata[29];
	assign ie01_e62_we = (addr_hit[86] & reg_we) & ~wr_err;
	assign ie01_e62_wd = reg_wdata[30];
	assign ie01_e63_we = (addr_hit[86] & reg_we) & ~wr_err;
	assign ie01_e63_wd = reg_wdata[31];
	assign ie02_e64_we = (addr_hit[87] & reg_we) & ~wr_err;
	assign ie02_e64_wd = reg_wdata[0];
	assign ie02_e65_we = (addr_hit[87] & reg_we) & ~wr_err;
	assign ie02_e65_wd = reg_wdata[1];
	assign ie02_e66_we = (addr_hit[87] & reg_we) & ~wr_err;
	assign ie02_e66_wd = reg_wdata[2];
	assign ie02_e67_we = (addr_hit[87] & reg_we) & ~wr_err;
	assign ie02_e67_wd = reg_wdata[3];
	assign ie02_e68_we = (addr_hit[87] & reg_we) & ~wr_err;
	assign ie02_e68_wd = reg_wdata[4];
	assign ie02_e69_we = (addr_hit[87] & reg_we) & ~wr_err;
	assign ie02_e69_wd = reg_wdata[5];
	assign ie02_e70_we = (addr_hit[87] & reg_we) & ~wr_err;
	assign ie02_e70_wd = reg_wdata[6];
	assign ie02_e71_we = (addr_hit[87] & reg_we) & ~wr_err;
	assign ie02_e71_wd = reg_wdata[7];
	assign ie02_e72_we = (addr_hit[87] & reg_we) & ~wr_err;
	assign ie02_e72_wd = reg_wdata[8];
	assign ie02_e73_we = (addr_hit[87] & reg_we) & ~wr_err;
	assign ie02_e73_wd = reg_wdata[9];
	assign ie02_e74_we = (addr_hit[87] & reg_we) & ~wr_err;
	assign ie02_e74_wd = reg_wdata[10];
	assign ie02_e75_we = (addr_hit[87] & reg_we) & ~wr_err;
	assign ie02_e75_wd = reg_wdata[11];
	assign ie02_e76_we = (addr_hit[87] & reg_we) & ~wr_err;
	assign ie02_e76_wd = reg_wdata[12];
	assign ie02_e77_we = (addr_hit[87] & reg_we) & ~wr_err;
	assign ie02_e77_wd = reg_wdata[13];
	assign ie02_e78_we = (addr_hit[87] & reg_we) & ~wr_err;
	assign ie02_e78_wd = reg_wdata[14];
	assign threshold0_we = (addr_hit[88] & reg_we) & ~wr_err;
	assign threshold0_wd = reg_wdata[1:0];
	assign cc0_we = (addr_hit[89] & reg_we) & ~wr_err;
	assign cc0_wd = reg_wdata[6:0];
	assign cc0_re = addr_hit[89] && reg_re;
	assign msip0_we = (addr_hit[90] & reg_we) & ~wr_err;
	assign msip0_wd = reg_wdata[0];
	always @(*) begin
		reg_rdata_next = 1'sb0;
		case (1'b1)
			addr_hit[0]: begin
				reg_rdata_next[0] = ip0_p0_qs;
				reg_rdata_next[1] = ip0_p1_qs;
				reg_rdata_next[2] = ip0_p2_qs;
				reg_rdata_next[3] = ip0_p3_qs;
				reg_rdata_next[4] = ip0_p4_qs;
				reg_rdata_next[5] = ip0_p5_qs;
				reg_rdata_next[6] = ip0_p6_qs;
				reg_rdata_next[7] = ip0_p7_qs;
				reg_rdata_next[8] = ip0_p8_qs;
				reg_rdata_next[9] = ip0_p9_qs;
				reg_rdata_next[10] = ip0_p10_qs;
				reg_rdata_next[11] = ip0_p11_qs;
				reg_rdata_next[12] = ip0_p12_qs;
				reg_rdata_next[13] = ip0_p13_qs;
				reg_rdata_next[14] = ip0_p14_qs;
				reg_rdata_next[15] = ip0_p15_qs;
				reg_rdata_next[16] = ip0_p16_qs;
				reg_rdata_next[17] = ip0_p17_qs;
				reg_rdata_next[18] = ip0_p18_qs;
				reg_rdata_next[19] = ip0_p19_qs;
				reg_rdata_next[20] = ip0_p20_qs;
				reg_rdata_next[21] = ip0_p21_qs;
				reg_rdata_next[22] = ip0_p22_qs;
				reg_rdata_next[23] = ip0_p23_qs;
				reg_rdata_next[24] = ip0_p24_qs;
				reg_rdata_next[25] = ip0_p25_qs;
				reg_rdata_next[26] = ip0_p26_qs;
				reg_rdata_next[27] = ip0_p27_qs;
				reg_rdata_next[28] = ip0_p28_qs;
				reg_rdata_next[29] = ip0_p29_qs;
				reg_rdata_next[30] = ip0_p30_qs;
				reg_rdata_next[31] = ip0_p31_qs;
			end
			addr_hit[1]: begin
				reg_rdata_next[0] = ip1_p32_qs;
				reg_rdata_next[1] = ip1_p33_qs;
				reg_rdata_next[2] = ip1_p34_qs;
				reg_rdata_next[3] = ip1_p35_qs;
				reg_rdata_next[4] = ip1_p36_qs;
				reg_rdata_next[5] = ip1_p37_qs;
				reg_rdata_next[6] = ip1_p38_qs;
				reg_rdata_next[7] = ip1_p39_qs;
				reg_rdata_next[8] = ip1_p40_qs;
				reg_rdata_next[9] = ip1_p41_qs;
				reg_rdata_next[10] = ip1_p42_qs;
				reg_rdata_next[11] = ip1_p43_qs;
				reg_rdata_next[12] = ip1_p44_qs;
				reg_rdata_next[13] = ip1_p45_qs;
				reg_rdata_next[14] = ip1_p46_qs;
				reg_rdata_next[15] = ip1_p47_qs;
				reg_rdata_next[16] = ip1_p48_qs;
				reg_rdata_next[17] = ip1_p49_qs;
				reg_rdata_next[18] = ip1_p50_qs;
				reg_rdata_next[19] = ip1_p51_qs;
				reg_rdata_next[20] = ip1_p52_qs;
				reg_rdata_next[21] = ip1_p53_qs;
				reg_rdata_next[22] = ip1_p54_qs;
				reg_rdata_next[23] = ip1_p55_qs;
				reg_rdata_next[24] = ip1_p56_qs;
				reg_rdata_next[25] = ip1_p57_qs;
				reg_rdata_next[26] = ip1_p58_qs;
				reg_rdata_next[27] = ip1_p59_qs;
				reg_rdata_next[28] = ip1_p60_qs;
				reg_rdata_next[29] = ip1_p61_qs;
				reg_rdata_next[30] = ip1_p62_qs;
				reg_rdata_next[31] = ip1_p63_qs;
			end
			addr_hit[2]: begin
				reg_rdata_next[0] = ip2_p64_qs;
				reg_rdata_next[1] = ip2_p65_qs;
				reg_rdata_next[2] = ip2_p66_qs;
				reg_rdata_next[3] = ip2_p67_qs;
				reg_rdata_next[4] = ip2_p68_qs;
				reg_rdata_next[5] = ip2_p69_qs;
				reg_rdata_next[6] = ip2_p70_qs;
				reg_rdata_next[7] = ip2_p71_qs;
				reg_rdata_next[8] = ip2_p72_qs;
				reg_rdata_next[9] = ip2_p73_qs;
				reg_rdata_next[10] = ip2_p74_qs;
				reg_rdata_next[11] = ip2_p75_qs;
				reg_rdata_next[12] = ip2_p76_qs;
				reg_rdata_next[13] = ip2_p77_qs;
				reg_rdata_next[14] = ip2_p78_qs;
			end
			addr_hit[3]: begin
				reg_rdata_next[0] = le0_le0_qs;
				reg_rdata_next[1] = le0_le1_qs;
				reg_rdata_next[2] = le0_le2_qs;
				reg_rdata_next[3] = le0_le3_qs;
				reg_rdata_next[4] = le0_le4_qs;
				reg_rdata_next[5] = le0_le5_qs;
				reg_rdata_next[6] = le0_le6_qs;
				reg_rdata_next[7] = le0_le7_qs;
				reg_rdata_next[8] = le0_le8_qs;
				reg_rdata_next[9] = le0_le9_qs;
				reg_rdata_next[10] = le0_le10_qs;
				reg_rdata_next[11] = le0_le11_qs;
				reg_rdata_next[12] = le0_le12_qs;
				reg_rdata_next[13] = le0_le13_qs;
				reg_rdata_next[14] = le0_le14_qs;
				reg_rdata_next[15] = le0_le15_qs;
				reg_rdata_next[16] = le0_le16_qs;
				reg_rdata_next[17] = le0_le17_qs;
				reg_rdata_next[18] = le0_le18_qs;
				reg_rdata_next[19] = le0_le19_qs;
				reg_rdata_next[20] = le0_le20_qs;
				reg_rdata_next[21] = le0_le21_qs;
				reg_rdata_next[22] = le0_le22_qs;
				reg_rdata_next[23] = le0_le23_qs;
				reg_rdata_next[24] = le0_le24_qs;
				reg_rdata_next[25] = le0_le25_qs;
				reg_rdata_next[26] = le0_le26_qs;
				reg_rdata_next[27] = le0_le27_qs;
				reg_rdata_next[28] = le0_le28_qs;
				reg_rdata_next[29] = le0_le29_qs;
				reg_rdata_next[30] = le0_le30_qs;
				reg_rdata_next[31] = le0_le31_qs;
			end
			addr_hit[4]: begin
				reg_rdata_next[0] = le1_le32_qs;
				reg_rdata_next[1] = le1_le33_qs;
				reg_rdata_next[2] = le1_le34_qs;
				reg_rdata_next[3] = le1_le35_qs;
				reg_rdata_next[4] = le1_le36_qs;
				reg_rdata_next[5] = le1_le37_qs;
				reg_rdata_next[6] = le1_le38_qs;
				reg_rdata_next[7] = le1_le39_qs;
				reg_rdata_next[8] = le1_le40_qs;
				reg_rdata_next[9] = le1_le41_qs;
				reg_rdata_next[10] = le1_le42_qs;
				reg_rdata_next[11] = le1_le43_qs;
				reg_rdata_next[12] = le1_le44_qs;
				reg_rdata_next[13] = le1_le45_qs;
				reg_rdata_next[14] = le1_le46_qs;
				reg_rdata_next[15] = le1_le47_qs;
				reg_rdata_next[16] = le1_le48_qs;
				reg_rdata_next[17] = le1_le49_qs;
				reg_rdata_next[18] = le1_le50_qs;
				reg_rdata_next[19] = le1_le51_qs;
				reg_rdata_next[20] = le1_le52_qs;
				reg_rdata_next[21] = le1_le53_qs;
				reg_rdata_next[22] = le1_le54_qs;
				reg_rdata_next[23] = le1_le55_qs;
				reg_rdata_next[24] = le1_le56_qs;
				reg_rdata_next[25] = le1_le57_qs;
				reg_rdata_next[26] = le1_le58_qs;
				reg_rdata_next[27] = le1_le59_qs;
				reg_rdata_next[28] = le1_le60_qs;
				reg_rdata_next[29] = le1_le61_qs;
				reg_rdata_next[30] = le1_le62_qs;
				reg_rdata_next[31] = le1_le63_qs;
			end
			addr_hit[5]: begin
				reg_rdata_next[0] = le2_le64_qs;
				reg_rdata_next[1] = le2_le65_qs;
				reg_rdata_next[2] = le2_le66_qs;
				reg_rdata_next[3] = le2_le67_qs;
				reg_rdata_next[4] = le2_le68_qs;
				reg_rdata_next[5] = le2_le69_qs;
				reg_rdata_next[6] = le2_le70_qs;
				reg_rdata_next[7] = le2_le71_qs;
				reg_rdata_next[8] = le2_le72_qs;
				reg_rdata_next[9] = le2_le73_qs;
				reg_rdata_next[10] = le2_le74_qs;
				reg_rdata_next[11] = le2_le75_qs;
				reg_rdata_next[12] = le2_le76_qs;
				reg_rdata_next[13] = le2_le77_qs;
				reg_rdata_next[14] = le2_le78_qs;
			end
			addr_hit[6]: reg_rdata_next[1:0] = prio0_qs;
			addr_hit[7]: reg_rdata_next[1:0] = prio1_qs;
			addr_hit[8]: reg_rdata_next[1:0] = prio2_qs;
			addr_hit[9]: reg_rdata_next[1:0] = prio3_qs;
			addr_hit[10]: reg_rdata_next[1:0] = prio4_qs;
			addr_hit[11]: reg_rdata_next[1:0] = prio5_qs;
			addr_hit[12]: reg_rdata_next[1:0] = prio6_qs;
			addr_hit[13]: reg_rdata_next[1:0] = prio7_qs;
			addr_hit[14]: reg_rdata_next[1:0] = prio8_qs;
			addr_hit[15]: reg_rdata_next[1:0] = prio9_qs;
			addr_hit[16]: reg_rdata_next[1:0] = prio10_qs;
			addr_hit[17]: reg_rdata_next[1:0] = prio11_qs;
			addr_hit[18]: reg_rdata_next[1:0] = prio12_qs;
			addr_hit[19]: reg_rdata_next[1:0] = prio13_qs;
			addr_hit[20]: reg_rdata_next[1:0] = prio14_qs;
			addr_hit[21]: reg_rdata_next[1:0] = prio15_qs;
			addr_hit[22]: reg_rdata_next[1:0] = prio16_qs;
			addr_hit[23]: reg_rdata_next[1:0] = prio17_qs;
			addr_hit[24]: reg_rdata_next[1:0] = prio18_qs;
			addr_hit[25]: reg_rdata_next[1:0] = prio19_qs;
			addr_hit[26]: reg_rdata_next[1:0] = prio20_qs;
			addr_hit[27]: reg_rdata_next[1:0] = prio21_qs;
			addr_hit[28]: reg_rdata_next[1:0] = prio22_qs;
			addr_hit[29]: reg_rdata_next[1:0] = prio23_qs;
			addr_hit[30]: reg_rdata_next[1:0] = prio24_qs;
			addr_hit[31]: reg_rdata_next[1:0] = prio25_qs;
			addr_hit[32]: reg_rdata_next[1:0] = prio26_qs;
			addr_hit[33]: reg_rdata_next[1:0] = prio27_qs;
			addr_hit[34]: reg_rdata_next[1:0] = prio28_qs;
			addr_hit[35]: reg_rdata_next[1:0] = prio29_qs;
			addr_hit[36]: reg_rdata_next[1:0] = prio30_qs;
			addr_hit[37]: reg_rdata_next[1:0] = prio31_qs;
			addr_hit[38]: reg_rdata_next[1:0] = prio32_qs;
			addr_hit[39]: reg_rdata_next[1:0] = prio33_qs;
			addr_hit[40]: reg_rdata_next[1:0] = prio34_qs;
			addr_hit[41]: reg_rdata_next[1:0] = prio35_qs;
			addr_hit[42]: reg_rdata_next[1:0] = prio36_qs;
			addr_hit[43]: reg_rdata_next[1:0] = prio37_qs;
			addr_hit[44]: reg_rdata_next[1:0] = prio38_qs;
			addr_hit[45]: reg_rdata_next[1:0] = prio39_qs;
			addr_hit[46]: reg_rdata_next[1:0] = prio40_qs;
			addr_hit[47]: reg_rdata_next[1:0] = prio41_qs;
			addr_hit[48]: reg_rdata_next[1:0] = prio42_qs;
			addr_hit[49]: reg_rdata_next[1:0] = prio43_qs;
			addr_hit[50]: reg_rdata_next[1:0] = prio44_qs;
			addr_hit[51]: reg_rdata_next[1:0] = prio45_qs;
			addr_hit[52]: reg_rdata_next[1:0] = prio46_qs;
			addr_hit[53]: reg_rdata_next[1:0] = prio47_qs;
			addr_hit[54]: reg_rdata_next[1:0] = prio48_qs;
			addr_hit[55]: reg_rdata_next[1:0] = prio49_qs;
			addr_hit[56]: reg_rdata_next[1:0] = prio50_qs;
			addr_hit[57]: reg_rdata_next[1:0] = prio51_qs;
			addr_hit[58]: reg_rdata_next[1:0] = prio52_qs;
			addr_hit[59]: reg_rdata_next[1:0] = prio53_qs;
			addr_hit[60]: reg_rdata_next[1:0] = prio54_qs;
			addr_hit[61]: reg_rdata_next[1:0] = prio55_qs;
			addr_hit[62]: reg_rdata_next[1:0] = prio56_qs;
			addr_hit[63]: reg_rdata_next[1:0] = prio57_qs;
			addr_hit[64]: reg_rdata_next[1:0] = prio58_qs;
			addr_hit[65]: reg_rdata_next[1:0] = prio59_qs;
			addr_hit[66]: reg_rdata_next[1:0] = prio60_qs;
			addr_hit[67]: reg_rdata_next[1:0] = prio61_qs;
			addr_hit[68]: reg_rdata_next[1:0] = prio62_qs;
			addr_hit[69]: reg_rdata_next[1:0] = prio63_qs;
			addr_hit[70]: reg_rdata_next[1:0] = prio64_qs;
			addr_hit[71]: reg_rdata_next[1:0] = prio65_qs;
			addr_hit[72]: reg_rdata_next[1:0] = prio66_qs;
			addr_hit[73]: reg_rdata_next[1:0] = prio67_qs;
			addr_hit[74]: reg_rdata_next[1:0] = prio68_qs;
			addr_hit[75]: reg_rdata_next[1:0] = prio69_qs;
			addr_hit[76]: reg_rdata_next[1:0] = prio70_qs;
			addr_hit[77]: reg_rdata_next[1:0] = prio71_qs;
			addr_hit[78]: reg_rdata_next[1:0] = prio72_qs;
			addr_hit[79]: reg_rdata_next[1:0] = prio73_qs;
			addr_hit[80]: reg_rdata_next[1:0] = prio74_qs;
			addr_hit[81]: reg_rdata_next[1:0] = prio75_qs;
			addr_hit[82]: reg_rdata_next[1:0] = prio76_qs;
			addr_hit[83]: reg_rdata_next[1:0] = prio77_qs;
			addr_hit[84]: reg_rdata_next[1:0] = prio78_qs;
			addr_hit[85]: begin
				reg_rdata_next[0] = ie00_e0_qs;
				reg_rdata_next[1] = ie00_e1_qs;
				reg_rdata_next[2] = ie00_e2_qs;
				reg_rdata_next[3] = ie00_e3_qs;
				reg_rdata_next[4] = ie00_e4_qs;
				reg_rdata_next[5] = ie00_e5_qs;
				reg_rdata_next[6] = ie00_e6_qs;
				reg_rdata_next[7] = ie00_e7_qs;
				reg_rdata_next[8] = ie00_e8_qs;
				reg_rdata_next[9] = ie00_e9_qs;
				reg_rdata_next[10] = ie00_e10_qs;
				reg_rdata_next[11] = ie00_e11_qs;
				reg_rdata_next[12] = ie00_e12_qs;
				reg_rdata_next[13] = ie00_e13_qs;
				reg_rdata_next[14] = ie00_e14_qs;
				reg_rdata_next[15] = ie00_e15_qs;
				reg_rdata_next[16] = ie00_e16_qs;
				reg_rdata_next[17] = ie00_e17_qs;
				reg_rdata_next[18] = ie00_e18_qs;
				reg_rdata_next[19] = ie00_e19_qs;
				reg_rdata_next[20] = ie00_e20_qs;
				reg_rdata_next[21] = ie00_e21_qs;
				reg_rdata_next[22] = ie00_e22_qs;
				reg_rdata_next[23] = ie00_e23_qs;
				reg_rdata_next[24] = ie00_e24_qs;
				reg_rdata_next[25] = ie00_e25_qs;
				reg_rdata_next[26] = ie00_e26_qs;
				reg_rdata_next[27] = ie00_e27_qs;
				reg_rdata_next[28] = ie00_e28_qs;
				reg_rdata_next[29] = ie00_e29_qs;
				reg_rdata_next[30] = ie00_e30_qs;
				reg_rdata_next[31] = ie00_e31_qs;
			end
			addr_hit[86]: begin
				reg_rdata_next[0] = ie01_e32_qs;
				reg_rdata_next[1] = ie01_e33_qs;
				reg_rdata_next[2] = ie01_e34_qs;
				reg_rdata_next[3] = ie01_e35_qs;
				reg_rdata_next[4] = ie01_e36_qs;
				reg_rdata_next[5] = ie01_e37_qs;
				reg_rdata_next[6] = ie01_e38_qs;
				reg_rdata_next[7] = ie01_e39_qs;
				reg_rdata_next[8] = ie01_e40_qs;
				reg_rdata_next[9] = ie01_e41_qs;
				reg_rdata_next[10] = ie01_e42_qs;
				reg_rdata_next[11] = ie01_e43_qs;
				reg_rdata_next[12] = ie01_e44_qs;
				reg_rdata_next[13] = ie01_e45_qs;
				reg_rdata_next[14] = ie01_e46_qs;
				reg_rdata_next[15] = ie01_e47_qs;
				reg_rdata_next[16] = ie01_e48_qs;
				reg_rdata_next[17] = ie01_e49_qs;
				reg_rdata_next[18] = ie01_e50_qs;
				reg_rdata_next[19] = ie01_e51_qs;
				reg_rdata_next[20] = ie01_e52_qs;
				reg_rdata_next[21] = ie01_e53_qs;
				reg_rdata_next[22] = ie01_e54_qs;
				reg_rdata_next[23] = ie01_e55_qs;
				reg_rdata_next[24] = ie01_e56_qs;
				reg_rdata_next[25] = ie01_e57_qs;
				reg_rdata_next[26] = ie01_e58_qs;
				reg_rdata_next[27] = ie01_e59_qs;
				reg_rdata_next[28] = ie01_e60_qs;
				reg_rdata_next[29] = ie01_e61_qs;
				reg_rdata_next[30] = ie01_e62_qs;
				reg_rdata_next[31] = ie01_e63_qs;
			end
			addr_hit[87]: begin
				reg_rdata_next[0] = ie02_e64_qs;
				reg_rdata_next[1] = ie02_e65_qs;
				reg_rdata_next[2] = ie02_e66_qs;
				reg_rdata_next[3] = ie02_e67_qs;
				reg_rdata_next[4] = ie02_e68_qs;
				reg_rdata_next[5] = ie02_e69_qs;
				reg_rdata_next[6] = ie02_e70_qs;
				reg_rdata_next[7] = ie02_e71_qs;
				reg_rdata_next[8] = ie02_e72_qs;
				reg_rdata_next[9] = ie02_e73_qs;
				reg_rdata_next[10] = ie02_e74_qs;
				reg_rdata_next[11] = ie02_e75_qs;
				reg_rdata_next[12] = ie02_e76_qs;
				reg_rdata_next[13] = ie02_e77_qs;
				reg_rdata_next[14] = ie02_e78_qs;
			end
			addr_hit[88]: reg_rdata_next[1:0] = threshold0_qs;
			addr_hit[89]: reg_rdata_next[6:0] = cc0_qs;
			addr_hit[90]: reg_rdata_next[0] = msip0_qs;
			default: reg_rdata_next = 1'sb1;
		endcase
	end
endmodule
