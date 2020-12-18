module top (
    input wire clk,
    output wire clk_pr1,
    output wire clk_pr2,
    input wire rst,
    output wire rst_pr1,
    output wire rst_pr2,
    input  wire [3:0] sw,
    output wire [3:0] in_pr1,
    input wire [3:0] out_pr1,
    output wire [3:0] in_pr2,
    input wire [3:0] out_pr2,
    output wire [3:0] led,
);
    // 'data' buffers
    wire [3:0] inter;
    genvar i;
    generate
        for (i=0; i < 4; i=i+1) begin
            SYN_OBUF in_obuf_pr1(.I(sw[i]), .O(in_pr1[i]));
            SYN_IBUF out_ibuf_pr1(.I(out_pr1[i]), .O(inter[i]));
            SYN_OBUF in_obuf_pr2(.I(inter[i]), .O(in_pr2[i]));
            SYN_IBUF out_ibuf2(.I(out_pr2[i]), .O(led[i]));
        end
    endgenerate

    // clock buffers
    IBUF clk_ibuf(.I(clk),      .O(clk_ibuf));
    BUFG clk_bufg(.I(clk_ibuf), .O(clk_b));
    SYN_OBUF clk_obuf1(.I(clk_b), .O(clk_pr1));
    SYN_OBUF clk_obuf2(.I(clk_b), .O(clk_pr2));

    // reset buffers
    SYN_OBUF rst_obuf1(.I(rst), .O(rst_pr1));
    SYN_OBUF rst_obuf2(.I(rst), .O(rst_pr2));
endmodule
