module \$__XILINX_IBUF (
  input  I,
  output O
);

  IBUF _TECHMAP_REPLACE_ (
  .I(I),
  .O(O)
  );

endmodule


module \$__XILINX_OBUF (
  input  I,
  output O
);

  OBUF _TECHMAP_REPLACE_ (
  .I(I),
  .O(O)
  );

endmodule
