module top (
    input  clk,
    input rx,
    output tx
);
    reg nrst = 0;
    wire tx_baud_edge;
    wire rx_baud_edge;

    // Data in.
    wire [7:0] rx_data_wire;
    wire rx_data_ready_wire;

    // Data out.
    reg tx_data_ready;
    wire tx_data_accepted;
    reg [7:0] tx_data;

    assign leds = rx_data;

    UART #(
        .COUNTER(25),
        .OVERSAMPLE(8)
    ) uart (
        .clk(clk),
        .rst(!nrst),
        .rx(rx),
        .tx(tx),
        .tx_data_ready(tx_data_ready),
        .tx_data(tx_data),
        .tx_data_accepted(tx_data_accepted),
        .rx_data(rx_data_wire),
        .rx_data_ready(rx_data_ready_wire)
    );

    always @(posedge clk) begin
        nrst <= 1;
        if(!nrst) begin
            tx_data_ready <= 0;
        end else begin
            if (rx_data_ready_wire) begin
                if(!tx_data_ready) begin
                    tx_data <= rx_data_wire;
                    tx_data_ready <= 1;
                end
            end

            if (tx_data_accepted) begin
                tx_data_ready <= 0;
            end
        end
    end
endmodule
