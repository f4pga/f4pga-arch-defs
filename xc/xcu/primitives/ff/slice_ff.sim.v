`include "slice_ff_half.sim.v"

module SLICE_FF(D, SR, CE, CLK, Q);
    input wire [15:0] D;
    input wire [1:0] SR;
    input wire [3:0] CE;
    input wire [1:0] CLK;
    output wire [15:0] Q;

    SLICE_FF_HALF BOT_SLICE_FF(.D(D[7:0]), .SR(SR[0]), .CE(CE[1:0]), .CLK(CLK[0]), .Q(Q[7:0]));
    SLICE_FF_HALF TOP_SLICE_FF(.D(D[15:8]), .SR(SR[1]), .CE(CE[3:2]), .CLK(CLK[1]), .Q(Q[15:8]));

endmodule
