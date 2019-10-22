module bufr_unit(
    input  wire CLK,
    input  wire CE,
    input  wire CLR,
    output wire O
);

parameter BUFR_DIVIDE = "bypass";

wire CLK_BUFR;

// The BUFR
generate if (BUFR_DIVIDE == "none") begin
    assign CLK_BUFR = CLK;

end else begin
    BUFR #(.BUFR_DIVIDE(BUFR_DIVIDE)) the_bufr (
    .I(CLK),
    .CE(CE),
    .CLR(CLR),
    .O(CLK_BUFR)
    );

end endgenerate

// Blinky counter
reg [23:0] cnt_div;

always @(posedge CLK_BUFR)
    cnt_div  <= cnt_div  + 1;

assign O = cnt_div [23];

endmodule
