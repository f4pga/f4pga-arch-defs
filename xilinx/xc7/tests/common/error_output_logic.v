module ERROR_OUTPUT_LOGIC #(
    parameter [7:0] DATA_WIDTH = 1,
    parameter [7:0] ADDR_WIDTH = 6
) (
    input rst,
    input clk,

    input loop_complete,
    input error_detected,
    input [7:0] error_state,
    input [ADDR_WIDTH-1:0] error_address,
    input [DATA_WIDTH-1:0] expected_data,
    input [DATA_WIDTH-1:0] actual_data,

    // Output to UART
    input tx_data_accepted,
    output reg tx_data_ready,
    output reg [7:0] tx_data
);
    reg reg_error_detected;
    reg [7:0] reg_error_state;
    reg [ADDR_WIDTH-1:0] reg_error_address;
    reg [DATA_WIDTH-1:0] reg_expected_data;
    reg [DATA_WIDTH-1:0] reg_actual_data;

    reg [7:0] error_count;
    reg [7:0] output_shift;

    wire [7:0] next_output_shift = output_shift + 8;
    wire count_shift_done = next_output_shift >= 8'd16;
    wire address_shift_done = next_output_shift >= ADDR_WIDTH;
    wire data_shift_done = next_output_shift >= DATA_WIDTH;

    reg loop_ready;
    reg [7:0] latched_error_count;

    reg [7:0] errors;
    reg [10:0] state;
    reg [15:0] loop_count;
    reg [15:0] latched_loop_count;

    localparam START = (1 << 0),
        ERROR_COUNT_HEADER = (1 << 1),
        ERROR_COUNT_COUNT = (1 << 2),
        CR = (1 << 3),
        LF = (1 << 4),
        ERROR_HEADER = (1 << 5),
        ERROR_STATE = (1 << 6),
        ERROR_ADDRESS = (1 << 7),
        ERROR_EXPECTED_DATA = (1 << 8),
        ERROR_ACTUAL_DATA = (1 << 9),
        LOOP_COUNT = (1 << 10);

    initial begin
        tx_data_ready <= 1'b0;
        tx_data <= 8'b0;
        state <= START;
        reg_error_detected <= 1'b0;
    end

    always @(posedge clk) begin
        if(rst) begin
            state <= START;
            error_count <= 0;
            reg_error_detected <= 0;
            tx_data_ready <= 0;
            tx_data <= 8'b0;
            loop_count <= 0;
            loop_ready <= 0;
        end else begin

            if(error_detected) begin
                if(error_count < 255) begin
                    error_count <= error_count + 1;
                end

                if(!reg_error_detected) begin
                    reg_error_detected <= 1;
                    reg_error_state <= error_state;
                    reg_error_address <= error_address;
                    reg_expected_data <= expected_data;
                    reg_actual_data <= actual_data;
                end
            end

            if(tx_data_accepted) begin
                tx_data_ready <= 0;
            end

            if(loop_complete) begin
                loop_count <= loop_count + 1;
                if(!loop_ready) begin
                    loop_ready <= 1;
                    latched_error_count <= error_count;
                    latched_loop_count <= loop_count;
                    error_count <= 0;
                end
            end

            case(state)
                START: begin
                    if(reg_error_detected) begin
                        state <= ERROR_HEADER;
                    end else if(loop_ready) begin
                        state <= ERROR_COUNT_HEADER;
                    end
                end
                ERROR_COUNT_HEADER: begin
                    if(!tx_data_ready) begin
                        tx_data <= "L";
                        tx_data_ready <= 1;
                        state <= ERROR_COUNT_COUNT;
                    end
                end
                ERROR_COUNT_COUNT: begin
                    if(!tx_data_ready) begin
                        tx_data <= latched_error_count;
                        tx_data_ready <= 1;
                        output_shift <= 0;
                        state <= LOOP_COUNT;
                    end
                end
                LOOP_COUNT: begin
                    if(!tx_data_ready) begin
                        tx_data <= (latched_loop_count >> output_shift);
                        tx_data_ready <= 1;

                        if(count_shift_done) begin
                            output_shift <= 0;
                            loop_ready <= 0;
                            state <= CR;
                        end else begin
                            output_shift <= next_output_shift;
                        end
                    end
                end
                CR: begin
                    if(!tx_data_ready) begin
                        tx_data <= 8'h0D; // "\r"
                        tx_data_ready <= 1;
                        state <= LF;
                    end
                end
                LF: begin
                    if(!tx_data_ready) begin
                        tx_data <= 8'h0A; // "\n"
                        tx_data_ready <= 1;
                        state <= START;
                    end
                end
                ERROR_HEADER: begin
                    if(!tx_data_ready) begin
                        tx_data <= "E";
                        tx_data_ready <= 1;
                        state <= ERROR_STATE;
                    end
                end
                ERROR_STATE: begin
                    if(!tx_data_ready) begin
                        tx_data <= reg_error_state;
                        tx_data_ready <= 1;
                        output_shift <= 0;
                        state <= ERROR_ADDRESS;
                    end
                end
                ERROR_ADDRESS: begin
                    if(!tx_data_ready) begin
                        tx_data <= (reg_error_address >> output_shift);
                        tx_data_ready <= 1;

                        if(address_shift_done) begin
                            output_shift <= 0;
                            state <= ERROR_EXPECTED_DATA;
                        end else begin
                            output_shift <= next_output_shift;
                        end
                    end
                end
                ERROR_EXPECTED_DATA: begin
                    if(!tx_data_ready) begin
                        tx_data <= (reg_expected_data >> output_shift);
                        tx_data_ready <= 1;

                        if(data_shift_done) begin
                            output_shift <= 0;
                            state <= ERROR_ACTUAL_DATA;
                        end else begin
                            output_shift <= next_output_shift;
                        end
                    end
                end
                ERROR_ACTUAL_DATA: begin
                    if(!tx_data_ready) begin
                        tx_data <= (reg_actual_data >> output_shift);
                        tx_data_ready <= 1;

                        if(data_shift_done) begin
                            state <= CR;
                            reg_error_detected <= 0;
                        end else begin
                            output_shift <= output_shift + 8;
                        end
                    end
                end
                default: begin
                    state <= START;
                end
            endcase
        end
    end
endmodule
