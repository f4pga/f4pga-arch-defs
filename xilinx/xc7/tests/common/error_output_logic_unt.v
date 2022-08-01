// Until the ROI is removed, using the common basys3 structure is the easiest 
// way to test post-PnR designs.
// One the ROI is removed, any top level can be used, and only the clk pin
// need be set during placement.
module top (
    input clk,
    input rx,
    output tx,
    input [15:0] sw,
    output [15:0] led
);

ERROR_OUTPUT_LOGIC #(
    .ADDR_WIDTH(10),
    .DATA_WIDTH(1)
) unt (
    .rst(sw[0]),
    .clk(clk),
    .loop_complete(sw[1]),
    .error_detected(sw[2]),
    .error_state(sw[4:3]),
    .error_address(sw[14:5]),
    .expected_data(sw[15]),
    .actual_data({1'b0}),
    .tx_data_accepted(rx),
    .tx_data_ready(led[8]),
    .tx_data(led[7:0])
);

assign led[15:9] = sw[15:9];
assign tx = sw[0];

endmodule
