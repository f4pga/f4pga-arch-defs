module top (
    input  wire clk,

    input  wire [7:0] sw,
    output wire [7:0] led
);

    localparam BITS = 8;
    localparam LOG2DELAY = 28;

    reg [BITS+LOG2DELAY-1:0] counter = 0;

    IBUF clk_ibuf(.I(clk),      .O(clk_ibuf));
    BUFG clk_bufg(.I(clk_ibuf), .O(clk_b));

    always @(posedge clk_b) begin
        counter <= counter + 1;
    end

    assign led = counter >> LOG2DELAY;
endmodule
