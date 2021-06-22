`timescale 1ns/10ps
(* whitebox *)
module fpga_interconnect(
		datain,
		dataout
		);
    input wire datain;
    output wire dataout;

    specify
        (datain=>dataout)=(0,0);
    endspecify

    assign dataout = datain;

endmodule
