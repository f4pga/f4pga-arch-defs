module adder(input a, b, ci, output y, co);
assign {co, y} = a + b + ci;
endmodule
