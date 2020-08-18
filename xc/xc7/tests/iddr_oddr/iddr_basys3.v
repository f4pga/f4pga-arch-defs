module top (
    input  wire i_clk,
    input  wire i_clkb,

    input  wire i_rst,
    input  wire i_ce,

    output wire o_q1,
    output wire o_q2,

    input  wire [35:0] io,
);

    // BUFGs
    wire clk;
    wire clkb;

    BUFG bufg_1 (.I(i_clk),  .O(clk));
    BUFG bufg_2 (.I(i_clkb), .O(clkb));

    wire [35:0] q1;
    wire [35:0] q2;

    assign o_q1 = |q1;
    assign o_q2 = |q2;

    // Generate IDDR cases
    genvar sa, e, i, sr;
    generate begin

        // SRTYPE
        for (sa=0; sa<2; sa=sa+1) begin
            localparam SRTYPE = (sa != 0) ? "SYNC" : "ASYNC";

            // DDR_CLK_EDGE
            for (e=0; e<3; e=e+1) begin
                localparam EDGE = (e == 0) ?   "SAME_EDGE" :
                                  (e == 1) ?   "SAME_EDGE_PIPELINED" :
                                /*(e == 2) ?*/ "OPPOSITE_EDGE";

                // Set, Reset or neither
                for (sr=0; sr<3; sr=sr+1) begin
                    wire r;
                    wire s;

                    assign r = ((sr & 1) != 0) ? i_rst : 1'b0;
                    assign s = ((sr & 2) != 0) ? i_rst : 1'b0;

                    // INIT_Q1, INIT_Q2
                    for (i=0; i<2; i=i+1) begin
                        localparam idx = sa*18 + e*6 + sr*2 + i;

                        IDDR_2CLK # (
                          .SRTYPE       (SRTYPE),
                          .INIT_Q1      (i == 1),
                          .INIT_Q2      (i != 1),
                          .DDR_CLK_EDGE (EDGE)
                        ) iddr (
                          .C(clk), .CB(clkb), .CE(i_ce), .Q1(q1[idx]), .Q2(q2[idx]),
                          .R(r), .S(s),
                          .D(io[idx])
                        );
                    end
                 end
            end
        end
    end endgenerate

endmodule
