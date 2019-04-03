module OUTPUT_GENERATOR(
    input clk,
    input rst,

    input count_saturated,
    input [COUNTER_WIDTH-1:0] count,

    input error,
    input [N_OUTPUTS-1:0] error_output,

    // Output data has been latched, FSM can output next value
    input tx_data_accepted,

    // Downstream transmit is complete
    input tx_idle,

    // Next data to output
    output reg [7:0] tx_data,
    // Data is ready to be output
    output reg tx_data_ready,
    // Data represents start of new frame
    output reg tx_start_of_new_frame,
    // Data represents end of frame
    output reg tx_end_of_frame,

    // Request global reset of design from RESET_CONTROLLER
    output reg do_reset
);

parameter COUNTER_WIDTH = 10;
parameter N_OUTPUTS = 10;
parameter STAT_WIDTH = 16;

reg had_reset = 0;
reg test_case_failed = 0;

reg had_error = 0;
reg [COUNTER_WIDTH-1:0] count_at_error = 0;
reg [N_OUTPUTS-1:0] reg_error_output = 0;

reg [STAT_WIDTH-1:0] num_errors = 0;
reg [STAT_WIDTH-1:0] num_error_overflows = 0;

// log of sum is a conservative version of log of max.
reg [$clog2(COUNTER_WIDTH+N_OUTPUTS+STAT_WIDTH)-1:0] output_shift = 0;

localparam IDLE = 0,

    // State handling reset frame
    OUTPUT_RESET_FRAME = 1,

    // State handling error output frame
    OUTPUT_ERROR = 2,
    OUTPUT_ERROR_COUNT = 3,
    OUTPUT_ERROR_VALUE = 4,

    // State handling stimulus complete frame
    OUTPUT_COMPLETE = 5,
    OUTPUT_TOTAL_ERROR_COUNT = 6,
    OUTPUT_ERROR_OVERFLOW_COUNT = 7,
    WAIT_FOR_FLUSH = 8,
    MAX_STATE = 9;

reg [$clog2(MAX_STATE)-1:0] state = 0;

localparam FRAME_ID_RESET = 0,
    FRAME_ID_ERROR = 1,
    FRAME_ID_COMPLETE = 2;

initial begin
    tx_data <= 0;
    tx_data_ready <= 1'b0;
    tx_start_of_new_frame <= 1'b0;
    tx_end_of_frame <= 1'b0;
    do_reset <= 1'b0;
end

always @(posedge clk) begin
    if(rst) begin
        had_reset <= 1;
        current_test_case <= 0;
        test_case_failed <= 0;
        had_error <= 0;
        count_at_error <= 0;
        reg_error_output <= 0;
        num_errors <= 0;
        num_error_overflows <= 0;
        state <= IDLE;
        tx_data <= 0;
        tx_data_ready <= 0;
        tx_start_of_new_frame <= 0;
        tx_end_of_frame <= 0;
        do_reset <= 0;
        output_shift <= 0;
    end else begin
        if (tx_data_accepted) begin
            tx_data_ready <= 0;
        end

        if (error && !count_saturated) begin
            if(num_errors != {STAT_WIDTH{1'b1}}) begin
                // Saturate num_errors at max
                num_errors <= num_errors + 1;
            end
            if(had_error) begin
                // There is already an error latched, count an overflow.
                if(num_error_overflows != {STAT_WIDTH{1'b1}}) begin
                    // Saturate num_errors at max
                    num_error_overflows <= num_error_overflows + 1;
                end
            end else begin
                had_error <= 1;
                count_at_error <= count;
                reg_error_output <= error_output;
            end
        end

        if(state == IDLE) begin
            if(had_reset) begin
                state <= OUTPUT_RESET_FRAME;
                had_reset <= 0;
            end else if (had_error) begin
                state <= OUTPUT_ERROR;
            end else if (count_saturated) begin
                state <= OUTPUT_COMPLETE;
            end
        end else if(state == OUTPUT_RESET_FRAME) begin
            if(!tx_data_ready) begin
                tx_data <= FRAME_ID_RESET;
                tx_data_ready <= 1;
                tx_start_of_new_frame <= 1;
                tx_end_of_frame <= 1;
                state <= IDLE;
            end
        end else if(state == OUTPUT_ERROR) begin
            if(!tx_data_ready) begin
                tx_data <= FRAME_ID_ERROR;
                tx_data_ready <= 1;
                tx_start_of_new_frame <= 1;
                tx_end_of_frame <= 0;
                state <= OUTPUT_ERROR_COUNT;
            end
        end else if(state == OUTPUT_ERROR_COUNT) begin
            if(!tx_data_ready) begin
                tx_start_of_new_frame <= 0;
                tx_end_of_frame <= 0;

                tx_data <= (count_at_error >> output_shift);
                tx_data_ready <= 1;

                if(output_shift + 8 >= COUNTER_WIDTH) begin
                    output_shift <= 0;
                    state <= OUTPUT_ERROR_VALUE;
                end else begin
                    output_shift <= output_shift + 8;
                end
            end
        end else if(state == OUTPUT_ERROR_VALUE) begin
            if(!tx_data_ready) begin
                tx_start_of_new_frame <= 0;

                tx_data <= (reg_error_output >> output_shift);
                tx_data_ready <= 1;

                if(output_shift + 8 >= N_OUTPUTS) begin
                    tx_end_of_frame <= 1;
                    state <= IDLE;
                end else begin
                    tx_end_of_frame <= 0;
                    output_shift <= output_shift + 8;
                end
            end
        end else if(state == OUTPUT_COMPLETE) begin
            if(!tx_data_ready) begin
                tx_data <= FRAME_ID_COMPLETE;
                tx_data_ready <= 1;
                tx_start_of_new_frame <= 1;
                tx_end_of_frame <= 0;
                state <= OUTPUT_TOTAL_ERROR_COUNT;
            end
        end else if(state == OUTPUT_TOTAL_ERROR_COUNT) begin
            if(!tx_data_ready) begin
                tx_start_of_new_frame <= 0;
                tx_end_of_frame <= 0;

                tx_data <= (num_errors >> output_shift);
                tx_data_ready <= 1;

                if(output_shift + 8 >= STAT_WIDTH) begin
                    output_shift <= 0;
                    state <= OUTPUT_ERROR_OVERFLOW_COUNT;
                end else begin
                    output_shift <= output_shift + 8;
                end
            end
        end else if(state == OUTPUT_ERROR_OVERFLOW_COUNT) begin
            if(!tx_data_ready) begin
                tx_start_of_new_frame <= 0;
                tx_end_of_frame <= 0;

                tx_data <= (num_errors >> output_shift);
                tx_data_ready <= 1;

                if(output_shift + 8 >= STAT_WIDTH) begin
                    tx_end_of_frame <= 1;
                    output_shift <= 0;
                    state <= WAIT_FOR_FLUSH;
                end else begin
                    tx_end_of_frame <= 0;
                    output_shift <= output_shift + 8;
                end
            end
        end else if(state == WAIT_FOR_FLUSH) begin
            if(!tx_data_ready && tx_idle) begin
                // Once flush occurs, request a reset and remain in this state.
                // Should enter the IDLE state again on RESET_CONTROLLER
                // resets the design.
                do_reset <= 1;
            end
        end else begin
            state <= IDLE;
        end
    end
end

endmodule
