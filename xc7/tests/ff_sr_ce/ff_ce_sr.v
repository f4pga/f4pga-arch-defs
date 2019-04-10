module top(
    input clk,
    input rx,
    output tx,
    input [15:0] sw,
    output [15:0] led
);

localparam NUM_FF = 4;

assign tx = rx;

// Generate some signals for the CE and reset lines.
wire ce = sw[14];
wire reset = sw[15];

wire [(4*NUM_FF)-1:0] Q;
wire [(4*NUM_FF)-1:0] D;

reg rst = 1;

always @(posedge clk) begin
    rst <= 0;
end


assign led[0] = Q[0];
assign led[1] = Q[1];
assign led[2] = Q[2];
assign led[3] = Q[3];
assign led[4] = Q[4];
assign led[5] = Q[4*NUM_FF-4];
assign led[6] = Q[4*NUM_FF-3];
assign led[7] = Q[4*NUM_FF-2];
assign led[8] = Q[4*NUM_FF-1];
assign led[9] = ^Q;
assign led[10] = |Q;
assign led[11] = &Q;
assign led[12] = ^sw;
assign led[13] = |sw;
assign led[14] = &sw;
assign led[15] = sw[15];

genvar i;

// 4 FF's of each SR/CE varient to check packing behavior.
generate for(i = 0; i < NUM_FF; i=i+1) begin:ff
    assign D[4*i+0] = sw[(4*i+0) % 14];
    assign D[4*i+1] = sw[(4*i+1) % 14];
    assign D[4*i+2] = sw[(4*i+2) % 14];
    assign D[4*i+3] = sw[(4*i+3) % 14];

    // Tie SR to GND and CE to VCC
    (* keep *) FDRE #(
        .INIT(1'b0)
    ) vcc_gnd (
        .Q(Q[4*i+0]),
        .C(clk),
        .D(D[4*i+0]),
        .CE(1'b1),
        .R(1'b0)
    );

    // Tie SR to GND and CE to signal
    (* keep *) FDRE #(
        .INIT(1'b0)
    ) s_gnd (
        .Q(Q[4*i+1]),
        .C(clk),
        .D(D[4*i+1]),
        .CE(ce),
        .R(1'b0)
    );

    // Tie SR to signal and CE to signal
    (* keep *) FDRE #(
        .INIT(1'b0)
    ) s_s (
        .Q(Q[4*i+2]),
        .C(clk),
        .D(D[4*i+2]),
        .CE(ce),
        .R(reset)
    );

    // Tie SR to signal and CE to VCC
    (* keep *) FDRE #(
        .INIT(0)
    ) vcc_s (
        .Q(Q[4*i+3]),
        .C(clk),
        .D(D[4*i+3]),
        .CE(1'b1),
        .R(reset)
    );
end endgenerate

endmodule
