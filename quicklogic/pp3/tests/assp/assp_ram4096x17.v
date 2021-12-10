module top (
    (* clkbuf_inhibit *)
    input  wire CLK,
    (* clkbuf_inhibit *)
    input  wire RST,
    input  wire DIN,
    output wire DOUT
);

    reg [11:0] addr;

    always @(posedge CLK or posedge RST)
        if (RST)    addr <= 0;
        else        addr <= addr + 1;

    // RAM8k
    wire [17:0] rdat;
    wire [17:0] wdat;

    assign wdat = {18{DIN}};
    assign DOUT = |rdat;

    qlal3_ram_4096x17_cell ram8k (
        .RAM_P0_ADDR             (addr),
        .RAM_P0_CLK              (CLK),
        .RAM_P0_CLKS             (1'b1),
        .RAM_P0_WR_BE            (2'b11),
        .RAM_P0_WR_DATA          (wdat),
        .RAM_P0_WR_EN            (1'b1),
        .RAM_P1_ADDR             (addr),
        .RAM_P1_CLK              (CLK),
        .RAM_P1_CLKS             (1'b1),
        .RAM_P1_RD_DATA          (rdat),
        .RAM_P1_RD_EN            (1'b1),
        .RAM_P1_mux              (1'b1),
        .RAM_RME_af              (),
        .RAM_RM_af               (),
        .RAM_TEST1_af            (),
        .RAM_fifo_almost_empty   (),
        .RAM_fifo_almost_full    (),
        .RAM_fifo_empty_flag     (),
        .RAM_fifo_en             (1'b0),
        .RAM_fifo_full_flag      ()
    );

endmodule
