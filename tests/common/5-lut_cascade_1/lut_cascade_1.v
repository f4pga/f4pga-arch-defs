// 4-input LUT test.
module luta(input [3:0] I, output O);
    always @(I)
    case(I)
        4'b1000 : O = 1;
        4'b1001 : O = 1;
        4'b1010 : O = 1;
        4'b1100 : O = 1;
        4'b1110 : O = 1;
        4'b1111 : O = 1;
        default : O = 0;
    endcase
endmodule // top

module lutb(input [3:0] I, output O);
    always @(I)
    case(I)
        4'b1001 : O = 1;
        4'b1010 : O = 1;
        4'b1100 : O = 1;
        4'b1110 : O = 1;
        4'b1111 : O = 1;
        default : O = 0;
    endcase
endmodule // top

module top(input [6:0] I, output O);
    wire cascade;

    luta luta_i (I[3:0], cascade);
    lutb lutb_i ({cascade, I[6:3]}, O);

endmodule // top
