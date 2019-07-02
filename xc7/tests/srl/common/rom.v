module ROM
(
input  wire       clk,
input  wire [8:0] adr,
output reg        dat
);

// ROM content
parameter [511:0] CONTENT = 512'd0;

// Data output
always @(posedge clk)
    dat <= CONTENT[adr];

endmodule

