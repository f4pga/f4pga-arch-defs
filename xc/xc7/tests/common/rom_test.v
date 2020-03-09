module ROM_TEST #(
    parameter ADDR_WIDTH = 6,
    parameter DATA_WIDTH = 1,
    // How much to increment the address to move 1 full data width.
    parameter ADDRESS_STEP = 1,
    // Max address for this memory
    parameter MAX_ADDRESS = 63
) (
    input rst,
    input clk,
    // Memory connection
    input [DATA_WIDTH-1:0] read_data,
    output reg [ADDR_WIDTH-1:0] read_address,
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
    reg [1:0]            delay = 1'b0;

    localparam START = 8'd1,
        VERIFY_INIT = 8'd2;

    always @(posedge clk) begin
        if(rst) begin
            state <= START;
            error <= 0;
        end else begin
            case(state)
                START: begin
                    loop_complete <= 0;
                    state <= VERIFY_INIT;
                    read_address <= 0;
                    rom_read_address <= 0;
                    error <= 0;
                end
                VERIFY_INIT: begin
                    if(delay == 0) begin
                        if(rom_read_data != read_data) begin
                            error <= 1;
                            error_state <= state;
                            error_address <= read_address;
                            expected_data <= rom_read_data;
                            actual_data <= read_data;
                        end else begin
                            error <= 0;
                        end
                    end
                    else if (delay == 1) begin
                        if(read_address + ADDRESS_STEP <= MAX_ADDRESS) begin
                            read_address <= read_address + ADDRESS_STEP;
                            rom_read_address <= rom_read_address + ADDRESS_STEP;
                        end else begin
                            rom_read_address <= 0;
                            read_address <= 0;
                            loop_complete <= 1;
                            state <= START;
                        end
                    end
                    delay <= delay + 1;
                end
            endcase
        end
    end
endmodule
