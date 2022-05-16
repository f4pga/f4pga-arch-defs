module top(
    input  wire clk,
    output wire [3:0] led
);

wire [63:0] emio_gpio_o;
wire [63:0] emio_gpio_t;
wire [63:0] emio_gpio_i;

wire clk_bufg;
BUFG BUFG(.I(clk), .O(clk_bufg));

wire en_counter = ~emio_gpio_o[0];
wire count_direction = ~emio_gpio_o[1];
reg [31:0] counter = 0;

always @(posedge clk_bufg) begin
    if (en_counter)
        if (count_direction)
            counter <= counter + 1;
        else
            counter <= counter - 1;
end

assign led = counter[27:24];

// The PS7
(* KEEP, DONT_TOUCH *)
PS7 PS7(
    .EMIOGPIOO                  (emio_gpio_o),
    .EMIOGPIOTN                 (emio_gpio_t),
    .EMIOGPIOI                  (emio_gpio_i),
);


endmodule
