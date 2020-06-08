module f1024x16_1024x16(DIN,Fifo_Push_Flush,Fifo_Pop_Flush,PUSH,POP,Clk,Clk_En,Fifo_Dir,Async_Flush,Almost_Full,Almost_Empty,PUSH_FLAG,POP_FLAG,DOUT);

input Fifo_Push_Flush,Fifo_Pop_Flush;
input Clk;
input PUSH,POP;
input [15:0] DIN;
input Clk_En,Fifo_Dir,Async_Flush;
output [15:0] DOUT;
output [3:0] PUSH_FLAG,POP_FLAG;
output Almost_Full,Almost_Empty;

parameter Concatenation_En = 1;

parameter wr_depth_int0 = 1024;
parameter rd_depth_int0 = 1024;
parameter wr_width_int0 = 16;
parameter rd_width_int0 = 16;
parameter reg_rd_int0 = 0;
parameter sync_fifo_int0 = 1;


FIFO_16K_BLK   #(Concatenation_En,
				 wr_depth_int0,rd_depth_int0,wr_width_int0,rd_width_int0,reg_rd_int0,sync_fifo_int0
				 ) 
FIFO_INST      (.DIN0(DIN),
				.PUSH0(PUSH),
				.POP0(POP),
				.Fifo_Push_Flush0(Fifo_Push_Flush),
				.Fifo_Pop_Flush0(Fifo_Pop_Flush),
				.Push_Clk0(Clk),
				.Pop_Clk0(Clk),
				.PUSH_FLAG0(PUSH_FLAG),
				.POP_FLAG0(POP_FLAG),
				.Push_Clk0_En(Clk_En),
				.Pop_Clk0_En(Clk_En),
				.Fifo0_Dir(Fifo_Dir),
				.Async_Flush0(Async_Flush),
				.Almost_Full0(Almost_Full),
				.Almost_Empty0(Almost_Empty),
				.DOUT0(DOUT),
				
				.LS(1'b0),
				.SD(1'b0),
				.DS(1'b0),
				.LS_RB1(1'b0),
				.SD_RB1(1'b0),
				.DS_RB1(1'b0)				
				);

endmodule

