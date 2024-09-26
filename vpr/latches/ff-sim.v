//  |---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|
//-
//-     $_SR_NP_ (S, R, Q)
//-
//- A set-reset latch with negative polarity SET and positive polarity RESET.
//-
//- Truth table:    S R | Q
//-                -----+---
//-                 0 1 | x
//-                 0 0 | 1
//-                 1 1 | 0
//-                 1 0 | y
//-
module \$_SR_NP_ (S, R, Q);
input S, R;
output reg Q;
always @(negedge S, posedge R) begin
	if (R == 1)
		Q <= 0;
	else if (S == 0)
		Q <= 1;
end
endmodule

//  |---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|
//-
//-     $_SR_PN_ (S, R, Q)
//-
//- A set-reset latch with positive polarity SET and negative polarity RESET.
//-
//- Truth table:    S R | Q
//-                -----+---
//-                 1 0 | x
//-                 1 1 | 1
//-                 0 0 | 0
//-                 0 1 | y
//-
module \$_SR_PN_ (S, R, Q);
input S, R;
output reg Q;
always @(posedge S, negedge R) begin
	if (R == 0)
		Q <= 0;
	else if (S == 1)
		Q <= 1;
end
endmodule

//  |---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|
//-
//-     $_SR_PP_ (S, R, Q)
//-
//- A set-reset latch with positive polarity SET and RESET.
//-
//- Truth table:    S R | Q
//-                -----+---
//-                 1 1 | x
//-                 1 0 | 1
//-                 0 1 | 0
//-                 0 0 | y
//-
module \$_SR_PP_ (S, R, Q);
input S, R;
output reg Q;
always @(posedge S, posedge R) begin
	if (R == 1)
		Q <= 0;
	else if (S == 1)
		Q <= 1;
end
endmodule

`ifdef SIMCELLS_FF
//  |---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|
//-
//-     $_FF_ (D, Q)
//-
//- A D-type flip-flop that is clocked from the implicit global clock. (This cell
//- type is usually only used in netlists for formal verification.)
//-
module \$_FF_ (D, Q);
input D;
output reg Q;
always @($global_clock) begin
	Q <= D;
end
endmodule
`endif

//  |---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|
//-
//-     $_DFF_N_ (D, C, Q)
//-
//- A negative edge D-type flip-flop.
//-
//- Truth table:    D C | Q
//-                -----+---
//-                 d \ | d
//-                 - - | q
//-
module \$_DFF_N_ (D, C, Q);
input D, C;
output reg Q;
always @(negedge C) begin
	Q <= D;
end
endmodule

//  |---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|
//-
//-     $_DFF_P_ (D, C, Q)
//-
//- A positive edge D-type flip-flop.
//-
//- Truth table:    D C | Q
//-                -----+---
//-                 d / | d
//-                 - - | q
//-
module \$_DFF_P_ (D, C, Q);
input D, C;
output reg Q;
always @(posedge C) begin
	Q <= D;
end
endmodule

//  |---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|
//-
//-     $_DFFE_NN_ (D, C, E, Q)
//-
//- A negative edge D-type flip-flop with negative polarity enable.
//-
//- Truth table:    D C E | Q
//-                -------+---
//-                 d \ 0 | d
//-                 - - - | q
//-
module \$_DFFE_NN_ (D, C, E, Q);
input D, C, E;
output reg Q;
always @(negedge C) begin
	if (!E) Q <= D;
end
endmodule

//  |---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|
//-
//-     $_DFFE_NP_ (D, C, E, Q)
//-
//- A negative edge D-type flip-flop with positive polarity enable.
//-
//- Truth table:    D C E | Q
//-                -------+---
//-                 d \ 1 | d
//-                 - - - | q
//-
module \$_DFFE_NP_ (D, C, E, Q);
input D, C, E;
output reg Q;
always @(negedge C) begin
	if (E) Q <= D;
end
endmodule

//  |---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|
//-
//-     $_DFFE_PN_ (D, C, E, Q)
//-
//- A positive edge D-type flip-flop with negative polarity enable.
//-
//- Truth table:    D C E | Q
//-                -------+---
//-                 d / 0 | d
//-                 - - - | q
//-
module \$_DFFE_PN_ (D, C, E, Q);
input D, C, E;
output reg Q;
always @(posedge C) begin
	if (!E) Q <= D;
