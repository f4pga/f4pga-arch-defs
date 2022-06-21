module top (WA,RA,WD,WClk,RClk,WClk_En,RClk_En,WEN,RD);

input  WA;
input  RA;
input  WClk,RClk;
input  WClk_En,RClk_En;
input  [1:0] WEN;
input  WD;
output RD;

localparam addr_bits = 11;
localparam data_bits = 8;

reg  [addr_bits-1:0] wa;
reg  [addr_bits-1:0] ra;
reg  [data_bits-1:0] wd;
reg  [data_bits-1:0] rd;

wire [data_bits-1:0] _rd;

// Note: The following shift regs are there just to reduce the top-level IO
// count.
always @(posedge WClk)
    wa <= (wa << 1) | WA;
always @(posedge RClk)
    ra <= (ra << 1) | RA;
always @(posedge WClk)
    wd <= (wd << 1) | WD;
always @(posedge RClk)
    rd <= |WEN ? (rd << 1) : _rd;

assign RD = rd;

r2048x8_2048x8 the_ram (
    .WA      (wa),
    .RA      (ra),
    .WD      (wd),
    .RD      (_rd),
    .WClk    (WClk),
    .RClk    (RClk),
    .WClk_En (WClk_En),
    .RClk_En (RClk_En),
    .WEN     (|WEN)
);

endmodule

