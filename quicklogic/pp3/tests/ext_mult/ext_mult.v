module top(
    input  wire [ 7:0] dat_a,
    input  wire [ 7:0] dat_b,
    output wire [15:0] dat_o
);

    // Asynchronous multiplier implemented using logic.
    // For the purpose of timing model evaluation.
    assign dat_o = dat_a * dat_b;

endmodule