end
endmodule

//  |---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|
//-
//-     $_DFFE_PP_ (D, C, E, Q)
//-
//- A positive edge D-type flip-flop with positive polarity enable.
//-
//- Truth table:    D C E | Q
//-                -------+---
//-                 d / 1 | d
//-                 - - - | q
//-
module \$_DFFE_PP_ (D, C, E, Q);
input D, C, E;
output reg Q;
always @(posedge C) begin
	if (E) Q <= D;
end
endmodule

//  |---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|
//-
//-     $_DFF_NN0_ (D, C, R, Q)
//-
//- A negative edge D-type flip-flop with negative polarity reset.
//-
//- Truth table:    D C R | Q
//-                -------+---
//-                 - - 0 | 0
//-                 d \ - | d
//-                 - - - | q
//-
module \$_DFF_NN0_ (D, C, R, Q);
input D, C, R;
output reg Q;
always @(negedge C or negedge R) begin
	if (R == 0)
		Q <= 0;
	else
		Q <= D;
end
endmodule

//  |---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|
//-
//-     $_DFF_NN1_ (D, C, R, Q)
//-
//- A negative edge D-type flip-flop with negative polarity set.
//-
//- Truth table:    D C R | Q
//-                -------+---
//-                 - - 0 | 1
//-                 d \ - | d
//-                 - - - | q
//-
module \$_DFF_NN1_ (D, C, R, Q);
input D, C, R;
output reg Q;
always @(negedge C or negedge R) begin
	if (R == 0)
		Q <= 1;
	else
		Q <= D;
end
endmodule

//  |---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|
//-
//-     $_DFF_NP0_ (D, C, R, Q)
//-
//- A negative edge D-type flip-flop with positive polarity reset.
//-
//- Truth table:    D C R | Q
//-                -------+---
//-                 - - 1 | 0
//-                 d \ - | d
//-                 - - - | q
//-
module \$_DFF_NP0_ (D, C, R, Q);
input D, C, R;
output reg Q;
always @(negedge C or posedge R) begin
	if (R == 1)
		Q <= 0;
	else
		Q <= D;
end
endmodule

//  |---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|
//-
//-     $_DFF_NP1_ (D, C, R, Q)
//-
//- A negative edge D-type flip-flop with positive polarity set.
//-
//- Truth table:    D C R | Q
//-                -------+---
//-                 - - 1 | 1
//-                 d \ - | d
//-                 - - - | q
//-
module \$_DFF_NP1_ (D, C, R, Q);
input D, C, R;
output reg Q;
always @(negedge C or posedge R) begin
	if (R == 1)
		Q <= 1;
	else
		Q <= D;
end
endmodule

//  |---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|
//-
//-     $_DFF_PN0_ (D, C, R, Q)
//-
//- A positive edge D-type flip-flop with negative polarity reset.
//-
//- Truth table:    D C R | Q
//-                -------+---
//-                 - - 0 | 0
//-                 d / - | d
//-                 - - - | q
//-
module \$_DFF_PN0_ (D, C, R, Q);
input D, C, R;
output reg Q;
always @(posedge C or negedge R) begin
	if (R == 0)
		Q <= 0;
	else
		Q <= D;
end
endmodule

//  |---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|
//-
//-     $_DFF_PN1_ (D, C, R, Q)
//-
//- A positive edge D-type flip-flop with negative polarity set.
//-
//- Truth table:    D C R | Q
//-                -------+---
//-                 - - 0 | 1
//-                 d / - | d
//-                 - - - | q
//-
module \$_DFF_PN1_ (D, C, R, Q);
input D, C, R;
output reg Q;
always @(posedge C or negedge R) begin
	if (R == 0)
		Q <= 1;
	else
		Q <= D;
end
endmodule

//  |---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|
//-
//-     $_DFF_PP0_ (D, C, R, Q)
//-
//- A positive edge D-type flip-flop with positive polarity reset.
//-
//- Truth table:    D C R | Q
//-                -------+---
//-                 - - 1 | 0
//-                 d / - | d
//-                 - - - | q
//-
module \$_DFF_PP0_ (D, C, R, Q);
input D, C, R;
output reg Q;
always @(posedge C or posedge R) begin
	if (R == 1)
		Q <= 0;
	else
		Q <= D;
