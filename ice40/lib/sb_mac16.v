(* blackbox *)
module SB_MAC16 (
	input CLK,
	input CE,
	input [15:0] C,
	input [15:0] A,
	input [15:0] B,
	input [15:0] D,
	input AHOLD,
	input BHOLD,
	input CHOLD,
	input DHOLD,
	input IRSTTOP,
	input IRSTBOT,
	input ORSTTOP,
	input ORSTBOT,
	input OLOADTOP,
	input OLOADBOT,
	input ADDSUBTOP,
	input ADDSUBBOT,
	input OHOLDTOP,
	input OHOLDBOT,
	input CI,
	input ACCUMCI,
	input SIGNEXTIN,
	output [31:0] O,
	output CO,
	output ACCUMCO,
	output SIGNEXTOUT
);
parameter NEG_TRIGGER = 1'b0;
parameter C_REG = 1'b0;
parameter A_REG = 1'b0;
parameter B_REG = 1'b0;
parameter D_REG = 1'b0;
parameter TOP_8x8_MULT_REG = 1'b0;
parameter BOT_8x8_MULT_REG = 1'b0;
parameter PIPELINE_16x16_MULT_REG1 = 1'b0;
parameter PIPELINE_16x16_MULT_REG2 = 1'b0;
parameter TOPOUTPUT_SELECT =  2'b00;
parameter TOPADDSUB_LOWERINPUT = 2'b00;
parameter TOPADDSUB_UPPERINPUT = 1'b0;
parameter TOPADDSUB_CARRYSELECT = 2'b00;
parameter BOTOUTPUT_SELECT =  2'b00;
parameter BOTADDSUB_LOWERINPUT = 2'b00;
parameter BOTADDSUB_UPPERINPUT = 1'b0;
parameter BOTADDSUB_CARRYSELECT = 2'b00;
parameter MODE_8x8 = 1'b0;
parameter A_SIGNED = 1'b0;
parameter B_SIGNED = 1'b0;
endmodule
