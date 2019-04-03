module SATURATING_COUNTER(
    input clk,
    input rst,
    output [COUNTER_WIDTH-1:0] count,
    output reg saturated
);

parameter MAX_COUNT = 15;
parameter COUNTER_WIDTH = 4;

reg [COUNTER_WIDTH-1:0] counter = 0;

assign count = counter;
initial begin
    saturated <= 0;
end

always @(posedge clk) begin
    if(rst) begin
        counter <= 0;
        saturated <= 0;
    end else begin
        if(counter == MAX_COUNT) begin
            saturated <= 1;
            counter <= counter;
        end else begin
            saturated <= 0;
            counter <= counter + 1;
        end
    end
end

endmodule
