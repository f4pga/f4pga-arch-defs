`timescale 1ns/1ps
`default_nettype none
module test;

localparam NUM_FF = 4;

task tbassert(input a, input reg [512:0] s);
begin
    if (a==0) begin
        $display("ASSERT FAILURE: %-s", s);
        $finish
    end
end
endtask


reg clk = 0;
reg rx = 1;
reg [15:0] sw = 0;

wire tx;
wire [15:0] led;


// clock generation
always #1 clk=~clk;

top (
    .clk(clk),
    .rx(rx),
    .tx(tx),
    .sw(sw),
    .led(led)
);

initial begin
#1.1
    tbassert(0, "Test")
#1  $finish;
end

endmodule
