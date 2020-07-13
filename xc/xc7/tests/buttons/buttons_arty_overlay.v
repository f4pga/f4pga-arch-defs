module top (
    input  wire clk,

    input  wire [7:0] sw,
    output wire [7:0] sw_pr1,
    output wire [7:0] led,
    input wire [7:0] led_pr1
);
    assign led = led_pr1;
    assign sw_pr1 = sw;
endmodule
