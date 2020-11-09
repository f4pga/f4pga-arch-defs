//`include "C:/QuickLogic/QuickWorks_2016.1.1_Release/spde/data/PolarPro-III/AL4S3B/rrw/fifo_blk.v" 
`ifdef af512x16_512x16
`else
`define af512x16_512x16
/************************************************************************
** File : af512x16_512x16.v
** Design Date: April 11, 2005
** Creation Date: Mon Apr 03 16:51:33 2017

** Created By SpDE Version: SpDE 2016.1.1 Release
** Author: QuickLogic India Development Centre,
** Copyright (C) 1998, Customers of QuickLogic may copy and modify this
** file for use in designing QuickLogic devices only.
** Description : This file is autogenerated RTL code that describes the
** top level design file for Asynchronous FIFO using QuickLogic's
** RAM block resources.
************************************************************************/
module af512x16_512x16(DIN,Fifo_Push_Flush,Fifo_Pop_Flush,PUSH,POP,Push_Clk,Pop_Clk,
       Push_Clk_En,Pop_Clk_En,Fifo_Dir,Async_Flush,
       Almost_Full,Almost_Empty,PUSH_FLAG,POP_FLAG,DOUT);


input Fifo_Push_Flush,Fifo_Pop_Flush;
input Push_Clk,Pop_Clk;
input PUSH,POP;
input [15:0] DIN;
input Push_Clk_En,Pop_Clk_En,Fifo_Dir,Async_Flush;
output [15:0] DOUT;
output [3:0] PUSH_FLAG,POP_FLAG;
output Almost_Full,Almost_Empty;

parameter wr_depth_int = 512;
parameter rd_depth_int = 512;
parameter wr_width_int = 16;
parameter rd_width_int = 16;
parameter reg_rd_int = 0;
parameter sync_fifo_int = 0;

supply0 GND;
supply1 VCC;
FIFO #( wr_depth_int, rd_depth_int,wr_width_int,rd_width_int,reg_rd_int,sync_fifo_int) 
      FIFO_INST (.DIN(DIN),.PUSH(PUSH),.POP(POP),.Fifo_Push_Flush(Fifo_Push_Flush),.Fifo_Pop_Flush(Fifo_Pop_Flush),
      .Push_Clk(Push_Clk),.Pop_Clk(Pop_Clk),.PUSH_FLAG(PUSH_FLAG),.POP_FLAG(POP_FLAG),
      .Push_Clk_En(Push_Clk_En),.Pop_Clk_En(Pop_Clk_En),.Push_Clk_Sel(GND),.Pop_Clk_Sel(GND),.Fifo_Dir(Fifo_Dir),.Async_Flush(Async_Flush),.Async_Flush_Sel(GND),
      .Almost_Full(Almost_Full),.Almost_Empty(Almost_Empty),.DOUT(DOUT),.LS(1'b0),.SD(1'b0),.DS(1'b0),.LS_RB1(1'b0),.SD_RB1(1'b0),.DS_RB1(1'b0));
endmodule
`endif
