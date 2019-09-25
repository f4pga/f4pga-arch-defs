module top (
    input  clk,
    input rx,
    output tx,
    input [15:0] sw,
    output [15:0] led
);
    reg nrst = 0;
    wire tx_baud_edge;
    wire rx_baud_edge;

    // Data in.
    wire [7:0] rx_data_wire;
    wire rx_data_ready_wire;

    // Data out.
    wire tx_data_ready;
    wire tx_data_accepted;
    wire [7:0] tx_data;

    assign led[14:0] = sw[14:0];
    assign led[15] = rx_data_ready_wire ^ sw[15];

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

    wire [5:0] write_address;
    wire [5:0] read_address;
    wire [2:0] read_data_unreg;
    reg [2:0] read_data = 3'b0;
    wire [2:0] write_data;
    wire write_enable;

    wire [2:0] rom_read_data;
    wire [5:0] rom_read_address;
    assign rom_read_data = rom_read_address[2:0];

    wire loop_complete;
    wire error_detected;
    wire [7:0] error_state;
    wire [5:0] error_address;
    wire [2:0] expected_data;
    wire [2:0] actual_data;

    RAM_TEST #(
        .ADDR_WIDTH(6),
        .DATA_WIDTH(3),
        .IS_DUAL_PORT(1),
        .ADDRESS_STEP(1),
        // 64-bit LUT memories are 0-63
        .MAX_ADDRESS(63),
    ) dram_test (
        .rst(!nrst),
        .clk(clk),
        // Memory connection
        .read_data(read_data),
        .write_data(write_data),
        .write_enable(write_enable),
        .read_address(read_address),
        .write_address(write_address),
        // INIT ROM connection
        .rom_read_data(rom_read_data),
        .rom_read_address(rom_read_address),
        // Reporting
        .loop_complete(loop_complete),
        .error(error_detected),
        .error_state(error_state),
        .error_address(error_address),
        .expected_data(expected_data),
        .actual_data(actual_data)
    );

    RAM64M #(
        .INIT_C(64'b1111_0000_1111_0000_1111_0000_1111_0000_1111_0000_1111_0000_1111_0000_1111_0000),
        .INIT_B(64'b1100_1100_1100_1100_1100_1100_1100_1100_1100_1100_1100_1100_1100_1100_1100_1100),
        .INIT_A(64'b1010_1010_1010_1010_1010_1010_1010_1010_1010_1010_1010_1010_1010_1010_1010_1010)
    ) dram(
        .WCLK(clk),

        .ADDRD(write_address),
        .ADDRC(read_address),
        .ADDRB(read_address),
        .ADDRA(read_address),

        .DOC(read_data_unreg[2]),
        .DOB(read_data_unreg[1]),
        .DOA(read_data_unreg[0]),

        .DIC(write_data[2]),
        .DIB(write_data[1]),
        .DIA(write_data[0]),

        .WE(write_enable)
    );

    always @(posedge clk) begin
        read_data <= read_data_unreg;
    end

    ERROR_OUTPUT_LOGIC #(
        .DATA_WIDTH(3),
        .ADDR_WIDTH(6)
    ) output_logic(
        .clk(clk),
        .rst(!nrst),
        .loop_complete(loop_complete),
        .error_detected(error_detected),
        .error_state(error_state),
        .error_address(error_address),
        .expected_data(expected_data),
        .actual_data(actual_data),
        .tx_data(tx_data),
        .tx_data_ready(tx_data_ready),
        .tx_data_accepted(tx_data_accepted)
    );

    always @(posedge clk) begin
        nrst <= 1;
    end
endmodule
