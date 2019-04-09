module top(
    input clk,
    input rx,
    output tx,
    input [15:0] sw,
    output [15:0] led
);

assign tx = rx;

// Generate some signals for the CE and reset lines.
wire ce = ^sw;
wire reset = &sw;

// 4 FF's of each SR/CE varient to check packing behavior.
generate for(i = 0; i < 3; i++) begin:ff
    // Tie SR to GND and CE to VCC
    FDRE #(
        .INIT(0),
    ) vcc_gnd (
        .Q(led[4*i+0]),
        .C(clk),
        .D(sw[4*i+0]),
        .CE(1),
        .R(0)
    );

    // Tie SR to GND and CE to signal
    FDRE #(
        .INIT(0),
    ) s_gnd (
        .Q(led[4*i+1]),
        .C(clk),
        .D(sw[4*i+1]),
        .CE(ce),
        .R(0)
    );

    // Tie SR to signal and CE to signal
    FDRE #(
        .INIT(0),
    ) s_s (
        .Q(led[4*i+2]),
        .C(clk),
        .D(sw[4*i+2]),
        .CE(ce),
        .R(reset)
    );

    // Tie SR to signal and CE to VCC
    FDRE #(
        .INIT(0),
    ) vcc_s (
        .Q(led[4*i+3]),
        .C(clk),
        .D(sw[4*i+3]),
        .CE(1),
        .R(reset)
    );
end generate

endmodule
