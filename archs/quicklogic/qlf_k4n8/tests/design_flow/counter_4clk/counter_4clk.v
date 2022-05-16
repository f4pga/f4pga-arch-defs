module top(
    (* clkbuf_inhibit *)
    input  wire       clk1,
    (* clkbuf_inhibit *)
    input  wire       clk2,
    (* clkbuf_inhibit *)
    input  wire       clk3,
    (* clkbuf_inhibit *)
    input  wire       clk4,
    output wire [3:0] led
);

    reg [7:0] cnt1;
    initial cnt1 <= 0;
    always @(posedge clk1)
        cnt1 <= cnt1 + 1;

    reg [7:0] cnt2;
    initial cnt2 <= 0;
    always @(posedge clk2)
        cnt2 <= cnt2 + 1;

    reg [7:0] cnt3;
    initial cnt3 <= 0;
    always @(posedge clk3)
        cnt3 <= cnt3 + 1;

    reg [7:0] cnt4;
    initial cnt4 <= 0;
    always @(posedge clk4)
        cnt4 <= cnt4 + 1;

    assign led = {cnt4[7], cnt3[7], cnt2[7], cnt1[7]};

endmodule
