// Two 5-input LUT which share inputs but independent outputs.
module top(input [4:0] I, output O1, output O2);
    // LUT5 to output O1
    always @(I)
    case(I)
        5'b00000 : O1 = 1;
        5'b10000 : O1 = 1;
        5'b11000 : O1 = 1;
        5'b10100 : O1 = 1;
        5'b10010 : O1 = 1;
        5'b10001 : O1 = 1;
        5'b11111 : O1 = 1;
        default : O1 = 0;
    endcase

    // LUT5 to output O2
    always @(I)
    case(I)
        5'b00000 : O2 = 1;
        5'b10000 : O2 = 1;
        5'b11000 : O2 = 1;
        5'b01100 : O2 = 1;
        5'b00110 : O2 = 1;
        5'b10011 : O2 = 1;
        5'b00001 : O2 = 1;
        5'b11111 : O2 = 1;
        default : O2 = 0;
    endcase
endmodule // top
