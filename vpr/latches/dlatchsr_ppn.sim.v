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
