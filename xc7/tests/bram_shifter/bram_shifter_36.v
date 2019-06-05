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
    wire [35:0]       ram_out;
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

    RAMB36E1 #(
        .RAM_MODE("TDP"),  // True dual-port mode (2x2 in/out ports)
        .READ_WIDTH_A(36),
        .WRITE_WIDTH_B(36),
        .WRITE_MODE_B("WRITE_FIRST")  // transparent write
    ) ram (
        // read from A
        .CLKARDCLK(clk),  // shared clock
        .ENARDEN(1'b1),   // enable read
        .REGCEAREGCE(1'b0),    // disable clock to the output register (not using it)
        .RSTRAMARSTRAM(1'b0),  // don't reset output latch
        .RSTREGARSTREG(1'b0),  // don't reset output register
        .ADDRARDADDR({~sw[0], addr, 5'b0}),  // use upper 10 bits, lower 5 are zero
        .WEA(4'h0),  // disable writing from this half
        .DIADI(32'h0000_0000),  // no input
        .DIPADIP(4'h0),         // no input
        .DOADO(ram_out[31:0]),    // 32 bit output
        .DOPADOP(ram_out[35:32]), // 4 more output bits

        // write to B
        .CLKBWRCLK(clk),  // shared clock
        .ENBWREN(1'b1),   // enable write
        .REGCEB(1'b0),    // disable clock to the output register (no output)
        .RSTRAMB(1'b0),   // don't reset the output latch
        .RSTREGB(1'b0),   // don't reset the output register
        .ADDRBWRADDR({sw[0], addr, 5'b0}),  // use upper 10 bits, lower 5 are zero
        .DIBDI({32{ram_in}}),   // 32 bit input
        .DIPBDIP({4{ram_in}}),  // 4 more input bits
        .WEBWE(8'h0f)  // enable writing all 4 bytes-wide (32 bits)
    );
endmodule
