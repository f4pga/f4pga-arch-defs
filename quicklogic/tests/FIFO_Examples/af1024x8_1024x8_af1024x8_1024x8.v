module af1024x8_1024x8_af1024x8_1024x8 (DIN0,Fifo_Push_Flush0,Fifo_Pop_Flush0,PUSH0,POP0,Push_Clk0,Pop_Clk0,Push_Clk0_En,Pop_Clk0_En,Fifo0_Dir,Async_Flush0,Almost_Full0,Almost_Empty0,PUSH_FLAG0,POP_FLAG0,DOUT0,
										DIN1,Fifo_Push_Flush1,Fifo_Pop_Flush1,PUSH1,POP1,Push_Clk1,Pop_Clk1,Push_Clk1_En,Pop_Clk1_En,Fifo1_Dir,Async_Flush1,Almost_Full1,Almost_Empty1,PUSH_FLAG1,POP_FLAG1,DOUT1
										);

input Fifo_Push_Flush0,Fifo_Pop_Flush0;
input Push_Clk0,Pop_Clk0;
input PUSH0,POP0;
input [7:0] DIN0;
input Push_Clk0_En,Pop_Clk0_En,Fifo0_Dir,Async_Flush0;
output [7:0] DOUT0;
output [3:0] PUSH_FLAG0,POP_FLAG0;
output Almost_Full0,Almost_Empty0;

input Fifo_Push_Flush1,Fifo_Pop_Flush1;
input Push_Clk1,Pop_Clk1;
input PUSH1,POP1;
input [7:0] DIN1;
input Push_Clk1_En,Pop_Clk1_En,Fifo1_Dir,Async_Flush1;
output [7:0] DOUT1;
output [3:0] PUSH_FLAG1,POP_FLAG1;
output Almost_Full1,Almost_Empty1;

parameter Concatenation_En = 0;

parameter wr_depth_int0 = 1024;
parameter rd_depth_int0 = 1024;
parameter wr_width_int0 = 8;
parameter rd_width_int0 = 8;
parameter reg_rd_int0 = 0;
parameter sync_fifo_int0 = 0;

parameter wr_depth_int1 = 1024;
parameter rd_depth_int1 = 1024;
parameter wr_width_int1 = 8;
parameter rd_width_int1 = 8;
parameter reg_rd_int1 = 0;
parameter sync_fifo_int1 = 0;

FIFO_16K_BLK   #(Concatenation_En,
				 wr_depth_int0,rd_depth_int0,wr_width_int0,rd_width_int0,reg_rd_int0,sync_fifo_int0,
				 wr_depth_int1,rd_depth_int1,wr_width_int1,rd_width_int1,reg_rd_int1,sync_fifo_int1
				 ) 
FIFO_INST      (.DIN0(DIN0),
				.PUSH0(PUSH0),
				.POP0(POP0),
				.Fifo_Push_Flush0(Fifo_Push_Flush0),
				.Fifo_Pop_Flush0(Fifo_Pop_Flush0),
				.Push_Clk0(Push_Clk0),
				.Pop_Clk0(Pop_Clk0),
				.PUSH_FLAG0(PUSH_FLAG0),
				.POP_FLAG0(POP_FLAG0),
				.Push_Clk0_En(Push_Clk0_En),
				.Pop_Clk0_En(Pop_Clk0_En),
				.Fifo0_Dir(Fifo0_Dir),
				.Async_Flush0(Async_Flush0),
				.Almost_Full0(Almost_Full0),
				.Almost_Empty0(Almost_Empty0),
				.DOUT0(DOUT0),
				
				.DIN1(DIN1),
				.PUSH1(PUSH1),
				.POP1(POP1),
				.Fifo_Push_Flush1(Fifo_Push_Flush1),
				.Fifo_Pop_Flush1(Fifo_Pop_Flush1),
				.Push_Clk1(Push_Clk1),
				.Pop_Clk1(Pop_Clk1),
				.PUSH_FLAG1(PUSH_FLAG1),
				.POP_FLAG1(POP_FLAG1),
				.Push_Clk1_En(Push_Clk1_En),
				.Pop_Clk1_En(Pop_Clk1_En),
				.Fifo1_Dir(Fifo1_Dir),
				.Async_Flush1(Async_Flush1),
				.Almost_Full1(Almost_Full1),
				.Almost_Empty1(Almost_Empty1),
				.DOUT1(DOUT1),
			
				.LS(1'b0),
				.SD(1'b0),
				.DS(1'b0),
				.LS_RB1(1'b0),
				.SD_RB1(1'b0),
				.DS_RB1(1'b0)				
				);
				
endmodule

