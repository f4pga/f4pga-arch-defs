// Oversampling UART receiver.
module UART_RX(
    input rst, clk, baud_edge, rx,
    output [7:0] data,
    output data_ready, framing_error
);
    parameter OVERSAMPLE = 8;
    localparam FIND_EDGE = 3'd1, START = 3'd2, DATA = 3'd3, END = 3'd4;

    reg prev_rx;
    reg [7:0] data_reg;
    reg [2:0] data_counter;
    reg [2:0] state = 0;
    reg [$clog2(OVERSAMPLE+OVERSAMPLE/2)-1:0] over_sample_counter = 0;

    reg data_ready_reg = 0;
    reg framing_error_reg = 0;

    assign data = data_reg;
    assign data_ready = data_ready_reg;
    assign framing_error = framing_error_reg;

    always @(posedge clk) begin
        if(rst) begin
            data_reg <= 0;
            prev_rx <= 0;
            data_ready_reg <= 0;
            state <= FIND_EDGE;
            data_counter <= 0;
            over_sample_counter <= 0;
        end else if(baud_edge) begin
            case(state)
                FIND_EDGE: begin
                    prev_rx <= rx;

                    if(prev_rx & !rx) begin
                        state <= START;
                        prev_rx <= 0;
                        over_sample_counter <= 0;
                    end
                end
                START: begin
                    // Align sample edge in the middle of the pulses.
                    if(over_sample_counter == OVERSAMPLE/2-1) begin
                        over_sample_counter <= 0;
                        data_counter <= 0;
                        state <= DATA;
                    end else begin
                        over_sample_counter <= over_sample_counter + 1;
                    end
                end
                DATA: begin
                    if(over_sample_counter == OVERSAMPLE-1) begin
                        over_sample_counter <= 0;
                        data_reg[data_counter] <= rx;
                        if(data_counter == 7) begin
                            state <= END;
                            data_counter <= 0;
                        end else begin
                            data_counter <= data_counter + 1;
                        end
                    end else begin
                        over_sample_counter <= over_sample_counter + 1;
                    end
                end
                END: begin
                    if(over_sample_counter == OVERSAMPLE-1) begin
                        if(rx) begin
                            data_ready_reg <= 1;
                        end else begin
                            framing_error_reg <= 1;
                        end
                        state <= FIND_EDGE;
                    end else begin
                        over_sample_counter <= over_sample_counter + 1;
                    end

                end
                default: begin
                    data_ready_reg <= 0;
                    state <= FIND_EDGE;
                end
            endcase
        end else begin
            data_ready_reg <= 0;
            framing_error_reg <= 0;
        end
    end
endmodule
