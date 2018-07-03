// 4-input, route-through LUT test.
module top( (* keep *) input [3:0] I, output O);
    //Cell instances
    SB_LUT4 #(
        .LUT_INIT(16'b0100000000000000)
    ) LUT  (
        .I0(1'b0),
        .I1(I[1]),
        .I2(1'b0),
        .I3(1'b0),
        .O(O)
    );
endmodule // top
