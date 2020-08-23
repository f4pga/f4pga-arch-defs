module ram16(
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

module ram32(
    // Write port
    input wrclk,
    input [31:0] di,
    input wren,
    input [8:0] wraddr,
    // Read port
    input rdclk,
    input rden,
    input [8:0] rdaddr,
    output reg [31:0] do);

    (* ram_style = "block" *) reg [31:0] ram[0:511];

    initial begin
        ram[0] = 32'b00000000_00000001_00000000_00000001;
        ram[1] = 32'b10101010_10101010_10101010_10101010;
        ram[2] = 32'b01010101_01010101_01010101_01010101;
        ram[3] = 32'b11111111_11111111_11111111_11111111;
        ram[4] = 32'b11110000_11110000_11110000_11110000;
        ram[5] = 32'b00001111_00001111_00001111_00001111;
        ram[6] = 32'b11001100_11001100_11001100_11001100;
        ram[7] = 32'b00110011_00110011_00110011_00110011;
        ram[8] = 32'b00000000_00000010_00000000_00000010;
        ram[9] = 32'b00000000_00000100_00000000_00000100;
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

module ram8(
    // Write port
    input wrclk,
    input [7:0] di,
    input wren,
    input [10:0] wraddr,
    // Read port
    input rdclk,
    input rden,
    input [10:0] rdaddr,
    output reg [7:0] do);

    (* ram_style = "block" *) reg [7:0] ram[0:1023];

    initial begin
        ram[0] = 8'b00000001;
        ram[1] = 8'b10101010;
        ram[2] = 8'b01010101;
        ram[3] = 8'b11111111;
        ram[4] = 8'b11110000;
        ram[5] = 8'b00001111;
        ram[6] = 8'b11001100;
        ram[7] = 8'b00110011;
        ram[8] = 8'b00000010;
        ram[9] = 8'b00000100;
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
    input  wire clk,

    //input  wire rx,
    //output wire tx,

    input  wire [19:0] sw,
    output wire [14:0] led
);
    wire rden8, rden16, rden32;
    reg wren8, wren16, wren32;
    wire [10:0] rdaddr;
    wire [10:0] wraddr;
    wire [32:0] di;
    wire [32:0] do;
    wire [7:0] do8;
    wire [15:0] do16;
    ram8 ram1(
        .wrclk(clk),
        .di(di[7:0]),
        .wren(wren8),
        .wraddr(wraddr),
        .rdclk(clk),
        .rden(rden8),
        .rdaddr(rdaddr),
        .do(do8[7:0])
    );
    ram16 ram2(
        .wrclk(clk),
        .di(di[15:0]),
        .wren(wren16),
        .wraddr(wraddr[9:0]),
        .rdclk(clk),
        .rden(rden16),
        .rdaddr(rdaddr[9:0]),
        .do(do16[15:0])
    );

    ram32 ram3(
        .wrclk(clk),
        .di(di),
        .wren(wren32),
        .wraddr(wraddr[8:0]),
        .rdclk(clk),
        .rden(rden32),
        .rdaddr(rdaddr[8:0]),
        .do(do)
    );
    reg [10:0] address_reg;
    reg [31:0] data_reg;
    reg [31:0] out_reg;

    assign rdaddr = address_reg;
    assign wraddr = address_reg;

    // display_mode == 00 -> ram[address_reg]
    // display_mode == 01 -> address_reg
    // display_mode == 10 -> data_reg
    wire [2:0] display_mode;

    // input_mode == 00 -> in[9:0] -> address_reg
    // input_mode == 01 -> in[7:0] -> data_reg[7:0]
    // input_mode == 10 -> in[7:0] -> data_reg[15:8]
    // input_mode == 11 -> data_reg -> ram[address_reg]
    wire [1:0] input_mode;

    // WE == 0 -> address_reg and data_reg unchanged.
    // WE == 1 -> address_reg or data_reg is updated because on input_mode.
    wire we;

    assign display_mode[0] = sw[17];
    assign display_mode[1] = sw[18];
    assign display_mode[2] = sw[19];

    assign input_mode[0] = sw[13];
    assign input_mode[1] = sw[14];
    assign input_mode[2] = sw[15];
    assign input_mode[3] = sw[16];

    assign we = sw[12];
    assign led = out_reg;
    assign di = data_reg;
    assign rden = 1;

    initial begin
        address_reg = 10'b0;
        data_reg = 32'b0;
        out_reg = 32'b0;
    end

    always @ (posedge clk) begin
        if(display_mode == 0) begin
            out_reg <= do;
        end else if(display_mode == 1) begin
            out_reg <= address_reg;
        end else if(display_mode == 2) begin
            out_reg <= data_reg;
        end if(display_mode == 3) begin
            out_reg <= do16;
        end if(display_mode == 4) begin
            out_reg <= do8;
        end

        if(we == 1) begin
            if(input_mode == 0) begin
                address_reg <= sw[9:0];
                wren16 <= 0;
            end else if(input_mode == 1) begin
                data_reg[7:0] <= sw[7:0];
                wren16 <= 0;
            end else if(input_mode == 2) begin
                data_reg[15:8] <= sw[7:0];
                wren16 <= 0;
            end else if(input_mode == 3) begin
                wren16 <= 1;
            end else if(input_mode == 4) begin
                address_reg <= sw[8:0];
                wren16 <= 0;
            end else if(input_mode == 5) begin
                data_reg[7:0] <= sw[7:0];
                wren32 <= 0;
            end else if(input_mode == 6) begin
                data_reg[15:8] <= sw[7:0];
                wren32 <= 0;
            end else if(input_mode == 7) begin
                data_reg[23:16] <= sw[7:0];
                wren32 <= 0;
            end else if(input_mode == 8) begin
                data_reg[31:17] <= sw[7:0];
                wren32 <= 0;
            end else if(input_mode == 9) begin
                wren32 <= 1;
            end else if (input_mode == 10) begin
                address_reg <= sw[10:0];
                wren8 <= 0;
            end else if(input_mode == 11) begin
                data_reg[7:0] <= sw[7:0];
                wren8 <= 0;
            end else if(input_mode == 12) begin
                wren8 <= 1;
            end
        end
    end

    // Uart loopback
    //assign tx = rx;
endmodule
