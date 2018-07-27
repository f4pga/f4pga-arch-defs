`ifndef VCDFILE
`define VCDFILE "out.vcd"
`endif

`timescale 1 ms / 1 ps
module test;

   /* Make a regular pulsing clock. */
   reg clk = 0;
   always #2 clk = !clk;

   reg [3:0] in;
   wire [3:0] out;
   wire [4:0] vec0;
   wire [4:0] vec1;
   
   top uut (.clk(clk), .cen(in[0]), .rst(in[1]), .ina(in[2]), .inb(in[3]),
	    .outa(out[0]), .outb(out[1]), .outc(out[2]), .outd(out[3]),
	    .vec0(vec0), .vec1(vec1));


   initial begin
      $dumpfile(`VCDFILE);
      $dumpvars(1, uut);
      #3; // get between edges
      in <= 4'b0010;
      #1; //negedge
      if (out != 4'b1000) $error("initial reset %b", out);
      #1; // between
      in <= 4'b0000;
      #1; //posedge
      #1; //between
      if (out != 4'b1000) $error("set and reg1 %b", out);
      #1; //negedge
      #1; //between
      if (out != 4'b0000) $error("set and reg1 %b", out);
      in <= 4'b1101;
      #1; //posedge
      #1; // b
      if (vec0 != 5'b00001) $error("vec0 %b", out);
      #1; // neg
      #1; // b
      if (vec1 != 5'b00001) $error("vec1 %b", out);
      #1; // pos
      #1; // b

      repeat (3)
	#4; // full cycle

      if (out != 4'b0000) $error("set and reg1 %b", out);
      #1; // neg
      #1; // b
      if (out != 4'b0100) $error("clock to out %b", out);
      #1; // pos
      #1; // b
      if (out != 4'b0111) $error("clock to out %b", out);
      #1; // neg
      #1; // b
      #1; // pos
      #1; // b
      in <= 4'b0010;
      $display("reseting with cen and ina off");
      
      #1; // neg
      if (out != 4'b1110) $error("clock to out %b", out);
      #1; // b
      in <= 4'b0111;
      $display("reseting with cen and ina");
      #1; // pos
      #1; // b
      if (vec0 != 5'b00000) $error("vec0 %b", vec0);
      if (vec1 != 5'b11111) $error("vec1 %b", vec1);

      #1; // neg
      #1; // b
      if (vec0 != 5'b00000) $error("vec0 %b", vec0);
      if (vec1 != 5'b00001) $error("vec1 %b", vec1);
      
      $dumpflush;
      $finish;
   end // initial begin

endmodule // test

