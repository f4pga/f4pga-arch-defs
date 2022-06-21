module af512x32_512x32 (DIN,Fifo_Push_Flush,Fifo_Pop_Flush,PUSH,POP,Push_Clk,Pop_Clk,Push_Clk_En,Pop_Clk_En,Fifo_Dir,Async_Flush,Almost_Full,Almost_Empty,PUSH_FLAG,POP_FLAG,DOUT);

input Fifo_Push_Flush,Fifo_Pop_Flush;
input Push_Clk,Pop_Clk;
input PUSH,POP;
input [31:0] DIN;
input Push_Clk_En,Pop_Clk_En,Fifo_Dir,Async_Flush;
output [31:0] DOUT;
output [3:0] PUSH_FLAG,POP_FLAG;
output Almost_Full,Almost_Empty;

parameter data_depth_int = 512;
parameter data_width_int = 32;
parameter reg_rd_int = 0;
parameter sync_fifo_int = 0;

FIFO_16K_BLK  # (.data_depth_int(data_depth_int),.data_width_int(data_width_int),.reg_rd_int(reg_rd_int),.sync_fifo_int(sync_fifo_int)
        				 ) 
  FIFO_INST    (
                .DIN(DIN),
                .PUSH(PUSH),
                .POP(POP),
                .Fifo_Push_Flush(Fifo_Push_Flush),
                .Fifo_Pop_Flush(Fifo_Pop_Flush),
                .Push_Clk(Push_Clk),
                .Pop_Clk(Pop_Clk),
                .PUSH_FLAG(PUSH_FLAG),
                .POP_FLAG(POP_FLAG),
                .Push_Clk_En(Push_Clk_En),
                .Pop_Clk_En(Pop_Clk_En),
                .Fifo_Dir(Fifo_Dir),
                .Async_Flush(Async_Flush),
                .Almost_Full(Almost_Full),
                .Almost_Empty(Almost_Empty),
                .DOUT(DOUT)
         				);

endmodule

