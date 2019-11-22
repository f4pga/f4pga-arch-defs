module \$IOBUF (
  input  I,
  input  T,
  output O,
  inout  IO
);

  IOBUF _TECHMAP_REPLACE_ (
  .I(I),
  .T(!T),
  .O(O),
  .IO(IO),
  );

endmodule
