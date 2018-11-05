module top (
    input  clk,
    input rx,
    output tx
);
    reg nrst = 0;
    wire tx_baud_edge;
    wire rx_baud_edge;

    wire [7:0] rx_data_wire;
    wire data_ready_wire;
    reg data_ready;
    wire data_accepted;
    reg [7:0] data;

    assign leds = rx_data;

    // COUNTER == 200 for a 100 MHz is a 500000 BAUD.
    BAUDGEN #(.COUNTER(200)) tx_baud (
        .clk(clk),
        .rst(!nrst),
        .baud_edge(tx_baud_edge)
    );

    UART_TX tx_gen(
        .rst(!nrst),
        .clk(clk),
        .baud_edge(tx_baud_edge),
        .data_ready(data_ready),
        .data(data),
        .tx(tx),
        .data_accepted(data_accepted)
    );


    // COUNTER == 25 for 100 Mhz is a 500000 BAUD at 8x oversample.
    BAUDGEN #(.COUNTER(25)) rx_baud (
        .clk(clk),
        .rst(!nrst),
        .baud_edge(rx_baud_edge)
    );

    UART_RX rx_gen(
        .rst(!nrst),
        .clk(clk),
        .baud_edge(rx_baud_edge),
        .rx(rx),
        .data(rx_data_wire),
        .data_ready(data_ready_wire)
    );

    always @(posedge clk) begin
        nrst <= 1;
        if(!nrst) begin
            data_ready <= 0;
        end else begin
            if (data_ready_wire) begin
                if(!data_ready) begin
                    data <= rx_data_wire;
                    data_ready <= 1;
                end
            end

            if (data_accepted) begin
                data_ready <= 0;
            end
        end
    end
endmodule
