// These models are copied directly from Yosys' cells_sim.v in order not to
// reference that file in the simulation.

module SRL16E (
  output Q,
  input A0, A1, A2, A3, CE, CLK, D
);
  parameter [15:0] INIT = 16'h0000;
  parameter [0:0] IS_CLK_INVERTED = 1'b0;

  reg [15:0] r = INIT;
  assign Q = r[{A3,A2,A1,A0}];
  generate begin
    if (IS_CLK_INVERTED)
      always @(negedge CLK) if (CE) r <= { r[14:0], D };
    else
      always @(posedge CLK) if (CE) r <= { r[14:0], D };
  end endgenerate
endmodule

module SRLC32E (
  output Q,
  output Q31,
  input [4:0] A,
  input CE, CLK, D
);
  parameter [31:0] INIT = 32'h00000000;
  parameter [0:0] IS_CLK_INVERTED = 1'b0;

  reg [31:0] r = INIT;
  assign Q31 = r[31];
  assign Q = r[A];
  generate begin
    if (IS_CLK_INVERTED) begin
      always @(negedge CLK) if (CE) r <= { r[30:0], D };
    end else begin
      always @(posedge CLK) if (CE) r <= { r[30:0], D };
    end
  end endgenerate
endmodule
