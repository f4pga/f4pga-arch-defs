`timescale 1ns/1ps

// VPR routing interconnect module
module fpga_interconnect(datain, dataout);
    input  datain;
    output dataout;

    // Behavioral model
    assign dataout = datain;

    // Timing paths. The values are dummy and are intended to be replaced by
    // ones from a SDF file during simulation.
    specify
        (datain => dataout) = 0;
    endspecify

endmodule


module frac_lut4_arith (in, cin, lut4_out, cout);

    parameter [15:0] LUT  = 16'd0;
    parameter [0: 0] MODE = 0;

    input  [3:0] in;
    input  [0:0] cin;
    output [0:0] lut4_out;
    output [0:0] cout;

    // Mode bits of frac_lut4_arith are responsible for the LI2 mux which
    // selects between the LI2 and CIN inputs.
    wire [3:0] li = (MODE == 1'b1) ?
        {in[3], cin,   in[1], in[0]} :
        {in[3], in[2], in[1], in[0]};

    // Output function
    wire [7:0] s1 = li[0] ?
        {LUT[14], LUT[12], LUT[10], LUT[8], LUT[6], LUT[4], LUT[2], LUT[0]} :
        {LUT[15], LUT[13], LUT[11], LUT[9], LUT[7], LUT[5], LUT[3], LUT[1]};

    wire [3:0] s2 = li[1] ?
        {s1[6], s1[4], s1[2], s1[0]} : 
        {s1[7], s1[5], s1[3], s1[1]};

    wire [1:0] s3 = li[2] ?
        {s2[2], s2[0]} :
        {s2[3], s2[1]};

    assign lut4_out = li[3] ? s3[0] : s3[1];
    
    // Carry out function
    assign cout = s2[2] ? cin : s2[3];

    // Timing paths. The values are dummy and are intended to be replaced by
    // ones from a SDF file during simulation.
    specify
        (in  *> lut4_out) = 0;
        (cin => lut4_out) = 0;
        (in  *> cout) = 0;
        (cin => cout) = 0;
    endspecify

endmodule


module scff (D, DI, clk, reset, Q); // QL_IOFF

    parameter  [0:0] MODE = 1; // The default

    input  [0:0] D;
    input  [0:0] DI;
    input  [0:0] clk;
    input  [0:0] reset;
    output [0:0] Q;

    scff_1 #(.MODE(MODE)) scff_1 (
        .D      (D),
        .DI     (DI),
        .clk    (clk),
        .preset (1'b1),
        .reset  (reset),
        .Q      (Q)
    );

endmodule


module scff_1 (D, DI, clk, preset, reset, Q); // QL_FF

    parameter  [0:0] MODE = 1; // The default

    input      [0:0] D;
    input      [0:0] DI;
    input      [0:0] clk;
    input      [0:0] preset;
    input      [0:0] reset;
    output reg [0:0] Q;

    initial Q <= 1'b0;

    // Clock inverter
    wire ck = (MODE == 1'b1) ? clk : !clk;

    // FLip-flop behavioral model
    always @(posedge ck or negedge reset or negedge preset) begin
        if      (!reset)  Q <= 1'b0;
        else if (!preset) Q <= 1'b1;
        else              Q <= D;
    end

    // Timing paths. The values are dummy and are intended to be replaced by
    // ones from a SDF file during simulation.
    specify
      (posedge clk => (Q +: D)) = 0;
      $setuphold(posedge clk, D, 0, 0);
      $recrem(posedge reset, posedge clk, 0, 0);
      $recrem(posedge preset, posedge clk, 0, 0);
    endspecify

endmodule
