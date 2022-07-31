// 4-input, or LUT test.
module top( (* keep *) input [3:0] I, output O);
    always @(I)
    case(I)
        4'b0000 : O = 0;
        default : O = 1;
    endcase
endmodule // top
