module ROM
(
input  wire       clk,
input  wire [7:0] adr,
output reg        dat
);

// ROM content
parameter [255:0] CONTENT = 256'd0;

// Data output
always @(posedge clk)
    dat <= CONTENT[adr];

endmodule

