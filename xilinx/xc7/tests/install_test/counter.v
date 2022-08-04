module top (
    input  wire clk,

    input  wire [7:0] sw,
    output wire [7:0] led,

    input wire rx,
    output wire tx
);

    localparam BITS = 4;
    localparam LOG2DELAY = 22;

    wire clk_to_bufg;
    IBUF clk_ibuf(.I(clk), .O(clk_to_bufg));

    wire bufg;
    BUFG bufgctrl(.I(clk_to_bufg), .O(bufg));

    reg [BITS+LOG2DELAY-1:0] counter = 0;

    always @(posedge bufg) begin
    	counter <= counter + 1;
    end

    assign led[6:0] = counter >> LOG2DELAY;
    assign led[7] = ^sw;
endmodule
