module IBUF (
  input  I,
  output O
);

  parameter IOSTANDARD   = "default";
  parameter IBUF_LOW_PWR = 0;
  parameter IN_TERM = "NONE";  // Not supported by Vivado ?

  \$__XILINX_IBUF # (
  .IOSTANDARD(IOSTANDARD),
  .IBUF_LOW_PWR(IBUF_LOW_PWR),
  .IN_TERM(IN_TERM)
  )
  _TECHMAP_REPLACE_ (
  .I(I),
  .O(O)
  );

endmodule


module OBUF (
  input  I,
  output O
);

  parameter IOSTANDARD   = "default";
  parameter DRIVE        = 12;
  parameter SLEW         = "SLOW";

  \$__XILINX_OBUF # (
  .IOSTANDARD(IOSTANDARD),
  .DRIVE(DRIVE),
  .SLEW(SLEW)
  )
  _TECHMAP_REPLACE_ (
  .I(I),
  .O(O)
  );

endmodule

