`timescale 1 ns / 1 ps

module tb ();

// ============================================================================

initial begin
    $dumpfile("tb.vcd");
    $dumpvars(0, tb);

    #10000 $finish();
end

// ============================================================================

reg CLK;
reg RST;

initial CLK <= 1'b1;
always #0.5 CLK <= ~CLK;

initial begin   
    #0      RST <= 1'b1;
    #10.1   RST <= 1'b0;
end

// ============================================================================
wire       srl_d;
wire       srl_q;
wire       srl_ce;
wire [4:0] srl_a;

SRLC32E srl
(
.CLK    (CLK),
.CE     (srl_ce),
.D      (srl_d),
.Q      (srl_q),
.A      (srl_a),
.Q31    ()
);

srl_tester dut
(
.clk    (CLK),
.rst    (RST),

.delay  (8),

.srl_d  (srl_d),
.srl_q  (srl_q),
.srl_ce (srl_ce),
.srl_a  (srl_a)
);

// ============================================================================

endmodule

