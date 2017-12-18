// D5FF, C5FF, B5FF, A5FF == W5FF
// Register/Latch flip-flop.
module W5FF(
	input D,
	input CE, // Clock enable
	input CK, // Clock
	input SR, // ???
	output Q
);

  parameter FF; // LAT
  parameter INIT1;
  parameter INIT0;
  parameter SRHI;
  parameter SRLO;

endmodule
