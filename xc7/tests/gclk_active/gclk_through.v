module top (
  input  wire clk,
  output wire out
);

// ============================================================================

wire clk_g;

(* LOC="BUFGCTRL_X0Y0" *)
BUFG bufg1 (.I(clk), .O(clk_g));

assign out = clk_g;

endmodule
