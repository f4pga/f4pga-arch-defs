`include "bufr_unit.v"

module top(
    input         in_clk,
    input  [11:0] in,
    output [11:0] out
);

// Clock input buffer
wire clk;
BUFG bufgctrl(.I(in_clk), .O(clk));

// Reference
bufr_unit #(.BUFR_DIVIDE("none")) unit_x (
.CLK    (clk),
.CE     (in[0]),
.CLR    (in[1]),
.O      (out[0])
);

// BUFR test unit(s)
localparam N = 1; // Max 7!

genvar i;
generate for(i=0; i<N; i=i+1) begin

    localparam DIVIDE = (i == 0) ?   "2" :
                        (i == 1) ?   "3" :
                        (i == 2) ?   "4" :
                        (i == 3) ?   "5" :
                        (i == 4) ?   "6" :
                        (i == 5) ?   "7" :
                      /*(i == 6) ?*/ "8";

    bufr_unit #(.BUFR_DIVIDE(DIVIDE)) unit (
    .CLK    (in_clk),
    .CE     (in[0]),
    .CLR    (in[1]),
    .O      (out[i+1])
    );

end endgenerate

assign out[11:N+1] = in[11:N+1];

endmodule
