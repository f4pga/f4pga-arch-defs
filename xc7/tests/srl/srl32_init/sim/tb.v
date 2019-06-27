`timescale 1 ns / 1 ps

module tb ();

// ============================================================================

initial begin
    $dumpfile("tb.vcd");
    $dumpvars(0, tb);

    #100000 $finish();
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

reg [1:0] ps_cnt  = 0;
wire      ps_tick = (ps_cnt == 0);

always @(posedge CLK)
    ps_cnt <= ps_cnt + 1;

// ============================================================================
// SRL
wire        srl_sh;
wire [4:0]  srl_a;
wire        srl_d;
wire        srl_q;

SRLC32E #
(
.INIT   (32'h5E851D30)
)
srl
(
.CLK    (CLK),
.CE     (srl_sh),
.A      (srl_a),
.D      (srl_d),
.Q      (srl_q)
);

// ============================================================================
// DUT

srl_init_tester #
(
.PATTERN(32'h5E851D30)
)
dut
(
.clk    (CLK),
.rst    (RST),
.ce     (ps_tick),

.srl_sh (srl_sh),
.srl_a  (srl_a),
.srl_d  (srl_d),
.srl_q  (srl_q),

.error  ()
);

// ============================================================================

endmodule