end
endmodule

//  |---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|
//-
//-     $_DFF_PP1_ (D, C, R, Q)
//-
//- A positive edge D-type flip-flop with positive polarity set.
//-
//- Truth table:    D C R | Q
//-                -------+---
//-                 - - 1 | 1
//-                 d / - | d
//-                 - - - | q
//-
module \$_DFF_PP1_ (D, C, R, Q);
input D, C, R;
output reg Q;
always @(posedge C or posedge R) begin
	if (R == 1)
		Q <= 1;
	else
		Q <= D;
end
endmodule

//  |---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|
//-
//-     $_DFFSR_NNN_ (C, S, R, D, Q)
//-
//- A negative edge D-type flip-flop with negative polarity set and reset.
//-
//- Truth table:    C S R D | Q
//-                ---------+---
//-                 - - 0 - | 0
//-                 - 0 - - | 1
//-                 \ - - d | d
//-                 - - - - | q
//-
module \$_DFFSR_NNN_ (C, S, R, D, Q);
input C, S, R, D;
output reg Q;
always @(negedge C, negedge S, negedge R) begin
	if (R == 0)
		Q <= 0;
	else if (S == 0)
		Q <= 1;
	else
		Q <= D;
end
endmodule

//  |---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|
//-
//-     $_DFFSR_NNP_ (C, S, R, D, Q)
//-
//- A negative edge D-type flip-flop with negative polarity set and positive
//- polarity reset.
//-
//- Truth table:    C S R D | Q
//-                ---------+---
//-                 - - 1 - | 0
//-                 - 0 - - | 1
//-                 \ - - d | d
//-                 - - - - | q
//-
module \$_DFFSR_NNP_ (C, S, R, D, Q);
input C, S, R, D;
output reg Q;
always @(negedge C, negedge S, posedge R) begin
	if (R == 1)
		Q <= 0;
	else if (S == 0)
		Q <= 1;
	else
		Q <= D;
end
endmodule

//  |---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|
//-
//-     $_DFFSR_NPN_ (C, S, R, D, Q)
//-
//- A negative edge D-type flip-flop with positive polarity set and negative
//- polarity reset.
//-
//- Truth table:    C S R D | Q
//-                ---------+---
//-                 - - 0 - | 0
//-                 - 1 - - | 1
//-                 \ - - d | d
//-                 - - - - | q
//-
module \$_DFFSR_NPN_ (C, S, R, D, Q);
input C, S, R, D;
output reg Q;
always @(negedge C, posedge S, negedge R) begin
	if (R == 0)
		Q <= 0;
	else if (S == 1)
		Q <= 1;
	else
		Q <= D;
end
endmodule

//  |---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|
//-
//-     $_DFFSR_NPP_ (C, S, R, D, Q)
//-
//- A negative edge D-type flip-flop with positive polarity set and reset.
//-
//- Truth table:    C S R D | Q
//-                ---------+---
//-                 - - 1 - | 0
//-                 - 1 - - | 1
//-                 \ - - d | d
//-                 - - - - | q
//-
module \$_DFFSR_NPP_ (C, S, R, D, Q);
input C, S, R, D;
output reg Q;
always @(negedge C, posedge S, posedge R) begin
	if (R == 1)
		Q <= 0;
	else if (S == 1)
		Q <= 1;
	else
		Q <= D;
end
endmodule

//  |---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|
//-
//-     $_DFFSR_PNN_ (C, S, R, D, Q)
//-
//- A positive edge D-type flip-flop with negative polarity set and reset.
//-
//- Truth table:    C S R D | Q
//-                ---------+---
//-                 - - 0 - | 0
//-                 - 0 - - | 1
//-                 / - - d | d
//-                 - - - - | q
//-
module \$_DFFSR_PNN_ (C, S, R, D, Q);
input C, S, R, D;
output reg Q;
always @(posedge C, negedge S, negedge R) begin
	if (R == 0)
		Q <= 0;
	else if (S == 0)
		Q <= 1;
	else
		Q <= D;
