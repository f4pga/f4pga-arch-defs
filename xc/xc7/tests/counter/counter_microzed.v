module top (
);

    wire [63:0] emio_gpio_o;
    wire [63:0] emio_gpio_t;
    wire [63:0] emio_gpio_i;

    wire led;
    wire [3:0] fclk;

    localparam BITS = 1;
    localparam LOG2DELAY = 23;

    reg [BITS+LOG2DELAY-1:0] counter = 0;

    always @(posedge fclk[0]) begin
    	counter <= counter + 1;
    end

    assign led = counter >> LOG2DELAY;

    assign emio_gpio_o[47] = led;


    (* keep *)
    PS7 PS7(
	    .FCLKCLK            (fclk),
	    .EMIOGPIOI			(emio_gpio_i),
	    .EMIOGPIOO			(emio_gpio_o),
    	.EMIOGPIOTN			(emio_gpio_t),
	);

endmodule
