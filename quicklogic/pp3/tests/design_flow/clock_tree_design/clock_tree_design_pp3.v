module clock_tree_design_pp3 (
    input  wire [4:0]  clk,
    input  wire        t,
    input  wire        clr_n,
    input  wire [1:0]  sel,
    output wire [19:0] mux_out
);

    clock_tree_design wrapped (
        .clk    (clk),
        .t      (t),
        .clr_n  (clr_n),
        .sel    (sel),
        .mux_out(mux_out)
    );

endmodule
