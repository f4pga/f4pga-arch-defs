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

module OBUFT (
  input  I,
  input  T,
  (* iopad_external_pin *)
  output O
);

  parameter IOSTANDARD   = "default";
  parameter DRIVE        = 12;
  parameter SLEW         = "SLOW";

  assign O = (T == 1'b0) ? I : 1'bz;

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

module SYN_OBUF(
    input I,
    (* iopad_external_pin *)
    output O);
  assign O = I;
endmodule

module SYN_IBUF(
    output O,
    (* iopad_external_pin *)
    input I);
  assign O = I;
endmodule