end
endmodule

//  |---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|
//-
//-     $_DFFSR_PNP_ (C, S, R, D, Q)
//-
//- A positive edge D-type flip-flop with negative polarity set and positive
//- polarity reset.
//-
//- Truth table:    C S R D | Q
//-                ---------+---
//-                 - - 1 - | 0
//-                 - 0 - - | 1
//-                 / - - d | d
//-                 - - - - | q
//-
module \$_DFFSR_PNP_ (C, S, R, D, Q);
input C, S, R, D;
output reg Q;
always @(posedge C, negedge S, posedge R) begin
	if (R == 1)
		Q <= 0;
	else if (S == 0)
		Q <= 1;
	else
		Q <= D;
end
endmodule

//  |---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|
//-
//-     $_DFFSR_PPN_ (C, S, R, D, Q)
//-
//- A positive edge D-type flip-flop with positive polarity set and negative
//- polarity reset.
//-
//- Truth table:    C S R D | Q
//-                ---------+---
//-                 - - 0 - | 0
//-                 - 1 - - | 1
//-                 / - - d | d
//-                 - - - - | q
//-
module \$_DFFSR_PPN_ (C, S, R, D, Q);
input C, S, R, D;
output reg Q;
always @(posedge C, posedge S, negedge R) begin
	if (R == 0)
		Q <= 0;
	else if (S == 1)
		Q <= 1;
	else
		Q <= D;
end
endmodule

//  |---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|
//-
//-     $_DFFSR_PPP_ (C, S, R, D, Q)
//-
//- A positive edge D-type flip-flop with positive polarity set and reset.
//-
//- Truth table:    C S R D | Q
//-                ---------+---
//-                 - - 1 - | 0
//-                 - 1 - - | 1
//-                 / - - d | d
//-                 - - - - | q
//-
module \$_DFFSR_PPP_ (C, S, R, D, Q);
input C, S, R, D;
output reg Q;
always @(posedge C, posedge S, posedge R) begin
	if (R == 1)
		Q <= 0;
	else if (S == 1)
		Q <= 1;
	else
		Q <= D;
end
endmodule

//  |---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|
//-
//-     $_DLATCH_N_ (E, D, Q)
//-
//- A negative enable D-type latch.
//-
//- Truth table:    E D | Q
//-                -----+---
//-                 0 d | d
//-                 - - | q
//-
module \$_DLATCH_N_ (E, D, Q);
input E, D;
output reg Q;
always @* begin
	if (E == 0)
		Q <= D;
end
endmodule

//  |---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|
//-
//-     $_DLATCH_P_ (E, D, Q)
//-
//- A positive enable D-type latch.
//-
//- Truth table:    E D | Q
//-                -----+---
//-                 1 d | d
//-                 - - | q
//-
module \$_DLATCH_P_ (E, D, Q);
input E, D;
output reg Q;
always @* begin
	if (E == 1)
		Q <= D;
end
endmodule

//  |---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|
//-
//-     $_DLATCHSR_NNN_ (E, S, R, D, Q)
//-
//- A negative enable D-type latch with negative polarity set and reset.
//-
//- Truth table:    E S R D | Q
//-                ---------+---
//-                 - - 0 - | 0
//-                 - 0 - - | 1
//-                 0 - - d | d
//-                 - - - - | q
//-
module \$_DLATCHSR_NNN_ (E, S, R, D, Q);
input E, S, R, D;
output reg Q;
always @* begin
	if (R == 0)
		Q <= 0;
	else if (S == 0)
		Q <= 1;
	else if (E == 0)
		Q <= D;
end
endmodule

//  |---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|
//-
//-     $_DLATCHSR_NNP_ (E, S, R, D, Q)
//-
//- A negative enable D-type latch with negative polarity set and positive polarity
//- reset.
//-
//- Truth table:    E S R D | Q
//-                ---------+---
//-                 - - 1 - | 0
//-                 - 0 - - | 1
//-                 0 - - d | d
//-                 - - - - | q
//-
module \$_DLATCHSR_NNP_ (E, S, R, D, Q);
input E, S, R, D;
output reg Q;
always @* begin
	if (R == 1)
		Q <= 0;
	else if (S == 0)
		Q <= 1;
	else if (E == 0)
		Q <= D;
