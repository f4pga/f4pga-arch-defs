module top (
    input  wire clk,

    input  wire [7:0] sw,
    output wire [7:0] led,
);
    wire clk_out;
    reg [26:0] counter;

    BUFGCE buf1(.CE(sw[0]), .I(clk), .O(clk_out));

    always @(posedge clk_out) begin
        counter <= counter + 1;
    end

    assign led[0] = counter[25];
endmodule
