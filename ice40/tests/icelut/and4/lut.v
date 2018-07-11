// 4-input, and LUT test.
module top( (* keep *) input [3:0] I, output O);
    always @(I)
    case(I)
        4'b1111 : O = 1;
        default : O = 0;
    endcase
endmodule // top
