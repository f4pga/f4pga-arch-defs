module IBUF (
  (* iopad_external_pin *)
  input  I,
  output O
);

  parameter IOSTANDARD   = "default";
  parameter IBUF_LOW_PWR = 0;
  parameter IN_TERM = "NONE";  // Not supported by Vivado ?
  parameter IO_LOC_PAIRS = ""; // Used by read_xdc.

  assign O = I;
  specify
    (I => O) = 0;
  endspecify

endmodule

module OBUF (
  input  I,
  (* iopad_external_pin *)
  output O
);

  parameter IOSTANDARD   = "default";
  parameter DRIVE        = 12;
  parameter SLEW         = "SLOW";
  parameter IO_LOC_PAIRS = ""; // Used by read_xdc.

  assign O = I;
  specify
    (I => O) = 0;
  endspecify

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

module OBUFDS (
  input  I,
  (* iopad_external_pin *)
  output O,
  (* iopad_external_pin *)
  output OB
);

  parameter IOSTANDARD  = "DEFAULT";
  parameter SLEW        = "SLOW";
  parameter PULLTYPE    = "NONE";
  parameter IO_LOC_PAIRS = ""; // Used by read_xdc.
  parameter HAS_OSERDES = 0;

  assign O  =  I;
  assign OB = ~I;

endmodule

module OBUFTDS (
  input  I,
  input  T,
  (* iopad_external_pin *)
  output O,
  (* iopad_external_pin *)
  output OB
);

  parameter IOSTANDARD  = "DEFAULT";
  parameter SLEW        = "SLOW";
  parameter PULLTYPE    = "NONE";
  parameter IO_LOC_PAIRS = ""; // Used by read_xdc.
  parameter HAS_OSERDES = 0;

  assign O  = (T == 1'b0) ?  I : 1'bz;
  assign OB = (T == 1'b0) ? ~I : 1'bz;

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
  parameter IO_LOC_PAIRS = ""; // Used by read_xdc.

  assign IO = T ? 1'bz : I;
  assign O = IO;
  specify
    (I => IO) = 0;
    (IO => O) = 0;
  endspecify

endmodule

module OBUFT (
    (* iopad_external_pin *)
    output O,
    input I,
    input T
);
    parameter CAPACITANCE = "DONT_CARE";
    parameter DRIVE = 12;
    parameter IOSTANDARD = "DEFAULT";
    parameter SLEW = "SLOW";
    parameter IO_LOC_PAIRS = ""; // Used by read_xdc.
    assign O = T ? 1'bz : I;
    specify
        (I => O) = 0;
    endspecify
endmodule

module IOBUFDS (
  input  I,
  input  T,
  output O,
    (* iopad_external_pin *)
  inout  IO,
    (* iopad_external_pin *)
  inout  IOB
);
  parameter IOSTANDARD = "DIFF_SSTL135";  // TODO: Is this the default ?
  parameter SLEW = "SLOW";
  parameter IN_TERM = "NONE";  // Not supported by Vivado ?
  parameter PULLTYPE = "NONE"; // Not supported by Vivado ?
  parameter IO_LOC_PAIRS = ""; // Used by read_xdc.
endmodule

module IBUFDS_GTE2 (
  output O,
  output ODIV2,
  input CEB,
    (* iopad_external_pin *)
  input I,
    (* iopad_external_pin *)
  input IB
  );
  parameter IO_LOC_PAIRS = ""; // Used by read_xdc.
endmodule
