module oddr_wrapper (
    input  wire C,
    input  wire OCE,
    input  wire S,
    input  wire R,
    input  wire D1,
    input  wire D2,
    output wire OQ
);
    parameter USE_PHY_ODDR  = 0;
    parameter SRTYPE        = "SYNC";
    parameter INIT          = 0;
    parameter DDR_CLK_EDGE  = "OPPOSITE_EDGE";

    // Use a physical ODDR block
    generate if (USE_PHY_ODDR != 0) begin

        ODDR # (
            .SRTYPE         (SRTYPE),
            .INIT           (INIT),
            .DDR_CLK_EDGE   (DDR_CLK_EDGE)

        ) the_oddr (
            .C              (C),
            .CE             (OCE),
            .S              (S),
            .R              (R),
            .D1             (D1),
            .D2             (D2),
            .Q              (OQ)
        );

    // Simulate ODDR behavior using logic
    // TODO: Reset/Set SYNC/ASYNC
    end else begin

        reg q1;
        reg q2;

        initial q1 <= INIT;
        initial q2 <= INIT;

        // OPPOSITE_EDGE
        if(DDR_CLK_EDGE == "OPPOSITE_EDGE") begin

            always @(posedge C)
                if (OCE)
                    q1 <= D1;

            always @(negedge C)
                if (OCE)
                    q2 <= D2;

        // SAME_EDGE
        end else if (DDR_CLK_EDGE == "SAME_EDGE" || DDR_CLK_EDGE == "SAME_EDGE_PIPELINED") begin

            always @(posedge C)
                if (OCE)
                    q1 <= D1;

            always @(posedge C)
                if (OCE)
                    q2 <= D2;

        end

        // Use clock as a mux select FIXME: This shouldn't be done this way!
        assign OQ = (C) ? q1 : q2;

    end endgenerate

endmodule
