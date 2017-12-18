// DFF, CFF, BFF, AFF == WFF
// Register Only flip-flop.
module WFF(
	input D,
	input CE, // Clock enable
	input CK, // Clock
	input SR, // ???
	output Q
);
  parameter INIT1;
  parameter INIT0;
  parameter SRHIGH;
  parameter SRLOW;

endmodule
