// Double buffering with dual-port RAM
// Uses dual-port RAM to write switches to one section, while reading another to control LEDs.
// Flip SW0 to swap the buffers.
module top (
        input         clk,
        input [15:0]  sw,
        output [15:0] led,

        // not used
        input         rx,
        output        tx
);

    assign tx = rx;  // TODO(#658): Remove this work-around

    wire [5:0]        addr;
    wire              ram_out;
    wire              ram_in;

    RAM_SHIFTER #(
        .IO_WIDTH(16),
        .ADDR_WIDTH(6)
    ) shifter (
        .clk(clk),
        .in(sw),
        .out(led),
        .addr(addr),
        .ram_out(ram_out),
        .ram_in(ram_in)
    );

    RAM128X1D #(
        .INIT(128'h96A5_96A5_96A5_96A5_96A5_96A5_96A5_96A5)
    ) ram0 (
        .WCLK(clk),
        .A({sw[0], addr}),
        .DPRA({~sw[0], addr}),
        .DPO(ram_out),
        .D(ram_in),
        .WE(1'b1)
    );
endmodule
