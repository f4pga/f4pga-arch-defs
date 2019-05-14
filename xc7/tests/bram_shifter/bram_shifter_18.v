module top (
        input         clk,
        input [15:0]  sw,
        output [15:0] led,

        // not used
        input         rx,
        output        tx
);

    assign tx = rx;  // TODO(#658): Remove this work-around

    wire [8:0]        addr;
    wire [17:0]       ram_out;
    wire              ram_in;

    RAM_SHIFTER #(
        .IO_WIDTH(16),
        .ADDR_WIDTH(9),
        .PHASE_SHIFT(3)
    ) shifter (
        .clk(clk),
        .in(sw),
        .out(led),
        .addr(addr),
        .ram_out(| ram_out),
        .ram_in(ram_in)
    );

    RAMB18E1 #(
        .RAM_MODE("TDP"),  // True dual-port mode (2x2 in/out ports)
        .READ_WIDTH_A(18),
        .WRITE_WIDTH_B(18),
        .WRITE_MODE_B("WRITE_FIRST")  // transparent write
    ) ram (
        // read from A
        .CLKARDCLK(clk),  // shared clock
        .ENARDEN(1'b1),   // enable read
        .REGCEAREGCE(1'b0),    // disable clock to the output register (not using it)
        .RSTRAMARSTRAM(1'b0),  // don't reset output latch
        .RSTREGARSTREG(1'b0),  // don't reset output register
        .ADDRARDADDR({~sw[0], addr, 4'b0}),  // use upper 10 bits, lower 4 are zero
        .WEA(4'h0),  // disable writing from this half
        .DIADI(16'h0000),  // no input
        .DIPADIP(2'h0),    // no input
        .DOADO(ram_out[15:0]),    // 16 bit output
        .DOPADOP(ram_out[17:16]), // 2 more output bits

        // write to B
        .CLKBWRCLK(clk),  // shared clock
        .ENBWREN(1'b1),   // enable write
        .REGCEB(1'b0),    // disable clock to the output register (no output)
        .RSTRAMB(1'b0),   // don't reset the output latch
        .RSTREGB(1'b0),   // don't reset the output register
        .ADDRBWRADDR({sw[0], addr, 4'b0}),  // use upper 10 bits, lower 4 are zero
        .DIBDI({16{ram_in}}),   // 16 bit input
        .DIPBDIP({2{ram_in}}),  // 2 more input bits
        .WEBWE(8'h03)  // enable writing all 2 bytes-wide (16 bits)
    );
endmodule
