// 7-input LUT test.
module top(input [6:0] I, output O);
    always @(I)
    case(I)
        7'b0000000 : O = 1;
        7'b1000000 : O = 1;
        7'b1100000 : O = 1;
        7'b1010000 : O = 1;
        7'b1001000 : O = 1;
        7'b1000100 : O = 1;
        7'b1000010 : O = 1;
        7'b1000001 : O = 1;
        7'b1111111 : O = 1;
        default : O = 0;
    endcase
endmodule // top
