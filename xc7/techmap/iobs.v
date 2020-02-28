module IBUF (
  input  I,
  output O
);

  parameter IOSTANDARD   = "default";
  parameter IBUF_LOW_PWR = 0;
  parameter IN_TERM = "NONE";  // Not supported by Vivado ?

  assign O = I;

endmodule


module OBUF (
  input  I,
  output O
);

  parameter IOSTANDARD   = "default";
  parameter DRIVE        = 12;
  parameter SLEW         = "SLOW";

  assign O = I;

endmodule


