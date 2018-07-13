`default_nettype none
module TRELLIS_FF(input CLK, LSR, CE, DI, output reg Q);
	parameter GSR = "ENABLED";
	parameter [127:0] CEMUX = "1";
	parameter CLKMUX = "CLK";
	parameter LSRMUX = "LSR";
	parameter SRMODE = "LSR_OVER_CE";
	parameter REGSET = "RESET";

	wire muxce = (CEMUX == "1") ? 1'b1 :
	             (CEMUX == "0") ? 1'b0 :
							 (CEMUX == "INV") ? ~CE :
							 CE;

	wire muxlsr = (LSRMUX == "INV") ? ~LSR : LSR;
	wire muxclk = (CLKMUX == "INV") ? ~CLK : CLK;

	wire srval = (REGSET == "SET") ? 1'b1 : 1'b0;

	initial Q = srval;

	generate
		if (SRMODE == "ASYNC") begin
			always @(posedge muxclk, posedge muxlsr)
				if (muxlsr)
					Q <= srval;
				else
					Q <= DI;
		end else begin
			always @(posedge muxclk)
				if (muxlsr)
					Q <= srval;
				else
					Q <= DI;
		end
	endgenerate
endmodule
