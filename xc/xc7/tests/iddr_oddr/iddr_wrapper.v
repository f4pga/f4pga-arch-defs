module iddr_wrapper (
    input  wire C,
    input  wire CB,
    input  wire CE,
    input  wire S,
    input  wire R,
    input  wire D,
    output wire Q1,
    output wire Q2
);

    parameter USE_PHY_IDDR  = 0;
    parameter USE_IDELAY    = 0;
    parameter DDR_CLK_EDGE  = "OPPOSITE_EDGE";
    parameter INIT_Q1       = 0;
    parameter INIT_Q2       = 0;
    parameter SRTYPE        = "ASYNC";

    // Use a physical IDDR
    generate if (USE_PHY_IDDR) begin
        wire d;

        if (USE_IDELAY) begin

            IDELAYE2 # (
                .IDELAY_TYPE    ("FIXED"),
                .DELAY_SRC      ("IDATAIN"),
                .IDELAY_VALUE   (16)
            ) an_idelay (
                .IDATAIN        (D),
                .DATAOUT        (d)
            );

        end else begin
            assign d = D;

        end

        IDDR_2CLK # (
            .SRTYPE         (SRTYPE),
            .INIT_Q1        (INIT_Q1),
            .INIT_Q2        (INIT_Q2),
            .DDR_CLK_EDGE   (DDR_CLK_EDGE)

        ) the_iddr (
            .C              (C),
            .CB             (CB),
            .CE             (CE),
            .S              (S),
            .R              (R),
            .D              (d),
            .Q1             (Q1),
            .Q2             (Q2)
        );

    end endgenerate

endmodule
