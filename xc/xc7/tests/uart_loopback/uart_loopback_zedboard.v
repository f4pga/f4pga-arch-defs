module top (
    input  wire clk,

    input  wire [7:0] sw,
    output wire [7:0] led
);

    wire [63:0] emio_gpio_o;
    wire [63:0] emio_gpio_t;
    wire [63:0] emio_gpio_i;

PS7 PS7(
    .EMIOGPIOO			(emio_gpio_o),
    .EMIOGPIOTN			(emio_gpio_t),
    .EMIOGPIOI			(emio_gpio_i)
)
endmodule
