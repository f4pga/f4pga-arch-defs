/* Data read from RAM and displayed on one LED while others are a
 * binary counter
 */
module top (
	input  clk,
	output LED1,
	output LED2,
	output LED3,
	output LED4,
	output LED5
);

   parameter LOG2RAMDELAY = 20;

   localparam BITS = 4;
   localparam LOG2DELAY = LOG2RAMDELAY + 7;

   reg [BITS+LOG2DELAY-1:0] counter = 0;
   reg [BITS-1:0] 	    outcnt;

   wire 		    bout;
   reg 			    enable = 0;

   always @(posedge clk) begin
      counter <= counter + 1;
      outcnt <= counter >> LOG2DELAY;
      enable <= counter[LOG2RAMDELAY];
   end

   memory m1 (clk, enable, bout);

   assign LED1 = bout;
   assign {LED2, LED3, LED4, LED5} = outcnt;

endmodule

module memory (
	       input  clk,
	       input inc,
	       output bout
	       );

   localparam DEPTH = 6;
   localparam LEN = 1<<(DEPTH-1);

   wire [15:0] 	      data;
   reg [DEPTH-1:0]    cnt = 0;

   // Morse code for "hello"
   SB_RAM40_4K #(
		 .INIT_0(256'h0000000100000000000000010000000000000001000000010000000100000001),
		 .INIT_1(256'h0000000100010001000000010000000000000001000000010000000100010001),
		 .INIT_2(256'h0001000100000001000100010000000100010001000000000000000100000001),
		 .INIT_3(256'h0000000000000000000000000000000000000000000000000000000000000001),
		 .INIT_4(256'hxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx),
		 .INIT_5(256'hxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx),
		 .INIT_6(256'hxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx),
		 .INIT_7(256'hxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx),
		 .INIT_8(256'hxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx),
		 .INIT_9(256'hxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx),
		 .INIT_A(256'hxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx),
		 .INIT_B(256'hxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx),
		 .INIT_C(256'hxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx),
		 .INIT_D(256'hxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx),
		 .INIT_E(256'hxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx),
		 .INIT_F(256'hxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx),
		 .READ_MODE(32'sd1),
		 .WRITE_MODE(32'sd1)
		 )
   mem
     (
      .RADDR({ 5'b0, cnt}),
      .RCLK(clk),
      .RCLKE(1'b1),
      .RDATA(data),
      .RE(1'b1),
      .WCLK(clk),
      .WCLKE(1'b0)
      );

   always @(posedge inc) begin
      cnt <= cnt + 1;
   end

   assign bout = data[0];

endmodule // memory
