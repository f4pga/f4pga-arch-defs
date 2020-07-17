module top (
    input wire clk,
    output wire clk_pr1,
    input  wire [7:0] sw,
    output wire [7:0] sw_pr1,
    output wire [7:0] led,
    input wire [7:0] led_pr1
);
    genvar i;
    generate
        for (i=0; i < 8; i=i+1) begin
            SYN_IBUF led_ibuf(.I(led_pr1[i]), .O(led[i]));
            SYN_OBUF sw_obuf(.I(sw[i]), .O(sw_pr1[i]));
        end
    endgenerate

    IBUF clk_ibuf(.I(clk),      .O(clk_ibuf));
    BUFG clk_bufg(.I(clk_ibuf), .O(clk_b));
    
    SYN_OBUF clk_obuf(.I(clk_b), .O(clk_pr1));
endmodule
