module FRAME_GENERATOR(
    input clk,
    input rst,

    // Frame upstream port

    // Next data to output
    input [7:0] frame_tx_data,
    // Data is ready to be output
    input frame_tx_data_ready,
    // Data represents start of new frame
    input frame_tx_start_of_new_frame,
    // Data represents end of frame
    input frame_tx_end_of_frame,

    output reg frame_tx_data_accepted,
    output frame_tx_idle,

    // UART downstream port
    input uart_tx_data_accepted,
    input uart_tx_idle,
    output reg [7:0] uart_tx_data,
    output reg uart_tx_data_ready
);

initial begin
    frame_tx_data_accepted <= 0;
    uart_tx_data <= 0;
    uart_tx_data_ready <= 0;
end

localparam IDLE = 0,

    OUTPUT_DATA = 3,
    OUTPUT_ESC = 4,
    OUTPUT_END = 5,
    HANDLE_END = 6,
    CHECKSUM_ESC = 7,
    CHECKSUM_END = 8,
    CLOSE_FRAME = 9,
    MAX_STATE = 10;

// SLIP constants
// https://en.wikipedia.org/wiki/Serial_Line_Internet_Protocol
localparam END = 8'hC0,
    ESC = 8'hDB,
    ESC_END = 8'hDC,
    ESC_ESC = 8'hDD;

reg do_end = 0;
reg [$clog2(MAX_STATE)-1:0] state = 0;
reg [7:0] checksum = 0;

assign frame_tx_idle = state == IDLE && uart_tx_idle && uart_tx_data_ready == 0;

always @(posedge clk) begin
    if(rst) begin
        frame_tx_data_accepted <= 0;
        uart_tx_data <= 0;
        uart_tx_data_ready <= 0;
        state <= IDLE;
        checksum <= 0;
        do_end <= 0;
    end else begin
        if (uart_tx_data_accepted) begin
            uart_tx_data_ready <= 0;
        end

        if(state == IDLE) begin
            frame_tx_data_accepted <= 0;
            if(frame_tx_data_ready && !uart_tx_data_ready) begin
                do_end <= frame_tx_end_of_frame;
                if(frame_tx_start_of_new_frame) begin
                    uart_tx_data_ready <= 1;
                    uart_tx_data <= END;
                end
                state <= OUTPUT_DATA;
            end
        end else if(state == OUTPUT_DATA) begin
            if(!uart_tx_data_ready) begin
                frame_tx_data_accepted <= 1;
                checksum <= checksum + frame_tx_data;
                if(frame_tx_data == END) begin
                    uart_tx_data_ready <= 1;
                    uart_tx_data <= ESC;
                    state <= OUTPUT_END;
                end else if(frame_tx_data == ESC) begin
                    uart_tx_data_ready <= 1;
                    uart_tx_data <= ESC;
                    state <= OUTPUT_ESC;
                end else begin
                    uart_tx_data_ready <= 1;
                    uart_tx_data <= frame_tx_data;
                    state <= HANDLE_END;
                end
            end
        end else if(state == OUTPUT_END) begin
            if(!uart_tx_data_ready) begin
                uart_tx_data_ready <= 1;
                uart_tx_data <= ESC_END;
                state <= HANDLE_END;
            end
        end else if(state == OUTPUT_ESC) begin
            if(!uart_tx_data_ready) begin
                uart_tx_data_ready <= 1;
                uart_tx_data <= ESC_ESC;
                state <= HANDLE_END;
            end
        end else if(state == HANDLE_END) begin
            if(do_end) begin
                if(!uart_tx_data_ready) begin
                    if(checksum == ESC) begin
                        uart_tx_data <= ESC;
                        uart_tx_data_ready <= 1;
                        state <= CHECKSUM_ESC;
                    end else if(checksum == END) begin
                        uart_tx_data <= ESC;
                        uart_tx_data_ready <= 1;
                        state <= CHECKSUM_END;
                    end else begin
                        uart_tx_data <= checksum;
                        uart_tx_data_ready <= 1;
                        state <= CLOSE_FRAME;
                    end
                end
            end else begin
                state <= IDLE;
            end
        end else if(state == CHECKSUM_ESC) begin
            if(!uart_tx_data_ready) begin
                uart_tx_data <= ESC_ESC;
                uart_tx_data_ready <= 1;
                state <= CLOSE_FRAME;
            end
        end else if(state == CHECKSUM_END) begin
            if(!uart_tx_data_ready) begin
                uart_tx_data <= ESC_END;
                uart_tx_data_ready <= 1;
                state <= CLOSE_FRAME;
            end
        end else if(state == CLOSE_FRAME) begin
            if(!uart_tx_data_ready) begin
                uart_tx_data <= END;
                uart_tx_data_ready <= 1;
                state <= IDLE;
            end
        end else begin
            state <= IDLE;
        end
    end
end

endmodule
