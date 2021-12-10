module top (
    (* clkbuf_inhibit *)
    input  wire       CLK,
    (* clkbuf_inhibit *)
    input  wire       RST,
    input  wire [1:0] DIN,
    output wire [1:0] DOUT
);

    reg [8:0] addr;

    always @(posedge CLK or posedge RST)
        if (RST)    addr <= 0;
        else        addr <= addr + 1;

    // RAM0
    wire [35:0] rdat0;
    wire [35:0] wdat0;

    assign wdat0   = {36{DIN[0]}};
    assign DOUT[0] = |rdat0;

    qlal3_ram_512x36_cell ram0 (
        .RAM_ADDR       (addr),
        .RAM_CLK        (CLK),
        .RAM_CLKS       (1'b1),
        .RAM_RD_DATA    (rdat0),
        .RAM_RD_EN      (1'b1),
        .RAM_RME_af     (),
        .RAM_RM_af      (),
        .RAM_TEST1_af   (),
        .RAM_WR_BE      (4'hF),
        .RAM_WR_DATA    (wdat0),
        .RAM_WR_EN      (1'b1)
    );

    // RAM1
    wire [35:0] rdat1;
    wire [35:0] wdat1;

    assign wdat1   = {36{DIN[1]}};
    assign DOUT[1] = |rdat1;

    qlal3_ram_512x36_cell ram1 (
        .RAM_ADDR       (addr),
        .RAM_CLK        (CLK),
        .RAM_CLKS       (1'b1),
        .RAM_RD_DATA    (rdat1),
        .RAM_RD_EN      (1'b1),
        .RAM_RME_af     (),
        .RAM_RM_af      (),
        .RAM_TEST1_af   (),
        .RAM_WR_BE      (4'hF),
        .RAM_WR_DATA    (wdat1),
        .RAM_WR_EN      (1'b1)
    );

endmodule
