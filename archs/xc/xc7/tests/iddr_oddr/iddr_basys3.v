module top (
    input  wire i_clk,
    input  wire i_clkb,

    input  wire i_rst,
    input  wire i_ce,

    output wire o_q1,
    output wire o_q2,

    input  wire [11:0] io
);

    // BUFGs
    wire clk;
    wire clkb;

    BUFG bufg_1 (.I(i_clk),  .O(clk));
    BUFG bufg_2 (.I(i_clkb), .O(clkb));

    // Generate IDDR cases

    wire [11:0] q1;
    wire [11:0] q2;

    assign o_q1 = |q1;
    assign o_q2 = |q2;

    genvar sa, e, i, sr, inv;
    generate begin
        // SRTYPE
        for (sa = 0; sa < 2; sa = sa + 1) begin
            localparam SRTYPE = (sa != 0) ? "SYNC" : "ASYNC";
            localparam sa_idx = sa;

            IDDR_2CLK # (
              .SRTYPE(SRTYPE)
            ) iddr_sr_type (
              .C(clk), .CB(clkb), .CE(i_ce), .Q1(q1[sa_idx]), .Q2(q2[sa_idx]),
              .D(io[sa_idx])
            );

        end

        // DDR_CLK_EDGE
        for (e = 0; e < 3; e = e + 1) begin
            localparam EDGE = (e == 0) ?   "SAME_EDGE" :
                              (e == 1) ?   "SAME_EDGE_PIPELINED" :
                            /*(e == 2) ?*/ "OPPOSITE_EDGE";
            localparam e_idx = 2 + e;

            IDDR_2CLK # (
              .DDR_CLK_EDGE(EDGE)
            ) iddr_edge (
              .C(clk), .CB(clkb), .CE(i_ce), .Q1(q1[e_idx]), .Q2(q2[e_idx]),
              .D(io[e_idx])
            );

        end

        // Set, Reset or neither
        for (sr = 0; sr < 3; sr = sr + 1) begin
            localparam sr_idx = 5 + sr;

            wire r;
            wire s;

            assign r = ((sr & 1) != 0) ? i_rst : 1'b0;
            assign s = ((sr & 2) != 0) ? i_rst : 1'b0;

            IDDR_2CLK iddr_sr (
              .C(clk), .CB(clkb), .CE(i_ce), .Q1(q1[sr_idx]), .Q2(q2[sr_idx]),
              .R(r), .S(s),
              .D(io[sr_idx])
            );

        end

        // INIT_Q1, INIT_Q2
        for (i = 0; i < 2; i = i + 1) begin
            localparam i_idx = 8 + i;
            IDDR_2CLK # (
              .INIT_Q1(i == 1),
              .INIT_Q2(i != 1)
            ) iddr_init (
              .C(clk), .CB(clkb), .CE(i_ce), .Q1(q1[i_idx]), .Q2(q2[i_idx]),
              .D(io[i_idx])
            );

        end

        // Inverted D
        for (inv = 0; inv < 2; inv = inv + 1) begin
            localparam inv_idx = 10 + inv;

            IDDR_2CLK # (
                .IS_D_INVERTED(inv != 0)
            ) iddr_inverted (
              .C(clk), .CB(clkb), .CE(i_ce), .Q1(q1[inv_idx]), .Q2(q2[inv_idx]),
              .D(io[inv_idx])
            );

        end
    end endgenerate
endmodule
