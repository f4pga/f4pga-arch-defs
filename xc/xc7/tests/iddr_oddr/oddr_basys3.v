module top (
    input  wire i_clk,

    input  wire i_rst,
    input  wire i_ce,

    input  wire i_d1,
    input  wire i_d2,

    output wire [14:0] io
);

    // BUFGs
    wire clk;

    BUFG bufg_1 (.I(i_clk),  .O(clk));

    genvar sa, e, i, sr, inv;
    generate begin
        // SRTYPE
        for (sa = 0; sa < 2; sa = sa + 1) begin
            localparam SRTYPE = (sa != 0) ? "SYNC" : "ASYNC";
            localparam sa_idx = sa;

            ODDR # (
              .SRTYPE       (SRTYPE)
            ) oddr_sr_type (
              .C(clk), .CE(i_ce), .D1(i_d1), .D2(i_d2),
              .Q(io[sa_idx])
            );
        end

        // DDR_CLK_EDGE
        for (e = 0; e < 2; e = e + 1) begin
            localparam EDGE = (e == 0) ?   "SAME_EDGE" :
                            /*(e == 1) ?*/ "OPPOSITE_EDGE";
            localparam e_idx = 2 + e;

            ODDR # (
              .DDR_CLK_EDGE (EDGE)
            ) oddr_edge (
              .C(clk), .CE(i_ce), .D1(i_d1), .D2(i_d2),
              .Q(io[e_idx])
            );
        end

        // Set, Reset or neither
        for (sr = 0; sr < 3; sr = sr + 1) begin
            localparam sr_idx = 4 + sr;

            wire r;
            wire s;

            assign r = ((sr & 1) != 0) ? i_rst : 1'b0;
            assign s = ((sr & 2) != 0) ? i_rst : 1'b0;

            ODDR oddr_sr (
              .C(clk), .CE(i_ce), .D1(i_d1), .D2(i_d2),
              .R(r), .S(s),
              .Q(io[sr_idx])
            );
        end

        // INIT_Q1, INIT_Q2
        for (i = 0; i < 2; i = i + 1) begin
            localparam i_idx = 7 + i;

            ODDR # (
              .INIT         (i == 1)
            ) oddr_init (
              .C(clk), .CE(i_ce), .D1(i_d1), .D2(i_d2),
              .Q(io[i_idx])
            );
        end

        // Inverted D
        for (inv = 0; inv < 6; inv = inv + 1) begin
            localparam inv_idx = 9 + inv;

            wire d1 = (inv / 2 == 0) ? i_d1 :
                      (inv / 2 == 1) ? 1'b1 :
                    /*(inv / 2 == 2)*/ 1'b0;

            wire d2 = (inv / 2 == 0) ? i_d2 :
                      (inv / 2 == 1) ? 1'b1 :
                    /*(inv / 2 == 2)*/ 1'b0;

            ODDR # (
                .IS_D1_INVERTED(inv % 2 != 0),
                .IS_D2_INVERTED(inv % 2 != 0)
            ) oddr_inverted (
              .C(clk), .CE(i_ce), .D1(d1), .D2(d2),
              .Q(io[inv_idx])
            );
        end

    end endgenerate

endmodule
