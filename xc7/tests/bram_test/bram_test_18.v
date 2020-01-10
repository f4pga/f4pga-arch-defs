module ram0(
    // Write port
    input wrclk,
    input [15:0] di,
    input wren,
    input [9:0] wraddr,
    // Read port
    input rdclk,
    input rden,
    input [9:0] rdaddr,
    output reg [15:0] do);

    (* ram_style = "block" *) reg [15:0] ram[0:1023];

    always @ (posedge wrclk) begin
        if (wren == 1) begin
            ram[wraddr] <= di;
        end
    end

    always @ (posedge rdclk) begin
        if (rden == 1) begin
            do <= ram[rdaddr];
        end
    end

endmodule

module top (
    input  wire clk,

    input  wire rx,
    output wire tx,

    input  wire [15:0] sw,
    output wire [15:0] led
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

    wire [9:0] write_address;
    wire [9:0] read_address;
    wire [15:0] read_data;
    wire [15:0] write_data;
    wire write_enable;
    wire read_enable = !write_enable;

    wire [9:0] rom_read_address;
    wire [15:0] rom_read_data = 16'b0;

    //assign rom_read_data[9:0] = rom_read_address;

    wire loop_complete;
    wire error_detected;
    wire [7:0] error_state;
    wire [9:0] error_address;
    wire [15:0] expected_data;
    wire [15:0] actual_data;

    RAM_TEST #(
        .ADDR_WIDTH(10),
        .DATA_WIDTH(16),
        .IS_DUAL_PORT(1),
        .ADDRESS_STEP(2),
        .MAX_ADDRESS(1023)
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

    ram0 #(
    ) bram (
        // Write port
        .wrclk(clk),
        .di(write_data),
        .wren(write_enable),
        .wraddr(write_address),
        // Read port
        .rdclk(clk),
        .rden(read_enable),
        .rdaddr(read_address),
        .do(read_data)
    );

    ERROR_OUTPUT_LOGIC #(
        .DATA_WIDTH(16),
        .ADDR_WIDTH(10)
    ) output_logic (
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
