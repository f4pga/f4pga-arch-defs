// Modified code found at:
// https://www.fpga4fun.com/Counters3.html

module LFSR8_11D
(
  input  wire clk,
  input  wire ce,
  output wire q
);

reg [7:0] LFSR = 255;
wire feedback = LFSR[7];

always @(posedge clk)
if (ce) begin
  LFSR[0] <= feedback;
  LFSR[1] <= LFSR[0];
  LFSR[2] <= LFSR[1] ^ feedback;
  LFSR[3] <= LFSR[2] ^ feedback;
  LFSR[4] <= LFSR[3] ^ feedback;
  LFSR[5] <= LFSR[4];
  LFSR[6] <= LFSR[5];
  LFSR[7] <= LFSR[6];
end else begin
  LFSR    <= LFSR;
end

/*
localparam TAPS = 8'b00011100;
wire [7:0] lut_o;

genvar i;
generate for(i=0; i<8; i=i+1) begin

    if (i != 0) begin
        if (TAPS & (1<<i))
            LUT2 #(.INIT(4'b0110)) lut (.I0(LFSR[i-1]), .I1(feedback), .O(lut_o[i]));
        else
            LUT1 #(.INIT(2'b10))   lut (.I0(LFSR[i-1]),                .O(lut_o[i]));

        always @(posedge clk)
            if(ce) LFSR[i] <= lut_o[i];
            else   LFSR[i] <= LFSR[i];

    end else begin

        always @(posedge clk)
            if(ce) LFSR[i] <= feedback;
            else   LFSR[i] <= LFSR[i];
    end

end endgenerate
*/

// Output
assign q = LFSR[0];

endmodule
