/* Binary counter displayed on LEDs (the 4 green ones on the right).
 * Changes value about once a second.
 */
module top (
	input  clk,
	output LED1,
	output LED2,
	output LED3,
	output LED4,
	output LED5
);

   localparam BITS = 4;
   localparam LOG2DELAY = 22;

   reg [BITS+LOG2DELAY-1:0] counter = 0;
   reg [BITS-1:0] 	    outcnt;

   always @(posedge clk) begin
      counter <= counter + 1;
      outcnt <= counter >> LOG2DELAY;
   end

   wire bout;
   memory m1 (clk, bout);

   assign LED1 = bout;
   assign {LED2, LED3, LED4, LED5} = outcnt;
endmodule

module memory (
	       input clk,
	       output bout
	       );

   localparam DEPTH = 10;
   localparam LEN = 1<<(DEPTH-1);

   wire [15:0] 	      data;

   reg [DEPTH-1:0] 	 cnt = 0;

  SB_RAM40_4K #(
		    .INIT_0(256'h5a5a5a5a5a5a5a5a5a5a5a5a5a5a5a5a5a5a5a5a5a5a5a5a5a5a5a5a5a5a5a5a),
		    .INIT_1(256'hffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff),
		    .INIT_2(256'hxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx),
		    .INIT_3(256'hxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx),
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
		  ) mem  (
			  .RADDR({ 2'h0, cnt}),
			  .RCLK(clk),
			  .RCLKE(1'h1),
			  .RDATA(data),
			  .RE(1'h1),
			  .WCLK(clk),
			  .WCLKE(0)
				 );


   always @(posedge clk) begin
      cnt <= cnt +1;
   end

   assign bout = data[0];

endmodule // memory
