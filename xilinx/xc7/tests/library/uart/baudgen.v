// Baudrate generator for asyncronous data transmitters (e.g. UARTs).
module BAUDGEN(
    input clk,
    input rst,
    output reg baud_edge
);
    parameter COUNTER = 200;

    reg [$clog2(COUNTER)-1:0] counter;

    always @(posedge clk) begin
        if(rst) begin
            counter <= 0;
            baud_edge <= 0;
        end else begin
            if(counter == COUNTER-1) begin
                baud_edge <= 1;
                counter <= 0;
            end else begin
                baud_edge <= 0;
                counter <= counter + 1;
            end
        end
    end
endmodule
