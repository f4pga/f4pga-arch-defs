// Simple multiplier to test the dsp
module top #(
) (
    input wire [15:0] sw;
    output wire [15:0] led;
);
assign led = sw[15:8] * sw[7:0];
    
endmodule