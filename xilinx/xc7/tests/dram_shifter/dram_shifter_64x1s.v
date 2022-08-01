// Double buffering with dual-port RAM
// Uses single-port RAM to write switches to a section while reading from the same section to control LEDs,
// so each switch acts as if connected directly to the corresponding LED.
// Flip SW0 to change sections.
module top (
        input         clk,
        input [15:0]  sw,
        output [15:0] led,

        // not used
        input         rx,
        output        tx
);

    assign tx = rx;  // TODO(#658): Remove this work-around

    wire [4:0]        addr;
    wire              ram_out;
    wire              ram_in;

    RAM_SHIFTER #(
        .IO_WIDTH(16),
        .ADDR_WIDTH(5)
    ) shifter (
        .clk(clk),
        .in(sw),
        .out(led),
        .addr(addr),
        .ram_out(ram_out),
        .ram_in(ram_in)
    );

    RAM64X1S #(
        .INIT(64'h96A5_96A5_96A5_96A5)
    ) ram0 (
        .WCLK(clk),
        .A5(sw[0]),
        .A4(addr[4]),
        .A3(addr[3]),
        .A2(addr[2]),
        .A1(addr[1]),
        .A0(addr[0]),
        .O(ram_out),
        .D(ram_in),
        .WE(1'b1)
    );
endmodule
