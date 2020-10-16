module r512x32_1024x16 (WA,RA,WD,WD_SEL,RD_SEL,WClk,RClk,WClk_En,RClk_En,WEN,RD);

input [8:0] WA;
input [9:0] RA;
input WD_SEL,RD_SEL;
input WClk,RClk;
input WClk_En,RClk_En;
input [3:0] WEN;
input [31:0] WD;
output [15:0] RD;

parameter Concatenation_En = 1 ;

parameter wr_addr_int0 = 9 ;
parameter rd_addr_int0 = 10;
parameter wr_depth_int0 = 512;
parameter rd_depth_int0 = 1024;
parameter wr_width_int0 = 32;
parameter rd_width_int0 = 16;
parameter wr_enable_int0 = 4;
parameter reg_rd_int0 = 0;

RAM_16K_BLK #(Concatenation_En,
			  wr_addr_int0,rd_addr_int0,wr_depth_int0,rd_depth_int0,wr_width_int0,rd_width_int0,wr_enable_int0,reg_rd_int0
			  )
RAM_INST (	.WA0(WA),
			.RA0(RA),
			.WD0(WD),
			.WD0_SEL(WD_SEL),
			.RD0_SEL(RD_SEL),
			.WClk0(WClk),
			.RClk0(RClk),
			.WClk0_En(WClk_En),
			.RClk0_En(RClk_En),
			.WEN0(WEN),
			.RD0(RD),
					
			.LS(1'b0),
			.SD(1'b0),
			.DS(1'b0),
			.LS_RB1(1'b0),
			.SD_RB1(1'b0),
			.DS_RB1(1'b0)
			);

endmodule


