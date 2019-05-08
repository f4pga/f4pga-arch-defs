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

    initial begin
        ram[0] = 16'b00000000_00000001;
        ram[1] = 16'b10101010_10101010;
        ram[2] = 16'b01010101_01010101;
        ram[3] = 16'b11111111_11111111;
        ram[4] = 16'b11110000_11110000;
        ram[5] = 16'b00001111_00001111;
        ram[6] = 16'b11001100_11001100;
        ram[7] = 16'b00110011_00110011;
        ram[8] = 16'b00000000_00000010;
        ram[9] = 16'b00000000_00000100;
    end

    always @ (posedge wrclk) begin
        if(wren == 1) begin
            ram[wraddr] <= di;
        end
    end

    always @ (posedge rdclk) begin
        if(rden == 1) begin
            do <= ram[rdaddr];
        end
    end

endmodule

module top (
        input         clk,
        input [15:0]  sw,
        output [15:0] led,

        // not used
        input         rx,
        output        tx
);

    assign tx = rx;  // TODO(#658): Remove this work-around

    wire [8:0]        addr;
    wire [15:0]       ram_out;
    wire              ram_in;

    RAM_SHIFTER #(
        .IO_WIDTH(16),
        .ADDR_WIDTH(9),
        .PHASE_SHIFT(3)
    ) shifter (
        .clk(clk),
        .in(sw),
        .out(led),
        .addr(addr),
        .ram_out(| ram_out),
        .ram_in(ram_in)
    );

    ram0 ram(
        .wrclk(clk),
        .di({16{ram_in}}),
        .wren(1'b1),
        .wraddr({sw[0], addr}),
        .rdclk(clk),
        .rden(1'b1),
        .rdaddr({~sw[0], addr}),
        .do(ram_out)
    );
endmodule
