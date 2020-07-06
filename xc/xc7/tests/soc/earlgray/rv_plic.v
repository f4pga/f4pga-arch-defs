module rv_plic (
	clk_i,
	rst_ni,
	tl_i,
	tl_o,
	intr_src_i,
	irq_o,
	irq_id_o,
	msip_o
);
	localparam top_pkg_TL_AIW = 8;
	localparam top_pkg_TL_AW = 32;
	localparam top_pkg_TL_DBW = top_pkg_TL_DW >> 3;
	localparam top_pkg_TL_DIW = 1;
	localparam top_pkg_TL_DUW = 16;
	localparam top_pkg_TL_DW = 32;
	localparam top_pkg_TL_SZW = $clog2($clog2(32 >> 3) + 1);
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
	localparam signed [31:0] SRCW = $clog2(NumSrc + 1);
	input clk_i;
	input rst_ni;
	input wire [((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_AW) + ((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW)) + top_pkg_TL_DW) + 17) - 1:0] tl_i;
	output wire [((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_DIW) + top_pkg_TL_DW) + top_pkg_TL_DUW) + 2) - 1:0] tl_o;
	input [NumSrc - 1:0] intr_src_i;
	output [NumTarget - 1:0] irq_o;
	output [(0 >= (NumTarget - 1) ? ((SRCW - 1) >= 0 ? ((2 - NumTarget) * SRCW) + (((NumTarget - 1) * SRCW) - 1) : ((2 - NumTarget) * (2 - SRCW)) + (((SRCW - 1) + ((NumTarget - 1) * (2 - SRCW))) - 1)) : ((SRCW - 1) >= 0 ? (NumTarget * SRCW) + -1 : (NumTarget * (2 - SRCW)) + ((SRCW - 1) - 1))):(0 >= (NumTarget - 1) ? ((SRCW - 1) >= 0 ? (NumTarget - 1) * SRCW : (SRCW - 1) + ((NumTarget - 1) * (2 - SRCW))) : ((SRCW - 1) >= 0 ? 0 : SRCW - 1))] irq_id_o;
	output wire [NumTarget - 1:0] msip_o;
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
	wire [327:0] reg2hw;
	wire [164:0] hw2reg;
	localparam signed [31:0] MAX_PRIO = 3;
	localparam signed [31:0] PRIOW = 2;
	wire [NumSrc - 1:0] le;
	wire [NumSrc - 1:0] ip;
	wire [NumSrc - 1:0] ie [0:NumTarget - 1];
	wire [NumTarget - 1:0] claim_re;
	wire [SRCW - 1:0] claim_id [0:NumTarget - 1];
	reg [NumSrc - 1:0] claim;
	wire [NumTarget - 1:0] complete_we;
	wire [SRCW - 1:0] complete_id [0:NumTarget - 1];
	reg [NumSrc - 1:0] complete;
	wire [(0 >= (NumTarget - 1) ? ((SRCW - 1) >= 0 ? ((2 - NumTarget) * SRCW) + (((NumTarget - 1) * SRCW) - 1) : ((2 - NumTarget) * (2 - SRCW)) + (((SRCW - 1) + ((NumTarget - 1) * (2 - SRCW))) - 1)) : ((SRCW - 1) >= 0 ? (NumTarget * SRCW) + -1 : (NumTarget * (2 - SRCW)) + ((SRCW - 1) - 1))):(0 >= (NumTarget - 1) ? ((SRCW - 1) >= 0 ? (NumTarget - 1) * SRCW : (SRCW - 1) + ((NumTarget - 1) * (2 - SRCW))) : ((SRCW - 1) >= 0 ? 0 : SRCW - 1))] cc_id;
	wire [(0 >= (NumSrc - 1) ? ((2 - NumSrc) * PRIOW) + (((NumSrc - 1) * PRIOW) - 1) : (NumSrc * PRIOW) + -1):(0 >= (NumSrc - 1) ? (NumSrc - 1) * PRIOW : 0)] prio;
	wire [PRIOW - 1:0] threshold [0:NumTarget - 1];
	assign cc_id = irq_id_o;
	always @(*) begin
		claim = 1'sb0;
		begin : sv2v_autoblock_146
			reg signed [31:0] i;
			for (i = 0; i < NumTarget; i = i + 1)
				if (claim_re[i])
					claim[claim_id[i] - 1] = 1'b1;
		end
	end
	always @(*) begin
		complete = 1'sb0;
		begin : sv2v_autoblock_147
			reg signed [31:0] i;
			for (i = 0; i < NumTarget; i = i + 1)
				if (complete_we[i])
					complete[complete_id[i] - 1] = 1'b1;
		end
	end
	assign prio[(0 >= (NumSrc - 1) ? 0 : NumSrc - 1) * PRIOW+:PRIOW] = reg2hw[248-:2];
	assign prio[(0 >= (NumSrc - 1) ? 1 : (NumSrc - 1) - 1) * PRIOW+:PRIOW] = reg2hw[246-:2];
	assign prio[(0 >= (NumSrc - 1) ? 2 : (NumSrc - 1) - 2) * PRIOW+:PRIOW] = reg2hw[244-:2];
	assign prio[(0 >= (NumSrc - 1) ? 3 : (NumSrc - 1) - 3) * PRIOW+:PRIOW] = reg2hw[242-:2];
	assign prio[(0 >= (NumSrc - 1) ? 4 : (NumSrc - 1) - 4) * PRIOW+:PRIOW] = reg2hw[240-:2];
	assign prio[(0 >= (NumSrc - 1) ? 5 : (NumSrc - 1) - 5) * PRIOW+:PRIOW] = reg2hw[238-:2];
	assign prio[(0 >= (NumSrc - 1) ? 6 : (NumSrc - 1) - 6) * PRIOW+:PRIOW] = reg2hw[236-:2];
	assign prio[(0 >= (NumSrc - 1) ? 7 : (NumSrc - 1) - 7) * PRIOW+:PRIOW] = reg2hw[234-:2];
	assign prio[(0 >= (NumSrc - 1) ? 8 : (NumSrc - 1) - 8) * PRIOW+:PRIOW] = reg2hw[232-:2];
	assign prio[(0 >= (NumSrc - 1) ? 9 : (NumSrc - 1) - 9) * PRIOW+:PRIOW] = reg2hw[230-:2];
	assign prio[(0 >= (NumSrc - 1) ? 10 : (NumSrc - 1) - 10) * PRIOW+:PRIOW] = reg2hw[228-:2];
	assign prio[(0 >= (NumSrc - 1) ? 11 : (NumSrc - 1) - 11) * PRIOW+:PRIOW] = reg2hw[226-:2];
	assign prio[(0 >= (NumSrc - 1) ? 12 : (NumSrc - 1) - 12) * PRIOW+:PRIOW] = reg2hw[224-:2];
	assign prio[(0 >= (NumSrc - 1) ? 13 : (NumSrc - 1) - 13) * PRIOW+:PRIOW] = reg2hw[222-:2];
	assign prio[(0 >= (NumSrc - 1) ? 14 : (NumSrc - 1) - 14) * PRIOW+:PRIOW] = reg2hw[220-:2];
	assign prio[(0 >= (NumSrc - 1) ? 15 : (NumSrc - 1) - 15) * PRIOW+:PRIOW] = reg2hw[218-:2];
	assign prio[(0 >= (NumSrc - 1) ? 16 : (NumSrc - 1) - 16) * PRIOW+:PRIOW] = reg2hw[216-:2];
	assign prio[(0 >= (NumSrc - 1) ? 17 : (NumSrc - 1) - 17) * PRIOW+:PRIOW] = reg2hw[214-:2];
	assign prio[(0 >= (NumSrc - 1) ? 18 : (NumSrc - 1) - 18) * PRIOW+:PRIOW] = reg2hw[212-:2];
	assign prio[(0 >= (NumSrc - 1) ? 19 : (NumSrc - 1) - 19) * PRIOW+:PRIOW] = reg2hw[210-:2];
	assign prio[(0 >= (NumSrc - 1) ? 20 : (NumSrc - 1) - 20) * PRIOW+:PRIOW] = reg2hw[208-:2];
	assign prio[(0 >= (NumSrc - 1) ? 21 : (NumSrc - 1) - 21) * PRIOW+:PRIOW] = reg2hw[206-:2];
	assign prio[(0 >= (NumSrc - 1) ? 22 : (NumSrc - 1) - 22) * PRIOW+:PRIOW] = reg2hw[204-:2];
	assign prio[(0 >= (NumSrc - 1) ? 23 : (NumSrc - 1) - 23) * PRIOW+:PRIOW] = reg2hw[202-:2];
	assign prio[(0 >= (NumSrc - 1) ? 24 : (NumSrc - 1) - 24) * PRIOW+:PRIOW] = reg2hw[200-:2];
	assign prio[(0 >= (NumSrc - 1) ? 25 : (NumSrc - 1) - 25) * PRIOW+:PRIOW] = reg2hw[198-:2];
	assign prio[(0 >= (NumSrc - 1) ? 26 : (NumSrc - 1) - 26) * PRIOW+:PRIOW] = reg2hw[196-:2];
	assign prio[(0 >= (NumSrc - 1) ? 27 : (NumSrc - 1) - 27) * PRIOW+:PRIOW] = reg2hw[194-:2];
	assign prio[(0 >= (NumSrc - 1) ? 28 : (NumSrc - 1) - 28) * PRIOW+:PRIOW] = reg2hw[192-:2];
	assign prio[(0 >= (NumSrc - 1) ? 29 : (NumSrc - 1) - 29) * PRIOW+:PRIOW] = reg2hw[190-:2];
	assign prio[(0 >= (NumSrc - 1) ? 30 : (NumSrc - 1) - 30) * PRIOW+:PRIOW] = reg2hw[188-:2];
	assign prio[(0 >= (NumSrc - 1) ? 31 : (NumSrc - 1) - 31) * PRIOW+:PRIOW] = reg2hw[186-:2];
	assign prio[(0 >= (NumSrc - 1) ? 32 : (NumSrc - 1) - 32) * PRIOW+:PRIOW] = reg2hw[184-:2];
	assign prio[(0 >= (NumSrc - 1) ? 33 : (NumSrc - 1) - 33) * PRIOW+:PRIOW] = reg2hw[182-:2];
	assign prio[(0 >= (NumSrc - 1) ? 34 : (NumSrc - 1) - 34) * PRIOW+:PRIOW] = reg2hw[180-:2];
	assign prio[(0 >= (NumSrc - 1) ? 35 : (NumSrc - 1) - 35) * PRIOW+:PRIOW] = reg2hw[178-:2];
	assign prio[(0 >= (NumSrc - 1) ? 36 : (NumSrc - 1) - 36) * PRIOW+:PRIOW] = reg2hw[176-:2];
	assign prio[(0 >= (NumSrc - 1) ? 37 : (NumSrc - 1) - 37) * PRIOW+:PRIOW] = reg2hw[174-:2];
	assign prio[(0 >= (NumSrc - 1) ? 38 : (NumSrc - 1) - 38) * PRIOW+:PRIOW] = reg2hw[172-:2];
	assign prio[(0 >= (NumSrc - 1) ? 39 : (NumSrc - 1) - 39) * PRIOW+:PRIOW] = reg2hw[170-:2];
	assign prio[(0 >= (NumSrc - 1) ? 40 : (NumSrc - 1) - 40) * PRIOW+:PRIOW] = reg2hw[168-:2];
	assign prio[(0 >= (NumSrc - 1) ? 41 : (NumSrc - 1) - 41) * PRIOW+:PRIOW] = reg2hw[166-:2];
	assign prio[(0 >= (NumSrc - 1) ? 42 : (NumSrc - 1) - 42) * PRIOW+:PRIOW] = reg2hw[164-:2];
	assign prio[(0 >= (NumSrc - 1) ? 43 : (NumSrc - 1) - 43) * PRIOW+:PRIOW] = reg2hw[162-:2];
	assign prio[(0 >= (NumSrc - 1) ? 44 : (NumSrc - 1) - 44) * PRIOW+:PRIOW] = reg2hw[160-:2];
	assign prio[(0 >= (NumSrc - 1) ? 45 : (NumSrc - 1) - 45) * PRIOW+:PRIOW] = reg2hw[158-:2];
	assign prio[(0 >= (NumSrc - 1) ? 46 : (NumSrc - 1) - 46) * PRIOW+:PRIOW] = reg2hw[156-:2];
	assign prio[(0 >= (NumSrc - 1) ? 47 : (NumSrc - 1) - 47) * PRIOW+:PRIOW] = reg2hw[154-:2];
	assign prio[(0 >= (NumSrc - 1) ? 48 : (NumSrc - 1) - 48) * PRIOW+:PRIOW] = reg2hw[152-:2];
	assign prio[(0 >= (NumSrc - 1) ? 49 : (NumSrc - 1) - 49) * PRIOW+:PRIOW] = reg2hw[150-:2];
	assign prio[(0 >= (NumSrc - 1) ? 50 : (NumSrc - 1) - 50) * PRIOW+:PRIOW] = reg2hw[148-:2];
	assign prio[(0 >= (NumSrc - 1) ? 51 : (NumSrc - 1) - 51) * PRIOW+:PRIOW] = reg2hw[146-:2];
	assign prio[(0 >= (NumSrc - 1) ? 52 : (NumSrc - 1) - 52) * PRIOW+:PRIOW] = reg2hw[144-:2];
	assign prio[(0 >= (NumSrc - 1) ? 53 : (NumSrc - 1) - 53) * PRIOW+:PRIOW] = reg2hw[142-:2];
	assign prio[(0 >= (NumSrc - 1) ? 54 : (NumSrc - 1) - 54) * PRIOW+:PRIOW] = reg2hw[140-:2];
	assign prio[(0 >= (NumSrc - 1) ? 55 : (NumSrc - 1) - 55) * PRIOW+:PRIOW] = reg2hw[138-:2];
	assign prio[(0 >= (NumSrc - 1) ? 56 : (NumSrc - 1) - 56) * PRIOW+:PRIOW] = reg2hw[136-:2];
	assign prio[(0 >= (NumSrc - 1) ? 57 : (NumSrc - 1) - 57) * PRIOW+:PRIOW] = reg2hw[134-:2];
	assign prio[(0 >= (NumSrc - 1) ? 58 : (NumSrc - 1) - 58) * PRIOW+:PRIOW] = reg2hw[132-:2];
	assign prio[(0 >= (NumSrc - 1) ? 59 : (NumSrc - 1) - 59) * PRIOW+:PRIOW] = reg2hw[130-:2];
	assign prio[(0 >= (NumSrc - 1) ? 60 : (NumSrc - 1) - 60) * PRIOW+:PRIOW] = reg2hw[128-:2];
	assign prio[(0 >= (NumSrc - 1) ? 61 : (NumSrc - 1) - 61) * PRIOW+:PRIOW] = reg2hw[126-:2];
	assign prio[(0 >= (NumSrc - 1) ? 62 : (NumSrc - 1) - 62) * PRIOW+:PRIOW] = reg2hw[124-:2];
	assign prio[(0 >= (NumSrc - 1) ? 63 : (NumSrc - 1) - 63) * PRIOW+:PRIOW] = reg2hw[122-:2];
	assign prio[(0 >= (NumSrc - 1) ? 64 : (NumSrc - 1) - 64) * PRIOW+:PRIOW] = reg2hw[120-:2];
	assign prio[(0 >= (NumSrc - 1) ? 65 : (NumSrc - 1) - 65) * PRIOW+:PRIOW] = reg2hw[118-:2];
	assign prio[(0 >= (NumSrc - 1) ? 66 : (NumSrc - 1) - 66) * PRIOW+:PRIOW] = reg2hw[116-:2];
	assign prio[(0 >= (NumSrc - 1) ? 67 : (NumSrc - 1) - 67) * PRIOW+:PRIOW] = reg2hw[114-:2];
	assign prio[(0 >= (NumSrc - 1) ? 68 : (NumSrc - 1) - 68) * PRIOW+:PRIOW] = reg2hw[112-:2];
	assign prio[(0 >= (NumSrc - 1) ? 69 : (NumSrc - 1) - 69) * PRIOW+:PRIOW] = reg2hw[110-:2];
	assign prio[(0 >= (NumSrc - 1) ? 70 : (NumSrc - 1) - 70) * PRIOW+:PRIOW] = reg2hw[108-:2];
	assign prio[(0 >= (NumSrc - 1) ? 71 : (NumSrc - 1) - 71) * PRIOW+:PRIOW] = reg2hw[106-:2];
	assign prio[(0 >= (NumSrc - 1) ? 72 : (NumSrc - 1) - 72) * PRIOW+:PRIOW] = reg2hw[104-:2];
	assign prio[(0 >= (NumSrc - 1) ? 73 : (NumSrc - 1) - 73) * PRIOW+:PRIOW] = reg2hw[102-:2];
	assign prio[(0 >= (NumSrc - 1) ? 74 : (NumSrc - 1) - 74) * PRIOW+:PRIOW] = reg2hw[100-:2];
	assign prio[(0 >= (NumSrc - 1) ? 75 : (NumSrc - 1) - 75) * PRIOW+:PRIOW] = reg2hw[98-:2];
	assign prio[(0 >= (NumSrc - 1) ? 76 : (NumSrc - 1) - 76) * PRIOW+:PRIOW] = reg2hw[96-:2];
	assign prio[(0 >= (NumSrc - 1) ? 77 : (NumSrc - 1) - 77) * PRIOW+:PRIOW] = reg2hw[94-:2];
	assign prio[(0 >= (NumSrc - 1) ? 78 : (NumSrc - 1) - 78) * PRIOW+:PRIOW] = reg2hw[92-:2];
	generate
		genvar s;
		for (s = 0; s < 79; s = s + 1) begin : gen_ie0
			assign ie[0][s] = reg2hw[12 + s];
		end
	endgenerate
	assign threshold[0] = reg2hw[11-:2];
	assign claim_re[0] = reg2hw[1];
	assign claim_id[0] = irq_id_o[((SRCW - 1) >= 0 ? 0 : SRCW - 1) + ((0 >= (NumTarget - 1) ? 0 : NumTarget - 1) * ((SRCW - 1) >= 0 ? SRCW : 2 - SRCW))+:((SRCW - 1) >= 0 ? SRCW : 2 - SRCW)];
	assign complete_we[0] = reg2hw[2];
	assign complete_id[0] = reg2hw[9-:7];
	assign hw2reg[6-:7] = cc_id[((SRCW - 1) >= 0 ? 0 : SRCW - 1) + ((0 >= (NumTarget - 1) ? 0 : NumTarget - 1) * ((SRCW - 1) >= 0 ? SRCW : 2 - SRCW))+:((SRCW - 1) >= 0 ? SRCW : 2 - SRCW)];
	assign msip_o[0] = reg2hw[0];
	generate
		for (s = 0; s < 79; s = s + 1) begin : gen_ip
			assign hw2reg[7 + (s * 2)] = 1'b1;
			assign hw2reg[7 + ((s * 2) + 1)] = ip[s];
		end
	endgenerate
	generate
		for (s = 0; s < 79; s = s + 1) begin : gen_le
			assign le[s] = reg2hw[249 + s];
		end
	endgenerate
	rv_plic_gateway #(.N_SOURCE(NumSrc)) u_gateway(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.src(intr_src_i),
		.le(le),
		.claim(claim),
		.complete(complete),
		.ip(ip)
	);
	generate
		genvar i;
		for (i = 0; i < NumTarget; i = i + 1) begin : gen_target
			rv_plic_target #(
				.N_SOURCE(NumSrc),
				.MAX_PRIO(MAX_PRIO)
			) u_target(
				.clk_i(clk_i),
				.rst_ni(rst_ni),
				.ip(ip),
				.ie(ie[i]),
				.prio(prio),
				.threshold(threshold[i]),
				.irq(irq_o[i]),
				.irq_id(irq_id_o[((SRCW - 1) >= 0 ? 0 : SRCW - 1) + ((0 >= (NumTarget - 1) ? i : (NumTarget - 1) - i) * ((SRCW - 1) >= 0 ? SRCW : 2 - SRCW))+:((SRCW - 1) >= 0 ? SRCW : 2 - SRCW)])
			);
		end
	endgenerate
	rv_plic_reg_top u_reg(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.tl_i(tl_i),
		.tl_o(tl_o),
		.reg2hw(reg2hw),
		.hw2reg(hw2reg),
		.devmode_i(1'b1)
	);
	genvar k;
endmodule