end
endmodule

//  |---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|
//-
//-     $_DLATCHSR_NPN_ (E, S, R, D, Q)
//-
//- A negative enable D-type latch with positive polarity set and negative polarity
//- reset.
//-
//- Truth table:    E S R D | Q
//-                ---------+---
//-                 - - 0 - | 0
//-                 - 1 - - | 1
//-                 0 - - d | d
//-                 - - - - | q
//-
module \$_DLATCHSR_NPN_ (E, S, R, D, Q);
input E, S, R, D;
output reg Q;
always @* begin
	if (R == 0)
		Q <= 0;
	else if (S == 1)
		Q <= 1;
	else if (E == 0)
		Q <= D;
end
endmodule

//  |---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|
//-
//-     $_DLATCHSR_NPP_ (E, S, R, D, Q)
//-
//- A negative enable D-type latch with positive polarity set and reset.
//-
//- Truth table:    E S R D | Q
//-                ---------+---
//-                 - - 1 - | 0
//-                 - 1 - - | 1
//-                 0 - - d | d
//-                 - - - - | q
//-
module \$_DLATCHSR_NPP_ (E, S, R, D, Q);
input E, S, R, D;
output reg Q;
always @* begin
	if (R == 1)
		Q <= 0;
	else if (S == 1)
		Q <= 1;
	else if (E == 0)
		Q <= D;
end
endmodule

//  |---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|
//-
//-     $_DLATCHSR_PNN_ (E, S, R, D, Q)
//-
//- A positive enable D-type latch with negative polarity set and reset.
//-
//- Truth table:    E S R D | Q
//-                ---------+---
//-                 - - 0 - | 0
//-                 - 0 - - | 1
//-                 1 - - d | d
//-                 - - - - | q
//-
module \$_DLATCHSR_PNN_ (E, S, R, D, Q);
input E, S, R, D;
output reg Q;
always @* begin
	if (R == 0)
		Q <= 0;
	else if (S == 0)
		Q <= 1;
	else if (E == 1)
		Q <= D;
end
endmodule

//  |---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|
//-
//-     $_DLATCHSR_PNP_ (E, S, R, D, Q)
//-
//- A positive enable D-type latch with negative polarity set and positive polarity
//- reset.
//-
//- Truth table:    E S R D | Q
//-                ---------+---
//-                 - - 1 - | 0
//-                 - 0 - - | 1
//-                 1 - - d | d
//-                 - - - - | q
//-
module \$_DLATCHSR_PNP_ (E, S, R, D, Q);
input E, S, R, D;
output reg Q;
always @* begin
	if (R == 1)
		Q <= 0;
	else if (S == 0)
		Q <= 1;
	else if (E == 1)
		Q <= D;
end
endmodule

//  |---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|
//-
//-     $_DLATCHSR_PPN_ (E, S, R, D, Q)
//-
//- A positive enable D-type latch with positive polarity set and negative polarity
//- reset.
//-
//- Truth table:    E S R D | Q
//-                ---------+---
//-                 - - 0 - | 0
//-                 - 1 - - | 1
//-                 1 - - d | d
//-                 - - - - | q
//-
module \$_DLATCHSR_PPN_ (E, S, R, D, Q);
input E, S, R, D;
output reg Q;
always @* begin
	if (R == 0)
		Q <= 0;
	else if (S == 1)
		Q <= 1;
	else if (E == 1)
		Q <= D;
end
endmodule

//  |---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|
//-
//-     $_DLATCHSR_PPP_ (E, S, R, D, Q)
//-
//- A positive enable D-type latch with positive polarity set and reset.
//-
//- Truth table:    E S R D | Q
//-                ---------+---
//-                 - - 1 - | 0
//-                 - 1 - - | 1
//-                 1 - - d | d
//-                 - - - - | q
//-
module \$_DLATCHSR_PPP_ (E, S, R, D, Q);
input E, S, R, D;
output reg Q;
always @* begin
	if (R == 1)
		Q <= 0;
	else if (S == 1)
		Q <= 1;
	else if (E == 1)
		Q <= D;
end
endmodule
