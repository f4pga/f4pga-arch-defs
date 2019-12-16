module ram0(
    // Write port
    input wrclk,
    input [63:0] di,
    input wren,
    input [8:0] wraddr,
    // Read port
    input rdclk,
    input rden,
    input [8:0] rdaddr,
    output reg [63:0] do);

    (* ram_style = "block" *) reg [63:0] ram[0:511];


    genvar i;
    generate
        for (i=0; i<1024; i=i+1)
        begin
            initial begin
                ram[i] <= i;
            end
        end
    endgenerate

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

    wire [8:0] write_address;
    wire [8:0] read_address;
    wire [63:0] read_data;
    wire [63:0] write_data;
    wire write_enable;
    wire read_enable = !write_enable;

    wire [8:0] rom_read_address;
    reg [63:0] rom_read_data;

    always @(posedge clk) begin
        rom_read_data[8:0] <= rom_read_address;
        rom_read_data[63:9] <= 1'b0;
    end

    wire loop_complete;
    wire error_detected;
    wire [7:0] error_state;
    wire [8:0] error_address;
    wire [63:0] expected_data;
    wire [63:0] actual_data;

    RAM_TEST #(
        .ADDR_WIDTH(10),
        .DATA_WIDTH(64),
        .IS_DUAL_PORT(1),
        .ADDRESS_STEP(1),
        .MAX_ADDRESS(511),
        .LFSR_WIDTH(64),
        .LFSR_POLY(64'hd800000000000000) // from Xilinx XAPP52 pg.5
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
        .DATA_WIDTH(64),
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
