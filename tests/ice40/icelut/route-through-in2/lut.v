// 4-input, route-through LUT test.
module top( (* keep *) input [3:0] I, output O);
    always @(I)
    case(I)
        4'b0100 : O = 1;
        4'b0000 : O = 0;
        default : O = 0;
    endcase
endmodule // top
