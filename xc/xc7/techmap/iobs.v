module IBUF (
  (* iopad_external_pin *)
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
  (* iopad_external_pin *)
  output O
);

  parameter IOSTANDARD   = "default";
  parameter DRIVE        = 12;
  parameter SLEW         = "SLOW";

  assign O = I;

endmodule


module IOBUF (
  (* iopad_external_pin *)
  inout IO,
  output O,
  input I,
  input T
);

  parameter IOSTANDARD   = "default";
  parameter DRIVE        = 12;
  parameter SLEW         = "SLOW";
  parameter IBUF_LOW_PWR = 0;
  parameter IN_TERM = "NONE";  // Not supported by Vivado ?

  assign IO = T ? 1'bz : I;
  assign O = IO;
  specify
    (I => IO) = 0;
    (IO => O) = 0;
  endspecify

endmodule
