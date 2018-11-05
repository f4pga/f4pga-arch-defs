module BAUDGEN(
    input clk,
    input rst,
    output baud_edge
);
    parameter COUNTER = 200;

    reg [$clog2(COUNTER)-1:0] counter = 0;

    reg baud_edge_reg;
    assign baud_edge = baud_edge_reg;

    always @(posedge clk) begin
        if(rst) begin
            counter <= 0;
            baud_edge_reg <= 0;
        end else begin
            if(counter == COUNTER-1) begin
                baud_edge_reg <= 1;
                counter <= 0;
            end else begin
                baud_edge_reg <= 0;
                counter <= counter + 1;
            end
        end
    end
endmodule
