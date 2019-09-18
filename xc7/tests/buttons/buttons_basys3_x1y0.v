module top(
	input in,
	output out
);

   wire        in_buf;
   wire        out_buf;
   IBUF inbuf(.I(in), .O(in_buf));
   OBUF outbuf(.I(out_buf), .O(out));
   assign out_buf = in_buf;

endmodule
