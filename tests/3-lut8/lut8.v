// 8-input LUT test.
module top(input [7:0] I, output O);
    always @(I)
    case(I)
        8'b00000000 : O = 1;
        8'b10000000 : O = 1;
        8'b11000000 : O = 1;
        8'b10100000 : O = 1;
        8'b10010000 : O = 1;
        8'b10001000 : O = 1;
        8'b10000100 : O = 1;
        8'b10000010 : O = 1;
        8'b11111111 : O = 1;
        default : O = 0;
    endcase
endmodule // top
