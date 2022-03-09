module top(input clk, cen, rst, ina, inb,
	   output reg outa, outb, outc, outd,
	   output [DEPTH-1:0] vec0,
	   output [DEPTH-1:0] vec1);

localparam DEPTH = 5;

reg [DEPTH-1:0] r_vec0 = 1'b0;
reg [DEPTH-1:0] r_vec1 = 1'b0;
initial outa = 1'b0;
initial outb = 1'b0;
initial outc = 1'b0;
initial outd = 1'b0;

// posedge, clock_enable, reset (sr)
always @(posedge clk)
    if (cen)
        if(rst)
            r_vec0 <= 1'b0;
        else
            r_vec0 <= {r_vec0[DEPTH-2:0], ina};

// negedge, clock_enable, reset (ss)
always @(negedge clk)
    if (ina)
        if(rst)
            r_vec1 <= 1'b1;
        else
            r_vec1 <= {r_vec1[DEPTH-2:0], inb};

// posedge, async reset (sr)
always @(posedge clk or posedge rst)
    if(rst)
        outa <= 1'b0;
    else
        outa <= r_vec0[DEPTH-1];

// posedge
always @(posedge clk)
    outb <= r_vec1[DEPTH-1];

// negedge
always @(negedge clk)
    outc <= r_vec0[DEPTH-1];

// negedge, async reset (ss)
always @(negedge clk or posedge rst)
    if (rst)
        outd <= 1'b1;
    else
        outd <= r_vec1[DEPTH-1];

assign vec0 = r_vec0;
assign vec1 = r_vec1;

endmodule
