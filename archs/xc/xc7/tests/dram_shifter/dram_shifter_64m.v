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
    wire [1:0]        ram_out;
    wire [1:0]        ram_in;

    assign ram_in[1] = 1'b1;

    RAM_SHIFTER #(
        .IO_WIDTH(16),
        .ADDR_WIDTH(6)
    ) shifter (
        .clk(clk),
        .in(sw),
        .out(led),
        .addr(addr),
        .ram_out(ram_out[0]),
        .ram_in(ram_in[0])
    );

    RAM64M ram0 (
        .WCLK(clk),
        .ADDRD(addr),
        .DOD(ram_out),
        .DID(ram_in),
        .WE(1'b1)
    );
endmodule
