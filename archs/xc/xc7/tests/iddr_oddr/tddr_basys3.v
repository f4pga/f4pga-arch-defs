module top (
    input  wire i_clk,

    input  wire i_rst,
    input  wire i_ce,

    input  wire i_d1,
    input  wire i_d2,

    output wire [23:0] io,
);

    // BUFGs
    wire clk;

    BUFG bufg_1 (.I(i_clk),  .O(clk));

    genvar sa, e, i, sr;
    generate begin

        // SRTYPE
        for (sa=0; sa<2; sa=sa+1) begin
            localparam SRTYPE = (sa != 0) ? "SYNC" : "ASYNC";

            // DDR_CLK_EDGE
            for (e=0; e<2; e=e+1) begin
                localparam EDGE = (e == 0) ?   "SAME_EDGE" :
                                /*(e == 1) ?*/ "OPPOSITE_EDGE";

                // Set, Reset or neither
                for (sr=0; sr<3; sr=sr+1) begin
                    wire r;
                    wire s;

                    assign r = ((sr & 1) != 0) ? i_rst : 1'b0;
                    assign s = ((sr & 2) != 0) ? i_rst : 1'b0;

                    // INIT_Q
                    for (i=0; i<2; i=i+1) begin
                        localparam idx = sa*12 + e*6 + sr*2 + i;

                        wire [0:0] t;
                        wire [0:0] i_sig;

                        ODDR # (
                          .SRTYPE       (SRTYPE),
                          .INIT         (i == 1),
                          .DDR_CLK_EDGE (EDGE)
                        ) tddr (
                          .C(clk), .CE(i_ce), .D1(i_d1), .D2(i_d2),
                          .R(r), .S(s),
                          .Q(t)
                        );

                        ODDR # (
                          .SRTYPE       (SRTYPE),
                          .INIT         (i == 1),
                          .DDR_CLK_EDGE (EDGE)
                        ) oddr (
                          .C(clk), .CE(i_ce), .D1(i_d1), .D2(i_d2),
                          .R(r), .S(s),
                          .Q(i_sig)
                        );

                        // Cannot instance OBUFT because Yosys infers IOBs and
                        // inserts an inferred OBUF after the OBUFT...
                        assign io[idx] = (t == 1'b0) ? i_sig : 1'bz;
                    end
                 end
            end
        end
    end endgenerate

endmodule
