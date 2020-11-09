module f512x18_512x9(DIN,Fifo_Push_Flush,Fifo_Pop_Flush,PUSH,POP,Clk,Clk_En,Fifo_Dir,Async_Flush,Almost_Full,Almost_Empty,PUSH_FLAG,POP_FLAG,DOUT,
					 DIN1,Fifo_Push_Flush1,Fifo_Pop_Flush1,PUSH1,POP1,Clk1,Clk_En1,Fifo_Dir1,Async_Flush1,Almost_Full1,Almost_Empty1,PUSH_FLAG1,POP_FLAG1,DOUT1
					 );

input Fifo_Push_Flush,Fifo_Pop_Flush;
input Clk;
input PUSH,POP;
input [17:0] DIN;
input Clk_En,Fifo_Dir,Async_Flush;
output [17:0] DOUT;
output [3:0] PUSH_FLAG,POP_FLAG;
output Almost_Full,Almost_Empty;

input Fifo_Push_Flush1,Fifo_Pop_Flush1;
input Clk1;
input PUSH1,POP1;
input [8:0] DIN1;
input Clk_En1,Fifo_Dir1,Async_Flush1;
output [8:0] DOUT1;
output [3:0] PUSH_FLAG1,POP_FLAG1;
output Almost_Full1,Almost_Empty1;

wire [10 :0] addr_wr,addr_rd;
wire		clk_sig,clk1_sig;

wire [35:0] in_reg;
wire [35:0] in_reg1;
wire [35:0] out_reg;
wire [35:0] out_reg1;

/*
parameter wr_depth_int = 512;
parameter rd_depth_int = 512;
parameter wr_width_int = 18;
parameter rd_width_int = 18;
parameter reg_rd_int = 0;
parameter sync_fifo_int = 1;

supply0 GND;
supply1 VCC;
FIFO #( wr_depth_int, rd_depth_int,wr_width_int,rd_width_int,reg_rd_int,sync_fifo_int) 
FIFO_INST (.DIN(DIN),.PUSH(PUSH),.POP(POP),.Fifo_Push_Flush(Fifo_Push_Flush),.Fifo_Pop_Flush(Fifo_Pop_Flush),
           .Push_Clk(Clk),.Pop_Clk(Clk),.PUSH_FLAG(PUSH_FLAG),.POP_FLAG(POP_FLAG),
      .Push_Clk_En(Clk_En),.Pop_Clk_En(Clk_En),.Fifo_Dir(Fifo_Dir),.Async_Flush(Async_Flush),.Push_Clk_Sel(GND),.Pop_Clk_Sel(GND),.Async_Flush_Sel(GND),
           .Almost_Full(Almost_Full),.Almost_Empty(Almost_Empty),.DOUT(DOUT),.LS(1'b0),.SD(1'b0),.DS(1'b0),.LS_RB1(1'b0),.SD_RB1(1'b0),.DS_RB1(1'b0));
*/

supply0 GND;
supply1 VCC;

assign addr_wr=11'b00000000000;
assign addr_rd=11'b00000000000;

assign clk_sig = Clk;
assign clk1_sig = Clk1 ;

assign clk_sig_en = Clk_En;
assign clk1_sig_en = Clk_En1 ;

assign in_reg[35:0] = {18'h0, DIN[17:0]};
assign in_reg1[35:0] = {27'h0, DIN1[8:0]};

assign DOUT[17:0] = out_reg[17:0];
assign DOUT1[8:0] = out_reg1[8:0];


ram8k_2x1_cell_macro U1 (.A1_0(addr_wr) , 
						 .A1_1(addr_wr), 
						 .A2_0(addr_rd), 
						 .A2_1(addr_rd), 
						 .ASYNC_FLUSH_0(Async_Flush), 
						 .ASYNC_FLUSH_1(Async_Flush1),
						 .ASYNC_FLUSH_S0(GND), 
						 .ASYNC_FLUSH_S1(GND), 
						 .CLK1_0(clk_sig), 
						 .CLK1_1(clk1_sig), 
						 .CLK1EN_0(clk_sig_en), 
						 .CLK1EN_1(clk1_sig_en), 
						 .CLK2_0(clk_sig),
						 .CLK2_1(clk1_sig), 
						 .CLK1S_0(GND), 
						 .CLK1S_1(GND), 
						 .CLK2S_0(GND),
						 .CLK2S_1(GND),
						 .CLK2EN_0(clk_sig_en), 
						 .CLK2EN_1(clk1_sig_en), 
						 .CONCAT_EN_0(GND),
						 .CONCAT_EN_1(GND), 
						 .CS1_0(Fifo_Push_Flush), 
						 .CS1_1(Fifo_Push_Flush1), 
						 .CS2_0(Fifo_Pop_Flush), 
						 .CS2_1(Fifo_Pop_Flush1), 
						 .DIR_0(Fifo_Dir),
						 .DIR_1(Fifo_Dir1), 
						 .FIFO_EN_0(VCC), 
						 .FIFO_EN_1(VCC), 
						 .P1_0(PUSH), 
						 .P1_1(PUSH1), 
						 .P2_0(POP),
						 .P2_1(POP1), 
						 .PIPELINE_RD_0(GND), 
						 .PIPELINE_RD_1(GND), 
						 .SYNC_FIFO_0(VCC),
						 .SYNC_FIFO_1(VCC), 
						 .WD_1(in_reg1[17:0]), 
						 .WD_0(in_reg[17:0]), 
						 .WIDTH_SELECT1_0({GND,VCC}), 
						 .WIDTH_SELECT1_1({GND,GND}), 
						 .WIDTH_SELECT2_0({GND,VCC}),
						 .WIDTH_SELECT2_1({GND,GND}), 
						 // PP-II doesn't use this signal
						 .WEN1_0({GND,GND}), 
						 .WEN1_1({GND,GND}), 
						 .Almost_Empty_0(Almost_Empty),
						 .Almost_Empty_1(Almost_Empty1), 
						 .Almost_Full_0(Almost_Full), 
						 .Almost_Full_1(Almost_Full1),
						 .POP_FLAG_0(POP_FLAG), 
						 .POP_FLAG_1(POP_FLAG1), 
						 .PUSH_FLAG_0(PUSH_FLAG), 
						 .PUSH_FLAG_1(PUSH_FLAG1),
						 .RD_0(out_reg[17:0]), 
						 .RD_1(out_reg1[17:0]),
						 .SD(1'b0),
						 .SD_RB1(1'b0),
						 .LS(1'b0),
						 .LS_RB1(1'b0),
						 .DS(1'b0),
						 .DS_RB1(1'b0),
						 .TEST1A(GND),
						 .TEST1B(GND),
						 .RMA(4'd0),
						 .RMB(4'd0),
						 .RMEA(GND),
						 .RMEB(GND)
						 );						   
  
endmodule

