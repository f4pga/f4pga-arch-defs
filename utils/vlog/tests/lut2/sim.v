module lut2 (input a, b, output y, co);
parameter [3:0] content = 4'b1000;
assign y = content[{b, a}];
assign co = 1'b0;
endmodule
