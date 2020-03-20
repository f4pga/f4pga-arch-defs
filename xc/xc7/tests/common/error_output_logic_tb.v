`timescale 1ns/1ps
`default_nettype none

`ifndef VCDFILE
`define VCDFILE "testbench_error_output_logic_tb.vcd"
`endif

module test;

`include "../../../../library/tbassert.v"

localparam ADDR_WIDTH = 10;
localparam DATA_WIDTH = 1;

reg [0:0] rst = 1'b0;
reg [0:0] clk = 1'b0;

reg [0:0] loop_complete = 1'b0;
reg [0:0] error_detected = 1'b0;
reg [7:0] error_state = 8'b0;
reg [ADDR_WIDTH-1:0] error_address = {ADDR_WIDTH{1'b0}};
reg [DATA_WIDTH-1:0] expected_data = {DATA_WIDTH{1'b0}};

// Output to UART
reg [0:0] tx_data_accepted = 1'b0;
wire [0:0] tx_data_ready;
wire [7:0] tx_data;

// clock generation
always #1 clk=~clk;

wire [15:0] sw;
wire [15:0] led;
wire tx;
wire rx;

assign sw[0] = rst;
assign sw[1] = loop_complete;
assign sw[2] = error_detected;
assign sw[4:3] = error_state[1:0];
assign sw[14:5] = error_address;
assign sw[15] = expected_data;
assign rx = tx_data_accepted;

assign tx_data = led[7:0];
assign tx_data_ready = led[8];

top unt(
    .clk(clk),
    .rx(rx),
    .tx(tx),
    .sw(sw),
    .led(led)
);

initial begin
    $dumpfile(`VCDFILE);
    $dumpvars;
#1.1 // 1
    tbassert(clk, "Clock!");
    tbassert(!tx_data_ready, "No data");
#1 // 2
    tbassert(!clk, "Clock!");
    tbassert(!tx_data_ready, "No data");
    rst = 1;
#1 // 3
    tbassert(clk, "Clock!");
    tbassert(!tx_data_ready, "No data");
#1 // 4
    tbassert(!clk, "Clock!");
    tbassert(!tx_data_ready, "No data");
    rst = 0;
#1 // 5
    tbassert(clk, "Clock!");
    tbassert(!tx_data_ready, "No data");
#1 // 6 : Test simple output
    tbassert(!clk, "Clock!");
    tbassert(!tx_data_ready, "No data");
    loop_complete = 1;
#2 // 8
    loop_complete = 0;
#3 // 11
    tbassert(clk, "Clock!");
    tbassert(tx_data_ready, "Data!");
    tbassert(tx_data == "L", "Check data value!");
#1 // 12
    tbassert(!clk, "Clock!");
    loop_complete = 0;
    tx_data_accepted = 1;
#1 // 13
    tbassert(clk, "Clock!");
    tbassert(!tx_data_ready, "No data");
#1 // 14
    tbassert(!clk, "Clock!");
#1 // 15
    tbassert(clk, "Clock!");
    tbassert(tx_data_ready, "Data!");
    tbassert(tx_data == 8'b0, "Check data value!");
#4 // 19
    tbassert(clk, "Clock!");
    tbassert(tx_data_ready, "Data!");
    tbassert(tx_data == 8'b0, "Check data value!");
#4 // 23
    tbassert(clk, "Clock!");
    tbassert(tx_data_ready, "Data!");
    tbassert(tx_data == 8'b0, "Check data value!");
#4 // 27
    tbassert(clk, "Clock!");
    tbassert(tx_data_ready, "Data!");
    tbassert(tx_data == 8'h0D, "Check data value!");
#4 // 31
    tbassert(clk, "Clock!");
    tbassert(tx_data_ready, "Data!");
    tbassert(tx_data == 8'h0A, "Check data value!");
#3 // 34 : Check no extra data
    tbassert(!clk, "Clock!");
    tbassert(!tx_data_ready, "No data");
#1 // 35
    tbassert(clk, "Clock!");
    tbassert(!tx_data_ready, "No data");
#1 // 36
    tbassert(!clk, "Clock!");
    tbassert(!tx_data_ready, "No data");
#1 // 37
    tbassert(clk, "Clock!");
    tbassert(!tx_data_ready, "No data");
#1 // 38
    tbassert(!clk, "Clock!");
    error_detected = 1;
    error_state = 8'b10;
    error_address = 10'h3EF;
    expected_data = 1;
#2 // 39
    error_detected = 0;
#3 // 39
    tbassert(clk, "Clock!");
    tbassert(tx_data_ready, "Data!");
    tbassert(tx_data == "E", "Check data value!");
#4 // 43
    tbassert(clk, "Clock!");
    tbassert(tx_data_ready, "Data!");
    tbassert(tx_data == 8'b10, "Check error state!");
#4 // 47
    tbassert(clk, "Clock!");
    tbassert(tx_data_ready, "Data!");
    tbassert(tx_data == 8'hEF, "Check addr[0] state!");
#4 // 51
    tbassert(clk, "Clock!");
    tbassert(tx_data_ready, "Data!");
    tbassert(tx_data == 8'h03, "Check addr[1] state!");
#4 // 55
    tbassert(clk, "Clock!");
    tbassert(tx_data_ready, "Data!");
    tbassert(tx_data == 8'b1, "Check expected data[0] state!");
#4 // 59
    tbassert(clk, "Clock!");
    tbassert(tx_data_ready, "Data!");
    tbassert(tx_data == 8'b0, "Check actual data[0] state!");
#4 // 63
    tbassert(clk, "Clock!");
    tbassert(tx_data_ready, "Data!");
    tbassert(tx_data == 8'h0D, "Check data value!");
#4 // 67
    tbassert(clk, "Clock!");
    tbassert(tx_data_ready, "Data!");
    tbassert(tx_data == 8'h0A, "Check data value!");
#3 // 70 : Check no extra data
    tbassert(!clk, "Clock!");
    tbassert(!tx_data_ready, "No data");
#1 // 71
    tbassert(clk, "Clock!");
    tbassert(!tx_data_ready, "No data");
#1 // 72
    tbassert(!clk, "Clock!");
    tbassert(!tx_data_ready, "No data");
#1 // 73
    tbassert(clk, "Clock!");
    tbassert(!tx_data_ready, "No data");
#1  $finish;
end

endmodule
