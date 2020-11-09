// ============================================================================

module tb ();

    // Clock generator
    reg clk;
    initial clk = 0;
    always #0.5 clk <= !clk;

    // Address counter
    reg [7:0] addr;
    initial addr <= 8'd0;

    always @(posedge clk)
        addr <= addr + 1;

    // DUT
    wire err;
    dut_miter dut
    (
    .in_A    (addr),
    .trigger (err)
    );

    // Simulation control / debug
    initial begin
        $dumpfile(`VCDFILE);
        $dumpvars(0, tb);
    end

    reg [8:0] errors;
    initial errors <= 0;

    always @(posedge clk)
        if (err) begin
            errors <= errors + 1;
            $display("ERROR at 0x%02x", addr);
        end

    always @(posedge clk)
        if (addr == 8'hFF)
            if (errors != 0) begin
                $display("%d errors", errors);
                $finish_and_return(-1);
            end else
                $finish();

endmodule
