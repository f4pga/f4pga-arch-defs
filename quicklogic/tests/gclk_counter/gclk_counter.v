module top(
    input  wire [1:0] clk,
    output wire [3:0] led
);

    // Clock pads
    wire [1:0] pclk;

    ckpad pad0 (
        .P(clk[0]),
        .Q(pclk[0]),
    );
    ckpad pad1 (
        .P(clk[1]),
        .Q(pclk[1]),
    );

    // Manual GMUXes for IPs
    wire [1:0] gclk;

    GMUX_IP gmux0 (
        .IP  (pclk[0]),
        .IC  (1'b0),
        .IS0 (1'b0), // Select the CLOCK pad
        .IZ  (gclk[0])
    );
    GMUX_IP gmux1 (
        .IP  (pclk[1]),
        .IC  (1'b0),
        .IS0 (1'b0), // Select the CLOCK pad
        .IZ  (gclk[1])
    );

    // Counters
    reg [23:0] cnt0;
    initial cnt0 <= 0;
    always @(posedge gclk[0])
        cnt0 <= cnt0 + 1;

    reg [23:0] cnt1;
    initial cnt1 <= 0;
    always @(posedge gclk[1])
        cnt1 <= cnt1 + 1;

    // Outputs
    assign led[0] = cnt0[23];
    assign led[1] = cnt0[24];

    assign led[2] = cnt1[23];
    assign led[3] = cnt1[24];

endmodule
