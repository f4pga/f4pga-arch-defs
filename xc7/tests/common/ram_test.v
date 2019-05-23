module RAM_TEST #(
    parameter ADDR_WIDTH = 6,
    parameter DATA_WIDTH = 1,
    parameter IS_DUAL_PORT = 1,
    parameter RANDOM_ITERATION_PER_LOOP = 10,
    parameter LFSR_WIDTH = 16,
    parameter LFSR_POLY = 16'hD008,
    // How much to increment the address to move 1 full data width.
    parameter ADDRESS_STEP = 1,
    // Max address for this memory
    parameter MAX_ADDRESS = 63
) (
    input rst,
    input clk,
    // Memory connection
    input [DATA_WIDTH-1:0] read_data,
    output reg [DATA_WIDTH-1:0] write_data,
    output reg write_enable,
    output reg [ADDR_WIDTH-1:0] read_address,
    output reg [ADDR_WIDTH-1:0] write_address,
    // INIT ROM
    // When the memory is first initialized, it is expected to match the ROM
    // port.
    input [DATA_WIDTH-1:0] rom_read_data,
    output reg [ADDR_WIDTH-1:0] rom_read_address,
    // When an iteration is complete, success will be 1 for 1 cycle
    output reg loop_complete,
    // If an error occurs during a test, error will be 1 for each cycle
    // with an error.
    output reg error,
    // error_state will contain the state of test FSM when the error occured.
    output reg [7:0] error_state,
    // error_address will be the read address where the error occurred.
    output reg [ADDR_WIDTH-1:0] error_address,
    // expected_data will be the read value expected.
    output reg [DATA_WIDTH-1:0] expected_data,
    // actual_data will be the read value read.
    output reg [DATA_WIDTH-1:0] actual_data
);
    reg [7:0] state;
    reg [DATA_WIDTH-1:0] test_value;

    reg [$clog2(RANDOM_ITERATION_PER_LOOP)-1:0] rand_count;

    localparam START = 8'd1,
        VERIFY_INIT = 8'd2,
        WRITE_ZEROS = 8'd3,
        VERIFY_ZEROS = 8'd4,
        WRITE_ONES = 8'd5,
        VERIFY_ONES = 8'd6,
        WRITE_10 = 8'd7,
        VERIFY_10 = 8'd8,
        WRITE_01 = 8'd9,
        VERIFY_01 = 8'd10,
        WRITE_RANDOM = 8'd11,
        VERIFY_RANDOM = 8'd12,
        RESTART_LOOP = 8'd13;

    reg pause;
    reg lfsr_reset;
    reg wait_for_lfsr_reset;
    reg [LFSR_WIDTH-1:0] lfsr_seed;
    reg [LFSR_WIDTH-1:0] start_lfsr_seed;
    wire [LFSR_WIDTH-1:0] rand_data;

    LFSR #(
        .WIDTH(LFSR_WIDTH),
        .POLY(LFSR_POLY)
    ) lfsr (
        .rst(lfsr_reset),
        .clk(clk),
        .seed(lfsr_seed),
        .r(rand_data)
    );

    always @(posedge clk) begin
        if(rst) begin
            state <= START;
            error <= 0;
            write_enable <= 0;
            lfsr_reset <= 1;
            lfsr_seed <= 1;
        end else begin
            case(state)
                START: begin
                    lfsr_reset <= 0;
                    state <= VERIFY_INIT;
                    read_address <= 0;
                    rom_read_address <= 0;
                    write_enable <= 0;
                    error <= 0;
                end
                VERIFY_INIT: begin
                    if(rom_read_data != read_data) begin
                        error <= 1;
                        error_state <= state;
                        error_address <= read_address;
                        expected_data <= rom_read_data;
                        actual_data <= read_data;
                    end else begin
                        error <= 0;
                    end

                    if(read_address + ADDRESS_STEP <= MAX_ADDRESS) begin
                        read_address <= read_address + ADDRESS_STEP;
                        rom_read_address <= rom_read_address + ADDRESS_STEP;
                    end else begin
                        read_address <= 0;
                        write_address <= 0;
                        write_enable <= 1;
                        write_data <= {DATA_WIDTH{1'b0}};
                        state <= WRITE_ZEROS;
                    end
                end
                WRITE_ZEROS: begin
                    loop_complete <= 0;
                    if(write_address + ADDRESS_STEP <= MAX_ADDRESS) begin
                        write_address <= write_address + ADDRESS_STEP;
                    end else begin
                        read_address <= 0;
                        write_address <= 0;
                        write_enable <= 0;
                        pause <= 1;
                        state <= VERIFY_ZEROS;
                    end
                end
                VERIFY_ZEROS: begin
                    if(pause) begin
                        pause <= 0;
                    end else begin
                        if(read_data != {DATA_WIDTH{1'b0}}) begin
                            error <= 1;
                            error_state <= state;
                            error_address <= read_address;
                            expected_data <= {DATA_WIDTH{1'b0}};
                            actual_data <= read_data;
                        end else begin
                            error <= 0;
                        end

                        if(read_address + ADDRESS_STEP <= MAX_ADDRESS) begin
                            read_address <= read_address + ADDRESS_STEP;
                        end else begin
                            read_address <= 0;
                            write_address <= 0;
                            write_enable <= 1;
                            write_data <= {DATA_WIDTH{1'b1}};
                            state <= WRITE_ONES;
                        end
                    end
                end
                WRITE_ONES: begin
                    // If dual port, data should still be zero.
                    if(IS_DUAL_PORT) begin
                        if(read_data != {DATA_WIDTH{1'b0}}) begin
                            error <= 1;
                            error_state <= state;
                            error_address <= read_address;
                            expected_data <= {DATA_WIDTH{1'b0}};
                            actual_data <= read_data;
                        end else begin
                            error <= 0;
                        end
                    end else begin
                        if(read_data != {DATA_WIDTH{1'b1}}) begin
                            error <= 1;
                            error_state <= state;
                            error_address <= read_address;
                            expected_data <= {DATA_WIDTH{1'b1}};
                            actual_data <= read_data;
                        end else begin
                            error <= 0;
                        end
                    end

                    if(write_address + ADDRESS_STEP <= MAX_ADDRESS) begin
                        read_address <= read_address + ADDRESS_STEP;
                        write_address <= write_address + ADDRESS_STEP;
                    end else begin
                        read_address <= 0;
                        write_address <= 0;
                        write_enable <= 0;
                        state <= VERIFY_ONES;
                        pause <= 1;
                    end
                end
                VERIFY_ONES: begin
                    if(pause) begin
                        pause <= 0;
                    end else begin
                        if(read_data != {DATA_WIDTH{1'b1}}) begin
                            error <= 1;
                            error_state <= state;
                            error_address <= read_address;
                            expected_data <= {DATA_WIDTH{1'b1}};
                            actual_data <= read_data;
                        end else begin
                            error <= 0;
                        end

                        if(read_address + ADDRESS_STEP <= MAX_ADDRESS) begin
                            read_address <= read_address + ADDRESS_STEP;
                        end else begin
                            state <= WRITE_RANDOM;
                            write_enable <= 1;
                            write_address <= 0;
                            lfsr_seed <= rand_data;
                            write_data <= rand_data[DATA_WIDTH-1:0];
                            read_address <= 0;
                        end
                    end
                end
                WRITE_RANDOM: begin
                    if(write_address + ADDRESS_STEP <= MAX_ADDRESS) begin
                        write_address <= write_address + ADDRESS_STEP;
                        write_data <= rand_data[DATA_WIDTH-1:0];
                    end else begin
                        read_address <= 0;
                        write_address <= 0;
                        write_enable <= 0;
                        state <= VERIFY_RANDOM;

                        // Return LFSR to state at beginning of WRITE_RANDOM.
                        lfsr_reset <= 1;
                        wait_for_lfsr_reset <= 1;
                    end
                end
                VERIFY_RANDOM: begin
                    if(wait_for_lfsr_reset) begin
                        wait_for_lfsr_reset <= 0;
                        lfsr_reset <= 1;
                    end else begin
                        lfsr_reset <= 0;
                        if(read_data != rand_data[DATA_WIDTH-1:0]) begin
                            error <= 1;
                            error_state <= state;
                            error_address <= read_address;
                            expected_data <= rand_data[DATA_WIDTH-1:0];
                            actual_data <= read_data;
                        end else begin
                            error <= 0;
                        end

                        if(read_address + ADDRESS_STEP <= MAX_ADDRESS) begin
                            read_address <= read_address + ADDRESS_STEP;
                        end else begin
                            state <= RESTART_LOOP;
                        end
                    end
                end
                RESTART_LOOP: begin
                    loop_complete <= 1;
                    error <= 0;
                    read_address <= 0;
                    write_address <= 0;
                    write_enable <= 1;
                    write_data <= {DATA_WIDTH{1'b0}};
                    state <= WRITE_ZEROS;
                end
                default: begin
                    state <= START;
                    error <= 0;
                end
            endcase

        end
    end
endmodule
