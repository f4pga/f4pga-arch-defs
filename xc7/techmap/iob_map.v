module IBUF (
  input  I,
  output O
);

  \$__XILINX_IBUF _TECHMAP_REPLACE_ (
  .I(I),
  .O(O)
  );

endmodule


module OBUF (
  input  I,
  output O
);

  \$__XILINX_OBUF _TECHMAP_REPLACE_ (
  .I(I),
  .O(O)
  );

endmodule

