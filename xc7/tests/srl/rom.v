module ROM
(
input  wire     clk,
input  wire     ce,
output wire     q
);

//localparam [31:0] DATA = 32'b01001100_01110000_11110000_01111100;
localparam [31:0] DATA = 32'b11100011_10001110_00111000_11100000;

reg [4:0] adr = 0;

assign q = DATA[adr];

always @(posedge clk)
    if (ce) adr <= adr + 1;
    else    adr <= adr;

endmodule
