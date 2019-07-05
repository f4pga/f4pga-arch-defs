`timescale 1 ns / 1 ps
`default_nettype none

module test;

`include "../../../../library/tbassert.v"

// ============================================================================

initial begin
    $dumpfile("tb.vcd");
    $dumpvars(0, tb);

    #100000 $finish();
end

// ============================================================================

reg CLK;
reg RST;

initial CLK <= 1'b1;
always #0.5 CLK <= ~CLK;

initial begin   
    #0      RST <= 1'b1;
    #10.1   RST <= 1'b0;
end

// ============================================================================
// DUT
localparam CHAIN_COUNT = 1;

wire [15:0] led;
wire error;

top #
(
.PRESCALER   (4),
.CHAIN_COUNT (CHAIN_COUNT)
)
dut
(
.clk    (CLK),
.rx     (1'b1),
.tx     (),
.sw     (16'd0),
.led    (led)
);

assign error = |led[CHAIN_COUNT-1:0];

always @(posedge CLK)
    tbassert(error == 1'd0);

// ============================================================================

endmodule

