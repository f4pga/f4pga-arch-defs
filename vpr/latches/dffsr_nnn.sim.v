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
