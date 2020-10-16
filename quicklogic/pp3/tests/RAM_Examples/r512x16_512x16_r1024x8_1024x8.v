module r512x16_512x16_r1024x8_1024x8 (WA0,RA0,WD0,WD0_SEL,RD0_SEL,WClk0,RClk0,WClk0_En,RClk0_En,WEN0,RD0,
									  WA1,RA1,WD1,WD1_SEL,RD1_SEL,WClk1,RClk1,WClk1_En,RClk1_En,WEN1,RD1
									  );

input [8:0] WA0;
input [8:0] RA0;
input WD0_SEL,RD0_SEL;
input WClk0,RClk0;
input WClk0_En,RClk0_En;
input [1:0] WEN0;
input [15:0] WD0;
output [15:0] RD0;

input [9:0] WA1;
input [9:0] RA1;
input WD1_SEL,RD1_SEL;
input WClk1,RClk1;
input WClk1_En,RClk1_En;
input WEN1;
input [7:0] WD1;
output [7:0] RD1;

parameter Concatenation_En = 0 ;

parameter wr_addr_int0 = 9 ;
parameter rd_addr_int0 = 9;
parameter wr_depth_int0 = 512;
parameter rd_depth_int0 = 512;
parameter wr_width_int0 = 16;
parameter rd_width_int0 = 16;
parameter wr_enable_int0 = 2;
parameter reg_rd_int0 = 0;

parameter wr_addr_int1 = 10;
parameter rd_addr_int1 = 10;
parameter wr_depth_int1 = 1024;
parameter rd_depth_int1 = 1024;
parameter wr_width_int1 = 8;
parameter rd_width_int1 = 8;
parameter wr_enable_int1 = 1;
parameter reg_rd_int1 = 0;


RAM_16K_BLK #(Concatenation_En,
			  wr_addr_int0,rd_addr_int0,wr_depth_int0,rd_depth_int0,wr_width_int0,rd_width_int0,wr_enable_int0,reg_rd_int0,
              wr_addr_int1,rd_addr_int1,wr_depth_int1,rd_depth_int1,wr_width_int1,rd_width_int1,wr_enable_int1,reg_rd_int1
			  )
RAM_INST (	.WA0(WA0),
			.RA0(RA0),
			.WD0(WD0),
			.WD0_SEL(WD0_SEL),
			.RD0_SEL(RD0_SEL),
			.WClk0(WClk0),
			.RClk0(RClk0),
			.WClk0_En(WClk0_En),
			.RClk0_En(RClk0_En),
			.WEN0(WEN0),
			.RD0(RD0),
		
			.WA1(WA1),
			.RA1(RA1),
			.WD1(WD1),
			.WD1_SEL(WD1_SEL),
			.RD1_SEL(RD1_SEL),
			.WClk1(WClk1),
			.RClk1(RClk1),
			.WClk1_En(WClk1_En),
			.RClk1_En(RClk1_En),
			.WEN1(WEN1),
			.RD1(RD1),

			.LS(1'b0),
			.SD(1'b0),
			.DS(1'b0),
			.LS_RB1(1'b0),
			.SD_RB1(1'b0),
			.DS_RB1(1'b0)
			);
endmodule

