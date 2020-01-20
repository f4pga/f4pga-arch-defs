module top (
    input  wire clk,

    input  wire rx,
    output wire tx,

    input  wire [15:0] sw,
    output wire [15:0] led
);
    RAM32M #(
        .INIT_A(64'b10),
        .INIT_B(64'b100),
        .INIT_C(64'b1000),
        .INIT_D(64'b10000)
    ) ram0 (
        .WCLK   (clk),
        .ADDRA  (sw[4:0]),
        .ADDRB  (sw[4:0]),
        .ADDRC  (sw[4:0]),
        .ADDRD  (sw[9:5]),
        .DIA    (sw[11:10]),
        .DIB    (sw[11:10]),
        .DIC    (sw[13:12]),
        .DID    (sw[15:14]),
        .DOA    (led[1:0]),
        .DOB    (led[3:2]),
        .DOC    (led[5:4]),
        .DOD    (led[7:6]),
        .WE     (sw[15])
    );

    assign led[15:8] = sw[15:8];
    assign tx = rx;

endmodule
