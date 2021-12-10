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

    // RAM2
    wire [31:0] rdat0;
    wire [31:0] wdat0;

    assign wdat0   = {32{DIN[0]}};
    assign DOUT[0] = |rdat0;

    qlal3_ram_512x32_cell ram2 (
        .RAM_P0_ADDR    (addr),
        .RAM_P0_CLK     (CLK),
        .RAM_P0_CLKS    (1'b1),
        .RAM_P0_WR_BE   (4'hF),
        .RAM_P0_WR_DATA (wdat0),
        .RAM_P0_WR_EN   (1'b1),
        .RAM_P1_ADDR    (addr),
        .RAM_P1_CLK     (CLK),
        .RAM_P1_CLKS    (1'b1),
        .RAM_P1_RD_DATA (rdat0),
        .RAM_P1_RD_EN   (1'b1),
        .RAM_RME_af     (),
        .RAM_RM_af      (),
        .RAM_TEST1_af   ()
    );

    // RAM3
    wire [31:0] rdat1;
    wire [31:0] wdat1;

    assign wdat1   = {32{DIN[1]}};
    assign DOUT[1] = |rdat1;

    qlal3_ram_512x32_cell ram3 (
        .RAM_P0_ADDR    (addr),
        .RAM_P0_CLK     (CLK),
        .RAM_P0_CLKS    (1'b1),
        .RAM_P0_WR_BE   (4'hF),
        .RAM_P0_WR_DATA (wdat0),
        .RAM_P0_WR_EN   (1'b1),
        .RAM_P1_ADDR    (addr),
        .RAM_P1_CLK     (CLK),
        .RAM_P1_CLKS    (1'b1),
        .RAM_P1_RD_DATA (rdat0),
        .RAM_P1_RD_EN   (1'b1),
        .RAM_RME_af     (),
        .RAM_RM_af      (),
        .RAM_TEST1_af   ()
    );

endmodule
