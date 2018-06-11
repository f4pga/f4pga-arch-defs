// 4-input, route-through LUT test.
module top( (* keep *) input [3:0] I, output O);
    always @(I)
    case(I)
        4'b1??? : O = 1;
        4'b0??? : O = 0;
    endcase
endmodule // top
