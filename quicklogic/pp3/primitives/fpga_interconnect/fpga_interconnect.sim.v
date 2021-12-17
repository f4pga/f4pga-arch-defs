`timescale 1ps/1ps
(* whitebox *)

// This cell is necessary only for post-pnr simulation
// as it is a cell emitted by VPR and not part of the
// PP3 architecture
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
