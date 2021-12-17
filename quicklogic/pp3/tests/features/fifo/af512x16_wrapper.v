module top (DIN,Fifo_Push_Flush,Fifo_Pop_Flush,PUSH,POP,Push_Clk,Pop_Clk,Push_Clk_En,Pop_Clk_En,Async_Flush,Almost_Full,Almost_Empty,PUSH_FLAG,POP_FLAG,DOUT);

input  Fifo_Push_Flush,Fifo_Pop_Flush;
input  Push_Clk,Pop_Clk;
input  PUSH,POP;
input  DIN;
input  Push_Clk_En,Pop_Clk_En,Async_Flush;
output DOUT;
output [3:0] PUSH_FLAG,POP_FLAG;
output Almost_Full,Almost_Empty;

localparam data_bits = 16;


reg  [data_bits-1:0] di;
reg  [data_bits-1:0] do;

wire [data_bits-1:0] _do;

// Note: The following shift regs are there just to reduce the top-level IO
// count.
always @(posedge WClk)
    di <= (di << 1) | DIN;
always @(posedge RClk)
    do <= POP_FLAG ? (do << 1) : _do;

assign DOUT = do;

af512x16_512x16 the_fifo(
    .DIN            (di),
    .Fifo_Push_Flush(Fifo_Push_Flush),
    .Fifo_Pop_Flush (Fifo_Pop_Flush),
    .PUSH           (PUSH),
    .POP            (POP),
    .Push_Clk       (Push_Clk),
    .Pop_Clk        (Pop_Clk),
    .Push_Clk_En    (Push_Clk_En),
    .Pop_Clk_En     (Pop_Clk_En),
    .Fifo_Dir       (1),
    .Async_Flush    (Async_Flush),
    .Almost_Full    (Almost_Full),
    .Almost_Empty   (Almost_Empty),
    .PUSH_FLAG      (PUSH_FLAG),
    .POP_FLAG       (POP_FLAG),
    .DOUT           (_do)
);

endmodule

