// adapts single bit memory to parallel inputs and outputs
module RAM_SHIFTER #(
    parameter IO_WIDTH = 16,
    parameter ADDR_WIDTH = 4,
    parameter PHASE_SHIFT = 2
) (
    input                       clk,

    // parallel I/O
    input [IO_WIDTH-1:0]        in,
    output reg [IO_WIDTH-1:0]   out,

    // memory interface
    output reg [ADDR_WIDTH-1:0] addr,
    input                       ram_out,
    output                      ram_in
);

    // shift registers
    reg [IO_WIDTH-1:0]          shift_in;
    reg [IO_WIDTH-1:0]          shift_out;

    assign ram_in = shift_in[0];

    initial begin
        out       <= 0;
        addr      <= 0;
        shift_in  <= 0;
        shift_out <= 0;
    end

    always @(posedge clk) begin
        if(addr == 0)
          begin // shift registers are aligned with I/O
              // write output shift register, which is a little out of phase
              out <= {shift_out[IO_WIDTH-PHASE_SHIFT-1:0], shift_out[IO_WIDTH-1:IO_WIDTH-PHASE_SHIFT]};

              // input shift register is aligned with input, so sample it
              shift_in <= in;
          end
        else
          begin
              // rotate the input
              shift_in <= {shift_in[IO_WIDTH-2:0], shift_in[IO_WIDTH-1]};
          end

        // insert a new bit on the right and push everything to the left
        shift_out <= {shift_out[IO_WIDTH-2:0], ram_out};

        addr <= addr + 1;
    end
endmodule
