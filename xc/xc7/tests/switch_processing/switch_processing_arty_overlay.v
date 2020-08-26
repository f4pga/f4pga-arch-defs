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
    SYN_OBUF in_obuf_pr1_0(.I(sw[0]), .O(in_pr1[0]));
    SYN_OBUF in_obuf_pr1_1(.I(sw[1]), .O(in_pr1[1]));
    SYN_OBUF in_obuf_pr1_2(.I(sw[2]), .O(in_pr1[2]));
    SYN_OBUF in_obuf_pr1_3(.I(sw[3]), .O(in_pr1[3]));

    SYN_IBUF out_ibuf_pr1_0(.I(out_pr1[0]), .O(inter[0]));
    SYN_IBUF out_ibuf_pr1_1(.I(out_pr1[1]), .O(inter[1]));
    SYN_IBUF out_ibuf_pr1_2(.I(out_pr1[2]), .O(inter[2]));
    SYN_IBUF out_ibuf_pr1_3(.I(out_pr1[3]), .O(inter[3]));

    SYN_OBUF in_obuf_pr2_0(.I(inter[0]), .O(in_pr2[0]));
    SYN_OBUF in_obuf_pr2_1(.I(inter[1]), .O(in_pr2[1]));
    SYN_OBUF in_obuf_pr2_2(.I(inter[2]), .O(in_pr2[2]));
    SYN_OBUF in_obuf_pr2_3(.I(inter[3]), .O(in_pr2[3]));

    SYN_IBUF out_ibuf2_0(.I(out_pr2[0]), .O(led[0]));
    SYN_IBUF out_ibuf2_1(.I(out_pr2[1]), .O(led[1]));
    SYN_IBUF out_ibuf2_2(.I(out_pr2[2]), .O(led[2]));
    SYN_IBUF out_ibuf2_3(.I(out_pr2[3]), .O(led[3]));

    // clock buffers
    IBUF clk_ibuf(.I(clk),      .O(clk_ibuf));
    BUFG clk_bufg(.I(clk_ibuf), .O(clk_b));
    SYN_OBUF clk_obuf1(.I(clk_b), .O(clk_pr1));
    SYN_OBUF clk_obuf2(.I(clk_b), .O(clk_pr2));

    // reset buffers
    SYN_OBUF rst_obuf1(.I(rst), .O(rst_pr1));
    SYN_OBUF rst_obuf2(.I(rst), .O(rst_pr2));
endmodule
