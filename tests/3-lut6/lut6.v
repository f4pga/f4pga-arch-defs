// 6-input LUT test.
module top(input [5:0] I, output O);
    always @(I)
    case(I)
        6'b000000 : O = 1;
        6'b100000 : O = 1;
        6'b110000 : O = 1;
        6'b101000 : O = 1;
        6'b100100 : O = 1;
        6'b100010 : O = 1;
        6'b100001 : O = 1;
        6'b111111 : O = 1;
        default : O = 0;
    endcase
endmodule // top
